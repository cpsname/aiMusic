import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/ui_locale.dart';
import 'common/brand.dart';
import 'common/messages.dart';
import 'governance/maintenance_gate.dart';
import 'mv/mv_notification_binding.dart';
import 'routing/app_router.dart';
import 'startup/startup_gate.dart';

/// Root widget: the Songlet theme (light + dark, ADR-0004), full localization
/// (PRD §11.2) and the typed router (ADR-0003). The startup and maintenance
/// gates sit above the router, so no route — deep links included — can bypass
/// a forced update or maintenance.
class SongletApp extends ConsumerStatefulWidget {
  const SongletApp({super.key, this.initialLocation});

  /// Start somewhere other than the create home (tests, deep-link restore).
  final String? initialLocation;

  @override
  ConsumerState<SongletApp> createState() => _SongletAppState();
}

class _SongletAppState extends ConsumerState<SongletApp> {
  late final GoRouter _router = widget.initialLocation == null
      ? buildAppRouter()
      : buildAppRouter(initialLocation: widget.initialLocation!);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      locale: ref.watch(uiLocaleProvider),
      onGenerateTitle: (context) => SongletBrand.name,
      debugShowCheckedModeBanner: false,
      theme: AuraTheme.warm,
      darkTheme: AuraTheme.warmDark,
      // The deep-space aurora language is the product's primary canvas.
      // Light remains available for system-level accessibility and previews.
      themeMode: ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedUiLocales,
      routerConfig: _router,
      // App-wide message stack above every screen (gates / sheets / dialogs),
      // surviving route changes — unlike a Scaffold-bound SnackBar.
      builder: (context, child) => Consumer(
        builder: (context, ref, _) => MessageHost(
          controller: ref.watch(messageControllerProvider),
          child: StartupGate(
            child: MaintenanceGate(
              child: MvNotificationBinding(
                router: _router,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
