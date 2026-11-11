import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet/ui/common/error_retry_view.dart';
import 'package:songlet/ui/me/profile_page.dart';
import 'package:songlet/ui/paywall/paywall_page.dart';
import 'package:songlet/ui/upload/upload_demo_page.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// LTR + RTL golden snapshots of the key screens (DF⑤). Rendered with
/// reduce-motion forced on (via `pumpApp(reduceMotion: true)`) so the perpetual
/// Aura/skeleton animations rest on a static frame — making the goldens
/// deterministic. The RTL variant forces `Directionality.rtl` — locale-independent,
/// since RTL is a layout property, not a shipped language (the template ships en/zh
/// and integrators batch-translate RTL languages later). Comparing the two
/// directions guards against directional-layout regressions.
void main() {
  const en = Locale('en');

  final paywallOverrides = [
    storeProductsProvider.overrideWith((ref) => [sampleStoreProduct()]),
    subscriptionEntitlementProvider.overrideWithValue(
      SubscriptionEntitlement.none,
    ),
  ];

  final profileOverrides = [
    // An entitled account, so the goldens cover the persistent
    // manage-subscription entry (a directional trailing control) in ltr + rtl.
    currentAccountProvider.overrideWith(
      (ref) => sampleAccount(
        subscription: const Subscription(status: 'active', isAutoRenew: true),
      ),
    ),
    walletSnapshotProvider.overrideWith(
      (ref) => const WalletSnapshot(
        balance: 4980,
        frozen: 20,
        totalCredited: 5000,
        totalDebited: 0,
        features: [
          WalletFeature(code: 'vip', name: 'VIP', source: 'iap_subscription'),
        ],
      ),
    ),
  ];

  Future<void> fixedSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('paywall — ltr', (tester) async {
    await fixedSurface(tester);
    await pumpApp(
      tester,
      const PaywallPage(),
      overrides: paywallOverrides,
      locale: en,
      reduceMotion: true,
    );
    await expectLater(
      find.byType(PaywallPage),
      matchesGoldenFile('goldens/paywall_ltr.png'),
    );
  });

  testWidgets('paywall — rtl', (tester) async {
    await fixedSurface(tester);
    await pumpApp(
      tester,
      const PaywallPage(),
      overrides: paywallOverrides,
      locale: en,
      textDirection: TextDirection.rtl,
      reduceMotion: true,
    );
    await expectLater(
      find.byType(PaywallPage),
      matchesGoldenFile('goldens/paywall_rtl.png'),
    );
  });

  testWidgets('profile — ltr', (tester) async {
    await fixedSurface(tester);
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: profileOverrides,
      locale: en,
      reduceMotion: true,
    );
    await expectLater(
      find.byType(ProfilePage),
      matchesGoldenFile('goldens/profile_ltr.png'),
    );
  });

  testWidgets('profile — rtl', (tester) async {
    await fixedSurface(tester);
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: profileOverrides,
      locale: en,
      textDirection: TextDirection.rtl,
      reduceMotion: true,
    );
    await expectLater(
      find.byType(ProfilePage),
      matchesGoldenFile('goldens/profile_rtl.png'),
    );
  });

  testWidgets('upload — ltr', (tester) async {
    await fixedSurface(tester);
    await pumpApp(
      tester,
      const UploadDemoPage(),
      locale: en,
      reduceMotion: true,
    );
    await expectLater(
      find.byType(UploadDemoPage),
      matchesGoldenFile('goldens/upload_ltr.png'),
    );
  });

  testWidgets('upload — rtl', (tester) async {
    await fixedSurface(tester);
    await pumpApp(
      tester,
      const UploadDemoPage(),
      locale: en,
      textDirection: TextDirection.rtl,
      reduceMotion: true,
    );
    await expectLater(
      find.byType(UploadDemoPage),
      matchesGoldenFile('goldens/upload_rtl.png'),
    );
  });

  // The reusable network-failure retry surface (StatusView via ErrorRetryView),
  // in its full-screen offline form. Covered ltr + rtl like the other screens.
  ErrorRetryView offlineError() => ErrorRetryView(
    failure: const NetworkFailure(
      message: '',
      kind: NetworkFailureKind.offline,
    ),
    onRetry: () {},
  );

  testWidgets('network error — ltr', (tester) async {
    await fixedSurface(tester);
    await pumpApp(tester, offlineError(), locale: en, reduceMotion: true);
    await expectLater(
      find.byType(ErrorRetryView),
      matchesGoldenFile('goldens/network_error_ltr.png'),
    );
  });

  testWidgets('network error — rtl', (tester) async {
    await fixedSurface(tester);
    await pumpApp(
      tester,
      offlineError(),
      locale: en,
      textDirection: TextDirection.rtl,
      reduceMotion: true,
    );
    await expectLater(
      find.byType(ErrorRetryView),
      matchesGoldenFile('goldens/network_error_rtl.png'),
    );
  });
}
