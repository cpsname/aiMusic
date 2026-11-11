import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_motion.dart';
import 'songlet_mark.dart';

/// The generating hero (docs/ui P05/P06): the mark in an accent disc with
/// soft halos that breathe while waiting. Rests still under reduce-motion.
class PulsingMark extends StatefulWidget {
  const PulsingMark({super.key, this.diameter = defaultDiameter, this.label});

  /// Default disc diameter (docs/ui P05).
  static const double defaultDiameter = SongletSize.coverLarge * 0.42;

  final double diameter;

  /// Accessibility label ("Writing Alex's song").
  final String? label;

  @override
  State<PulsingMark> createState() => _PulsingMarkState();
}

class _PulsingMarkState extends State<PulsingMark>
    with SingleTickerProviderStateMixin, RepeatingMotion {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SongletMotion.pulse,
  );

  /// Halos, outermost first: diameter (× disc) and accent opacity.
  static const _outerHalo = (scale: 2.0, alpha: 0.06);
  static const _middleHalo = (scale: 1.65, alpha: 0.10);
  static const _innerHalo = (scale: 1.32, alpha: 0.16);
  static const _halos = [_outerHalo, _middleHalo, _innerHalo];

  /// How far (× disc) each halo shrinks at the breath's low point.
  static const double _breath = 0.08;

  /// Inset of the mark in the disc and the mark's size (× disc).
  static const double _markInset = 0.12;
  static const double _markScale = 0.76;

  @override
  AnimationController get motionController => _controller;

  @override
  double get restFrame => 0.5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final d = widget.diameter;
    return Semantics(
      label: widget.label,
      image: true,
      child: SizedBox.square(
        dimension: d * 2,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(
              _controller.value <= 0.5
                  ? _controller.value * 2
                  : (1 - _controller.value) * 2,
            );
            return Stack(
              alignment: Alignment.center,
              children: [
                for (final (:scale, :alpha) in _halos)
                  Container(
                    width: d * (scale - _breath + _breath * t),
                    height: d * (scale - _breath + _breath * t),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.accent.withValues(alpha: alpha),
                    ),
                  ),
                Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: c.actionGradient,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(d * _markInset),
                    child: SongletMark(
                      size: d * _markScale,
                      tile: false,
                      color: c.onArt,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
