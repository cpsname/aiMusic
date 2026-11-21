import 'package:flutter/widgets.dart';

/// Aura design tokens — spacing, radii, palette, gradients and motion.
///
/// The values are warm: this file is the same press run as [SongletColors],
/// kept for the template's original primitives (skeletons, message stack,
/// legacy profile screens) so nothing in the kit still points at the old
/// violet/glass world.
abstract final class StudioTokens {
  // Spacing scale.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double space2xl = 48;

  // Corner radii.
  static const double radiusSm = 4;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusPill = 999;

  // Ink palette.
  static const Color voidBlack = Color(0xFF12100E);
  static const Color deepSpace = Color(0xFF171310);
  static const Color nebula = Color(0xFF221C18);
  static const Color auroraViolet = Color(0xFFC6431D);
  static const Color auroraBlue = Color(0xFFC8842A);
  static const Color auroraTeal = Color(0xFF6C8560);
  static const Color auroraPink = Color(0xFFB4553F);
  static const Color textPrimary = Color(0xFFF3E9DE);
  static const Color textSecondary = Color(0xFFB5A698);

  // Semantic feedback colours (Message component + status surfaces).
  static const Color successColor = Color(0xFF6C8560);
  static const Color warningColor = Color(0xFFC8842A);
  static const Color errorColor = Color(0xFFB33327);
  static const Color infoColor = Color(0xFF8A6A4F);

  // Light plates (the sample app's light theme).
  static const Color lightBackground = Color(0xFFF4EDE2);
  static const Color lightTextPrimary = Color(0xFF221C17);
  static const Color lightTextSecondary = Color(0xFF6B5F53);

  // Rule and plate tints.
  static const Color glassFill = Color(0x14FFFFFF); // white @ 8%
  static const Color glassStroke = Color(0x26FFFFFF); // white @ 15%

  // Two-ink gradients: neighbouring tones of the same plate, for duotone
  // text and the odd warm mark. Never a rainbow.
  static const LinearGradient auroraGradient = LinearGradient(
    colors: [auroraViolet, auroraBlue],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [auroraPink, auroraViolet],
  );

  // Motion.
  static const Duration durationFast = Duration(milliseconds: 180);
  static const Duration durationMedium = Duration(milliseconds: 420);
  static const Duration auroraDrift = Duration(seconds: 12);
  static const Duration shimmer = Duration(milliseconds: 1200);
}

/// Light-mode constants of the Songlet tokens for contexts without a theme
/// (the share-card renderer paints on a `dart:ui` canvas). Widgets read
/// [SongletColors.of] instead so dark mode applies.
abstract final class SongletPalette {
  static const Color canvas = Color(0xFFF2EFE9);
  static const Color card = Color(0xFFFCFBF8);
  static const Color hairline = Color(0xFFCFC8BA);
  static const Color terracotta = Color(0xFFF2401C);
  static const Color terracottaDeep = Color(0xFFC93012);
  static const Color blush = Color(0xFFFBD9CF);
  static const Color ink = Color(0xFF111010);
  static const Color inkSoft = Color(0xFF6A6357);
  static const Color field = Color(0xFFE7E2D8);

  static const LinearGradient actionGradient = LinearGradient(
    colors: [ink, Color(0xFF2B2825)],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );
}
