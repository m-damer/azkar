import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:azkar/design/colors.dart';
import 'package:flutter_test/flutter_test.dart';

/// Raw design values are allowed only in lib/design (the tokens). Anywhere
/// else they fail this test.
final _banned = <String, RegExp>{
  'raw colour': RegExp(r'Color\(\s*0x|Colors\.|Color\.fromARGB|Color\.fromRGBO'),
  'raw font weight': RegExp(r'FontWeight\.'),
  'raw font size': RegExp(r'fontSize\s*:'),
  'raw font family': RegExp(r'fontFamily\s*:'),
  'raw padding': RegExp(r'EdgeInsets\.\w+\(\s*-?\d'),
  'raw gap': RegExp(r'SizedBox\(\s*(width|height)\s*:\s*\d'),
  'raw radius': RegExp(r'BorderRadius\.circular\(\s*\d'),
  'raw duration': RegExp(r'Duration\('),
};

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  test('no raw design values outside lib/design', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final p = f.path.replaceAll('\\', '/');
      if (p.startsWith('lib/design/') || p.startsWith('lib/l10n/')) continue;
      final lines = f.readAsLinesSync();
      for (var n = 0; n < lines.length; n++) {
        _banned.forEach((name, re) {
          if (re.hasMatch(lines[n])) offenders.add('$p:${n + 1} $name');
        });
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  group('contrast >= 4.5', () {
    final pairs = <String, List<Color> Function(AppColors)>{
      'text on base': (c) => [c.textPrimary, c.surfaceBase],
      'text on raised': (c) => [c.textPrimary, c.surfaceRaised],
      'secondary on base': (c) => [c.textSecondary, c.surfaceBase],
      'secondary on raised': (c) => [c.textSecondary, c.surfaceRaised],
      'on-accent': (c) => [c.onAccent, c.accent],
      'on-accent-warm': (c) => [c.onAccentWarm, c.accentWarm],
      'morning tile': (c) => [c.onTileMorning, c.tileMorning],
      'evening tile': (c) => [c.onTileEvening, c.tileEvening],
      'wake tile': (c) => [c.onTileWake, c.tileWake],
      'sleep tile': (c) => [c.onTileSleep, c.tileSleep],
      'done tile': (c) => [c.onTileDone, c.tileDone],
      'nav active': (c) => [c.onNavActive, c.navActive],
      'on-danger': (c) => [c.onDanger, c.danger],
      'danger on base': (c) => [c.danger, c.surfaceBase],
    };
    for (final theme in {'light': AppColors.light, 'dark': AppColors.dark}.entries) {
      pairs.forEach((name, pick) {
        test('${theme.key}: $name', () {
          final p = pick(theme.value);
          expect(_contrast(p[0], p[1]), greaterThanOrEqualTo(4.5));
        });
      });
    }
  });
}
