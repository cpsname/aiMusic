import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';

class MusicFakeStoreClient implements StoreClient {
  final StreamController<List<StorePurchase>> _controller =
      StreamController<List<StorePurchase>>.broadcast();
  int buyCount = 0;
  int restoreCount = 0;

  /// `.restored` events pushed onto [purchaseStream] when [restore] is called.
  List<StorePurchase> restoreEmits = const [];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<StoreProductDetails>> queryProducts(Set<String> ids) async =>
      const [];

  @override
  Stream<List<StorePurchase>> get purchaseStream => _controller.stream;

  @override
  Future<void> buy({
    required StoreProductDetails product,
    required bool isConsumable,
    String? appAccountToken,
  }) async {
    buyCount += 1;
  }

  @override
  Future<void> complete(StorePurchase purchase) async {}

  @override
  Future<void> restore() async {
    restoreCount += 1;
    for (final purchase in restoreEmits) {
      _controller.add([purchase]);
    }
  }

  void emit(StorePurchase purchase) => _controller.add([purchase]);

  void dispose() => _controller.close();
}

class MusicFakeIapRepository implements IapRepository {
  MusicFakeIapRepository({required this.order});

  final CreateOrderResult order;

  @override
  Future<AppInitData> appInit({String? clientVersion}) async =>
      const AppInitData(products: [], legal: LegalInfo());

  @override
  Future<CreateOrderResult> createOrder({
    required String distributionCode,
    required String productCode,
    String? pushToken,
  }) async => order;

  @override
  Future<VerifyResult> verify({
    required String orderNo,
    required String transactionId,
  }) async => VerifyResult(
    orderNo: orderNo,
    status: 'completed',
    grantStatus: 'granted',
  );
}

StoreProduct sampleStoreProduct({
  String code = 'pro_monthly',
  String name = 'Pro Monthly',
  String price = r'US$9.98',
  String cycle = 'monthly',
  ProductKind kind = ProductKind.autoRenewable,
}) => StoreProduct(
  product: Product(
    productCode: code,
    storeProductId: 'com.example.$code',
    productName: name,
    kind: kind,
    priceCents: 998,
    currency: 'USD',
    billingCycle: cycle,
  ),
  details: StoreProductDetails(
    id: 'com.example.$code',
    title: name,
    description: 'Everything unlocked',
    price: price,
    rawPrice: 9.98,
    currencyCode: 'USD',
  ),
);

CreateOrderResult sampleOrder({String code = 'pro_monthly'}) =>
    CreateOrderResult(
      orderNo: 'ORD-1',
      productCode: code,
      storeProductId: 'com.example.$code',
      amountCents: 998,
      currency: 'USD',
      expiresAt: DateTime.utc(2035),
    );

CurrentAccount sampleAccount({
  bool isGuest = false,
  List<WalletFeature> features = const [],
  Subscription? subscription,
}) => CurrentAccount(
  userId: 'u1',
  nickname: 'Alice',
  accountType: isGuest ? 'guest' : 'personal',
  role: 'user',
  status: 'active',
  isGuest: isGuest,
  email: 'a***@example.com',
  createdAt: DateTime.utc(2024, 3),
  subscription: subscription,
  features: features,
  guidance: const Guidance(
    needsProfileComplete: false,
    hasActiveSubscription: false,
    hasCredits: false,
  ),
);
