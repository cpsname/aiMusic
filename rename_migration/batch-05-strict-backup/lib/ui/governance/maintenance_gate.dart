import 'dart:async';

import 'package:app_config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';

/// Reactive maintenance gate (AppConfig BC): when `GET /app/config` reports an
/// active maintenance window it overlays a blocking maintenance page (server
/// message + optional countdown); otherwise it renders [child].
///
/// Runtime-mutable — it reflects maintenance toggling on app resume without a
/// restart. **Never blocks boot**: until the first config fetch lands the state
/// is the safe default (inactive), so the app is shown immediately (fail-open).
/// Sits inside the startup/force-update gate and above the shell.
class MaintenanceGate extends ConsumerWidget {
  const MaintenanceGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenance = ref.watch(maintenanceProvider);
    if (!maintenance.active) return child;
    return _MaintenancePage(maintenance: maintenance);
  }
}

class _MaintenancePage extends ConsumerStatefulWidget {
  const _MaintenancePage({required this.maintenance});

  final Maintenance maintenance;

  @override
  ConsumerState<_MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends ConsumerState<_MaintenancePage> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    ref.read(telemetrySinkProvider).logEvent('maintenance_shown');
    // While blocked, poll to detect when maintenance clears and to re-render the
    // countdown. Force-refreshes bypass the throttle; the gate dismisses itself
    // reactively once the server reports `active:false`.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {});
      ref.read(appConfigProvider.notifier).refresh(force: true);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final maintenance = widget.maintenance;
    final minutes = _remainingMinutes(maintenance.resumeAt);
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(StudioTokens.spaceXl),
            child: Center(
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.maintenanceTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                    if (maintenance.message.isNotEmpty) ...[
                      const SizedBox(height: StudioTokens.spaceSm),
                      Text(
                        maintenance.message,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (minutes != null) ...[
                      const SizedBox(height: StudioTokens.spaceSm),
                      Text(
                        l10n.maintenanceResumeEstimate(minutes),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: StudioTokens.spaceLg),
                    ObsButton(
                      label: l10n.commonRetry,
                      onPressed: () => ref
                          .read(appConfigProvider.notifier)
                          .refresh(force: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Whole minutes until [resumeAt] using the server-corrected clock (DF①);
  /// null when unknown or already elapsed.
  int? _remainingMinutes(DateTime? resumeAt) {
    if (resumeAt == null) return null;
    final remaining = resumeAt.difference(
      ref.read(clockOffsetServiceProvider).now(),
    );
    if (remaining.inSeconds <= 0) return null;
    return (remaining.inSeconds / 60).ceil(); // round up to the next minute
  }
}
