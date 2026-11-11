import 'package:flutter/material.dart';

/// Type scale (iOS text styles, heavy display titles per docs/ui). Styles carry
/// size, weight, line height and tracking only — colour comes from the theme.
abstract final class SongletType {
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    height: 41 / 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  );
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    height: 25 / 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const TextStyle body = TextStyle(
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    height: 21 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );
  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    height: 13 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  /// Serif family for share cards (Georgia ships with iOS; tests register
  /// the host's serif under the same name).
  static const String serifFamily = 'Georgia';

  /// Share-card display serif (docs/ui P10).
  static const TextStyle displaySerif = TextStyle(
    fontFamily: serifFamily,
    fontSize: 56,
    height: 1.05,
    fontWeight: FontWeight.w400,
  );

  /// Share-card lyric serif.
  static const TextStyle bodySerif = TextStyle(
    fontFamily: serifFamily,
    fontSize: 22,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  /// Ordered largest → smallest (for scale tests and docs).
  static const List<TextStyle> scale = [
    largeTitle,
    title1,
    title2,
    title3,
    headline,
    body,
    callout,
    subhead,
    footnote,
    caption,
    caption2,
  ];

  /// Dynamic Type ceiling for chrome — page headers, pills, bars. UIKit bars
  /// stop growing at xxxLarge (23 pt body) and hand larger sizes to the Large
  /// Content Viewer; page content keeps scaling to AX5.
  static const double chromeMaxTextScale = 23 / 17;

  /// The system colour-emoji family, named as the fallback of text that
  /// carries emoji (country flags) so it resolves the same everywhere.
  static const String emojiFamily = 'Apple Color Emoji';

  /// From AX1 (28 pt body) layouts switch to their accessibility arrangement:
  /// stacked instead of side by side, pinned panels scroll with the page.
  static const double accessibilityTextScale = 28 / 17;

  /// True when [context] renders at an accessibility Dynamic Type size.
  static bool isAccessibilitySize(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(body.fontSize!) / body.fontSize! >=
      accessibilityTextScale;
}

/// [style] completed with the theme's font family and features. Needed where
/// Material takes a style verbatim instead of merging it with the ambient
/// text style — button `textStyle`s.
TextStyle themedTextStyle(BuildContext context, TextStyle style) =>
    (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).merge(style);
