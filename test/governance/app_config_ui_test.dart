import 'package:app_config/app_config.dart';
import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/ui/paywall/music_paywall_page.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('kill-switch replaces the paywall with the unavailable notice', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const MusicPaywallPage(),
      appConfig: const AppConfig(
        maintenance: Maintenance.inactive,
        killSwitches: [AppFeatureCodes.iapPurchase],
        config: {},
      ),
    );

    expect(
      find.text('This feature is temporarily unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Continue'), findsNothing); // the buy CTA is gone
  });

  testWidgets('remote config promo_text renders a promo banner', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const MusicPaywallPage(),
      appConfig: const AppConfig(
        maintenance: Maintenance.inactive,
        killSwitches: [],
        config: {'promo_text': 'Spring sale!'},
      ),
      overrides: [
        storeProductsProvider.overrideWith((ref) => [sampleStoreProduct()]),
        subscriptionEntitlementProvider.overrideWithValue(
          SubscriptionEntitlement.none,
        ),
      ],
    );

    expect(find.text('Spring sale!'), findsOneWidget);
  });
}
