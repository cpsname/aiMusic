import 'package:meta/meta.dart';

import 'store_offer.dart';

enum ProductKind { consumable, nonConsumable, autoRenewable, nonRenewable, unknown }

/// A purchasable product as defined by the backend (`/app/init`).
@immutable
class Product {
  const Product({
    required this.productCode,
    required this.storeProductId,
    required this.productName,
    required this.kind,
    required this.priceCents,
    required this.currency,
    this.productNameZh,
    this.description,
    this.iconUrl,
    this.originalPriceCents,
    this.billingCycle = 'one_time',
    this.trialDays = 0,
    this.subscriptionGroup,
    this.highlightTag,
    this.sortOrder = 0,
    this.isActive = true,
    this.isVisible = true,
  });

  final String productCode;
  final String storeProductId;
  final String productName;
  final String? productNameZh;
  final String? description;
  final String? iconUrl;
  final ProductKind kind;
  final int priceCents;
  final int? originalPriceCents;
  final String currency;
  final String billingCycle;
  final int trialDays;
  final String? subscriptionGroup;
  final String? highlightTag;
  final int sortOrder;
  final bool isActive;
  final bool isVisible;

  bool get isConsumable => kind == ProductKind.consumable;

  bool get isSubscription =>
      kind == ProductKind.autoRenewable || kind == ProductKind.nonRenewable;

  /// Whether a transaction for this product is safe to **finish even when the
  /// server has not (yet) confirmed a grant**. True for subscriptions and
  /// non-consumables: the entitlement stays in StoreKit's `currentEntitlements`
  /// (so a user-initiated restore re-claims it) and the server grants it
  /// out-of-band via the Apple S2S webhook — so acknowledging the transaction
  /// can never lose it. **False for consumables and any unknown kind**: they have
  /// neither net (no renewal webhook, not in `currentEntitlements`), so an
  /// unfinished-transaction redelivery is their only recovery path and finishing
  /// before a confirmed grant would lose the purchase.
  bool get isRestorable =>
      kind == ProductKind.autoRenewable ||
      kind == ProductKind.nonRenewable ||
      kind == ProductKind.nonConsumable;
}

/// Localized store-side product info from StoreKit / Play (App Store Connect),
/// extracted from the `in_app_purchase` plugin's `ProductDetails`. Carries the
/// live subscription period + introductory/promotional offers (App Store Connect
/// discounts) so the paywall can surface trials and promos.
@immutable
class StoreProductDetails {
  const StoreProductDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    this.currencySymbol,
    this.storeType = StoreType.appStore,
    this.subscriptionPeriod,
    this.introductoryOffer,
    this.promotionalOffers = const [],
  });

  final String id; // == Product.storeProductId
  final String title; // localized display name
  final String description;
  final String price; // localized display price, e.g. "US$9.98"
  final double rawPrice;
  final String currencyCode;
  final String? currencySymbol;
  final StoreType storeType;

  /// Subscription period (null for non-subscription products).
  final SubscriptionPeriodValue? subscriptionPeriod;

  /// Introductory offer (free trial / intro price), if configured.
  final ProductOffer? introductoryOffer;

  /// Promotional offers (App Store Connect promo / win-back, Play offers).
  final List<ProductOffer> promotionalOffers;
}

/// The backend product merged with its live, localized store details. This is
/// what the paywall renders — every label/price comes from the store, never a
/// hardcoded value.
@immutable
class StoreProduct {
  const StoreProduct({required this.product, required this.details});

  final Product product;
  final StoreProductDetails details;

  String get productCode => product.productCode;
  String get storeProductId => product.storeProductId;

  /// Localized store title, falling back to the backend name only if the store
  /// omitted a title.
  String get displayName =>
      details.title.isNotEmpty ? details.title : product.productName;

  String get displayPrice => details.price;
  bool get isConsumable => product.isConsumable;
  bool get isSubscription => product.isSubscription;
  String? get highlightTag => product.highlightTag;

  /// Live subscription period from the store (e.g. 1 week), if any.
  SubscriptionPeriodValue? get subscriptionPeriod => details.subscriptionPeriod;

  /// Introductory offer (free trial / intro price), if any.
  ProductOffer? get introductoryOffer => details.introductoryOffer;

  /// Promotional offers / discounts configured in the store.
  List<ProductOffer> get promotionalOffers => details.promotionalOffers;

  bool get hasIntroductoryOffer => details.introductoryOffer != null;
  bool get hasFreeTrial => details.introductoryOffer?.isFreeTrial ?? false;
  bool get hasPromotionalOffers => details.promotionalOffers.isNotEmpty;
}

@immutable
class LegalInfo {
  const LegalInfo({this.privacyUrl, this.termsUrl, this.subscriptionTermsUrl});

  final String? privacyUrl;
  final String? termsUrl;
  final String? subscriptionTermsUrl;
}

@immutable
class UpdateInfo {
  const UpdateInfo({
    required this.forceUpdate,
    this.latestVersion,
    this.updateUrl,
    this.releaseNotes,
  });

  final bool forceUpdate;
  final String? latestVersion;
  final String? updateUrl;
  final String? releaseNotes;
}

/// `/app/init` payload: catalog + legal links + optional update prompt.
@immutable
class AppInitData {
  const AppInitData({
    required this.products,
    required this.legal,
    this.update,
  });

  final List<Product> products;
  final LegalInfo legal;
  final UpdateInfo? update;

  /// Visible, active products in display order.
  List<Product> get visibleProducts {
    final list = products.where((p) => p.isVisible && p.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }
}
