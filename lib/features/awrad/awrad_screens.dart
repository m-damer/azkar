import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/library.dart';
import '../../design/dimens.dart';
import '../../design/extras.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/numbers.dart';
import '../../data/progress.dart';
import '../../data/reminders.dart';
import '../../data/wird_lists.dart';
import '../../l10n/dates.dart';
import '../../services/reminder_service.dart';
import '../duas/duas_screens.dart' show showNameSheet;
import '../sessions/session.dart';
import '../shared/pickers.dart';
import '../shared/widgets.dart';

const _targets = [33, 100, 500, 1000];

/// The awrad tab: the user's own daily counters.
class AwradScreen extends ConsumerWidget {
  const AwradScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final state = ref.watch(awradProvider);
    final lists = ref.watch(wirdListsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.s6),
              Text(t.navAwrad, style: AppType.titleSm),
              Text(t.awradSubtitle,
                  style: AppType.body.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpace.s4),
              WideButton(
                label: t.awradAdd,
                icon: Icons.add,
                onPressed: () => context.push('/awrad/new'),
              ),
              const SizedBox(height: AppSpace.s3),
              WideButton(
                label: t.listNew,
                icon: Icons.playlist_add,
                outlined: true,
                onPressed: () => _newList(context, ref),
              ),
              const SizedBox(height: AppSpace.s4),
              Expanded(
                child: state.awrad.isEmpty && lists.isEmpty
                    ? EmptyState(
                        icon: Icons.add_circle_outline,
                        title: t.awradEmptyTitle,
                        hint: t.awradEmptyHint,
                      )
                    : ListView(
                        children: [
                          for (final w in state.awrad) ...[
                            _WirdRow(wird: w, count: state.countOf(w.id)),
                            const SizedBox(height: AppSpace.s3),
                          ],
                          if (lists.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.s2),
                            Text(t.listsTitle, style: AppType.label),
                            const SizedBox(height: AppSpace.s3),
                            for (final l in lists) ...[
                              InfoRow(
                                title: l.name,
                                subtitle: Nouns.wird.of(l.wirdIds
                                    .where((id) => state.awrad
                                        .any((w) => w.id == id))
                                    .length),
                                leading: Icon(Icons.list_alt,
                                    size: AppSize.iconLg, color: c.iconWarm),
                                onTap: () =>
                                    context.push('/awrad/list/${l.id}'),
                              ),
                              const SizedBox(height: AppSpace.s3),
                            ],
                          ],
                          const SizedBox(height: AppSpace.s5),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _newList(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final name = await showNameSheet(context,
        title: t.listNew, label: t.listName, action: t.listCreate);
    if (name == null) return;
    final id = ref.read(wirdListsProvider.notifier).create(name);
    if (context.mounted) context.push('/awrad/list/$id');
  }
}

class _WirdRow extends ConsumerWidget {
  const _WirdRow({required this.wird, required this.count});

  final Wird wird;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final done = count >= wird.target;
    return Material(
      color: done ? c.tileDone : c.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: () => context.push('/awrad/${wird.id}'),
        onLongPress: () => showWirdOptions(context, ref, wird),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.s4, AppSpace.s3, AppSpace.s3, AppSpace.s3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            wird.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.label.copyWith(
                                color: done ? c.onTileDone : c.textPrimary),
                          ),
                        ),
                        Text(
                          t.awradProgress(arNum(count), arNum(wird.target)),
                          style: AppType.caption.copyWith(
                              color:
                                  done ? c.onTileDone : c.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s2),
                    BarProgress(
                      value: count / wird.target,
                      color: done ? c.onTileDone : c.accent,
                      track: done
                          ? c.onTileDone.withValues(alpha: AppAlpha.track)
                          : c.borderSubtle,
                    ),
                    if (wird.reminder != null) ...[
                      const SizedBox(height: AppSpace.s2),
                      Row(
                        children: [
                          Icon(Icons.notifications_none,
                              size: AppSize.iconMd,
                              color: done ? c.onTileDone : c.textSecondary),
                          const SizedBox(width: AppSpace.s1),
                          Expanded(
                            child: Text(
                              reminderSummary(
                                  wird.reminder!, ref.watch(nowProvider)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.caption.copyWith(
                                  color: done
                                      ? c.onTileDone
                                      : c.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.s3),
              IconButton.filled(
                tooltip: t.awradCount(wird.name),
                style: IconButton.styleFrom(
                  backgroundColor: done ? c.onTileDone : c.accent,
                  foregroundColor: done ? c.tileDone : c.onAccent,
                  minimumSize: const Size.square(AppSize.controlMd),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(awradProvider.notifier).setCount(wird.id, count + 1);
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edit / reset / delete a wird.
Future<void> showWirdOptions(
    BuildContext context, WidgetRef ref, Wird wird) async {
  final t = AppLocalizations.of(context);
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: context.colors.surfaceBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (s) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(wird.name, style: AppType.titleSm),
            const SizedBox(height: AppSpace.s3),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(t.awradEdit, style: AppType.label),
              onTap: () => Navigator.of(s).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: Text(t.awradResetToday, style: AppType.label),
              onTap: () => Navigator.of(s).pop('reset'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: s.colors.danger),
              title: Text(t.awradDelete,
                  style: AppType.label.copyWith(color: s.colors.danger)),
              onTap: () => Navigator.of(s).pop('delete'),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted) return;
  final n = ref.read(awradProvider.notifier);
  switch (action) {
    case 'edit':
      context.push('/awrad/edit/${wird.id}');
    case 'reset':
      n.setCount(wird.id, 0);
    case 'delete':
      final ok = await confirmDialog(
        context,
        title: t.awradDeleteTitle,
        message: t.awradDeleteMessage(wird.name),
        confirm: t.awradDelete,
      );
      if (ok) {
        n.delete(wird.id);
        ref.read(wirdListsProvider.notifier).forgetWird(wird.id);
        ref
            .read(reminderServiceProvider)
            .scheduleAwrad(ref.read(awradProvider).awrad);
      }
  }
}

/// Create or edit a wird.
class WirdFormScreen extends ConsumerStatefulWidget {
  const WirdFormScreen({super.key, this.wirdId, this.listId});

  final String? wirdId;

  /// A list to put the new wird in.
  final String? listId;

  @override
  ConsumerState<WirdFormScreen> createState() => _WirdFormState();
}

class _WirdFormState extends ConsumerState<WirdFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  bool _remind = false;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  bool _once = false;
  DateTime? _date;
  final Set<int> _days = {1, 2, 3, 4, 5, 6, 7};

  @override
  void initState() {
    super.initState();
    final w = widget.wirdId == null
        ? null
        : ref.read(awradProvider).byId(widget.wirdId!);
    _name = TextEditingController(text: w?.name ?? '');
    _target = TextEditingController(text: '${w?.target ?? 100}');
    final r = w?.reminder;
    if (r != null) {
      _remind = true;
      _time = TimeOfDay(hour: r.hour, minute: r.minute);
      _once = r.once;
      _date = r.onceDate;
      _days
        ..clear()
        ..addAll(r.days);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_target.text.trim()) ?? 0;

  bool get _reminderValid => !_remind || _once || _days.isNotEmpty;

  Future<void> _save() async {
    final n = ref.read(awradProvider.notifier);
    final svc = ref.read(reminderServiceProvider);
    final now = ref.read(nowProvider);
    WirdReminder? r;
    if (_remind) {
      final d = _date ?? DateTime(now.year, now.month, now.day);
      r = WirdReminder(
        minutes: _time.hour * 60 + _time.minute,
        once: _once,
        date: _once ? dayKey(d) : null,
        days: _days.toList()..sort(),
      );
      await svc.requestPermission();
    }
    if (widget.wirdId == null) {
      final id = n.add(_name.text, _value, reminder: r);
      if (widget.listId != null) {
        ref.read(wirdListsProvider.notifier).addWirds(widget.listId!, [id]);
      }
    } else {
      n.edit(widget.wirdId!, _name.text, _value, reminder: r);
    }
    await svc.scheduleAwrad(ref.read(awradProvider).awrad);
    if (mounted) context.pop();
  }

  Widget _reminderSection(AppLocalizations t) {
    final c = context.colors;
    final now = ref.watch(nowProvider);
    Widget segment(String label, bool selected, VoidCallback onTap) => Expanded(
          child: ChoiceChip(
            label: SizedBox(
                width: double.infinity,
                child: Text(label,
                    textAlign: TextAlign.center, style: AppType.label)),
            selected: selected,
            onSelected: (_) => onTap(),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _remind,
          title: Text(t.wirdRemind, style: AppType.label),
          subtitle: Text(t.wirdRemindHint,
              style: AppType.caption.copyWith(color: c.textSecondary)),
          onChanged: (v) => setState(() => _remind = v),
        ),
        if (_remind) ...[
          InfoRow(
            title: t.wirdTime,
            subtitle: formatTime(_time),
            leading: const Icon(Icons.schedule),
            trailing: const Icon(Icons.edit_outlined, size: AppSize.iconMd),
            onTap: () async {
              final p = await showTimeSheet(context,
                  title: t.wirdPickTime, initial: _time);
              if (p != null) setState(() => _time = p);
            },
          ),
          const SizedBox(height: AppSpace.s3),
          Row(
            children: [
              segment(t.wirdOnce, _once, () => setState(() => _once = true)),
              const SizedBox(width: AppSpace.s2),
              segment(
                  t.wirdRepeat, !_once, () => setState(() => _once = false)),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          if (_once)
            InfoRow(
              title: t.wirdDate,
              subtitle: dayLabel(_date ?? now, now),
              leading: const Icon(Icons.event),
              trailing: const Icon(Icons.edit_outlined, size: AppSize.iconMd),
              onTap: () async {
                final p = await showDaySheet(context,
                    title: t.wirdPickDay, today: now, initial: _date);
                if (p != null) setState(() => _date = p);
              },
            )
          else ...[
            Text(t.wirdDays, style: AppType.label),
            const SizedBox(height: AppSpace.s2),
            Wrap(
              spacing: AppSpace.s2,
              children: [
                ChoiceChip(
                  label: Text(t.wirdEveryDay, style: AppType.label),
                  selected: _days.length == 7,
                  onSelected: (_) => setState(() {
                    if (_days.length == 7) {
                      _days.clear();
                    } else {
                      _days.addAll([1, 2, 3, 4, 5, 6, 7]);
                    }
                  }),
                ),
                for (final d in weekOrder)
                  ChoiceChip(
                    label: Text(weekdayNames[d]!, style: AppType.label),
                    selected: _days.contains(d),
                    onSelected: (v) => setState(() {
                      v ? _days.add(d) : _days.remove(d);
                    }),
                  ),
              ],
            ),
            if (_days.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.s2),
                child: Text(t.wirdNeedDay,
                    style: AppType.caption.copyWith(color: c.danger)),
              ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final valid = _name.text.trim().isNotEmpty && _value > 0;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
                title: widget.wirdId == null ? t.awradNew : t.awradEdit),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.s5),
                children: [
                  Text(t.awradName, style: AppType.label),
                  const SizedBox(height: AppSpace.s2),
                  TextField(
                    controller: _name,
                    style: AppType.body.copyWith(color: c.textPrimary),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: t.awradNameHint,
                      filled: true,
                      fillColor: c.surfaceRaised,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s5),
                  Text(t.awradTarget, style: AppType.label),
                  const SizedBox(height: AppSpace.s2),
                  TextField(
                    controller: _target,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppType.body.copyWith(color: c.textPrimary),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: c.surfaceRaised,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s3),
                  Wrap(
                    spacing: AppSpace.s2,
                    children: [
                      for (final v in _targets)
                        ChoiceChip(
                          label: Text(arNum(v), style: AppType.label),
                          selected: _value == v,
                          onSelected: (_) =>
                              setState(() => _target.text = '$v'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s5),
                  Text(t.awradRenews,
                      style: AppType.caption.copyWith(color: c.textSecondary)),
                  const SizedBox(height: AppSpace.s5),
                  _reminderSection(t),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.s5),
              child: WideButton(
                label: t.awradSave,
                onPressed: valid && _reminderValid ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen counter for one wird.
class WirdCounterScreen extends ConsumerWidget {
  const WirdCounterScreen({super.key, required this.wirdId});

  final String wirdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final state = ref.watch(awradProvider);
    final wird = state.byId(wirdId);
    if (wird == null) {
      return Scaffold(body: SafeArea(child: Center(child: Text(t.notFound))));
    }
    final count = state.countOf(wirdId);
    final done = count >= wird.target;
    final bg = done ? c.tileDone : c.surfaceBase;
    final fg = done ? c.onTileDone : c.textPrimary;
    final n = ref.read(awradProvider.notifier);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s5),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton.filled(
                    tooltip: t.close,
                    style: IconButton.styleFrom(
                      backgroundColor: fg,
                      foregroundColor: bg,
                      minimumSize: const Size.square(AppSize.touchMin),
                    ),
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Text(
                      wird.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.heading.copyWith(color: fg),
                    ),
                  ),
                  const SizedBox(width: AppSize.touchMin),
                ],
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: t.awradCount(wird.name),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      n.setCount(wirdId, count + 1);
                    },
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (done)
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpace.s3),
                              child: Text(t.awradDone,
                                  style: AppType.heading.copyWith(color: fg)),
                            ),
                          Text(arNum(count),
                              style: AppType.displayXl.copyWith(color: fg)),
                          Text(t.awradOf(arNum(wird.target)),
                              style: AppType.body.copyWith(color: fg)),
                          const SizedBox(height: AppSpace.s4),
                          if (!done)
                            Text(t.counterTap,
                                style: AppType.caption.copyWith(color: fg)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _Pill(
                      icon: Icons.undo,
                      label: t.awradUndo,
                      fg: fg,
                      onTap: () => n.setCount(wirdId, count - 1),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: _Pill(
                      icon: Icons.restart_alt,
                      label: t.awradReset,
                      fg: fg,
                      onTap: () => n.setCount(wirdId, 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s5),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.controlLg,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: fg, width: AppStroke.md),
          shape: const StadiumBorder(),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: AppType.label),
      ),
    );
  }
}

/// One list of awrad. Edit controls show only after «تعديل القائمة».
class WirdListScreen extends ConsumerStatefulWidget {
  const WirdListScreen({super.key, required this.listId});

  final String listId;

  @override
  ConsumerState<WirdListScreen> createState() => _WirdListState();
}

class _WirdListState extends ConsumerState<WirdListScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final lists = ref.watch(wirdListsProvider);
    final state = ref.watch(awradProvider);
    final list = lists.where((l) => l.id == widget.listId).firstOrNull;
    if (list == null) {
      return Scaffold(body: SafeArea(child: Center(child: Text(t.notFound))));
    }
    final wirds = [
      for (final id in list.wirdIds)
        for (final w in state.awrad)
          if (w.id == id) w,
    ];
    final n = ref.read(wirdListsProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: list.name,
              actions: [
                HeaderIconButton(
                  icon: _editing ? Icons.check : Icons.more_horiz,
                  tooltip: _editing ? t.done : t.listOptions,
                  onPressed: _editing
                      ? () => setState(() => _editing = false)
                      : () => _options(context, list),
                ),
              ],
            ),
            if (_editing)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.s5, 0, AppSpace.s5, AppSpace.s3),
                child: InfoRow(
                  title: t.listName,
                  subtitle: list.name,
                  leading: const Icon(Icons.edit_outlined),
                  onTap: () => _rename(context, list),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(Nouns.wird.of(wirds.length),
                        style:
                            AppType.caption.copyWith(color: c.textSecondary)),
                  ),
                  TextButton.icon(
                    onPressed: () => _add(context, list),
                    icon: const Icon(Icons.add),
                    label: Text(t.listAdd),
                  ),
                ],
              ),
            ),
            Expanded(
              child: wirds.isEmpty
                  ? EmptyState(
                      icon: Icons.bookmark_border,
                      title: t.listEmptyTitle,
                      hint: t.wirdListEmptyHint,
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.fromLTRB(
                          AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s5),
                      itemCount: wirds.length,
                      onReorderItem: (from, to) {
                        final order = [for (final w in wirds) w.id];
                        order.insert(to, order.removeAt(from));
                        n.reorder(list.id, order);
                      },
                      itemBuilder: (_, i) {
                        final w = wirds[i];
                        final row = _WirdRow(
                            wird: w, count: state.countOf(w.id));
                        return Padding(
                          key: ValueKey(w.id),
                          padding: const EdgeInsets.only(bottom: AppSpace.s3),
                          child: _editing
                              ? Row(
                                  children: [
                                    ReorderableDragStartListener(
                                      index: i,
                                      child: SizedBox(
                                        width: AppSize.touchMin,
                                        height: AppSize.touchMin,
                                        child: Icon(Icons.drag_handle,
                                            color: c.textSecondary),
                                      ),
                                    ),
                                    Expanded(child: row),
                                    IconButton(
                                      tooltip: t.itemDelete,
                                      onPressed: () =>
                                          n.removeWird(list.id, w.id),
                                      icon: Icon(Icons.delete_outline,
                                          color: c.danger),
                                    ),
                                  ],
                                )
                              : row,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WirdList list) async {
    final t = AppLocalizations.of(context);
    final name = await showNameSheet(context,
        title: t.listEdit,
        label: t.listName,
        action: t.save,
        initial: list.name);
    if (name != null) ref.read(wirdListsProvider.notifier).rename(list.id, name);
  }

  Future<void> _options(BuildContext context, WirdList list) async {
    final t = AppLocalizations.of(context);
    final action = await showAppSheet<String>(
      context,
      title: list.name,
      builder: (sheet, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(t.listEdit, style: AppType.label),
            onTap: () => close('edit'),
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
    if (action == 'edit') {
      setState(() => _editing = true);
    } else if (action == 'delete') {
      final ok = await confirmDialog(
        context,
        title: t.listDeleteTitle,
        message: t.wirdListDeleteMessage,
        confirm: t.listDelete,
      );
      if (ok) {
        ref.read(wirdListsProvider.notifier).delete(list.id);
        if (context.mounted) context.pop();
      }
    }
  }

  Future<void> _add(BuildContext context, WirdList list) async {
    final t = AppLocalizations.of(context);
    final action = await showAppSheet<String>(
      context,
      title: t.wirdAddTitle,
      builder: (sheet, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(t.wirdAddNew, style: AppType.label),
            onTap: () => close('new'),
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: Text(t.wirdAddExisting, style: AppType.label),
            onTap: () => close('existing'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (action == 'new') {
      context.push('/awrad/new?list=${list.id}');
    } else if (action == 'existing') {
      final others = [
        for (final w in ref.read(awradProvider).awrad)
          if (!list.wirdIds.contains(w.id)) w,
      ];
      final picked = await showAppSheet<List<String>>(
        context,
        title: t.wirdAddExisting,
        builder: (sheet, close) => _WirdPicker(wirds: others, onDone: close),
      );
      if (picked != null && picked.isNotEmpty) {
        ref.read(wirdListsProvider.notifier).addWirds(list.id, picked);
      }
    }
  }
}

class _WirdPicker extends StatefulWidget {
  const _WirdPicker({required this.wirds, required this.onDone});

  final List<Wird> wirds;
  final void Function(List<String>?) onDone;

  @override
  State<_WirdPicker> createState() => _WirdPickerState();
}

class _WirdPickerState extends State<_WirdPicker> {
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (widget.wirds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Text(t.wirdPickEmpty),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final w in widget.wirds)
          CheckboxListTile(
            value: _picked.contains(w.id),
            title: Text(w.name, style: AppType.label),
            onChanged: (v) => setState(
                () => v == true ? _picked.add(w.id) : _picked.remove(w.id)),
          ),
        const SizedBox(height: AppSpace.s3),
        WideButton(
          label: t.listAdd,
          icon: Icons.add,
          onPressed:
              _picked.isEmpty ? null : () => widget.onDone(_picked.toList()),
        ),
      ],
    );
  }
}
