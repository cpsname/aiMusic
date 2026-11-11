import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:commerce_kit/src/iap/data/pending_order_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/auth_fakes.dart' show testEnv;
import '../support/iap_fakes.dart';

const _storeId = 'com.example.pro_monthly';
const _purchased = StorePurchase(
  productId: _storeId,
  transactionId: 'tx1',
  status: StorePurchaseStatus.purchased,
);

class _CaptureTelemetry implements TelemetrySink {
  final List<String> events = [];
  final List<Map<String, Object?>?> properties = [];

  @override
  void logEvent(String name, {Map<String, Object?>? properties}) {
    events.add(name);
    this.properties.add(properties);
  }

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, Object?>? context,
    bool fatal = false,
  }) {}

  @override
  void breadcrumb(String message, {Map<String, Object?>? data}) {}

  @override
  void setUser(String? anonymousId) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeIapRepository repo;
  late FakeStoreClient store;
  late PendingOrderStore pending;
  late int walletFetches;
  late _CaptureTelemetry telemetry;

  setUp(() async {
    repo = FakeIapRepository();
    store = FakeStoreClient();
    SharedPreferences.setMockInitialValues({});
    pending = PendingOrderStore(KeyValueStore(await SharedPreferences.getInstance()));
    telemetry = _CaptureTelemetry();
    walletFetches = 0;
  });

  tearDown(() => store.dispose());

  ProviderContainer makeContainer({
    List<Duration> backoff = const [],
    DateTime? now,
    SubscriptionEntitlement entitlement = SubscriptionEntitlement.none,
    List<Product> catalog = const [],
    String? appAccountToken,
    Duration nativeTimeout = const Duration(minutes: 5),
  }) {
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(testEnv),
        iapRepositoryProvider.overrideWithValue(repo),
        storeClientProvider.overrideWithValue(store),
        pendingOrderRepositoryProvider.overrideWithValue(pending),
        iapVerifyBackoffProvider.overrideWithValue(backoff),
        iapClockProvider.overrideWithValue(() => now ?? DateTime.utc(2026)),
        subscriptionEntitlementProvider.overrideWithValue(entitlement),
        appAccountTokenProvider.overrideWithValue(appAccountToken),
        telemetrySinkProvider.overrideWithValue(telemetry),
        // Keep the silent-cancel detector fast; real success/pending events
        // settle the claim well inside it.
        sk2CancelDetectorWindowProvider
            .overrideWithValue(const Duration(milliseconds: 50)),
        iapCatalogProvider.overrideWithValue(catalog),
        nativePurchaseTimeoutProvider.overrideWithValue(nativeTimeout),
        // Keep the restore drain window tiny; the fake emits synchronously.
        restoreDrainWindowProvider
            .overrideWithValue(const Duration(milliseconds: 5)),
        walletSnapshotProvider.overrideWith((ref) async {
          walletFetches += 1;
          return WalletSnapshot.empty;
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(walletSnapshotProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  IapPurchaseState stateOf(ProviderContainer c) =>
      c.read(iapPurchaseOrchestratorProvider);
  IapPurchaseOrchestrator orchOf(ProviderContainer c) =>
      c.read(iapPurchaseOrchestratorProvider.notifier);

  test('success: order → native → verify → completed', () async {
    repo.orderResult = testOrder();
    repo.verifyOutcomes.add(completedVerify());
    store.buyResult = _purchased;
    final c = makeContainer();

    await orchOf(c).purchase(testProduct());
    await pumpEventQueue();

    expect(stateOf(c), isA<IapCompleted>());
    expect(store.completed.single.transactionId, 'tx1');
    expect(pending.all(), isEmpty);
    expect(repo.verifyCalls, 1);
    expect(walletFetches, greaterThanOrEqualTo(2));
  });

  group('appAccountToken / push_token binding', () {
    const uuid = '0193b9a0-7c8d-7e3f-9a01-abcdef012345';

    test('a resolved account token is sent to createOrder + the native buy',
        () async {
      repo.orderResult = testOrder();
      repo.verifyOutcomes.add(completedVerify());
      store.buyResult = _purchased;
      final c = makeContainer(appAccountToken: uuid);

      await orchOf(c).purchase(testProduct());
      await pumpEventQueue();

      expect(repo.pushTokenSeen, uuid); // create-order push_token
      expect(store.appAccountTokenSeen, uuid); // native appAccountToken
    });

    test('an unresolved (null) token omits push_token + appAccountToken',
        () async {
      repo.orderResult = testOrder();
      repo.verifyOutcomes.add(completedVerify());
      store.buyResult = _purchased;
      final c = makeContainer(); // appAccountToken defaults to null

      await orchOf(c).purchase(testProduct());
      await pumpEventQueue();

      expect(repo.pushTokenSeen, isNull);
      expect(store.appAccountTokenSeen, isNull);
    });
  });

  group('IAP funnel telemetry (DF②)', () {
    test('success emits purchase_start → purchase_success', () async {
      repo.orderResult = testOrder();
      repo.verifyOutcomes.add(completedVerify());
      store.buyResult = _purchased;
      final c = makeContainer();

      await orchOf(c).purchase(testProduct());
      await pumpEventQueue();

      expect(
        telemetry.events,
        containsAllInOrder(['purchase_start', 'purchase_success']),
      );
    });

    test('already-subscribed emits already_subscribed', () async {
      final c = makeContainer(
        entitlement: const SubscriptionEntitlement(
          renewalState: SubscriptionRenewalState.subscribed,
        ),
      );

      await orchOf(c).purchase(testProduct());

      expect(telemetry.events, contains('already_subscribed'));
    });

    test('SK2 silent cancel emits native_cancel (source: sk2_silence)', () async {
      repo.orderResult = testOrder();
      final c = makeContainer();

      await orchOf(c).purchase(testProduct());

      expect(telemetry.events, contains('native_cancel'));
      final props = telemetry.properties[telemetry.events.indexOf('native_cancel')];
      expect(props!['source'], 'sk2_silence');
    });

    test('deferred emits a deferred event', () async {
      repo.orderResult = testOrder();
      store.buyResult = const StorePurchase(
        productId: _storeId,
        transactionId: '',
        status: StorePurchaseStatus.pending,
      );
      final c = makeContainer();

      await orchOf(c).purchase(testProduct());
      await pumpEventQueue();

      expect(telemetry.events, contains('deferred'));
    });

    test('a retryable verify emits verify_retry then purchase_success', () async {
      repo.orderResult = testOrder();
      repo.verifyOutcomes.add(dioApiError(40912));
      repo.verifyOutcomes.add(completedVerify());
      store.buyResult = _purchased;
      final c = makeContainer(backoff: const [Duration.zero]);

      await orchOf(c).purchase(testProduct());
      await pumpEventQueue();

      expect(
        telemetry.events,
        containsAllInOrder(['purchase_start', 'verify_retry', 'purchase_success']),
      );
    });

    test('createOrder failure emits purchase_fail(creatingOrder)', () async {
      repo.orderError = dioApiError(40404, message: 'no product');
      final c = makeContainer();

      await orchOf(c).purchase(testProduct());

      expect(telemetry.events, contains('purchase_fail'));
      final props = telemetry.properties[telemetry.events.indexOf('purchase_fail')];
      expect(props!['stage'], 'creatingOrder');
    });
  });

  test('SK2 silent cancel (buy returns true, stream silent) → cancelled, '
      'pending RETAINED', () async {
    repo.orderResult = testOrder();
    // buyResult stays null: buy() returns, nothing is emitted — exactly what the
    // 0.4.10 plugin does on a user cancel.
    final c = makeContainer();

    await orchOf(c).purchase(testProduct());

    expect(stateOf(c), isA<IapCancelled>());
    expect(store.completed, isEmpty);
    expect(repo.verifyCalls, 0);
    expect(pending.all().length, 1); // heuristic cancel keeps the order
  });

  test('a silent cancel that was really a slow success is recovered by the '
      'reconciler', () async {
    repo.orderResult = testOrder();
    repo.verifyOutcomes.add(completedVerify());
    final c = makeContainer(); // buyResult null → detector fires → silent cancel

    await orchOf(c).purchase(testProduct());
    expect(stateOf(c), isA<IapCancelled>());
    expect(pending.all().length, 1); // retained

    // The "slow" success transaction finally arrives, after the detector gave up.
    store.emit(const StorePurchase(
      productId: _storeId,
      transactionId: 'late-tx',
      status: StorePurchaseStatus.purchased,
    ));
    await pumpEventQueue();

    expect(store.completed.single.transactionId, 'late-tx');
    expect(pending.all(), isEmpty); // reconciler verified + finished + removed
    expect(repo.verifyCalls, 1);
    expect(walletFetches, greaterThanOrEqualTo(2));
  });

  test('defensive PlatformException cancel → cancelled, pending RETAINED',
      () async {
    repo.orderResult = testOrder();
    store.buyThrows = const StorePurchaseCancelledException();
    final c = makeContainer();

    await orchOf(c).purchase(testProduct());

    expect(stateOf(c), isA<IapCancelled>());
    expect(store.completed, isEmpty);
    expect(pending.all().length, 1); // SK2 cancel (any form) retains
  });

  test('stream cancel (Android/SK1): cancelled, pending REMOVED', () async {
    repo.orderResult = testOrder();
    store.buyResult = const StorePurchase(
      productId: _storeId,
      transactionId: '',
      status: StorePurchaseStatus.canceled,
    );
    final c = makeContainer();

    await orchOf(c).purchase(testProduct());
    await pumpEventQueue();

    expect(stateOf(c), isA<IapCancelled>());
    expect(pending.all(), isEmpty); // explicit platform cancel → removed
  });

  test('deferred (Ask to Buy / SCA): deferred, no finish, pending kept',
      () async {
    repo.orderResult = testOrder();
    store.buyResult = const StorePurchase(
      productId: _storeId,
      transactionId: '',
      status: StorePurchaseStatus.pending,
    );
    final c = makeContainer();

    await orchOf(c).purchase(testProduct());
    await pumpEventQueue();

    expect(stateOf(c), isA<IapDeferred>());
    expect(store.completed, isEmpty);
    expect(pending.all().length, 1); // kept for the reconciler to finish later
  });

  test('already subscribed → routed to manage, no order created', () async {
    final c = makeContainer(
      entitlement: const SubscriptionEntitlement(
        renewalState: SubscriptionRenewalState.subscribed,
      ),
    );

    await orchOf(c).purchase(testProduct()); // testProduct() is a subscription

    expect(stateOf(c), isA<IapAlreadySubscribed>());
    expect(pending.all(), isEmpty);
    expect(repo.verifyCalls, 0);
  });

  test('expired order fails at expiryCheck before any native call', () async {
    repo.orderResult = testOrder(expiresAt: DateTime.utc(2020));
    final c = makeContainer(now: DateTime.utc(2026));

    await orchOf(c).purchase(testProduct());

    final failed = stateOf(c) as IapFailed;
    expect(failed.stage, PurchaseStage.expiryCheck);
    // No hardcoded English diagnostic — the UI resolves the empty message to
    // localized copy.
    expect(failed.failure.message, isEmpty);
    expect(pending.all(), isEmpty);
    expect(store.completed, isEmpty);
  });

  test('createOrder failure fails at creatingOrder', () async {
    repo.orderError = dioApiError(40404, message: 'no product');
    final c = makeContainer();

    await orchOf(c).purchase(testProduct());

    expect((stateOf(c) as IapFailed).stage, PurchaseStage.creatingOrder);
  });

  test('non-retryable verify failure keeps the pending order for resume',
      () async {
    repo.orderResult = testOrder();
    repo.verifyOutcomes.add(dioApiError(40012, message: 'receipt invalid'));
    store.buyResult = _purchased;
    final c = makeContainer();

    await orchOf(c).purchase(testProduct());
    await pumpEventQueue();

    expect((stateOf(c) as IapFailed).stage, PurchaseStage.verifying);
    expect(pending.all().length, 1);
    expect(store.completed, isEmpty);
  });

  test('verified but NOT granted (completed + grant_failed) → failed, '
      'native not finished, pending retained', () async {
    repo.orderResult = testOrder();
    repo.verifyOutcomes.add(grantFailedVerify());
    store.buyResult = _purchased;
    final c = makeContainer();

    await orchOf(c).purchase(testProduct());
    await pumpEventQueue();

    final failed = stateOf(c) as IapFailed;
    expect(failed.stage, PurchaseStage.verifying);
    // The verify status is telemetry-only detail, never user copy.
    expect(failed.failure.message, isEmpty);
    final props =
        telemetry.properties[telemetry.events.indexOf('purchase_fail')];
    expect(props!['diagnostic'], 'status=completed grant_status=failed');
    expect(store.completed, isEmpty); // must NOT finish — user would lose money
    expect(pending.all().length, 1); // retained so the reconciler re-verifies
  });

  test('verify returns a non-completed status (not thrown) → failed, retained',
      () async {
    repo.orderResult = testOrder();
    repo.verifyOutcomes.add(failedVerify());
    store.buyResult = _purchased;
    final c = makeContainer();

    await orchOf(c).purchase(testProduct());
    await pumpEventQueue();

    expect((stateOf(c) as IapFailed).stage, PurchaseStage.verifying);
    expect(store.completed, isEmpty);
    expect(pending.all().length, 1);
  });

  test('native error event → failed (awaitingNative), pending removed', () async {
    repo.orderResult = testOrder();
    store.buyResult = const StorePurchase(
      productId: _storeId,
      transactionId: 'tx-err',
      status: StorePurchaseStatus.error,
      error: 'payment declined',
    );
    final c = makeContainer();

    await orchOf(c).purchase(testProduct());
    await pumpEventQueue();

    final failed = stateOf(c) as IapFailed;
    expect(failed.stage, PurchaseStage.awaitingNative);
    // The raw plugin diagnostic must never surface as user copy (it is English
    // and unlocalized); it travels to telemetry via the funnel instead.
    expect(failed.failure.message, isEmpty);
    final props =
        telemetry.properties[telemetry.events.indexOf('purchase_fail')];
    expect(props!['diagnostic'], 'payment declined');
    expect(pending.all(), isEmpty); // store error, no transaction → removed
    expect(store.completed, isEmpty);
  });

  test('retryable verify (40912 twice) then success', () async {
    repo.orderResult = testOrder();
    repo.verifyOutcomes
        .addAll([dioApiError(40912), dioApiError(40912), completedVerify()]);
    store.buyResult = _purchased;
    final c = makeContainer(
      backoff: const [Duration(milliseconds: 1), Duration(milliseconds: 1)],
    );

    await orchOf(c).purchase(testProduct());
    await pumpEventQueue();

    expect(stateOf(c), isA<IapCompleted>());
    expect(repo.verifyCalls, 3);
  });

  test('40011 (transaction already used) is treated as completed', () async {
    repo.orderResult = testOrder();
    repo.verifyOutcomes.add(dioApiError(40011, message: 'tx used'));
    store.buyResult = _purchased;
    final c = makeContainer();

    await orchOf(c).purchase(testProduct());
    await pumpEventQueue();

    expect(stateOf(c), isA<IapCompleted>());
    expect(store.completed.single.transactionId, 'tx1');
    expect(pending.all(), isEmpty);
  });

  test('network timeout during verify then success', () async {
    repo.orderResult = testOrder();
    repo.verifyOutcomes.addAll([dioTimeout(), completedVerify()]);
    store.buyResult = _purchased;
    final c = makeContainer(backoff: const [Duration(milliseconds: 1)]);

    await orchOf(c).purchase(testProduct());
    await pumpEventQueue();

    expect(stateOf(c), isA<IapCompleted>());
  });

  test('a second purchase while one is in flight is ignored', () async {
    repo.orderResult = testOrder();
    store.buyGate = Completer<void>(); // hold the first in awaitingNative
    final c = makeContainer();

    final first = orchOf(c).purchase(testProduct());
    await pumpEventQueue();
    expect(stateOf(c), isA<IapAwaitingNative>());

    await orchOf(c).purchase(testProduct()); // guarded → ignored
    expect(stateOf(c), isA<IapAwaitingNative>());

    store.buyGate!.complete(); // buy returns; no event → silent cancel
    await first;
    expect(stateOf(c), isA<IapCancelled>());
  });

  test('a native call that never answers fails (awaitingNative), pending '
      'RETAINED, and a late success is still reconciled', () async {
    repo.orderResult = testOrder();
    repo.verifyOutcomes.add(completedVerify());
    store.buyGate = Completer<void>(); // the native sheet never answers
    final c = makeContainer(nativeTimeout: const Duration(milliseconds: 20));

    await orchOf(c).purchase(testProduct());

    final state = stateOf(c);
    expect(state, isA<IapFailed>());
    expect((state as IapFailed).stage, PurchaseStage.awaitingNative);
    expect(state.isInProgress, isFalse); // the paywall is usable again
    expect(pending.all().length, 1);
    expect(
      telemetry.properties[telemetry.events.indexOf('purchase_fail')],
      containsPair('diagnostic', 'native_timeout'),
    );

    // StoreKit completes after all: the reconciler verifies the late event.
    store.emit(const StorePurchase(
      productId: _storeId,
      transactionId: 'late-tx',
      status: StorePurchaseStatus.purchased,
    ));
    await pumpEventQueue();
    expect(repo.verifyCalls, 1);
    expect(pending.all(), isEmpty);
  });

  group('restore (user-initiated, create-order → verify kernel)', () {
    const proStoreId = _storeId;
    const weeklyStoreId = 'org.example.weekly';

    Product proProduct() => const Product(
          productCode: 'pro_monthly',
          storeProductId: proStoreId,
          productName: 'Pro',
          kind: ProductKind.autoRenewable,
          priceCents: 998,
          currency: 'USD',
        );
    Product weeklyProduct() => const Product(
          productCode: 'weekly',
          storeProductId: weeklyStoreId,
          productName: 'Weekly',
          kind: ProductKind.autoRenewable,
          priceCents: 199,
          currency: 'USD',
        );
    StorePurchase restoredTx(String txId, {String storeId = proStoreId}) =>
        StorePurchase(
          productId: storeId,
          transactionId: txId,
          status: StorePurchaseStatus.restored,
        );

    test('restoring is set before the first await', () async {
      final c = makeContainer(catalog: [proProduct()]);

      final future = orchOf(c).restorePurchases();
      expect(stateOf(c), isA<IapRestoring>());
      await future;

      expect(store.restoreCalls, 1);
    });

    test('restores N transactions via create-order → verify → IapRestored(N)',
        () async {
      repo.orderResult = testOrder();
      repo.verifyOutcomes.add(completedVerify());
      store.restoreEmits = [
        restoredTx('rtx-1'),
        restoredTx('rtx-2', storeId: weeklyStoreId),
      ];
      final c = makeContainer(catalog: [proProduct(), weeklyProduct()]);

      await orchOf(c).restorePurchases();
      await pumpEventQueue();

      final state = stateOf(c);
      expect(state, isA<IapRestored>());
      expect((state as IapRestored).restoredCount, 2);
      expect(repo.verifyCalls, 2);
      expect(store.completed.length, 2);
      expect(walletFetches, greaterThanOrEqualTo(2));
    });

    test('restored transactions run create-order → verify strictly in sequence',
        () async {
      repo.orderResult = testOrder();
      repo.verifyOutcomes.add(completedVerify());
      store.restoreEmits = [
        restoredTx('rtx-1'),
        restoredTx('rtx-2', storeId: weeklyStoreId),
      ];
      final c = makeContainer(catalog: [proProduct(), weeklyProduct()]);

      await orchOf(c).restorePurchases();
      await pumpEventQueue();

      // A concurrent burst interleaves as [order, order, verify, verify];
      // serialization is load-bearing: createOrder has no retry/back-off, so a
      // same-account burst trips the backend's 40912/rate-limit rejections,
      // and only a serialized duplicate lands on the idempotent 40011 path.
      expect(repo.callLog, ['order', 'verify', 'order', 'verify']);
    });

    test('nothing to restore → IapRestored(0)', () async {
      store.restoreEmits = const [];
      final c = makeContainer(catalog: [proProduct()]);

      await orchOf(c).restorePurchases();
      await pumpEventQueue();

      expect((stateOf(c) as IapRestored).restoredCount, 0);
    });

    test('40011 (already used by another order) counts as restored', () async {
      repo.orderResult = testOrder();
      repo.verifyOutcomes.add(dioApiError(40011));
      store.restoreEmits = [restoredTx('rtx-1')];
      final c = makeContainer(catalog: [proProduct()]);

      await orchOf(c).restorePurchases();
      await pumpEventQueue();

      expect((stateOf(c) as IapRestored).restoredCount, 1);
      expect(store.completed.single.transactionId, 'rtx-1');
    });

    test('a verify failure leaves that transaction unfinished and uncounted',
        () async {
      repo.orderResult = testOrder();
      repo.verifyOutcomes.add(failedVerify());
      store.restoreEmits = [restoredTx('rtx-1')];
      final c = makeContainer(catalog: [proProduct()]);

      await orchOf(c).restorePurchases();
      await pumpEventQueue();

      expect((stateOf(c) as IapRestored).restoredCount, 0);
      expect(store.completed, isEmpty); // retryable on a later restore
    });

    test('catalog-unresolved restored product is finished as fallback (no verify)',
        () async {
      store.restoreEmits = [restoredTx('rtx-x', storeId: 'unknown.product')];
      final c = makeContainer(catalog: [proProduct()]);

      await orchOf(c).restorePurchases();
      await pumpEventQueue();

      expect((stateOf(c) as IapRestored).restoredCount, 1);
      expect(store.completed.single.transactionId, 'rtx-x');
      expect(repo.verifyCalls, 0); // no order created → no verify
    });

    test('restore() failure → IapFailed(restoring)', () async {
      store.restoreThrows = StateError('restore boom');
      final c = makeContainer(catalog: [proProduct()]);

      await orchOf(c).restorePurchases();

      expect(store.restoreCalls, 1);
      final state = stateOf(c);
      expect(state, isA<IapFailed>());
      expect((state as IapFailed).stage, PurchaseStage.restoring);
    });

    test('one transaction whose finish throws neither aborts the batch nor '
        'strands the state in restoring', () async {
      repo.orderResult = testOrder();
      repo.verifyOutcomes.add(completedVerify());
      store.restoreEmits = [
        restoredTx('rtx-bad'),
        restoredTx('rtx-ok', storeId: weeklyStoreId),
      ];
      store.completeThrowsFor = {'rtx-bad'};
      final c = makeContainer(catalog: [proProduct(), weeklyProduct()]);

      await orchOf(c).restorePurchases();
      await pumpEventQueue();

      final state = stateOf(c);
      expect(state, isA<IapRestored>()); // not stuck in IapRestoring
      expect((state as IapRestored).restoredCount, 1); // only the good one
      expect(store.completed.single.transactionId, 'rtx-ok');
    });

    test('emits restore_start → restore_success funnel', () async {
      repo.orderResult = testOrder();
      repo.verifyOutcomes.add(completedVerify());
      store.restoreEmits = [restoredTx('rtx-1')];
      final c = makeContainer(catalog: [proProduct()]);

      await orchOf(c).restorePurchases();
      await pumpEventQueue();

      expect(
        telemetry.events,
        containsAllInOrder(['restore_start', 'restore_success']),
      );
    });

    test('a restore while a flow is in progress is ignored', () async {
      repo.orderResult = testOrder();
      store.buyGate = Completer<void>();
      final c = makeContainer(catalog: [proProduct()]);

      final purchasing = orchOf(c).purchase(testProduct());
      await pumpEventQueue();
      expect(stateOf(c).isInProgress, isTrue);

      await orchOf(c).restorePurchases(); // guarded out
      expect(store.restoreCalls, 0);

      store.buyGate!.complete();
      await purchasing;
    });
  });
}
