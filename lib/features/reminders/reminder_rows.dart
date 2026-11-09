import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reminders.dart';
import '../../design/dimens.dart';
import '../../l10n/app_localizations.dart';
import '../sessions/session.dart';
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
        for (final k in SessionKind.values) ...[
          InfoRow(
            title: k.name(t),
            subtitle: formatTime(times.of(k)),
            leading: Icon(k.icon),
            trailing: const Icon(Icons.edit_outlined, size: AppSize.iconMd),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: times.of(k),
                helpText: k.name(t),
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

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s5),
          children: [
            const SizedBox(height: AppSpace.s6),
            Text(t.navReminders, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: AppSpace.s1),
            Text(t.remindersSubtitle,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpace.s5),
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
    );
  }
}
