import 'package:flutter/material.dart';

import 'colors.dart';
import 'dimens.dart';
import 'typography.dart';

/// Builds Material themes from the design tokens. All raw values live in
/// lib/design; widgets read them via [AppColors] (Theme extension) and the
/// scale classes.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness b) {
    final scheme = ColorScheme(
      brightness: b,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accentWarm,
      onSecondary: c.onAccentWarm,
      error: c.danger,
      onError: c.onDanger,
      surface: c.surfaceBase,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.surfaceSunken,
      outline: c.borderStrong,
      outlineVariant: c.borderSubtle,
      scrim: c.scrim,
    );
    final text = TextTheme(
      displayLarge: AppType.displayXl,
      displayMedium: AppType.displayLg,
      displaySmall: AppType.displayMd,
      headlineLarge: AppType.titleLg,
      headlineMedium: AppType.titleMd,
      headlineSmall: AppType.titleSm,
      titleLarge: AppType.heading,
      titleMedium: AppType.label,
      bodyLarge: AppType.body,
      bodyMedium: AppType.body,
      bodySmall: AppType.caption,
      labelLarge: AppType.label,
      labelMedium: AppType.caption,
      labelSmall: AppType.caption,
    ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.surfaceBase,
      fontFamily: AppFonts.sans,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[c],
      dividerColor: c.borderSubtle,
      appBarTheme: AppBarTheme(
        backgroundColor: c.surfaceBase,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppType.titleSm.copyWith(color: c.textPrimary),
      ),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Pill radius used by every button and chip.
BorderRadius get pillRadius => BorderRadius.circular(AppRadius.full);
