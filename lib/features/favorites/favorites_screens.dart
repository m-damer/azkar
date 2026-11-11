import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/locator.dart';
import '../../content/models.dart';
import '../../data/library.dart';
import '../../design/dimens.dart';
import '../../design/extras.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/numbers.dart';
import '../reader/reader_screen.dart';
import '../shared/widgets.dart';
import 'list_colors.dart';

export 'list_picker.dart';

/// Favourites home: the general favourites plus the user's lists.
class FavsScreen extends ConsumerWidget {
  const FavsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final lib = ref.watch(libraryProvider);
    final empty =
        lib.favorites.isEmpty && lib.lists.isEmpty && lib.links.isEmpty;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: t.favsTitle),
            Expanded(
              child: empty
                  ? EmptyState(
                      icon: Icons.favorite_border,
                      title: t.favsEmptyTitle,
                      hint: t.favsEmptyHint,
                      action: Column(
                        children: [
                          WideButton(
                            label: t.favsBrowse,
                            onPressed: () => context.go('/s/s1'),
                          ),
                          const SizedBox(height: AppSpace.s3),
                          WideButton(
                            label: t.listNew,
                            outlined: true,
                            icon: Icons.add,
                            onPressed: () => _newList(context, ref),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpace.s5, 0,
                          AppSpace.s5, AppSpace.s5),
                      children: [
                        Text(
                          t.favsSummary(Nouns.dhikr.of(lib.favorites.length), Nouns.list.of(lib.lists.length)),
                          style: AppType.caption
                              .copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: AppSpace.s3),
                        InfoRow(
                          title: t.favsAll,
                          subtitle: Nouns.item.of(lib.favorites.length),
                          leading: Icon(Icons.favorite,
                              size: AppSize.iconLg, color: c.iconWarm),
                          onTap: () => context.push('/favs/all'),
                        ),
                        const SizedBox(height: AppSpace.s5),
                        Text(t.listsTitle, style: AppType.label),
                        const SizedBox(height: AppSpace.s3),
                        for (final l in lib.lists) ...[
                          InfoRow(
                            title: l.name,
                            subtitle: Nouns.item.of(l.itemIds.length),
                            leading: _Dot(index: l.color),
                            onTap: () => context.push('/favs/list/${l.id}'),
                          ),
                          const SizedBox(height: AppSpace.s3),
                        ],
                        AddTile(
                          label: t.listNew,
                          onTap: () => _newList(context, ref),
                        ),
                        if (lib.links.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.s5),
                          Text(t.linksTitle, style: AppType.label),
                          const SizedBox(height: AppSpace.s3),
                          for (final l in lib.links) ...[
                            InfoRow(
                              title: l.name,
                              subtitle: t.linkKindList,
                              leading: Icon(Icons.list_alt,
                                  size: AppSize.iconLg, color: c.iconWarm),
                              onTap: () => context.push(l.path),
                              trailing: IconButton(
                                tooltip: t.linkRemoveTooltip,
                                onPressed: () => ref
                                    .read(libraryProvider.notifier)
                                    .removeLink(l.id),
                                icon: Icon(Icons.close,
                                    size: AppSize.iconMd,
                                    color: c.textSecondary),
                              ),
                            ),
                            const SizedBox(height: AppSpace.s3),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// New list: name it, then pick what goes in it.
Future<void> _newList(BuildContext context, WidgetRef ref) async {
  final id = await showListDialog(context, ref);
  if (id != null && context.mounted) context.push('/favs/list/$id/add');
}

class _Dot extends StatelessWidget {
  const _Dot({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final bg = listColors(context.colors, index).$1;
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: const SizedBox(width: AppSize.iconXl, height: AppSize.iconXl),
    );
  }
}

/// Creates (or renames / recolours) a list. Returns the list id.
Future<String?> showListDialog(
  BuildContext context,
  WidgetRef ref, {
  UserList? existing,
}) async {
  final t = AppLocalizations.of(context);
  final ctrl = TextEditingController(text: existing?.name ?? '');
  var color = existing?.color ?? 0;
  final result = await showAppSheet<bool>(
    context,
    title: existing == null ? t.listNew : t.listEdit,
    builder: (sheet, close) => StatefulBuilder(
      builder: (ctx, setState) {
        final colors = ctx.colors;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              style: AppType.body,
              decoration: InputDecoration(
                  labelText: t.listName, hintText: t.nameHint),
            ),
            const SizedBox(height: AppSpace.s4),
            Text(t.listColor, style: AppType.label),
            const SizedBox(height: AppSpace.s2),
            Wrap(
              spacing: AppSpace.s2,
              children: [
                for (var i = 0; i < listColorCount; i++)
                  Semantics(
                    button: true,
                    selected: i == color,
                    child: GestureDetector(
                      onTap: () => setState(() => color = i),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: listColors(colors, i).$1,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.textPrimary,
                            width: i == color ? AppStroke.md : 0,
                          ),
                        ),
                        child: SizedBox(
                          width: AppSize.touchMin,
                          height: AppSize.touchMin,
                          child: i == color
                              ? Icon(Icons.check,
                                  color: listColors(colors, i).$2)
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.s5),
            WideButton(
              label: existing == null ? t.listCreate : t.save,
              onPressed: () => close(true),
            ),
            const SizedBox(height: AppSpace.s2),
            Center(
              child: TextButton(
                  onPressed: () => close(false), child: Text(t.cancel)),
            ),
          ],
        );
      },
    ),
  );
  final name = ctrl.text.trim();
  if (result != true || name.isEmpty) return null;
  final lib = ref.read(libraryProvider.notifier);
  if (existing == null) return lib.createList(name, color);
  lib.updateList(existing.id, name: name, color: color);
  return existing.id;
}

/// Asks for a name, then saves (or renames / removes) a shortcut to a list.
Future<void> showLinkDialog(
  BuildContext context,
  WidgetRef ref, {
  required String path,
  required String defaultName,
}) async {
  final t = AppLocalizations.of(context);
  final lib = ref.read(libraryProvider.notifier);
  final existing = ref.read(libraryProvider).linkFor(path);
  final ctrl = TextEditingController(text: existing?.name ?? defaultName);
  final result = await showAppSheet<String>(
    context,
    title: existing == null ? t.linkDialogTitle : t.linkEditTitle,
    builder: (sheet, close) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: null,
          style: AppType.body,
          decoration: InputDecoration(labelText: t.linkName),
        ),
        const SizedBox(height: AppSpace.s4),
        WideButton(
          label: existing == null ? t.linkAdd : t.linkSaveName,
          onPressed: () => close('save'),
        ),
        if (existing != null) ...[
          const SizedBox(height: AppSpace.s2),
          TextButton(
              onPressed: () => close('remove'), child: Text(t.linkRemove)),
        ],
        const SizedBox(height: AppSpace.s2),
        TextButton(onPressed: () => close(null), child: Text(t.cancel)),
      ],
    ),
  );
  if (result == 'save') lib.saveLink(path, ctrl.text);
  if (result == 'remove' && existing != null) lib.removeLink(existing.id);
}

/// Bottom sheet: save one item to the favourites and / or lists.
Future<void> showSaveSheet(BuildContext context, String itemId) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.surfaceBase,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (_) => _SaveSheet(itemId: itemId),
  );
}

class _SaveSheet extends ConsumerWidget {
  const _SaveSheet({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final lib = ref.watch(libraryProvider);
    final notifier = ref.read(libraryProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.saveTitle, style: AppType.titleSm),
            const SizedBox(height: AppSpace.s3),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  CheckboxListTile(
                    value: lib.favorites.contains(itemId),
                    title: Text(t.favsGeneral, style: AppType.label),
                    onChanged: (v) => notifier.setFavorite(itemId, v ?? false),
                  ),
                  for (final l in lib.lists)
                    CheckboxListTile(
                      value: l.itemIds.contains(itemId),
                      title: Text(l.name, style: AppType.label),
                      secondary: _Dot(index: l.color),
                      onChanged: (v) =>
                          notifier.setInList(l.id, itemId, v ?? false),
                    ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(t.listNew, style: AppType.label),
                    onTap: () async {
                      final id = await showListDialog(context, ref);
                      if (id != null) notifier.setInList(id, itemId, true);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s3),
            WideButton(
                label: t.done, onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

/// One list, or all favourites when [listId] is null.
class ListDetailScreen extends ConsumerWidget {
  const ListDetailScreen({super.key, this.listId});

  final String? listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final lib = ref.watch(libraryProvider);
    final loc = ref.watch(itemLocatorProvider);
    final list = listId == null ? null : lib.list(listId!);
    if (listId != null && list == null) {
      return Scaffold(body: SafeArea(child: Center(child: Text(t.notFound))));
    }
    final ids = list?.itemIds ?? lib.favorites;
    final refs = [for (final id in ids) if (loc[id] != null) loc[id]!];
    final title = list?.name ?? t.favsAll;
    final readPath = '/favs/read/${listId ?? 'all'}';
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
                    child: Text(Nouns.item.of(refs.length),
                        style: AppType.caption
                            .copyWith(color: c.textSecondary)),
                  ),
                  if (list != null)
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/favs/list/${list.id}/add'),
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
                      hint: t.listEmptyHint,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s5),
                      itemCount: refs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpace.s3),
                      itemBuilder: (_, i) {
                        final r = refs[i];
                        return _ItemRow(
                          item: r.item,
                          onTap: () => context.push('$readPath?i=$i'),
                          onRemove: () {
                            final n = ref.read(libraryProvider.notifier);
                            if (list == null) {
                              n.setFavorite(r.item.id, false);
                            } else {
                              n.setInList(list.id, r.item.id, false);
                            }
                          },
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
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.surfaceBase,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (s) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(list.name, style: AppType.titleSm),
              const SizedBox(height: AppSpace.s3),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(t.listEdit, style: AppType.label),
                onTap: () => Navigator.of(s).pop('edit'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: s.colors.danger),
                title: Text(t.listDelete,
                    style: AppType.label.copyWith(color: s.colors.danger)),
                onTap: () => Navigator.of(s).pop('delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      await showListDialog(context, ref, existing: list);
    } else if (action == 'delete') {
      final ok = await confirmDialog(
        context,
        title: t.listDeleteTitle,
        message: t.listDeleteMessage(list.name),
        confirm: t.listDelete,
      );
      if (ok) {
        ref.read(libraryProvider.notifier).deleteList(list.id);
        if (context.mounted) context.pop();
      }
    }
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  final Item item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Material(
      color: c.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.s4, AppSpace.s3, AppSpace.s2, AppSpace.s3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body.copyWith(color: c.textPrimary)),
                    Text(Nouns.times.of(item.repeat ?? 1),
                        style: AppType.caption
                            .copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                tooltip: t.remove,
                onPressed: onRemove,
                icon: Icon(Icons.close, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reads a list (or all favourites).
class FavReader extends ConsumerWidget {
  const FavReader({super.key, required this.listId, this.index = 0});

  final String listId;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final lib = ref.watch(libraryProvider);
    final loc = ref.watch(itemLocatorProvider);
    final list = listId == 'all' ? null : lib.list(listId);
    final ids = list?.itemIds ?? lib.favorites;
    final items = [for (final id in ids) if (loc[id] != null) loc[id]!.item];
    if (items.isEmpty) {
      return Scaffold(body: SafeArea(child: Center(child: Text(t.notFound))));
    }
    return ReaderScreen(
      title: list?.name ?? t.favsAll,
      items: items,
      initialIndex: index.clamp(0, items.length - 1),
    );
  }
}

/// Pick items (by search) to add to a list.
