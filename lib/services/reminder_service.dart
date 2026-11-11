import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/library.dart';
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

  /// (Re)schedules the reminders of the user's awrad.
  Future<void> scheduleAwrad(List<Wird> awrad);

  /// Routes of notifications the user taps while the app is running.
  Stream<String> get taps;

  /// The route of the notification that launched the app, if any.
  Future<String?> launchRoute();
}

class LocalReminderService implements ReminderService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  final StreamController<String> _taps = StreamController<String>.broadcast();

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<String?> launchRoute() async {
    try {
      await _init();
      final d = await _plugin.getNotificationAppLaunchDetails();
      if (d?.didNotificationLaunchApp ?? false) {
        return d?.notificationResponse?.payload;
      }
    } catch (e) {
      debugPrint('launchRoute failed: $e');
    }
    return null;
  }

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) {
        final p = r.payload;
        if (p != null && p.isNotEmpty) _taps.add(p);
      },
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
          payload: '/session/${k.key}',
        );
      }
    } catch (e) {
      debugPrint('schedule failed: $e');
    }
  }

  static const _awradBase = 1000;

  @override
  Future<void> scheduleAwrad(List<Wird> awrad) async {
    try {
      await _init();
      for (final p in await _plugin.pendingNotificationRequests()) {
        if (p.id >= _awradBase) await _plugin.cancel(p.id);
      }
      final t = lookupAppLocalizations(const Locale('ar'));
      final now = DateTime.now();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'azkar_awrad',
          t.wirdChannel,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      for (final w in awrad) {
        final r = w.reminder;
        if (r == null) continue;
        final base = _awradBase + (w.id.hashCode.abs() % 100000) * 8;
        if (r.once) {
          final d = r.onceDate;
          if (d == null) continue;
          final at = DateTime(d.year, d.month, d.day, r.hour, r.minute);
          if (!at.isAfter(now)) continue;
          await _plugin.zonedSchedule(
            base,
            w.name,
            t.wirdReminderBody,
            tz.TZDateTime.from(at, tz.UTC),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: '/awrad/${w.id}',
          );
          continue;
        }
        var k = 1;
        for (final day in r.days) {
          var at = DateTime(now.year, now.month, now.day, r.hour, r.minute);
          while (at.weekday != day || !at.isAfter(now)) {
            at = DateTime(at.year, at.month, at.day + 1, r.hour, r.minute);
          }
          await _plugin.zonedSchedule(
            base + k++,
            w.name,
            t.wirdReminderBody,
            tz.TZDateTime.from(at, tz.UTC),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: '/awrad/${w.id}',
          );
        }
      }
    } catch (e) {
      debugPrint('scheduleAwrad failed: $e');
    }
  }
}

final reminderServiceProvider =
    Provider<ReminderService>((ref) => LocalReminderService());

/// Whether the app may post notifications (refreshed with `ref.invalidate`).
final notificationsEnabledProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(reminderServiceProvider).notificationsEnabled(),
);
