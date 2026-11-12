import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/locator.dart';
import '../../data/list_prefs.dart';
import '../../data/my_duas.dart';
import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/numbers.dart';
import '../favorites/favorites_screens.dart';
import '../reader/reader_screen.dart';
import '../shared/widgets.dart';

/// Tab «أدعيتي»: duas added straight to the page, plus the user's lists.
class MyDuasScreen extends ConsumerWidget {
  const MyDuasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final my = ref.watch(myDuasProvider);
    final empty = my.loose.isEmpty && my.lists.isEmpty;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.s6),
              Text(t.navMyDuas, style: AppType.titleSm),
              Text(t.myDuasSubtitle,
                  style: AppType.body.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpace.s4),
              WideButton(
                label: t.duaAdd,
                icon: Icons.add,
                onPressed: () => startAddDua(context, ref),
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
                child: empty
                    ? EmptyState(
                        icon: Icons.volunteer_activism_outlined,
                        title: t.myDuasEmptyTitle,
                        hint: t.myDuasEmptyHint,
                      )
                    : ListView(
                        children: [
                          if (my.loose.isNotEmpty) ...[
                            InfoRow(
                              title: t.myDuasDirect,
                              subtitle: Nouns.item.of(my.loose.length),
                              leading: Icon(Icons.volunteer_activism_outlined,
                                  size: AppSize.iconLg, color: c.iconWarm),
                              onTap: () => context.push('/duas/all'),
                            ),
                            const SizedBox(height: AppSpace.s5),
                          ],
                          if (my.lists.isNotEmpty) ...[
                            Text(t.listsTitle, style: AppType.label),
                            const SizedBox(height: AppSpace.s3),
                            for (final l in my.lists) ...[
                              InfoRow(
                                title: l.name,
                                subtitle: Nouns.item.of(l.itemIds.length),
                                leading: Icon(Icons.list_alt,
                                    size: AppSize.iconLg, color: c.iconWarm),
                                onTap: () => context.push('/duas/list/${l.id}'),
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
    final id = ref.read(myDuasProvider.notifier).createList(name);
    if (context.mounted) context.push('/duas/list/$id');
  }
}

/// One list, or the duas added straight to the page when [listId] is null.
class MyListScreen extends ConsumerWidget {
  const MyListScreen({super.key, this.listId});

  final String? listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final my = ref.watch(myDuasProvider);
    final loc = ref.watch(itemLocatorProvider);
    final list = listId == null ? null : my.list(listId!);
    if (listId != null && list == null) {
      return Scaffold(body: SafeArea(child: Center(child: Text(t.notFound))));
    }
    final key = 'duas:${listId ?? 'all'}';
    final prefs = ref.watch(listPrefsProvider);
    final prefsNotifier = ref.read(listPrefsProvider.notifier);
    final ids = prefs.ordered(key, list?.itemIds ?? my.loose, (e) => e);
    final refs = [for (final id in ids) if (loc[id] != null) loc[id]!];
    final hiddenCount = refs.where((r) => prefs.isHidden(key, r.item.id)).length;
    final title = list?.name ?? t.myDuasDirect;
    final readPath = '/duas/read/${listId ?? 'all'}';
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: title,
              actions: [
                if (list != null)
                  HeaderIconButton(
                    icon: Icons.more_horiz,
                    tooltip: t.listOptions,
                    onPressed: () => _options(context, ref, list),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                        [
                          Nouns.item.of(refs.length),
                          if (hiddenCount > 0) t.hiddenCount(arNum(hiddenCount)),
                        ].join(' · '),
                        style: AppType.caption.copyWith(color: c.textSecondary)),
                  ),
                  if (prefs.isCustom(key))
                    TextButton(
                      onPressed: () => prefsNotifier.reset(key),
                      child: Text(t.listRestoreDefault),
                    ),
                  TextButton.icon(
                    onPressed: () => startAddDua(context, ref, listId: listId),
                    icon: const Icon(Icons.add),
                    label: Text(t.listAdd),
                  ),
                ],
              ),
            ),
            if (refs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s3),
                child: WideButton(
                  label: t.listStartReading,
                  icon: Icons.play_arrow,
                  onPressed: () => context.push(readPath),
                ),
              ),
            Expanded(
              child: refs.isEmpty
                  ? EmptyState(
                      icon: Icons.bookmark_border,
                      title: t.listEmptyTitle,
                      hint: t.myListEmptyHint,
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.fromLTRB(
                          AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s5),
                      itemCount: refs.length,
                      onReorderItem: (from, to) {
                        final order = [for (final r in refs) r.item.id];
                        order.insert(to, order.removeAt(from));
                        prefsNotifier.setOrder(key, order);
                      },
                      itemBuilder: (_, i) {
                        final r = refs[i];
                        final hidden = prefs.isHidden(key, r.item.id);
                        final own = r.chapter.id == myDuasChapterId;
                        return Padding(
                          key: ValueKey(r.item.id),
                          padding: const EdgeInsets.only(bottom: AppSpace.s3),
                          child: ItemRow(
                            index: i,
                            item: r.item,
                            heading: r.item.title ?? r.chapter.title,
                            hidden: hidden,
                            canHide: hidden || refs.length - hiddenCount > 1,
                            onTap: () => context.push('$readPath?i=$i'),
                            onToggleHide: () => prefsNotifier.setHidden(
                                key, r.item.id, !hidden),
                            onEdit: own
                                ? () => showDuaForm(context, ref,
                                    existing: my.dua(r.item.id))
                                : null,
                            onDelete: () async {
                              final ok = await confirmDialog(
                                context,
                                title: t.myItemDeleteTitle,
                                message: t.myItemDeleteMessage(title),
                                confirm: t.itemDelete,
                              );
                              if (!ok) return;
                              ref
                                  .read(myDuasProvider.notifier)
                                  .remove(r.item.id, listId: listId);
                              prefsNotifier.forget(key, r.item.id);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _options(
      BuildContext context, WidgetRef ref, UserList list) async {
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
      if (name != null) {
        ref.read(myDuasProvider.notifier).renameList(list.id, name);
      }
    } else if (action == 'delete') {
      final ok = await confirmDialog(
        context,
        title: t.listDeleteTitle,
        message: t.myListDeleteMessage(list.name),
        confirm: t.listDelete,
      );
      if (ok) {
        ref.read(myDuasProvider.notifier).deleteList(list.id);
        if (context.mounted) context.pop();
      }
    }
  }
}

/// Reads a list of the user's duas.
class MyReader extends ConsumerWidget {
  const MyReader({super.key, required this.listId, this.index = 0});

  final String listId;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final my = ref.watch(myDuasProvider);
    final loc = ref.watch(itemLocatorProvider);
    final list = listId == 'all' ? null : my.list(listId);
    final key = 'duas:$listId';
    final ids = ref
        .watch(listPrefsProvider)
        .ordered(key, list?.itemIds ?? my.loose, (e) => e);
    final refs = [for (final id in ids) if (loc[id] != null) loc[id]!];
    final items = [for (final r in refs) r.item];
    if (items.isEmpty) {
      return Scaffold(body: SafeArea(child: Center(child: Text(t.notFound))));
    }
    return ReaderScreen(
      title: list?.name ?? t.myDuasDirect,
      items: items,
      headings: [for (final r in refs) r.item.title ?? r.chapter.title],
      initialIndex: index.clamp(0, items.length - 1),
      listKey: key,
      onDelete: (it) => ref
          .read(myDuasProvider.notifier)
          .remove(it.id, listId: list?.id),
    );
  }
}

/// Picks built-in azkar (search or sections) for the page or a list.
class MyAddPicker extends ConsumerWidget {
  const MyAddPicker({super.key, this.listId});

  final String? listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final my = ref.watch(myDuasProvider);
    final existing = (listId == null ? my.loose : my.list(listId!)?.itemIds ?? [])
        .toSet();
    return AddToListScreen(
      title: t.duaFromApp,
      existingIds: existing,
      onConfirm: (ids) =>
          ref.read(myDuasProvider.notifier).addMany(ids, listId: listId),
    );
  }
}

/// «Add a dua»: write one, or choose from the app. [listId] null = the page.
Future<void> startAddDua(BuildContext context, WidgetRef ref,
    {String? listId}) async {
  final t = AppLocalizations.of(context);
  final choice = await showAppSheet<String>(
    context,
    title: t.duaAdd,
    builder: (sheet, close) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoRow(
          title: t.duaFromApp,
          subtitle: t.duaFromAppHint,
          leading: const Icon(Icons.search),
          onTap: () => close('app'),
        ),
        const SizedBox(height: AppSpace.s3),
        InfoRow(
          title: t.duaWrite,
          subtitle: t.duaWriteHint,
          leading: const Icon(Icons.edit_outlined),
          onTap: () => close('write'),
        ),
      ],
    ),
  );
  if (!context.mounted || choice == null) return;
  if (choice == 'app') {
    context.push(listId == null ? '/duas/all/add' : '/duas/list/$listId/add');
  } else {
    await showDuaForm(context, ref, listId: listId);
  }
}

/// Name + text form for a dua the user writes (or edits).
Future<void> showDuaForm(BuildContext context, WidgetRef ref,
    {CustomDua? existing, String? listId}) async {
  final t = AppLocalizations.of(context);
  final name = TextEditingController(text: existing?.name ?? '');
  final text = TextEditingController(text: existing?.text ?? '');
  final saved = await showAppSheet<bool>(
    context,
    title: existing == null ? t.duaNew : t.duaEditTitle,
    builder: (sheet, close) => StatefulBuilder(
      builder: (ctx, setState) {
        final ready =
            name.text.trim().isNotEmpty && text.text.trim().isNotEmpty;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              style: AppType.body,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: t.duaName),
            ),
            const SizedBox(height: AppSpace.s3),
            TextField(
              controller: text,
              minLines: 4,
              maxLines: 8,
              style: AppType.body,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: t.duaText),
            ),
            const SizedBox(height: AppSpace.s4),
            WideButton(
              label: t.save,
              onPressed: ready ? () => close(true) : null,
            ),
            const SizedBox(height: AppSpace.s2),
            TextButton(onPressed: () => close(false), child: Text(t.cancel)),
          ],
        );
      },
    ),
  );
  if (saved != true) return;
  final n = ref.read(myDuasProvider.notifier);
  if (existing == null) {
    n.addCustom(name.text, text.text, listId: listId);
  } else {
    n.editCustom(existing.id, name.text, text.text);
  }
}

/// One-field sheet for naming a list. Null when cancelled or left empty.
Future<String?> showNameSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String action,
  String initial = '',
}) async {
  final t = AppLocalizations.of(context);
  final ctrl = TextEditingController(text: initial);
  final ok = await showAppSheet<bool>(
    context,
    title: title,
    builder: (sheet, close) => StatefulBuilder(
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            style: AppType.body,
            onChanged: (_) => setState(() {}),
            decoration:
                InputDecoration(labelText: label, hintText: t.nameHint),
          ),
          const SizedBox(height: AppSpace.s4),
          WideButton(
            label: action,
            onPressed: ctrl.text.trim().isEmpty ? null : () => close(true),
          ),
          const SizedBox(height: AppSpace.s2),
          TextButton(onPressed: () => close(false), child: Text(t.cancel)),
        ],
      ),
    ),
  );
  final v = ctrl.text.trim();
  return ok == true && v.isNotEmpty ? v : null;
}
