import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/settings.dart';
import '../../services/reminder_service.dart';
import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../reminders/reminder_rows.dart';
import '../shared/widgets.dart';

/// First-run flow: welcome, reminder times, notification permission.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  int _step = 0;

  void _finish() {
    ref.read(settingsProvider.notifier).finishOnboarding();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final Widget body;
    final List<Widget> buttons;
    switch (_step) {
      case 0:
        body = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.onbWelcome1, style: AppType.displayMd),
            Text(t.onbWelcome2,
                style: AppType.displayMd.copyWith(color: c.iconWarm)),
            const SizedBox(height: AppSpace.s4),
            Text(t.onbWelcomeHint,
                style: AppType.body.copyWith(color: c.textSecondary)),
          ],
        );
        buttons = [
          WideButton(label: t.onbStart, onPressed: () => setState(() => _step = 1)),
        ];
      case 1:
        body = ListView(
          shrinkWrap: true,
          children: [
            Text(t.onbTimesTitle, style: AppType.titleMd),
            const SizedBox(height: AppSpace.s2),
            Text(t.onbTimesHint,
                style: AppType.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: AppSpace.s5),
            const ReminderRows(),
          ],
        );
        buttons = [
          WideButton(label: t.onbContinue, onPressed: () => setState(() => _step = 2)),
        ];
      default:
        body = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notifications_none, size: AppSize.icon2Xl, color: c.iconWarm),
            const SizedBox(height: AppSpace.s4),
            Text(t.onbNotifTitle, style: AppType.titleMd),
            const SizedBox(height: AppSpace.s2),
            Text(t.onbNotifHint,
                style: AppType.body.copyWith(color: c.textSecondary)),
          ],
        );
        buttons = [
          WideButton(
            label: t.onbAllow,
            onPressed: () async {
              await ref.read(reminderServiceProvider).requestPermission();
              _finish();
            },
          ),
          const SizedBox(height: AppSpace.s3),
          WideButton(label: t.onbNotNow, outlined: true, onPressed: _finish),
        ];
    }
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s5),
          child: Column(
            children: [
              Expanded(child: Align(alignment: Alignment.centerRight, child: body)),
              ...buttons,
              const SizedBox(height: AppSpace.s3),
            ],
          ),
        ),
      ),
    );
  }
}
