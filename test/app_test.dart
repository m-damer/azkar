import 'dart:convert';
import 'dart:io';

import 'package:azkar/app.dart';
import 'package:azkar/content/content_provider.dart';
import 'package:azkar/content/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home lists the sections and drills into a category',
      (tester) async {
    final content = Content.fromJson(
      jsonDecode(File('content/content.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [contentProvider.overrideWith((ref) async => content)],
        child: const AzkarApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الأذكار'), findsOneWidget);
    expect(find.text('الأدعية'), findsOneWidget);

    await tester.tap(find.text('الأذكار'));
    await tester.pumpAndSettle();
    expect(find.text('الاستيقاظ والنوم'), findsOneWidget);
  });
}
