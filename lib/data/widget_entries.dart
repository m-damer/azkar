import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/arabic.dart';
import '../content/locator.dart';
import '../services/widget_service.dart';
import 'library.dart';
import 'progress.dart';

/// How long each azkar stays on the widget, in minutes, to choose from.
const List<int> widgetMinuteChoices = [1, 2, 3, 5, 10, 15, 30, 60];

/// A named list for the home-screen widget. During its time window the widget
/// shows the list's azkar one after another, [minutes] each, and starts over
/// until the window ends.
class WidgetList {
  const WidgetList({
    required this.id,
    required this.name,
    this.itemIds = const [],
    this.from = 6 * 60,
    this.to = 9 * 60,
    this.days = const [1, 2, 3, 4, 5, 6, 7],
    this.minutes = 5,
  });

  factory WidgetList.fromJson(Map<String, dynamic> j) => WidgetList(
        id: j['id'] as String,
        name: j['name'] as String,
        itemIds: (j['items'] as List<dynamic>).cast<String>(),
        from: j['from'] as int,
        to: j['to'] as int,
        days: (j['days'] as List<dynamic>).cast<int>(),
        minutes: (j['minutes'] as int?) ?? 5,
      );

  final String id;
  final String name;
  final List<String> itemIds;

  /// Minutes since midnight; a window may pass midnight (from > to).
  final int from;
  final int to;
  final List<int> days;
  final int minutes;

  WidgetList copyWith({
    String? name,
    List<String>? itemIds,
    int? from,
    int? to,
    List<int>? days,
    int? minutes,
  }) =>
      WidgetList(
        id: id,
        name: name ?? this.name,
        itemIds: itemIds ?? this.itemIds,
        from: from ?? this.from,
        to: to ?? this.to,
        days: days ?? this.days,
        minutes: minutes ?? this.minutes,
      );

  /// Length of the window in minutes.
  int get windowMinutes => (to - from + 1440) % 1440 == 0 ? 1440 : (to - from + 1440) % 1440;

  /// One full round through every azkar.
  int get cycleMinutes => itemIds.length * minutes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': itemIds,
        'from': from,
        'to': to,
        'days': days,
        'minutes': minutes,
      };
}

class WidgetListsNotifier extends Notifier<List<WidgetList>> {
  @override
  List<WidgetList> build() {
    final raw = ref.read(sharedPreferencesProvider).getString('widgetLists');
    if (raw == null) return const [];
    return [
      for (final j in jsonDecode(raw) as List<dynamic>)
        WidgetList.fromJson(j as Map<String, dynamic>),
    ];
  }

  void _save(List<WidgetList> next) {
    ref
        .read(sharedPreferencesProvider)
        .setString('widgetLists', jsonEncode([for (final l in next) l.toJson()]));
    state = next;
    sync();
  }

  /// Turns the old one-azkar-per-window entries into one-azkar lists. Needs the
  /// content, so it runs once the app has loaded it.
  void migrate() {
    final p = ref.read(sharedPreferencesProvider);
    final raw = p.getString('widgetEntries');
    if (raw == null) return;
    final loc = ref.read(itemLocatorProvider);
    final lists = <WidgetList>[...state];
    for (final j in jsonDecode(raw) as List<dynamic>) {
      final e = j as Map<String, dynamic>;
      final id = e['id'] as String;
      final r = loc[id];
      if (r == null) continue;
      var name = stripDiacritics(r.item.listLabel);
      if (name.length > 28) name = '${name.substring(0, 28)}…';
      lists.add(WidgetList(
        id: newId(),
        name: name,
        itemIds: [id],
        from: e['from'] as int,
        to: e['to'] as int,
        days: (e['days'] as List<dynamic>).cast<int>(),
      ));
    }
    p.remove('widgetEntries');
    _save(lists);
  }

  /// Sends the schedule (with readable text) to the native widget.
  void sync() {
    final loc = ref.read(itemLocatorProvider);
    ref.read(widgetServiceProvider).sync([
      for (final l in state)
        if (l.itemIds.any((id) => loc[id] != null))
          {
            'from': l.from,
            'to': l.to,
            'days': l.days,
            'minutes': l.minutes,
            'items': [
              for (final id in l.itemIds)
                if (loc[id] != null)
                  {
                    'title': loc[id]!.item.title ?? loc[id]!.chapter.title,
                    'text': loc[id]!.item.text,
                  },
            ],
          },
    ]);
  }

  String create(String name) {
    final id = newId();
    _save([...state, WidgetList(id: id, name: name.trim())]);
    return id;
  }

  void update(String id, WidgetList Function(WidgetList) f) =>
      _save([for (final l in state) l.id == id ? f(l) : l]);

  void rename(String id, String name) =>
      update(id, (l) => l.copyWith(name: name.trim()));

  void addItems(String id, Iterable<String> ids) => update(
      id, (l) => l.copyWith(itemIds: {...l.itemIds, ...ids}.toList()));

  void removeItem(String id, String itemId) => update(id,
      (l) => l.copyWith(itemIds: l.itemIds.where((e) => e != itemId).toList()));

  void delete(String id) => _save(state.where((l) => l.id != id).toList());
}

final widgetListsProvider =
    NotifierProvider<WidgetListsNotifier, List<WidgetList>>(
        WidgetListsNotifier.new);
