import 'package:flutter/widgets.dart';

import '../tokens/songlet_colors.dart';

/// The Songlet mark: a bow tied from a sound wave, on the accent tile
/// (app icon, docs/ui). Vector, so it stays sharp at any size.
class SongletMark extends StatelessWidget {
  const SongletMark({
    super.key,
    this.size = defaultSize,
    this.tile = true,
    this.color,
  });

  /// Default side length (the brand header's mark).
  static const double defaultSize = 44;

  final double size;

  /// Draws the rounded accent tile behind the line; false = line only.
  final bool tile;

  /// Line colour; defaults to the canvas colour on the tile, else the accent.
  final Color? color;

  /// iOS app-icon corner ratio.
  static const double cornerRatio = 0.225;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final line = color ?? (tile ? SongletColors.light.canvas : c.accent);
    final mark = CustomPaint(
      size: Size.square(size),
      painter: SongletMarkPainter(color: line),
    );
    if (!tile) return mark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: c.actionGradient,
        borderRadius: BorderRadius.circular(size * cornerRatio),
      ),
      child: mark,
    );
  }
}

/// Paints the bow-wave line inside a square; exposed for the share-card and
/// cover renderers, which draw on a raw canvas.
class SongletMarkPainter extends CustomPainter {
  const SongletMarkPainter({
    required this.color,
    this.strokeRatio = defaultStrokeRatio,
  });

  final Color color;

  /// Stroke width as a fraction of the side.
  final double strokeRatio;

  /// Default [strokeRatio] (the app icon's line weight).
  static const double defaultStrokeRatio = 0.048;

  /// The line in a 1254-unit design grid (the app icon's pixel grid).
  static const double _grid = 1254;

  /// Bow-wave path in the 1254-unit source grid: the start point, then cubic
  /// segments left wave → knot → the bow's two loops → knot → right wave.
  static const Offset _start = Offset(108, 763);
  static const _leftCrest = _Cubic(180, 763, 230, 647, 288, 647);
  static const _leftTrough = _Cubic(370, 647, 410, 818, 466, 818);
  static const _riseToKnot = _Cubic(530, 818, 590, 660, 627, 615);
  static const _rightLoopOut = _Cubic(650, 590, 700, 585, 760, 570);
  static const _rightLoopTop = _Cubic(850, 545, 880, 470, 820, 440);
  static const _rightLoopBack = _Cubic(760, 410, 670, 440, 627, 528);
  static const _leftLoopTop = _Cubic(585, 440, 495, 410, 435, 440);
  static const _leftLoopOut = _Cubic(375, 470, 405, 545, 494, 570);
  static const _leftLoopBack = _Cubic(555, 585, 605, 590, 627, 615);
  static const _rightTrough = _Cubic(665, 660, 725, 818, 787, 818);
  static const _rightCrest = _Cubic(845, 818, 885, 647, 965, 647);
  static const _rightTail = _Cubic(1025, 647, 1075, 763, 1145, 763);
  static const List<_Cubic> _segments = [
    _leftCrest,
    _leftTrough,
    _riseToKnot,
    _rightLoopOut,
    _rightLoopTop,
    _rightLoopBack,
    _leftLoopTop,
    _leftLoopOut,
    _leftLoopBack,
    _rightTrough,
    _rightCrest,
    _rightTail,
  ];

  /// Vertical shift (× side) that centres the line, which sits low in the
  /// icon's tile.
  static const double _verticalShift = -0.07;

  static Path path(Size size) {
    final sx = size.width / _grid;
    final sy = size.height / _grid;
    final p = Path()..moveTo(_start.dx * sx, _start.dy * sy);
    for (final s in _segments) {
      p.cubicTo(
        s.c1x * sx,
        s.c1y * sy,
        s.c2x * sx,
        s.c2y * sy,
        s.x * sx,
        s.y * sy,
      );
    }
    // Centre the drawing vertically (the icon's line sits low in its tile).
    return p.shift(Offset(0, _verticalShift * size.height));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      path(size),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * strokeRatio
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(SongletMarkPainter old) =>
      old.color != color || old.strokeRatio != strokeRatio;
}

/// One cubic Bézier segment of the mark: two control points, then the end.
class _Cubic {
  const _Cubic(this.c1x, this.c1y, this.c2x, this.c2y, this.x, this.y);

  final double c1x;
  final double c1y;
  final double c2x;
  final double c2y;
  final double x;
  final double y;
}
