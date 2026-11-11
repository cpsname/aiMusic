import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'canonical_json.dart';

/// The four signature-chain headers a signed request must carry, alongside
/// `X-Distribution-Code`.
@immutable
class SignaturePayload {
  const SignaturePayload({
    required this.timestamp,
    required this.nonce,
    required this.signature,
  });

  final String timestamp;
  final String nonce;
  final String signature;
}

/// Computes the app signature exactly as the backend verifies it:
///
///     canonical = timestamp + nonce + canonicalJson(body)
///     signature = hex_lowercase( HMAC_SHA256(secret, canonical) )
///
/// The three segments are concatenated with no separators; an empty/null body
/// contributes the literal `{}`. The result is 64 lowercase hex characters.
@immutable
class SigningService {
  const SigningService();

  String sign({
    required String secret,
    required String timestamp,
    required String nonce,
    Object? body,
  }) {
    final canonicalBody = canonicalJson(body);
    final message = '$timestamp$nonce$canonicalBody';
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(message)).toString();
  }

  /// Convenience that signs [body] and bundles the timestamp/nonce/signature.
  SignaturePayload signRequest({
    required String secret,
    required String timestamp,
    required String nonce,
    Object? body,
  }) {
    return SignaturePayload(
      timestamp: timestamp,
      nonce: nonce,
      signature:
          sign(secret: secret, timestamp: timestamp, nonce: nonce, body: body),
    );
  }
}
