import 'package:commerce_kit/commerce_kit.dart';
import 'package:dio/dio.dart';
import 'package:infra_core/infra_core.dart';
import 'package:uuid/uuid.dart';

import '../../common/json.dart';
import '../../platform/domain/native_gateways.dart';

/// commerce_kit's [AuthRepository] for Songlet's account-less identity (PRD
/// §6.3 / D5): "guest registration" is an App Attest exchange at
/// `POST /v1/attest`, returning a device token (a JWT whose `abid` is the
/// `app_account_token`). [AuthController] keeps doing everything else —
/// persistence, the valid-token fast path, single-flight refresh (= a new
/// App Attest assertion) and the auth interceptor's refresh-and-replay.
///
/// `app_account_token` is the persistent Keychain device UUID (infra_core's
/// `DeviceInfoService`), which survives reinstalls; purchases carry it as the
/// StoreKit `appAccountToken`.
class AttestAuthRepository implements AuthRepository {
  AttestAuthRepository({
    required Dio authDio,
    required AttestationProvider attestation,
    required DeviceInfoService deviceInfo,
    DateTime Function()? now,
    Uuid uuid = const Uuid(),
  })  : _authDio = authDio,
        _attestation = attestation,
        _deviceInfo = deviceInfo,
        _now = now ?? DateTime.now,
        _uuid = uuid;

  /// The refresh "token": re-attesting needs no secret, only the device key.
  static const String refreshMarker = 'songlet.attest';

  final Dio _authDio;
  final AttestationProvider _attestation;
  final DeviceInfoService _deviceInfo;
  final DateTime Function() _now;
  final Uuid _uuid;

  @override
  Future<TokenBundle> guestRegister(AppDescriptor app) => _attest();

  @override
  Future<TokenBundle> refresh(String refreshToken) => _attest();

  /// Songlet has no user accounts (PRD §2.3 / D5).
  @override
  Future<TokenBundle> login({required String username, required String password}) =>
      Future<TokenBundle>.error(UnsupportedError('Songlet has no accounts'));

  @override
  Future<void> logout(String accessToken) async {}

  @override
  Future<void> logoutAll(String accessToken) async {}

  Future<TokenBundle> _attest() async {
    final profile = await _deviceInfo.load();
    final accountToken = profile.deviceId;
    final challenge =
        '$accountToken.${_now().toUtc().millisecondsSinceEpoch}.${_uuid.v4()}';
    final proof = await _attestation.assertion(challenge);
    final response = await _authDio.post<dynamic>(
      '/attest',
      data: <String, Object?>{
        'app_account_token': accountToken,
        'challenge': challenge,
        ...proof,
      },
    );
    final token = asString(asMap(response.data)['device_token']);
    final claims = JwtUtils.decode(token);
    return TokenBundle(
      accessToken: token,
      refreshToken: refreshMarker,
      userId: claims.abid ?? accountToken,
      isGuest: true,
      expiresAt: claims.expiresAt,
    );
  }
}
