import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';
import 'tokens/songlet_colors.dart';
import 'tokens/songlet_metrics.dart';

/// A paper-toned shimmer placeholder.
///
/// The highlight sweeps via an infinitely repeating [AnimationController]
/// (disposed with the state). In tests, render frames with `tester.pump()` — not
/// `pumpAndSettle()`.
class AuraSkeleton extends StatefulWidget {
  const AuraSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<AuraSkeleton> createState() => _AuraSkeletonState();
}

class _AuraSkeletonState extends State<AuraSkeleton>
    with SingleTickerProviderStateMixin, RepeatingMotion<AuraSkeleton> {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: StudioTokens.shimmer,
  );

  @override
  AnimationController get motionController => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final radius = widget.borderRadius ?? SongletRadius.thumbAll;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final dx = _controller.value * 2 - 1; // -1 → 1
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(dx - 1, 0),
              end: Alignment(dx + 1, 0),
              colors: [c.surfaceMuted, c.surface, c.surfaceMuted],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}
