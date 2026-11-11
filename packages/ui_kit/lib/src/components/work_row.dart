import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'meta_line.dart';

/// A library song (docs/ui P12): cover thumbnail, title, recipient, duration ·
/// date, a Preview / Full badge, play and more buttons.
class WorkRow extends StatelessWidget {
  const WorkRow({
    super.key,
    required this.cover,
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
  });

  final Widget cover;
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

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Semantics(
      container: true,
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: SongletRadius.cardAll,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(SongletSpace.x3),
          child: Row(
            children: [
              SizedBox.square(
                dimension: SongletSize.thumbnail + SongletSpace.x6,
                child: cover,
              ),
              const SizedBox(width: SongletSpace.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SongletType.headline.copyWith(color: c.ink),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SongletType.subhead.copyWith(
                          color: c.inkSecondary,
                        ),
                      ),
                    const SizedBox(height: SongletSpace.x1),
                    MetaLine(
                      parts: meta,
                      textAlign: TextAlign.start,
                      style: SongletType.footnote.copyWith(
                        color: c.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  badge,
                  const SizedBox(height: SongletSpace.x2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onPlay != null)
                        IconButton(
                          tooltip: playLabel,
                          onPressed: onPlay,
                          style: IconButton.styleFrom(
                            backgroundColor: c.surfaceMuted,
                          ),
                          icon: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: c.ink,
                          ),
                        ),
                      if (onMore != null)
                        IconButton(
                          tooltip: moreLabel,
                          onPressed: onMore,
                          icon: Icon(Icons.more_horiz_rounded, color: c.ink),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
