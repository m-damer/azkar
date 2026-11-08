import 'dart:convert';
import 'dart:io';

import 'package:azkar/app.dart';
import 'package:azkar/content/content_provider.dart';
import 'package:azkar/content/models.dart';
import 'package:azkar/features/sessions/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Content> _pump(WidgetTester tester, {DateTime? now}) async {
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
    for (final label in ['اليوم', 'أوراد', 'التذكيرات', 'الإعدادات']) {
      expect(find.text(label), findsOneWidget);
    }
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

  testWidgets('reader: counter counts, and swiping or buttons move on',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text('أذكار النوم'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 13'), findsOneWidget);

    await tester.tap(find.text('اضغط للعدّ'));
    await tester.pump();
    expect(find.text('1'), findsWidgets);

    // RTL: pages sit right-to-left, so swiping right reveals the next item.
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('2 / 13'), findsOneWidget);

    await tester.tap(find.byTooltip('السابق'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 13'), findsOneWidget);

    await tester.tap(find.byTooltip('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 13'), findsOneWidget);
  });
}
