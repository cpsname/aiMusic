import 'package:flutter/material.dart';

import 'tokens.dart';
import 'tokens/songlet_colors.dart';
import 'tokens/songlet_elevation.dart';

/// Surface + accent styling the primitives read from the ambient theme, so one
/// component set serves both runs of the press. Absent from a theme → the
/// warm daylight defaults.
@immutable
class AuraStyle extends ThemeExtension<AuraStyle> {
  const AuraStyle({
    required this.cardFill,
    required this.cardStroke,
    required this.actionGradient,
    required this.accent,
    this.cardShadow = const <BoxShadow>[],
    this.cardBlur = false,
    this.onAction = const Color(0xFFFFF8F1),
  });

  /// Warm daylight defaults, for a context without the Songlet extension.
  static const AuraStyle aura = AuraStyle(
    cardFill: SongletPalette.card,
    cardStroke: SongletPalette.hairline,
    actionGradient: SongletPalette.actionGradient,
    accent: SongletPalette.terracotta,
  );

  /// Light paper run.
  static final AuraStyle warm = _songlet(
    SongletColors.light,
    SongletElevation.light,
  );

  /// Night paper run.
  static final AuraStyle warmDark = _songlet(
    SongletColors.dark,
    SongletElevation.dark,
  );

  static AuraStyle _songlet(SongletColors c, SongletElevation e) => AuraStyle(
    cardFill: c.surface,
    cardStroke: c.hairline,
    actionGradient: c.actionGradient,
    accent: c.accent,
    cardShadow: e.level1,
    onAction: c.onAccent,
  );

  final Color cardFill;
  final Color cardStroke;
  final Gradient actionGradient;
  final Color accent;
  final List<BoxShadow> cardShadow;

  /// Kept for the template's primitives; the press never frosts glass.
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
