import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';
import 'tokens/songlet_colors.dart';

/// A slowly drifting aurora gradient backdrop.
///
/// Driven by an infinitely repeating [AnimationController] (disposed with the
/// state). In tests, advance it with a single `tester.pump()` — never
/// `pumpAndSettle()`, which would hang on the perpetual animation.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, this.child});

  final Widget? child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin, RepeatingMotion<AuroraBackground> {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: StudioTokens.auroraDrift,
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
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final t = _controller.value * 2 * math.pi;
          // The backdrop stays in the ambient theme: the deep-space canvas in
          // dark, the holographic ice canvas in light — with dimmer blobs as
          // a content underlay so text above keeps its contrast.
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final base = SongletColors.of(context).canvas;
          final alpha = isDark ? 0.24 : 0.14;
          return DecoratedBox(
            decoration: BoxDecoration(color: base),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _blob(
                  StudioTokens.auroraViolet,
                  Alignment(0.6 * math.cos(t), -0.5 + 0.25 * math.sin(t)),
                  1.1,
                  alpha,
                ),
                _blob(
                  StudioTokens.auroraBlue,
                  Alignment(-0.7 * math.cos(t * 0.8), 0.2 * math.sin(t * 1.2)),
                  1.3,
                  alpha,
                ),
                _blob(
                  StudioTokens.auroraTeal,
                  Alignment(0.3 * math.sin(t * 1.1), 0.7 + 0.2 * math.cos(t)),
                  1.0,
                  alpha,
                ),
                ?child,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _blob(Color color, Alignment alignment, double scale, double alpha) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: 0.95 * scale,
        heightFactor: 0.7 * scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.7,
              colors: [
                color.withValues(alpha: alpha),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
