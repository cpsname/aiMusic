import 'package:flutter/material.dart';

/// Colour roles for the Songlet look, light and dark (docs/ui; ADR-0004).
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
    this.onArt = const Color(0xFFFFFFFF),
    this.artScrim = const Color(0xA6000000),
  });

  /// Holographic light surfaces: the same aurora language remains legible in
  /// daylight without turning the product back into a warm, opaque UI.
  static const SongletColors light = SongletColors(
    canvas: Color(0xFFF4F6FF),
    surface: Color(0xF2FFFFFF),
    surfaceMuted: Color(0xFFE9EDFA),
    surfaceRaised: Color(0xFFFFFFFF),
    hairline: Color(0xFFD7DDF2),
    accent: Color(0xFF6752E8),
    accentPressed: Color(0xFF4D3BC6),
    accentSoft: Color(0xFFE7E3FF),
    onAccent: Color(0xFFFFFFFF),
    ink: Color(0xFF11152A),
    inkSecondary: Color(0xFF5E6682),
    inkTertiary: Color(0xFF929AB6),
    success: Color(0xFF118C78),
    warning: Color(0xFF9A6410),
    danger: Color(0xFFC43F55),
    dangerSoft: Color(0xFFFFE5EB),
    scrim: Color(0x6611152A),
    badgeFill: Color(0xCC11152A),
    onBadge: Color(0xFFFFFFFF),
    waveformIdle: Color(0xFFC9D0E8),
  );

  /// Signature Songlet surface: deep space, cool ink and aurora accents.
  static const SongletColors dark = SongletColors(
    canvas: Color(0xFF0B0E1A),
    surface: Color(0x141F2945),
    surfaceMuted: Color(0x1A8390B8),
    surfaceRaised: Color(0x262D3D5F),
    hairline: Color(0x3DFFFFFF),
    accent: Color(0xFF7C5CFF),
    accentPressed: Color(0xFF5D42D6),
    accentSoft: Color(0x297C5CFF),
    onAccent: Color(0xFFFFFFFF),
    ink: Color(0xFFF2F4FF),
    inkSecondary: Color(0xFFA6ACCB),
    inkTertiary: Color(0xFF5F6584),
    success: Color(0xFF22E0C3),
    warning: Color(0xFFFFB454),
    danger: Color(0xFFFF5C6E),
    dangerSoft: Color(0x33FF5C6E),
    scrim: Color(0xB3000000),
    badgeFill: Color(0xCC06070D),
    onBadge: Color(0xFFFFFFFF),
    waveformIdle: Color(0x4DFFFFFF),
  );

  /// Page background.
  final Color canvas;

  /// Cards, sheets, tab bar.
  final Color surface;

  /// Input fields, segmented tracks, neutral chips.
  final Color surfaceMuted;

  /// Popovers and floating cards above [surface].
  final Color surfaceRaised;

  /// Dividers and card outlines.
  final Color hairline;

  /// Primary actions, selection, progress.
  final Color accent;
  final Color accentPressed;

  /// Tinted fills: selected chips, badges, banners.
  final Color accentSoft;

  /// Content on [accent].
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

  /// Text and icons laid over photographic art (same in both modes).
  final Color onArt;

  /// Bottom gradient behind [onArt] text on art.
  final Color artScrim;

  /// Primary action gradient (accent → pressed).
  LinearGradient get actionGradient => LinearGradient(
    colors: [accent, accentPressed],
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
      onArt: l(onArt, other.onArt),
      artScrim: l(artScrim, other.artScrim),
    );
  }
}
