import 'package:infra_core/infra_core.dart';

import '../../common/json.dart';
import '../domain/iap_models.dart';
import '../domain/product_query_result.dart';
import '../domain/store_offer.dart';
import 'iap_dtos.dart';

/// Persists the merged store product list (catalog + live store details + offers)
/// so the paywall stays available when a later store query fails or is offline.
///
/// Non-sensitive, so it lives in [KeyValueStore] (SharedPreferences). Entries
/// carry a `cached_at` stamp: [read] reports `isStale` once past [validity]
/// (default 24h), and the caller serves stale data only as a fallback. A region
/// change is detectable via [isCurrencyMismatch].
class ProductCache {
  ProductCache({
    required KeyValueStore store,
    Duration validity = const Duration(hours: 24),
    DateTime Function()? now,
  })  : _store = store,
        _validity = validity,
        _now = now ?? DateTime.now;

  static const _key = 'iap.products.v1';

  final KeyValueStore _store;
  final Duration _validity;
  final DateTime Function() _now;

  /// The cached products, or null when absent/corrupt. `isStale` is true once
  /// the entry is older than [validity].
  ProductQueryResult? read({String languageTag = ''}) {
    final entry = _store.getJson(_cacheKey(languageTag));
    if (entry == null) return null;
    final cachedAt = asInt(entry['cached_at']);
    if (cachedAt <= 0) return null;
    final raw = asMapList(entry['products']);
    if (raw.isEmpty) return null;

    final at = DateTime.fromMillisecondsSinceEpoch(cachedAt, isUtc: true);
    final isStale = _now().toUtc().difference(at) > _validity;
    return ProductQueryResult(
      products: raw.map(_storeProductFromJson).toList(growable: false),
      isFromCache: true,
      isStale: isStale,
      queriedAt: at,
    );
  }

  Future<void> write(List<StoreProduct> products, {String languageTag = ''}) => _store.setJson(_cacheKey(languageTag), {
    'cached_at': _now().toUtc().millisecondsSinceEpoch,
    'products': [for (final p in products) _storeProductToJson(p)],
  });

  Future<void> clear({String languageTag = ''}) => _store.remove(_cacheKey(languageTag));

  String _cacheKey(String languageTag) => languageTag.isEmpty ? _key : '$_key.$languageTag';

  /// True when any cached product's currency differs from [currencyCode] — the
  /// user likely switched App Store / Play regions, so the cache should be
  /// dropped and re-queried.
  bool isCurrencyMismatch(String currencyCode, {String languageTag = ''}) {
    final entry = _store.getJson(_cacheKey(languageTag));
    if (entry == null) return false;
    return asMapList(entry['products']).any(
      (p) => asString(asMap(p['details'])['currency_code']) != currencyCode,
    );
  }

  // --- serialization --------------------------------------------------------

  Map<String, dynamic> _storeProductToJson(StoreProduct p) => {
    'product': productToJson(p.product),
    'details': _detailsToJson(p.details),
  };

  StoreProduct _storeProductFromJson(Map<String, dynamic> json) => StoreProduct(
    product: productFromJson(asMap(json['product'])),
    details: _detailsFromJson(asMap(json['details'])),
  );

  Map<String, dynamic> _detailsToJson(StoreProductDetails d) => {
    'id': d.id,
    'title': d.title,
    'description': d.description,
    'price': d.price,
    'raw_price': d.rawPrice,
    'currency_code': d.currencyCode,
    if (d.currencySymbol != null) 'currency_symbol': d.currencySymbol,
    'store_type': d.storeType.name,
    if (d.subscriptionPeriod != null) 'period': _periodToJson(d.subscriptionPeriod!),
    if (d.introductoryOffer != null) 'intro': _offerToJson(d.introductoryOffer!),
    'promos': [for (final o in d.promotionalOffers) _offerToJson(o)],
  };

  StoreProductDetails _detailsFromJson(Map<String, dynamic> j) =>
      StoreProductDetails(
        id: asString(j['id']),
        title: asString(j['title']),
        description: asString(j['description']),
        price: asString(j['price']),
        rawPrice: (j['raw_price'] as num?)?.toDouble() ?? 0,
        currencyCode: asString(j['currency_code']),
        currencySymbol: j['currency_symbol'] as String?,
        storeType: _storeType(asString(j['store_type'])),
        subscriptionPeriod:
            j['period'] is Map ? _periodFromJson(asMap(j['period'])) : null,
        introductoryOffer:
            j['intro'] is Map ? _offerFromJson(asMap(j['intro'])) : null,
        promotionalOffers:
            asMapList(j['promos']).map(_offerFromJson).toList(growable: false),
      );

  Map<String, dynamic> _offerToJson(ProductOffer o) => {
    if (o.identifier != null) 'identifier': o.identifier,
    'type': o.type.name,
    'payment_mode': o.paymentMode.name,
    'formatted_price': o.formattedPrice,
    'raw_price': o.rawPrice,
    'currency_code': o.currencyCode,
    'number_of_periods': o.numberOfPeriods,
    'period': _periodToJson(o.period),
  };

  ProductOffer _offerFromJson(Map<String, dynamic> j) => ProductOffer(
    identifier: j['identifier'] as String?,
    type: asString(j['type']) == 'promotional'
        ? OfferType.promotional
        : OfferType.introductory,
    paymentMode: _paymentMode(asString(j['payment_mode'])),
    formattedPrice: asString(j['formatted_price']),
    rawPrice: (j['raw_price'] as num?)?.toDouble() ?? 0,
    currencyCode: asString(j['currency_code']),
    numberOfPeriods: asInt(j['number_of_periods']),
    period: _periodFromJson(asMap(j['period'])),
  );

  Map<String, dynamic> _periodToJson(SubscriptionPeriodValue p) => {
    'units': p.numberOfUnits,
    'unit': p.unit.name,
  };

  SubscriptionPeriodValue _periodFromJson(Map<String, dynamic> j) =>
      SubscriptionPeriodValue(
        numberOfUnits: asInt(j['units']),
        unit: _periodUnit(asString(j['unit'])),
      );

  StoreType _storeType(String name) => switch (name) {
    'playStore' => StoreType.playStore,
    'web' => StoreType.web,
    _ => StoreType.appStore,
  };

  OfferPaymentMode _paymentMode(String name) => switch (name) {
    'payAsYouGo' => OfferPaymentMode.payAsYouGo,
    'payUpFront' => OfferPaymentMode.payUpFront,
    _ => OfferPaymentMode.freeTrial,
  };

  PeriodUnit _periodUnit(String name) => switch (name) {
    'day' => PeriodUnit.day,
    'week' => PeriodUnit.week,
    'year' => PeriodUnit.year,
    _ => PeriodUnit.month,
  };
}
