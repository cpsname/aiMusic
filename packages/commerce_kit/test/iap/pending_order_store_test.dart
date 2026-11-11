import 'package:commerce_kit/src/iap/data/pending_order_store.dart';
import 'package:commerce_kit/src/iap/domain/order_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  PendingOrder order(String no, String storeId) => PendingOrder(
        orderNo: no,
        productCode: 'pro_monthly',
        storeProductId: storeId,
        createdAt: DateTime.utc(2026),
      );

  test('save, find by store product id, and remove', () async {
    final store = PendingOrderStore(KeyValueStore(prefs));
    await store.save(order('O1', 'sp1'));
    await store.save(order('O2', 'sp2'));

    expect(store.all().length, 2);
    expect(store.findByStoreProductId('sp2')?.orderNo, 'O2');
    expect(store.findByStoreProductId('missing'), isNull);

    await store.remove('O1');
    expect(store.all().length, 1);
    expect(store.findByStoreProductId('sp1'), isNull);
  });

  test('persists across store instances (same backing store)', () async {
    await PendingOrderStore(KeyValueStore(prefs)).save(order('O9', 'sp9'));
    final reopened = PendingOrderStore(KeyValueStore(prefs));
    expect(reopened.findByStoreProductId('sp9')?.orderNo, 'O9');
  });

  test('degrades to empty on corrupt (non-JSON) persisted data', () async {
    await prefs.setString('iap.pending_orders', 'totally not json');
    expect(PendingOrderStore(KeyValueStore(prefs)).all(), isEmpty);
  });

  test('isolates an unparseable record but keeps the valid ones', () async {
    final kv = KeyValueStore(prefs);
    await PendingOrderStore(kv).save(order('O1', 'sp1'));

    // Corrupt one record (wrong type for created_at → fromJson throws).
    final raw = kv.getJson('iap.pending_orders')!;
    raw['BAD'] = {'created_at': 'not-a-number'};
    await kv.setJson('iap.pending_orders', raw);

    final reopened = PendingOrderStore(kv);
    expect(reopened.all().length, 1);
    expect(reopened.findByStoreProductId('sp1')?.orderNo, 'O1');
  });
}
