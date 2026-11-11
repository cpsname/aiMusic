import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:dio/dio.dart';
import 'package:infra_core/infra_core.dart';

DioException dioApiError(int code, {String message = 'error'}) => DioException(
      requestOptions: RequestOptions(path: '/iap/verify'),
      error: ApiError.fromEnvelope(code: code, message: message),
    );

DioException dioTimeout() => DioException(
      requestOptions: RequestOptions(path: '/iap/verify'),
      type: DioExceptionType.receiveTimeout,
    );

StoreProduct testProduct({
  String code = 'pro_monthly',
  String storeId = 'com.example.pro_monthly',
  ProductKind kind = ProductKind.autoRenewable,
}) =>
    StoreProduct(
      product: Product(
        productCode: code,
        storeProductId: storeId,
        productName: 'Pro',
        kind: kind,
        priceCents: 998,
        currency: 'USD',
      ),
      details: StoreProductDetails(
        id: storeId,
        title: 'Pro Monthly',
        description: 'Unlock everything',
        price: r'US$9.98',
        rawPrice: 9.98,
        currencyCode: 'USD',
      ),
    );

CreateOrderResult testOrder({
  String orderNo = 'ORD-1',
  String storeId = 'com.example.pro_monthly',
  DateTime? expiresAt,
}) =>
    CreateOrderResult(
      orderNo: orderNo,
      productCode: 'pro_monthly',
      storeProductId: storeId,
      amountCents: 998,
      currency: 'USD',
      expiresAt: expiresAt ?? DateTime.utc(2035),
    );

VerifyResult completedVerify([String orderNo = 'ORD-1']) =>
    VerifyResult(orderNo: orderNo, status: 'completed', grantStatus: 'granted');

/// A receipt the server verified (`completed`) but whose entitlement grant
/// failed (`grant_status: failed`) — must NOT be treated as a success.
VerifyResult grantFailedVerify([String orderNo = 'ORD-1']) =>
    VerifyResult(orderNo: orderNo, status: 'completed', grantStatus: 'failed');

/// A verify that returned a non-completed status (HTTP 200, not thrown).
VerifyResult failedVerify([String orderNo = 'ORD-1']) =>
    VerifyResult(orderNo: orderNo, status: 'failed', grantStatus: 'failed');

class FakeIapRepository implements IapRepository {
  CreateOrderResult? orderResult;
  Object? orderError;
  AppInitData? appInitResult;
  int appInitCalls = 0;

  /// One outcome per verify attempt (VerifyResult or a thrown error); the last
  /// entry repeats for further attempts.
  final List<Object> verifyOutcomes = [];
  int verifyCalls = 0;

  /// Interleaving log of repository calls (`order` / `verify`) — lets tests
  /// assert sequencing, e.g. that restore serializes create-order → verify per
  /// transaction instead of firing a concurrent same-account burst.
  final List<String> callLog = [];

  @override
  Future<AppInitData> appInit({String? clientVersion}) async {
    appInitCalls += 1;
    return appInitResult!;
  }

  /// Captures the `push_token` passed to the most recent createOrder call.
  String? pushTokenSeen;

  @override
  Future<CreateOrderResult> createOrder({
    required String distributionCode,
    required String productCode,
    String? pushToken,
  }) async {
    callLog.add('order');
    pushTokenSeen = pushToken;
    if (orderError != null) throw orderError!;
    return orderResult!;
  }

  @override
  Future<VerifyResult> verify({
    required String orderNo,
    required String transactionId,
  }) async {
    callLog.add('verify');
    final index = verifyCalls < verifyOutcomes.length
        ? verifyCalls
        : verifyOutcomes.length - 1;
    verifyCalls += 1;
    final outcome = verifyOutcomes[index];
    if (outcome is VerifyResult) return outcome;
    throw outcome;
  }
}

class FakeStoreClient implements StoreClient {
  final StreamController<List<StorePurchase>> _controller =
      StreamController<List<StorePurchase>>.broadcast();

  /// Emitted onto [purchaseStream] when [buy] is called (simulating the native
  /// purchase update). Null = emit nothing (the SK2 silent-cancel path: no
  /// exception, no stream event).
  StorePurchase? buyResult;
  Object? buyThrows;

  /// When set, [buy] awaits this before returning — lets a test hold the flow in
  /// `awaitingNative` (e.g. to exercise the in-flight guard) deterministically.
  Completer<void>? buyGate;

  /// Store details returned by [queryProducts]; [queryThrows] forces a failure.
  List<StoreProductDetails> queryResult = const [];
  Object? queryThrows;

  final List<StorePurchase> completed = [];
  int restoreCalls = 0;
  Object? restoreThrows;

  /// `.restored` transactions pushed onto [purchaseStream] when [restore] is
  /// called — one event each, mirroring the native per-entitlement callbacks.
  List<StorePurchase> restoreEmits = const [];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<StoreProductDetails>> queryProducts(Set<String> ids) async {
    if (queryThrows != null) throw queryThrows!;
    return queryResult.where((d) => ids.contains(d.id)).toList(growable: false);
  }

  @override
  Stream<List<StorePurchase>> get purchaseStream => _controller.stream;

  /// Captures the `appAccountToken` passed to the most recent buy call.
  String? appAccountTokenSeen;

  @override
  Future<void> buy({
    required StoreProductDetails product,
    required bool isConsumable,
    String? appAccountToken,
  }) async {
    appAccountTokenSeen = appAccountToken;
    if (buyGate != null) await buyGate!.future;
    if (buyThrows != null) throw buyThrows!;
    final result = buyResult;
    if (result != null) _controller.add([result]);
  }

  /// transactionIds whose [complete] should throw (simulates a native
  /// finishPurchase failure for a specific transaction).
  Set<String> completeThrowsFor = const {};

  @override
  Future<void> complete(StorePurchase purchase) async {
    if (completeThrowsFor.contains(purchase.transactionId)) {
      throw StateError('finish failed for ${purchase.transactionId}');
    }
    completed.add(purchase);
  }

  @override
  Future<void> restore() async {
    restoreCalls += 1;
    if (restoreThrows != null) throw restoreThrows!;
    for (final purchase in restoreEmits) {
      _controller.add([purchase]);
    }
  }

  /// Pushes an unsolicited event (e.g. a re-delivered transaction on launch).
  void emit(StorePurchase purchase) => _controller.add([purchase]);

  void dispose() => _controller.close();
}
