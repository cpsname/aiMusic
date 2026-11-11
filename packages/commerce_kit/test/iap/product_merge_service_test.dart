import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const merge = ProductMergeService();

  Product item(String code, String storeId) => Product(
    productCode: code,
    storeProductId: storeId,
    productName: '',
    kind: ProductKind.autoRenewable,
    priceCents: 0,
    currency: 'USD',
  );

  StoreProductDetails detail(String storeId, String title) => StoreProductDetails(
    id: storeId,
    title: title,
    description: '',
    price: r'$1.00',
    rawPrice: 1,
    currencyCode: 'USD',
  );

  test('matches by storeProductId and preserves catalog (display) order', () {
    final result = merge.merge(
      catalog: [item('a', 'store.a'), item('b', 'store.b')],
      storeDetails: [detail('store.b', 'B'), detail('store.a', 'A')],
    );

    expect(result.products.map((p) => p.productCode), ['a', 'b']);
    expect(result.products.first.displayName, 'A'); // store title wins
    expect(result.unavailableIds, isEmpty);
    expect(result.hasUnavailableProducts, isFalse);
  });

  test('drops catalog products the store did not return → unavailableIds', () {
    final result = merge.merge(
      catalog: [item('a', 'store.a'), item('b', 'store.b')],
      storeDetails: [detail('store.a', 'A')], // store has no details for b
    );

    expect(result.products.map((p) => p.productCode), ['a']);
    expect(result.unavailableIds, ['store.b']);
    expect(result.hasUnavailableProducts, isTrue);
  });
}
