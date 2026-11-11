import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// "Lots of songs being made right now. Yours is queued." with the estimated
/// wait and, when the server reports one, the queue position (docs/ui P06).
class QueueBanner extends StatelessWidget {
  const QueueBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.positionLabel,
    this.position,
    required this.waitValue,
    required this.waitLabel,
  });

  final String title;
  final String subtitle;
  final String positionLabel;

  /// Null when the server does not report a position: the stat is left out.
  final String? position;
  final String waitValue;
  final String waitLabel;

  /// Opacity of the accent dividers between the stats.
  static const double _dividerAlpha = 0.2;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final divider = Container(
      width: SongletSize.hairline,
      height: SongletSize.minTap,
      color: c.accent.withValues(alpha: _dividerAlpha),
    );
    final message = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SongletType.footnote.copyWith(
            color: c.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          subtitle,
          style: SongletType.footnote.copyWith(color: c.inkSecondary),
        ),
      ],
    );
    final value = this.position;
    final position = value == null
        ? null
        : _Stat(label: positionLabel, value: value, valueFirst: false);
    final wait = _Stat(label: waitLabel, value: waitValue, valueFirst: true);
    final icon = Icon(
      Icons.schedule_rounded,
      color: c.accent,
      size: SongletSize.iconLg,
    );
    // Accessibility sizes: the stats move under the message.
    final stacked = SongletType.isAccessibilitySize(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(SongletSpace.x4),
        decoration: BoxDecoration(
          color: c.accentSoft,
          borderRadius: SongletRadius.cardAll,
        ),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(height: SongletSpace.x2),
                  message,
                  const SizedBox(height: SongletSpace.x3),
                  Wrap(
                    spacing: SongletSpace.x6,
                    runSpacing: SongletSpace.x2,
                    children: [?position, wait],
                  ),
                ],
              )
            : Row(
                children: [
                  icon,
                  const SizedBox(width: SongletSpace.x3),
                  Expanded(child: message),
                  if (position != null) ...[
                    const SizedBox(width: SongletSpace.x2),
                    divider,
                    const SizedBox(width: SongletSpace.x2),
                    position,
                  ],
                  const SizedBox(width: SongletSpace.x2),
                  divider,
                  const SizedBox(width: SongletSpace.x2),
                  wait,
                ],
              ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.valueFirst,
  });

  final String label;
  final String value;
  final bool valueFirst;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final v = Text(value, style: SongletType.headline.copyWith(color: c.ink));
    final l = Text(
      label,
      style: SongletType.caption2.copyWith(color: c.inkSecondary),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: valueFirst ? [v, l] : [l, v],
    );
  }
}
