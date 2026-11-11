import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/iap_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStoreClient store;
  late KeyValueStore kv;

  setUp(() async {
    store = FakeStoreClient();
    SharedPreferences.setMockInitialValues({});
    kv = KeyValueStore(await SharedPreferences.getInstance());
  });

  tearDown(() => store.dispose());

  Product item(String code, String storeId) => Product(
    productCode: code,
    storeProductId: storeId,
    productName: '',
    kind: ProductKind.autoRenewable,
    priceCents: 0,
    currency: 'USD',
  );

  StoreProductDetails detail(String storeId, String title) => StoreProductDetails(
    id: storeId,
    title: title,
    description: '',
    price: r'$1.00',
    rawPrice: 1,
    currencyCode: 'USD',
  );

  AppInitData init(List<Product> products) =>
      AppInitData(products: products, legal: const LegalInfo());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        appInitProvider.overrideWith(
          (ref) async => init([item('a', 'store.a'), item('b', 'store.b')]),
        ),
        storeClientProvider.overrideWithValue(store),
        keyValueStoreProvider.overrideWithValue(kv),
        iapClockProvider.overrideWithValue(() => DateTime.utc(2026)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('shows products the store resolves; drops the rest to unavailableIds',
      () async {
    store.queryResult = [detail('store.a', 'A')]; // store has A, not B
    final container = makeContainer();

    final products = await container.read(storeProductsProvider.future);

    expect(products.map((p) => p.productCode), ['a']);
    expect(products.single.displayName, 'A'); // live store title
    expect(container.read(unavailableProductIdsProvider), ['store.b']);
  });

  test('a store-query failure serves the last good cache (stale-flagged)',
      () async {
    // First launch: a successful query populates the cache.
    store.queryResult = [detail('store.a', 'A'), detail('store.b', 'B')];
    final first = await makeContainer().read(storeProductsProvider.future);
    expect(first.map((p) => p.productCode), ['a', 'b']);
    await pumpEventQueue(); // let the background cache write complete

    // Next launch: the store query throws → serve the cache.
    store
      ..queryResult = const []
      ..queryThrows = StateError('offline');
    final result =
        await makeContainer().read(storeCatalogQueryProvider.future);

    expect(result.isFromCache, isTrue);
    expect(result.products.map((p) => p.productCode), ['a', 'b']);
  });

  test('a store-query failure with no cache surfaces the error', () async {
    store.queryThrows = StateError('offline');
    final container = makeContainer();

    await expectLater(
      container.read(storeProductsProvider.future),
      throwsA(isA<StateError>()),
    );
  });
}
