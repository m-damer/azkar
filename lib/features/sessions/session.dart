import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/colors.dart';
import '../../l10n/app_localizations.dart';

/// The four daily sessions shown on the home screen, in the order of the day.
enum SessionKind {
  wake('wake', 'b001', Icons.alarm),
  morning('morning', 'b027', Icons.wb_twilight),
  evening('evening', 'b027e', Icons.wb_sunny_outlined),
  sleep('sleep', 'b028', Icons.bedtime_outlined);

  const SessionKind(this.key, this.chapterId, this.icon);

  /// Route key.
  final String key;

  /// Chapter whose items the session reads.
  final String chapterId;
  final IconData icon;

  /// Sessions that have a daily reminder (waking up has none).
  static const reminderKinds = [morning, evening, sleep];

  static SessionKind? fromKey(String key) {
    for (final s in values) {
      if (s.key == key) return s;
    }
    return null;
  }

  String name(AppLocalizations t) => switch (this) {
        wake => t.sessionWake,
        morning => t.sessionMorning,
        evening => t.sessionEvening,
        sleep => t.sessionSleep,
      };

  String hint(AppLocalizations t) => switch (this) {
        wake => t.sessionWakeHint,
        morning => t.sessionMorningHint,
        evening => t.sessionEveningHint,
        sleep => t.sessionSleepHint,
      };

  String greeting(AppLocalizations t) => switch (this) {
        wake => t.greetWake,
        morning => t.greetMorning,
        evening => t.greetEvening,
        sleep => t.greetSleep,
      };

  Color background(AppColors c) => switch (this) {
        wake => c.tileWake,
        morning => c.tileMorning,
        evening => c.tileEvening,
        sleep => c.tileSleep,
      };

  Color foreground(AppColors c) => switch (this) {
        wake => c.onTileWake,
        morning => c.onTileMorning,
        evening => c.onTileEvening,
        sleep => c.onTileSleep,
      };

  /// The session that fits [now]: waking up 4:00–6:00, morning until 15:00,
  /// evening until 21:30, then sleep until 4:00.
  static SessionKind at(DateTime now) {
    final m = now.hour * 60 + now.minute;
    if (m >= 4 * 60 && m < 6 * 60) return wake;
    if (m >= 6 * 60 && m < 15 * 60) return morning;
    if (m >= 15 * 60 && m < 21 * 60 + 30) return evening;
    return sleep;
  }

  /// All sessions, starting from the current one and cycling.
  static List<SessionKind> cycleFrom(SessionKind first) {
    final i = values.indexOf(first);
    return [...values.sublist(i), ...values.sublist(0, i)];
  }
}

/// Injectable clock, overridden in tests.
final nowProvider = Provider<DateTime>((ref) => DateTime.now());
