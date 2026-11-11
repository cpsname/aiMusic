import 'package:commerce_kit/commerce_kit.dart';
import 'package:commerce_kit/src/iap/data/app_init_cache.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppInitData _sampleInit() => const AppInitData(
      products: [
        Product(
          productCode: 'pro',
          storeProductId: 'com.example.pro',
          productName: 'Pro',
          kind: ProductKind.autoRenewable,
          priceCents: 998,
          currency: 'USD',
          billingCycle: 'monthly',
          trialDays: 7,
          highlightTag: 'Best value',
          sortOrder: 2,
        ),
      ],
      legal: LegalInfo(
        privacyUrl: 'https://example.com/privacy',
        termsUrl: 'https://example.com/terms',
        subscriptionTermsUrl: 'https://example.com/sub',
      ),
      update: UpdateInfo(forceUpdate: false, latestVersion: '2.0.0'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('infra_core/device');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  int? bootMillis;
  late KeyValueStore store;

  setUp(() async {
    bootMillis = 1700000000000;
    messenger.setMockMethodCallHandler(channel, (call) async => bootMillis);
    SharedPreferences.setMockInitialValues({});
    store = KeyValueStore(await SharedPreferences.getInstance());
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  AppInitCache cache() =>
      AppInitCache(store: store, bootClock: const DeviceBootClock());

  test('empty store → miss', () async {
    expect(await cache().read(appVersion: '1.0.0'), isNull);
  });

  test('language caches are isolated, including legacy entries', () async {
    final c = cache();
    await c.write(_sampleInit(), appVersion: '1.0.0');
    expect(await c.read(appVersion: '1.0.0', languageTag: 'de'), isNull);
    await c.write(_sampleInit(), appVersion: '1.0.0', languageTag: 'de');
    expect(await c.read(appVersion: '1.0.0', languageTag: 'de'), isNotNull);
    expect(await c.read(appVersion: '1.0.0', languageTag: 'ja'), isNull);
    await c.clear(languageTag: 'de');
    expect(await c.read(appVersion: '1.0.0', languageTag: 'de'), isNull);
    expect(await c.read(appVersion: '1.0.0'), isNotNull);
  });

  test('write then read in the same boot session → hit, round-trips '
      'products + legal + update', () async {
    final c = cache();
    await c.write(_sampleInit(), appVersion: '1.0.0');

    final got = await c.read(appVersion: '1.0.0');
    expect(got, isNotNull);
    final product = got!.products.single;
    expect(product.productCode, 'pro');
    expect(product.kind, ProductKind.autoRenewable);
    expect(product.trialDays, 7);
    expect(product.highlightTag, 'Best value');
    expect(got.legal.privacyUrl, 'https://example.com/privacy');
    expect(got.legal.subscriptionTermsUrl, 'https://example.com/sub');
    expect(got.update?.latestVersion, '2.0.0');
  });

  test('device reboot (boot instant changed beyond tolerance) → miss',
      () async {
    final c = cache();
    await c.write(_sampleInit(), appVersion: '1.0.0');

    bootMillis = bootMillis! + 60000; // +60s → a different boot session
    expect(await c.read(appVersion: '1.0.0'), isNull);
  });

  test('small clock jitter within tolerance → still a hit', () async {
    final c = cache();
    await c.write(_sampleInit(), appVersion: '1.0.0');

    bootMillis = bootMillis! + 3000; // +3s ≤ 5s tolerance
    expect(await c.read(appVersion: '1.0.0'), isNotNull);
  });

  test('app upgrade (version changed) → miss', () async {
    final c = cache();
    await c.write(_sampleInit(), appVersion: '1.0.0');
    expect(await c.read(appVersion: '1.1.0'), isNull);
  });

  test('undetectable boot at read → miss (safe refetch)', () async {
    final c = cache();
    await c.write(_sampleInit(), appVersion: '1.0.0');

    bootMillis = null;
    expect(await c.read(appVersion: '1.0.0'), isNull);
  });

  test('undetectable boot at write → nothing cached', () async {
    bootMillis = null;
    await cache().write(_sampleInit(), appVersion: '1.0.0');

    bootMillis = 1700000000000;
    expect(await cache().read(appVersion: '1.0.0'), isNull);
  });

  test('clear removes the entry', () async {
    final c = cache();
    await c.write(_sampleInit(), appVersion: '1.0.0');
    await c.clear();
    expect(await c.read(appVersion: '1.0.0'), isNull);
  });
}
