import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_info.dart';
import '../../content/arabic.dart';
import '../../data/progress.dart';
import '../../data/settings.dart';
import '../../design/dhikr_weight.dart';
import '../../design/dimens.dart';
import '../../design/mushaf.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/numbers.dart';
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
              subtitle: fontScaleLabel(t, s.fontScale),
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
              title: t.widgetTitle,
              subtitle: t.widgetSettingHint,
              leading: const Icon(Icons.widgets_outlined),
              onTap: () => context.push('/settings/widget'),
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
              title: t.setUpdate,
              leading: const Icon(Icons.system_update),
              onTap: () => context.push('/settings/update'),
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

String fontScaleLabel(AppLocalizations t, FontScale f) => f.step == 0
    ? t.fontDefault
    : f.step > 0
        ? t.fontLarger(Nouns.degreesBy(f.step))
        : t.fontSmaller(Nouns.degreesBy(-f.step));

class FontSettingsScreen extends ConsumerWidget {
  const FontSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    Widget section(String title, Widget preview, String label,
        VoidCallback? minus, VoidCallback? plus) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppType.heading),
            const SizedBox(height: AppSpace.s2),
            Material(
              color: c.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s5),
                  child: preview,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s3),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: t.fontDecrease,
                  onPressed: minus,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.label,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: t.fontIncrease,
                  onPressed: plus,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget glyphLine(List<String> glyphs, double base) => Wrap(
          textDirection: TextDirection.rtl,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: MushafType.headerGap(base),
          children: [
            for (final g in glyphs)
              Text(g, style: MushafType.header(base, c.textPrimary)),
          ],
        );

    final headerBase = s.headerScale.dhikrStyle.fontSize!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: t.setFont),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.s5),
                children: [
                  section(
                    t.setFontText,
                    Text(
                      s.tashkeel ? _sampleDhikr : stripDiacritics(_sampleDhikr),
                      textAlign: TextAlign.center,
                      style: s.fontScale.dhikrStyle
                          .copyWith(color: c.textPrimary),
                    ),
                    fontScaleLabel(t, s.fontScale),
                    s.fontScale.smaller == null
                        ? null
                        : () => n.setFontScale(s.fontScale.smaller!),
                    s.fontScale.larger == null
                        ? null
                        : () => n.setFontScale(s.fontScale.larger!),
                  ),
                  section(
                    t.setFontWeight,
                    DhikrText(
                      _sampleDhikr,
                      style: s.fontScale.dhikrStyle,
                      color: c.textPrimary,
                      weight: s.weight,
                    ),
                    switch (s.weight) {
                      DhikrWeight.thin => t.weightThin,
                      DhikrWeight.light => t.weightLight,
                      DhikrWeight.normal => t.weightNormal,
                      DhikrWeight.bold => t.weightBold,
                      DhikrWeight.heavy => t.weightHeavy,
                    },
                    s.weight.lighter == null
                        ? null
                        : () => n.setWeight(s.weight.lighter!),
                    s.weight.heavier == null
                        ? null
                        : () => n.setWeight(s.weight.heavier!),
                  ),
                  section(
                    t.setFontVerse,
                    Text(
                      _sampleVerse,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: MushafType.verse(_samplePage,
                          s.verseScale.dhikrStyle.fontSize!, c.textPrimary),
                    ),
                    fontScaleLabel(t, s.verseScale),
                    s.verseScale.smaller == null
                        ? null
                        : () => n.setVerseScale(s.verseScale.smaller!),
                    s.verseScale.larger == null
                        ? null
                        : () => n.setVerseScale(s.verseScale.larger!),
                  ),
                  section(
                    t.setFontHeader,
                    Column(
                      children: [
                        glyphLine(MushafType.basmala, headerBase),
                        const SizedBox(height: AppSpace.s3),
                        glyphLine(MushafType.taawwudh, headerBase),
                      ],
                    ),
                    fontScaleLabel(t, s.headerScale),
                    s.headerScale.smaller == null
                        ? null
                        : () => n.setHeaderScale(s.headerScale.smaller!),
                    s.headerScale.larger == null
                        ? null
                        : () => n.setHeaderScale(s.headerScale.larger!),
                  ),
                  Text(t.fontPreviewHint,
                      textAlign: TextAlign.center,
                      style: AppType.body.copyWith(color: c.textSecondary)),
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

/// «قل هو الله أحد» as mushaf glyphs of page 604, for the size preview.
const int _samplePage = 604;
const String _sampleVerse = 'ﱁ\u200bﱂ\u200bﱃ\u200bﱄﱅ';

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
                      stat(arNum(streak), t.streakCurrent),
                      stat(arNum(longest), t.streakLongest),
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
          child: Text(arNum(day),
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
                  const SizedBox(height: AppSpace.s3),
                  InfoRow(
                    title: t.sourcesQuran,
                    subtitle: t.sourcesQuranCredit,
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
