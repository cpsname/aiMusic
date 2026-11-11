import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/auth_fakes.dart';
import '../support/iap_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Gate 0: a build with no injected `--dart-define-from-file` config. It must
  // fail before the guest-register call — that call would be answered `40110` /
  // `40114` / `40304` by the app-signature middleware, and presenting that as a
  // connection error is what once shipped to the App Store unnoticed.
  test('an unconfigured build fails startup without touching the network',
      () async {
    const unconfigured = EnvConfig(
      env: AppEnv.dev,
      baseUrl: '',
      distributionCode: '',
      distributionSecret: '',
      appCode: '',
      bundleId: '',
      iapChannel: 'appstore',
    );
    // No repository/store overrides on purpose: if startup reached any of them
    // the container would throw instead of settling on ConfigFailure.
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [envConfigProvider.overrideWithValue(unconfigured)],
    );
    addTearDown(container.dispose);

    await container.read(startupControllerProvider.notifier).start();

    final state = container.read(startupControllerProvider);
    expect(state, isA<StartupFailed>());
    final failure = (state as StartupFailed).failure;
    expect(failure, isA<ConfigFailure>());
    expect(
      (failure as ConfigFailure).missingKeys,
      containsAll(['BASE_URL', 'DISTRIBUTION_SECRET']),
    );
    // No retry button: nothing at runtime can inject a compile-time define.
    expect(failure.isRetryable, isFalse);
  });

  late FakeAuthRepository auth;
  late FakeSecureTokenStore tokenStore;
  late FakeStoreClient store;
  late SharedPreferences prefs;

  setUp(() async {
    auth = FakeAuthRepository()
      ..guestResult =
          bundle(access: makeJwt(exp: DateTime.utc(2035)), isGuest: true);
    tokenStore = FakeSecureTokenStore();
    store = FakeStoreClient();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => store.dispose());

  AppInitData appInitData({UpdateInfo? update}) =>
      AppInitData(products: const [], legal: const LegalInfo(), update: update);

  ProviderContainer makeContainer(Override appInit) {
    final container = ProviderContainer(
      // Mirror the app's ProviderScope: error states are terminal (no retry
      // loop), so a throwing appInit settles to StartupFailed deterministically.
      retry: (_, _) => null,
      overrides: [
        envConfigProvider.overrideWithValue(testEnv),
        sharedPreferencesProvider.overrideWith((ref) async => prefs),
        keyValueStoreProvider.overrideWithValue(KeyValueStore(prefs)),
        authRepositoryProvider.overrideWithValue(auth),
        secureTokenStoreProvider.overrideWithValue(tokenStore),
        deviceInfoServiceProvider
            .overrideWithValue(fakeDeviceInfoService(tokenStore)),
        storeClientProvider.overrideWithValue(store),
        iapRepositoryProvider.overrideWithValue(FakeIapRepository()),
        // Prefetches (fire-and-forget) — overridden so they don't hit the network.
        currentAccountProvider.overrideWith(
          (ref) async => const CurrentAccount(
            userId: 'u1',
            nickname: 'Guest',
            accountType: 'guest',
            role: 'user',
            status: 'active',
            isGuest: true,
            guidance: Guidance(
              needsProfileComplete: false,
              hasActiveSubscription: false,
              hasCredits: false,
            ),
          ),
        ),
        walletSnapshotProvider.overrideWith((ref) async => WalletSnapshot.empty),
        appInit,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('success → StartupReady, with auth established and no force-update',
      () async {
    final container =
        makeContainer(appInitProvider.overrideWith((ref) async => appInitData()));

    await container.read(startupControllerProvider.notifier).start();

    expect(container.read(startupControllerProvider), isA<StartupReady>());
    expect(auth.guestCalls, 1); // ensureAuthenticated ran (guest-register)
  });

  test('force-update gate → StartupForceUpdate', () async {
    final container = makeContainer(
      appInitProvider.overrideWith(
        (ref) async => appInitData(
          update: const UpdateInfo(forceUpdate: true, latestVersion: '9.9.9'),
        ),
      ),
    );

    await container.read(startupControllerProvider.notifier).start();

    final state = container.read(startupControllerProvider);
    expect(state, isA<StartupForceUpdate>());
    expect((state as StartupForceUpdate).update.latestVersion, '9.9.9');
  });

  test('app-init failure → StartupFailed', () async {
    final container = makeContainer(
      appInitProvider.overrideWith(
        (ref) async => throw const ServerFailure(message: 'boom'),
      ),
    );

    await container.read(startupControllerProvider.notifier).start();

    expect(container.read(startupControllerProvider), isA<StartupFailed>());
  });
}
