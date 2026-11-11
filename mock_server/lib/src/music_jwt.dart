import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'music_core.dart';

String base64UrlNoPad(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

List<int> base64UrlDecodeLenient(String segment) =>
    base64Url.decode(base64Url.normalize(segment));

/// HS256 device tokens (`/v1/attest`): `{sub, abid, typ:"device", iat, exp}`,
/// times in Unix **seconds** — the shape `commerce_kit`'s `JwtUtils` decodes.
class MusicDeviceTokenIssuer {
  MusicDeviceTokenIssuer({required this.secret, required this.clock});

  final String secret;
  final MusicMockClock clock;

  String issue({required String appAccountToken, required int ttlSeconds}) {
    final iat = clock.nowSeconds();
    final header = {'alg': 'HS256', 'typ': 'JWT'};
    final claims = {
      'sub': appAccountToken,
      'abid': appAccountToken,
      'typ': 'device',
      'iat': iat,
      'exp': iat + ttlSeconds,
    };
    final signingInput =
        '${base64UrlNoPad(utf8.encode(jsonEncode(header)))}.'
        '${base64UrlNoPad(utf8.encode(jsonEncode(claims)))}';
    return '$signingInput.${_sign(signingInput)}';
  }

  /// Returns the verified `abid`. Any missing / malformed / forged / expired
  /// token → 40102 (the client re-attests with an assertion and replays).
  String verifyBearer(String? authorization) {
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      throw MusicApiException(ApiCodes.tokenExpired, 'missing bearer token');
    }
    final token = authorization.substring('Bearer '.length).trim();
    final parts = token.split('.');
    if (parts.length != 3) {
      throw MusicApiException(ApiCodes.tokenExpired, 'malformed token');
    }
    final expected = _sign('${parts[0]}.${parts[1]}');
    if (expected != parts[2]) {
      throw MusicApiException(ApiCodes.tokenExpired, 'invalid token signature');
    }
    final Object? claims;
    try {
      claims = jsonDecode(utf8.decode(base64UrlDecodeLenient(parts[1])));
    } on FormatException {
      throw MusicApiException(ApiCodes.tokenExpired, 'malformed token claims');
    }
    if (claims is! Map<String, Object?> ||
        claims['typ'] != 'device' ||
        claims['abid'] is! String ||
        claims['exp'] is! int) {
      throw MusicApiException(ApiCodes.tokenExpired, 'not a device token');
    }
    if ((claims['exp']! as int) <= clock.nowSeconds()) {
      throw MusicApiException(ApiCodes.tokenExpired, 'token expired');
    }
    return claims['abid']! as String;
  }

  String _sign(String input) => base64UrlNoPad(
    Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(input)).bytes,
  );
}
