import 'dart:convert';
import 'dart:io';

import 'package:azkar/app.dart';
import 'package:azkar/content/content_provider.dart';
import 'package:azkar/content/models.dart';
import 'package:azkar/data/progress.dart';
import 'package:azkar/data/reminders.dart';
import 'package:azkar/features/sessions/session.dart';
import 'package:azkar/services/reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReminders implements ReminderService {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> notificationsEnabled() async => true;

  @override
  Future<void> schedule(ReminderTimes times) async {}
}

Future<Content> _pump(WidgetTester tester,
    {DateTime? now, Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true, ...prefs});
  final sp = await SharedPreferences.getInstance();
  final content = Content.fromJson(
    jsonDecode(File('content/content.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        reminderServiceProvider.overrideWithValue(_FakeReminders()),
        contentProvider.overrideWith((ref) async => content),
        nowProvider.overrideWithValue(now ?? DateTime(2026, 11, 8, 8)),
      ],
      child: const AzkarApp(),
    ),
  );
  await tester.pumpAndSettle();
  return content;
}

void main() {
  testWidgets('home shows the sessions, the three section links and the nav',
      (tester) async {
    await _pump(tester);
    expect(find.text('صباح الخير'), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('أذكار المساء'), findsOneWidget);
    expect(find.text('أذكار النوم'), findsOneWidget);
    expect(find.text('المزيد من الأذكار'), findsOneWidget);
    expect(find.text('الأدعية'), findsOneWidget);
    expect(find.text('الآداب الجامعة'), findsOneWidget);
    for (final label in ['اليوم', 'التذكيرات', 'الإعدادات']) {
      expect(find.text(label), findsOneWidget);
    }
    // The awrad tile and the awrad tab.
    expect(find.text('أوراد'), findsNWidgets(2));
  });

  testWidgets('home shows the streak and a completed session', (tester) async {
    await _pump(tester, prefs: {
      'activeDays': ['2026-11-07', '2026-11-08'],
      'done:2026-11-08': ['morning'],
    });
    expect(find.text('سلسلتك 2 يوم'), findsOneWidget);
    expect(find.text('اكتمل'), findsOneWidget);
  });

  testWidgets('the hero follows the time of day', (tester) async {
    await _pump(tester, now: DateTime(2026, 11, 8, 22));
    expect(find.text('ليلة هانئة'), findsOneWidget);
  });

  testWidgets('a section lists categories and opens the reader',
      (tester) async {
    final content = await _pump(tester);
    await tester.tap(find.text('الأدعية'));
    await tester.pumpAndSettle();
    final first = content.sectionById('s2')!.categories.first.chapters.first;
    await tester.tap(find.text(first.title));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('the adab section opens without category chips', (tester) async {
    await _pump(tester);
    await tester.scrollUntilVisible(find.text('الآداب الجامعة'), 100);
    await tester.tap(find.text('الآداب الجامعة'));
    await tester.pumpAndSettle();
    expect(find.text('من أنواع الخير والآداب الجامعة'), findsWidgets);
  });

  Future<void> openSleep(WidgetTester tester) async {
    await _pump(tester);
    await tester.tap(find.text('أذكار النوم'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 17'), findsOneWidget);
  }

  testWidgets('reader: the counter counts', (tester) async {
    await openSleep(tester);
    await tester.tap(find.text('اضغط للعدّ'));
    await tester.pump();
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('reader: auto-advance moves on when the counter finishes',
      (tester) async {
    await openSleep(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('اضغط للعدّ'));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('2 / 17'), findsOneWidget);
  });

  testWidgets('reader: auto-advance can be switched off', (tester) async {
    await _pump(tester, prefs: {'autoAdvance': false});
    await tester.tap(find.text('أذكار النوم'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('اضغط للعدّ'));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('1 / 17'), findsOneWidget);
  });

  testWidgets('reader: swipe right goes to the next item (RTL)',
      (tester) async {
    await openSleep(tester);
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 17'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 17'), findsOneWidget);
  });

  testWidgets('reader: next and previous buttons', (tester) async {
    await openSleep(tester);
    await tester.tap(find.byTooltip('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 17'), findsOneWidget);
    await tester.tap(find.byTooltip('السابق'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 17'), findsOneWidget);
  });

  testWidgets('reader: a count survives leaving and reopening',
      (tester) async {
    await openSleep(tester);
    await tester.tap(find.text('اضغط للعدّ'));
    await tester.pump();
    await tester.tap(find.byTooltip('إغلاق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أذكار النوم'));
    await tester.pumpAndSettle();
    expect(find.text('اضغط للعدّ'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('search finds items, shows filters and opens the reader',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('بحث'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'سفر');
    await tester.pumpAndSettle();
    expect(find.textContaining('الكل ·'), findsOneWidget);
    expect(find.text('لا توجد نتائج'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzzzqq');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج'), findsOneWidget);
  });

  testWidgets('favourites: saving from the reader shows it in favourites',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text('أذكار النوم'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('حفظ الذكر في قائمة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المفضلة العامة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تم'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إغلاق'));
    await tester.pumpAndSettle();
    expect(find.text('1 نص'), findsOneWidget);
  });

  testWidgets('awrad: create a wird, count it, and see it on home',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text('أوراد').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة ورد'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'الاستغفار');
    await tester.pump();
    await tester.tap(find.text('حفظ الورد'));
    await tester.pumpAndSettle();
    expect(find.text('الاستغفار'), findsOneWidget);
    await tester.tap(find.byTooltip('عدّ الاستغفار'));
    await tester.pump();
    expect(find.text('1 / 100'), findsOneWidget);
  });

  testWidgets('first run shows onboarding, then home', (tester) async {
    await _pump(tester, prefs: {'onboarded': false});
    expect(find.text('أذكارك اليومية،'), findsOneWidget);
    await tester.tap(find.text('ابدأ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ليس الآن'));
    await tester.pumpAndSettle();
    expect(find.text('صباح الخير'), findsOneWidget);
  });

  testWidgets('settings: font size and theme controls exist', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('حجم الخط'), findsOneWidget);
    await tester.tap(find.text('حجم الخط'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('كبير'));
    await tester.pumpAndSettle();
    expect(find.text('عرض التشكيل'), findsOneWidget);
  });

  testWidgets('reminders tab lists the three sessions', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('التذكيرات'));
    await tester.pumpAndSettle();
    expect(find.text('6:00 ص'), findsOneWidget);
    expect(find.text('5:00 م'), findsOneWidget);
    expect(find.text('10:30 م'), findsOneWidget);
  });
}
