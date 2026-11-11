import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// How the create home's idea grid lays out at a width (ADR-0032, ADR-0034):
/// columns that keep every localized name on two lines without splitting a
/// word, the tile shape, and the heading — so the page can reserve one full
/// row for it and a deep link can scroll to a tile the lazy grid has not
/// built yet.
@immutable
class IdeaGridLayout {
  const IdeaGridLayout({
    required this.columns,
    required this.aspect,
    required this.tileWidth,
    required this.headerExtent,
  });

  /// Lays the grid out over [width] for the tile [names] (every name the app
  /// knows, loaded or not, so the columns never reflow when the list lands).
  factory IdeaGridLayout.of(
    BuildContext context, {
    required double width,
    required Iterable<String> names,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    // Accessibility sizes: tiles grow with the text (one per row on a phone)
    // and turn landscape so the art stays in view.
    final accessible = SongletType.isAccessibilitySize(context);
    final extent =
        SongletSize.tileMinExtent * (accessible ? scaler.scale(1) : 1);
    var columns = (width / (extent + SongletSpace.x2)).floor().clamp(
      accessible ? 1 : minColumns,
      maxColumns,
    );
    final labelStyle = DefaultTextStyle.of(context).style.merge(
      SongletType.footnote.copyWith(
        fontWeight: FontWeight.w600,
        height: _labelLineHeight,
      ),
    );
    // Measure the localized labels: two lines at most, and no long Latin
    // word split across the tile's edge.
    bool labelsFit(int count) {
      final labelWidth =
          (width - (count - 1) * SongletSpace.x2) / count - SongletSpace.x4;
      for (final name in names) {
        final painter = TextPainter(
          text: TextSpan(text: name, style: labelStyle),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 2,
        )..layout(maxWidth: labelWidth);
        final clipped = painter.didExceedMaxLines;
        painter.dispose();
        if (clipped) return false;
        for (final word in _latinWord.allMatches(name)) {
          final wordPainter = TextPainter(
            text: TextSpan(text: word.group(0), style: labelStyle),
            textDirection: direction,
            textScaler: scaler,
          )..layout();
          final tooWide = wordPainter.width > labelWidth;
          wordPainter.dispose();
          if (tooWide) return false;
        }
      }
      return true;
    }

    while (columns > 1 && !labelsFit(columns)) {
      columns--;
    }
    return IdeaGridLayout(
      columns: columns,
      aspect: accessible ? SongletSize.tileAspectWide : SongletSize.tileAspect,
      tileWidth: (width - (columns - 1) * SongletSpace.x2) / columns,
      headerExtent:
          scaler.scale(SongletType.headline.fontSize ?? _headlineFallback) *
              _headingLineHeight +
          SongletSpace.x2,
    );
  }

  /// Start with four phone columns; translated labels may need wider tiles.
  static const int minColumns = 4;
  static const int maxColumns = 6;

  /// Tight line height of the two-line tile title.
  static const double _labelLineHeight = 1.15;

  /// Line height of the "MusicInspiration" heading.
  static const double _headingLineHeight = 1.3;

  /// The iOS headline size, should the token ever carry none.
  static const double _headlineFallback = 17;

  static final RegExp _latinWord = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]+');

  final int columns;

  /// Width / height of a tile.
  final double aspect;
  final double tileWidth;

  /// The "MusicInspiration" heading with the space under it.
  final double headerExtent;

  /// One row of tiles with the spacing under it.
  double get rowExtent => tileWidth / aspect + SongletSpace.x2;

  /// The heading and one full row: what the page always leaves the grid
  /// (ADR-0034).
  double get minExtent => headerExtent + rowExtent;

  /// Scroll offset of the tile at [index].
  double offsetOf(int index) => headerExtent + (index ~/ columns) * rowExtent;
}
