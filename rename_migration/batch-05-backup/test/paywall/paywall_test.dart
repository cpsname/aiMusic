import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songlet/ui/common/messages.dart';
import 'package:songlet/ui/paywall/paywall_page.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';
import '../support/music_harness.dart' show reveal;

/// Wraps the paywall in a [MessageHost] bound to the app's
/// [messageControllerProvider], so the overlay feedback (which the app mounts via
/// `MaterialApp.builder`) renders in the test.
Widget _paywallWithMessages() => Consumer(
  builder: (context, ref, _) => MessageHost(
    controller: ref.watch(messageControllerProvider),
    child: const PaywallPage(),
  ),
);

void main() {
  testWidgets('renders products dynamically from the store', (tester) async {
    await pumpApp(
      tester,
      const PaywallPage(),
      overrides: [
        storeProductsProvider.overrideWith((ref) => [sampleStoreProduct()]),
        subscriptionEntitlementProvider.overrideWithValue(
          SubscriptionEntitlement.none,
        ),
      ],
    );

    expect(find.text('Pro Monthly'), findsOneWidget);
    expect(find.text(r'US$9.98/mo'), findsOneWidget);
    expect(find.text('40 full songs per month'), findsOneWidget);
    expect(find.text('Subscribe'), findsOneWidget);
  });

  testWidgets('empty catalog shows the no-products message', (tester) async {
    await pumpApp(
      tester,
      const PaywallPage(),
      overrides: [
        storeProductsProvider.overrideWith((ref) => <StoreProduct>[]),
        subscriptionEntitlementProvider.overrideWithValue(
          SubscriptionEntitlement.none,
        ),
      ],
    );

    expect(find.text('No products available right now.'), findsOneWidget);
  });

  testWidgets('load error shows a retry action, no raw exception leak', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const PaywallPage(),
      overrides: [
        storeProductsProvider.overrideWith(
          (ref) => Future<List<StoreProduct>>.error(
            StateError('boom-internal-detail'),
          ),
        ),
      ],
    );

    expect(find.text('Retry'), findsOneWidget);
    // Screen-specific title preserved for a non-network load failure...
    expect(find.text('Couldn\'t load products'), findsOneWidget);
    // ...and the raw exception string must NOT reach the user.
    expect(find.textContaining('boom-internal-detail'), findsNothing);
    expect(find.textContaining('Bad state'), findsNothing);
  });

  testWidgets('billing-retry shows the update-payment banner', (tester) async {
    await pumpApp(
      tester,
      const PaywallPage(),
      overrides: [
        storeProductsProvider.overrideWith((ref) => [sampleStoreProduct()]),
        subscriptionEntitlementProvider.overrideWithValue(
          const SubscriptionEntitlement(
            renewalState: SubscriptionRenewalState.inBillingRetryPeriod,
          ),
        ),
      ],
    );

    expect(find.textContaining('Update your payment method'), findsOneWidget);
  });

  testWidgets(
    'tapping Continue starts a purchase and the button shows loading',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = FakeStoreClient();
      addTearDown(store.dispose);

      await pumpApp(
        tester,
        const PaywallPage(),
        overrides: [
          storeProductsProvider.overrideWith((ref) => [sampleStoreProduct()]),
          subscriptionEntitlementProvider.overrideWithValue(
            SubscriptionEntitlement.none,
          ),
          iapRepositoryProvider.overrideWithValue(
            FakeIapRepository(order: sampleOrder()),
          ),
          storeClientProvider.overrideWithValue(store),
          keyValueStoreProvider.overrideWithValue(KeyValueStore(prefs)),
          iapClockProvider.overrideWithValue(() => DateTime.utc(2026)),
          walletSnapshotProvider.overrideWith((ref) => WalletSnapshot.empty),
        ],
      );

      await tester.ensureVisible(find.text('Subscribe'));
      await tester.pump();
      await tester.tap(find.text('Subscribe'));
      await tester.pump();
      await tester.pump();

      expect(store.buyCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Resolve the in-flight purchase (cancel) so no timeout timer leaks.
      store.emit(
        const StorePurchase(
          productId: 'com.example.pro_monthly',
          transactionId: '',
          status: StorePurchaseStatus.canceled,
        ),
      );
      await tester.pump();
      await tester.pump();
    },
  );

  testWidgets('a deferred (Ask to Buy) purchase shows the awaiting hint', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FakeStoreClient();
    addTearDown(store.dispose);

    await pumpApp(
      tester,
      const PaywallPage(),
      overrides: [
        storeProductsProvider.overrideWith((ref) => [sampleStoreProduct()]),
        subscriptionEntitlementProvider.overrideWithValue(
          SubscriptionEntitlement.none,
        ),
        iapRepositoryProvider.overrideWithValue(
          FakeIapRepository(order: sampleOrder()),
        ),
        storeClientProvider.overrideWithValue(store),
        keyValueStoreProvider.overrideWithValue(KeyValueStore(prefs)),
        iapClockProvider.overrideWithValue(() => DateTime.utc(2026)),
        walletSnapshotProvider.overrideWith((ref) => WalletSnapshot.empty),
      ],
    );

    await tester.ensureVisible(find.text('Subscribe'));
    await tester.pump();
    await tester.tap(find.text('Subscribe'));
    await tester.pump();
    await tester.pump();

    store.emit(
      const StorePurchase(
        productId: 'com.example.pro_monthly',
        transactionId: '',
        status: StorePurchaseStatus.pending,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Waiting for approval'), findsWidgets);
  });

  testWidgets('Restore with nothing to restore → "No purchases to restore"', (
    tester,
  ) async {
    final store = FakeStoreClient();
    addTearDown(store.dispose);

    await pumpApp(
      tester,
      _paywallWithMessages(),
      overrides: [
        storeProductsProvider.overrideWith((ref) => [sampleStoreProduct()]),
        subscriptionEntitlementProvider.overrideWithValue(
          SubscriptionEntitlement.none,
        ),
        storeClientProvider.overrideWithValue(store),
        restoreDrainWindowProvider.overrideWithValue(
          const Duration(milliseconds: 5),
        ),
        walletSnapshotProvider.overrideWith((ref) => WalletSnapshot.empty),
      ],
    );

    await reveal(tester, find.text('Restore purchases'));
    await tester.pump();
    await tester.tap(find.text('Restore purchases'));
    await tester.pump(); // restoring
    await tester.pump(const Duration(milliseconds: 20)); // drain window elapses
    await tester.pump();

    expect(store.restoreCount, 1);
    expect(find.textContaining('No purchases to restore'), findsWidgets);
  });

  testWidgets('Restore that finds an entitlement → "1 purchase restored"', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FakeStoreClient()
      ..restoreEmits = const [
        StorePurchase(
          productId: 'com.example.pro_monthly',
          transactionId: 'rtx-1',
          status: StorePurchaseStatus.restored,
        ),
      ];
    addTearDown(store.dispose);

    await pumpApp(
      tester,
      _paywallWithMessages(),
      overrides: [
        storeProductsProvider.overrideWith((ref) => [sampleStoreProduct()]),
        subscriptionEntitlementProvider.overrideWithValue(
          SubscriptionEntitlement.none,
        ),
        storeClientProvider.overrideWithValue(store),
        iapRepositoryProvider.overrideWithValue(
          FakeIapRepository(order: sampleOrder()),
        ),
        keyValueStoreProvider.overrideWithValue(KeyValueStore(prefs)),
        iapCatalogProvider.overrideWithValue([sampleStoreProduct().product]),
        restoreDrainWindowProvider.overrideWithValue(
          const Duration(milliseconds: 5),
        ),
        walletSnapshotProvider.overrideWith((ref) => WalletSnapshot.empty),
      ],
    );

    await reveal(tester, find.text('Restore purchases'));
    await tester.pump();
    await tester.tap(find.text('Restore purchases'));
    await tester.pump(); // restoring
    await tester.pump(const Duration(milliseconds: 20)); // drain + verify
    await tester.pump();

    expect(store.restoreCount, 1);
    expect(find.textContaining('1 purchase restored'), findsWidgets);
  });

  testWidgets('renders Terms / Privacy / Subscription legal links (3.1.2)', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const PaywallPage(),
      overrides: [
        storeProductsProvider.overrideWith((ref) => [sampleStoreProduct()]),
        subscriptionEntitlementProvider.overrideWithValue(
          SubscriptionEntitlement.none,
        ),
        legalInfoProvider.overrideWithValue(
          const LegalInfo(
            termsUrl: 'https://example.com/terms',
            privacyUrl: 'https://example.com/privacy',
            subscriptionTermsUrl: 'https://example.com/sub',
          ),
        ),
      ],
    );

    await reveal(tester, find.text('Terms of Use'));
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Subscription Terms'), findsOneWidget);
  });

  testWidgets('an empty catalog still offers Restore and the legal links', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const PaywallPage(),
      overrides: [
        storeProductsProvider.overrideWith((ref) => const <StoreProduct>[]),
        subscriptionEntitlementProvider.overrideWithValue(
          SubscriptionEntitlement.none,
        ),
        legalInfoProvider.overrideWithValue(
          const LegalInfo(
            termsUrl: 'https://example.com/terms',
            privacyUrl: 'https://example.com/privacy',
          ),
        ),
      ],
    );

    expect(find.text('No products available right now.'), findsOneWidget);
    await reveal(tester, find.text('Restore purchases'));
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  testWidgets(
    'backend omits legal links → compile-time fallbacks still render (3.1.2)',
    (tester) async {
      const env = EnvConfig(
        env: AppEnv.dev,
        baseUrl: 'http://localhost:9999/v1',
        distributionCode: 'ios_global',
        distributionSecret: 'secret',
        appCode: 'studio_app',
        bundleId: 'com.example.studio',
        iapChannel: 'appstore',
        privacyUrl: 'https://example.com/privacy-fallback',
      );

      await pumpApp(
        tester,
        const PaywallPage(),
        overrides: [
          storeProductsProvider.overrideWith((ref) => [sampleStoreProduct()]),
          subscriptionEntitlementProvider.overrideWithValue(
            SubscriptionEntitlement.none,
          ),
          legalInfoProvider.overrideWithValue(null),
          envConfigProvider.overrideWithValue(env),
        ],
      );

      // Terms: Apple standard-EULA last resort; Privacy: the PRIVACY_URL define.
      await reveal(tester, find.text('Terms of Use'));
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      // Subscription terms are server-only — absent stays absent.
      expect(find.text('Subscription Terms'), findsNothing);
    },
  );

  testWidgets(
    'a subscription product shows the auto-renewal disclosure (3.1.2)',
    (tester) async {
      await pumpApp(
        tester,
        const PaywallPage(),
        overrides: [
          storeProductsProvider.overrideWith((ref) => [sampleStoreProduct()]),
          subscriptionEntitlementProvider.overrideWithValue(
            SubscriptionEntitlement.none,
          ),
        ],
      );

      expect(find.textContaining('renew automatically'), findsOneWidget);
    },
  );

  testWidgets('a consumable-only catalog shows no auto-renewal disclosure', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const PaywallPage(),
      overrides: [
        storeProductsProvider.overrideWith(
          (ref) => [sampleStoreProduct(kind: ProductKind.consumable)],
        ),
        subscriptionEntitlementProvider.overrideWithValue(
          SubscriptionEntitlement.none,
        ),
      ],
    );

    expect(find.textContaining('renew automatically'), findsNothing);
  });
}
