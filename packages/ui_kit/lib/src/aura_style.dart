import 'package:flutter/material.dart';

import 'tokens.dart';
import 'tokens/songlet_colors.dart';
import 'tokens/songlet_elevation.dart';

/// Surface + accent styling the Aura primitives read from the ambient theme,
/// so one component set serves both the signature dark "Aura" look and the
/// warm light "Songlet" look. Absent from a theme → the dark Aura defaults.
@immutable
class AuraStyle extends ThemeExtension<AuraStyle> {
  const AuraStyle({
    required this.cardFill,
    required this.cardStroke,
    required this.actionGradient,
    required this.accent,
    this.cardShadow = const <BoxShadow>[],
    this.cardBlur = true,
    this.onAction = const Color(0xFFFFFFFF),
  });

  /// The dark Aura defaults (frosted glass, aurora gradient).
  static const AuraStyle aura = AuraStyle(
    cardFill: StudioTokens.glassFill,
    cardStroke: StudioTokens.glassStroke,
    actionGradient: StudioTokens.auroraGradient,
    accent: StudioTokens.auroraViolet,
  );

  /// Light holographic surfaces: opaque enough for daylight readability while
  /// retaining the cool aurora language.
  static final AuraStyle warm = _songlet(
    SongletColors.light,
    SongletElevation.light,
    blur: false,
  );

  /// Signature dark theme: translucent glass over the deep-space canvas.
  static final AuraStyle warmDark = _songlet(
    SongletColors.dark,
    SongletElevation.dark,
    blur: true,
  );

  static AuraStyle _songlet(
    SongletColors c,
    SongletElevation e, {
    required bool blur,
  }) => AuraStyle(
    cardFill: c.surface,
    cardStroke: c.hairline,
    actionGradient: c.actionGradient,
    accent: c.accent,
    cardShadow: e.level1,
    cardBlur: blur,
    onAction: c.onAccent,
  );

  final Color cardFill;
  final Color cardStroke;
  final Gradient actionGradient;
  final Color accent;
  final List<BoxShadow> cardShadow;
  final bool cardBlur;

  /// Label and icon colour on [actionGradient].
  final Color onAction;

  static AuraStyle of(BuildContext context) =>
      Theme.of(context).extension<AuraStyle>() ?? aura;

  @override
  AuraStyle copyWith({
    Color? cardFill,
    Color? cardStroke,
    Gradient? actionGradient,
    Color? accent,
    List<BoxShadow>? cardShadow,
    bool? cardBlur,
    Color? onAction,
  }) => AuraStyle(
    cardFill: cardFill ?? this.cardFill,
    cardStroke: cardStroke ?? this.cardStroke,
    actionGradient: actionGradient ?? this.actionGradient,
    accent: accent ?? this.accent,
    cardShadow: cardShadow ?? this.cardShadow,
    cardBlur: cardBlur ?? this.cardBlur,
    onAction: onAction ?? this.onAction,
  );

  @override
  AuraStyle lerp(covariant AuraStyle? other, double t) {
    if (other == null) return this;
    return AuraStyle(
      cardFill: Color.lerp(cardFill, other.cardFill, t)!,
      cardStroke: Color.lerp(cardStroke, other.cardStroke, t)!,
      actionGradient: t < 0.5 ? actionGradient : other.actionGradient,
      accent: Color.lerp(accent, other.accent, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      cardBlur: t < 0.5 ? cardBlur : other.cardBlur,
      onAction: Color.lerp(onAction, other.onAction, t)!,
    );
  }
}
