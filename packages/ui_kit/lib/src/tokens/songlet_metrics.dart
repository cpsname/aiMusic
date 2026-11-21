import 'package:flutter/widgets.dart';

/// Spacing scale — every step is a multiple of 4 pt (docs/ui).
abstract final class SongletSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x7 = 28;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;

  /// Horizontal page gutter on compact widths: a printed margin rather than a
  /// device edge (docs/ui).
  static const double gutter = x5;

  /// Denser gutter of the create home, whose contact sheet runs closer to the
  /// edge than the text pages do.
  static const double gutterDense = x4;

  /// Sheet content inset.
  static const double sheetInset = x6;

  /// Horizontal page gutter on regular widths (iPad).
  static const double gutterRegular = x8;

  /// Vertical rhythm between two printed blocks (sections, cards).
  static const double block = x6;

  /// Space between a rule and the text above or below it.
  static const double ruleGap = x3;
}

/// Corner radii (docs/ui): printed matter is nearly square — plates 4, cards
/// 10, controls 10, sheets 20.
abstract final class SongletRadius {
  static const double thumb = 2;
  static const double control = 8;
  static const double card = 4;
  static const double sheet = 16;

  /// Stamps, bars and tracks: the press has no capsules. Used by the components
  /// that were built as pills, so one number squares them all.
  static const double pill = 2;

  static const BorderRadius controlAll = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius thumbAll = BorderRadius.all(Radius.circular(thumb));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Component sizes that are not spacing (hit targets, control heights, icons,
/// layout breakpoints).
abstract final class SongletSize {
  /// Apple HIG minimum hit target.
  static const double minTap = 44;
  static const double controlHeight = 50;

  /// The primary action bar — the page's one main action.
  static const double primaryAction = 52;

  /// Spinner inside a primary action while it is busy.
  static const double actionSpinner = 20;
  static const double compactControlHeight = 34;
  static const double chipHeight = 30;
  static const double iconXs = 12;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
  static const double playButton = 60;
  static const double playButtonSm = 32;
  static const double brandMark = 34;
  static const double thumbnail = 56;
  static const double coverLarge = 240;
  static const double waveformHeight = 52;
  static const double progressHeight = 3;
  static const double hairline = 1;

  /// The heavier rule that closes a masthead or opens a section.
  static const double rule = 1;
  static const double ruleStrong = 2;
  static const double focusRing = 2;

  /// Unselected radio ring stroke.
  static const double ring = 1.5;

  /// Width of the serif folio that numbers a list row or a section.
  static const double folioColumn = 34;

  /// Readable column width for forms and players on wide screens.
  static const double contentMaxWidth = 600;

  /// Width at and above which layouts switch to two columns (iPad, landscape).
  static const double twoPaneBreakpoint = 700;

  /// Width of the leading pane in a two-column layout.
  static const double leadingPaneMaxWidth = 520;

  /// Max width of an anchored popover panel (docs/ui P02a–c).
  static const double anchoredPanelWidth = contentMaxWidth * 0.6;

  /// Max width of a roomier anchored panel (genre list, template options).
  static const double anchoredPanelWideWidth = contentMaxWidth * 0.7;

  /// Minimum plate width in the adaptive contact sheet (four across on a
  /// 393 pt phone, docs/ui).
  static const double tileMinExtent = 74;

  /// Plate width ÷ height: a portrait photo frame, not a square button.
  static const double tileAspect = 0.76;

  /// Tile width ÷ height at accessibility text sizes: one plate per row, so a
  /// landscape card keeps the art visible without a screen-tall tile.
  static const double tileAspectWide = 1.6;

  /// Minimum height of the composer's prompt field.
  static const double promptMinHeight = 46;

  /// Bars in a live level meter / generated waveform.
  static const int waveformBars = 48;

  /// Share-card aspect ratio (9:16, PRD F08).
  static const double shareCardAspect = 9 / 16;

  /// Max height of a list-picker bottom sheet as a share of the screen
  /// height (lyric-language pickers in settings and the region sheet).
  static const double pickerSheetFactor = 0.7;
}
