/// Design values that are not (yet) part of docs/design-tokens.json.
/// Raw numbers are allowed here only; widgets read these names.
abstract final class AppAlpha {
  /// Faint track / divider drawn in the current foreground colour.
  static const double track = 0.2;

  /// Disabled control.
  static const double disabled = 0.4;
}

abstract final class AppStroke {
  /// Outline width of outlined buttons and badges.
  static const double md = 2.0;
}

abstract final class AppExtra {
  /// Height of the dhikr counter button in the reader.
  static const double counterHeight = 96.0;
}
