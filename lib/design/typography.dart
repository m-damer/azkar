// GENERATED from docs/design-tokens.json — keep in sync with the design system.
import 'package:flutter/material.dart';

/// Font families bundled in assets/fonts.
abstract final class AppFonts {
  static const String sans = 'IBMPlexSansArabic';
  static const String dhikr = 'Amiri';
}

TextStyle _s(String family, double size, double line, FontWeight w) =>
    TextStyle(fontFamily: family, fontSize: size, height: line / size, fontWeight: w);

abstract final class AppType {
  /// Tap counter on the full-screen awrad counter.
  static final TextStyle displayXl = _s(AppFonts.sans, 64.0, 72.0, FontWeight.w700);
  /// Dhikr counter numeral, big streak number.
  static final TextStyle displayLg = _s(AppFonts.sans, 48.0, 56.0, FontWeight.w700);
  /// Onboarding headline, streak page figure.
  static final TextStyle displayMd = _s(AppFonts.sans, 40.0, 48.0, FontWeight.w700);
  /// Screen titles.
  static final TextStyle titleLg = _s(AppFonts.sans, 32.0, 40.0, FontWeight.w700);
  /// Greeting, tile headline.
  static final TextStyle titleMd = _s(AppFonts.sans, 28.0, 36.0, FontWeight.w700);
  /// Sheet titles, dialog titles.
  static final TextStyle titleSm = _s(AppFonts.sans, 24.0, 32.0, FontWeight.w700);
  /// Tile titles, section titles, large button labels.
  static final TextStyle heading = _s(AppFonts.sans, 20.0, 28.0, FontWeight.w700);
  /// Paragraphs: fadl and explanation text. Arabic needs 1.75 leading.
  static final TextStyle body = _s(AppFonts.sans, 16.0, 28.0, FontWeight.w400);
  /// Button labels, list-row titles, tab labels.
  static final TextStyle label = _s(AppFonts.sans, 16.0, 24.0, FontWeight.w700);
  /// Counts, helper text, metadata. Never for anything the user must read to act.
  static final TextStyle caption = _s(AppFonts.sans, 12.0, 20.0, FontWeight.w500);
  /// Smallest reader size (font-size setting: small).
  static final TextStyle dhikrSm = _s(AppFonts.dhikr, 28.0, 52.0, FontWeight.w700);
  /// Reader setting: medium.
  static final TextStyle dhikrMd = _s(AppFonts.dhikr, 32.0, 60.0, FontWeight.w700);
  /// Reader default.
  static final TextStyle dhikrLg = _s(AppFonts.dhikr, 40.0, 72.0, FontWeight.w700);
  /// Reader setting: large.
  static final TextStyle dhikrXl = _s(AppFonts.dhikr, 48.0, 88.0, FontWeight.w700);
}
