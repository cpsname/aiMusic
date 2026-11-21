import 'package:flutter/material.dart';

/// Colour roles for the Songlet look, light and dark (docs/ui; ADR-0004).
///
/// Two-ink printing on bone stock: the ground is a cool bone white, the ink is
/// near-black, and a single signal coral is used as a *spot* — rules, numerals,
/// progress, selection — never as a field of colour. The primary action is
/// printed in ink, the way a poster signs its one call to action.
/// Components read roles through [SongletColors.of]; nothing hardcodes a hex.
@immutable
class SongletColors extends ThemeExtension<SongletColors> {
  const SongletColors({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.hairline,
    required this.accent,
    required this.accentPressed,
    required this.accentSoft,
    required this.onAccent,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.dangerSoft,
    required this.scrim,
    required this.badgeFill,
    required this.onBadge,
    required this.waveformIdle,
    this.highlight = const Color(0xFF1B33F0),
    this.highlightSoft = const Color(0xFFDDE2FF),
    this.onHighlight = const Color(0xFFFFFFFF),
    this.onArt = const Color(0xFFFFFDF9),
    this.artScrim = const Color(0xA60F0D0C),
  });

  /// Daylight sheet: warm clay stock, espresso ink, vermilion plate.
  static const SongletColors light = SongletColors(
    canvas: Color(0xFFF4E6D7),
    surface: Color(0xFFFDF7EE),
    surfaceMuted: Color(0xFFEBD9C6),
    surfaceRaised: Color(0xFFFFFCF6),
    hairline: Color(0xFFD9C3AC),
    accent: Color(0xFFC93C17),
    accentPressed: Color(0xFFA32F10),
    accentSoft: Color(0xFFF9D9CB),
    onAccent: Color(0xFFFFF6EC),
    ink: Color(0xFF241A14),
    inkSecondary: Color(0xFF6F5A4A),
    inkTertiary: Color(0xFFA38B78),
    success: Color(0xFF4E7A52),
    warning: Color(0xFFA96A12),
    danger: Color(0xFFA3231B),
    dangerSoft: Color(0xFFF7DAD2),
    scrim: Color(0x80241A14),
    badgeFill: Color(0xE6241A14),
    onBadge: Color(0xFFFFF6EC),
    waveformIdle: Color(0xFFDCC7B1),
    highlight: Color(0xFFA9762A),
    highlightSoft: Color(0xFFF6E6C8),
    onHighlight: Color(0xFF3A2A10),
  );

  /// Night sheet: espresso stock, the same vermilion plate.
  static const SongletColors dark = SongletColors(
    canvas: Color(0xFF1A1410),
    surface: Color(0xFF241C16),
    surfaceMuted: Color(0xFF2E241C),
    surfaceRaised: Color(0xFF2A211A),
    hairline: Color(0xFF3E3229),
    accent: Color(0xFFFF7A4D),
    accentPressed: Color(0xFFFF9A75),
    accentSoft: Color(0xFF3D1F14),
    onAccent: Color(0xFF1A0C06),
    ink: Color(0xFFF6EADC),
    inkSecondary: Color(0xFFC0A895),
    inkTertiary: Color(0xFF8A7563),
    success: Color(0xFF9CC08A),
    warning: Color(0xFFE7B06A),
    danger: Color(0xFFFF7A63),
    dangerSoft: Color(0xFF3D1D17),
    scrim: Color(0xB3000000),
    badgeFill: Color(0xCC100B08),
    onBadge: Color(0xFFFFF6EC),
    waveformIdle: Color(0xFF4A3B2D),
    highlight: Color(0xFFE7B06A),
    highlightSoft: Color(0xFF3A2C18),
    onHighlight: Color(0xFF1E1408),
  );

  /// Page background: the stock.
  final Color canvas;

  /// Cards, sheets, tab bar: a lighter pull of the same stock.
  final Color surface;

  /// Input fields, segmented tracks, neutral chips.
  final Color surfaceMuted;

  /// Popovers and plates above [surface].
  final Color surfaceRaised;

  /// Dividers, rules and plate outlines.
  final Color hairline;

  /// The signal colour: selection, progress, numerals, the odd rule.
  final Color accent;
  final Color accentPressed;

  /// Tinted fills: selected chips, badges, banners.
  final Color accentSoft;

  /// Content on [accent] — near-black, because the signal is bright.
  final Color onAccent;

  /// Primary text and icons.
  final Color ink;

  /// Supporting text (metadata, hints).
  final Color inkSecondary;

  /// Disabled content and placeholders.
  final Color inkTertiary;

  final Color success;
  final Color warning;
  final Color danger;

  /// Error banner fill.
  final Color dangerSoft;

  /// Modal barrier.
  final Color scrim;

  /// "AI generated" badge fill (sits on artwork).
  final Color badgeFill;
  final Color onBadge;

  /// Unplayed waveform bars.
  final Color waveformIdle;

  /// The second ink: cobalt, reserved for offers and counters ("Best value",
  /// "Recommended"). Used rarely, like a second plate in a two-colour print.
  final Color highlight;
  final Color highlightSoft;
  final Color onHighlight;

  /// Text and icons laid over photographic art (same in both modes).
  final Color onArt;

  /// Bottom gradient behind [onArt] text on art.
  final Color artScrim;

  /// True when this sheet is the night run.
  bool get isDark => canvas.computeLuminance() < 0.2;

  /// Primary action gradient — kept for the template's callers; the press
  /// prints actions in flat ink.
  LinearGradient get actionGradient => LinearGradient(
    colors: [ink, Color.lerp(ink, accent, 0.18)!],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  static SongletColors of(BuildContext context) =>
      Theme.of(context).extension<SongletColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  SongletColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceRaised,
    Color? hairline,
    Color? accent,
    Color? accentPressed,
    Color? accentSoft,
    Color? onAccent,
    Color? ink,
    Color? inkSecondary,
    Color? inkTertiary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? dangerSoft,
    Color? scrim,
    Color? badgeFill,
    Color? onBadge,
    Color? waveformIdle,
    Color? highlight,
    Color? highlightSoft,
    Color? onHighlight,
    Color? onArt,
    Color? artScrim,
  }) => SongletColors(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    hairline: hairline ?? this.hairline,
    accent: accent ?? this.accent,
    accentPressed: accentPressed ?? this.accentPressed,
    accentSoft: accentSoft ?? this.accentSoft,
    onAccent: onAccent ?? this.onAccent,
    ink: ink ?? this.ink,
    inkSecondary: inkSecondary ?? this.inkSecondary,
    inkTertiary: inkTertiary ?? this.inkTertiary,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    dangerSoft: dangerSoft ?? this.dangerSoft,
    scrim: scrim ?? this.scrim,
    badgeFill: badgeFill ?? this.badgeFill,
    onBadge: onBadge ?? this.onBadge,
    waveformIdle: waveformIdle ?? this.waveformIdle,
    highlight: highlight ?? this.highlight,
    highlightSoft: highlightSoft ?? this.highlightSoft,
    onHighlight: onHighlight ?? this.onHighlight,
    onArt: onArt ?? this.onArt,
    artScrim: artScrim ?? this.artScrim,
  );

  @override
  SongletColors lerp(covariant SongletColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SongletColors(
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      hairline: l(hairline, other.hairline),
      accent: l(accent, other.accent),
      accentPressed: l(accentPressed, other.accentPressed),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccent: l(onAccent, other.onAccent),
      ink: l(ink, other.ink),
      inkSecondary: l(inkSecondary, other.inkSecondary),
      inkTertiary: l(inkTertiary, other.inkTertiary),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      scrim: l(scrim, other.scrim),
      badgeFill: l(badgeFill, other.badgeFill),
      onBadge: l(onBadge, other.onBadge),
      waveformIdle: l(waveformIdle, other.waveformIdle),
      highlight: l(highlight, other.highlight),
      highlightSoft: l(highlightSoft, other.highlightSoft),
      onHighlight: l(onHighlight, other.onHighlight),
      onArt: l(onArt, other.onArt),
      artScrim: l(artScrim, other.artScrim),
    );
  }
}
