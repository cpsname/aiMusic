import 'iap_models.dart';
import 'order_models.dart';

abstract interface class IapRepository {
  /// `POST /v1/app/init` — public (no JWT), over the no-auth Dio.
  Future<AppInitData> appInit({String? clientVersion});

  /// `POST /v1/iap/orders` — authed. [pushToken] (the account BID UUID, the same
  /// value attached to the native purchase as `appAccountToken`) is sent as
  /// `push_token` so the backend can pre-bind the order to the account; omitted
  /// when null.
  Future<CreateOrderResult> createOrder({
    required String distributionCode,
    required String productCode,
    String? pushToken,
  });

  /// `POST /v1/iap/orders/{order_no}/verify` — authed.
  Future<VerifyResult> verify({
    required String orderNo,
    required String transactionId,
  });
}
