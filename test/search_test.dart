import 'dart:convert';
import 'dart:io';

import 'package:azkar/content/arabic.dart';
import 'package:azkar/content/models.dart';
import 'package:azkar/content/search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalisation ignores diacritics and letter variants', () {
    expect(normalizeQuery('السَّفَر'), normalizeQuery('السفر'));
    expect(normalizeQuery('أذكار'), normalizeQuery('اذكار'));
    expect(stripDiacritics('سُبْحَانَ'), 'سبحان');
  });

  test('highlight ranges point into the original text', () {
    final n = NormText('سُبْحَانَ اللهِ');
    final at = n.text.indexOf('الله');
    expect(at, greaterThanOrEqualTo(0));
    expect('سُبْحَانَ اللهِ'.substring(n.map[at]).startsWith('الله'), isTrue);
  });

  test('searching the real content returns grouped hits', () {
    final content = Content.fromJson(
      jsonDecode(File('content/content.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final idx = SearchIndex(content);
    expect(idx.size, greaterThan(200));
    final hits = idx.search('سبحان الله');
    expect(hits, isNotEmpty);
    expect(hits.first.ranges, isNotEmpty);
    expect(idx.search('zzzzqq'), isEmpty);
  });
}
