import 'iap_models.dart';
import 'product_query_result.dart';

/// Pure domain merge of the backend catalog with live store details.
///
/// Matches by `storeProductId`. A catalog entry the store didn't return details
/// for goes to [ProductQueryResult.unavailableIds] and is **dropped** — the
/// paywall never shows an unpurchasable product with a faked backend price.
/// Output order mirrors [catalog] (the backend's display order).
class ProductMergeService {
  const ProductMergeService();

  ProductQueryResult merge({
    required List<Product> catalog,
    required List<StoreProductDetails> storeDetails,
    bool isFromCache = false,
    bool isStale = false,
    DateTime? queriedAt,
  }) {
    final byStoreId = {for (final d in storeDetails) d.id: d};
    final products = <StoreProduct>[];
    final unavailableIds = <String>[];

    for (final item in catalog) {
      final detail = byStoreId[item.storeProductId];
      if (detail != null) {
        products.add(StoreProduct(product: item, details: detail));
      } else {
        unavailableIds.add(item.storeProductId);
      }
    }

    return ProductQueryResult(
      products: products,
      unavailableIds: unavailableIds,
      isFromCache: isFromCache,
      isStale: isStale,
      queriedAt: queriedAt,
    );
  }
}
