import 'package:flutter/widgets.dart';

/// Aura design tokens — spacing, radii, palette, gradients and motion. Pure
/// constants; no theme lookup required.
abstract final class StudioTokens {
  // Spacing scale.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double space2xl = 48;

  // Corner radii.
  static const double radiusSm = 10;
  static const double radiusMd = 18;
  static const double radiusLg = 28;
  static const double radiusPill = 999;

  // Dark "Aura" palette.
  static const Color voidBlack = Color(0xFF06070D);
  static const Color deepSpace = Color(0xFF0B0E1A);
  static const Color nebula = Color(0xFF141A30);
  static const Color auroraViolet = Color(0xFF7C5CFF);
  static const Color auroraBlue = Color(0xFF2FB6FF);
  static const Color auroraTeal = Color(0xFF22E0C3);
  static const Color auroraPink = Color(0xFFFF5CA8);
  static const Color textPrimary = Color(0xFFF2F4FF);
  static const Color textSecondary = Color(0xFFA6ACCB);

  // Semantic feedback colors (Message component + status surfaces).
  static const Color successColor = auroraTeal;
  static const Color warningColor = Color(0xFFFFB454);
  static const Color errorColor = Color(0xFFFF5C6E);
  static const Color infoColor = auroraBlue;

  // Light surfaces (for the extensible light theme).
  static const Color lightBackground = Color(0xFFF5F6FF);
  static const Color lightTextPrimary = Color(0xFF161A2C);
  static const Color lightTextSecondary = Color(0xFF5A5E78);

  // Glass surface.
  static const Color glassFill = Color(0x14FFFFFF); // white @ 8%
  static const Color glassStroke = Color(0x26FFFFFF); // white @ 15%

  // Signature gradients.
  static const LinearGradient auroraGradient = LinearGradient(
    colors: [auroraViolet, auroraBlue, auroraTeal],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [auroraPink, auroraViolet],
  );

  // Motion.
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 450);
  static const Duration auroraDrift = Duration(seconds: 12);
  static const Duration shimmer = Duration(milliseconds: 1200);
}

/// Light-mode constants of the Songlet tokens for contexts without a theme
/// (the share-card renderer paints on a `dart:ui` canvas). Widgets read
/// [SongletColors.of] instead so dark mode applies.
abstract final class SongletPalette {
  static const Color canvas = Color(0xFFFFF6EE);
  static const Color card = Color(0xFFFFFFFF);
  static const Color hairline = Color(0xFFF0E2D8);
  static const Color terracotta = Color(0xFFC9472B);
  static const Color terracottaDeep = Color(0xFFB03B22);
  static const Color blush = Color(0xFFFBECE5);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color inkSoft = Color(0xFF8A8A8A);
  static const Color field = Color(0xFFF7EDE5);

  static const LinearGradient actionGradient = LinearGradient(
    colors: [terracotta, terracottaDeep],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );
}
