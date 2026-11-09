import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/typography.dart';
import 'progress.dart';

enum FontScale {
  small('small'),
  medium('medium'),
  large('large');

  const FontScale(this.key);
  final String key;

  TextStyle get dhikrStyle => switch (this) {
        small => AppType.dhikrSm,
        medium => AppType.dhikrLg,
        large => AppType.dhikrXl,
      };

  static FontScale fromKey(String? k) =>
      values.firstWhere((v) => v.key == k, orElse: () => medium);
}

class Settings {
  const Settings({
    this.themeMode = ThemeMode.system,
    this.fontScale = FontScale.medium,
    this.tashkeel = true,
    this.grace = false,
    this.autoAdvance = true,
    this.onboarded = false,
  });

  final ThemeMode themeMode;
  final FontScale fontScale;
  final bool tashkeel;

  /// A single missed day does not break the streak.
  final bool grace;

  /// Move to the next dhikr as soon as the counter finishes.
  final bool autoAdvance;
  final bool onboarded;

  Settings copyWith({
    ThemeMode? themeMode,
    FontScale? fontScale,
    bool? tashkeel,
    bool? grace,
    bool? autoAdvance,
    bool? onboarded,
  }) =>
      Settings(
        themeMode: themeMode ?? this.themeMode,
        fontScale: fontScale ?? this.fontScale,
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
