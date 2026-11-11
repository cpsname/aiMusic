import 'order_models.dart';

/// Domain contract for persisting orders awaiting native completion and
/// server-side verification. The application layer depends on this interface;
/// the concrete implementation (data layer, `PendingOrderStore`) is bound in the
/// composition root (`iap_providers.dart`).
///
/// An order is saved *before* the native purchase so an interrupted flow can be
/// recovered on the next launch.
abstract interface class PendingOrderRepository {
  /// Upserts [order], keyed by its order number.
  Future<void> save(PendingOrder order);

  /// Removes the pending order identified by [orderNo] (no-op when absent).
  Future<void> remove(String orderNo);

  /// Every order currently awaiting completion.
  List<PendingOrder> all();

  /// The pending order for [storeProductId], or null when there is none.
  PendingOrder? findByStoreProductId(String storeProductId);
}
