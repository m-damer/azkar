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
    expect(content.sections.length, 2);
    expect(chapters.length, 134);
    expect(items.length, 312);
  });

  test('ids are unique', () {
    expect({for (final b in chapters) b.id}.length, chapters.length);
    expect({for (final i in items) i.id}.length, items.length);
  });

  test('every item has text and a takhrij or note', () {
    for (final i in items) {
      expect(i.text.trim(), isNotEmpty, reason: i.id);
      expect(
          (i.takhrij ?? i.virtue ?? i.note ?? '').trim(), isNotEmpty,
          reason: i.id);
    }
  });

  test('morning and evening are separate chapters', () {
    final m = content.chapterById('b027')!;
    final e = content.chapterById('b027e')!;
    expect(m.title, 'أذكار الصباح');
    expect(e.title, 'أذكار المساء');
    expect(m.items.any((i) => i.title == 'ذِكر بداية الصباح'), isTrue);
    expect(e.items.any((i) => i.title == 'ذِكر بداية المساء'), isTrue);
    expect(e.items.any((i) => i.text.contains('أصبحنا وأصبح')), isFalse);
    expect(m.items.length, 23);
    expect(e.items.length, 21);
  });

  test('each surah is its own page with a counter of 3', () {
    final b = content.chapterById('b028')!;
    final first = b.items.take(3).toList();
    expect(first.map((i) => i.repeat), [3, 3, 3]);
    expect(first.map((i) => i.title),
        ['سورة الإخلاص', 'سورة الفلق', 'سورة الناس']);
    expect(first.any((i) => i.text.contains('ثلاث مرات')), isFalse);
  });

  test('الآداب الجامعة is the last category of the azkar section', () {
    expect(content.sections.length, 2);
    final last = content.sectionById('s1')!.categories.last;
    expect(last.title, 'من أنواع الخير والآداب الجامعة');
    expect(last.chapters.single.id, 'b132');
  });

  test('Quranic items carry mushaf glyphs and proper titles', () {
    final b = content.chapterById('b028')!;
    final byTitle = {for (final i in b.items) i.title: i};
    expect(byTitle.keys.whereType<String>().toSet(), {
      'سورة الإخلاص', 'سورة الفلق', 'سورة الناس', 'آية الكرسي',
      'خواتيم سورة البقرة', 'قراءة سورة السجدة', 'قراءة سورة الملك',
    });
    expect(byTitle['قراءة سورة الملك']!.mushaf!.length, 3);
    expect(byTitle['قراءة سورة السجدة']!.mushaf!.length, 3);
    expect(byTitle['آية الكرسي']!.header, 'taawwudh');
    expect(byTitle['سورة الإخلاص']!.header, 'basmala');
    expect(b.items.length, 18);
  });

  test('lookups work', () {
    expect(content.chapterById('b027'), isNotNull);
    expect(content.sectionById('s1')!.categories.length, 14);
  });
}
