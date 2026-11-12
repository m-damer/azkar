import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/my_duas.dart';
import 'content_provider.dart';
import 'models.dart';

/// Where an item lives: used to open favourites and list entries.
class ItemRef {
  const ItemRef(this.item, this.chapter, this.index);

  final Item item;
  final Chapter chapter;
  final int index;
}

/// The pseudo-chapter that holds the user's own duas.
const String myDuasChapterId = 'mine';

final itemLocatorProvider = Provider<Map<String, ItemRef>>((ref) {
  final content = ref.watch(contentProvider).value;
  final out = <String, ItemRef>{};
  final mine = ref.watch(myDuasProvider).duas;
  if (mine.isNotEmpty) {
    final chapter = Chapter(
      id: myDuasChapterId,
      bookNo: 0,
      title: 'أدعيتي',
      items: [
        for (final d in mine)
          Item(id: d.id, text: d.text, source: '', kind: 'text', title: d.name),
      ],
    );
    for (var i = 0; i < chapter.items.length; i++) {
      out[chapter.items[i].id] = ItemRef(chapter.items[i], chapter, i);
    }
  }
  if (content == null) return out;
  for (final s in content.sections) {
    for (final c in s.categories) {
      for (final b in c.chapters) {
        for (var i = 0; i < b.items.length; i++) {
          out[b.items[i].id] = ItemRef(b.items[i], b, i);
        }
      }
    }
  }
  return out;
});
