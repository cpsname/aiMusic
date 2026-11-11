import 'package:flutter/painting.dart';

/// Art palettes for generated covers and share-card themes (docs/ui P07,
/// P10: terracotta · sand · olive · navy). Content colours, identical in light
/// and dark mode.
enum ArtPalette {
  terracotta(
    base: Color(0xFFC9472B),
    mid: Color(0xFFE07B55),
    light: Color(0xFFF3C6A8),
    ink: Color(0xFFFFF6EE),
  ),
  sand(
    base: Color(0xFFE5C3A0),
    mid: Color(0xFFD9A77F),
    light: Color(0xFFF6E3CF),
    ink: Color(0xFF4A2B1C),
  ),
  olive(
    base: Color(0xFF66744A),
    mid: Color(0xFF8A9868),
    light: Color(0xFFC9D1B0),
    ink: Color(0xFFF8F4EA),
  ),
  navy(
    base: Color(0xFF3F5475),
    mid: Color(0xFF5E7598),
    light: Color(0xFFB4C2D8),
    ink: Color(0xFFF5F2EC),
  );

  const ArtPalette({
    required this.base,
    required this.mid,
    required this.light,
    required this.ink,
  });

  final Color base;
  final Color mid;
  final Color light;

  /// Text and line colour on this palette.
  final Color ink;

  /// Stable palette for a seed (a work id), so a cover never changes.
  static ArtPalette forSeed(String seed) =>
      values[seed.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff) %
          values.length];
}

/// Gradient covers for create-home tiles that have no photo (an inspiration
/// the app bundles no art for and the server sends no `cover_url` for). Chosen
/// by a stable hash of the seed so a tile keeps its colour across launches and
/// languages. Content colours, identical in light and dark mode.
abstract final class CoverGradients {
  static const List<List<Color>> _pairs = [
    [Color(0xFFEE8A66), Color(0xFFB53A22)], // terracotta
    [Color(0xFFEC76A0), Color(0xFF9E2F5E)], // rose
    [Color(0xFF52BDB3), Color(0xFF1E6A78)], // teal
    [Color(0xFF7685E6), Color(0xFF383C9A)], // indigo
    [Color(0xFFF4B650), Color(0xFFBE6A1E)], // amber
    [Color(0xFFA872DC), Color(0xFF58298C)], // plum
  ];

  /// Number of distinct gradients.
  static int get count => _pairs.length;

  /// The gradient for [seed] (top-start → bottom-end).
  static LinearGradient of(String seed) {
    // FNV-1a: String.hashCode is not specified to be stable across runs.
    var hash = 0x811C9DC5;
    for (final unit in seed.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    final pair = _pairs[hash % _pairs.length];
    return LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: pair,
    );
  }
}
