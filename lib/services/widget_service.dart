import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pushes the home-screen widget's schedule to the native Android widget.
abstract class WidgetService {
  /// [entries]: title, text, from / to (minutes since midnight), days (1 = Mon … 7 = Sun).
  Future<void> sync(List<Map<String, Object?>> entries);

  /// Route the app was opened with from the widget (null when none).
  Future<String?> initialRoute();

  /// Called when the widget opens the already-running app on a route.
  void onRoute(void Function(String route) handler);
}

class NativeWidgetService implements WidgetService {
  static const _channel = MethodChannel('com.azkar/widget');

  @override
  Future<void> sync(List<Map<String, Object?>> entries) async {
    try {
      await _channel.invokeMethod<bool>('sync', jsonEncode(entries));
    } catch (e) {
      debugPrint('widget sync failed: $e');
    }
  }

  @override
  Future<String?> initialRoute() async {
    try {
      return await _channel.invokeMethod<String>('initialRoute');
    } catch (e) {
      return null;
    }
  }

  @override
  void onRoute(void Function(String route) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'route') handler(call.arguments as String);
    });
  }
}

final widgetServiceProvider =
    Provider<WidgetService>((ref) => NativeWidgetService());
