import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'songlet_mark.dart';

/// Page header: mark, app name, optional tagline and a trailing slot
/// (allowance pill, sync status, settings) — docs/ui P01, P12, P16.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.title,
    this.tagline,
    this.trailing,
    this.markSize = SongletSize.brandMark,
    this.centered = false,
  });

  final String title;
  final String? tagline;
  final Widget? trailing;
  final double markSize;

  /// Centred compact variant for pushed pages (P07, P09, P11, P13).
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (centered ? SongletType.headline : SongletType.title1)
              .copyWith(color: c.ink),
        ),
        if (tagline != null)
          Text(
            tagline!,
            maxLines: centered ? 1 : null,
            overflow: centered ? TextOverflow.ellipsis : TextOverflow.visible,
            style: SongletType.caption.copyWith(color: c.inkSecondary),
          ),
      ],
    );
    // Accessibility sizes: the trailing slot moves under the brand so the
    // name keeps its line.
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackTrailing =
            trailing != null &&
            !centered &&
            (constraints.maxWidth < SongletSize.twoPaneBreakpoint ||
                SongletType.isAccessibilitySize(context));
        final brand = Row(
          mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
          children: [
            SongletMark(size: markSize),
            const SizedBox(width: SongletSpace.x3),
            if (centered) Flexible(child: text) else Expanded(child: text),
            if (trailing != null && !centered && !stackTrailing) ...[
              const SizedBox(width: SongletSpace.x3),
              trailing!,
            ],
          ],
        );
        return Semantics(
          header: true,
          // Chrome: capped like a UIKit bar (SongletType.chromeMaxTextScale).
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: SongletType.chromeMaxTextScale,
            child: stackTrailing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      brand,
                      const SizedBox(height: SongletSpace.x2),
                      trailing!,
                    ],
                  )
                : brand,
          ),
        );
      },
    );
  }
}
