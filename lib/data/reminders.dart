import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/sessions/session.dart';
import '../l10n/numbers.dart';
import 'progress.dart';

/// Reminder time for each session.
class ReminderTimes {
  const ReminderTimes({
    this.morning = const TimeOfDay(hour: 6, minute: 0),
    this.evening = const TimeOfDay(hour: 17, minute: 0),
    this.sleep = const TimeOfDay(hour: 22, minute: 30),
  });

  final TimeOfDay morning;
  final TimeOfDay evening;
  final TimeOfDay sleep;

  TimeOfDay of(SessionKind k) => switch (k) {
        SessionKind.wake => morning,
        SessionKind.morning => morning,
        SessionKind.evening => evening,
        SessionKind.sleep => sleep,
      };

  ReminderTimes with_(SessionKind k, TimeOfDay t) => ReminderTimes(
        morning: k == SessionKind.morning ? t : morning,
        evening: k == SessionKind.evening ? t : evening,
        sleep: k == SessionKind.sleep ? t : sleep,
      );
}

/// "6:00 ص" style label.
String formatTime(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  return arDigits('$h:$m ${t.period == DayPeriod.am ? 'ص' : 'م'}');
}

class RemindersNotifier extends Notifier<ReminderTimes> {
  TimeOfDay _read(String key, TimeOfDay def) {
    final v = ref.read(sharedPreferencesProvider).getInt(key);
    return v == null ? def : TimeOfDay(hour: v ~/ 60, minute: v % 60);
  }

  @override
  ReminderTimes build() {
    const d = ReminderTimes();
    return ReminderTimes(
      morning: _read('remind:morning', d.morning),
      evening: _read('remind:evening', d.evening),
      sleep: _read('remind:sleep', d.sleep),
    );
  }

  void set(SessionKind k, TimeOfDay t) {
    ref
        .read(sharedPreferencesProvider)
        .setInt('remind:${k.key}', t.hour * 60 + t.minute);
    state = state.with_(k, t);
  }
}

final remindersProvider =
    NotifierProvider<RemindersNotifier, ReminderTimes>(RemindersNotifier.new);
