import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

import '../domain/auth_phase.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/jwt.dart';
import 'auth_providers.dart';

/// Owns the session and drives [AuthPhase]. Also the concrete [AuthGateway] the
/// network layer calls for the bearer token, refresh and force-logout.
///
/// The token pair is held privately (not in the observable state). Every
/// network call here uses the no-auth Dio, so this controller never depends on
/// `apiDio` (which depends back on the gateway).
class AuthController extends Notifier<AuthPhase> implements AuthGateway {
  static const String _kIsGuest = 'session.is_guest';
  static const String _kUserId = 'session.user_id';

  TokenBundle? _session;
  Completer<bool>? _refreshing;

  @override
  AuthPhase build() => const AuthIdle();

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  SecureTokenStore get _store => ref.read(secureTokenStoreProvider);
  KeyValueStore get _kv => ref.read(keyValueStoreProvider);
  DeviceInfoService get _device => ref.read(deviceInfoServiceProvider);
  EnvConfig get _env => ref.read(envConfigProvider);
  ErrorHandler get _errors => ref.read(errorHandlerProvider);

  /// In-memory session (token pair + identity), null when unauthenticated.
  TokenBundle? get session => _session;

  @override
  String? get accessToken => _session?.accessToken;

  /// Three-lines-of-defence: valid token → refresh → guest-register.
  Future<void> ensureAuthenticated() async {
    if (_session != null && !JwtUtils.isExpired(_session!.accessToken)) return;
    try {
      final restored = await _restore();
      if (restored != null) {
        if (!JwtUtils.isExpired(restored.accessToken)) {
          _apply(restored);
          return;
        }
        _session = restored; // make the refresh token available to refresh()
        // 防线②: only attempt /auth/refresh when the refresh token isn't
        // *provably* expired. Opaque (non-JWT) refresh tokens fall through and
        // are still tried; a provably-expired one skips straight to 防线③.
        if (!JwtUtils.isProvablyExpired(restored.refreshToken) &&
            await refresh()) {
          return;
        }
      }
      await _guestRegister();
    } on Object catch (error, stackTrace) {
      _session = null;
      state = AuthError(_errors.handle(error, stackTrace));
      rethrow;
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthRegistering();
    try {
      await _establish(
        await _repo.login(username: username, password: password),
      );
    } on Object catch (error, stackTrace) {
      final failure = _errors.handle(error, stackTrace);
      state = AuthError(failure);
      throw failure;
    }
  }

  Future<void> logout() async {
    final token = _session?.accessToken;
    if (token != null) {
      try {
        await _repo.logout(token);
      } on Object {
        // Best-effort: clear the local session even if the call fails.
      }
    }
    await forceLogout();
  }

  Future<void> logoutAll() async {
    final token = _session?.accessToken;
    if (token != null) {
      try {
        await _repo.logoutAll(token);
      } on Object {
        // Best-effort, as above.
      }
    }
    await forceLogout();
  }

  @override
  Future<bool> refresh() async {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<bool>();
    _refreshing = completer;
    bool result;
    try {
      final refreshToken =
          _session?.refreshToken ?? await _store.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        result = false;
      } else {
        await _establish(await _repo.refresh(refreshToken));
        result = true;
      }
    } on Object {
      result = false;
    } finally {
      _refreshing = null;
    }
    completer.complete(result);
    return result;
  }

  @override
  Future<void> forceLogout() async {
    _session = null;
    await _store.clearTokens(); // keeps the device id
    await _kv.remove(_kIsGuest);
    await _kv.remove(_kUserId);
    state = const AuthIdle();
  }

  /// Deletes the current **guest** account (App Review 5.1.1(v), guest
  /// lifecycle) and immediately establishes a fresh one.
  ///
  /// The guest contract is anchored to the Keychain `device_id` — registration
  /// is idempotent per id — so destroying the tokens **and the device id**
  /// makes this account permanently unreachable by anyone: that is the
  /// client-side deletion for a guest-only product. The device-info cache is
  /// reset before re-registering so the new request carries a freshly minted
  /// id (a stale cache would silently resurrect the deleted guest). Server-side
  /// data of the orphaned guest is retired by the backend's own lifecycle; when
  /// the dedicated delete endpoint lands (BACKEND_COORDINATION §8), its call
  /// belongs at the top of this method, before the local wipe.
  ///
  /// The wipe itself is local and effectively infallible; only the follow-up
  /// re-registration needs the network. On its failure the error state is set
  /// and rethrown — the action is safe to retry end-to-end (wiping again is a
  /// no-op, registration is attempted anew).
  Future<void> deleteAccount() async {
    _session = null;
    await _store.clearTokens();
    await _store.deleteDeviceId();
    _device.reset();
    ref.invalidate(deviceProfileProvider);
    await _kv.remove(_kIsGuest);
    await _kv.remove(_kUserId);
    state = const AuthIdle();
    await ensureAuthenticated(); // mints a brand-new guest on the new device id
  }

  Future<void> _guestRegister() async {
    state = const AuthRegistering();
    await _device.load(); // ensures the persistent device id exists
    final bundle = await _repo.guestRegister(
      AppDescriptor(
        distributionCode: _env.distributionCode,
        appCode: _env.appCode,
        bundleId: _env.bundleId,
        channel: _env.iapChannel,
      ),
    );
    await _establish(bundle);
    if (bundle.isNewUser) {
      // The only unrecoverable exit in the token decision tree: a fresh guest
      // means the device_id idempotency anchor was lost/changed.
      debugPrint(
        '[auth] guest-register minted a NEW guest (is_new_user=true): any prior '
        'guest is unrecoverable if the device id changed.',
      );
    }
  }

  Future<TokenBundle?> _restore() async {
    final tokens = await _store.readTokens();
    if (tokens == null) return null;
    final claims = JwtUtils.decode(tokens.accessToken);
    return TokenBundle(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      userId: _kv.getString(_kUserId) ?? claims.subject ?? '',
      isGuest: _kv.getBool(_kIsGuest) ?? false,
      expiresAt: claims.expiresAt,
    );
  }

  /// Activates an already-persisted session (restore path).
  void _apply(TokenBundle bundle) {
    _session = bundle;
    state = AuthAuthenticated(
      userId: bundle.userId,
      isGuest: bundle.isGuest,
      isNewUser: bundle.isNewUser,
    );
  }

  /// Persists then activates a freshly minted session.
  Future<void> _establish(TokenBundle bundle) async {
    await _persist(bundle);
    _apply(bundle);
  }

  Future<void> _persist(TokenBundle bundle) async {
    await _store.writeTokens(
      TokenPair(
        accessToken: bundle.accessToken,
        refreshToken: bundle.refreshToken,
      ),
    );
    await _kv.setBool(_kIsGuest, value: bundle.isGuest);
    await _kv.setString(_kUserId, bundle.userId);
  }
}
