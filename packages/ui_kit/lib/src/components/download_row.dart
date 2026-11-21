import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// A downloadable file (docs/ui P11: "MP3 · 320 kbps", "WAV · 44.1 kHz
/// (Premier)", the license PDF), set as a delivery-note line: what it is on
/// the left, its specification at the margin, and a ruled key to fetch it.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: SongletSpace.x3,
        ),
        child: Row(
          children: [
            Icon(icon, color: c.inkSecondary, size: SongletSize.iconMd),
            const SizedBox(width: SongletSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SongletType.title3.copyWith(
                      color: c.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: SongletType.caption.copyWith(color: c.inkSecondary),
                  ),
                ],
              ),
            ),
            if (detail != null) ...[
              const SizedBox(width: SongletSpace.x2),
              Text(
                detail!,
                style: SongletType.folio.copyWith(color: c.inkTertiary),
              ),
            ],
            const SizedBox(width: SongletSpace.x2),
            Semantics(
              container: true,
              button: true,
              label: actionLabel,
              excludeSemantics: true,
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: SongletRadius.controlAll,
                  side: BorderSide(color: c.hairline),
                ),
                child: InkWell(
                  borderRadius: SongletRadius.controlAll,
                  onTap: busy ? null : onPressed,
                  child: SizedBox.square(
                    dimension: SongletSize.minTap,
                    child: busy
                        ? Padding(
                            padding: const EdgeInsetsDirectional.all(
                              SongletSpace.x3,
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: SongletSize.focusRing,
                              color: c.accent,
                            ),
                          )
                        : Icon(
                            locked
                                ? Icons.lock_outline_rounded
                                : Icons.arrow_downward_rounded,
                            size: SongletSize.iconMd,
                            color: onPressed == null ? c.inkTertiary : c.ink,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 2-column grid of the allowed uses ("You can use this song for:"), set as
/// a checklist — a ruled dash per line, no discs.
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
                    Text(
                      '—',
                      style: SongletType.footnote.copyWith(color: c.accent),
                    ),
                    const SizedBox(width: SongletSpace.x2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: SongletType.subhead.copyWith(
                              color: c.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            detail,
                            style: SongletType.caption.copyWith(
                              color: c.inkSecondary,
                              height: 1.35,
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

/// Wide ruled key (P11 "Save to Files", "Add to Music").
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
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: SongletRadius.controlAll,
        side: BorderSide(color: c.inkTertiary),
      ),
      child: InkWell(
        borderRadius: SongletRadius.controlAll,
        onTap: busy ? null : onPressed,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: SongletSize.controlHeight,
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: SongletSpace.x3,
            vertical: SongletSpace.x2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox.square(
                  dimension: SongletSize.iconSm,
                  child: CircularProgressIndicator(
                    strokeWidth: SongletSize.focusRing,
                    color: c.accent,
                  ),
                )
              else
                Icon(icon, color: c.ink, size: SongletSize.iconMd),
              const SizedBox(width: SongletSpace.x2),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: SongletType.headline.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
