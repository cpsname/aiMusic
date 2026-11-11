import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'surface_card.dart';

/// A downloadable file (docs/ui P11: "MP3 · 320 kbps", "WAV · 44.1 kHz
/// (Premier)", the license PDF): leading glyph, title, one or two detail
/// lines, and a round download button.
class DownloadRow extends StatelessWidget {
  const DownloadRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
    this.detail,
    this.busy = false,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? detail;
  final String actionLabel;
  final VoidCallback? onPressed;
  final bool busy;

  /// Not in the plan: a padlock replaces the download glyph (tap upgrades).
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return SurfaceCard(
      padding: const EdgeInsetsDirectional.all(SongletSpace.x4),
      child: Row(
        children: [
          Icon(
            icon,
            color: c.accent,
            size: SongletSize.iconXl + SongletSpace.x2,
          ),
          const SizedBox(width: SongletSpace.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SongletType.headline.copyWith(
                    color: c.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: SongletType.subhead.copyWith(color: c.inkSecondary),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: SongletType.footnote.copyWith(color: c.inkSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: SongletSpace.x2),
          Semantics(
            container: true,
            button: true,
            label: actionLabel,
            excludeSemantics: true,
            child: Material(
              color: c.surfaceMuted,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: busy ? null : onPressed,
                child: SizedBox.square(
                  dimension: SongletSize.controlHeight,
                  child: busy
                      ? Padding(
                          padding: const EdgeInsetsDirectional.all(
                            SongletSpace.x4,
                          ),
                          child: CircularProgressIndicator(
                            strokeWidth: SongletSize.focusRing,
                            color: c.accent,
                          ),
                        )
                      : Icon(
                          locked
                              ? Icons.lock_outline_rounded
                              : Icons.download_rounded,
                          color: onPressed == null ? c.inkTertiary : c.ink,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A 2-column grid of allowed uses with checks (P11 "You can use this song
/// for:").
class UsageGrid extends StatelessWidget {
  const UsageGrid({super.key, required this.items});

  /// (title, detail).
  final List<(String, String)> items;

  /// Width below which the grid collapses to a single column.
  static const double _singleColumnBelow = SongletSize.minTap * 6;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < _singleColumnBelow ? 1 : 2;
        final width =
            (constraints.maxWidth - SongletSpace.x3 * (columns - 1)) / columns;
        return Wrap(
          spacing: SongletSpace.x3,
          runSpacing: SongletSpace.x3,
          children: [
            for (final (title, detail) in items)
              SizedBox(
                width: width,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: SongletSize.iconXl,
                      height: SongletSize.iconXl,
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: c.accent,
                        size: SongletSize.iconMd,
                      ),
                    ),
                    const SizedBox(width: SongletSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: SongletType.subhead.copyWith(
                              color: c.ink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            detail,
                            style: SongletType.caption.copyWith(
                              color: c.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Wide icon + label button in a card (P11 "Save to Files", "Add to Music").
class CardButton extends StatelessWidget {
  const CardButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return SurfaceCard(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SongletSpace.x4,
        vertical: SongletSpace.x4,
      ),
      onTap: busy ? null : onPressed,
      child: Semantics(
        container: true,
        button: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              SizedBox.square(
                dimension: SongletSize.iconLg,
                child: CircularProgressIndicator(
                  strokeWidth: SongletSize.focusRing,
                  color: c.accent,
                ),
              )
            else
              Icon(icon, color: c.accent, size: SongletSize.iconXl),
            const SizedBox(width: SongletSpace.x3),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: SongletType.callout.copyWith(color: c.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
