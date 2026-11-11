import 'package:meta/meta.dart';

import 'iap_models.dart';

/// The outcome of merging the backend catalog with live store details.
@immutable
class ProductQueryResult {
  const ProductQueryResult({
    required this.products,
    this.unavailableIds = const [],
    this.isFromCache = false,
    this.isStale = false,
    this.queriedAt,
  });

  /// Merged products (backend ∩ store), in catalog (display) order.
  final List<StoreProduct> products;

  /// Catalog `storeProductId`s the store returned no details for — dropped from
  /// [products] (an unpurchasable product is never shown with a faked price).
  final List<String> unavailableIds;

  /// True when [products] were served from the persistent cache.
  final bool isFromCache;

  /// True when the served cache is past its validity window.
  final bool isStale;

  final DateTime? queriedAt;

  bool get hasUnavailableProducts => unavailableIds.isNotEmpty;
}
