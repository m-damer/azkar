import 'dart:convert';
import 'dart:io';

import 'package:azkar/content/arabic.dart';
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
    expect(chapters.length, 133);
    expect(items.length, 303);
  });

  test('ids are unique', () {
    expect({for (final b in chapters) b.id}.length, chapters.length);
    expect({for (final i in items) i.id}.length, items.length);
  });

  test('every item has text and a takhrij or note', () {
    for (final i in items) {
      expect(i.text.trim(), isNotEmpty, reason: i.id);
      expect(
          (i.takhrij ?? i.note ?? '').trim(), isNotEmpty,
          reason: i.id);
    }
  });

  test('morning and evening are separate chapters', () {
    final m = content.chapterById('b027')!;
    final e = content.chapterById('b027e')!;
    expect(m.title, 'أذكار الصباح');
    expect(e.title, 'أذكار المساء');
    expect(m.items.any((i) => i.text.startsWith('أصبحنا')), isTrue);
    expect(e.items.any((i) => i.text.startsWith('أمسينا')), isTrue);
    expect(e.items.any((i) => i.text.contains('أصبحنا وأصبح')), isFalse);
  });

  test('each surah is its own page with a counter of 3', () {
    final b = content.chapterById('b028')!;
    final first = b.items.take(3).toList();
    expect(first.map((i) => i.repeat), [3, 3, 3]);
    expect(stripDiacritics(first[0].text), contains('الصمد'));
    expect(stripDiacritics(first[1].text), contains('الفلق'));
    expect(stripDiacritics(first[2].text), contains('الناس'));
    expect(first.any((i) => i.text.contains('ثلاث مرات')), isFalse);
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
