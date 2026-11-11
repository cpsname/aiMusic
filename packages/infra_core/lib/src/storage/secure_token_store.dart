import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';

/// An access/refresh token pair.
@immutable
class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Secure (Keychain / KeyStore) storage for the JWT pair and the persistent
/// device id.
///
/// The device id lives here precisely because it must survive app reinstalls
/// (iOS Keychain persistence) — losing it creates an unrecoverable new guest.
/// [clearTokens] therefore clears the tokens but deliberately keeps the device
/// id intact.
class SecureTokenStore {
  SecureTokenStore(this._storage);

  /// Default instance with Keychain accessibility tuned for background reads.
  factory SecureTokenStore.withDefaults() => SecureTokenStore(
        const FlutterSecureStorage(
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
          mOptions: MacOsOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        ),
      );

  static const String _kAccess = 'auth.access_token';
  static const String _kRefresh = 'auth.refresh_token';
  static const String _kDeviceId = 'device.id';

  final FlutterSecureStorage _storage;

  Future<TokenPair?> readTokens() async {
    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    if (access == null || refresh == null) return null;
    return TokenPair(accessToken: access, refreshToken: refresh);
  }

  Future<String?> readAccessToken() => _storage.read(key: _kAccess);

  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  Future<void> writeTokens(TokenPair tokens) async {
    await _storage.write(key: _kAccess, value: tokens.accessToken);
    await _storage.write(key: _kRefresh, value: tokens.refreshToken);
  }

  /// Clears the JWT pair only. The device id is preserved on purpose.
  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  Future<String?> readDeviceId() => _storage.read(key: _kDeviceId);

  Future<void> writeDeviceId(String deviceId) =>
      _storage.write(key: _kDeviceId, value: deviceId);

  /// Destroys the persistent device id — the guest account's identity anchor.
  ///
  /// **Account deletion only.** Guest registration is idempotent per device id,
  /// so deleting it makes the current guest permanently unreachable (the next
  /// register mints a brand-new guest). Every other flow — logout included —
  /// must go through [clearTokens], which preserves the id on purpose.
  Future<void> deleteDeviceId() => _storage.delete(key: _kDeviceId);
}
