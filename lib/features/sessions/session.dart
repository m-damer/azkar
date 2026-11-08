import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/colors.dart';
import '../../l10n/app_localizations.dart';

/// The three daily sessions shown on the home screen.
enum SessionKind {
  morning('morning', 'b027', Icons.wb_twilight),
  evening('evening', 'b027', Icons.wb_sunny_outlined),
  sleep('sleep', 'b028', Icons.bedtime_outlined);

  const SessionKind(this.key, this.chapterId, this.icon);

  /// Route key.
  final String key;

  /// Chapter whose items the session reads.
  final String chapterId;
  final IconData icon;

  static SessionKind? fromKey(String key) {
    for (final s in values) {
      if (s.key == key) return s;
    }
    return null;
  }

  String name(AppLocalizations t) => switch (this) {
        morning => t.sessionMorning,
        evening => t.sessionEvening,
        sleep => t.sessionSleep,
      };

  String hint(AppLocalizations t) => switch (this) {
        morning => t.sessionMorningHint,
        evening => t.sessionEveningHint,
        sleep => t.sessionSleepHint,
      };

  String greeting(AppLocalizations t) => switch (this) {
        morning => t.greetMorning,
        evening => t.greetEvening,
        sleep => t.greetSleep,
      };

  Color background(AppColors c) => switch (this) {
        morning => c.tileMorning,
        evening => c.tileEvening,
        sleep => c.tileSleep,
      };

  Color foreground(AppColors c) => switch (this) {
        morning => c.onTileMorning,
        evening => c.onTileEvening,
        sleep => c.onTileSleep,
      };

  /// The session that fits [now]: morning until mid-afternoon, evening until
  /// night, then sleep.
  static SessionKind at(DateTime now) {
    final h = now.hour;
    if (h >= 4 && h < 15) return morning;
    if (h >= 15 && h < 20) return evening;
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
