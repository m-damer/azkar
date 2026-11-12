import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'library.dart';
import 'progress.dart';

/// A dua the user wrote by hand: a name and its text.
class CustomDua {
  const CustomDua({required this.id, required this.name, required this.text});

  factory CustomDua.fromJson(Map<String, dynamic> j) => CustomDua(
      id: j['id'] as String, name: j['name'] as String, text: j['text'] as String);

  final String id;
  final String name;
  final String text;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'text': text};
}

/// «أدعيتي»: duas written by hand, those added straight to the page, and the
/// user's named lists. Lists and the page hold ids of built-in azkar or of the
/// user's own duas.
class MyDuas {
  const MyDuas({
    this.duas = const [],
    this.loose = const [],
    this.lists = const [],
  });

  factory MyDuas.fromJson(Map<String, dynamic> j) => MyDuas(
        duas: [
          for (final d in (j['duas'] as List<dynamic>? ?? const []))
            CustomDua.fromJson(d as Map<String, dynamic>),
        ],
        loose: (j['loose'] as List<dynamic>? ?? const []).cast<String>(),
        lists: [
          for (final l in (j['lists'] as List<dynamic>? ?? const []))
            UserList.fromJson(l as Map<String, dynamic>),
        ],
      );

  final List<CustomDua> duas;

  /// Ids added straight to the page, in the order they were added.
  final List<String> loose;
  final List<UserList> lists;

  CustomDua? dua(String id) {
    for (final d in duas) {
      if (d.id == id) return d;
    }
    return null;
  }

  UserList? list(String id) {
    for (final l in lists) {
      if (l.id == id) return l;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'duas': [for (final d in duas) d.toJson()],
        'loose': loose,
        'lists': [for (final l in lists) l.toJson()],
      };
}

/// Ids of the user's own duas start with this.
const String customDuaPrefix = 'u-';

class MyDuasNotifier extends Notifier<MyDuas> {
  @override
  MyDuas build() {
    final raw = ref.read(sharedPreferencesProvider).getString('myDuas');
    if (raw == null) return const MyDuas();
    try {
      return MyDuas.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const MyDuas();
    }
  }

  /// Saves, dropping the user's own duas that nothing refers to any more.
  void _save(MyDuas next) {
    final used = {...next.loose, for (final l in next.lists) ...l.itemIds};
    final kept = MyDuas(
      duas: [for (final d in next.duas) if (used.contains(d.id)) d],
      loose: next.loose,
      lists: next.lists,
    );
    ref
        .read(sharedPreferencesProvider)
        .setString('myDuas', jsonEncode(kept.toJson()));
    state = kept;
  }

  MyDuas _with({
    List<CustomDua>? duas,
    List<String>? loose,
    List<UserList>? lists,
  }) =>
      MyDuas(
        duas: duas ?? state.duas,
        loose: loose ?? state.loose,
        lists: lists ?? state.lists,
      );

  List<UserList> _mapList(String id, UserList Function(UserList) f) =>
      [for (final l in state.lists) l.id == id ? f(l) : l];

  /// Writes a new dua and puts it on the page, or in [listId] when given.
  String addCustom(String name, String text, {String? listId}) {
    final id = '$customDuaPrefix${newId()}';
    final dua = CustomDua(id: id, name: name.trim(), text: text.trim());
    final duas = [...state.duas, dua];
    if (listId == null) {
      _save(_with(duas: duas, loose: [...state.loose, id]));
    } else {
      _save(_with(
        duas: duas,
        lists: _mapList(listId, (l) => l.copyWith(itemIds: [...l.itemIds, id])),
      ));
    }
    return id;
  }

  void editCustom(String id, String name, String text) => _save(_with(
        duas: [
          for (final d in state.duas)
            d.id == id
                ? CustomDua(id: id, name: name.trim(), text: text.trim())
                : d,
        ],
      ));

  /// Adds built-in azkar (or own duas) to the page or to [listId].
  void addMany(Iterable<String> ids, {String? listId}) {
    if (listId == null) {
      _save(_with(loose: {...state.loose, ...ids}.toList()));
    } else {
      _save(_with(
        lists: _mapList(
            listId,
            (l) => l.copyWith(itemIds: {...l.itemIds, ...ids}.toList())),
      ));
    }
  }

  void remove(String id, {String? listId}) {
    if (listId == null) {
      _save(_with(loose: state.loose.where((e) => e != id).toList()));
    } else {
      _save(_with(
        lists: _mapList(listId,
            (l) => l.copyWith(itemIds: l.itemIds.where((e) => e != id).toList())),
      ));
    }
  }

  String createList(String name) {
    final id = newId();
    _save(_with(lists: [
      ...state.lists,
      UserList(id: id, name: name.trim(), color: 0),
    ]));
    return id;
  }

  void renameList(String id, String name) =>
      _save(_with(lists: _mapList(id, (l) => l.copyWith(name: name.trim()))));

  void deleteList(String id) =>
      _save(_with(lists: state.lists.where((l) => l.id != id).toList()));
}

final myDuasProvider =
    NotifierProvider<MyDuasNotifier, MyDuas>(MyDuasNotifier.new);
