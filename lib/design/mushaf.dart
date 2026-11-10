import 'package:flutter/material.dart';

/// Mushaf (QCF V2) glyph fonts: one font per Quran page, plus the font that
/// carries the ornamental basmala and ta'awwudh.
abstract final class MushafType {
  static const String _headerFamily = 'QCF2BSML';
  static const double _verseScale = 1.15;
  static const double _headerScale = 1.3;
  static const double _verseLine = 1.9;
  static const double _headerLine = 1.6;

  static const double gapScale = 0.25;

  /// Glyphs of «بسم الله الرحمن الرحيم», in reading order.
  static const List<String> basmala = ['*', '+', ',', '-'];

  /// Glyphs of «أعوذ بالله من الشيطان الرجيم», in reading order.
  static const List<String> taawwudh = ['G', 'H', 'D', 'E', 'F'];

  static String familyOf(int page) => 'QCF2${page.toString().padLeft(3, '0')}';

  static TextStyle verse(int page, double base, Color color) => TextStyle(
        fontFamily: familyOf(page),
        fontSize: base * _verseScale,
        height: _verseLine,
        color: color,
      );

  static TextStyle header(double base, Color color) => TextStyle(
        fontFamily: _headerFamily,
        fontSize: base * _headerScale,
        height: _headerLine,
        color: color,
      );

  /// Space between header words, relative to the base size.
  static double headerGap(double base) => base * gapScale;
}
