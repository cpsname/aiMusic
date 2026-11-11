import 'package:commerce_kit/commerce_kit.dart';
import 'package:commerce_kit/src/iap/data/product_detail_extractor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

AppStoreProduct2Details _sk2({List<SK2SubscriptionOffer> offers = const []}) {
  return AppStoreProduct2Details.fromSK2Product(
    SK2Product(
      id: 'vizgo.sub.weekly',
      displayName: 'Weekly Pro',
      displayPrice: r'$0.58',
      description: 'Weekly subscription',
      price: 0.58,
      type: SK2ProductType.autoRenewable,
      priceLocale: SK2PriceLocale(currencyCode: 'USD', currencySymbol: r'$'),
      subscription: SK2SubscriptionInfo(
        subscriptionGroupID: 'group.pro',
        promotionalOffers: offers,
        subscriptionPeriod: const SK2SubscriptionPeriod(
          value: 1,
          unit: SK2SubscriptionPeriodUnit.week,
        ),
      ),
    ),
  );
}

void main() {
  const extractor = ProductDetailExtractor();

  test('SK2: extracts store type, title, period, intro trial, promo offer', () {
    final details = _sk2(
      offers: [
        SK2SubscriptionOffer(
          price: 0,
          type: SK2SubscriptionOfferType.introductory,
          period: const SK2SubscriptionPeriod(
            value: 3,
            unit: SK2SubscriptionPeriodUnit.day,
          ),
          periodCount: 1,
          paymentMode: SK2SubscriptionOfferPaymentMode.freeTrial,
        ),
        SK2SubscriptionOffer(
          id: 'promo-week',
          price: 0.29,
          type: SK2SubscriptionOfferType.promotional,
          period: const SK2SubscriptionPeriod(
            value: 1,
            unit: SK2SubscriptionPeriodUnit.week,
          ),
          periodCount: 2,
          paymentMode: SK2SubscriptionOfferPaymentMode.payAsYouGo,
        ),
      ],
    );

    expect(extractor.detectStoreType(details), StoreType.appStore);
    expect(extractor.cleanTitle(details), 'Weekly Pro');
    expect(
      extractor.extractSubscriptionPeriod(details),
      const SubscriptionPeriodValue(numberOfUnits: 1, unit: PeriodUnit.week),
    );

    final intro = extractor.extractIntroductoryOffer(details);
    expect(intro, isNotNull);
    expect(intro!.isFreeTrial, isTrue);
    expect(intro.type, OfferType.introductory);
    expect(intro.period.displayLabel, '3 days');

    final promos = extractor.extractPromotionalOffers(details);
    expect(promos, hasLength(1));
    expect(promos.first.type, OfferType.promotional);
    expect(promos.first.identifier, 'promo-week');
    expect(promos.first.numberOfPeriods, 2);
  });

  test('SK2: no offers → null intro, empty promos', () {
    final details = _sk2();
    expect(extractor.extractIntroductoryOffer(details), isNull);
    expect(extractor.extractPromotionalOffers(details), isEmpty);
    expect(extractor.extractSubscriptionPeriod(details)?.unit, PeriodUnit.week);
  });
}
