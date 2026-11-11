import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_elevation.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_motion.dart';
import '../tokens/songlet_type.dart';

/// Two-or-more segment control with a sliding thumb (the music-video hub's
/// aspect, quality and subtitle choices).
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = SongletSize.minTap,
  });

  /// Value → label, in display order.
  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T>? onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final e = SongletElevation.of(context);
    final index = segments.indexWhere((s) => s.$1 == selected);
    final reduce = MotionPolicy.reduceMotion(context);
    const inset = SongletSpace.x1;
    return Container(
      height: height,
      padding: const EdgeInsetsDirectional.all(inset),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: SongletRadius.pillAll,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / segments.length;
          return Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: reduce ? SongletMotion.none : SongletMotion.standard,
                curve: SongletMotion.emphasizedCurve,
                start: width * (index < 0 ? 0 : index),
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: SongletRadius.pillAll,
                    boxShadow: e.level1,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (value, label) in segments)
                    Expanded(
                      child: Semantics(
                        container: true,
                        button: true,
                        selected: value == selected,
                        child: InkWell(
                          borderRadius: SongletRadius.pillAll,
                          onTap: onChanged == null
                              ? null
                              : () => onChanged!(value),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: SongletSpace.x1,
                              ),
                              // Long translations shrink rather than truncate.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  style: SongletType.subhead.copyWith(
                                    color: value == selected
                                        ? c.ink
                                        : c.inkSecondary,
                                    fontWeight: value == selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
