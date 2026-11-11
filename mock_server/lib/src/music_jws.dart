import 'dart:convert';

import 'music_core.dart';
import 'music_jwt.dart';

/// The fields of an Apple `JWSTransactionDecodedPayload` the ledger reads
/// (contract §5). Dates are Unix **milliseconds**, as Apple sends them.
class MusicSignedTransaction {
  const MusicSignedTransaction({
    required this.transactionId,
    required this.originalTransactionId,
    required this.productId,
    required this.purchaseDate,
    this.originalPurchaseDate,
    this.expiresDate,
    this.type,
    this.appAccountToken,
    this.storefront,
    this.offerType,
    this.revocationDate,
  });

  /// Decodes the payload (middle base64url segment) of a JWS **without**
  /// verifying its signature (dev mock: Xcode StoreKit-testing JWS are signed
  /// by a local certificate). Malformed → 40001.
  factory MusicSignedTransaction.decode(String jws) {
    final parts = jws.split('.');
    if (parts.length != 3) {
      throw MusicApiException.validation('signed_transactions', 'is not a JWS');
    }
    final Object? payload;
    try {
      payload = jsonDecode(utf8.decode(base64UrlDecodeLenient(parts[1])));
    } on FormatException {
      throw MusicApiException.validation(
        'signed_transactions',
        'has an undecodable payload',
      );
    }
    if (payload is! Map<String, Object?>) {
      throw MusicApiException.validation('signed_transactions', 'payload not JSON');
    }
    final transactionId = _str(payload['transactionId']);
    final productId = _str(payload['productId']);
    final purchaseDate = _int(payload['purchaseDate']);
    if (transactionId == null || productId == null || purchaseDate == null) {
      throw MusicApiException.validation(
        'signed_transactions',
        'needs transactionId, productId and purchaseDate',
      );
    }
    return MusicSignedTransaction(
      transactionId: transactionId,
      originalTransactionId:
          _str(payload['originalTransactionId']) ?? transactionId,
      productId: productId,
      purchaseDate: purchaseDate,
      originalPurchaseDate: _int(payload['originalPurchaseDate']),
      expiresDate: _int(payload['expiresDate']),
      type: _str(payload['type']),
      appAccountToken: _str(payload['appAccountToken'])?.toLowerCase(),
      storefront: _str(payload['storefront'])?.toUpperCase(),
      offerType: _int(payload['offerType']),
      revocationDate: _int(payload['revocationDate']),
    );
  }

  final String transactionId;
  final String originalTransactionId;
  final String productId;
  final int purchaseDate;
  final int? originalPurchaseDate;
  final int? expiresDate;
  final String? type;
  final String? appAccountToken;
  final String? storefront;
  final int? offerType;
  final int? revocationDate;

  /// Transaction ids arrive as strings from StoreKit but as numbers from some
  /// fixtures — accept both.
  static String? _str(Object? v) => switch (v) {
    final String s when s.isNotEmpty => s,
    final num n => n.toInt().toString(),
    _ => null,
  };

  static int? _int(Object? v) => switch (v) {
    final int i => i,
    final num n => n.toInt(),
    final String s => int.tryParse(s),
    _ => null,
  };
}

/// Builds an unsigned-but-well-formed JWS around [payload] (fixtures for tests
/// and `tool/happy_path.dart`; the mock never checks the signature segment).
String encodeFixtureJws(Map<String, Object?> payload) {
  final header = {'alg': 'ES256', 'x5c': <String>[], 'kid': 'mock'};
  return '${base64UrlNoPad(utf8.encode(jsonEncode(header)))}.'
      '${base64UrlNoPad(utf8.encode(jsonEncode(payload)))}.'
      '${base64UrlNoPad(utf8.encode('mock-signature'))}';
}
