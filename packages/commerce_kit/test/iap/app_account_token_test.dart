import 'dart:convert';

import 'package:commerce_kit/src/iap/application/iap_providers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds an unsigned JWT (header.payload.sig) carrying [claims].
String _jwt(Map<String, dynamic> claims) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${seg({'alg': 'HS256', 'typ': 'JWT'})}.${seg(claims)}.sig';
}

void main() {
  const uuid = '0193b9a0-7c8d-7e3f-9a01-abcdef012345';

  test('returns the abid claim when it is a valid UUID', () {
    expect(appAccountTokenFromAccessToken(_jwt({'abid': uuid})), uuid);
  });

  test('does NOT fall back to sub — the appAccountToken contract is abid-only', () {
    // The backend maps the webhook appAccountToken to the account by `abid`
    // (BACKEND_COORDINATION §3.1); a standard `sub` is not interchangeable, so a
    // token without `abid` yields null (backend uses its originalTransactionId
    // reverse-lookup) rather than binding to the wrong id.
    expect(appAccountTokenFromAccessToken(_jwt({'sub': uuid})), isNull);
  });

  test('prefers abid even when a differing sub UUID is present', () {
    const other = 'ffffffff-ffff-4fff-8fff-ffffffffffff';
    expect(
      appAccountTokenFromAccessToken(_jwt({'abid': uuid, 'sub': other})),
      uuid,
    );
  });

  test('returns null for a non-UUID account id (e.g. a guest_id)', () {
    expect(appAccountTokenFromAccessToken(_jwt({'abid': 'guest_a1b2c3'})), isNull);
  });

  test('returns null for null / empty / opaque (non-JWT) tokens', () {
    expect(appAccountTokenFromAccessToken(null), isNull);
    expect(appAccountTokenFromAccessToken(''), isNull);
    expect(appAccountTokenFromAccessToken('opaque-not-a-jwt'), isNull);
  });

  test('returns null when the token carries no account claim', () {
    expect(appAccountTokenFromAccessToken(_jwt({'role': 'user'})), isNull);
  });
}
