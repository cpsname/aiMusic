import 'package:commerce_kit/commerce_kit.dart';
import 'package:commerce_kit/src/iap/data/pending_order_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/auth_fakes.dart' show testEnv;
import '../support/iap_fakes.dart';

const _storeId = 'com.example.pro_monthly';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeIapRepository repo;
  late FakeStoreClient store;
  late PendingOrderStore pending;
  late int walletFetches;

  setUp(() async {
    repo = FakeIapRepository();
    store = FakeStoreClient();
    SharedPreferences.setMockInitialValues({});
    pending = PendingOrderStore(KeyValueStore(await SharedPreferences.getInstance()));
    walletFetches = 0;
  });

  tearDown(() => store.dispose());

  ProviderContainer makeContainer({List<Product> catalog = const []}) {
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(testEnv),
        iapRepositoryProvider.overrideWithValue(repo),
        storeClientProvider.overrideWithValue(store),
        pendingOrderRepositoryProvider.overrideWithValue(pending),
        iapVerifyBackoffProvider.overrideWithValue(const <Duration>[]),
        iapCatalogProvider.overrideWithValue(catalog),
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

  Product subProduct(String storeId) => Product(
        productCode: 'sub_$storeId',
        storeProductId: storeId,
        productName: 'Sub',
        kind: ProductKind.autoRenewable,
        priceCents: 998,
        currency: 'USD',
      );
  Product consumableProduct(String storeId) => Product(
        productCode: 'coins_$storeId',
        storeProductId: storeId,
        productName: 'Coins',
        kind: ProductKind.consumable,
        priceCents: 99,
        currency: 'USD',
      );

  IapBackgroundReconciler start(ProviderContainer c) =>
      c.read(iapReconcilerProvider);

  test('re-delivered order → verify by orderNo → finish + refresh', () async {
    final container = makeContainer();
    await pending.save(
      PendingOrder(
        orderNo: 'ORD-9',
        productCode: 'pro_monthly',
        storeProductId: _storeId,
        createdAt: DateTime.utc(2026),
      ),
    );
    repo.verifyOutcomes.add(completedVerify('ORD-9'));
    start(container);

    store.emit(const StorePurchase(
      productId: _storeId,
      transactionId: 'tx-redelivered',
      status: StorePurchaseStatus.purchased,
    ));
    await pumpEventQueue();

    expect(store.completed.single.transactionId, 'tx-redelivered');
    expect(pending.all(), isEmpty);
    expect(repo.verifyCalls, 1);
    expect(walletFetches, greaterThanOrEqualTo(2));
  });

  group('finish policy on a pending order whose verify did NOT confirm a grant',
      () {
    Future<void> savePending(String orderNo, String storeId) => pending.save(
          PendingOrder(
            orderNo: orderNo,
            productCode: 'p',
            storeProductId: storeId,
            createdAt: DateTime.utc(2026),
          ),
        );

    test('subscription, verify THROWS → finish anyway + remove + refresh',
        () async {
      final container = makeContainer(catalog: [subProduct(_storeId)]);
      await savePending('ORD-S', _storeId);
      repo.verifyOutcomes.add(dioTimeout()); // exhausts → throws
      start(container);

      store.emit(const StorePurchase(
        productId: _storeId,
        transactionId: 'tx-sub',
        status: StorePurchaseStatus.purchased,
      ));
      await pumpEventQueue();

      // Restorable: acknowledged so StoreKit stops redelivering; entitlement is
      // server-truth (webhook) + recoverable via restore.
      expect(store.completed.single.transactionId, 'tx-sub');
      expect(pending.all(), isEmpty);
      expect(walletFetches, greaterThanOrEqualTo(2));
    });

    test('subscription, verify grant_failed → finish anyway + remove', () async {
      final container = makeContainer(catalog: [subProduct(_storeId)]);
      await savePending('ORD-S2', _storeId);
      repo.verifyOutcomes.add(grantFailedVerify('ORD-S2'));
      start(container);

      store.emit(const StorePurchase(
        productId: _storeId,
        transactionId: 'tx-sub2',
        status: StorePurchaseStatus.purchased,
      ));
      await pumpEventQueue();

      expect(store.completed.single.transactionId, 'tx-sub2');
      expect(pending.all(), isEmpty);
    });

    test('CONSUMABLE, verify fails → NOT finished, pending kept for recovery',
        () async {
      final container = makeContainer(catalog: [consumableProduct(_storeId)]);
      await savePending('ORD-C', _storeId);
      repo.verifyOutcomes.add(grantFailedVerify('ORD-C'));
      start(container);

      store.emit(const StorePurchase(
        productId: _storeId,
        transactionId: 'tx-coins',
        status: StorePurchaseStatus.purchased,
      ));
      await pumpEventQueue();

      // No webhook + not in currentEntitlements → redelivery is the only
      // recovery; must NOT finish before a confirmed grant.
      expect(store.completed, isEmpty);
      expect(pending.all().single.orderNo, 'ORD-C');
    });

    test('unknown product (not in catalog), verify fails → NOT finished',
        () async {
      final container = makeContainer(); // empty catalog → unresolved
      await savePending('ORD-U', _storeId);
      repo.verifyOutcomes.add(grantFailedVerify('ORD-U'));
      start(container);

      store.emit(const StorePurchase(
        productId: _storeId,
        transactionId: 'tx-unknown',
        status: StorePurchaseStatus.purchased,
      ));
      await pumpEventQueue();

      expect(store.completed, isEmpty); // safe default = treat as consumable
      expect(pending.all().single.orderNo, 'ORD-U');
    });
  });

  test('in-flight guard: duplicate redelivery → a single verify + finish',
      () async {
    final container = makeContainer(catalog: [subProduct(_storeId)]);
    await pending.save(
      PendingOrder(
        orderNo: 'ORD-DUP',
        productCode: 'p',
        storeProductId: _storeId,
        createdAt: DateTime.utc(2026),
      ),
    );
    repo.verifyOutcomes.add(completedVerify('ORD-DUP'));
    start(container);

    // Two deliveries of the same transaction in one batch.
    store.emit(const StorePurchase(
      productId: _storeId,
      transactionId: 'tx-dup',
      status: StorePurchaseStatus.purchased,
    ));
    store.emit(const StorePurchase(
      productId: _storeId,
      transactionId: 'tx-dup',
      status: StorePurchaseStatus.purchased,
    ));
    await pumpEventQueue();

    expect(repo.verifyCalls, 1); // not 2
    expect(store.completed.length, 1);
    expect(pending.all(), isEmpty);
  });

  test('renewal/restore (no local order) → finish + refresh, no verify',
      () async {
    final container = makeContainer();
    start(container);

    store.emit(const StorePurchase(
      productId: 'org.example.weekly',
      transactionId: 'renewal-tx',
      status: StorePurchaseStatus.purchased,
    ));
    await pumpEventQueue();

    expect(store.completed.single.transactionId, 'renewal-tx');
    expect(repo.verifyCalls, 0); // no order → server reconciles via webhook
    expect(walletFetches, greaterThanOrEqualTo(2));
  });

  test('a claimed product is handed to the awaiter, not reconciled', () async {
    final container = makeContainer();
    final reconciler = start(container);
    final claim = reconciler.awaitPurchase(_storeId);

    store.emit(const StorePurchase(
      productId: _storeId,
      transactionId: 'claimed-tx',
      status: StorePurchaseStatus.purchased,
    ));
    final event = await claim;

    expect(event.transactionId, 'claimed-tx');
    expect(store.completed, isEmpty); // not auto-finished — the orchestrator owns it
    expect(repo.verifyCalls, 0);
  });

  test(
      'unsolicited .restored (no restore session) → passive finish + refresh, '
      'NEVER creates an order', () async {
    final container = makeContainer();
    start(container);

    store.emit(const StorePurchase(
      productId: 'org.example.weekly',
      transactionId: 'restored-unsolicited',
      status: StorePurchaseStatus.restored,
    ));
    await pumpEventQueue();

    // Finished + refreshed (server-truth via webhook), but never turned into an
    // order — restore-via-order is only ever triggered by an explicit user call.
    expect(store.completed.single.transactionId, 'restored-unsolicited');
    expect(repo.verifyCalls, 0);
    expect(walletFetches, greaterThanOrEqualTo(2));
  });

  test(
      'beginRestore captures .restored events (deduped) instead of reconciling',
      () async {
    final container = makeContainer();
    final reconciler = start(container);
    reconciler.beginRestore();

    store.emit(const StorePurchase(
      productId: _storeId,
      transactionId: 'rtx-a',
      status: StorePurchaseStatus.restored,
    ));
    store.emit(const StorePurchase(
      productId: _storeId,
      transactionId: 'rtx-a', // duplicate delivery
      status: StorePurchaseStatus.restored,
    ));
    await pumpEventQueue();
    final collected = reconciler.endRestore();

    expect(collected.map((e) => e.transactionId), ['rtx-a']); // deduped
    expect(store.completed, isEmpty); // not auto-finished — the orchestrator owns it
    expect(repo.verifyCalls, 0);
    expect(reconciler.endRestore(), isEmpty); // window closed
  });

  test('pruneStalePendingOrders removes only orders older than 24h', () async {
    final container = makeContainer();
    final reconciler = start(container);
    await pending.save(
      PendingOrder(
        orderNo: 'OLD',
        productCode: 'p',
        storeProductId: 's1',
        createdAt: DateTime.utc(2020),
      ),
    );
    await pending.save(
      PendingOrder(
        orderNo: 'NEW',
        productCode: 'p',
        storeProductId: 's2',
        createdAt: DateTime.utc(2026),
      ),
    );

    await reconciler.pruneStalePendingOrders(now: DateTime.utc(2026, 1, 2));

    expect(pending.all().map((o) => o.orderNo), ['NEW']);
  });

  test('refreshEntitlement re-fetches the wallet', () async {
    final container = makeContainer();
    final reconciler = start(container);
    await pumpEventQueue();
    final before = walletFetches;

    reconciler.refreshEntitlement();
    await pumpEventQueue();

    expect(walletFetches, greaterThan(before));
  });
}
