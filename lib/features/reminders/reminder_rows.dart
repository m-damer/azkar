import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reminders.dart';
import '../../design/dimens.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../services/reminder_service.dart';
import '../sessions/session.dart';
import '../shared/pickers.dart';
import '../shared/widgets.dart';

/// Three rows (morning / evening / sleep) with a time picker.
class ReminderRows extends ConsumerWidget {
  const ReminderRows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final times = ref.watch(remindersProvider);
    return Column(
      children: [
        for (final k in SessionKind.reminderKinds) ...[
          InfoRow(
            title: k.name(t),
            subtitle: formatTime(times.of(k)),
            leading: Icon(k.icon),
            trailing: const Icon(Icons.edit_outlined, size: AppSize.iconMd),
            onTap: () async {
              final picked = await showTimeSheet(
                context,
                initial: times.of(k),
                title: k.name(t),
              );
              if (picked != null) {
                ref.read(remindersProvider.notifier).set(k, picked);
              }
            },
          ),
          const SizedBox(height: AppSpace.s3),
        ],
      ],
    );
  }
}

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final enabled = ref.watch(notificationsEnabledProvider).value ?? true;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: t.navReminders),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.s5, AppSpace.s1, AppSpace.s5, AppSpace.s5),
                children: [
                  Text(t.remindersSubtitle, style: AppType.body),
                  const SizedBox(height: AppSpace.s5),
                  if (!enabled) ...[
                    InfoRow(
                      title: t.notifOffTitle,
                      subtitle: t.notifOffHint,
                      trailing: const Icon(Icons.notifications_off_outlined),
                      onTap: () async {
                        await ref
                            .read(reminderServiceProvider)
                            .requestPermission();
                        ref.invalidate(notificationsEnabledProvider);
                      },
                    ),
                    const SizedBox(height: AppSpace.s3),
                  ],
                  const ReminderRows(),
                  const SizedBox(height: AppSpace.s3),
                  InfoRow(
                    title: t.remindersBatteryTitle,
                    subtitle: t.remindersBatteryHint,
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
