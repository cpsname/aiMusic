import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart' show PlatformException;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/iap_models.dart';
import '../domain/store_client.dart';
import 'product_detail_extractor.dart';

/// [StoreClient] backed by `in_app_purchase` (StoreKit 2 / Play Billing).
///
/// Cancellation handling: the locked plugin (`in_app_purchase_storekit` 0.4.10)
/// **does not** signal an SK2 user-cancel — `buyNonConsumable` discards
/// `SK2Product.purchase()`'s `.userCancelled` and returns true, and Apple delivers
/// no `Transaction`, so neither this `PlatformException` catch nor a stream event
/// fires (verified against the pinned source; see flutter/flutter#160659, #178292).
/// The orchestrator detects that silence with a short window. The catch below is
/// kept as a **forward-compatible defensive fallback** for plugin versions (past
/// pre-releases / a future fix) that do throw `storekit2_purchase_cancelled`; on
/// 0.4.10 it is unreachable.
class InAppPurchaseStoreClient implements StoreClient {
  InAppPurchaseStoreClient([InAppPurchase? iap])
      : _iap = iap ?? InAppPurchase.instance;

  static const String _sk2CancelCode = 'storekit2_purchase_cancelled';

  final InAppPurchase _iap;
  final ProductDetailExtractor _extractor = const ProductDetailExtractor();
  final Map<String, ProductDetails> _productCache = {};
  final Map<String, PurchaseDetails> _detailsByTransaction = {};

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<StoreProductDetails>> queryProducts(
    Set<String> storeProductIds,
  ) async {
    final response = await _iap.queryProductDetails(storeProductIds);
    if (kDebugMode) {
      debugPrint(
        '[iap] queryProducts requested=$storeProductIds '
        'found=${response.productDetails.map((p) => p.id).toList()} '
        'notFound=${response.notFoundIDs} error=${response.error?.message}',
      );
    }
    for (final details in response.productDetails) {
      _productCache[details.id] = details;
    }
    return response.productDetails.map(_toStoreDetails).toList(growable: false);
  }

  @override
  Stream<List<StorePurchase>> get purchaseStream =>
      _iap.purchaseStream.map((list) {
        for (final details in list) {
          _detailsByTransaction[_transactionId(details)] = details;
        }
        return list.map(_toStorePurchase).toList(growable: false);
      });

  @override
  Future<void> buy({
    required StoreProductDetails product,
    required bool isConsumable,
    String? appAccountToken,
  }) async {
    final details = _productCache[product.id];
    if (details == null) {
      throw StoreUnavailableException('Product ${product.id} not loaded');
    }
    // The caller passes the account BID (a UUID) or null. `applicationUserName`
    // maps per platform: on StoreKit 2 → the purchase's `appAccountToken` (Apple
    // echoes it on the transaction + every S2S notification; a non-UUID is
    // silently dropped natively); on Play Billing → `obfuscatedAccountId` (Play
    // echoes it on RTDN; the UUID BID satisfies its ≤64-char, non-PII contract).
    // Either way the backend can map the purchase to the account.
    final param = PurchaseParam(
      productDetails: details,
      applicationUserName: appAccountToken,
    );
    try {
      if (isConsumable) {
        await _iap.buyConsumable(purchaseParam: param);
      } else {
        await _iap.buyNonConsumable(purchaseParam: param);
      }
    } on PlatformException catch (error) {
      // Defensive/forward-compat: unreachable on 0.4.10 (see class doc).
      if (error.code == _sk2CancelCode) {
        throw const StorePurchaseCancelledException();
      }
      rethrow;
    }
  }

  @override
  Future<void> complete(StorePurchase purchase) async {
    final details = _detailsByTransaction[purchase.transactionId];
    if (details != null && details.pendingCompletePurchase) {
      await _iap.completePurchase(details);
      _detailsByTransaction.remove(purchase.transactionId);
    }
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  StoreProductDetails _toStoreDetails(ProductDetails details) =>
      StoreProductDetails(
        id: details.id,
        title: _extractor.cleanTitle(details),
        description: details.description,
        price: details.price,
        rawPrice: details.rawPrice,
        currencyCode: details.currencyCode,
        currencySymbol: details.currencySymbol,
        storeType: _extractor.detectStoreType(details),
        subscriptionPeriod: _extractor.extractSubscriptionPeriod(details),
        introductoryOffer: _extractor.extractIntroductoryOffer(details),
        promotionalOffers: _extractor.extractPromotionalOffers(details),
      );

  StorePurchase _toStorePurchase(PurchaseDetails details) => StorePurchase(
        productId: details.productID,
        transactionId: _transactionId(details),
        status: _mapStatus(details.status),
        error: details.error?.message,
      );

  String _transactionId(PurchaseDetails details) => details.purchaseID ?? '';

  StorePurchaseStatus _mapStatus(PurchaseStatus status) => switch (status) {
        PurchaseStatus.pending => StorePurchaseStatus.pending,
        PurchaseStatus.purchased => StorePurchaseStatus.purchased,
        PurchaseStatus.restored => StorePurchaseStatus.restored,
        PurchaseStatus.canceled => StorePurchaseStatus.canceled,
        PurchaseStatus.error => StorePurchaseStatus.error,
      };
}
