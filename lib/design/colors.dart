// GENERATED from docs/design-tokens.json — keep in sync with the design system.
import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.accentWarm,
    required this.onAccentWarm,
    required this.iconWarm,
    required this.tileMorning,
    required this.onTileMorning,
    required this.tileEvening,
    required this.onTileEvening,
    required this.tileWake,
    required this.onTileWake,
    required this.tileSleep,
    required this.onTileSleep,
    required this.tileDone,
    required this.onTileDone,
    required this.navActive,
    required this.onNavActive,
    required this.danger,
    required this.onDanger,
    required this.focusRing,
    required this.scrim,
  });

  final Color surfaceBase;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color onAccent;
  final Color accentWarm;
  final Color onAccentWarm;
  final Color iconWarm;
  final Color tileMorning;
  final Color onTileMorning;
  final Color tileEvening;
  final Color onTileEvening;
  final Color tileWake;
  final Color onTileWake;
  final Color tileSleep;
  final Color onTileSleep;
  final Color tileDone;
  final Color onTileDone;
  final Color navActive;
  final Color onNavActive;
  final Color danger;
  final Color onDanger;
  final Color focusRing;
  final Color scrim;

  static const light = AppColors(
    surfaceBase: Color(0xFFF4EDE0),
    surfaceRaised: Color(0xFFFBF7EE),
    surfaceSunken: Color(0xFFEFE5D0),
    borderSubtle: Color(0xFFD8CCB2),
    borderStrong: Color(0xFF8A7D5D),
    textPrimary: Color(0xFF2B2A24),
    textSecondary: Color(0xFF625B4B),
    accent: Color(0xFF5B6B3A),
    onAccent: Color(0xFFF6F0E4),
    accentWarm: Color(0xFFF2D2A9),
    onAccentWarm: Color(0xFF3B2A12),
    iconWarm: Color(0xFF8A4E2B),
    tileMorning: Color(0xFFF2D2A9),
    onTileMorning: Color(0xFF3B2A12),
    tileEvening: Color(0xFFE4D6B8),
    onTileEvening: Color(0xFF2B2A24),
    tileWake: Color(0xFFEBC4B0),
    onTileWake: Color(0xFF4A2414),
    tileSleep: Color(0xFF8A4524),
    onTileSleep: Color(0xFFFFF8EE),
    tileDone: Color(0xFF5B6B3A),
    onTileDone: Color(0xFFF6F0E4),
    navActive: Color(0xFF2B2A24),
    onNavActive: Color(0xFFF2D2A9),
    danger: Color(0xFF9A2F1B),
    onDanger: Color(0xFFFFF8EE),
    focusRing: Color(0xFF2B2A24),
    scrim: Color(0x802B2A24),
  );

  static const dark = AppColors(
    surfaceBase: Color(0xFF1E1C17),
    surfaceRaised: Color(0xFF2A2720),
    surfaceSunken: Color(0xFF38342A),
    borderSubtle: Color(0xFF4A4538),
    borderStrong: Color(0xFF8A8068),
    textPrimary: Color(0xFFEDE6D6),
    textSecondary: Color(0xFFB4AB97),
    accent: Color(0xFF9DB06B),
    onAccent: Color(0xFF16140F),
    accentWarm: Color(0xFFE3B77F),
    onAccentWarm: Color(0xFF2B1D0A),
    iconWarm: Color(0xFFE0925E),
    tileMorning: Color(0xFF8A6330),
    onTileMorning: Color(0xFFFFF3DF),
    tileEvening: Color(0xFF4A4130),
    onTileEvening: Color(0xFFEDE6D6),
    tileWake: Color(0xFF6E4A3A),
    onTileWake: Color(0xFFFFEFE4),
    tileSleep: Color(0xFFA2522B),
    onTileSleep: Color(0xFFFFF8EE),
    tileDone: Color(0xFF2F3A1D),
    onTileDone: Color(0xFFEEF2DF),
    navActive: Color(0xFFEDE6D6),
    onNavActive: Color(0xFF2B2A24),
    danger: Color(0xFFF0907A),
    onDanger: Color(0xFF2B1D0A),
    focusRing: Color(0xFFEDE6D6),
    scrim: Color(0x99000000),
  );

  @override
  AppColors copyWith({
    Color? surfaceBase,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? onAccent,
    Color? accentWarm,
    Color? onAccentWarm,
    Color? iconWarm,
    Color? tileMorning,
    Color? onTileMorning,
    Color? tileEvening,
    Color? onTileEvening,
    Color? tileWake,
    Color? onTileWake,
    Color? tileSleep,
    Color? onTileSleep,
    Color? tileDone,
    Color? onTileDone,
    Color? navActive,
    Color? onNavActive,
    Color? danger,
    Color? onDanger,
    Color? focusRing,
    Color? scrim,
  }) {
    return AppColors(
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentWarm: accentWarm ?? this.accentWarm,
      onAccentWarm: onAccentWarm ?? this.onAccentWarm,
      iconWarm: iconWarm ?? this.iconWarm,
      tileMorning: tileMorning ?? this.tileMorning,
      onTileMorning: onTileMorning ?? this.onTileMorning,
      tileEvening: tileEvening ?? this.tileEvening,
      onTileEvening: onTileEvening ?? this.onTileEvening,
      tileWake: tileWake ?? this.tileWake,
      onTileWake: onTileWake ?? this.onTileWake,
      tileSleep: tileSleep ?? this.tileSleep,
      onTileSleep: onTileSleep ?? this.onTileSleep,
      tileDone: tileDone ?? this.tileDone,
      onTileDone: onTileDone ?? this.onTileDone,
      navActive: navActive ?? this.navActive,
      onNavActive: onNavActive ?? this.onNavActive,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      focusRing: focusRing ?? this.focusRing,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!,
      onAccentWarm: Color.lerp(onAccentWarm, other.onAccentWarm, t)!,
      iconWarm: Color.lerp(iconWarm, other.iconWarm, t)!,
      tileMorning: Color.lerp(tileMorning, other.tileMorning, t)!,
      onTileMorning: Color.lerp(onTileMorning, other.onTileMorning, t)!,
      tileEvening: Color.lerp(tileEvening, other.tileEvening, t)!,
      onTileEvening: Color.lerp(onTileEvening, other.onTileEvening, t)!,
      tileWake: Color.lerp(tileWake, other.tileWake, t)!,
      onTileWake: Color.lerp(onTileWake, other.onTileWake, t)!,
      tileSleep: Color.lerp(tileSleep, other.tileSleep, t)!,
      onTileSleep: Color.lerp(onTileSleep, other.onTileSleep, t)!,
      tileDone: Color.lerp(tileDone, other.tileDone, t)!,
      onTileDone: Color.lerp(onTileDone, other.onTileDone, t)!,
      navActive: Color.lerp(navActive, other.navActive, t)!,
      onNavActive: Color.lerp(onNavActive, other.onNavActive, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}
