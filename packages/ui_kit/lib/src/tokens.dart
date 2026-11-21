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
  static const Color deepSpace = Color(0xFF1A1410);
  static const Color nebula = Color(0xFF241C16);
  static const Color auroraViolet = Color(0xFFC93C17);
  static const Color auroraBlue = Color(0xFFA9762A);
  static const Color auroraTeal = Color(0xFF4E7A52);
  static const Color auroraPink = Color(0xFF8E3A22);
  static const Color textPrimary = Color(0xFFF6EADC);
  static const Color textSecondary = Color(0xFFC0A895);

  // Semantic feedback colours (Message component + status surfaces).
  static const Color successColor = Color(0xFF4E7A52);
  static const Color warningColor = Color(0xFFA96A12);
  static const Color errorColor = Color(0xFFA3231B);
  static const Color infoColor = Color(0xFFA9762A);

  // Light plates (the sample app's light theme).
  static const Color lightBackground = Color(0xFFF4E6D7);
  static const Color lightTextPrimary = Color(0xFF241A14);
  static const Color lightTextSecondary = Color(0xFF6F5A4A);

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
  static const Color canvas = Color(0xFFF4E6D7);
  static const Color card = Color(0xFFFDF7EE);
  static const Color hairline = Color(0xFFD9C3AC);
  static const Color terracotta = Color(0xFFC93C17);
  static const Color terracottaDeep = Color(0xFFA32F10);
  static const Color blush = Color(0xFFF9D9CB);
  static const Color ink = Color(0xFF241A14);
  static const Color inkSoft = Color(0xFF6F5A4A);
  static const Color field = Color(0xFFEBD9C6);

  static const LinearGradient actionGradient = LinearGradient(
    colors: [terracotta, terracottaDeep],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );
}
