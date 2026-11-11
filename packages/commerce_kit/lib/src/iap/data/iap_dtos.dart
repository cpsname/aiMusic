import '../../common/json.dart';
import '../domain/iap_models.dart';
import '../domain/order_models.dart';

/// `expires_at` may arrive as Unix seconds or milliseconds — `< 1e12` is seconds.
DateTime _flexibleTimestamp(Object? value) {
  final n = asInt(value);
  if (n <= 0) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final millis = n < 1000000000000 ? n * 1000 : n;
  return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
}

ProductKind _productKind(Object? raw) => switch (asString(raw)) {
  'consumable' => ProductKind.consumable,
  'non_consumable' => ProductKind.nonConsumable,
  'auto_renewable' => ProductKind.autoRenewable,
  'non_renewable' => ProductKind.nonRenewable,
  _ => ProductKind.unknown,
};

Product productFromJson(Map<String, dynamic> json) {
  // OpenAPI calls it `product_name`; the live backend sends `name`. Accept both.
  final productName = asString(json['product_name']).isNotEmpty
      ? asString(json['product_name'])
      : asString(json['name']);
  return Product(
    productCode: asString(json['product_code']),
    storeProductId: asString(json['store_product_id']),
    productName: productName,
    productNameZh: json['product_name_zh'] as String?,
    description: json['description'] as String?,
    iconUrl: json['icon_url'] as String?,
    kind: _productKind(json['product_kind']),
    priceCents: asInt(json['price_cents']),
    originalPriceCents: json['original_price_cents'] is int
        ? json['original_price_cents'] as int
        : null,
    currency: asString(json['currency'], 'USD'),
    billingCycle: asString(json['billing_cycle'], 'one_time'),
    trialDays: asInt(json['trial_days']),
    subscriptionGroup: json['subscription_group'] as String?,
    highlightTag: json['highlight_tag'] as String?,
    sortOrder: asInt(json['sort_order']),
    isActive: asBool(json['is_active'], true),
    isVisible: asBool(json['is_visible'], true),
  );
}

String _productKindToJson(ProductKind kind) => switch (kind) {
  ProductKind.consumable => 'consumable',
  ProductKind.nonConsumable => 'non_consumable',
  ProductKind.autoRenewable => 'auto_renewable',
  ProductKind.nonRenewable => 'non_renewable',
  ProductKind.unknown => '',
};

/// Serializes a [Product] back to the backend wire shape (so the cache can be
/// re-parsed by [productFromJson] — one parse path, no second schema).
Map<String, dynamic> productToJson(Product p) => {
  'product_code': p.productCode,
  'store_product_id': p.storeProductId,
  'product_name': p.productName,
  'product_name_zh': p.productNameZh,
  'description': p.description,
  'icon_url': p.iconUrl,
  'product_kind': _productKindToJson(p.kind),
  'price_cents': p.priceCents,
  'original_price_cents': p.originalPriceCents,
  'currency': p.currency,
  'billing_cycle': p.billingCycle,
  'trial_days': p.trialDays,
  'subscription_group': p.subscriptionGroup,
  'highlight_tag': p.highlightTag,
  'sort_order': p.sortOrder,
  'is_active': p.isActive,
  'is_visible': p.isVisible,
};

/// Serializes [AppInitData] to the backend wire shape for persistent caching.
/// Round-trips through [AppInitResponseDto.fromJson].
Map<String, dynamic> appInitDataToJson(AppInitData data) => {
  'products': [for (final p in data.products) productToJson(p)],
  'legal': {
    'privacy_url': data.legal.privacyUrl,
    'terms_url': data.legal.termsUrl,
    'subscription_terms_url': data.legal.subscriptionTermsUrl,
  },
  if (data.update case final update?)
    'update': {
      'force_update': update.forceUpdate,
      'latest_version': update.latestVersion,
      'update_url': update.updateUrl,
      'release_notes': update.releaseNotes,
    },
};

class AppInitResponseDto {
  const AppInitResponseDto(this._json);

  factory AppInitResponseDto.fromJson(Map<String, dynamic> json) =>
      AppInitResponseDto(json);

  final Map<String, dynamic> _json;

  AppInitData toDomain() => AppInitData(
    products: asMapList(
      _json['products'],
    ).map(productFromJson).toList(growable: false),
    legal: _legal(_json['legal']),
    update: _update(_json['update']),
  );

  static LegalInfo _legal(Object? raw) {
    final json = asMap(raw);
    return LegalInfo(
      privacyUrl: json['privacy_url'] as String?,
      termsUrl: json['terms_url'] as String?,
      subscriptionTermsUrl: json['subscription_terms_url'] as String?,
    );
  }

  static UpdateInfo? _update(Object? raw) {
    if (raw is! Map) return null;
    final json = asMap(raw);
    return UpdateInfo(
      forceUpdate: asBool(json['force_update']),
      latestVersion: json['latest_version'] as String?,
      updateUrl: json['update_url'] as String?,
      releaseNotes: json['release_notes'] as String?,
    );
  }
}

class CreateOrderResponseDto {
  const CreateOrderResponseDto(this._json);

  factory CreateOrderResponseDto.fromJson(Map<String, dynamic> json) =>
      CreateOrderResponseDto(json);

  final Map<String, dynamic> _json;

  CreateOrderResult toDomain() => CreateOrderResult(
    orderNo: asString(_json['order_no']),
    productCode: asString(_json['product_code']),
    storeProductId: asString(_json['store_product_id']),
    amountCents: asInt(_json['amount_cents']),
    currency: asString(_json['currency'], 'USD'),
    expiresAt: _flexibleTimestamp(_json['expires_at']),
  );
}

class VerifyReceiptResponseDto {
  const VerifyReceiptResponseDto(this._json);

  factory VerifyReceiptResponseDto.fromJson(Map<String, dynamic> json) =>
      VerifyReceiptResponseDto(json);

  final Map<String, dynamic> _json;

  VerifyResult toDomain() => VerifyResult(
    orderNo: asString(_json['order_no']),
    status: asString(_json['status']),
    grantStatus: asString(_json['grant_status']),
    grant: _grant(_json['grant']),
    subscription: _subscription(_json['subscription']),
  );

  static OrderGrant? _grant(Object? raw) {
    if (raw is! Map) return null;
    final json = asMap(raw);
    return OrderGrant(
      type: asString(json['type']),
      credits: asInt(json['credits']),
      features: asStringList(json['features']),
    );
  }

  static OrderSubscription? _subscription(Object? raw) {
    if (raw is! Map) return null;
    final json = asMap(raw);
    return OrderSubscription(
      originalTransactionId: asString(json['original_transaction_id']),
      status: asString(json['status']),
      expiresDate: json['expires_date'] != null
          ? _flexibleTimestamp(json['expires_date'])
          : null,
      autoRenew: asBool(json['auto_renew']),
    );
  }
}
