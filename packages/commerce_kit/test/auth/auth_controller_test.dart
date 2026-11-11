import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/auth_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository repo;
  late FakeSecureTokenStore store;
  late SharedPreferences prefs;

  setUp(() async {
    repo = FakeAuthRepository();
    store = FakeSecureTokenStore();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        secureTokenStoreProvider.overrideWithValue(store),
        keyValueStoreProvider.overrideWithValue(KeyValueStore(prefs)),
        deviceInfoServiceProvider.overrideWithValue(fakeDeviceInfoService(store)),
        envConfigProvider.overrideWithValue(testEnv),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  final freshToken = makeJwt(exp: DateTime.utc(2035));

  group('ensureAuthenticated — three lines of defence', () {
    test('no stored tokens → guest-register', () async {
      repo.guestResult = bundle(access: freshToken, isGuest: true, userId: 'g1');
      final container = makeContainer();
      final controller = container.read(authControllerProvider.notifier);

      await controller.ensureAuthenticated();

      expect(repo.guestCalls, 1);
      expect(repo.refreshCalls, 0);
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).isGuest, isTrue);
      expect(controller.accessToken, freshToken);
    });

    test('valid stored token → used directly, no network', () async {
      store = FakeSecureTokenStore(
        tokens: TokenPair(accessToken: freshToken, refreshToken: 'r'),
      );
      final container = makeContainer();

      await container.read(authControllerProvider.notifier).ensureAuthenticated();

      expect(repo.guestCalls, 0);
      expect(repo.refreshCalls, 0);
      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
    });

    test('expired token + working refresh → refresh, no registration', () async {
      store = FakeSecureTokenStore(
        tokens: TokenPair(
          accessToken: makeJwt(exp: DateTime.utc(2000)),
          refreshToken: 'r',
        ),
      );
      repo.refreshResult = bundle(access: freshToken);
      final container = makeContainer();

      await container.read(authControllerProvider.notifier).ensureAuthenticated();

      expect(repo.refreshCalls, 1);
      expect(repo.guestCalls, 0);
      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
    });

    test('expired token + failed refresh → falls back to guest-register',
        () async {
      store = FakeSecureTokenStore(
        tokens: TokenPair(
          accessToken: makeJwt(exp: DateTime.utc(2000)),
          refreshToken: 'r',
        ),
      );
      repo.refreshError =
          const AuthApiError(code: 40106, message: 'reused', requiresForceLogout: true);
      repo.guestResult = bundle(access: freshToken, isGuest: true);
      final container = makeContainer();

      await container.read(authControllerProvider.notifier).ensureAuthenticated();

      expect(repo.refreshCalls, 1);
      expect(repo.guestCalls, 1);
      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
    });

    test('防线②: a provably-expired refresh token skips refresh → register',
        () async {
      store = FakeSecureTokenStore(
        tokens: TokenPair(
          accessToken: makeJwt(exp: DateTime.utc(2000)),
          refreshToken: makeJwt(exp: DateTime.utc(2000)), // decodable + past
        ),
      );
      repo.guestResult = bundle(access: freshToken, isGuest: true);
      final container = makeContainer();

      await container.read(authControllerProvider.notifier).ensureAuthenticated();

      expect(repo.refreshCalls, 0); // doomed /auth/refresh skipped
      expect(repo.guestCalls, 1); // straight to 防线③
    });

    test('guest-register surfaces is_new_user (unrecoverable-exit signal)',
        () async {
      repo.guestResult =
          bundle(access: freshToken, isGuest: true, isNewUser: true);
      final container = makeContainer();

      await container.read(authControllerProvider.notifier).ensureAuthenticated();

      final state = container.read(authControllerProvider) as AuthAuthenticated;
      expect(state.isNewUser, isTrue);
    });
  });

  test('concurrent refresh() calls are single-flighted', () async {
    store = FakeSecureTokenStore(
      tokens: TokenPair(accessToken: 'old', refreshToken: 'r'),
    );
    repo.refreshResult = bundle(access: freshToken);
    final controller = makeContainer().read(authControllerProvider.notifier);

    final results = await Future.wait([controller.refresh(), controller.refresh()]);

    expect(results, [true, true]);
    expect(repo.refreshCalls, 1);
  });

  group('login / logout', () {
    test('login success authenticates', () async {
      repo.loginResult = bundle(access: freshToken, userId: 'alice');
      final container = makeContainer();

      await container
          .read(authControllerProvider.notifier)
          .login(username: 'alice', password: 'pw');

      final state = container.read(authControllerProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).isGuest, isFalse);
    });

    test('login failure surfaces a Failure and sets AuthError', () async {
      repo.loginError = const AuthApiError(
        code: 40101,
        message: 'bad credentials',
        requiresForceLogout: false,
      );
      final container = makeContainer();
      final controller = container.read(authControllerProvider.notifier);

      await expectLater(
        controller.login(username: 'alice', password: 'wrong'),
        throwsA(isA<Failure>()),
      );
      expect(container.read(authControllerProvider), isA<AuthError>());
    });

    test('logout clears the session but preserves the device id', () async {
      repo.guestResult = bundle(access: freshToken, isGuest: true);
      final container = makeContainer();
      final controller = container.read(authControllerProvider.notifier);
      await controller.ensureAuthenticated();

      await controller.logout();

      expect(repo.logoutCalls, 1);
      expect(store.clearCalls, greaterThanOrEqualTo(1));
      expect(await store.readDeviceId(), 'device-1');
      expect(controller.accessToken, isNull);
      expect(container.read(authControllerProvider), isA<AuthIdle>());
    });
  });

  group('deleteAccount — guest lifecycle (5.1.1(v))', () {
    test('destroys tokens + device id and mints a brand-new guest', () async {
      store = FakeSecureTokenStore(
        tokens: TokenPair(accessToken: freshToken, refreshToken: 'r'),
      );
      repo.guestResult =
          bundle(access: freshToken, isGuest: true, userId: 'g2', isNewUser: true);
      final container = makeContainer();
      final controller = container.read(authControllerProvider.notifier);
      await controller.ensureAuthenticated();
      expect(repo.guestCalls, 0); // valid token — the old guest is live

      await controller.deleteAccount();

      // The identity anchor is gone (the deletion) and registration ran on a
      // freshly generated id — the old guest is unreachable by construction.
      expect(store.deviceIdDeletes, 1);
      expect(store.clearCalls, greaterThanOrEqualTo(1));
      expect(repo.guestCalls, 1);
      expect(store.deviceId, isNotNull);
      expect(store.deviceId, isNot('device-1'));
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).isGuest, isTrue);
    });

    test('re-registration failure: wipe stands, error state, retryable',
        () async {
      store = FakeSecureTokenStore(
        tokens: TokenPair(accessToken: freshToken, refreshToken: 'r'),
      );
      repo.guestError = StateError('offline');
      final container = makeContainer();
      final controller = container.read(authControllerProvider.notifier);

      await expectLater(controller.deleteAccount(), throwsA(isA<StateError>()));

      expect(store.deviceIdDeletes, 1);
      expect(await store.readTokens(), isNull);
      expect(container.read(authControllerProvider), isA<AuthError>());

      // The action is retryable end-to-end: wiping again is a no-op-equivalent,
      // registration is attempted anew.
      repo.guestError = null;
      repo.guestResult = bundle(access: freshToken, isGuest: true, userId: 'g3');
      await controller.deleteAccount();

      expect(repo.guestCalls, 2);
      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
    });
  });
}
