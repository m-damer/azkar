import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/arabic.dart';
import '../../content/locator.dart';
import '../../data/reminders.dart';
import '../../data/widget_entries.dart';
import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/dates.dart';
import '../../l10n/numbers.dart';
import '../duas/duas_screens.dart';
import '../favorites/favorites_screens.dart';
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

/// Settings → widget: the lists the home-screen widget cycles through.
class WidgetSettingsScreen extends ConsumerWidget {
  const WidgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final lists = ref.watch(widgetListsProvider);
    Future<void> create() async {
      final name = await showNameSheet(context,
          title: t.widgetNewList, label: t.listName, action: t.listCreate);
      if (name == null) return;
      final id = ref.read(widgetListsProvider.notifier).create(name);
      if (context.mounted) context.push('/settings/widget/list/$id');
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: t.widgetTitle),
            Expanded(
              child: lists.isEmpty
                  ? EmptyState(
                      icon: Icons.widgets_outlined,
                      title: t.widgetEmptyTitle,
                      hint: t.widgetEmptyHint,
                      action: WideButton(
                        label: t.widgetNewList,
                        icon: Icons.add,
                        onPressed: create,
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
                        for (final l in lists) ...[
                          InfoRow(
                            title: l.name,
                            subtitle: [
                              if (l.onWidget) t.widgetAssigned,
                              Nouns.item.of(l.itemIds.length),
                              t.widgetWindow(
                                  formatTime(_tod(l.from)), formatTime(_tod(l.to))),
                              if (l.itemIds.length > 1)
                                t.widgetEvery(Nouns.minute.of(l.minutes)),
                              _daysLabel(l.days),
                            ].join(' · '),
                            leading: Icon(Icons.schedule,
                                size: AppSize.iconLg, color: c.iconWarm),
                            onTap: () =>
                                context.push('/settings/widget/list/${l.id}'),
                          ),
                          const SizedBox(height: AppSpace.s3),
                        ],
                        AddTile(label: t.widgetNewList, onTap: create),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One widget list: when it shows, how long each azkar stays, and its azkar.
class WidgetListScreen extends ConsumerWidget {
  const WidgetListScreen({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final lists = ref.watch(widgetListsProvider);
    final list = lists.where((l) => l.id == listId).firstOrNull;
    if (list == null) {
      return Scaffold(body: SafeArea(child: Center(child: Text(t.notFound))));
    }
    final n = ref.read(widgetListsProvider.notifier);
    final loc = ref.watch(itemLocatorProvider);
    final refs = [for (final id in list.itemIds) if (loc[id] != null) loc[id]!];

    Future<void> pickTime(bool from) async {
      final p = await showTimeSheet(context,
          title: from ? t.widgetFrom : t.widgetTo,
          initial: _tod(from ? list.from : list.to));
      if (p == null) return;
      final m = p.hour * 60 + p.minute;
      n.update(listId, (l) => from ? l.copyWith(from: m) : l.copyWith(to: m));
    }

    Future<void> options() async {
      final action = await showAppSheet<String>(
        context,
        title: list.name,
        builder: (sheet, close) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(t.listEdit, style: AppType.label),
              onTap: () => close('rename'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: sheet.colors.danger),
              title: Text(t.listDelete,
                  style: AppType.label.copyWith(color: sheet.colors.danger)),
              onTap: () => close('delete'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (action == 'rename') {
        final name = await showNameSheet(context,
            title: t.listEdit,
            label: t.listName,
            action: t.save,
            initial: list.name);
        if (name != null) n.rename(listId, name);
      } else if (action == 'delete') {
        final ok = await confirmDialog(
          context,
          title: t.listDeleteTitle,
          message: t.widgetListDeleteMessage(list.name),
          confirm: t.listDelete,
        );
        if (ok) {
          n.delete(listId);
          if (context.mounted) context.pop();
        }
      }
    }

    final cycle = list.itemIds.length > 1
        ? t.widgetCycle(Nouns.minute.of(list.cycleMinutes))
        : t.widgetCycleOne;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: list.name,
              actions: [
                HeaderIconButton(
                  icon: Icons.more_horiz,
                  tooltip: t.listOptions,
                  onPressed: options,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.s5),
                children: [
                  Material(
                    color: c.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: SwitchListTile(
                      value: list.onWidget,
                      onChanged: (v) => n.setOnWidget(listId, v),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl)),
                      title: Text(t.widgetAssign, style: AppType.label),
                      subtitle: Text(t.widgetAssignHint,
                          style: AppType.caption
                              .copyWith(color: c.textSecondary)),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Row(
                    children: [
                      Expanded(
                        child: InfoRow(
                          title: t.widgetFrom,
                          subtitle: formatTime(_tod(list.from)),
                          trailing: const SizedBox.shrink(),
                          onTap: () => pickTime(true),
                        ),
                      ),
                      const SizedBox(width: AppSpace.s2),
                      Expanded(
                        child: InfoRow(
                          title: t.widgetTo,
                          subtitle: formatTime(_tod(list.to)),
                          trailing: const SizedBox.shrink(),
                          onTap: () => pickTime(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Text(t.widgetDays, style: AppType.label),
                  const SizedBox(height: AppSpace.s2),
                  _ChipStrip(
                    children: [
                      _FlatChip(
                        label: t.wirdEveryDay,
                        selected: list.days.length == 7,
                        onTap: () => n.update(
                            listId,
                            (l) => l.copyWith(
                                days: l.days.length == 7
                                    ? [1]
                                    : [1, 2, 3, 4, 5, 6, 7])),
                      ),
                      for (final d in weekOrder)
                        _FlatChip(
                          label: weekdayNames[d]!,
                          selected: list.days.contains(d),
                          onTap: () {
                            final days = {...list.days};
                            list.days.contains(d) ? days.remove(d) : days.add(d);
                            if (days.isNotEmpty) {
                              n.update(listId,
                                  (l) => l.copyWith(days: days.toList()..sort()));
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s5),
                  Text(t.widgetPerItemMinutes, style: AppType.label),
                  const SizedBox(height: AppSpace.s2),
                  _ChipStrip(
                    children: [
                      for (final m in widgetMinuteChoices)
                        _FlatChip(
                          label: arNum(m),
                          selected: list.minutes == m,
                          onTap: () =>
                              n.update(listId, (l) => l.copyWith(minutes: m)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s2),
                  Text(cycle,
                      style: AppType.caption.copyWith(color: c.textSecondary)),
                  const SizedBox(height: AppSpace.s6),
                  Row(
                    children: [
                      Expanded(child: Text(t.widgetItems, style: AppType.label)),
                      TextButton.icon(
                        onPressed: () =>
                            context.push('/settings/widget/list/$listId/add'),
                        icon: const Icon(Icons.add),
                        label: Text(t.widgetAdd),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s2),
                  if (refs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
                      child: Text(t.widgetListEmpty,
                          textAlign: TextAlign.center,
                          style: AppType.body.copyWith(color: c.textSecondary)),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: refs.length,
                      onReorderItem: (from, to) {
                        final order = [for (final r in refs) r.item.id];
                        order.insert(to, order.removeAt(from));
                        n.update(listId, (l) => l.copyWith(itemIds: order));
                      },
                      itemBuilder: (_, i) {
                        final r = refs[i];
                        return Padding(
                          key: ValueKey(r.item.id),
                          padding: const EdgeInsets.only(bottom: AppSpace.s3),
                          child: _WidgetItemRow(
                            index: i,
                            heading: r.item.title ?? r.chapter.title,
                            text: stripDiacritics(r.item.text),
                            onDelete: () async {
                              final ok = await confirmDialog(
                                context,
                                title: t.itemDeleteTitle,
                                message: t.itemDeleteMessage(list.name),
                                confirm: t.itemDelete,
                              );
                              if (ok) n.removeItem(listId, r.item.id);
                            },
                          ),
                        );
                      },
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

/// One flat line of chips; scrolls sideways only when it must.
class _ChipStrip extends StatelessWidget {
  const _ChipStrip({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final w in children) ...[w, const SizedBox(width: AppSpace.s2)],
        ],
      ),
    );
  }
}

class _FlatChip extends StatelessWidget {
  const _FlatChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: AppType.label),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onTap(),
    );
  }
}

class _WidgetItemRow extends StatelessWidget {
  const _WidgetItemRow({
    required this.index,
    required this.heading,
    required this.text,
    required this.onDelete,
  });

  final int index;
  final String heading;
  final String text;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return ReorderableDelayedDragStartListener(
      index: index,
      child: Material(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Tooltip(
                message: t.itemDragHandle,
                child: SizedBox(
                  width: AppSize.touchMin,
                  height: AppSize.touchMin,
                  child: Icon(Icons.drag_handle, color: c.textSecondary),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(heading,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.label.copyWith(color: c.textPrimary)),
                    Text(text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: t.itemDelete,
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: c.danger),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks azkar (sections, search, or «أدعيتي») for a widget list.
class WidgetAddPicker extends ConsumerWidget {
  const WidgetAddPicker({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final list =
        ref.watch(widgetListsProvider).where((l) => l.id == listId).firstOrNull;
    return AddToListScreen(
      title: t.widgetPickTitle,
      includeMine: true,
      existingIds: list?.itemIds.toSet() ?? {},
      onConfirm: (ids) =>
          ref.read(widgetListsProvider.notifier).addItems(listId, ids),
    );
  }
}
