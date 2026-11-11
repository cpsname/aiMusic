import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/iap_fakes.dart';

DeviceProfile _profile(String version) => DeviceProfile(
  deviceId: 'dev-1',
  platform: 'ios',
  osVersion: '18.0',
  deviceModel: 'iPhone',
  appVersion: version,
  appBuild: '1',
);

AppInitData _sampleInit() => const AppInitData(
  products: [
    Product(
      productCode: 'pro',
      storeProductId: 'com.example.pro',
      productName: 'Pro',
      kind: ProductKind.autoRenewable,
      priceCents: 998,
      currency: 'USD',
    ),
  ],
  legal: LegalInfo(
    privacyUrl: 'https://example.com/privacy',
    termsUrl: 'https://example.com/terms',
  ),
);

class _Language extends Notifier<String> {
  @override
  String build() => 'en';
  void select(String value) => state = value;
}

final _language = NotifierProvider<_Language, String>(_Language.new);

class _QueuedRepo extends FakeIapRepository {
  final requests = <Completer<AppInitData>>[];
  @override
  Future<AppInitData> appInit({String? clientVersion}) {
    final request = Completer<AppInitData>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('infra_core/device');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  int? bootMillis;
  late FakeIapRepository repo;
  late KeyValueStore store;

  setUp(() async {
    bootMillis = 1700000000000;
    messenger.setMockMethodCallHandler(channel, (call) async => bootMillis);
    repo = FakeIapRepository()..appInitResult = _sampleInit();
    SharedPreferences.setMockInitialValues({});
    store = KeyValueStore(await SharedPreferences.getInstance());
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  ProviderContainer makeContainer({String version = '1.0.0'}) {
    final container = ProviderContainer(
      overrides: [
        iapRepositoryProvider.overrideWithValue(repo),
        keyValueStoreProvider.overrideWithValue(store),
        deviceProfileProvider.overrideWith((ref) async => _profile(version)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'language changes discard obsolete responses and reuse only their own cache',
    () async {
      final queued = _QueuedRepo();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          iapRepositoryProvider.overrideWithValue(queued),
          keyValueStoreProvider.overrideWithValue(store),
          deviceProfileProvider.overrideWith((ref) async => _profile('1.0.0')),
          languageTagProvider.overrideWith((ref) => ref.watch(_language)),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(appInitProvider, (_, _) {});
      addTearDown(subscription.close);
      Future<void> flush() async {
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      await flush();
      expect(queued.requests, hasLength(1));
      container.read(_language.notifier).select('de');
      await flush();
      expect(queued.requests, hasLength(2));
      const german = AppInitData(
        products: [],
        legal: LegalInfo(termsUrl: 'https://example.com/de'),
      );
      queued.requests[1].complete(german);
      expect(await container.read(appInitProvider.future), same(german));
      queued.requests[0].complete(_sampleInit());
      await flush();
      expect(container.read(appInitProvider).requireValue, same(german));
      final cache = container.read(appInitCacheProvider);
      expect(await cache.read(appVersion: '1.0.0', languageTag: 'en'), isNull);
      expect(
        (await cache.read(
          appVersion: '1.0.0',
          languageTag: 'de',
        ))!.legal.termsUrl,
        german.legal.termsUrl,
      );
      container.read(_language.notifier).select('ja');
      await flush();
      expect(queued.requests, hasLength(3));
      queued.requests[2].complete(_sampleInit());
      await container.read(appInitProvider.future);
      container.read(_language.notifier).select('de');
      expect(
        (await container.read(appInitProvider.future)).legal.termsUrl,
        german.legal.termsUrl,
      );
      expect(queued.requests, hasLength(3));
    },
  );

  test('first launch: cache miss → fetch /app/init and persist it', () async {
    final data = await makeContainer().read(appInitProvider.future);

    expect(repo.appInitCalls, 1);
    expect(data.products.single.productCode, 'pro');
  });

  test(
    'second launch in the same boot session → served from cache, no fetch',
    () async {
      await makeContainer().read(appInitProvider.future);
      expect(repo.appInitCalls, 1);

      // A fresh container (app relaunch) reads the persisted cache.
      await makeContainer().read(appInitProvider.future);
      expect(repo.appInitCalls, 1); // unchanged → no second /app/init
    },
  );

  test('after a device reboot → /app/init is fetched again', () async {
    await makeContainer().read(appInitProvider.future);
    expect(repo.appInitCalls, 1);

    bootMillis = bootMillis! + 60000; // reboot → different boot instant
    await makeContainer().read(appInitProvider.future);
    expect(repo.appInitCalls, 2);
  });

  test('after an app upgrade → /app/init is fetched again', () async {
    await makeContainer().read(appInitProvider.future); // default 1.0.0
    expect(repo.appInitCalls, 1);

    await makeContainer(version: '1.1.0').read(appInitProvider.future);
    expect(repo.appInitCalls, 2);
  });

  test('legalInfoProvider exposes the saved legal links', () async {
    final container = makeContainer();
    await container.read(appInitProvider.future);

    expect(
      container.read(legalInfoProvider)?.privacyUrl,
      'https://example.com/privacy',
    );
  });
}
