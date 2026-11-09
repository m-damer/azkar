import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_provider.dart';
import 'models.dart';

/// Where an item lives: used to open favourites and list entries.
class ItemRef {
  const ItemRef(this.item, this.chapter, this.index);

  final Item item;
  final Chapter chapter;
  final int index;
}

final itemLocatorProvider = Provider<Map<String, ItemRef>>((ref) {
  final content = ref.watch(contentProvider).value;
  final out = <String, ItemRef>{};
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
