// GENERATED from docs/design-tokens.json — keep in sync with the design system.

/// Spacing, 4-point scale.
abstract final class AppSpace {
  /// Icon-to-label gap, tight inline gaps.
  static const double s1 = 4.0;
  /// Gap between chips and small controls; inner padding of compact elements.
  static const double s2 = 8.0;
  /// Gap between tiles and list rows; padding inside small cards.
  static const double s3 = 12.0;
  /// Default padding inside cards and sheets; gap between sections of related content.
  static const double s4 = 16.0;
  /// Screen gutter (left and right edge of every screen).
  static const double s5 = 20.0;
  /// Padding inside large tiles; bottom safe margin above floating navigation.
  static const double s6 = 24.0;
  /// Gap between unrelated groups.
  static const double s8 = 32.0;
  /// Large vertical rhythm on onboarding screens.
  static const double s10 = 40.0;
  /// Space above a screen title block on onboarding.
  static const double s12 = 48.0;
  /// Top inset below the status bar on phones.
  static const double s14 = 56.0;
  /// Empty-state vertical padding.
  static const double s16 = 64.0;
  /// Reserved for tablet gutters.
  static const double s20 = 80.0;
}

/// Corner radii.
abstract final class AppRadius {
  /// Progress bars, thin indicators.
  static const double xs = 4.0;
  /// Small badges, focus outline radius.
  static const double sm = 8.0;
  /// Icon buttons with a square silhouette, swatches.
  static const double md = 12.0;
  /// Inner panels inside a card (text well in a bottom sheet).
  static const double lg = 16.0;
  /// List rows, inputs, option rows, dialogs.
  static const double xl = 24.0;
  /// Session tiles, bottom-sheet top corners, hero tiles.
  static const double xxl = 32.0;
  /// Every button, chip, segmented control, switch track and circular icon button.
  static const double full = 9999.0;
}

/// Component sizes.
abstract final class AppSize {
  /// Inline glyph next to 12px captions.
  static const double iconSm = 16.0;
  /// Glyph inside chips and small buttons.
  static const double iconMd = 20.0;
  /// Default icon size. Stroke 2px.
  static const double iconLg = 24.0;
  /// Tile icons.
  static const double iconXl = 32.0;
  /// Empty-state glyphs.
  static const double icon2Xl = 48.0;
  /// Visual height of chips and segment items. The hit area still extends to 48px.
  static const double controlSm = 40.0;
  /// Icon buttons, secondary buttons, inputs.
  static const double controlMd = 48.0;
  /// Primary buttons and list-row actions.
  static const double controlLg = 56.0;
  /// Floating navigation bar, large list rows.
  static const double controlXl = 64.0;
  /// Minimum interactive target in any direction.
  static const double touchMin = 48.0;
  /// Screen left and right padding. Same value as space-5.
  static const double gutter = 20.0;
  /// Standard dhikr row height.
  static const double row = 64.0;
  /// First session tile on the home screen.
  static const double tileHero = 152.0;
  /// Second and third session tiles, awrad and favourites tiles.
  static const double tileHalf = 128.0;
  /// Below this tile height the hint line is dropped so short screens never overflow.
  static const double tileCompact = 96.0;
  /// Switch track width.
  static const double switchW = 52.0;
  /// Switch track height.
  static const double switchH = 32.0;
  /// Switch thumb (on). Off thumb is 20.
  static const double switchThumb = 24.0;
  /// Progress track thickness, thin.
  static const double barSm = 4.0;
  /// Progress track thickness, default.
  static const double barMd = 8.0;
  /// Streak dot diameter.
  static const double dot = 12.0;
}
