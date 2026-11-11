import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'aura_style.dart';
import 'tokens.dart';
import 'tokens/songlet_colors.dart';
import 'tokens/songlet_elevation.dart';
import 'tokens/songlet_metrics.dart';
import 'tokens/songlet_type.dart';
import 'typography.dart';

/// Builds the Aura [ThemeData]. Dark is the signature look; light is provided
/// for extensibility.
abstract final class AuraTheme {
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData get light => _build(Brightness.light);

  /// The warm Songlet look (docs/ui), light. Built only from tokens
  /// (ADR-0004).
  static ThemeData get warm => songlet(Brightness.light);

  /// The warm Songlet look, dark.
  static ThemeData get warmDark => songlet(Brightness.dark);

  /// Songlet theme for [brightness]: colour roles from [SongletColors], shadows
  /// from [SongletElevation], type from [SongletType].
  static ThemeData songlet(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final c = isDark ? SongletColors.dark : SongletColors.light;
    final elevation = isDark ? SongletElevation.dark : SongletElevation.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.ink,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.danger,
      onError: c.onAccent,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.ink,
      surface: c.canvas,
      onSurface: c.ink,
      onSurfaceVariant: c.inkSecondary,
      surfaceContainerLowest: c.canvas,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceMuted,
      surfaceContainerHighest: c.surfaceRaised,
      outline: c.hairline,
      outlineVariant: c.hairline,
      scrim: c.scrim,
      shadow: elevation.level1.first.color,
      surfaceTint: Colors.transparent,
    );
    final text = songletTextTheme(c);
    final theme = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: c.canvas,
      dividerColor: c.hairline,
      textTheme: text,
      extensions: [c, elevation, isDark ? AuraStyle.warmDark : AuraStyle.warm],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: c.ink,
        centerTitle: false,
        titleTextStyle: SongletType.headline.copyWith(color: c.ink),
      ),
      iconTheme: IconThemeData(color: c.ink, size: SongletSize.iconLg),
      dividerTheme: DividerThemeData(
        color: c.hairline,
        thickness: SongletSize.hairline,
        space: SongletSize.hairline,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SongletSpace.x4,
          vertical: SongletSpace.x4,
        ),
        border: const OutlineInputBorder(
          borderRadius: SongletRadius.controlAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: SongletRadius.controlAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SongletRadius.controlAll,
          borderSide: BorderSide(color: c.accent, width: SongletSize.focusRing),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: SongletRadius.controlAll,
          borderSide: BorderSide(color: c.danger, width: SongletSize.focusRing),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: SongletRadius.controlAll,
          borderSide: BorderSide(color: c.danger, width: SongletSize.focusRing),
        ),
        hintStyle: SongletType.callout.copyWith(color: c.inkSecondary),
        errorStyle: SongletType.footnote.copyWith(color: c.danger),
        helperStyle: SongletType.footnote.copyWith(color: c.inkSecondary),
        counterStyle: SongletType.caption.copyWith(color: c.inkSecondary),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accentSoft,
        selectionHandleColor: c.accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceMuted,
        circularTrackColor: c.surfaceMuted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(c.surface),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.accent : c.inkTertiary,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      // Sheets sit on the canvas colour so the white cards inside them read
      // as cards (docs/ui P02).
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised,
        modalBackgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: SongletRadius.sheetTop,
        ),
        showDragHandle: true,
        dragHandleColor: c.inkTertiary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: SongletRadius.cardAll,
        ),
        titleTextStyle: SongletType.headline.copyWith(color: c.ink),
        contentTextStyle: SongletType.subhead.copyWith(color: c.inkSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface.withValues(alpha: isDark ? 0.82 : 0.94),
        elevation: 0,
        indicatorColor: c.accentSoft,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => SongletType.caption2.copyWith(
            color: states.contains(WidgetState.selected)
                ? c.accent
                : c.inkSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c.accent
                : c.inkSecondary,
            size: SongletSize.iconLg,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface.withValues(alpha: isDark ? 0.82 : 0.94),
        indicatorColor: c.accentSoft,
        selectedIconTheme: IconThemeData(color: c.accent),
        unselectedIconTheme: IconThemeData(color: c.inkSecondary),
        selectedLabelTextStyle: SongletType.caption2.copyWith(color: c.accent),
        unselectedLabelTextStyle: SongletType.caption2.copyWith(
          color: c.inkSecondary,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
    );
    // NavigationRail sets its label style verbatim (no merge with the text
    // theme), so the labels take the resolved theme's font family here.
    final rail = theme.textTheme.labelSmall!;
    return theme.copyWith(
      navigationRailTheme: theme.navigationRailTheme.copyWith(
        selectedLabelTextStyle: rail.merge(
          theme.navigationRailTheme.selectedLabelTextStyle,
        ),
        unselectedLabelTextStyle: rail.merge(
          theme.navigationRailTheme.unselectedLabelTextStyle,
        ),
      ),
    );
  }

  /// Maps [SongletType] onto Material's text roles, coloured from [c].
  static TextTheme songletTextTheme(SongletColors c) => TextTheme(
    displayLarge: SongletType.largeTitle.copyWith(color: c.ink),
    displayMedium: SongletType.title1.copyWith(color: c.ink),
    displaySmall: SongletType.title2.copyWith(color: c.ink),
    headlineLarge: SongletType.title1.copyWith(color: c.ink),
    headlineMedium: SongletType.title2.copyWith(color: c.ink),
    headlineSmall: SongletType.title3.copyWith(color: c.ink),
    titleLarge: SongletType.title3.copyWith(color: c.ink),
    titleMedium: SongletType.headline.copyWith(color: c.ink),
    titleSmall: SongletType.subhead.copyWith(
      color: c.ink,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: SongletType.body.copyWith(color: c.ink),
    bodyMedium: SongletType.subhead.copyWith(color: c.inkSecondary),
    bodySmall: SongletType.footnote.copyWith(color: c.inkSecondary),
    labelLarge: SongletType.headline.copyWith(color: c.ink),
    labelMedium: SongletType.footnote.copyWith(
      color: c.inkSecondary,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: SongletType.caption2.copyWith(color: c.inkSecondary),
  );

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: StudioTokens.auroraViolet,
      brightness: brightness,
    );
    final primary = isDark
        ? StudioTokens.textPrimary
        : StudioTokens.lightTextPrimary;
    final secondary = isDark
        ? StudioTokens.textSecondary
        : StudioTokens.lightTextSecondary;

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? StudioTokens.voidBlack
          : StudioTokens.lightBackground,
      textTheme: StudioTypography.textTheme(
        primary: primary,
        secondary: secondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primary,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? StudioTokens.nebula : null,
      ),
    );
  }
}
