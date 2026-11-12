import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'library.dart';
import 'progress.dart';

/// A named group of existing awrad. Deleting a list never deletes a wird.
class WirdList {
  const WirdList({required this.id, required this.name, this.wirdIds = const []});

  factory WirdList.fromJson(Map<String, dynamic> j) => WirdList(
        id: j['id'] as String,
        name: j['name'] as String,
        wirdIds: (j['wirdIds'] as List<dynamic>? ?? const []).cast<String>(),
      );

  final String id;
  final String name;
  final List<String> wirdIds;

  WirdList copyWith({String? name, List<String>? wirdIds}) =>
      WirdList(id: id, name: name ?? this.name, wirdIds: wirdIds ?? this.wirdIds);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'wirdIds': wirdIds};
}

class WirdListsNotifier extends Notifier<List<WirdList>> {
  static const _key = 'wirdLists';

  @override
  List<WirdList> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return [
        for (final l in jsonDecode(raw) as List<dynamic>)
          WirdList.fromJson(l as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  void _save(List<WirdList> next) {
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode([for (final l in next) l.toJson()]));
    state = next;
  }

  WirdList? byId(String id) {
    for (final l in state) {
      if (l.id == id) return l;
    }
    return null;
  }

  String create(String name) {
    final id = newId();
    _save([...state, WirdList(id: id, name: name.trim())]);
    return id;
  }

  void rename(String id, String name) => _save([
        for (final l in state) l.id == id ? l.copyWith(name: name.trim()) : l
      ]);

  void addWirds(String id, Iterable<String> wirdIds) => _save([
        for (final l in state)
          l.id == id
              ? l.copyWith(wirdIds: [...{...l.wirdIds, ...wirdIds}])
              : l
      ]);

  void removeWird(String id, String wirdId) => _save([
        for (final l in state)
          l.id == id
              ? l.copyWith(wirdIds: [
                  for (final w in l.wirdIds) if (w != wirdId) w
                ])
              : l
      ]);

  void reorder(String id, List<String> order) => _save([
        for (final l in state) l.id == id ? l.copyWith(wirdIds: order) : l
      ]);

  void delete(String id) => _save([for (final l in state) if (l.id != id) l]);

  /// Drops a deleted wird from every list.
  void forgetWird(String wirdId) => _save([
        for (final l in state)
          l.copyWith(wirdIds: [
            for (final w in l.wirdIds) if (w != wirdId) w
          ])
      ]);
}

final wirdListsProvider =
    NotifierProvider<WirdListsNotifier, List<WirdList>>(WirdListsNotifier.new);
