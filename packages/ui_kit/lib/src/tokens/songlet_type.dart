import 'package:flutter/material.dart';

/// The type system (docs/ui). Three voices, each with one job:
///
/// * **the grotesque** — the display voice. System sans, set black and very
///   tight (negative tracking at display sizes): mastheads, titles, figures.
///   This is the poster voice.
/// * **the serif** — the emotional voice. Lyrics, quotes, standfirsts. It is
///   never used for chrome.
/// * **the mono** — the operator's voice. Every label, folio, price, timestamp
///   and stamp, tracked wide: the small print that tells you what you are
///   looking at.
///
/// Styles carry size, weight, leading and tracking only; colour comes from the
/// theme.
abstract final class SongletType {
  /// The masthead: the publication's name, black and tight.
  static const TextStyle masthead = TextStyle(
    fontSize: 44,
    height: 1.02,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.2,
  );

  /// A struck figure — credits, percent, counts — tabular so it never jitters.
  static const TextStyle numeral = TextStyle(
    fontSize: 46,
    height: 1.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    height: 1.06,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.4,
  );

  static const TextStyle title1 = TextStyle(
    fontSize: 27,
    height: 1.12,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.9,
  );

  static const TextStyle title2 = TextStyle(
    fontSize: 21,
    height: 1.18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static const TextStyle title3 = TextStyle(
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  /// The serif voice: a lyric line, a standfirst, a quote.
  static const TextStyle lede = TextStyle(
    fontFamily: serifFamily,
    fontFamilyFallback: serifFallback,
    fontSize: 19,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 16.5,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 17,
    height: 1.45,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.15,
  );

  static const TextStyle callout = TextStyle(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );

  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    height: 1.38,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w400,
  );

  /// Numbered list folios, prices, times: mono, tabular, tracked.
  static const TextStyle folio = TextStyle(
    fontFamily: monoFamily,
    fontFamilyFallback: monoFallback,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  /// The small tracked label above a title or beside a value ("SECTION 01").
  static const TextStyle eyebrow = TextStyle(
    fontFamily: monoFamily,
    fontFamilyFallback: monoFallback,
    fontSize: 10.5,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.8,
  );

  /// Rubber-stamp lettering: the AI badge, "NEW", the offer tag.
  static const TextStyle stamp = TextStyle(
    fontFamily: monoFamily,
    fontFamilyFallback: monoFallback,
    fontSize: 10,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
  );

  /// The display face for the share card (a print artefact of its own).
  static const String serifFamily = 'Georgia';

  /// Families tried when [serifFamily] has no glyph for a character.
  static const List<String> serifFallback = [
    'Songti SC',
    'STSong',
    'Noto Serif CJK SC',
    'Times New Roman',
  ];

  /// The mono voice. Menlo ships with iOS and macOS; SF Mono and Consolas
  /// cover the rest, and the platform's own text face is the last resort — a
  /// tracked label in the normal sans is better than a missing-glyph box.
  static const String monoFamily = 'Menlo';

  static const List<String> monoFallback = [
    'SF Mono',
    'Consolas',
    'Noto Sans Mono',
    'DejaVu Sans Mono',
    'Courier New',
    'Roboto',
    '.SF Pro Text',
    'CupertinoSystemText',
  ];

  /// Share-card display serif (docs/ui P10).
  static const TextStyle displaySerif = TextStyle(
    fontFamily: serifFamily,
    fontFamilyFallback: serifFallback,
    fontSize: 56,
    height: 1.05,
    fontWeight: FontWeight.w400,
  );

  /// Share-card lyric serif.
  static const TextStyle bodySerif = TextStyle(
    fontFamily: serifFamily,
    fontFamilyFallback: serifFallback,
    fontSize: 22,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  /// Ordered largest → smallest (for scale tests and docs).
  static const List<TextStyle> scale = [
    numeral,
    masthead,
    largeTitle,
    title1,
    title2,
    lede,
    title3,
    body,
    headline,
    callout,
    subhead,
    footnote,
    caption,
    folio,
    caption2,
    eyebrow,
    stamp,
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

  /// [style] carrying the tabular figures that keep ruled values aligned.
  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

/// [style] completed with the theme's font family and features. Needed where
/// Material takes a style verbatim instead of merging it with the ambient
/// text style — button `textStyle`s.
TextStyle themedTextStyle(BuildContext context, TextStyle style) =>
    (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).merge(style);
