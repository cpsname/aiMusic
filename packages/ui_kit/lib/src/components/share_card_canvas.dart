import 'package:flutter/material.dart';

import '../ai_badge.dart';
import '../tokens/songlet_art.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import '../waveform.dart';

/// Share-card layout (docs/ui P10): with the illustrated scene, or text only.
enum ShareCardLayout { scene, text }

/// The 9:16 share card (PRD F08; docs/ui P10). Designed on a fixed 360×640
/// canvas and scaled to fit, so the on-screen preview and the exported video
/// frames (rendered from this same widget at 1080×1920) are identical. The
/// "AI generated" badge is always painted — there is no parameter to omit it
/// (PRD D8).
class ShareCardCanvas extends StatelessWidget {
  const ShareCardCanvas({
    super.key,
    required this.brand,
    required this.tagline,
    required this.title,
    required this.lines,
    required this.badgeLabel,
    required this.bars,
    this.palette = ArtPalette.terracotta,
    this.layout = ShareCardLayout.scene,
  });

  /// Logical design size.
  static const Size design = Size(360, 640);

  /// Most lyric lines shown on the card.
  static const int maxLines = 4;

  final String brand;
  final String tagline;
  final String title;

  /// The lyric lines of the current section (up to four shown).
  final List<String> lines;
  final String badgeLabel;
  final List<double> bars;
  final ArtPalette palette;
  final ShareCardLayout layout;

  @override
  Widget build(BuildContext context) {
    // Artwork at a fixed design size (it is rendered into the shared video),
    // so Dynamic Type does not reflow it; the page around it scales.
    return MediaQuery.withNoTextScaling(
      child: AspectRatio(
        aspectRatio: design.width / design.height,
        child: FittedBox(
          child: SizedBox.fromSize(
            size: design,
            child: _Card(
              brand: brand,
              tagline: tagline,
              title: title,
              lines: lines.take(maxLines).toList(),
              badgeLabel: badgeLabel,
              bars: bars,
              palette: palette,
              layout: layout,
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.brand,
    required this.tagline,
    required this.title,
    required this.lines,
    required this.badgeLabel,
    required this.bars,
    required this.palette,
    required this.layout,
  });

  final String brand;
  final String tagline;
  final String title;
  final List<String> lines;
  final String badgeLabel;
  final List<double> bars;
  final ArtPalette palette;
  final ShareCardLayout layout;

  // Card geometry on the 360×640 design canvas (scaled as a whole).
  static const double pad = 28;
  static const double radius = 24;
  static const double titleGapScene = 72;
  static const double titleGapText = 110;
  static const double ruleGap = 20;
  static const double ruleWidth = 40;
  static const double ruleThickness = 1.2;
  static const double waveGap = 28;
  static const double waveWidth = 180;
  static const double waveHeight = 44;
  static const double textLayoutLyricSize = 26;
  static const double taglineTracking = 2.4;
  static const double badgeInset = 20;

  /// Ink opacity of the tagline, the title rule and the waveform.
  static const double taglineAlpha = 0.85;
  static const double ruleAlpha = 0.7;
  static const double waveAlpha = 0.9;

  @override
  Widget build(BuildContext context) {
    final ink = palette.ink;
    final scene = layout == ShareCardLayout.scene;
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(radius)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _BackdropPainter(palette: palette, scene: scene),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  brand,
                  style: SongletType.title3.copyWith(
                    fontFamily: SongletType.serifFamily,
                    color: ink,
                  ),
                ),
                Text(
                  tagline.toUpperCase(),
                  style: SongletType.caption2.copyWith(
                    color: ink.withValues(alpha: taglineAlpha),
                    letterSpacing: taglineTracking,
                  ),
                ),
                SizedBox(height: scene ? titleGapScene : titleGapText),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SongletType.displaySerif.copyWith(color: ink),
                ),
                const SizedBox(height: ruleGap),
                Center(
                  child: Container(
                    width: ruleWidth,
                    height: ruleThickness,
                    color: ink.withValues(alpha: ruleAlpha),
                  ),
                ),
                const SizedBox(height: ruleGap),
                for (final line in lines)
                  Text(
                    line,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SongletType.bodySerif.copyWith(
                      color: ink,
                      fontSize: scene
                          ? SongletType.bodySerif.fontSize
                          : textLayoutLyricSize,
                    ),
                  ),
                const SizedBox(height: waveGap),
                Center(
                  child: SizedBox(
                    width: waveWidth,
                    child: WaveformView(
                      bars: bars,
                      progress: 1,
                      activeColor: ink.withValues(alpha: waveAlpha),
                      inactiveColor: ink,
                      height: waveHeight,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          PositionedDirectional(
            end: badgeInset,
            bottom: badgeInset,
            child: AiGeneratedBadge(label: badgeLabel, locked: true),
          ),
        ],
      ),
    );
  }
}

/// Illustration of the card backdrop; coordinates are fractions of the card.
class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.palette, required this.scene});

  final ArtPalette palette;
  final bool scene;

  /// Shade colour the backdrop tones are darkened toward.
  static const Color _shadeTarget = Color(0xFF000000);

  /// Background gradient: [ArtPalette.base] → this far toward the mid tone.
  static const double _gradientMix = 0.6;

  /// Top-corner shape: end of its top edge (× width), the first curve's
  /// control / end point, then the second curve down the leading edge.
  static const double _cornerTopEnd = 0.72;
  static const _cornerCurve = (cx: 0.55, cy: 0.16, x: 0.18, y: 0.2);
  static const _cornerTail = (cy: 0.22, y: 0.34);

  /// How far the corner shape is shaded toward [_shadeTarget].
  static const double _cornerShade = 0.12;

  /// Horizon line (× height).
  static const double _horizon = 0.8;

  /// Sun: centre x and radius (× width), and opacity; it sits on the horizon.
  static const double _sunX = 0.66;
  static const double _sunRadius = 0.19;
  static const double _sunAlpha = 0.95;

  /// How far the sea is shaded toward [_shadeTarget].
  static const double _seaShade = 0.18;

  /// Reflection strokes under the sun: count, first offset below the horizon
  /// and spacing (design px), and half-length (× width) shrinking per stroke.
  static const int _reflectionCount = 5;
  static const double _reflectionTop = 10;
  static const double _reflectionSpacing = 12.0;
  static const double _reflectionHalf = 0.14;
  static const double _reflectionHalfStep = 0.02;

  /// Headland: start height above the horizon (× height), first curve
  /// (x × width, rise above the horizon × height), second curve (× width)
  /// ending [_hillFoot] design px below the horizon.
  static const double _hillStart = 0.1;
  static const _hillCurve = (cx: 0.18, cRise: 0.14, x: 0.34, rise: 0.05);
  static const _hillTail = (cx: 0.44, x: 0.52);
  static const double _hillFoot = 4;

  /// How far the headland is shaded toward [_shadeTarget].
  static const double _hillShade = 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.base,
            Color.lerp(palette.base, palette.mid, _gradientMix)!,
          ],
        ).createShader(rect),
    );
    // Soft organic shape in the top corner.
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * _cornerTopEnd, 0)
        ..quadraticBezierTo(
          size.width * _cornerCurve.cx,
          size.height * _cornerCurve.cy,
          size.width * _cornerCurve.x,
          size.height * _cornerCurve.y,
        )
        ..quadraticBezierTo(
          0,
          size.height * _cornerTail.cy,
          0,
          size.height * _cornerTail.y,
        )
        ..close(),
      Paint()
        ..color = Color.lerp(
          palette.base,
          _shadeTarget,
          _cornerShade,
        )!.withValues(alpha: 0.5),
    );
    if (!scene) return;
    final horizon = size.height * _horizon;
    // Sun.
    canvas.drawCircle(
      Offset(size.width * _sunX, horizon),
      size.width * _sunRadius,
      Paint()..color = palette.light.withValues(alpha: _sunAlpha),
    );
    // Sea.
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, size.width, size.height - horizon),
      Paint()..color = Color.lerp(palette.base, _shadeTarget, _seaShade)!,
    );
    // Reflection strokes.
    final reflection = Paint()
      ..color = palette.light.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _reflectionCount; i++) {
      final y = horizon + _reflectionTop + i * _reflectionSpacing;
      final half = size.width * (_reflectionHalf - i * _reflectionHalfStep);
      canvas.drawLine(
        Offset(size.width * _sunX - half, y),
        Offset(size.width * _sunX + half, y),
        reflection,
      );
    }
    // Headland.
    final hill = Path()
      ..moveTo(0, horizon - size.height * _hillStart)
      ..quadraticBezierTo(
        size.width * _hillCurve.cx,
        horizon - size.height * _hillCurve.cRise,
        size.width * _hillCurve.x,
        horizon - size.height * _hillCurve.rise,
      )
      ..quadraticBezierTo(
        size.width * _hillTail.cx,
        horizon,
        size.width * _hillTail.x,
        horizon + _hillFoot,
      )
      ..lineTo(0, horizon + _hillFoot)
      ..close();
    canvas.drawPath(
      hill,
      Paint()..color = Color.lerp(palette.base, _shadeTarget, _hillShade)!,
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.palette != palette || old.scene != scene;
}

/// A theme swatch (P10 "Theme").
class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({
    super.key,
    required this.palette,
    required this.selected,
    required this.onTap,
    required this.label,
    this.size = SongletSize.controlHeight - SongletSpace.x1,
  });

  final ArtPalette palette;
  final bool selected;
  final VoidCallback onTap;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    const ring = SongletSpace.x1;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: size / 2 + ring,
        child: Container(
          width: size + ring * 2,
          height: size + ring * 2,
          padding: const EdgeInsetsDirectional.all(ring),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? c.accent : c.accent.withValues(alpha: 0),
              width: SongletSize.focusRing,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.base,
            ),
          ),
        ),
      ),
    );
  }
}
