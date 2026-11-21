import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'meta_line.dart';

/// A library song (docs/ui P12), set as an index entry: folio, title, the
/// metadata line under it, and the badge and keys at the margin. The row is
/// closed by a hairline — the list is a printed index, not a stack of cards.
///
/// [cover] is optional: with it the entry carries its plate; without it the
/// entry is pure type (the library shows its covers in the filmstrip above the
/// index instead of repeating one per row).
class WorkRow extends StatelessWidget {
  const WorkRow({
    super.key,
    this.cover,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.badge,
    required this.onTap,
    required this.playLabel,
    required this.moreLabel,
    this.onPlay,
    this.onMore,
    this.playing = false,
    this.ordinal,
  });

  final Widget? cover;
  final String title;
  final String subtitle;
  final List<String> meta;
  final Widget badge;
  final VoidCallback onTap;
  final String playLabel;
  final String moreLabel;
  final VoidCallback? onPlay;
  final VoidCallback? onMore;
  final bool playing;

  /// Printed folio of the entry ("01"), when the list numbers its rows.
  final String? ordinal;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Semantics(
      container: true,
      button: true,
      label: title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.hairline)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: SongletSpace.x3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ordinal != null) ...[
                  SizedBox(
                    width: SongletSize.folioColumn,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 2),
                      child: Text(
                        ordinal!,
                        style: SongletType.folio.copyWith(color: c.inkTertiary),
                      ),
                    ),
                  ),
                ],
                if (cover != null) ...[
                  SizedBox.square(
                    dimension: SongletSize.thumbnail,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: SongletRadius.thumbAll,
                        border: Border.all(color: c.hairline),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(
                          Radius.circular(SongletRadius.thumb - 1),
                        ),
                        child: cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: SongletSpace.x3),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SongletType.title2.copyWith(
                          color: c.ink,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(top: 1),
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SongletType.subhead.copyWith(
                              color: c.inkSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      MetaLine(
                        parts: meta,
                        textAlign: TextAlign.start,
                        style: SongletType.caption2.copyWith(
                          color: c.inkTertiary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: SongletSpace.x2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    badge,
                    const SizedBox(height: SongletSpace.x2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onPlay != null)
                          _Key(
                            tooltip: playLabel,
                            onPressed: onPlay,
                            icon: playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        if (onMore != null)
                          _Key(
                            tooltip: moreLabel,
                            onPressed: onMore,
                            icon: Icons.more_horiz_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small ruled key at the row's margin.
class _Key extends StatelessWidget {
  const _Key({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(
        minWidth: SongletSize.playButtonSm,
        minHeight: SongletSize.playButtonSm,
      ),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.hairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SongletRadius.thumb),
        ),
      ),
      icon: Icon(icon, size: SongletSize.iconMd),
    );
  }
}
