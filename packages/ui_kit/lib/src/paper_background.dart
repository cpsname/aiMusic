import 'package:flutter/material.dart';

import 'tokens/songlet_colors.dart';

/// The page stock: warm paper under everything.
///
/// A flat colour plus a laid-paper texture — fine horizontal lines, the way a
/// letterpress sheet catches the light — and nothing that moves. Replaces the
/// old drifting aurora: the product is printed, not projected.
///
/// The paper is painted *behind* the page rather than as an ancestor of it, so
/// Material ink and list tiles still find their own Material.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, this.child, this.texture = true});

  final Widget? child;

  /// Draws the laid-paper lines. Off for surfaces that print their own
  /// (the share card, full-bleed media).
  final bool texture;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.canvas,
              gradient: LinearGradient(
                begin: AlignmentDirectional.topCenter,
                end: AlignmentDirectional.bottomCenter,
                colors: [
                  c.canvas,
                  Color.alphaBlend(
                    c.surfaceMuted.withValues(alpha: 0.32),
                    c.canvas,
                  ),
                ],
              ),
            ),
          ),
          if (texture)
            IgnorePointer(
              child: CustomPaint(
                painter: LaidPaperPainter(color: c.hairline),
              ),
            ),
          ?child,
        ],
      ),
    );
  }
}

/// Paints the laid-paper lines: one hairline every [spacing] points, at low
/// alpha, so the page reads as stock rather than as a flat fill.
class LaidPaperPainter extends CustomPainter {
  const LaidPaperPainter({required this.color, this.spacing = 6});

  final Color color;
  final double spacing;

  /// Very low alpha: the texture must never compete with the text.
  static const double opacity = 0.11;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 0.6;
    for (var y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant LaidPaperPainter old) =>
      old.color != color || old.spacing != spacing;
}
