import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../player/lyrics_model.dart';
import 'widget_rasterizer.dart';

/// The share card's content and look for one work (docs/ui P10).
class ShareCardSpec {
  const ShareCardSpec({
    required this.brand,
    required this.tagline,
    required this.title,
    required this.badgeLabel,
    required this.bars,
    required this.palette,
    required this.layout,
  });

  final String brand;
  final String tagline;
  final String title;
  final String badgeLabel;
  final List<double> bars;
  final ArtPalette palette;
  final ShareCardLayout layout;

  /// The card widget showing [lines] — the preview and every video frame.
  ShareCardCanvas card(List<String> lines) => ShareCardCanvas(
    brand: brand,
    tagline: tagline,
    title: title,
    lines: lines,
    badgeLabel: badgeLabel,
    bars: bars,
    palette: palette,
    layout: layout,
  );
}

/// Renders the 9:16 share-card frames (PRD F08): one frame per lyric section,
/// timed by the song structure, each the same [ShareCardCanvas] as the
/// on-screen preview — with the "AI generated" badge burned into every frame
/// (PRD D8), since the card has no way to omit it.
class ShareCardRenderer {
  const ShareCardRenderer(this.spec);

  final ShareCardSpec spec;

  /// Output size of a frame (1080 × 1920).
  static const double pixelRatio = 3;

  /// Assumed section length in seconds when the job returned no `structure`.
  static const double fallbackSectionSeconds = 10;

  Future<List<MusicCardFrame>> render(
    BuildContext context,
    List<LyricBlock> blocks,
  ) async {
    final sections = blocks.where((b) => b.lines.isNotEmpty).toList();
    if (sections.isEmpty) {
      return [MusicCardFrame(png: await _frame(context, const []), start: 0)];
    }
    final frames = <MusicCardFrame>[];
    for (final (i, block) in sections.indexed) {
      if (!context.mounted) break;
      final start = i == 0 ? 0.0 : (block.start ?? i * fallbackSectionSeconds);
      frames.add(
        MusicCardFrame(png: await _frame(context, block.lines), start: start),
      );
    }
    return frames;
  }

  Future<Uint8List> _frame(BuildContext context, List<String> lines) =>
      rasterizeWidget(
        context,
        spec.card(lines),
        size: ShareCardCanvas.design,
        pixelRatio: pixelRatio,
      );
}
