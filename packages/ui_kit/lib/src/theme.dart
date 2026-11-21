import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'aura_style.dart';
import 'tokens.dart';
import 'tokens/songlet_colors.dart';
import 'tokens/songlet_elevation.dart';
import 'tokens/songlet_metrics.dart';
import 'tokens/songlet_type.dart';
import 'typography.dart';

/// Builds the press theme. The warm paper run is the product's look; the dark
/// run is the same ink at night, and the legacy Aura themes stay for the
/// template's unreleased screens.
abstract final class AuraTheme {
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData get light => _build(Brightness.light);

  /// The printed Songlet look (docs/ui), light.
  static ThemeData get warm => songlet(Brightness.light);

  /// The printed Songlet look, dark — same press, night stock.
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
      secondary: c.highlight,
      onSecondary: c.onHighlight,
      secondaryContainer: c.highlightSoft,
      onSecondaryContainer: c.ink,
      error: c.danger,
      onError: c.onAccent,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.ink,
      surface: c.canvas,
      onSurface: c.ink,
      onSurfaceVariant: c.inkSecondary,
      surfaceContainerLowest: c.canvas,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surfaceMuted,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceMuted,
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
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      dividerColor: c.hairline,
      textTheme: text,
      extensions: [c, elevation, isDark ? AuraStyle.warmDark : AuraStyle.warm],
      // A printed page has no system chrome above it: no elevation, no tint,
      // a hairline where a rule belongs.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.ink,
        centerTitle: false,
        titleTextStyle: SongletType.headline.copyWith(color: c.ink),
      ),
      iconTheme: IconThemeData(color: c.ink, size: SongletSize.iconLg),
      dividerTheme: DividerThemeData(
        color: c.hairline,
        thickness: SongletSize.rule,
        space: SongletSize.rule,
      ),
      // Fields are ruled boxes, not pills: paper fill, one hairline, and the
      // accent rule when they take focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        isDense: true,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(
          SongletSpace.x4,
          SongletSpace.x4,
          SongletSpace.x4,
          SongletSpace.x4,
        ),
        border: OutlineInputBorder(
          borderRadius: SongletRadius.controlAll,
          borderSide: BorderSide(color: c.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SongletRadius.controlAll,
          borderSide: BorderSide(color: c.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SongletRadius.controlAll,
          borderSide: BorderSide(color: c.accent, width: SongletSize.ruleStrong),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: SongletRadius.controlAll,
          borderSide: BorderSide(color: c.danger, width: SongletSize.ruleStrong),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: SongletRadius.controlAll,
          borderSide: BorderSide(color: c.danger, width: SongletSize.ruleStrong),
        ),
        hintStyle: SongletType.callout.copyWith(color: c.inkTertiary),
        errorStyle: SongletType.footnote.copyWith(color: c.danger),
        helperStyle: SongletType.footnote.copyWith(color: c.inkSecondary),
        counterStyle: SongletType.caption.copyWith(color: c.inkTertiary),
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
        linearMinHeight: SongletSize.progressHeight,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(c.canvas),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.accent
              : c.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent : c.hairline,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.canvas,
        modalBackgroundColor: c.canvas,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: SongletRadius.sheetTop,
        ),
        showDragHandle: true,
        dragHandleColor: c.inkTertiary,
        dragHandleSize: const Size(SongletSpace.x10, SongletSpace.x1 * 0.5),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: SongletRadius.cardAll,
          side: BorderSide(color: c.hairline),
        ),
        titleTextStyle: SongletType.title2.copyWith(color: c.ink),
        contentTextStyle: SongletType.subhead.copyWith(color: c.inkSecondary),
      ),
      // The one action is printed on the brand plate: vermilion stock with
      // cream lettering.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(c.accent),
          foregroundColor: WidgetStatePropertyAll(c.onAccent),
          elevation: const WidgetStatePropertyAll(0),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: SongletRadius.controlAll),
          ),
          textStyle: WidgetStatePropertyAll(
            SongletType.headline.copyWith(
              color: c.onAccent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, SongletSize.controlHeight),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.ink),
          side: WidgetStatePropertyAll(
            BorderSide(color: c.ink, width: SongletSize.rule),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: SongletRadius.controlAll),
          ),
          textStyle: WidgetStatePropertyAll(
            SongletType.headline.copyWith(color: c.ink),
          ),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, SongletSize.controlHeight),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.ink),
          textStyle: WidgetStatePropertyAll(
            SongletType.subhead.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceMuted,
        selectedColor: c.accentSoft,
        side: BorderSide(color: c.hairline),
        shape: const RoundedRectangleBorder(
          borderRadius: SongletRadius.controlAll,
        ),
        labelStyle: SongletType.footnote.copyWith(color: c.ink),
        secondaryLabelStyle: SongletType.footnote.copyWith(color: c.ink),
        showCheckmark: false,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.inkSecondary,
        textColor: c.ink,
        titleTextStyle: SongletType.body.copyWith(color: c.ink),
        subtitleTextStyle: SongletType.footnote.copyWith(
          color: c.inkSecondary,
        ),
        minVerticalPadding: SongletSpace.x3,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.ink,
          borderRadius: SongletRadius.thumbAll,
        ),
        textStyle: SongletType.caption.copyWith(color: c.canvas),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: SongletType.subhead.copyWith(color: c.canvas),
        shape: const RoundedRectangleBorder(
          borderRadius: SongletRadius.controlAll,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashColor: c.accent.withValues(alpha: 0.06),
      highlightColor: c.ink.withValues(alpha: 0.04),
    );
    // Button labels take their `textStyle` verbatim — Material does not merge
    // them with the text theme, so a style written in SongletType (no font
    // family) would fall back to the engine's default face. Complete them with
    // the resolved family once the theme exists.
    final family = theme.textTheme.bodyMedium ?? const TextStyle();
    TextStyle label(TextStyle style) => family.copyWith(
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      letterSpacing: style.letterSpacing,
      height: style.height,
    );
    return theme.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: (theme.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: WidgetStatePropertyAll(
            label(
              SongletType.headline.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: (theme.outlinedButtonTheme.style ?? const ButtonStyle())
            .copyWith(
              textStyle: WidgetStatePropertyAll(
                label(SongletType.headline),
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: (theme.textButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: WidgetStatePropertyAll(
            label(
              SongletType.subhead.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
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

  /// Legacy Aura theme (the template's unreleased screens).
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
