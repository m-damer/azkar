import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pushes the home-screen widget's schedule to the native Android widget.
abstract class WidgetService {
  /// [entries]: title, text, from / to (minutes since midnight), days (1 = Mon … 7 = Sun).
  Future<void> sync(List<Map<String, Object?>> entries);
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
}

final widgetServiceProvider =
    Provider<WidgetService>((ref) => NativeWidgetService());
