import 'dart:convert';
import 'dart:io';

import 'package:azkar/content/models.dart';
import 'package:flutter_test/flutter_test.dart';

Content _load() {
  final raw = File('content/content.json').readAsStringSync();
  return Content.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

void main() {
  final content = _load();
  final chapters = [
    for (final s in content.sections)
      for (final c in s.categories) ...c.chapters,
  ];
  final items = [for (final b in chapters) ...b.items];

  test('content has the expected shape', () {
    expect(content.sections.length, 3);
    expect(chapters.length, 132);
    expect(items.length, 273);
  });

  test('ids are unique', () {
    expect({for (final b in chapters) b.id}.length, chapters.length);
    expect({for (final i in items) i.id}.length, items.length);
  });

  test('every item has text and a source', () {
    for (final i in items) {
      expect(i.text.trim(), isNotEmpty, reason: i.id);
      expect(i.source.trim(), isNotEmpty, reason: i.id);
    }
  });

  test('split fields keep the original source intact', () {
    final b = content.chapterById('b028')!;
    final kursi = b.items.firstWhere((i) => i.text.startsWith('{اللّهُ'));
    expect(kursi.virtue, isNotNull);
    expect(kursi.takhrij, contains('البخاري'));
  });

  test('الآداب الجامعة is its own third section', () {
    expect(content.sections[2].title, 'الآداب الجامعة');
    expect(content.sections[2].categories.single.chapters.single.id, 'b132');
  });

  test('lookups work', () {
    expect(content.chapterById('b027'), isNotNull);
    expect(content.sectionById('s1')!.categories.length, 12);
  });
}
