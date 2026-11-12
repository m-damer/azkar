import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/widget_service.dart';
import 'progress.dart';

/// Number of enlargement steps above the default (step 0 = default size).
const int widgetScaleSteps = 8;

/// A step is half a size: step 0 → ×1, step 8 → ×5.
double widgetScaleOf(int step) => 1 + step * 0.5;

/// Font size of the Android widget's title and text, each on its own.
/// Step 0 is the default size the widget always had.
class WidgetStyle {
  const WidgetStyle({this.title = 0, this.text = 0});

  final int title;
  final int text;

  double get titleScale => widgetScaleOf(title);
  double get textScale => widgetScaleOf(text);
  bool get isDefault => title == 0 && text == 0;
}

class WidgetStyleNotifier extends Notifier<WidgetStyle> {
  @override
  WidgetStyle build() {
    final p = ref.read(sharedPreferencesProvider);
    int read(String k) => (p.getInt(k) ?? 0).clamp(0, widgetScaleSteps);
    return WidgetStyle(title: read('widgetTitleStep'), text: read('widgetTextStep'));
  }

  void _save(WidgetStyle s) {
    final p = ref.read(sharedPreferencesProvider);
    p.setInt('widgetTitleStep', s.title);
    p.setInt('widgetTextStep', s.text);
    state = s;
    push();
  }

  void setTitle(int step) =>
      _save(WidgetStyle(title: step.clamp(0, widgetScaleSteps), text: state.text));

  void setText(int step) =>
      _save(WidgetStyle(title: state.title, text: step.clamp(0, widgetScaleSteps)));

  void reset() => _save(const WidgetStyle());

  /// Sends the sizes to the native widget.
  void push() => ref
      .read(widgetServiceProvider)
      .style(state.titleScale, state.textScale);
}

final widgetStyleProvider =
    NotifierProvider<WidgetStyleNotifier, WidgetStyle>(WidgetStyleNotifier.new);
