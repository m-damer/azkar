class Item {
  const Item({
    required this.id,
    required this.text,
    required this.source,
    required this.kind,
    this.repeat,
  });

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as String,
        text: j['text'] as String,
        source: (j['source'] as String?) ?? '',
        kind: (j['kind'] as String?) ?? 'text',
        repeat: j['repeat'] as int?,
      );

  final String id;
  final String text;
  final String source;
  final String kind;
  final int? repeat;
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
