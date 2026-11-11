import 'dart:convert';

import 'package:meta/meta.dart';

import '../../common/json.dart';

/// The decoded payload of a StoreKit 2 signed transaction (JWS,
/// `JWSTransactionDecodedPayload`). The client only **reads** it — to route an
/// update to the right product and to key the outbox; the signature is verified
/// by StoreKit on device and by the backend against Apple's root (the client
/// never trusts it for entitlement: the server's sync response is the truth).
@immutable
class SignedTransaction {
  const SignedTransaction({
    required this.jws,
    required this.transactionId,
    required this.originalTransactionId,
    required this.productId,
    this.appAccountToken,
    this.purchaseDate,
    this.expiresDate,
    this.revocationDate,
    this.storefront,
    this.type,
  });

  /// Decodes [jws] (`header.payload.signature`). Returns null for anything that
  /// is not a three-part JWS with a JSON object payload carrying ids.
  static SignedTransaction? tryParse(String jws) {
    final parts = jws.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return null;
      final map = asMap(payload);
      final transactionId = asString(map['transactionId']);
      final productId = asString(map['productId']);
      if (transactionId.isEmpty || productId.isEmpty) return null;
      return SignedTransaction(
        jws: jws,
        transactionId: transactionId,
        originalTransactionId:
            asString(map['originalTransactionId'], transactionId),
        productId: productId,
        appAccountToken: asNullableString(map['appAccountToken']),
        purchaseDate: _date(map['purchaseDate']),
        expiresDate: _date(map['expiresDate']),
        revocationDate: _date(map['revocationDate']),
        storefront: asNullableString(map['storefront']),
        type: asNullableString(map['type']),
      );
    } on FormatException {
      return null;
    }
  }

  final String jws;
  final String transactionId;
  final String originalTransactionId;
  final String productId;
  final String? appAccountToken;
  final DateTime? purchaseDate;
  final DateTime? expiresDate;
  final DateTime? revocationDate;

  /// App Store storefront, ISO 3166-1 alpha-3 (e.g. `USA`).
  final String? storefront;

  /// e.g. `Auto-Renewable Subscription`, `Consumable`.
  final String? type;

  bool get isRevoked => revocationDate != null;

  static DateTime? _date(Object? value) {
    final millis = asInt(value);
    return millis > 0
        ? DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true)
        : null;
  }
}
