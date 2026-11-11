import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet/l10n/generated/app_localizations.dart';
import 'package:songlet/ui/common/error_retry_view.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/pump_app.dart';

void main() {
  group('describeFailure', () {
    late AppLocalizations l10n;
    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('offline network failure → offline copy + wifi-off icon', () {
      final d = describeFailure(
        l10n,
        const NetworkFailure(
          message: 'Connection refused',
          kind: NetworkFailureKind.offline,
        ),
      );
      expect(d.title, l10n.networkErrorTitle);
      // PRD §6.5 NETWORK_OFFLINE copy.
      expect(d.message, l10n.errorNetworkOffline);
      expect(d.icon, Icons.wifi_off_rounded);
    });

    test('timeout network failure → generic network copy + cloud-off icon', () {
      final d = describeFailure(
        l10n,
        const NetworkFailure(
          message: 'timeout',
          kind: NetworkFailureKind.timeout,
        ),
      );
      expect(d.title, l10n.networkErrorTitle);
      expect(d.message, l10n.commonNetworkError);
      expect(d.icon, Icons.cloud_off_rounded);
    });

    test('non-network failure prefers the (localized) backend message', () {
      final d = describeFailure(
        l10n,
        const ServerFailure(message: 'server said no'),
      );
      expect(d.title, l10n.commonErrorTitle);
      expect(d.message, 'server said no');
    });

    test('non-network failure with empty message → generic fallback', () {
      final d = describeFailure(l10n, const ServerFailure(message: ''));
      expect(d.message, l10n.commonError);
    });
  });

  group('ErrorRetryView', () {
    testWidgets('shows offline copy and fires onRetry', (tester) async {
      var retried = false;
      await pumpApp(
        tester,
        ErrorRetryView(
          failure: const NetworkFailure(
            message: '',
            kind: NetworkFailureKind.offline,
          ),
          onRetry: () => retried = true,
        ),
        locale: const Locale('en'),
      );

      expect(find.text('Connection problem'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets(
      'a title override replaces the generic (non-network) headline',
      (tester) async {
        await pumpApp(
          tester,
          ErrorRetryView(
            failure: const ServerFailure(message: ''),
            onRetry: () {},
            title: 'Couldn\'t load products',
            fullScreen: false,
          ),
          locale: const Locale('en'),
        );

        expect(find.text('Couldn\'t load products'), findsOneWidget);
      },
    );

    testWidgets('a title override does NOT hide the connectivity-aware title', (
      tester,
    ) async {
      // A network failure keeps "Connection problem" so title/icon/body agree,
      // even when the screen passes a generic title override.
      await pumpApp(
        tester,
        ErrorRetryView(
          failure: const NetworkFailure(
            message: '',
            kind: NetworkFailureKind.offline,
          ),
          onRetry: () {},
          title: 'Couldn\'t load products',
          fullScreen: false,
        ),
        locale: const Locale('en'),
      );

      expect(find.text('Connection problem'), findsOneWidget);
      expect(find.text('Couldn\'t load products'), findsNothing);
    });

    testWidgets('a config failure offers no action at all', (tester) async {
      // The build itself is missing its dart-defines: a retry provably cannot
      // change the outcome, so the surface must not pretend otherwise.
      await pumpApp(
        tester,
        ErrorRetryView(
          failure: const ConfigFailure(
            message: '',
            missingKeys: ['DISTRIBUTION_SECRET'],
          ),
          onRetry: () {},
        ),
        locale: const Locale('en'),
      );

      expect(find.text('App configuration problem'), findsOneWidget);
      expect(find.byIcon(Icons.settings_suggest_rounded), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(find.byType(ObsButton), findsNothing);
      // Debug builds (tests run in debug) name the actual missing key.
      expect(find.textContaining('DISTRIBUTION_SECRET'), findsOneWidget);
    });

    testWidgets('retrying shows a spinner and disables the action', (
      tester,
    ) async {
      var retried = false;
      await pumpApp(
        tester,
        ErrorRetryView(
          failure: const NetworkFailure(
            message: '',
            kind: NetworkFailureKind.offline,
          ),
          onRetry: () => retried = true,
          retrying: true,
        ),
        locale: const Locale('en'),
      );

      // While retrying the button renders a spinner (no label) and is disabled.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      await tester.tap(find.byType(ObsButton), warnIfMissed: false);
      expect(retried, isFalse);
    });
  });
}
