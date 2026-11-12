import 'package:azkar/data/progress.dart';
import 'package:azkar/data/widget_style.dart';
import 'package:azkar/services/widget_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Native implements WidgetService {
  final styles = <List<double>>[];

  @override
  Future<void> style(double title, double text) async => styles.add([title, text]);

  @override
  Future<void> sync(List<Map<String, Object?>> entries) async {}

  @override
  Future<String?> initialRoute() async => null;

  @override
  void onRoute(void Function(String route) handler) {}
}

void main() {
  test('widget font: default is x1, up to x5, title and text apart, reset',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final native = _Native();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      widgetServiceProvider.overrideWithValue(native),
    ]);
    expect(c.read(widgetStyleProvider).isDefault, isTrue);
    final n = c.read(widgetStyleProvider.notifier);
    n.setTitle(2);
    n.setText(99);
    final s = c.read(widgetStyleProvider);
    expect(s.titleScale, 2.0);
    expect(s.textScale, 5.0);
    expect(native.styles.last, [2.0, 5.0]);
    n.reset();
    expect(c.read(widgetStyleProvider).isDefault, isTrue);
    expect(native.styles.last, [1.0, 1.0]);
    expect(prefs.getInt('widgetTextStep'), 0);
  });
}
