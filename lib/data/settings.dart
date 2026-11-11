import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/dhikr_weight.dart';
import '../design/typography.dart';
import 'progress.dart';

/// Reader sizes. Level 0 is the designed default; one step smaller and eight
/// larger. The keys are the stored values, kept from the earlier scale so a
/// saved choice keeps the same size.
enum FontScale {
  smaller1('m6', -1),
  normal('m5', 0),
  larger1('m4', 1),
  larger2('m3', 2),
  larger3('m2', 3),
  larger4('m1', 4),
  larger5('medium', 5),
  larger6('p1', 6),
  larger7('p2', 7),
  larger8('p3', 8);

  const FontScale(this.key, this.step);
  final String key;
  final int step;

  TextStyle get dhikrStyle => switch (this) {
        smaller1 => AppType.dhikr16,
        normal => AppType.dhikr20,
        larger1 => AppType.dhikr24,
        larger2 => AppType.dhikrSm,
        larger3 => AppType.dhikrMd,
        larger4 => AppType.dhikr36,
        larger5 => AppType.dhikrLg,
        larger6 => AppType.dhikr44,
        larger7 => AppType.dhikrXl,
        larger8 => AppType.dhikr52,
      };

  FontScale? get smaller => index > 0 ? values[index - 1] : null;
  FontScale? get larger => index < values.length - 1 ? values[index + 1] : null;

  static FontScale fromKey(String? k, [FontScale fallback = normal]) =>
      values.firstWhere((v) => v.key == k, orElse: () => fallback);
}

/// What a fresh install starts with: level 0 in size and weight.
const FontScale defaultFontScale = FontScale.normal;
const DhikrWeight defaultWeight = DhikrWeight.normal;

class Settings {
  const Settings({
    this.themeMode = ThemeMode.system,
    this.fontScale = defaultFontScale,
    this.weight = defaultWeight,
    this.verseScale = defaultFontScale,
    this.headerScale = defaultFontScale,
    this.tashkeel = true,
    this.grace = false,
    this.autoAdvance = true,
    this.onboarded = false,
  });

  final ThemeMode themeMode;
  final FontScale fontScale;

  /// Size of mushaf verses, and of the ornamental basmala / ta'awwudh line.
  final DhikrWeight weight;
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
    DhikrWeight? weight,
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
        weight: weight ?? this.weight,
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
      fontScale: FontScale.fromKey(p.getString('font'), defaultFontScale),
      weight: DhikrWeight.fromKey(p.getString('fontWeight'), defaultWeight),
      verseScale: FontScale.fromKey(p.getString('fontVerse'), defaultFontScale),
      headerScale: FontScale.fromKey(p.getString('fontHeader'), defaultFontScale),
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

  void setWeight(DhikrWeight w) {
    ref.read(sharedPreferencesProvider).setString('fontWeight', w.key);
    state = state.copyWith(weight: w);
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
