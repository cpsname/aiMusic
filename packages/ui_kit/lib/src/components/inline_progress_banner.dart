import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'progress_meter.dart';

/// Work in progress shown in place, on a page about something else
/// (docs/ui P23, ADR-0027): the lyric video being made under a finished
/// song, or the countdown before it starts. [value] null = indeterminate
/// (nothing reported yet: the bar never guesses); an optional end action
/// ("Cancel", "View").
class InlineProgressBanner extends StatelessWidget {
  const InlineProgressBanner({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.value,
    this.percentLabel,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;

  /// Stage or countdown: "Rendering scene 2 of 3", "Starts in 8 s".
  final String? detail;

  /// 0..1 when reported; null shows an indeterminate bar.
  final double? value;
  final String? percentLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Height of the indeterminate bar (matches [ProgressMeter]).
  static const double _barHeight = SongletSize.progressHeight * 1.5;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final stacked = SongletType.isAccessibilitySize(context);
    final action = actionLabel == null
        ? null
        : TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: c.accent,
              minimumSize: const Size(SongletSize.minTap, SongletSize.minTap),
            ),
            child: Text(actionLabel!, style: SongletType.subhead.copyWith(fontWeight: FontWeight.w600)),
          );
    final head = Row(
      children: [
        Icon(icon, color: c.accent, size: SongletSize.iconLg),
        const SizedBox(width: SongletSpace.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: SongletType.subhead.copyWith(color: c.ink, fontWeight: FontWeight.w600)),
              if (detail != null) Text(detail!, style: SongletType.footnote.copyWith(color: c.inkSecondary)),
            ],
          ),
        ),
        if (action != null && !stacked) action,
      ],
    );
    final v = value;
    // Reduce motion: an empty, still track instead of the sweeping bar.
    final bar = v == null
        ? ClipRRect(
            borderRadius: SongletRadius.pillAll,
            child: LinearProgressIndicator(
              value: MotionPolicy.reduceMotion(context) ? 0 : null,
              minHeight: _barHeight,
              color: c.accent,
              backgroundColor: c.hairline,
              semanticsLabel: title,
            ),
          )
        : ProgressMeter(value: v, percentLabel: percentLabel, semanticsLabel: title);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(SongletSpace.x4),
        decoration: BoxDecoration(color: c.accentSoft, borderRadius: SongletRadius.cardAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            head,
            const SizedBox(height: SongletSpace.x3),
            bar,
            if (action != null && stacked) Align(alignment: AlignmentDirectional.centerEnd, child: action),
          ],
        ),
      ),
    );
  }
}
