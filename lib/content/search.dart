import 'arabic.dart';
import 'models.dart';

class SearchHit {
  const SearchHit({
    required this.item,
    required this.chapter,
    required this.category,
    required this.section,
    required this.index,
    required this.ranges,
  });

  final Item item;
  final Chapter chapter;
  final Category category;
  final Section section;

  /// Position of the item inside its chapter.
  final int index;

  /// Matched character ranges (start, end) in `item.text`.
  final List<(int, int)> ranges;
}

class _Entry {
  _Entry(this.item, this.chapter, this.category, this.section, this.index)
      : text = NormText(item.text),
        extra = NormText('${chapter.title} ${category.title}').text;

  final Item item;
  final Chapter chapter;
  final Category category;
  final Section section;
  final int index;
  final NormText text;
  final String extra;
}

/// In-memory full-text index over every item.
class SearchIndex {
  SearchIndex(Content content) {
    for (final s in content.sections) {
      for (final c in s.categories) {
        for (final b in c.chapters) {
          for (var i = 0; i < b.items.length; i++) {
            _entries.add(_Entry(b.items[i], b, c, s, i));
          }
        }
      }
    }
  }

  final List<_Entry> _entries = [];

  int get size => _entries.length;

  /// Every word of the query must appear in the item text or in its chapter /
  /// category title. Text matches come first.
  List<SearchHit> search(String query) {
    final q = normalizeQuery(query);
    if (q.isEmpty) return const [];
    final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final inText = <SearchHit>[];
    final inTitle = <SearchHit>[];
    for (final e in _entries) {
      var allInText = true;
      var all = true;
      for (final w in words) {
        final t = e.text.text.contains(w);
        if (!t) allInText = false;
        if (!t && !e.extra.contains(w)) {
          all = false;
          break;
        }
      }
      if (!all) continue;
      final ranges = <(int, int)>[];
      for (final w in words) {
        var from = 0;
        while (true) {
          final at = e.text.text.indexOf(w, from);
          if (at < 0) break;
          final start = e.text.map[at];
          final endNorm = at + w.length - 1;
          final end = e.text.map[endNorm] + 1;
          ranges.add((start, end));
          from = at + w.length;
        }
      }
      ranges.sort((a, b) => a.$1.compareTo(b.$1));
      final hit = SearchHit(
        item: e.item,
        chapter: e.chapter,
        category: e.category,
        section: e.section,
        index: e.index,
        ranges: ranges,
      );
      (allInText ? inText : inTitle).add(hit);
    }
    return [...inText, ...inTitle];
  }
}
