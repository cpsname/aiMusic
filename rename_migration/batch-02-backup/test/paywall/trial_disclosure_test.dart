import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/l10n/generated/app_localizations.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../support/songlet_harness.dart';

void main() {
  setUp(mockNativeChannels);

  // Deliberately unlike rawPrice/currencyCode: the store's display string must
  // survive intact, even when the UI and storefront use different locales.
  const displayPrice = 'CHF\u00a012.90';
  for (final (tag, month, year) in [
    ('en', '/mo', '/yr'),
    ('de', '/Monat', '/Jahr'),
    ('hi', '/महीना', '/साल'),
  ]) {
    for (final annual in [false, true]) {
      testWidgets(
        '$tag trial discloses the selected ${annual ? 'year' : 'month'} price',
        (tester) async {
          final products = songletProducts();
          final trial = products
              .firstWhere((p) => p.storeProductId == SongletCatalog.proYearly)
              .introductoryOffer;
          final base = products.firstWhere(
            (p) =>
                p.storeProductId ==
                (annual ? SongletCatalog.proYearly : SongletCatalog.proMonthly),
          );
          final env = SongletTestEnv()
            ..products = [
              StoreProduct(
                product: base.product,
                details: StoreProductDetails(
                  id: base.storeProductId,
                  title: base.displayName,
                  description: base.details.description,
                  price: displayPrice,
                  rawPrice: 99,
                  currencyCode: 'USD',
                  subscriptionPeriod: base.subscriptionPeriod,
                  introductoryOffer: trial,
                ),
              ),
            ];
          await pumpRoute(tester, '/paywall', env: env, locale: Locale(tag));
          final l10n = await AppLocalizations.delegate.load(Locale(tag));
          final disclosure = find.textContaining(l10n.paywallAutoRenewNotice);
          await reveal(tester, disclosure);
          final text = tester.widget<Text>(disclosure).data!;
          expect(text, contains('$displayPrice${annual ? year : month}'));
          expect(
            text,
            isNot(contains('$displayPrice${annual ? month : year}')),
          );
          expect(text, contains(l10n.paywallAutoRenewNotice));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('live StoreKit period takes precedence over the catalog cycle', (
    tester,
  ) async {
    final base = songletProducts().firstWhere(
      (p) => p.storeProductId == SongletCatalog.proYearly,
    );
    final env = SongletTestEnv()
      ..products = [
        StoreProduct(
          product: base.product,
          details: StoreProductDetails(
            id: base.storeProductId,
            title: base.displayName,
            description: base.details.description,
            price: displayPrice,
            rawPrice: 99,
            currencyCode: 'USD',
            subscriptionPeriod: const SubscriptionPeriodValue(
              numberOfUnits: 1,
              unit: PeriodUnit.month,
            ),
            introductoryOffer: base.introductoryOffer,
          ),
        ),
      ];
    await pumpRoute(tester, '/paywall', env: env);
    final disclosure = find.textContaining('After your free trial');
    await reveal(tester, disclosure);
    final text = tester.widget<Text>(disclosure).data!;
    expect(text, contains('$displayPrice/mo'));
    expect(text, isNot(contains('$displayPrice/yr')));
    expect(tester.takeException(), isNull);
  });
}
