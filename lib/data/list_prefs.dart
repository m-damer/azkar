import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress.dart';

/// The user's own order and hidden items for each list of azkar.
///
/// A list is named by a key such as `session:morning`, `chapter:h001` or
/// `fav:<listId>`. Items are never removed from the content; hiding only skips
/// them when reading.
class ListPrefs {
  const ListPrefs({this.order = const {}, this.hidden = const {}});

  factory ListPrefs.fromJson(Map<String, dynamic> j) => ListPrefs(
        order: {
          for (final e in ((j['order'] as Map<String, dynamic>?) ?? {}).entries)
            e.key: (e.value as List<dynamic>).cast<String>(),
        },
        hidden: {
          for (final e
              in ((j['hidden'] as Map<String, dynamic>?) ?? {}).entries)
            e.key: (e.value as List<dynamic>).cast<String>().toSet(),
        },
      );

  final Map<String, List<String>> order;
  final Map<String, Set<String>> hidden;

  bool isHidden(String key, String id) => hidden[key]?.contains(id) ?? false;

  /// True when the user changed the order or hid something in [key].
  bool isCustom(String key) =>
      (order[key]?.isNotEmpty ?? false) || (hidden[key]?.isNotEmpty ?? false);

  /// [src] in the user's order (hidden items included). Items the order does
  /// not know about keep their place at the end.
  List<T> ordered<T>(String? key, List<T> src, String Function(T) id) {
    final saved = key == null ? null : order[key];
    if (saved == null || saved.isEmpty) return src;
    final byId = {for (final e in src) id(e): e};
    final out = <T>[
      for (final s in saved)
        if (byId.containsKey(s)) byId[s] as T,
    ];
    final seen = {for (final e in out) id(e)};
    out.addAll(src.where((e) => !seen.contains(id(e))));
    return out;
  }

  /// [src] in the user's order without the hidden items.
  List<T> visible<T>(String? key, List<T> src, String Function(T) id) {
    final all = ordered(key, src, id);
    if (key == null) return all;
    final h = hidden[key];
    if (h == null || h.isEmpty) return all;
    return all.where((e) => !h.contains(id(e))).toList();
  }

  Map<String, dynamic> toJson() => {
        'order': order,
        'hidden': {for (final e in hidden.entries) e.key: e.value.toList()},
      };
}

class ListPrefsNotifier extends Notifier<ListPrefs> {
  @override
  ListPrefs build() {
    final raw = ref.read(sharedPreferencesProvider).getString('listPrefs');
    if (raw == null) return const ListPrefs();
    try {
      return ListPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ListPrefs();
    }
  }

  void _save(ListPrefs next) {
    ref
        .read(sharedPreferencesProvider)
        .setString('listPrefs', jsonEncode(next.toJson()));
    state = next;
  }

  void setOrder(String key, List<String> ids) =>
      _save(ListPrefs(order: {...state.order, key: ids}, hidden: state.hidden));

  void setHidden(String key, String id, bool hide) {
    final set = {...(state.hidden[key] ?? <String>{})};
    hide ? set.add(id) : set.remove(id);
    _save(ListPrefs(order: state.order, hidden: {...state.hidden, key: set}));
  }

  /// Back to the content's own order with nothing hidden.
  void reset(String key) => _save(ListPrefs(
        order: {...state.order}..remove(key),
        hidden: {...state.hidden}..remove(key),
      ));

  /// Drops what is known about an item that was deleted from a list.
  void forget(String key, String id) {
    final o = state.order[key];
    _save(ListPrefs(
      order: o == null
          ? state.order
          : {...state.order, key: o.where((e) => e != id).toList()},
      hidden: {
        ...state.hidden,
        if (state.hidden[key] != null)
          key: state.hidden[key]!.where((e) => e != id).toSet(),
      },
    ));
  }
}

final listPrefsProvider =
    NotifierProvider<ListPrefsNotifier, ListPrefs>(ListPrefsNotifier.new);
