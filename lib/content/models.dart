/// A run of mushaf glyphs that all belong to one page font.
class MushafRun {
  const MushafRun(this.page, this.glyphs);

  factory MushafRun.fromJson(Map<String, dynamic> j) =>
      MushafRun(j['p'] as int, j['g'] as String);

  final int page;
  final String glyphs;
}

class Item {
  const Item({
    required this.id,
    required this.text,
    required this.source,
    required this.kind,
    this.repeat,
    this.repeatParts,
    this.intro,
    this.virtue,
    this.takhrij,
    this.note,
    this.title,
    this.quran,
    this.header,
    this.mushaf,
  });

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as String,
        text: j['text'] as String,
        source: (j['source'] as String?) ?? '',
        kind: (j['kind'] as String?) ?? 'text',
        repeat: j['repeat'] as int?,
        repeatParts: (j['repeatParts'] as List<dynamic>?)?.cast<int>(),
        intro: j['intro'] as String?,
        virtue: j['virtue'] as String?,
        takhrij: j['takhrij'] as String?,
        note: j['note'] as String?,
        title: j['title'] as String?,
        quran: j['quran'] as String?,
        header: j['header'] as String?,
        mushaf: (j['mushaf'] as List<dynamic>?)
            ?.map((r) => MushafRun.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  final String id;
  final String text;
  final String source;
  final String kind;
  final int? repeat;

  /// Per-phrase counts for compound items such as 33 / 33 / 34.
  final List<int>? repeatParts;

  /// Small texts shown under the dhikr, in this order when present.
  final String? intro;
  final String? virtue;
  final String? takhrij;
  final String? note;

  /// Quranic items: the proper title shown in lists (e.g. «سورة الإخلاص»).
  final String? title;

  /// Quranic items: verse key or range ("112", "2:255", "2:285-286").
  final String? quran;

  /// Line written above the verses: 'basmala' or 'taawwudh'.
  final String? header;

  /// Quranic items: the verses as mushaf glyphs, one run per page font.
  final List<MushafRun>? mushaf;

  /// What the list shows for this item.
  String get listLabel => title ?? text;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.bookNo,
    required this.title,
    required this.items,
  });

  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
        id: j['id'] as String,
        bookNo: (j['bookNo'] as int?) ?? 0,
        title: j['title'] as String,
        items: [
          for (final i in j['items'] as List<dynamic>)
            Item.fromJson(i as Map<String, dynamic>),
        ],
      );

  final String id;
  final int bookNo;
  final String title;
  final List<Item> items;
}

class Category {
  const Category({
    required this.id,
    required this.title,
    required this.chapters,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        title: j['title'] as String,
        chapters: [
          for (final c in j['chapters'] as List<dynamic>)
            Chapter.fromJson(c as Map<String, dynamic>),
        ],
      );

  final String id;
  final String title;
  final List<Chapter> chapters;

  int get itemCount => chapters.fold(0, (n, c) => n + c.items.length);
}

class Section {
  const Section({
    required this.id,
    required this.title,
    required this.categories,
    required this.isAppendix,
  });

  factory Section.fromJson(Map<String, dynamic> j) => Section(
        id: j['id'] as String,
        title: j['title'] as String,
        isAppendix: (j['appendix'] as bool?) ?? false,
        categories: [
          for (final c in j['categories'] as List<dynamic>)
            Category.fromJson(c as Map<String, dynamic>),
        ],
      );

  final String id;
  final String title;
  final bool isAppendix;
  final List<Category> categories;

  int get itemCount => categories.fold(0, (n, c) => n + c.itemCount);
}

class Content {
  const Content(this.sections);

  factory Content.fromJson(Map<String, dynamic> j) => Content([
        for (final s in j['sections'] as List<dynamic>)
          Section.fromJson(s as Map<String, dynamic>),
      ]);

  final List<Section> sections;

  Category? categoryById(String id) {
    for (final s in sections) {
      for (final c in s.categories) {
        if (c.id == id) return c;
      }
    }
    return null;
  }

  Chapter? chapterById(String id) {
    for (final s in sections) {
      for (final c in s.categories) {
        for (final b in c.chapters) {
          if (b.id == id) return b;
        }
      }
    }
    return null;
  }

  Section? sectionById(String id) {
    for (final s in sections) {
      if (s.id == id) return s;
    }
    return null;
  }
}
