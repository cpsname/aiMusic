import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

import '../domain/iap_models.dart';
import '../domain/iap_repository.dart';
import '../domain/order_models.dart';
import '../domain/pending_order_repository.dart';
import '../domain/purchase_state.dart';
import '../domain/store_client.dart';
import 'iap_background_reconciler.dart';
import 'iap_providers.dart';
import 'iap_verifier.dart';

/// User purchase-session state machine (spec §3/§4). Owns only the foreground
/// purchase flow (claims its product's event from the reconciler, with a short
/// SK2 silent-cancel detection window); long-lived/background events are handled
/// by [IapBackgroundReconciler].
///
/// Invariants: persist the pending order **before** the native purchase; finish
/// **only after** verify succeeds; verify failure leaves the pending order for
/// recovery. SK2 user-cancel surfaces as neither an exception nor a stream event
/// on the locked plugin (`buyNonConsumable` discards `.userCancelled` and returns
/// true), so it is detected by a short stream-silence window and the pending
/// order is **retained** — a misjudged slow success is reconciled live by
/// [IapBackgroundReconciler], so no money is lost. An explicit SK1/Play
/// stream-cancel **removes** it. Deferred (Ask to Buy) → `deferred` (loading
/// released, no finish, pending kept); a subscription that is already entitled →
/// routed to "manage" instead of a duplicate order.
///
/// Every branch emits an IAP funnel event to the telemetry sink (DF②):
/// `purchase_start → native_cancel / deferred / verify_retry / purchase_success /
/// purchase_fail(stage)`, plus `already_subscribed`.
class IapPurchaseOrchestrator extends Notifier<IapPurchaseState> {
  @override
  IapPurchaseState build() => const IapIdle();

  IapRepository get _repo => ref.read(iapRepositoryProvider);
  StoreClient get _store => ref.read(storeClientProvider);
  PendingOrderRepository get _pending =>
      ref.read(pendingOrderRepositoryProvider);
  IapVerifier get _verifier => ref.read(iapVerifierProvider);
  IapBackgroundReconciler get _reconciler => ref.read(iapReconcilerProvider);
  EnvConfig get _env => ref.read(envConfigProvider);
  ErrorHandler get _errors => ref.read(errorHandlerProvider);
  Duration get _sk2CancelWindow => ref.read(sk2CancelDetectorWindowProvider);
  Duration get _nativeTimeout => ref.read(nativePurchaseTimeoutProvider);
  Duration get _restoreDrainWindow => ref.read(restoreDrainWindowProvider);
  DateTime Function() get _now => ref.read(iapClockProvider);

  /// The account BID (UUID) to bind this purchase to (StoreKit `appAccountToken`
  /// + create-order `push_token`); null when unresolved (omit). See
  /// [appAccountTokenProvider].
  String? get _appAccountToken => ref.read(appAccountTokenProvider);

  /// Emits one IAP funnel event (DF②). Only product codes / stages travel here;
  /// the wrapping `RedactingTelemetrySink` scrubs any residual PII.
  void _funnel(String event, [Map<String, Object?> properties = const {}]) =>
      ref.read(telemetrySinkProvider).logEvent(event, properties: properties);

  /// Records a funnel failure and transitions to [IapFailed]. [diagnostic] is a
  /// non-user-facing detail (raw plugin error string / verify status) that
  /// travels only to telemetry — the [Failure]'s message stays empty so every
  /// UI surface resolves it to localized copy (see `ErrorHandler`).
  void _fail(
    String code,
    PurchaseStage stage,
    Failure failure, {
    String? diagnostic,
  }) {
    _funnel('purchase_fail', {
      'product_code': code,
      'stage': stage.name,
      'diagnostic': ?diagnostic,
    });
    state = IapFailed(productCode: code, stage: stage, failure: failure);
  }

  Future<void> purchase(StoreProduct product) async {
    if (state.isInProgress) return;
    final code = product.productCode;
    _funnel('purchase_start', {
      'product_code': code,
      'is_subscription': product.isSubscription,
    });

    // Pre-gate: never create a duplicate subscription order.
    if (product.isSubscription &&
        ref.read(subscriptionEntitlementProvider).isEntitled) {
      _funnel('already_subscribed', {'product_code': code});
      state = IapAlreadySubscribed(code);
      return;
    }

    // Bind the purchase to the account: sent as the create-order push_token and
    // attached to the native purchase as StoreKit's appAccountToken (Apple echoes
    // it on every S2S notification). Resolved once so both carry the same value.
    final appAccountToken = _appAccountToken;

    state = IapCreatingOrder(code);
    final CreateOrderResult order;
    try {
      order = await _repo.createOrder(
        distributionCode: _env.distributionCode,
        productCode: code,
        pushToken: appAccountToken,
      );
    } on Object catch (error, stackTrace) {
      _fail(code, PurchaseStage.creatingOrder, _errors.handle(error, stackTrace));
      return;
    }
    state = IapOrderCreated(code, order);

    if (order.isExpired(_now())) {
      // Empty message → the UI shows localized copy; the stage identifies the
      // fault in the funnel.
      _fail(code, PurchaseStage.expiryCheck, const StoreFailure(message: ''));
      return;
    }

    // Invariant: persist BEFORE the native purchase (resume safety).
    await _pending.save(
      PendingOrder(
        orderNo: order.orderNo,
        productCode: code,
        storeProductId: order.storeProductId,
        createdAt: _now(),
      ),
    );

    state = IapAwaitingNative(code, order);
    final claim = _reconciler.awaitPurchase(order.storeProductId);
    try {
      await _store
          .buy(
            product: product.details,
            isConsumable: product.isConsumable,
            appAccountToken: appAccountToken,
          )
          .timeout(_nativeTimeout);
    } on TimeoutException {
      // The native call never answered (e.g. no sheet was presented). Fail
      // visibly, but keep the pending order: if StoreKit still completes the
      // purchase, the reconciler verifies the late event.
      _reconciler.cancelAwait(order.storeProductId);
      _fail(
        code,
        PurchaseStage.awaitingNative,
        const StoreFailure(message: ''),
        diagnostic: 'native_timeout',
      );
      return;
    } on StorePurchaseCancelledException {
      // Defensive: the locked plugin (0.4.10) does not throw this — it discards
      // the cancel result and returns true. If a future version restores the
      // contract, treat it like the silent-cancel path and retain the pending
      // order for the reconciler.
      _reconciler.cancelAwait(order.storeProductId);
      _funnel('native_cancel', {'product_code': code, 'source': 'exception'});
      state = IapCancelled(code);
      return;
    } on Object catch (error, stackTrace) {
      _reconciler.cancelAwait(order.storeProductId);
      await _abort(order);
      _fail(code, PurchaseStage.awaitingNative, _errors.handle(error, stackTrace));
      return;
    }

    // SK2 silent-cancel detector. On the locked plugin, `buyNonConsumable`
    // discards `SK2Product.purchase()`'s `.userCancelled` and returns true, and
    // Apple delivers no Transaction for a cancel — so neither an exception nor a
    // `purchaseStream` event arrives. Detect that silence within a short window;
    // success/pending events arrive in milliseconds, well inside it. The timer is
    // cancelled the instant the claim settles, so nothing dangles on the fast path.
    final settled = Completer<void>();
    var eventReceived = false;
    unawaited(
      claim.then(
        (_) {
          eventReceived = true;
          if (!settled.isCompleted) settled.complete();
        },
        onError: (Object _, StackTrace _) {
          eventReceived = true;
          if (!settled.isCompleted) settled.complete();
        },
      ),
    );
    final detector = Timer(_sk2CancelWindow, () {
      if (!settled.isCompleted) settled.complete();
    });
    await settled.future;
    detector.cancel();

    if (!eventReceived) {
      // Heuristic cancel: retain the pending order. If this was actually a slow
      // success, the still-listening reconciler reconciles the late event and
      // refreshes the wallet — nothing is lost.
      _reconciler.cancelAwait(order.storeProductId);
      _funnel('native_cancel', {'product_code': code, 'source': 'sk2_silence'});
      state = IapCancelled(code);
      return;
    }

    final purchase = await claim;
    switch (purchase.status) {
      case StorePurchaseStatus.pending:
        // Deferred (Ask to Buy / SCA): release loading, no finish, pending kept.
        _funnel('deferred', {'product_code': code});
        state = IapDeferred(code);
        return;
      case StorePurchaseStatus.canceled:
        // SK1 / Play explicit cancel via the stream → remove the pending order.
        await _abort(order);
        _funnel('native_cancel', {'product_code': code, 'source': 'stream'});
        state = IapCancelled(code);
        return;
      case StorePurchaseStatus.error:
        await _abort(order);
        // The plugin's error string is a raw English diagnostic (e.g.
        // "SKErrorDomain error 2"), never user copy — it travels to telemetry
        // only; the UI resolves the empty message to localized copy.
        _fail(
          code,
          PurchaseStage.awaitingNative,
          const StoreFailure(message: ''),
          diagnostic: purchase.error,
        );
        return;
      case StorePurchaseStatus.purchased:
      case StorePurchaseStatus.restored:
        break;
    }

    await _verifyAndComplete(code, order, purchase);
  }

  /// Restores prior purchases on **explicit user action only** (never by
  /// default). Each restored transaction is driven through the same
  /// create-order → verify kernel as a normal purchase — `transaction_id` is the
  /// binding key, and `40011` (already used by another order) is an idempotent
  /// success. The reconciler collects the `.restored` events during the call
  /// (an unsolicited one outside this window is never turned into an order).
  /// Entitlement is server-authoritative, so a successful verify plus the final
  /// refresh surface it. Emits `restore_start → restore_success / restore_fail`.
  Future<void> restorePurchases() async {
    if (state.isInProgress) return;
    state = const IapRestoring();
    _funnel('restore_start');

    _reconciler.beginRestore();
    try {
      await _store.restore();
    } on Object catch (error, stackTrace) {
      _reconciler.endRestore();
      _funnel('restore_fail', {'stage': PurchaseStage.restoring.name});
      state = IapFailed(
        productCode: '',
        stage: PurchaseStage.restoring,
        failure: _errors.handle(error, stackTrace),
      );
      return;
    }

    // Restored events arrive on the stream just after restore() returns; drain
    // briefly, then verify each collected transaction.
    await Future<void>.delayed(_restoreDrainWindow);
    final restored = _reconciler.endRestore();

    // Each transaction runs create-order → verify strictly in sequence:
    // `POST /iap/orders` has no retry/back-off, so a concurrent same-account
    // burst trips the backend's conflict (40912) / rate-limit rejections and
    // under-counts genuinely restorable entitlements. Serialized, a duplicate
    // transaction lands on the idempotent 40011 already-used path and still
    // counts. `_restoreOne` never throws, so one bad transaction cannot abort
    // the batch.
    var restoredCount = 0;
    for (final event in restored) {
      if (await _restoreOne(event)) restoredCount += 1;
    }

    _reconciler.refreshEntitlement();
    _funnel('restore_success', {'count': restoredCount});
    state = IapRestored(restoredCount);
  }

  /// Restores one transaction through create-order → verify. Returns true when
  /// the entitlement is finished — verified/idempotent, or finished as a
  /// catalog-unresolved fallback. **Never throws**: any failure (order / verify /
  /// native finish) returns false and leaves the transaction for a later restore
  /// retry, so one bad transaction can neither abort the batch nor strand the
  /// state in `restoring`. No money is involved — these are already-owned
  /// entitlements that stay in `currentEntitlements` and are server-authoritative.
  Future<bool> _restoreOne(StorePurchase event) async {
    try {
      final product = _catalogProductForStore(event.productId);
      if (product == null) {
        // Not in the current catalog → no order can be created. It is still a
        // real entitlement: finish it so it is not re-delivered, and let the
        // server-truth refresh surface any grant.
        await _store.complete(event);
        return true;
      }

      final order = await _repo.createOrder(
        distributionCode: _env.distributionCode,
        productCode: product.productCode,
        pushToken: _appAccountToken,
      );
      final result = await _verifier.verify(
        orderNo: order.orderNo,
        transactionId: event.transactionId,
      );
      if (!result.isSuccessful) return false;

      await _store.complete(event);
      return true;
    } on Object {
      return false;
    }
  }

  /// The catalog [Product] whose `storeProductId` matches [storeProductId], or
  /// null when the store product is not in the current backend catalog.
  Product? _catalogProductForStore(String storeProductId) {
    for (final product in ref.read(iapCatalogProvider)) {
      if (product.storeProductId == storeProductId) return product;
    }
    return null;
  }

  void reset() => state = const IapIdle();

  Future<void> _verifyAndComplete(
    String code,
    CreateOrderResult order,
    StorePurchase purchase,
  ) async {
    state = IapVerifying(code, order, 0);
    final VerifyResult result;
    try {
      result = await _verifier.verify(
        orderNo: order.orderNo,
        transactionId: purchase.transactionId,
        onAttempt: (attempt) {
          state = IapVerifying(code, order, attempt);
          if (attempt > 0) {
            _funnel('verify_retry', {
              'product_code': code,
              'attempt': attempt,
            });
          }
        },
      );
    } on Object catch (error, stackTrace) {
      // Keep the pending order persisted so it can be recovered later.
      _fail(code, PurchaseStage.verifying, _errors.handle(error, stackTrace));
      return;
    }

    if (!result.isSuccessful) {
      // Verified-but-not-granted (`completed` + `grant_failed`) is a failure too:
      // do NOT finish the native transaction, and leave the pending order so the
      // reconciler re-verifies until the server grants the entitlement.
      _fail(
        code,
        PurchaseStage.verifying,
        const StoreFailure(message: ''),
        diagnostic: 'status=${result.status} grant_status=${result.grantStatus}',
      );
      return;
    }

    // Invariant: finish only after a successful verify + grant.
    await _store.complete(purchase);
    await _pending.remove(order.orderNo);
    _reconciler.refreshEntitlement();
    _funnel('purchase_success', {'product_code': code});
    state = IapCompleted(code, subscription: result.subscription);
  }

  /// Removes the pending order. Used for explicit stream-cancel (SK1/Play) and
  /// native errors, where no native transaction was produced. SK2 silent-cancel
  /// deliberately does NOT call this — it retains the order for reconciliation.
  Future<void> _abort(CreateOrderResult order) => _pending.remove(order.orderNo);
}
