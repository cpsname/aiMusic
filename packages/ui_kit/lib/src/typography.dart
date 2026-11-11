import 'package:flutter/material.dart';

/// Aura typography. Uses the platform font by default; set [fontFamily] (and
/// bundle the asset in the app) to brand it.
abstract final class StudioTypography {
  static const String? fontFamily = null;

  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: primary),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: secondary),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: TextStyle(fontSize: 12, color: secondary),
    );
  }
}
