import 'package:infra_core/infra_core.dart';

import '../domain/order_models.dart';
import '../domain/pending_order_repository.dart';

/// Persists orders awaiting native completion + verification, keyed by order
/// number. Saved *before* the native purchase so an interrupted flow can be
/// recovered on the next launch.
class PendingOrderStore implements PendingOrderRepository {
  PendingOrderStore(this._kv);

  static const String _key = 'iap.pending_orders';

  final KeyValueStore _kv;

  @override
  Future<void> save(PendingOrder order) async {
    final map = _read()..[order.orderNo] = order;
    await _write(map);
  }

  @override
  Future<void> remove(String orderNo) async {
    final map = _read()..remove(orderNo);
    await _write(map);
  }

  @override
  List<PendingOrder> all() => _read().values.toList(growable: false);

  @override
  PendingOrder? findByStoreProductId(String storeProductId) {
    for (final order in _read().values) {
      if (order.storeProductId == storeProductId) return order;
    }
    return null;
  }

  Map<String, PendingOrder> _read() {
    final raw = _kv.getJson(_key);
    if (raw == null) return <String, PendingOrder>{};
    final result = <String, PendingOrder>{};
    raw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        try {
          result[key] = PendingOrder.fromJson(value);
        } on Object {
          // Isolate an unparseable record rather than failing the whole read.
        }
      }
    });
    return result;
  }

  Future<void> _write(Map<String, PendingOrder> map) => _kv.setJson(
        _key,
        {for (final entry in map.entries) entry.key: entry.value.toJson()},
      );
}
