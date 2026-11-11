import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'canonical_json.dart';
import 'core.dart';

/// Header names of the monolith's app-signature chain (overview §5).
abstract final class SignatureHeaders {
  static const String distributionCode = 'X-Distribution-Code';
  static const String timestamp = 'X-Timestamp';
  static const String nonce = 'X-Nonce';
  static const String appSignature = 'X-App-Signature';
}

/// `hex(HMAC_SHA256(secret, timestamp + nonce + canonicalJson(body)))` —
/// identical to `infra_core`'s `SigningService.sign`.
String computeAppSignature({
  required String secret,
  required String timestamp,
  required String nonce,
  Object? body,
}) {
  final message = '$timestamp$nonce${canonicalJson(body)}';
  return Hmac(
    sha256,
    utf8.encode(secret),
  ).convert(utf8.encode(message)).toString();
}

/// Server-side verification of the app signature.
///
/// Error mapping (monolith codes, HTTP 401, `details.error_code` absent):
/// missing header → 40110, non-numeric timestamp → 40111, outside ±[window]
/// → 40112, nonce replay → 40113, wrong distribution code or HMAC → 40114.
class SignatureVerifier {
  SignatureVerifier({
    required this.secret,
    required this.distributionCode,
    required this.clock,
    this.window = const Duration(minutes: 5),
  });

  final String secret;
  final String distributionCode;
  final MockClock clock;
  final Duration window;

  /// nonce → unix-ms after which it may be forgotten.
  final Map<String, int> _nonces = {};

  /// Verifies a request. [header] reads a request header (case-insensitive);
  /// [decodedBody] is the parsed JSON body (null when the body was empty).
  void verify({
    required String? Function(String name) header,
    required Object? decodedBody,
  }) {
    final dist = header(SignatureHeaders.distributionCode);
    final ts = header(SignatureHeaders.timestamp);
    final nonce = header(SignatureHeaders.nonce);
    final signature = header(SignatureHeaders.appSignature);
    if ([dist, ts, nonce, signature].any((v) => v == null || v.isEmpty)) {
      throw ApiException(
        ApiCodes.signatureHeaderMissing,
        'missing app signature headers',
      );
    }
    final seconds = int.tryParse(ts!);
    if (seconds == null) {
      throw ApiException(
        ApiCodes.signatureTimestampInvalid,
        'invalid X-Timestamp',
      );
    }
    final nowMs = clock.nowMs();
    if ((nowMs - seconds * 1000).abs() > window.inMilliseconds) {
      throw ApiException(
        ApiCodes.signatureExpired,
        'X-Timestamp outside the ${window.inMinutes} min window',
      );
    }
    if (dist != distributionCode) {
      throw ApiException(ApiCodes.signatureInvalid, 'unknown distribution');
    }
    final expected = computeAppSignature(
      secret: secret,
      timestamp: ts,
      nonce: nonce!,
      body: decodedBody,
    );
    if (!_constantTimeEquals(expected, signature!.toLowerCase())) {
      throw ApiException(ApiCodes.signatureInvalid, 'invalid app signature');
    }
    _nonces.removeWhere((_, expiry) => expiry < nowMs);
    if (_nonces.containsKey(nonce)) {
      throw ApiException(ApiCodes.signatureNonceReused, 'nonce reused');
    }
    _nonces[nonce] = nowMs + 2 * window.inMilliseconds;
  }

  void reset() => _nonces.clear();

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
