import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../me/music_profile_page.dart';
import '../paywall/music_paywall_page.dart';
import '../upload/music_upload_demo_page.dart';

/// Adaptive app shell: an aurora backdrop with a translucent bottom navigation
/// switching between Profile, the Paywall (Store) and the upload demo. No route
/// table.
class MusicStudioShell extends StatefulWidget {
  const MusicStudioShell({super.key});

  @override
  State<MusicStudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<MusicStudioShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBody: true,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: const [MusicProfilePage(), MusicPaywallPage(), MusicUploadDemoPage()],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: StudioTokens.nebula.withValues(alpha: 0.72),
        surfaceTintColor: Colors.transparent,
        indicatorColor: StudioTokens.auroraViolet.withValues(alpha: 0.30),
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
          NavigationDestination(
            icon: const Icon(Icons.workspace_premium_outlined),
            selectedIcon: const Icon(Icons.workspace_premium),
            label: l10n.navStore,
          ),
          NavigationDestination(
            icon: const Icon(Icons.cloud_upload_outlined),
            selectedIcon: const Icon(Icons.cloud_upload),
            label: l10n.navUpload,
          ),
        ],
      ),
    );
  }
}
