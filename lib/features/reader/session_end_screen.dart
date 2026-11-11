import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/progress.dart';
import '../../data/settings.dart';
import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/numbers.dart';
import '../sessions/session.dart';

/// Shown after the last item of a session is completed.
class SessionEndScreen extends ConsumerWidget {
  const SessionEndScreen({super.key, required this.kind});

  final SessionKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final progress = ref.watch(progressProvider);
    final now = ref.watch(nowProvider);
    final streak = progress.streak(now, grace: ref.watch(settingsProvider).grace);
    final bothDone = progress.doneSessions.contains(SessionKind.morning.key) &&
        progress.doneSessions.contains(SessionKind.evening.key);
    final bg = bothDone ? c.tileDone : kind.background(c);
    final fg = bothDone ? c.onTileDone : kind.foreground(c);
    final title = bothDone ? t.endDayDone : t.endSessionDone(kind.name(t));
    final sub = bothDone
        ? t.endDayDoneHint
        : switch (kind) {
            SessionKind.wake => t.endWakeHint,
            SessionKind.morning => t.endMorningHint,
            SessionKind.evening => t.endEveningHint,
            SessionKind.sleep => t.endSleepHint,
          };
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s5),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: AppSize.icon2Xl, color: fg),
                    const SizedBox(height: AppSpace.s4),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: AppType.titleMd.copyWith(color: fg)),
                    const SizedBox(height: AppSpace.s2),
                    Text(sub,
                        textAlign: TextAlign.center,
                        style: AppType.body.copyWith(color: fg)),
                    const SizedBox(height: AppSpace.s8),
                    Text(t.endStreakLabel,
                        style: AppType.caption.copyWith(color: fg)),
                    Text(t.endStreakDays(Nouns.day.of(streak)),
                        style: AppType.displayMd.copyWith(color: fg)),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: AppSize.controlLg,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: fg, foregroundColor: bg),
                  onPressed: () => context.go('/'),
                  child: Text(t.endHome, style: AppType.label),
                ),
              ),
              const SizedBox(height: AppSpace.s3),
              SizedBox(
                width: double.infinity,
                height: AppSize.controlLg,
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: fg),
                  onPressed: () {
                    ref.read(progressProvider.notifier).resetSession(kind.key);
                    context.pushReplacement('/session/${kind.key}');
                  },
                  child: Text(t.endReread, style: AppType.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
