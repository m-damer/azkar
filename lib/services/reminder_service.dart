import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/reminders.dart';
import '../features/sessions/session.dart';
import '../l10n/app_localizations.dart';

/// Daily local reminders for the three sessions.
abstract class ReminderService {
  /// Asks the user for the notification permission; true when granted.
  Future<bool> requestPermission();

  /// Whether notifications are currently allowed for the app.
  Future<bool> notificationsEnabled();

  /// (Re)schedules the three daily reminders.
  Future<void> schedule(ReminderTimes times);
}

class LocalReminderService implements ReminderService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> requestPermission() async {
    try {
      await _init();
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (e) {
      debugPrint('requestPermission failed: $e');
      return false;
    }
  }

  @override
  Future<bool> notificationsEnabled() async {
    try {
      await _init();
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (e) {
      debugPrint('notificationsEnabled failed: $e');
      return false;
    }
  }

  @override
  Future<void> schedule(ReminderTimes times) async {
    try {
      await _init();
      final t = lookupAppLocalizations(const Locale('ar'));
      final now = DateTime.now();
      for (final k in SessionKind.reminderKinds) {
        final id = SessionKind.reminderKinds.indexOf(k) + 1;
        final at = times.of(k);
        var next = DateTime(now.year, now.month, now.day, at.hour, at.minute);
        if (!next.isAfter(now)) {
          next = DateTime(now.year, now.month, now.day + 1, at.hour, at.minute);
        }
        await _plugin.cancel(id);
        await _plugin.zonedSchedule(
          id,
          k.name(t),
          t.reminderBody(k.name(t)),
          tz.TZDateTime.from(next, tz.UTC),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'azkar_reminders',
              t.reminderChannel,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (e) {
      debugPrint('schedule failed: $e');
    }
  }
}

final reminderServiceProvider =
    Provider<ReminderService>((ref) => LocalReminderService());

/// Whether the app may post notifications (refreshed with `ref.invalidate`).
final notificationsEnabledProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(reminderServiceProvider).notificationsEnabled(),
);
