import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress.dart';

/// A user-made list of saved items.
class UserList {
  const UserList({
    required this.id,
    required this.name,
    required this.color,
    this.itemIds = const [],
  });

  factory UserList.fromJson(Map<String, dynamic> j) => UserList(
        id: j['id'] as String,
        name: j['name'] as String,
        color: (j['color'] as int?) ?? 0,
        itemIds: (j['items'] as List<dynamic>).cast<String>(),
      );

  final String id;
  final String name;

  /// Index into the list colour palette.
  final int color;
  final List<String> itemIds;

  UserList copyWith({String? name, int? color, List<String>? itemIds}) =>
      UserList(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        itemIds: itemIds ?? this.itemIds,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'color': color, 'items': itemIds};
}

class Library {
  const Library({this.favorites = const [], this.lists = const []});

  /// Item ids in the general favourites, newest first.
  final List<String> favorites;
  final List<UserList> lists;

  bool isSaved(String itemId) =>
      favorites.contains(itemId) || lists.any((l) => l.itemIds.contains(itemId));

  UserList? list(String id) {
    for (final l in lists) {
      if (l.id == id) return l;
    }
    return null;
  }
}

String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

class LibraryNotifier extends Notifier<Library> {
  @override
  Library build() {
    final p = ref.read(sharedPreferencesProvider);
    final raw = p.getString('lists');
    return Library(
      favorites: p.getStringList('favorites') ?? const [],
      lists: raw == null
          ? const []
          : [
              for (final j in jsonDecode(raw) as List<dynamic>)
                UserList.fromJson(j as Map<String, dynamic>),
            ],
    );
  }

  void _save(Library next) {
    final p = ref.read(sharedPreferencesProvider);
    p.setStringList('favorites', next.favorites);
    p.setString('lists', jsonEncode([for (final l in next.lists) l.toJson()]));
    state = next;
  }

  void setFavorite(String itemId, bool on) {
    final f = state.favorites.where((e) => e != itemId).toList();
    if (on) f.insert(0, itemId);
    _save(Library(favorites: f, lists: state.lists));
  }

  void setInList(String listId, String itemId, bool on) {
    _save(Library(favorites: state.favorites, lists: [
      for (final l in state.lists)
        if (l.id == listId)
          l.copyWith(
            itemIds: [
              ...l.itemIds.where((e) => e != itemId),
              if (on) itemId,
            ],
          )
        else
          l,
    ]));
  }

  void addToList(String listId, Iterable<String> ids) {
    _save(Library(favorites: state.favorites, lists: [
      for (final l in state.lists)
        if (l.id == listId)
          l.copyWith(itemIds: [
            ...l.itemIds,
            ...ids.where((e) => !l.itemIds.contains(e)),
          ])
        else
          l,
    ]));
  }

  String createList(String name, int color) {
    final id = newId();
    _save(Library(
      favorites: state.favorites,
      lists: [...state.lists, UserList(id: id, name: name.trim(), color: color)],
    ));
    return id;
  }

  void updateList(String id, {String? name, int? color}) {
    _save(Library(favorites: state.favorites, lists: [
      for (final l in state.lists)
        if (l.id == id) l.copyWith(name: name?.trim(), color: color) else l,
    ]));
  }

  void deleteList(String id) {
    _save(Library(
      favorites: state.favorites,
      lists: state.lists.where((l) => l.id != id).toList(),
    ));
  }
}

final libraryProvider =
    NotifierProvider<LibraryNotifier, Library>(LibraryNotifier.new);

/// A daily counter the user defines (e.g. 100 x istighfar).
class Wird {
  const Wird({required this.id, required this.name, required this.target});

  factory Wird.fromJson(Map<String, dynamic> j) => Wird(
        id: j['id'] as String,
        name: j['name'] as String,
        target: j['target'] as int,
      );

  final String id;
  final String name;
  final int target;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'target': target};
}

class AwradState {
  const AwradState({this.awrad = const [], this.counts = const {}});

  final List<Wird> awrad;

  /// Today's count per wird id.
  final Map<String, int> counts;

  int countOf(String id) => counts[id] ?? 0;

  Wird? byId(String id) {
    for (final w in awrad) {
      if (w.id == id) return w;
    }
    return null;
  }
}

class AwradNotifier extends Notifier<AwradState> {
  String get _day => 'awradCounts:${dayKey(ref.read(nowProvider))}';

  @override
  AwradState build() {
    final p = ref.read(sharedPreferencesProvider);
    final raw = p.getString('awrad');
    final rawCounts = p.getString(_day);
    return AwradState(
      awrad: raw == null
          ? const []
          : [
              for (final j in jsonDecode(raw) as List<dynamic>)
                Wird.fromJson(j as Map<String, dynamic>),
            ],
      counts: rawCounts == null
          ? const {}
          : (jsonDecode(rawCounts) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as int)),
    );
  }

  void _save(AwradState next) {
    final p = ref.read(sharedPreferencesProvider);
    p.setString('awrad', jsonEncode([for (final w in next.awrad) w.toJson()]));
    p.setString(_day, jsonEncode(next.counts));
    state = next;
  }

  String add(String name, int target) {
    final id = newId();
    _save(AwradState(
      awrad: [...state.awrad, Wird(id: id, name: name.trim(), target: target)],
      counts: state.counts,
    ));
    return id;
  }

  void edit(String id, String name, int target) {
    _save(AwradState(
      awrad: [
        for (final w in state.awrad)
          if (w.id == id) Wird(id: id, name: name.trim(), target: target) else w,
      ],
      counts: state.counts,
    ));
  }

  void delete(String id) {
    _save(AwradState(
      awrad: state.awrad.where((w) => w.id != id).toList(),
      counts: {...state.counts}..remove(id),
    ));
  }

  void setCount(String id, int value) {
    _save(AwradState(
      awrad: state.awrad,
      counts: {...state.counts, id: value < 0 ? 0 : value},
    ));
  }
}

final awradProvider =
    NotifierProvider<AwradNotifier, AwradState>(AwradNotifier.new);
