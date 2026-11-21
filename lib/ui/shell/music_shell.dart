import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/music_page_layout.dart';
import '../common/music_test_id.dart';

/// The shell (docs/ui P01): Create · Library · Settings, each tab keeping its
/// own navigation stack.
///
/// The tab bar is an index strip: three cells divided by hairlines, each with a
/// mono folio and its name, and the section being read printed as an ink block
/// with reversed-out lettering. Compact widths get the strip; regular widths
/// get the same sections stacked as a margin rail.
class MusicShell extends StatelessWidget {
  const MusicShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = [
      (id: 'nav.create', label: l10n.navCreate, icon: Icons.brush_outlined),
      (id: 'nav.library', label: l10n.navLibrary, icon: Icons.library_music_outlined),
      (id: 'nav.settings', label: l10n.navSettings, icon: Icons.tune_outlined),
    ];
    // Tab bar and rail are chrome: capped like UIKit's (chromeMaxTextScale).
    Widget chrome(Widget bar) => MediaQuery.withClampedTextScaling(
      maxScaleFactor: SongletType.chromeMaxTextScale,
      child: bar,
    );

    if (MusicWindowClass.of(context) == MusicWindowClass.regular) {
      return Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: Row(
              children: [
                chrome(
                  _MarginRail(
                    currentIndex: shell.currentIndex,
                    onSelected: _select,
                    destinations: destinations,
                  ),
                ),
                Expanded(child: shell),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PaperBackground(child: SafeArea(bottom: false, child: shell)),
      bottomNavigationBar: chrome(
        _PressNavBar(
          currentIndex: shell.currentIndex,
          onSelected: _select,
          destinations: destinations,
        ),
      ),
    );
  }
}

/// The three sections as an index strip: folio, name, and an ink block under
/// the section being read.
class _PressNavBar extends StatelessWidget {
  const _PressNavBar({
    required this.currentIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<({String id, String label, IconData icon})> destinations;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.canvas,
        border: Border(top: BorderSide(color: c.ink)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++) ...[
                if (i > 0)
                  Container(width: SongletSize.rule, color: c.hairline),
                Expanded(
                  child: _SectionTab(
                    id: destinations[i].id,
                    folio: _folio(i),
                    label: destinations[i].label,
                    selected: i == currentIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Section folio: 01, 02, 03.
String _folio(int index) => (index + 1).toString().padLeft(2, '0');

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.id,
    required this.folio,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String folio;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final tone = selected ? c.canvas : c.inkTertiary;
    return MusicTestId(
      id,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: selected ? c.ink : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: c.accent.withValues(alpha: 0.16),
            highlightColor: c.accent.withValues(alpha: 0.08),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    folio,
                    style: SongletType.folio.copyWith(
                      color: selected ? c.accent : c.inkTertiary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SongletType.eyebrow.copyWith(
                      color: tone,
                      fontSize: 10,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Regular widths: the same sections stacked along the leading margin.
class _MarginRail extends StatelessWidget {
  const _MarginRail({
    required this.currentIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<({String id, String label, IconData icon})> destinations;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Container(
      width: 96,
      decoration: BoxDecoration(
        border: BorderDirectional(end: BorderSide(color: c.ink)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: SongletSpace.x5),
            child: SongletMark(size: SongletSize.brandMark),
          ),
          Container(height: SongletSize.rule, color: c.hairline),
          for (var i = 0; i < destinations.length; i++)
            _RailTab(
              id: destinations[i].id,
              folio: _folio(i),
              label: destinations[i].label,
              selected: i == currentIndex,
              onTap: () => onSelected(i),
            ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _RailTab extends StatelessWidget {
  const _RailTab({
    required this.id,
    required this.folio,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String folio;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return MusicTestId(
      id,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: selected ? c.ink : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: SongletSpace.x3,
              ),
              child: Column(
                children: [
                  Text(
                    folio,
                    style: SongletType.folio.copyWith(
                      color: selected ? c.accent : c.inkTertiary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: SongletType.eyebrow.copyWith(
                      color: selected ? c.canvas : c.inkTertiary,
                      fontSize: 9.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
