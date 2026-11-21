import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_motion.dart';
import '../tokens/songlet_type.dart';

/// The progress rule: a printed bar, one ink fill inside a hairline frame, with
/// an optional percent set at the margin (docs/ui P05).
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

  /// Bar thickness: a rule, not a bar.
  static const double _barHeight = 7;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final v = value.clamp(0.0, 1.0);
    final reduce = MotionPolicy.reduceMotion(context);
    final radius = BorderRadius.circular(2);
    return Semantics(
      label: semanticsLabel,
      value: percentLabel,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: radius,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: v),
                duration: reduce
                    ? SongletMotion.none
                    : SongletMotion.emphasized,
                curve: SongletMotion.standardCurve,
                builder: (context, animated, _) {
                  return SizedBox(
                    height: _barHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: c.surfaceMuted),
                        FractionallySizedBox(
                          widthFactor: animated,
                          alignment: AlignmentDirectional.centerStart,
                          child: ColoredBox(color: c.accent),
                        ),
                        // The frame sits above the fill so the rule keeps its
                        // printed edge.
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: c.hairline),
                            borderRadius: radius,
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
                style: SongletType.folio.copyWith(
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
