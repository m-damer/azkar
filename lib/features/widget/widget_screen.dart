import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/arabic.dart';
import '../../content/locator.dart';
import '../../data/reminders.dart';
import '../../data/widget_entries.dart';
import '../../design/dimens.dart';
import '../../design/extras.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/dates.dart';
import '../shared/pickers.dart';
import '../shared/widgets.dart';

TimeOfDay _tod(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);

String _daysLabel(List<int> days) {
  if (days.length == 7) return 'كل يوم';
  return [
    for (final d in weekOrder)
      if (days.contains(d)) weekdayNames[d]!,
  ].join('، ');
}

/// Which azkar the home-screen widget shows, and when.
class WidgetSettingsScreen extends ConsumerWidget {
  const WidgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final entries = ref.watch(widgetEntriesProvider);
    final loc = ref.watch(itemLocatorProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: t.widgetTitle),
            Expanded(
              child: entries.isEmpty
                  ? EmptyState(
                      icon: Icons.widgets_outlined,
                      title: t.widgetEmptyTitle,
                      hint: t.widgetEmptyHint,
                      action: WideButton(
                        label: t.widgetAdd,
                        icon: Icons.add,
                        onPressed: () => context.push('/settings/widget/add'),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpace.s5, 0, AppSpace.s5, AppSpace.s5),
                      children: [
                        Text(t.widgetIntro,
                            style: AppType.caption
                                .copyWith(color: c.textSecondary)),
                        const SizedBox(height: AppSpace.s4),
                        for (final e in entries)
                          if (loc[e.itemId] != null) ...[
                            InfoRow(
                              title: stripDiacritics(
                                  loc[e.itemId]!.item.listLabel),
                              subtitle:
                                  '${t.widgetWindow(formatTime(_tod(e.from)), formatTime(_tod(e.to)))} · ${_daysLabel(e.days)}',
                              leading: Icon(Icons.schedule,
                                  size: AppSize.iconLg, color: c.iconWarm),
                              trailing: Icon(Icons.edit_outlined,
                                  size: AppSize.iconMd,
                                  color: c.textSecondary),
                              onTap: () => _edit(context, ref, e, t),
                            ),
                            const SizedBox(height: AppSpace.s3),
                          ],
                        AddTile(
                          label: t.widgetAdd,
                          onTap: () => context.push('/settings/widget/add'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, WidgetEntry e,
      AppLocalizations t) async {
    final n = ref.read(widgetEntriesProvider.notifier);
    await showAppSheet<void>(
      context,
      title: t.widgetTitle,
      builder: (sheet, close) => _EntryEditor(
        entry: e,
        onChanged: (x) => n.update(e.itemId, x),
        onRemove: () {
          n.remove(e.itemId);
          close(null);
        },
        onDone: () => close(null),
      ),
    );
  }
}

class _EntryEditor extends StatefulWidget {
  const _EntryEditor({
    required this.entry,
    required this.onChanged,
    required this.onRemove,
    required this.onDone,
  });

  final WidgetEntry entry;
  final ValueChanged<WidgetEntry> onChanged;
  final VoidCallback onRemove;
  final VoidCallback onDone;

  @override
  State<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<_EntryEditor> {
  late WidgetEntry _e = widget.entry;

  void _set(WidgetEntry x) {
    setState(() => _e = x);
    widget.onChanged(x);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    Future<void> pick(bool from) async {
      final p = await showTimeSheet(context,
          title: from ? t.widgetFrom : t.widgetTo,
          initial: _tod(from ? _e.from : _e.to));
      if (p == null) return;
      final m = p.hour * 60 + p.minute;
      _set(from ? _e.copyWith(from: m) : _e.copyWith(to: m));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: InfoRow(
                title: t.widgetFrom,
                subtitle: formatTime(_tod(_e.from)),
                trailing: const SizedBox.shrink(),
                onTap: () => pick(true),
              ),
            ),
            const SizedBox(width: AppSpace.s2),
            Expanded(
              child: InfoRow(
                title: t.widgetTo,
                subtitle: formatTime(_tod(_e.to)),
                trailing: const SizedBox.shrink(),
                onTap: () => pick(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s4),
        Text(t.widgetDays, style: AppType.label),
        const SizedBox(height: AppSpace.s2),
        Wrap(
          spacing: AppSpace.s2,
          children: [
            ChoiceChip(
              label: Text(t.wirdEveryDay, style: AppType.label),
              selected: _e.days.length == 7,
              onSelected: (_) => _set(_e.copyWith(
                  days: _e.days.length == 7 ? [1] : [1, 2, 3, 4, 5, 6, 7])),
            ),
            for (final d in weekOrder)
              ChoiceChip(
                label: Text(weekdayNames[d]!, style: AppType.label),
                selected: _e.days.contains(d),
                onSelected: (v) {
                  final days = {..._e.days};
                  v ? days.add(d) : days.remove(d);
                  if (days.isNotEmpty) _set(_e.copyWith(days: days.toList()..sort()));
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s5),
        WideButton(label: t.done, onPressed: widget.onDone),
        const SizedBox(height: AppSpace.s2),
        TextButton(
          onPressed: widget.onRemove,
          child: Text(t.widgetRemove,
              style: AppType.label.copyWith(color: c.danger)),
        ),
      ],
    );
  }
}
