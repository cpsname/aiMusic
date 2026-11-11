import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_motion.dart';
import '../tokens/songlet_type.dart';

/// Rounded progress bar with an optional trailing percent (docs/ui P05).
class ProgressMeter extends StatelessWidget {
  const ProgressMeter({
    super.key,
    required this.value,
    this.percentLabel,
    this.semanticsLabel,
  });

  /// 0..1.
  final double value;

  /// "60%" (formatted by the caller); null hides it.
  final String? percentLabel;
  final String? semanticsLabel;

  /// Bar thickness: a little heavier than the standard progress bar.
  static const double _barHeight = SongletSize.progressHeight * 1.5;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final v = value.clamp(0.0, 1.0);
    final reduce = MotionPolicy.reduceMotion(context);
    return Semantics(
      label: semanticsLabel,
      value: percentLabel,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: SongletRadius.pillAll,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: v),
                duration: reduce
                    ? SongletMotion.none
                    : SongletMotion.emphasized,
                curve: SongletMotion.standardCurve,
                builder: (context, animated, _) {
                  // The aurora fills the meter; the hairline track reads as
                  // the unplayed canvas.
                  return SizedBox(
                    height: _barHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: c.hairline),
                        FractionallySizedBox(
                          widthFactor: animated,
                          alignment: AlignmentDirectional.centerStart,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [c.accent, c.success],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (percentLabel != null) ...[
            const SizedBox(width: SongletSpace.x3),
            ExcludeSemantics(
              child: Text(
                percentLabel!,
                style: SongletType.subhead.copyWith(
                  color: c.inkSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
