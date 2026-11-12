import 'dart:convert';
import 'dart:io';

import 'package:azkar/app.dart';
import 'package:azkar/content/content_provider.dart';
import 'package:azkar/content/models.dart';
import 'package:azkar/data/library.dart';
import 'package:azkar/data/progress.dart';
import 'package:azkar/data/reminders.dart';
import 'package:azkar/features/sessions/session.dart';
import 'package:azkar/services/reminder_service.dart';
import 'package:azkar/services/update_service.dart';
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

  @override
  Future<void> scheduleAwrad(List<Wird> awrad) async {}

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<String?> launchRoute() async => null;
}

class _FakeUpdates implements UpdateService {
  _FakeUpdates(this.info);
  final UpdateInfo? info;
  bool installed = false;

  @override
  Future<UpdateInfo?> latest() async => info;

  @override
  Future<String> download(UpdateInfo i, void Function(double) p) async {
    p(1);
    return '/tmp/x.apk';
  }

  @override
  Future<bool> install(String path) async => installed = true;
}

Future<Content> _pump(WidgetTester tester,
    {DateTime? now,
    Map<String, Object> prefs = const {},
    UpdateInfo? update}) async {
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
        updateServiceProvider.overrideWithValue(_FakeUpdates(update)),
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
    expect(find.text('الاستيقاظ من النوم'), findsOneWidget);
    expect(find.text('المزيد من الأذكار والأدعية'), findsOneWidget);
    expect(find.text('من كتاب حصن المسلم'), findsOneWidget);
    expect(find.text('من أدعية الرسول ﷺ'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    for (final label in ['اليوم', 'الإعدادات']) {
      expect(find.text(label), findsOneWidget);
    }
    // Awrad lives only in the nav now.
    expect(find.text('أوراد'), findsOneWidget);
  });

  testWidgets('home shows the streak and a completed session', (tester) async {
    await _pump(tester, prefs: {
      'activeDays': ['2026-11-07', '2026-11-08'],
      'done:2026-11-08': ['morning'],
    });
    expect(find.text('سلسلتك يومان'), findsOneWidget);
    expect(find.text('اكتمل'), findsOneWidget);
  });

  testWidgets('the hero follows the time of day', (tester) async {
    await _pump(tester, now: DateTime(2026, 11, 8, 22));
    expect(find.text('ليلة هانئة'), findsOneWidget);
  });

  testWidgets('the four sessions follow the clock', (tester) async {
    DateTime t(int h, int m) => DateTime(2026, 11, 8, h, m);
    expect(SessionKind.at(t(3, 59)), SessionKind.sleep);
    expect(SessionKind.at(t(4, 0)), SessionKind.wake);
    expect(SessionKind.at(t(5, 59)), SessionKind.wake);
    expect(SessionKind.at(t(6, 0)), SessionKind.morning);
    expect(SessionKind.at(t(14, 59)), SessionKind.morning);
    expect(SessionKind.at(t(15, 0)), SessionKind.evening);
    expect(SessionKind.at(t(21, 29)), SessionKind.evening);
    expect(SessionKind.at(t(21, 30)), SessionKind.sleep);
    await _pump(tester, now: t(5, 0));
    expect(find.text('يوم مبارك'), findsOneWidget);
  });

  testWidgets('a section lists categories and opens the reader',
      (tester) async {
    final content = await _pump(tester);
    await tester.tap(find.text('المزيد من الأذكار والأدعية'));
    await tester.pumpAndSettle();
    expect(find.text('من كتاب حصن المسلم'), findsOneWidget);
    final cat = content.sectionById('s1')!.categories[1];
    await tester.tap(find.text(cat.title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(cat.chapters.first.title));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('a list can be saved to favourites under an edited name',
      (tester) async {
    final content = await _pump(tester);
    await tester.tap(find.text('المزيد من الأذكار والأدعية'));
    await tester.pumpAndSettle();
    final cat = content.sectionById('s1')!.categories[1];
    await tester.tap(find.byTooltip('أضف هذه القائمة إلى المفضلة').first);
    await tester.pumpAndSettle();
    expect(find.text('إضافة هذه القائمة إلى المفضلة'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'قائمتي');
    await tester.tap(find.text('إضافة هذه القائمة إلى المفضلة'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('هذه القائمة في المفضلة'), findsOneWidget);
    expect(cat.title, isNotEmpty);
  });

  testWidgets('new list: name it, pick a whole list, review, confirm',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text('المفضلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('قائمة جديدة').last);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.enterText(find.byType(TextField), 'قائمتي');
    await tester.tap(find.text('إنشاء القائمة'));
    await tester.pumpAndSettle();
    expect(find.text('من أدعية الرسول ﷺ'), findsOneWidget);
    await tester.tap(find.text('المزيد من الأذكار والأدعية'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('مراجعة'));
    await tester.pumpAndSettle();
    expect(find.text('مراجعة الاختيارات'), findsOneWidget);
    await tester.tap(find.textContaining('تأكيد وإضافة'));
    await tester.pumpAndSettle();
    expect(find.text('قائمتي'), findsOneWidget);
  });

  testWidgets('the duas section says it is coming soon', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('من أدعية الرسول ﷺ'));
    await tester.pumpAndSettle();
    expect(find.text('قريباً سيتم تفعيل هذا القسم'), findsOneWidget);
  });

  testWidgets('home fits a short screen without overflow or scrolling',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester);
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsNothing);
  });

  Future<void> openSleep(WidgetTester tester) async {
    await _pump(tester);
    await tester.tap(find.text('أذكار النوم'));
    await tester.pumpAndSettle();
    expect(find.text('١ / ١٨'), findsOneWidget);
  }

  testWidgets('reader: the counter counts', (tester) async {
    await openSleep(tester);
    await tester.tap(find.text('اضغط للعدّ'));
    await tester.pump();
    expect(find.text('١'), findsWidgets);
  });

  testWidgets('reader: auto-advance moves on when the counter finishes',
      (tester) async {
    await openSleep(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('اضغط للعدّ'));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('٢ / ١٨'), findsOneWidget);
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
    expect(find.text('١ / ١٨'), findsOneWidget);
  });

  testWidgets('reader: swipe right goes to the next item (RTL)',
      (tester) async {
    await openSleep(tester);
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('٢ / ١٨'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('١ / ١٨'), findsOneWidget);
  });

  testWidgets('reader: next and previous buttons', (tester) async {
    await openSleep(tester);
    await tester.tap(find.byTooltip('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('٢ / ١٨'), findsOneWidget);
    await tester.tap(find.byTooltip('السابق'));
    await tester.pumpAndSettle();
    expect(find.text('١ / ١٨'), findsOneWidget);
  });

  testWidgets('reader: a dhikr can be hidden and the default restored',
      (tester) async {
    await openSleep(tester);
    await tester.tap(find.byTooltip('قائمة الأذكار'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إخفاء').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إغلاق').last);
    await tester.pumpAndSettle();
    expect(find.text('١ / ١٧'), findsOneWidget);
    await tester.tap(find.byTooltip('قائمة الأذكار'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('استعادة الافتراضي'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إغلاق').last);
    await tester.pumpAndSettle();
    expect(find.text('٢ / ١٨'), findsOneWidget);
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
    expect(find.text('١'), findsWidgets);
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
    expect(find.text('نص واحد'), findsOneWidget);
  });

  testWidgets('widget settings: pick an azkar and edit its time window',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('ويدجت الأذكار'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('ويدجت الأذكار'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ويدجت الأذكار'));
    await tester.pumpAndSettle();
    expect(find.text('لم تختر أذكاراً بعد'), findsOneWidget);
    await tester.tap(find.text('إضافة أذكار'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المزيد من الأذكار والأدعية'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('مراجعة'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('تأكيد وإضافة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('٦:٠٠ ص'), findsWidgets);
  });

  testWidgets('awrad: a wird can have a repeating reminder', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('أوراد').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة ورد'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'الحمد');
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('أيام التكرار'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('وقت التذكير'), findsOneWidget);
    expect(find.text('أيام التكرار'), findsOneWidget);
    await tester.tap(find.text('حفظ الورد'));
    await tester.pumpAndSettle();
    expect(find.textContaining('كل يوم'), findsOneWidget);
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
    expect(find.text('١ / ١٠٠'), findsOneWidget);
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
    expect(find.text('نصوص الأذكار والأدعية'), findsOneWidget);
    // Fresh installs start at level 0 in size and weight.
    expect(find.text('الحجم الافتراضي'), findsAtLeastNWidgets(2));
    expect(find.text('الوزن الافتراضي'), findsOneWidget);
    for (var i = 0; i < 9; i++) {
      await tester.tap(find.byTooltip('تكبير الخط').first);
      await tester.pumpAndSettle();
    }
    expect(find.text('أكبر بـ ٨ درجات'), findsOneWidget);
    for (var i = 0; i < 9; i++) {
      await tester.tap(find.byTooltip('تصغير الخط').first);
      await tester.pumpAndSettle();
    }
    expect(find.text('أصغر بدرجة واحدة'), findsOneWidget);
    await tester.tap(find.byTooltip('تكبير الخط').at(1));
    await tester.pumpAndSettle();
    expect(find.text('أثقل بدرجة واحدة'), findsOneWidget);
    // The verse size is independent of the text size.
    await tester.scrollUntilVisible(find.text('الآيات'), 100);
    final verse = find.ancestor(
        of: find.text('الآيات'), matching: find.byType(Column)).first;
    final more = find.descendant(
        of: verse, matching: find.byTooltip('تكبير الخط'));
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('أكبر بدرجة واحدة'), findsAtLeastNWidgets(1));
    expect(find.text('عرض التشكيل', skipOffstage: false), findsOneWidget);
  });

  testWidgets('settings: developer page, auto update and font reset',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حجم الخط'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تكبير الخط').first);
    await tester.pumpAndSettle();
    expect(find.text('أكبر بدرجة واحدة'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.text('العودة إلى الأحجام الافتراضية'), 100);
    await tester.pumpAndSettle();
    await tester.tap(find.text('العودة إلى الأحجام الافتراضية'));
    await tester.pumpAndSettle();
    expect(find.text('أكبر بدرجة واحدة'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('التحديث'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('التحديث'));
    await tester.pumpAndSettle();
    expect(find.text('تحديث تلقائي'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('عن المطور'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('عن المطور'));
    await tester.pumpAndSettle();
    expect(find.text('تواصل عبر واتساب'), findsOneWidget);
    expect(find.text('أرسل بريداً إلكترونياً'), findsOneWidget);
  });

  testWidgets('back from another tab goes home, then asks to press again',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('صباح الخير'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('اضغط مرة أخرى للخروج'), findsOneWidget);
  });

  testWidgets('the main list of more azkar has no morning/evening/sleep',
      (tester) async {
    final content = await _pump(tester);
    await tester.tap(find.text('المزيد من الأذكار والأدعية'));
    await tester.pumpAndSettle();
    final first = content.sectionById('s1')!.categories[1].title;
    expect(find.text(first), findsOneWidget);
    expect(find.text('أذكار اليوم'), findsNothing);
    expect(find.text('الصباح والمساء'), findsNothing);
  });

  const newer = UpdateInfo(
      build: 9, apkUrl: 'https://x/y.apk', notes: 'إصلاحات', size: 10);

  testWidgets('update: home shows a card and the screen installs',
      (tester) async {
    await _pump(tester, update: newer);
    expect(find.text('تحديث جديد متوفر'), findsOneWidget);
    await tester.tap(find.text('تحديث جديد متوفر'));
    await tester.pumpAndSettle();
    expect(find.text('إصلاحات'), findsOneWidget);
    await tester.tap(find.text('تنزيل وتثبيت'));
    await tester.pumpAndSettle();
    expect(find.text('تنزيل وتثبيت'), findsOneWidget);
  });

  testWidgets('update: settings says up to date when nothing newer',
      (tester) async {
    await _pump(tester);
    expect(find.text('تحديث جديد متوفر'), findsNothing);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('التحديث'), 100);
    await tester.scrollUntilVisible(find.text('التحديث'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('التحديث'));
    await tester.pumpAndSettle();
    expect(find.text('أنت على أحدث نسخة'), findsOneWidget);
  });

  testWidgets('settings: reminders are inside settings and list the three sessions',
      (tester) async {
    await _pump(tester);
    expect(find.text('التذكيرات'), findsNothing);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('التذكير'), findsOneWidget);
    await tester.tap(find.text('التذكيرات'));
    await tester.pumpAndSettle();
    expect(find.text('٦:٠٠ ص'), findsOneWidget);
    expect(find.text('٥:٠٠ م'), findsOneWidget);
    expect(find.text('١٠:٣٠ م'), findsOneWidget);
  });
}
