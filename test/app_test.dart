import 'package:azkar/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home lists the sections and drills into a category',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AzkarApp()));
    await tester.pumpAndSettle();

    expect(find.text('أذكار'), findsWidgets);
    expect(find.text('الأذكار'), findsOneWidget);
    expect(find.text('الأدعية'), findsOneWidget);

    await tester.tap(find.text('الأذكار'));
    await tester.pumpAndSettle();
    expect(find.text('الاستيقاظ والنوم'), findsOneWidget);
  });
}
