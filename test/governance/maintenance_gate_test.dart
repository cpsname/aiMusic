import 'package:app_config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet/l10n/generated/app_localizations.dart';
import 'package:songlet/ui/governance/music_maintenance_gate.dart';

import '../support/pump_app.dart';

void main() {
  const childKey = Key('shell-child');
  const child = SizedBox(key: childKey);

  testWidgets('renders the child when not under maintenance', (tester) async {
    await pumpApp(tester, const MusicMaintenanceGate(child: child)); // safeDefault
    expect(find.byKey(childKey), findsOneWidget);
  });

  testWidgets('overlays the maintenance page when active', (tester) async {
    await pumpApp(
      tester,
      const MusicMaintenanceGate(child: child),
      appConfig: const AppConfig(
        maintenance: Maintenance(active: true, message: 'Upgrading the studio'),
        killSwitches: [],
        config: {},
      ),
    );
    expect(find.byKey(childKey), findsNothing);
    expect(find.text('Scheduled maintenance'), findsOneWidget);
    expect(find.text('Upgrading the studio'), findsOneWidget);
  });

  testWidgets('shows a resume estimate when resume_at is provided', (
    tester,
  ) async {
    final fixedNow = DateTime.utc(2026, 1, 1, 12);
    await pumpApp(
      tester,
      const MusicMaintenanceGate(child: child),
      appConfig: AppConfig(
        maintenance: Maintenance(
          active: true,
          message: 'down',
          resumeAt: fixedNow.add(const Duration(minutes: 30)),
        ),
        killSwitches: const [],
        config: const {},
      ),
      overrides: [
        clockOffsetServiceProvider.overrideWithValue(
          ClockOffsetService(deviceClock: () => fixedNow),
        ),
      ],
    );
    expect(find.textContaining('30 min'), findsOneWidget);
  });

  testWidgets('auto-dismisses when the server clears maintenance', (
    tester,
  ) async {
    final repo = _MutableRepo()
      ..result = const AppConfig(
        maintenance: Maintenance(active: true, message: 'down'),
        killSwitches: [],
        config: {},
      );
    final now = DateTime.utc(2026);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        appConfigRepositoryProvider.overrideWithValue(repo),
        clockOffsetServiceProvider.overrideWithValue(
          ClockOffsetService(deviceClock: () => now),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MusicMaintenanceGate(child: SizedBox(key: Key('shell'))),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('Scheduled maintenance'), findsOneWidget);
    expect(find.byKey(const Key('shell')), findsNothing);

    // Server clears maintenance → the gate dismisses reactively (no restart).
    repo.result = AppConfig.safeDefault;
    await container.read(appConfigProvider.notifier).refresh(force: true);
    await tester.pump();

    expect(find.byKey(const Key('shell')), findsOneWidget);
    expect(find.text('Scheduled maintenance'), findsNothing);
  });
}

class _MutableRepo implements AppConfigRepository {
  AppConfig result = AppConfig.safeDefault;

  @override
  Future<AppConfig> fetch() async => result;
}
