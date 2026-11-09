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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.s6),
              Text(t.navAwrad, style: AppType.titleLg),
              Text(t.awradSubtitle,
                  style: AppType.body.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpace.s4),
              Expanded(
                child: state.awrad.isEmpty
                    ? EmptyState(
                        icon: Icons.add_circle_outline,
                        title: t.awradEmptyTitle,
                        hint: t.awradEmptyHint,
                        action: WideButton(
                          label: t.awradAdd,
                          icon: Icons.add,
                          onPressed: () => context.push('/awrad/new'),
                        ),
                      )
                    : ListView(
                        children: [
                          for (final w in state.awrad) ...[
                            _WirdRow(wird: w, count: state.countOf(w.id)),
                            const SizedBox(height: AppSpace.s3),
                          ],
                          AddTile(
                            label: t.awradAdd,
                            onTap: () => context.push('/awrad/new'),
                          ),
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
                          t.awradProgress(count, wird.target),
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
      if (ok) n.delete(wird.id);
  }
}

/// Create or edit a wird.
class WirdFormScreen extends ConsumerStatefulWidget {
  const WirdFormScreen({super.key, this.wirdId});

  final String? wirdId;

  @override
  ConsumerState<WirdFormScreen> createState() => _WirdFormState();
}

class _WirdFormState extends ConsumerState<WirdFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _target;

  @override
  void initState() {
    super.initState();
    final w = widget.wirdId == null
        ? null
        : ref.read(awradProvider).byId(widget.wirdId!);
    _name = TextEditingController(text: w?.name ?? '');
    _target = TextEditingController(text: '${w?.target ?? 100}');
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_target.text.trim()) ?? 0;

  void _save() {
    final n = ref.read(awradProvider.notifier);
    if (widget.wirdId == null) {
      n.add(_name.text, _value);
    } else {
      n.edit(widget.wirdId!, _name.text, _value);
    }
    context.pop();
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
                          label: Text('$v', style: AppType.label),
                          selected: _value == v,
                          onSelected: (_) =>
                              setState(() => _target.text = '$v'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s5),
                  Text(t.awradRenews,
                      style: AppType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.s5),
              child: WideButton(
                label: t.awradSave,
                onPressed: valid ? _save : null,
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
                          Text('$count',
                              style: AppType.displayXl.copyWith(color: fg)),
                          Text(t.awradOf(wird.target),
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
