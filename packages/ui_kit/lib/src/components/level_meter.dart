import 'package:flutter/widgets.dart';

import '../tokens/songlet_metrics.dart';

/// Live microphone level bars, centred and mirrored like the P03a recorder:
/// [levels] are 0..1, newest last; missing history renders as rest dots.
class LevelMeter extends StatelessWidget {
  const LevelMeter({
    super.key,
    required this.levels,
    required this.color,
    this.bars = SongletSize.waveformBars,
    this.height = SongletSize.waveformHeight * 2,
  });

  final List<double> levels;
  final Color color;
  final int bars;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(
      painter: _LevelPainter(levels: levels, color: color, bars: bars),
    ),
  );
}

class _LevelPainter extends CustomPainter {
  _LevelPainter({
    required this.levels,
    required this.color,
    required this.bars,
  });

  final List<double> levels;
  final Color color;
  final int bars;

  /// Resting amplitude so silence still draws a dotted line.
  static const double _rest = 0.04;

  /// Bar stroke width as a share of its slot.
  static const double _strokeShare = 0.45;

  /// Envelope gain: [_edgeGain] at the ends, rising by [_taperGain] mid-meter.
  static const double _edgeGain = 0.35;
  static const double _taperGain = 0.65;

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / bars;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = slot * _strokeShare;
    final recent = levels.length > bars
        ? levels.sublist(levels.length - bars)
        : levels;
    final offset = bars - recent.length;
    for (var i = 0; i < bars; i++) {
      final raw = i < offset ? 0.0 : recent[i - offset];
      // Taper towards both ends like a voice envelope.
      final t = (i + 0.5) / bars;
      final taper = 1 - (2 * t - 1).abs();
      final amplitude = (raw.clamp(0.0, 1.0) * (_edgeGain + _taperGain * taper))
          .clamp(_rest, 1.0);
      final half = amplitude * size.height / 2;
      final x = slot * i + slot / 2;
      canvas.drawLine(
        Offset(x, size.height / 2 - half),
        Offset(x, size.height / 2 + half),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelPainter old) =>
      old.levels != levels || old.color != color || old.bars != bars;
}
