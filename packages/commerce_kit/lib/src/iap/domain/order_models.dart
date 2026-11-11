import 'package:meta/meta.dart';

/// Result of `POST /v1/iap/orders`. `expiresAt` is parsed defensively (the
/// field may arrive as Unix seconds or milliseconds).
@immutable
class CreateOrderResult {
  const CreateOrderResult({
    required this.orderNo,
    required this.productCode,
    required this.storeProductId,
    required this.amountCents,
    required this.currency,
    required this.expiresAt,
  });

  final String orderNo;
  final String productCode;
  final String storeProductId;
  final int amountCents;
  final String currency;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);
}

@immutable
class OrderGrant {
  const OrderGrant({
    required this.type,
    this.credits = 0,
    this.features = const <String>[],
  });

  final String type;
  final int credits;
  final List<String> features;
}

@immutable
class OrderSubscription {
  const OrderSubscription({
    required this.originalTransactionId,
    required this.status,
    this.expiresDate,
    this.autoRenew = false,
  });

  final String originalTransactionId;
  final String status; // active / trialing / expired / canceled
  final DateTime? expiresDate;
  final bool autoRenew;
}

/// Result of `POST /v1/iap/orders/{order_no}/verify`.
@immutable
class VerifyResult {
  const VerifyResult({
    required this.orderNo,
    required this.status,
    required this.grantStatus,
    this.grant,
    this.subscription,
  });

  final String orderNo;
  final String status; // completed / failed
  final String grantStatus; // granted / failed
  final OrderGrant? grant;
  final OrderSubscription? subscription;

  bool get isCompleted => status == 'completed';

  /// The entitlement was actually granted. The backend can return HTTP 200 with
  /// `status: completed` **and** `grant_status: failed` (independent enums per
  /// the contract) — finishing on `isCompleted` alone would charge the user and
  /// grant nothing.
  bool get isGranted => grantStatus == 'granted';

  /// The only safe success predicate: verified **and** granted. Callers must
  /// finish the native transaction only when this is true.
  bool get isSuccessful => isCompleted && isGranted;
}

/// Persisted order awaiting native completion + verification. Written before the
/// native purchase so an app kill mid-flow can be recovered on next launch.
@immutable
class PendingOrder {
  const PendingOrder({
    required this.orderNo,
    required this.productCode,
    required this.storeProductId,
    required this.createdAt,
  });

  factory PendingOrder.fromJson(Map<String, dynamic> json) => PendingOrder(
        orderNo: json['order_no'] as String? ?? '',
        productCode: json['product_code'] as String? ?? '',
        storeProductId: json['store_product_id'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          json['created_at'] as int? ?? 0,
          isUtc: true,
        ),
      );

  final String orderNo;
  final String productCode;
  final String storeProductId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'order_no': orderNo,
        'product_code': productCode,
        'store_product_id': storeProductId,
        'created_at': createdAt.toUtc().millisecondsSinceEpoch,
      };
}
