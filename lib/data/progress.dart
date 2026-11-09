import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/sessions/session.dart';

/// Overridden in main() with the real instance (and in tests).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Number of consecutive active days ending today (or yesterday, so the
/// streak is not lost before the user has read today).
///
/// With [grace], a single missing day between two active days does not break
/// the streak (the missing day is not counted).
int computeStreak(Iterable<String> activeDays, DateTime today,
    {bool grace = false}) {
  final days = activeDays.toSet();
  var cursor = DateTime(today.year, today.month, today.day);
  if (!days.contains(dayKey(cursor))) {
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  var n = 0;
  while (true) {
    if (days.contains(dayKey(cursor))) {
      n++;
    } else {
      final before = DateTime(cursor.year, cursor.month, cursor.day - 1);
      if (!(grace && n > 0 && days.contains(dayKey(before)))) break;
    }
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return n;
}

/// Longest run of consecutive active days ever recorded.
int longestStreak(Iterable<String> activeDays) {
  final sorted = activeDays.toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? prev;
  for (final d in sorted) {
    final cur = DateTime.parse(d);
    if (prev != null &&
        DateTime(prev.year, prev.month, prev.day + 1) == cur) {
      run++;
    } else {
      run = 1;
    }
    if (run > best) best = run;
    prev = cur;
  }
  return best;
}

class Progress {
  const Progress({
    this.counts = const {},
    this.doneSessions = const {},
    this.activeDays = const {},
  });

  /// Today's counter value per item id.
  final Map<String, int> counts;

  /// Session keys completed today.
  final Set<String> doneSessions;

  /// Every day on which at least one session was completed.
  final Set<String> activeDays;

  int streak(DateTime today, {bool grace = false}) =>
      computeStreak(activeDays, today, grace: grace);
}

class ProgressNotifier extends Notifier<Progress> {
  static const _kDays = 'activeDays';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  String get _today => dayKey(ref.read(nowProvider));

  @override
  Progress build() {
    final today = _today;
    final counts = <String, int>{};
    final raw = _prefs.getString('counts:$today');
    if (raw != null) {
      (jsonDecode(raw) as Map<String, dynamic>)
          .forEach((k, v) => counts[k] = v as int);
    }
    return Progress(
      counts: counts,
      doneSessions: (_prefs.getStringList('done:$today') ?? const []).toSet(),
      activeDays: (_prefs.getStringList(_kDays) ?? const []).toSet(),
    );
  }

  void setCount(String itemId, int value) {
    final counts = {...state.counts, itemId: value};
    _prefs.setString('counts:$_today', jsonEncode(counts));
    state = Progress(
      counts: counts,
      doneSessions: state.doneSessions,
      activeDays: state.activeDays,
    );
  }

  /// Clears today's counts of one session so it can be read again.
  void resetSession(String key) {
    final counts = {...state.counts}..removeWhere((k, _) => k.startsWith('$key:'));
    _prefs.setString('counts:$_today', jsonEncode(counts));
    state = Progress(
      counts: counts,
      doneSessions: state.doneSessions,
      activeDays: state.activeDays,
    );
  }

  void completeSession(String key) {
    if (state.doneSessions.contains(key)) return;
    final done = {...state.doneSessions, key};
    // A day counts toward the streak once morning and evening are both done.
    final both = done.contains(SessionKind.morning.key) &&
        done.contains(SessionKind.evening.key);
    final days = both ? {...state.activeDays, _today} : state.activeDays;
    _prefs.setStringList('done:$_today', done.toList());
    if (both) _prefs.setStringList(_kDays, days.toList());
    state = Progress(
      counts: state.counts,
      doneSessions: done,
      activeDays: days,
    );
  }
}

final progressProvider =
    NotifierProvider<ProgressNotifier, Progress>(ProgressNotifier.new);

/// Recent search queries, newest first.
class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() =>
      ref.read(sharedPreferencesProvider).getStringList('recents') ??
      const [];

  void add(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    state = [t, ...state.where((e) => e != t)].take(8).toList();
    ref.read(sharedPreferencesProvider).setStringList('recents', state);
  }

  void clear() {
    state = const [];
    ref.read(sharedPreferencesProvider).remove('recents');
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
        RecentSearchesNotifier.new);
