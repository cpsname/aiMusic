import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'songlet_mark.dart';

/// The masthead: the publication's name set black and tight, a mono standfirst
/// under it, and a heavy ink rule carrying the page's datum.
///
/// On a poster the name is the composition — no tile behind it, no gradient.
/// The bow glyph is set once, small, in the signal coral.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.title,
    this.tagline,
    this.trailing,
    this.meta,
    this.markSize = SongletSize.iconXl,
    this.centered = false,
  });

  final String title;
  final String? tagline;
  final Widget? trailing;

  /// Short right-hand datum on the rule ("12 SONGS", "FREE").
  final String? meta;
  final double markSize;

  /// Compact centred variant for pushed pages (P07, P09, P11, P13).
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    if (centered) return _compact(context, c);
    return Semantics(
      header: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: SongletType.chromeMaxTextScale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SongletMark(size: markSize, tile: false, color: c.accent),
                const SizedBox(width: SongletSpace.x2),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SongletType.masthead.copyWith(color: c.ink),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: SongletSpace.x3),
                  trailing!,
                ],
              ],
            ),
            if (tagline != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 2),
                child: Text(
                  tagline!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SongletType.eyebrow.copyWith(
                    color: c.inkTertiary,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            const SizedBox(height: SongletSpace.x3),
            _Rule(color: c.ink, accent: c.accent, meta: meta, metaColor: c.inkSecondary),
          ],
        ),
      ),
    );
  }

  Widget _compact(BuildContext context, SongletColors c) => Semantics(
    header: true,
    child: MediaQuery.withClampedTextScaling(
      maxScaleFactor: SongletType.chromeMaxTextScale,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SongletMark(size: SongletSize.iconMd, tile: false),
          const SizedBox(width: SongletSpace.x2),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SongletType.title2.copyWith(
                color: c.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: SongletSpace.x3),
            trailing!,
          ],
        ],
      ),
    ),
  );
}

/// The masthead rule: a heavy ink line with a short coral block at its head,
/// and an optional mono datum at its end.
class _Rule extends StatelessWidget {
  const _Rule({
    required this.color,
    required this.accent,
    required this.meta,
    required this.metaColor,
  });

  final Color color;
  final Color accent;
  final String? meta;
  final Color metaColor;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: SongletSpace.x5,
        child: Container(height: SongletSize.ruleStrong + 2, color: accent),
      ),
      Expanded(
        child: Container(height: SongletSize.ruleStrong, color: color),
      ),
      if (meta != null) ...[
        const SizedBox(width: SongletSpace.x2),
        Text(
          meta!,
          style: SongletType.folio.copyWith(
            color: metaColor,
            fontSize: 10,
          ),
        ),
      ],
    ],
  );
}
