import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../wallet/application/wallet_providers.dart';
import '../domain/iap_models.dart';
import '../domain/pending_order_repository.dart';
import '../domain/store_client.dart';
import 'iap_providers.dart';
import 'iap_verifier.dart';

/// App-level, long-lived transaction reconciler (spec §2/§5).
///
/// Established at startup and alive for the whole app lifecycle — **no timeout**.
/// It owns the single purchase-stream subscription and:
///
/// * hands an active purchase's terminal/deferred event to the orchestrator
///   (which "claims" it) and reconciles everything else;
/// * re-delivered orders (interrupted user flow) → verify by `orderNo` → finish;
/// * renewals / restores / family grants (no local order) → finish + refresh the
///   server entitlement (Apple S2S webhook is the source of truth);
/// * refreshes entitlement on app foreground — covering Settings-cancel and
///   webhook-driven revocation, which emit no StoreKit event.
class IapBackgroundReconciler {
  IapBackgroundReconciler(this._ref);

  final Ref _ref;
  final Map<String, Completer<StorePurchase>> _claims = {};

  /// Store product ids with a `_reconcile` in flight — guards against a batched /
  /// duplicate redelivery spawning concurrent verify+finish for the same
  /// transaction (no double-verify, no double-finish, no double-remove).
  final Set<String> _reconciling = {};

  /// Collected `.restored` transactions while a user-initiated restore is in
  /// flight; null at all other times. Crucially, an **unsolicited** `.restored`
  /// event (one arriving with no active restore session) is NOT captured here —
  /// it falls through to the safe passive [_reconcile] (finish + refresh) and is
  /// **never** turned into a new order. So restore-via-order is only ever
  /// triggered by an explicit user action, never by default.
  List<StorePurchase>? _restore;

  StreamSubscription<List<StorePurchase>>? _subscription;
  AppLifecycleListener? _lifecycle;
  bool _started = false;

  StoreClient get _store => _ref.read(storeClientProvider);
  PendingOrderRepository get _pending =>
      _ref.read(pendingOrderRepositoryProvider);
  IapVerifier get _verifier => _ref.read(iapVerifierProvider);

  /// Begins listening. Idempotent. Backlog is drained as the platform re-delivers
  /// unfinished transactions onto the stream.
  void start() {
    if (_started) return;
    _started = true;
    _subscription = _store.purchaseStream.listen(_onEvents);
    _lifecycle = AppLifecycleListener(onResume: refreshEntitlement);
    _ref.onDispose(() {
      _subscription?.cancel();
      _lifecycle?.dispose();
    });
  }

  /// The orchestrator registers interest in the next terminal/deferred event for
  /// [storeProductId]; the reconciler hands it over instead of reconciling it.
  Future<StorePurchase> awaitPurchase(String storeProductId) {
    final completer = Completer<StorePurchase>();
    _claims[storeProductId] = completer;
    return completer.future;
  }

  void cancelAwait(String storeProductId) => _claims.remove(storeProductId);

  /// Opens a restore-collection window. While open, `.restored` stream events are
  /// gathered (not passively reconciled) so the orchestrator can drive each one
  /// through the create-order → verify kernel. Called by the orchestrator's
  /// explicit, user-initiated restore only.
  void beginRestore() => _restore = <StorePurchase>[];

  /// Closes the window and returns the restored transactions collected since
  /// [beginRestore] (deduplicated by `transactionId`, in arrival order).
  List<StorePurchase> endRestore() {
    final collected = _restore ?? const <StorePurchase>[];
    _restore = null;
    return collected;
  }

  /// Refreshes the server-authoritative entitlement (account + wallet).
  void refreshEntitlement() {
    _ref.invalidate(walletSnapshotProvider);
    _ref.invalidate(currentAccountProvider);
  }

  /// Removes long-stale pending orders (e.g. app killed before any payment). The
  /// server expires unpaid orders; this just stops orphans accumulating.
  Future<void> pruneStalePendingOrders({DateTime? now}) async {
    final reference = now ?? DateTime.now().toUtc();
    for (final order in _pending.all()) {
      if (reference.difference(order.createdAt) > const Duration(hours: 24)) {
        await _pending.remove(order.orderNo);
      }
    }
  }

  void _onEvents(List<StorePurchase> events) {
    for (final event in events) {
      final claim = _claims[event.productId];
      if (claim != null &&
          !claim.isCompleted &&
          (event.isTerminal || event.status == StorePurchaseStatus.pending)) {
        claim.complete(event);
        _claims.remove(event.productId);
        continue;
      }
      // Inside an explicit restore window: hand restored entitlements to the
      // orchestrator (which verifies them) instead of passively reconciling.
      final restore = _restore;
      if (restore != null && event.status == StorePurchaseStatus.restored) {
        if (!restore.any((e) => e.transactionId == event.transactionId)) {
          restore.add(event);
        }
        continue;
      }
      if (event.isSuccessful) {
        unawaited(_reconcile(event));
      }
      // Unsolicited pending/cancel/error need no background action.
    }
  }

  Future<void> _reconcile(StorePurchase event) async {
    // In-flight guard: a batched/duplicate redelivery must not run concurrent
    // verify+finish for the same product.
    if (!_reconciling.add(event.productId)) return;
    try {
      await _reconcileLocked(event);
    } finally {
      _reconciling.remove(event.productId);
    }
  }

  Future<void> _reconcileLocked(StorePurchase event) async {
    final pending = _pending.findByStoreProductId(event.productId);
    if (pending != null) {
      // Interrupted user flow re-delivered → verify by its order number. verify
      // is the best-effort fast path to a grant; whether or not it confirms one,
      // the StoreKit transaction's finish policy is decided by product type.
      var granted = false;
      try {
        final result = await _verifier.verify(
          orderNo: pending.orderNo,
          transactionId: event.transactionId,
        );
        granted = result.isSuccessful;
      } on Object {
        granted = false;
      }
      if (granted || _mayFinishWithoutGrant(event.productId)) {
        // Granted → finish. Not granted but **restorable** (subscription /
        // non-consumable) → finish anyway: the transaction MUST be acknowledged
        // so StoreKit stops re-delivering it, and the entitlement can never be
        // lost (it stays in `currentEntitlements` for restore + the server
        // grants via the Apple S2S webhook). The refresh surfaces a
        // webhook-granted entitlement. For consumables / unknown — which have
        // neither net — leave it unfinished so the next redelivery re-verifies
        // (their only recovery), bounded by the 24h stale-order prune.
        await _store.complete(event);
        await _pending.remove(pending.orderNo);
        refreshEntitlement();
      }
      return;
    }
    // Renewal / restore / family grant: no local order. The server reconciles
    // via the Apple S2S webhook (by originalTransactionId). Finish + refresh.
    await _store.complete(event);
    refreshEntitlement();
  }

  /// Whether a transaction for [storeProductId] may be finished even though
  /// verify did not confirm a grant — true only for **restorable** catalog
  /// products (subscriptions / non-consumables). An unresolved product (not in
  /// the catalog) defaults to **false** (safe: treated like a consumable, never
  /// finished without a confirmed grant). See [Product.isRestorable].
  bool _mayFinishWithoutGrant(String storeProductId) {
    for (final product in _ref.read(iapCatalogProvider)) {
      if (product.storeProductId == storeProductId) return product.isRestorable;
    }
    return false;
  }
}
