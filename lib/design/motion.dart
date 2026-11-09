import 'package:flutter/animation.dart';

/// Motion tokens.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  /// Window for the second back press that exits the app.
  static const Duration exitWindow = Duration(seconds: 2);
  static const Curve standard = Curves.easeOutCubic;
}
