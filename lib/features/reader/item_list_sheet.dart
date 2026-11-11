import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models.dart';
import '../../data/list_prefs.dart';
import '../../design/dimens.dart';
import '../../design/extras.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/numbers.dart';
import '../shared/widgets.dart';

/// Bottom sheet listing every item of a list. The user jumps to an item, hides
/// or shows it, and reorders the list (drag handle, or long press on a row).
/// When [onDelete] is given each row also has a delete button.
Future<void> showItemListSheet(
  BuildContext context, {
  required String title,
  required String? listKey,
  required List<Item> Function() itemsOf,
  required String currentId,
  required bool Function(Item) isDone,
  required void Function(Item) onPick,
  void Function(Item)? onDelete,
}) {
  final c = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surfaceBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, scroll) => _ItemListSheet(
        title: title,
        listKey: listKey,
        itemsOf: itemsOf,
        currentId: currentId,
        isDone: isDone,
        onPick: (it) {
          Navigator.of(sheet).pop();
          onPick(it);
        },
        onDelete: onDelete,
        onClose: () => Navigator.of(sheet).pop(),
        scroll: scroll,
      ),
    ),
  );
}

class _ItemListSheet extends ConsumerStatefulWidget {
  const _ItemListSheet({
    required this.title,
    required this.listKey,
    required this.itemsOf,
    required this.currentId,
    required this.isDone,
    required this.onPick,
    required this.onDelete,
    required this.onClose,
    required this.scroll,
  });

  final String title;
  final String? listKey;
  final List<Item> Function() itemsOf;
  final String currentId;
  final bool Function(Item) isDone;
  final void Function(Item) onPick;
  final void Function(Item)? onDelete;
  final VoidCallback onClose;
  final ScrollController scroll;

  @override
  ConsumerState<_ItemListSheet> createState() => _ItemListSheetState();
}

class _ItemListSheetState extends ConsumerState<_ItemListSheet> {
  Future<void> _delete(Item it) async {
    final t = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: t.itemDeleteTitle,
      message: t.itemDeleteMessage(widget.title),
      confirm: t.itemDelete,
    );
    if (!ok || !mounted) return;
    widget.onDelete!(it);
    final key = widget.listKey;
    if (key != null) ref.read(listPrefsProvider.notifier).forget(key, it.id);
    // The parent rebuilds with the shorter list; read it again afterwards.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.itemsOf().isEmpty) {
        widget.onClose();
      } else {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final prefs = ref.watch(listPrefsProvider);
    final key = widget.listKey;
    final notifier = ref.read(listPrefsProvider.notifier);
    final all = prefs.ordered(key, widget.itemsOf(), (e) => e.id);
    final hiddenCount =
        key == null ? 0 : all.where((e) => prefs.isHidden(key, e.id)).length;
    final visibleCount = all.length - hiddenCount;
    final position = all.indexWhere((e) => e.id == widget.currentId);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.s5, AppSpace.s5, AppSpace.s5, AppSpace.s2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppType.titleSm),
                    Text(
                      [
                        t.sessionListSubtitle(arNum(position + 1)),
                        if (hiddenCount > 0) t.hiddenCount(arNum(hiddenCount)),
                      ].join(' · '),
                      style:
                          AppType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: t.close,
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        if (key != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.s5, 0, AppSpace.s5, AppSpace.s2),
            child: Row(
              children: [
                Expanded(
                  child: Text(t.listReorderHint,
                      style:
                          AppType.caption.copyWith(color: c.textSecondary)),
                ),
                if (prefs.isCustom(key))
                  TextButton(
                    onPressed: () => notifier.reset(key),
                    child: Text(t.listRestoreDefault),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ReorderableListView.builder(
            scrollController: widget.scroll,
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.fromLTRB(
                AppSpace.s5, 0, AppSpace.s5, AppSpace.s5),
            itemCount: all.length,
            onReorderItem: key == null
                ? (_, _) {}
                : (from, to) {
                    final ids = [for (final e in all) e.id];
                    ids.insert(to, ids.removeAt(from));
                    notifier.setOrder(key, ids);
                  },
            itemBuilder: (_, n) {
              final it = all[n];
              final current = it.id == widget.currentId;
              final hidden = key != null && prefs.isHidden(key, it.id);
              final fg = current ? c.onAccentWarm : c.textPrimary;
              return Padding(
                key: ValueKey(it.id),
                padding: const EdgeInsets.only(bottom: AppSpace.s2),
                child: ReorderableDelayedDragStartListener(
                  index: n,
                  child: Material(
                    color: current ? c.accentWarm : c.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      onTap: hidden ? null : () => widget.onPick(it),
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(minHeight: AppSize.controlLg),
                        child: Row(
                          children: [
                            if (key != null)
                              ReorderableDragStartListener(
                                index: n,
                                child: Tooltip(
                                  message: t.itemDragHandle,
                                  child: SizedBox(
                                    width: AppSize.touchMin,
                                    height: AppSize.touchMin,
                                    child: Icon(Icons.drag_handle,
                                        color: current
                                            ? c.onAccentWarm
                                            : c.textSecondary),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: AppSpace.s4),
                            SizedBox(
                              width: AppSize.iconXl,
                              child: widget.isDone(it)
                                  ? Icon(Icons.check_circle,
                                      size: AppSize.iconLg, color: c.accent)
                                  : Text(arNum(n + 1),
                                      style: AppType.label.copyWith(
                                          color: current
                                              ? c.onAccentWarm
                                              : c.textSecondary)),
                            ),
                            Expanded(
                              child: Opacity(
                                opacity: hidden ? AppAlpha.disabled : 1,
                                child: Text(
                                  it.listLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.body.copyWith(color: fg),
                                ),
                              ),
                            ),
                            if (key != null)
                              IconButton(
                                tooltip: hidden ? t.itemShow : t.itemHide,
                                color: fg,
                                onPressed: !hidden && visibleCount <= 1
                                    ? null
                                    : () => notifier.setHidden(
                                        key, it.id, !hidden),
                                icon: Icon(hidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                              ),
                            if (widget.onDelete != null)
                              IconButton(
                                tooltip: t.itemDelete,
                                color: c.danger,
                                onPressed: () => _delete(it),
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ),
            );
          },
        ),
      ),
    ],
  );
  }
}
