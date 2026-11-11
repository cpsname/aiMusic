import 'package:commerce_kit/commerce_kit.dart';
import 'package:commerce_kit/src/iap/data/iap_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('productFromJson', () {
    test('maps kinds and core fields', () {
      final product = productFromJson({
        'product_code': 'pro_monthly',
        'store_product_id': 'com.example.pro_monthly',
        'product_name': 'Pro Monthly',
        'product_kind': 'auto_renewable',
        'price_cents': 998,
        'currency': 'USD',
        'highlight_tag': 'Recommended',
        'sort_order': 2,
      });
      expect(product.kind, ProductKind.autoRenewable);
      expect(product.isSubscription, isTrue);
      expect(product.priceCents, 998);
      expect(product.highlightTag, 'Recommended');
    });
  });

  group('CreateOrderResponseDto.expires_at defensive parse', () {
    CreateOrderResult parse(Object expiresAt) =>
        CreateOrderResponseDto.fromJson({
          'order_no': 'O',
          'store_product_id': 's',
          'amount_cents': 998,
          'currency': 'USD',
          'expires_at': expiresAt,
        }).toDomain();

    test('value < 1e12 is treated as Unix seconds', () {
      expect(
        parse(1735689600).expiresAt,
        DateTime.fromMillisecondsSinceEpoch(1735689600 * 1000, isUtc: true),
      );
    });

    test('value >= 1e12 is treated as Unix milliseconds', () {
      expect(
        parse(1735689600000).expiresAt,
        DateTime.fromMillisecondsSinceEpoch(1735689600000, isUtc: true),
      );
    });
  });

  group('AppInitResponseDto', () {
    test('parses products, legal links and a force-update prompt', () {
      final data = AppInitResponseDto.fromJson({
        'products': [
          {
            'product_code': 'pro_monthly',
            'store_product_id': 'com.example.pro_monthly',
            'product_name': 'Pro',
            'product_kind': 'auto_renewable',
            'price_cents': 998,
            'currency': 'USD',
            'is_visible': true,
            'is_active': true,
            'sort_order': 1,
          },
          {
            'product_code': 'hidden',
            'store_product_id': 'com.example.hidden',
            'product_name': 'Hidden',
            'product_kind': 'consumable',
            'price_cents': 100,
            'currency': 'USD',
            'is_visible': false,
          },
        ],
        'legal': {'privacy_url': 'https://p', 'terms_url': 'https://t'},
        'update': {'force_update': true, 'latest_version': '2.0.0'},
      }).toDomain();

      expect(data.products.length, 2);
      expect(data.visibleProducts.length, 1); // hidden excluded
      expect(data.legal.privacyUrl, 'https://p');
      expect(data.update?.forceUpdate, isTrue);
    });
  });

  group('VerifyReceiptResponseDto', () {
    test('parses status, grant and subscription', () {
      final result = VerifyReceiptResponseDto.fromJson({
        'order_no': 'O1',
        'status': 'completed',
        'grant_status': 'granted',
        'grant': {
          'type': 'quota_and_feature',
          'credits': 500,
          'features': ['vip'],
        },
        'subscription': {
          'original_transaction_id': '2000000123',
          'status': 'active',
          'expires_date': 1735689600000,
          'auto_renew': true,
        },
      }).toDomain();

      expect(result.isCompleted, isTrue);
      expect(result.grant?.credits, 500);
      expect(result.subscription?.status, 'active');
      expect(result.subscription?.autoRenew, isTrue);
    });
  });
}
