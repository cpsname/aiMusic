import 'package:commerce_kit/commerce_kit.dart';
import 'package:commerce_kit/src/iap/data/product_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

StoreProduct _sample() => StoreProduct(
  product: const Product(
    productCode: 'pro',
    storeProductId: 'com.example.pro',
    productName: 'Pro',
    kind: ProductKind.autoRenewable,
    priceCents: 5800,
    currency: 'CNY',
    highlightTag: 'Best',
  ),
  details: const StoreProductDetails(
    id: 'com.example.pro',
    title: 'Weekly Pro',
    description: 'desc',
    price: '¥58.00',
    rawPrice: 58,
    currencyCode: 'CNY',
    currencySymbol: '¥',
    subscriptionPeriod:
        SubscriptionPeriodValue(numberOfUnits: 1, unit: PeriodUnit.week),
    introductoryOffer: ProductOffer(
      type: OfferType.introductory,
      paymentMode: OfferPaymentMode.freeTrial,
      formattedPrice: '',
      rawPrice: 0,
      currencyCode: 'CNY',
      numberOfPeriods: 1,
      period: SubscriptionPeriodValue(numberOfUnits: 3, unit: PeriodUnit.day),
    ),
    promotionalOffers: [
      ProductOffer(
        identifier: 'promo',
        type: OfferType.promotional,
        paymentMode: OfferPaymentMode.payAsYouGo,
        formattedPrice: '¥29.00',
        rawPrice: 29,
        currencyCode: 'CNY',
        numberOfPeriods: 2,
        period: SubscriptionPeriodValue(numberOfUnits: 1, unit: PeriodUnit.week),
      ),
    ],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KeyValueStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = KeyValueStore(await SharedPreferences.getInstance());
  });

  test('empty cache → null', () {
    expect(ProductCache(store: store).read(), isNull);
  });

  test('localized catalog cache cannot fall back to another language', () async {
    final cache = ProductCache(store: store);
    await cache.write([_sample()], languageTag: 'de');
    expect(cache.read(languageTag: 'ja'), isNull);
    expect(cache.read(languageTag: 'de')!.products.single.displayPrice, '¥58.00');
  });

  test('write → read round-trips products, period, and offers', () async {
    final cache = ProductCache(store: store);
    await cache.write([_sample()]);

    final result = cache.read();
    expect(result, isNotNull);
    expect(result!.isFromCache, isTrue);
    expect(result.isStale, isFalse);

    final p = result.products.single;
    expect(p.productCode, 'pro');
    expect(p.displayName, 'Weekly Pro');
    expect(p.highlightTag, 'Best');
    expect(p.subscriptionPeriod?.displayLabel, '1 week');
    expect(p.hasFreeTrial, isTrue);
    expect(p.introductoryOffer?.period.displayLabel, '3 days');
    expect(p.promotionalOffers.single.formattedPrice, '¥29.00');
    expect(p.promotionalOffers.single.numberOfPeriods, 2);
  });

  test('reports stale once past the validity window', () async {
    var now = DateTime.utc(2026);
    final cache = ProductCache(store: store, now: () => now); // 24h default
    await cache.write([_sample()]);

    now = DateTime.utc(2026, 1, 2, 1); // +25h
    expect(cache.read()!.isStale, isTrue);
  });

  test('detects a currency mismatch (region change)', () async {
    final cache = ProductCache(store: store);
    await cache.write([_sample()]); // CNY

    expect(cache.isCurrencyMismatch('CNY'), isFalse);
    expect(cache.isCurrencyMismatch('USD'), isTrue);
  });

  test('clear removes the cache', () async {
    final cache = ProductCache(store: store);
    await cache.write([_sample()]);
    await cache.clear();
    expect(cache.read(), isNull);
  });
}
