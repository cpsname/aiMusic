import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/page_layout.dart';
import '../common/test_id.dart';

/// The Songlet shell (docs/ui P01): Create · Library · Settings, each tab
/// keeping its own navigation stack. Compact widths get the bottom tab bar;
/// regular widths (iPad, landscape) a navigation rail.
class SongletShell extends StatelessWidget {
  const SongletShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final destinations = [
      (
        id: 'nav.create',
        label: l10n.navCreate,
        icon: Icons.add_circle_outline_rounded,
        selected: const _CreateSelected(),
      ),
      (
        id: 'nav.library',
        label: l10n.navLibrary,
        icon: Icons.music_note_outlined,
        selected: Icon(Icons.music_note_rounded, color: c.accent),
      ),
      (
        id: 'nav.settings',
        label: l10n.navSettings,
        icon: Icons.settings_outlined,
        selected: Icon(Icons.settings_rounded, color: c.accent),
      ),
    ];

    // Tab bar and rail are chrome: capped like UIKit's (chromeMaxTextScale).
    Widget chrome(Widget bar) => MediaQuery.withClampedTextScaling(
      maxScaleFactor: SongletType.chromeMaxTextScale,
      child: bar,
    );

    if (WindowClass.of(context) == WindowClass.regular) {
      return AuroraBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              SafeArea(
                child: chrome(
                  NavigationRail(
                    selectedIndex: shell.currentIndex,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        vertical: SongletSpace.x4,
                      ),
                      child: SongletMark(),
                    ),
                    destinations: [
                      for (final d in destinations)
                        NavigationRailDestination(
                          icon: TestId(d.id, child: Icon(d.icon)),
                          selectedIcon: TestId(d.id, child: d.selected),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                ),
              ),
              VerticalDivider(width: SongletSize.hairline, color: c.hairline),
              Expanded(child: shell),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(child: SafeArea(child: shell)),
      bottomNavigationBar: chrome(
        _GlassNavBar(shell: shell, destinations: destinations),
      ),
    );
  }
}

/// Floating frosted-glass bottom bar: the deep-space canvas stays visible
/// behind it and the current tab carries the aurora tint.
class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.shell, required this.destinations});

  final StatefulNavigationShell shell;
  final List<({String id, String label, IconData icon, Widget selected})>
  destinations;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Theme(
      data: Theme.of(context).copyWith(
        navigationBarTheme: Theme.of(context).navigationBarTheme.copyWith(
          backgroundColor: Colors.transparent,
          indicatorColor: c.accentSoft,
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.85),
              border: Border(top: BorderSide(color: c.hairline)),
            ),
            child: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (index) => shell.goBranch(
                index,
                initialLocation: index == shell.currentIndex,
              ),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: TestId(d.id, child: Icon(d.icon)),
                    selectedIcon: TestId(d.id, child: d.selected),
                    label: d.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The selected Create tab: the brand mark in an accent disc (docs/ui P01).
class _CreateSelected extends StatelessWidget {
  const _CreateSelected();

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Container(
      width: SongletSize.iconXl + SongletSpace.x1,
      height: SongletSize.iconXl + SongletSpace.x1,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: c.actionGradient,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(SongletSpace.x1),
        child: SongletMark(
          size: SongletSize.iconLg,
          tile: false,
          color: c.onAccent,
        ),
      ),
    );
  }
}
