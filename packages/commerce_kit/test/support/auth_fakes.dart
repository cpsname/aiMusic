import 'dart:convert';

import 'package:commerce_kit/src/auth/domain/auth_repository.dart';
import 'package:commerce_kit/src/auth/domain/auth_session.dart';
import 'package:infra_core/infra_core.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Builds an unsigned JWT whose `exp`/`abid` claims the client can decode.
String makeJwt({required DateTime exp, String subject = 'user-1'}) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final header = seg({'alg': 'HS256', 'typ': 'JWT'});
  final payload =
      seg({'abid': subject, 'exp': exp.millisecondsSinceEpoch ~/ 1000});
  return '$header.$payload.signature';
}

TokenBundle bundle({
  required String access,
  String refresh = 'refresh-token',
  String userId = 'user-1',
  bool isGuest = false,
  bool isNewUser = false,
}) =>
    TokenBundle(
      accessToken: access,
      refreshToken: refresh,
      userId: userId,
      isGuest: isGuest,
      isNewUser: isNewUser,
    );

class FakeAuthRepository implements AuthRepository {
  TokenBundle? guestResult;
  TokenBundle? loginResult;
  TokenBundle? refreshResult;
  Object? guestError;
  Object? loginError;
  Object? refreshError;

  int guestCalls = 0;
  int loginCalls = 0;
  int refreshCalls = 0;
  int logoutCalls = 0;
  int logoutAllCalls = 0;

  @override
  Future<TokenBundle> guestRegister(AppDescriptor app) async {
    guestCalls += 1;
    if (guestError != null) throw guestError!;
    return guestResult!;
  }

  @override
  Future<TokenBundle> login({
    required String username,
    required String password,
  }) async {
    loginCalls += 1;
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<TokenBundle> refresh(String refreshToken) async {
    refreshCalls += 1;
    if (refreshError != null) throw refreshError!;
    return refreshResult!;
  }

  @override
  Future<void> logout(String accessToken) async {
    logoutCalls += 1;
  }

  @override
  Future<void> logoutAll(String accessToken) async {
    logoutAllCalls += 1;
  }
}

class FakeSecureTokenStore implements SecureTokenStore {
  FakeSecureTokenStore({TokenPair? tokens, this.deviceId = 'device-1'})
      : _tokens = tokens;

  TokenPair? _tokens;
  String? deviceId;
  int clearCalls = 0;
  int deviceIdDeletes = 0;

  @override
  Future<TokenPair?> readTokens() async => _tokens;

  @override
  Future<String?> readAccessToken() async => _tokens?.accessToken;

  @override
  Future<String?> readRefreshToken() async => _tokens?.refreshToken;

  @override
  Future<void> writeTokens(TokenPair tokens) async => _tokens = tokens;

  @override
  Future<void> clearTokens() async {
    clearCalls += 1;
    _tokens = null; // device id intentionally preserved
  }

  @override
  Future<String?> readDeviceId() async => deviceId;

  @override
  Future<void> writeDeviceId(String id) async => deviceId = id;

  @override
  Future<void> deleteDeviceId() async {
    deviceIdDeletes += 1;
    deviceId = null;
  }
}

DeviceInfoService fakeDeviceInfoService(SecureTokenStore store) =>
    DeviceInfoService(
      tokenStore: store,
      platformDetailsProbe: () async =>
          (platform: 'ios', osVersion: '17.0', model: 'iPhone15,2'),
      packageInfoProbe: () async => PackageInfo(
        appName: 'Studio',
        packageName: 'com.example.studio',
        version: '1.0.0',
        buildNumber: '1',
      ),
    );

const EnvConfig testEnv = EnvConfig(
  env: AppEnv.dev,
  baseUrl: 'https://api.test/v1',
  distributionCode: 'ios_global',
  distributionSecret: 'shhh',
  appCode: 'studio_app',
  bundleId: 'com.example.studio',
  iapChannel: 'appstore',
);
