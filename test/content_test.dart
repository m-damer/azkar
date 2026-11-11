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
    expect(chapters.length, 133);
    expect(items.length, 285);
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

  test('more azkar is the Hisn al-Muslim list: 11 sections, 214 azkar', () {
    final s1 = content.sectionById('s1')!;
    expect(s1.title, 'المزيد من الأذكار والأدعية');
    final hisn = s1.categories.where((k) => k.id != 's1c0').toList();
    expect(hisn.length, 11);
    expect(
        hisn.map((k) => k.chapters.fold<int>(0, (n, b) => n + b.items.length)),
        [66, 8, 3, 31, 24, 10, 14, 22, 13, 7, 16]);
    expect(hisn.first.title,
        'أذكار الطهارة والوضوء والخلاء والمسجد والأذان والصلاة');
  });

  test('after-prayer tasbih: each phrase has its own page x33, surahs x3', () {
    final ch = content.chapterById('h054')!;
    final byText = {for (final i in ch.items) i.text: i};
    expect(byText['«سُبْحَانَ اللَّهِ»']!.repeat, 33);
    expect(byText['«الْحَمْدُ لِلَّهِ»']!.repeat, 33);
    expect(byText['«اللَّهُ أَكْبَرُ»']!.repeat, 33);
    final surahs = ch.items.where((i) => i.title != null).toList();
    expect(surahs.map((i) => i.title),
        ['سورة الإخلاص', 'سورة الفلق', 'سورة الناس']);
    expect(surahs.map((i) => i.repeat), [3, 3, 3]);
  });

  test('the Duas section is emptied for now', () {
    final s2 = content.sectionById('s2')!;
    expect(s2.title, 'من أدعية الرسول ﷺ');
    expect(s2.categories, isEmpty);
  });

  test('waking Al-Imran item has the requested virtue', () {
    final it = content.chapterById('b001')!.items
        .firstWhere((i) => i.quran == '3:190-200');
    expect(it.virtue, startsWith('سُنّة ثابتة عن النبي ﷺ عند الاستيقاظ من نوم الليل'));
    expect(it.mushaf!.map((r) => r.page), [75, 76]);
  });

  test('Quranic items carry mushaf glyphs and proper titles', () {
    final b = content.chapterById('b028')!;
    final byTitle = {
      for (final i in b.items.where((i) => i.quran != null)) i.title: i
    };
    expect(byTitle.keys.whereType<String>().toSet(), {
      'سورة الإخلاص', 'سورة الفلق', 'سورة الناس', 'آية الكرسي',
      'خواتيم سورة البقرة', 'سورة السجدة', 'سورة الملك',
    });
    expect(byTitle['سورة الملك']!.mushaf!.length, 3);
    expect(byTitle['سورة السجدة']!.mushaf!.length, 3);
    expect(byTitle['آية الكرسي']!.header, 'taawwudh');
    expect(byTitle['سورة الإخلاص']!.header, 'basmala');
    expect(b.items.length, 18);
  });

  test('lookups work', () {
    expect(content.chapterById('b027'), isNotNull);
    expect(content.sectionById('s1')!.categories.length, 12);
  });
}
