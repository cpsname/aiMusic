import 'package:flutter/widgets.dart';

/// A bar waveform with a played / unplayed split at [progress] (0..1). Bars
/// are amplitudes 0..1; the widget draws in text direction (mirrors in RTL).
class WaveformView extends StatelessWidget {
  const WaveformView({
    super.key,
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    this.height = 64,
    this.onSeek,
  });

  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final double height;

  /// Tap-to-seek target (0..1) — optional.
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final paint = CustomPaint(
      size: Size.fromHeight(height),
      painter: _WaveformPainter(
        bars: bars,
        progress: progress.clamp(0, 1).toDouble(),
        active: activeColor,
        inactive: inactiveColor,
        rtl: rtl,
      ),
    );
    if (onSeek == null) return SizedBox(height: height, child: paint);
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          final x = details.localPosition.dx / constraints.maxWidth;
          onSeek!((rtl ? 1 - x : x).clamp(0, 1).toDouble());
        },
        child: SizedBox(height: height, child: paint),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.active,
    required this.inactive,
    required this.rtl,
  });

  final List<double> bars;
  final double progress;
  final Color active;
  final Color inactive;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final slot = size.width / bars.length;
    final barWidth = (slot * 0.55).clamp(1.5, 6.0);
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < bars.length; i++) {
      final fraction = (i + 0.5) / bars.length;
      paint
        ..color = fraction <= progress ? active : inactive
        ..strokeWidth = barWidth;
      final amplitude = bars[i].clamp(0.08, 1.0) * size.height / 2;
      final xLtr = slot * i + slot / 2;
      final x = rtl ? size.width - xLtr : xLtr;
      canvas.drawLine(
        Offset(x, size.height / 2 - amplitude),
        Offset(x, size.height / 2 + amplitude),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.bars != bars || old.active != active;
}
