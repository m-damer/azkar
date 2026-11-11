import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/locator.dart';
import '../services/widget_service.dart';
import 'progress.dart';

/// One azkar shown by the home-screen widget during a time window.
class WidgetEntry {
  const WidgetEntry({
    required this.itemId,
    this.from = 6 * 60,
    this.to = 9 * 60,
    this.days = const [1, 2, 3, 4, 5, 6, 7],
  });

  factory WidgetEntry.fromJson(Map<String, dynamic> j) => WidgetEntry(
        itemId: j['id'] as String,
        from: j['from'] as int,
        to: j['to'] as int,
        days: (j['days'] as List<dynamic>).cast<int>(),
      );

  final String itemId;

  /// Minutes since midnight; a window may pass midnight (from > to).
  final int from;
  final int to;
  final List<int> days;

  WidgetEntry copyWith({int? from, int? to, List<int>? days}) => WidgetEntry(
        itemId: itemId,
        from: from ?? this.from,
        to: to ?? this.to,
        days: days ?? this.days,
      );

  Map<String, dynamic> toJson() =>
      {'id': itemId, 'from': from, 'to': to, 'days': days};
}

class WidgetEntriesNotifier extends Notifier<List<WidgetEntry>> {
  @override
  List<WidgetEntry> build() {
    final raw = ref.read(sharedPreferencesProvider).getString('widgetEntries');
    if (raw == null) return const [];
    return [
      for (final j in jsonDecode(raw) as List<dynamic>)
        WidgetEntry.fromJson(j as Map<String, dynamic>),
    ];
  }

  void _save(List<WidgetEntry> next) {
    ref
        .read(sharedPreferencesProvider)
        .setString('widgetEntries', jsonEncode([for (final e in next) e.toJson()]));
    state = next;
    sync();
  }

  /// Sends the current schedule (with readable text) to the native widget.
  void sync() {
    final loc = ref.read(itemLocatorProvider);
    ref.read(widgetServiceProvider).sync([
      for (final e in state)
        if (loc[e.itemId] != null)
          {
            'title': loc[e.itemId]!.chapter.title,
            'text': loc[e.itemId]!.item.text,
            'from': e.from,
            'to': e.to,
            'days': e.days,
          },
    ]);
  }

  void add(Iterable<String> ids) {
    final have = state.map((e) => e.itemId).toSet();
    _save([...state, for (final id in ids) if (!have.contains(id)) WidgetEntry(itemId: id)]);
  }

  void update(String id, WidgetEntry e) =>
      _save([for (final x in state) if (x.itemId == id) e else x]);

  void remove(String id) => _save(state.where((e) => e.itemId != id).toList());
}

final widgetEntriesProvider =
    NotifierProvider<WidgetEntriesNotifier, List<WidgetEntry>>(
        WidgetEntriesNotifier.new);
