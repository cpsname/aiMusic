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

  /// Horizontal page gutter on compact widths: 16 pt, the prototypes' edge
  /// and UIKit's compact layout margin (docs/ui/diff-report.md).
  static const double gutter = x4;

  /// Denser gutter of the create home, whose template grid and composer run
  /// closer to the edge (docs/ui P01, diff report).
  static const double gutterDense = x3;

  /// Sheet content inset (docs/ui P02, diff report).
  static const double sheetInset = x5;

  /// Horizontal page gutter on regular widths (iPad).
  static const double gutterRegular = x8;
}

/// Corner radii (docs/ui): cards 20, sheets 24, controls 16.
abstract final class SongletRadius {
  static const double thumb = 12;
  static const double control = 18;
  static const double card = 24;
  static const double sheet = 28;
  static const double pill = 999;

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
  static const double controlHeight = 52;

  /// The primary gradient action (ObsButton) — the page's one main action.
  static const double primaryAction = 54;

  /// Spinner inside a primary action while it is busy.
  static const double actionSpinner = 22;
  static const double compactControlHeight = 36;
  static const double chipHeight = 32;
  static const double iconXs = 12;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
  static const double playButton = 64;
  static const double playButtonSm = 36;
  static const double brandMark = 40;
  static const double thumbnail = 56;
  static const double coverLarge = 240;
  static const double waveformHeight = 56;
  static const double progressHeight = 6;
  static const double hairline = 1;
  static const double focusRing = 2;

  /// Unselected radio ring stroke.
  static const double ring = 1.5;

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

  /// Minimum template tile width in the adaptive grid (four per row on a
  /// 393 pt phone, docs/ui P01).
  static const double tileMinExtent = 80;

  /// Template tile width ÷ height (docs/ui P01).
  static const double tileAspect = 0.86;

  /// Tile width ÷ height at accessibility text sizes: one tile per row, so a
  /// landscape card keeps the art visible without a screen-tall tile.
  static const double tileAspectWide = 1.6;

  /// Minimum height of the composer's prompt field.
  static const double promptMinHeight = 48;

  /// Bars in a live level meter / generated waveform.
  static const int waveformBars = 48;

  /// Share-card aspect ratio (9:16, PRD F08).
  static const double shareCardAspect = 9 / 16;

  /// Max height of a list-picker bottom sheet as a share of the screen
  /// height (lyric-language pickers in settings and the region sheet).
  static const double pickerSheetFactor = 0.7;
}
