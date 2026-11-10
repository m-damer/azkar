import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/typography.dart';
import 'progress.dart';

/// Ten reader sizes: six steps smaller and three larger than the default.
enum FontScale {
  smaller6('m6', -6),
  smaller5('m5', -5),
  smaller4('m4', -4),
  smaller3('m3', -3),
  smaller2('m2', -2),
  smaller1('m1', -1),
  normal('medium', 0),
  larger1('p1', 1),
  larger2('p2', 2),
  larger3('p3', 3);

  const FontScale(this.key, this.step);
  final String key;
  final int step;

  TextStyle get dhikrStyle => switch (this) {
        smaller6 => AppType.dhikr16,
        smaller5 => AppType.dhikr20,
        smaller4 => AppType.dhikr24,
        smaller3 => AppType.dhikrSm,
        smaller2 => AppType.dhikrMd,
        smaller1 => AppType.dhikr36,
        normal => AppType.dhikrLg,
        larger1 => AppType.dhikr44,
        larger2 => AppType.dhikrXl,
        larger3 => AppType.dhikr52,
      };

  FontScale? get smaller => step > -6 ? values[index - 1] : null;
  FontScale? get larger => step < 3 ? values[index + 1] : null;

  static FontScale fromKey(String? k) =>
      values.firstWhere((v) => v.key == k, orElse: () => normal);
}

class Settings {
  const Settings({
    this.themeMode = ThemeMode.system,
    this.fontScale = FontScale.normal,
    this.verseScale = FontScale.normal,
    this.headerScale = FontScale.normal,
    this.tashkeel = true,
    this.grace = false,
    this.autoAdvance = true,
    this.onboarded = false,
  });

  final ThemeMode themeMode;
  final FontScale fontScale;

  /// Size of mushaf verses, and of the ornamental basmala / ta'awwudh line.
  final FontScale verseScale;
  final FontScale headerScale;
  final bool tashkeel;

  /// A single missed day does not break the streak.
  final bool grace;

  /// Move to the next dhikr as soon as the counter finishes.
  final bool autoAdvance;
  final bool onboarded;

  Settings copyWith({
    ThemeMode? themeMode,
    FontScale? fontScale,
    FontScale? verseScale,
    FontScale? headerScale,
    bool? tashkeel,
    bool? grace,
    bool? autoAdvance,
    bool? onboarded,
  }) =>
      Settings(
        themeMode: themeMode ?? this.themeMode,
        fontScale: fontScale ?? this.fontScale,
        verseScale: verseScale ?? this.verseScale,
        headerScale: headerScale ?? this.headerScale,
        tashkeel: tashkeel ?? this.tashkeel,
        grace: grace ?? this.grace,
        autoAdvance: autoAdvance ?? this.autoAdvance,
        onboarded: onboarded ?? this.onboarded,
      );
}

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    final p = ref.read(sharedPreferencesProvider);
    return Settings(
      themeMode: switch (p.getString('theme')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      fontScale: FontScale.fromKey(p.getString('font')),
      verseScale: FontScale.fromKey(p.getString('fontVerse')),
      headerScale: FontScale.fromKey(p.getString('fontHeader')),
      tashkeel: p.getBool('tashkeel') ?? true,
      grace: p.getBool('grace') ?? false,
      autoAdvance: p.getBool('autoAdvance') ?? true,
      onboarded: p.getBool('onboarded') ?? false,
    );
  }

  void setThemeMode(ThemeMode m) {
    ref.read(sharedPreferencesProvider).setString('theme', m.name);
    state = state.copyWith(themeMode: m);
  }

  void setFontScale(FontScale f) {
    ref.read(sharedPreferencesProvider).setString('font', f.key);
    state = state.copyWith(fontScale: f);
  }

  void setVerseScale(FontScale f) {
    ref.read(sharedPreferencesProvider).setString('fontVerse', f.key);
    state = state.copyWith(verseScale: f);
  }

  void setHeaderScale(FontScale f) {
    ref.read(sharedPreferencesProvider).setString('fontHeader', f.key);
    state = state.copyWith(headerScale: f);
  }

  void setTashkeel(bool v) {
    ref.read(sharedPreferencesProvider).setBool('tashkeel', v);
    state = state.copyWith(tashkeel: v);
  }

  void setGrace(bool v) {
    ref.read(sharedPreferencesProvider).setBool('grace', v);
    state = state.copyWith(grace: v);
  }

  void setAutoAdvance(bool v) {
    ref.read(sharedPreferencesProvider).setBool('autoAdvance', v);
    state = state.copyWith(autoAdvance: v);
  }

  void finishOnboarding() {
    ref.read(sharedPreferencesProvider).setBool('onboarded', true);
    state = state.copyWith(onboarded: true);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
