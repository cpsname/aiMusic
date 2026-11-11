import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ai_badge.dart';
import '../tokens/songlet_art.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_elevation.dart';
import '../tokens/songlet_metrics.dart';
import 'songlet_mark.dart';

/// A song's cover: template art when the work has one, else a generated
/// abstract (organic shapes + the bow line) seeded by the work id — never a
/// photo of anyone (docs/ui P07, P09, P12). Always carries the AI badge
/// unless [badgeLabel] is null (thumbnails show it on the player instead).
class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    required this.seed,
    this.image,
    this.palette,
    this.badgeLabel,
    this.framed = false,
    this.radius = SongletRadius.card,
  });

  final String seed;
  final ImageProvider? image;
  final ArtPalette? palette;
  final String? badgeLabel;

  /// White mat around the art (P07).
  final bool framed;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final e = SongletElevation.of(context);
    final art = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Image(image: image!, fit: BoxFit.cover, excludeFromSemantics: true)
          else
            CustomPaint(
              painter: GeneratedCoverPainter(
                seed: seed,
                palette: palette ?? ArtPalette.forSeed(seed),
              ),
            ),
          if (badgeLabel != null)
            PositionedDirectional(
              end: SongletSpace.x3,
              bottom: SongletSpace.x3,
              child: AiGeneratedBadge(label: badgeLabel!, compact: true),
            ),
        ],
      ),
    );
    return AspectRatio(
      aspectRatio: 1,
      child: framed
          ? Container(
              padding: const EdgeInsetsDirectional.all(SongletSpace.x2),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(radius + SongletSpace.x2),
                boxShadow: e.level2,
              ),
              child: art,
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: e.level1,
              ),
              child: art,
            ),
    );
  }
}

/// Deterministic abstract cover: palette gradient, three soft shapes and the
/// Songlet line. Also used by the share-card renderer.
class GeneratedCoverPainter extends CustomPainter {
  GeneratedCoverPainter({required this.seed, required this.palette});

  final String seed;
  final ArtPalette palette;

  /// String hash of [seed] → generator seed: start value, multiplier, and a
  /// mask keeping it in 31 bits.
  static const int _hashStart = 7;
  static const int _hashMultiplier = 31;
  static const int _mask31 = 0x7fffffff;

  /// Soft shapes: radius (× shortest side) = min + random × spread.
  static const double _shapeRadiusMin = 0.35;
  static const double _shapeRadiusSpread = 0.3;

  /// Soft shapes: centre y (× height) = top + random × spread.
  static const double _shapeTop = 0.2;
  static const double _shapeYSpread = 0.8;

  /// Soft shapes: height (× radius) = min + random × spread; width is 2 × r.
  static const double _shapeHeightMin = 1.6;
  static const double _shapeHeightSpread = 0.6;

  /// Opacity of the soft shapes and of the mark line.
  static const double _shapeAlpha = 0.85;
  static const double _lineAlpha = 0.9;

  /// Mark line stroke (× shortest side).
  static const double _lineWidth = 0.012;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(
      seed.codeUnits.fold<int>(
        _hashStart,
        (a, b) => (a * _hashMultiplier + b) & _mask31,
      ),
    );
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.light, palette.mid],
        ).createShader(rect),
    );
    final colors = [palette.base, palette.mid, palette.light];
    for (var i = 0; i < colors.length; i++) {
      final r =
          size.shortestSide *
          (_shapeRadiusMin + random.nextDouble() * _shapeRadiusSpread);
      final center = Offset(
        size.width * random.nextDouble(),
        size.height * (_shapeTop + random.nextDouble() * _shapeYSpread),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: r * 2,
          height:
              r * (_shapeHeightMin + random.nextDouble() * _shapeHeightSpread),
        ),
        Paint()..color = colors[i].withValues(alpha: _shapeAlpha),
      );
    }
    final line = SongletMarkPainter.path(size);
    canvas.drawPath(
      line,
      Paint()
        ..color = palette.ink.withValues(alpha: _lineAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * _lineWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(GeneratedCoverPainter old) =>
      old.seed != seed || old.palette != palette;
}
