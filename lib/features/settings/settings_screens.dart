import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_info.dart';
import '../../content/arabic.dart';
import '../../data/progress.dart';
import '../../data/settings.dart';
import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../sessions/session.dart';
import '../shared/widgets.dart';

const _sampleDhikr = 'سُبْحَانَ اللهِ وَبِحَمْدِهِ';

/// The settings tab.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s5),
          children: [
            const SizedBox(height: AppSpace.s6),
            Text(t.navSettings, style: AppType.titleLg),
            const SizedBox(height: AppSpace.s5),
            InfoRow(
              title: t.setFont,
              subtitle: switch (s.fontScale) {
                FontScale.small => t.fontSmall,
                FontScale.medium => t.fontMedium,
                FontScale.large => t.fontLarge,
              },
              leading: const Icon(Icons.text_fields),
              onTap: () => context.push('/settings/font'),
            ),
            const SizedBox(height: AppSpace.s3),
            Text(t.setTheme, style: AppType.label),
            const SizedBox(height: AppSpace.s2),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: ThemeMode.light, label: Text(t.themeLight)),
                ButtonSegment(value: ThemeMode.dark, label: Text(t.themeDark)),
                ButtonSegment(value: ThemeMode.system, label: Text(t.themeAuto)),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => n.setThemeMode(v.first),
            ),
            const SizedBox(height: AppSpace.s3),
            SwitchListTile(
              value: s.autoAdvance,
              onChanged: n.setAutoAdvance,
              title: Text(t.setAutoAdvance, style: AppType.label),
              subtitle: Text(t.setAutoAdvanceHint, style: AppType.caption),
            ),
            const SizedBox(height: AppSpace.s3),
            InfoRow(
              title: t.setStreak,
              leading: const Icon(Icons.local_fire_department_outlined),
              onTap: () => context.push('/settings/streak'),
            ),
            const SizedBox(height: AppSpace.s3),
            InfoRow(
              title: t.setSources,
              leading: const Icon(Icons.menu_book_outlined),
              onTap: () => context.push('/settings/sources'),
            ),
            const SizedBox(height: AppSpace.s3),
            InfoRow(
              title: t.setAbout,
              leading: const Icon(Icons.info_outline),
              onTap: () => context.push('/settings/about'),
            ),
          ],
        ),
      ),
    );
  }
}

class FontSettingsScreen extends ConsumerWidget {
  const FontSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: t.setFont),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.s5),
                children: [
                  Material(
                    color: c.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.s6),
                      child: Column(
                        children: [
                          Text(
                            s.tashkeel
                                ? _sampleDhikr
                                : stripDiacritics(_sampleDhikr),
                            textAlign: TextAlign.center,
                            style: s.fontScale.dhikrStyle
                                .copyWith(color: c.textPrimary),
                          ),
                          const SizedBox(height: AppSpace.s3),
                          Text(t.fontPreviewHint,
                              textAlign: TextAlign.center,
                              style: AppType.body
                                  .copyWith(color: c.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s5),
                  SegmentedButton<FontScale>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: FontScale.small, label: Text(t.fontSmall)),
                      ButtonSegment(
                          value: FontScale.medium, label: Text(t.fontMedium)),
                      ButtonSegment(
                          value: FontScale.large, label: Text(t.fontLarge)),
                    ],
                    selected: {s.fontScale},
                    onSelectionChanged: (v) => n.setFontScale(v.first),
                  ),
                  const SizedBox(height: AppSpace.s3),
                  SwitchListTile(
                    value: s.tashkeel,
                    onChanged: n.setTashkeel,
                    title: Text(t.setTashkeel, style: AppType.label),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final progress = ref.watch(progressProvider);
    final today = ref.watch(nowProvider);
    final streak = progress.streak(today, grace: s.grace);
    final longest = longestStreak(progress.activeDays);
    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value, style: AppType.displayMd.copyWith(color: c.textPrimary)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: AppType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        );
    final days = [
      for (var i = 29; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: t.setStreak),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.s5),
                children: [
                  Row(
                    children: [
                      stat('$streak', t.streakCurrent),
                      stat('$longest', t.streakLongest),
                      stat('${progress.activeDays.length}', t.streakTotal),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s6),
                  Wrap(
                    spacing: AppSpace.s2,
                    runSpacing: AppSpace.s2,
                    children: [
                      for (final d in days)
                        _DayDot(
                          day: d.day,
                          active: progress.activeDays.contains(dayKey(d)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s5),
                  Text(t.streakRule,
                      style: AppType.body.copyWith(color: c.textSecondary)),
                  SwitchListTile(
                    value: s.grace,
                    onChanged: n.setGrace,
                    title: Text(t.streakGrace, style: AppType.label),
                    subtitle: Text(t.streakGraceHint, style: AppType.caption),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day, required this.active});

  final int day;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? c.tileDone : c.surfaceRaised,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: AppSize.controlMd - AppSpace.s2,
        height: AppSize.controlMd - AppSpace.s2,
        child: Center(
          child: Text('$day',
              style: AppType.caption
                  .copyWith(color: active ? c.onTileDone : c.textSecondary)),
        ),
      ),
    );
  }
}

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: t.setSources),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.s5),
                children: [
                  Text(t.sourcesIntro,
                      style: AppType.body.copyWith(color: c.textSecondary)),
                  const SizedBox(height: AppSpace.s4),
                  InfoRow(
                    title: t.sourcesBook,
                    subtitle: t.sourcesBookAuthor,
                    trailing: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: t.setAbout),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t.appName, style: AppType.displayMd),
                    Text(t.aboutVersion(appVersion),
                        style: AppType.caption.copyWith(color: c.textSecondary)),
                    const SizedBox(height: AppSpace.s5),
                    Text(t.aboutDescription,
                        textAlign: TextAlign.center,
                        style: AppType.body),
                    const SizedBox(height: AppSpace.s3),
                    Text(t.aboutPrivacy,
                        textAlign: TextAlign.center,
                        style: AppType.body.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
