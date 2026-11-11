import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet/ui/me/profile_page.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('data state shows the name, balance and active features', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: [
        currentAccountProvider.overrideWith((ref) => sampleAccount()),
        walletSnapshotProvider.overrideWith(
          (ref) => const WalletSnapshot(
            balance: 4980,
            frozen: 20,
            totalCredited: 5000,
            totalDebited: 0,
            features: [
              WalletFeature(
                code: 'vip',
                name: 'VIP',
                source: 'iap_subscription',
              ),
            ],
          ),
        ),
      ],
    );

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('4,980'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);
    // No subscription on the account → no manage entry to a pointless page.
    expect(find.text('Manage subscription'), findsNothing);
    // Signed-in accounts keep sign-out only: a local wipe would masquerade as
    // deletion while the server account survives (needs the backend endpoint).
    expect(find.text('Delete account'), findsNothing);
  });

  testWidgets('an active subscription shows a persistent manage entry', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: [
        currentAccountProvider.overrideWith(
          (ref) => sampleAccount(
            subscription: const Subscription(
              status: 'active',
              isAutoRenew: true,
            ),
          ),
        ),
        walletSnapshotProvider.overrideWith((ref) => WalletSnapshot.empty),
      ],
    );

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Manage subscription'), findsOneWidget);
  });

  testWidgets('billing retry also shows the manage entry (it is the fix)', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: [
        currentAccountProvider.overrideWith(
          (ref) => sampleAccount(
            subscription: const Subscription(status: 'billing_retry'),
          ),
        ),
        walletSnapshotProvider.overrideWith((ref) => WalletSnapshot.empty),
      ],
    );

    expect(find.text('Manage subscription'), findsOneWidget);
  });

  testWidgets('a guest sees the sign-in action and the delete-account entry', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: [
        currentAccountProvider.overrideWith(
          (ref) => sampleAccount(isGuest: true),
        ),
        walletSnapshotProvider.overrideWith((ref) => WalletSnapshot.empty),
      ],
    );

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
  });

  testWidgets('delete account asks for confirmation; cancel does nothing', (
    tester,
  ) async {
    final auth = _RecordingAuthController();
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: [
        currentAccountProvider.overrideWith(
          (ref) => sampleAccount(isGuest: true),
        ),
        walletSnapshotProvider.overrideWith((ref) => WalletSnapshot.empty),
        authControllerProvider.overrideWith(() => auth),
      ],
    );

    await tester.tap(find.text('Delete account'));
    await tester.pump();

    // The dialog spells out the consequences (irreversible; the App Store
    // subscription is NOT cancelled by this).
    expect(find.text('Delete this account?'), findsOneWidget);
    expect(find.textContaining('cannot be undone'), findsOneWidget);
    expect(find.textContaining('not cancelled'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(find.text('Delete this account?'), findsNothing);
    expect(auth.deleteCalls, 0);
  });

  testWidgets('confirming the dialog runs the deletion', (tester) async {
    final auth = _RecordingAuthController();
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: [
        currentAccountProvider.overrideWith(
          (ref) => sampleAccount(isGuest: true),
        ),
        walletSnapshotProvider.overrideWith((ref) => WalletSnapshot.empty),
        authControllerProvider.overrideWith(() => auth),
      ],
    );

    await tester.tap(find.text('Delete account'));
    await tester.pump();
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump();

    expect(auth.deleteCalls, 1);
  });

  testWidgets('loading state shows skeletons', (tester) async {
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: [
        currentAccountProvider.overrideWith(
          (ref) => Completer<CurrentAccount>().future,
        ),
      ],
    );

    expect(find.byType(AuraSkeleton), findsWidgets);
  });

  testWidgets('error state shows a retry action', (tester) async {
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: [
        currentAccountProvider.overrideWith(
          (ref) async => throw const ServerFailure(message: 'boom'),
        ),
      ],
    );

    expect(find.text('Retry'), findsOneWidget);
  });
}

/// Network-free [AuthController] recording [deleteAccount] invocations.
class _RecordingAuthController extends AuthController {
  int deleteCalls = 0;

  @override
  AuthPhase build() => const AuthIdle();

  @override
  Future<void> deleteAccount() async {
    deleteCalls += 1;
  }
}
