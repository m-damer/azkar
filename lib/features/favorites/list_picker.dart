import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/arabic.dart';
import '../../content/content_provider.dart';
import '../../content/models.dart';
import '../../content/locator.dart';
import '../../data/library.dart';
import '../../data/my_duas.dart';
import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/numbers.dart';
import '../search/search_screen.dart';
import '../sessions/session.dart';
import '../shared/widgets.dart';

/// Picks what goes into a user list: sections → lists → chapters → single
/// azkar, choosing a whole list or individual azkar, then review and confirm.
class AddToListScreen extends ConsumerStatefulWidget {
  const AddToListScreen(
      {super.key,
      this.listId,
      this.onConfirm,
      this.title,
      this.confirmLabel,
      this.existingIds,
      this.includeMine = false});

  /// The user list to add to; null when [onConfirm] takes the choice instead.
  final String? listId;
  final void Function(Set<String> ids)? onConfirm;
  final String? title;
  final String Function(String n)? confirmLabel;

  /// Ids shown as already added when no library list is given.
  final Set<String>? existingIds;

  /// Adds «أدعيتي» below the sections.
  final bool includeMine;

  @override
  ConsumerState<AddToListScreen> createState() => _AddToListState();
}

class _AddToListState extends ConsumerState<AddToListScreen> {
  static final _hidden = {for (final k in SessionKind.values) k.chapterId};

  Section? _section;
  Category? _cat;
  Chapter? _chapter;
  bool _mine = false;
  bool _review = false;
  String _q = '';
  final Set<String> _picked = {};

  List<Chapter> _chaptersOf(Category k) =>
      [for (final ch in k.chapters) if (!_hidden.contains(ch.id)) ch];

  List<Category> _catsOf(Section s) =>
      [for (final k in s.categories) if (_chaptersOf(k).isNotEmpty) k];

  Iterable<String> _idsOf(Iterable<Chapter> chs) =>
      [for (final ch in chs) for (final i in ch.items) i.id];

  bool get _atRoot => _section == null && !_mine && !_review;

  void _back() {
    setState(() {
      if (_review) {
        _review = false;
      } else if (_mine) {
        _mine = false;
      } else if (_chapter != null) {
        _chapter = null;
      } else if (_cat != null) {
        _cat = null;
      } else {
        _section = null;
      }
    });
  }

  /// true = all chosen, null = some, false = none (already-saved count as chosen).
  bool? _stateOf(Iterable<String> ids, Set<String> existing) {
    final open = ids.where((i) => !existing.contains(i)).toList();
    if (open.isEmpty) return true;
    final n = open.where(_picked.contains).length;
    return n == open.length ? true : (n == 0 ? false : null);
  }

  void _toggle(Iterable<String> ids, Set<String> existing) {
    final open = ids.where((i) => !existing.contains(i)).toList();
    setState(() {
      if (_stateOf(ids, existing) == true) {
        _picked.removeAll(open);
      } else {
        _picked.addAll(open);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final list =
        widget.listId == null ? null : ref.watch(libraryProvider).list(widget.listId!);
    final content = ref.watch(contentProvider).value;
    final existing = list?.itemIds.toSet() ?? widget.existingIds ?? <String>{};
    final title = _review
        ? t.pickReviewTitle
        : (_mine
            ? t.navMyDuas
            : _chapter?.title ??
            _cat?.title ??
            _section?.title ??
            widget.title ?? t.listAddTitle(list?.name ?? ''));
    Widget body;
    if (content == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_review) {
      body = _reviewBody(content, t);
    } else if (_q.trim().isNotEmpty) {
      body = _searchBody(existing, t);
    } else if (_mine) {
      body = _mineBody(existing, t);
    } else if (_section == null) {
      body = _rootBody(content, t);
    } else if (_cat == null) {
      body = _catsBody(_section!, existing, t);
    } else if (_chapter == null) {
      body = _chaptersBody(_cat!, existing, t);
    } else {
      body = _itemsBody(_chapter!, existing, t);
    }
    return PopScope(
      canPop: _atRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: title,
                onBack: _atRoot ? () => context.pop() : _back,
              ),
              if (!_review)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.s5, 0, AppSpace.s5, AppSpace.s2),
                  child: TextField(
                    style: AppType.body
                        .copyWith(color: context.colors.textPrimary),
                    onChanged: (v) => setState(() => _q = v),
                    decoration: InputDecoration(
                      hintText: t.searchHint,
                      filled: true,
                      fillColor: context.colors.surfaceRaised,
                      prefixIcon: const Icon(Icons.search),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: AppSpace.s4),
                      border: OutlineInputBorder(
                        borderRadius: pillRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              Expanded(child: body),
              Padding(
                padding: const EdgeInsets.all(AppSpace.s5),
                child: WideButton(
                  label: _review
                      ? t.pickConfirm(arNum(_picked.length))
                      : t.pickReview(arNum(_picked.length)),
                  onPressed: _picked.isEmpty
                      ? null
                      : _review
                          ? () {
                              if (widget.onConfirm != null) {
                                widget.onConfirm!(_picked);
                              } else {
                                ref
                                    .read(libraryProvider.notifier)
                                    .addToList(widget.listId!, _picked);
                              }
                              context.pop();
                            }
                          : () => setState(() => _review = true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row({
    required String title,
    String? subtitle,
    bool? checked,
    VoidCallback? onCheck,
    VoidCallback? onTap,
  }) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s3),
      child: Material(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap ?? onCheck,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.row),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s2, vertical: AppSpace.s2),
              child: Row(
                children: [
                  if (onCheck != null || checked == true)
                    Checkbox(
                      tristate: true,
                      value: checked,
                      onChanged: onCheck == null ? null : (_) => onCheck(),
                    ),
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpace.s2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.label
                                  .copyWith(color: c.textPrimary)),
                          if (subtitle != null)
                            Text(subtitle,
                                style: AppType.caption
                                    .copyWith(color: c.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Padding(
                      padding: const EdgeInsets.all(AppSpace.s2),
                      child: Icon(Icons.chevron_right,
                          size: AppSize.iconLg, color: c.textSecondary),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rootBody(Content content, AppLocalizations t) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s2),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s3),
          child: Text(t.pickRootHint,
              style: AppType.caption.copyWith(color: c.textSecondary)),
        ),
        for (final s in content.sections)
          _row(
            title: s.title,
            subtitle: s.id == 's1'
                ? t.homeMoreAzkarHint
                : (_catsOf(s).isEmpty ? t.homeDuasHint : null),
            onTap: () => setState(() => _section = s),
          ),
        if (widget.includeMine)
          _row(
            title: t.navMyDuas,
            subtitle: t.pickMineHint,
            onTap: () => setState(() => _mine = true),
          ),
      ],
    );
  }

  /// The user's own duas, grouped by where they were added.
  Widget _mineBody(Set<String> existing, AppLocalizations t) {
    final my = ref.watch(myDuasProvider);
    final loc = ref.watch(itemLocatorProvider);
    final groups = <(String, List<String>)>[
      (t.myDuasDirect, my.loose),
      for (final l in my.lists) (l.name, l.itemIds),
    ];
    final rows = <Widget>[];
    for (final g in groups) {
      final ids = [for (final id in g.$2) if (loc[id] != null) id];
      if (ids.isEmpty) continue;
      rows.add(Padding(
        padding: const EdgeInsets.only(top: AppSpace.s2),
        child: _row(
          title: g.$1,
          subtitle: Nouns.item.of(ids.length),
          checked: _stateOf(ids, existing),
          onCheck: () => _toggle(ids, existing),
        ),
      ));
      for (final id in ids) {
        rows.add(Padding(
          padding: const EdgeInsets.only(right: AppSpace.s5),
          child: _row(
            title: stripDiacritics(loc[id]!.item.listLabel),
            subtitle: existing.contains(id) ? t.pickAlready : null,
            checked: existing.contains(id) || _picked.contains(id),
            onCheck: existing.contains(id) ? null : () => _toggle([id], existing),
          ),
        ));
      }
    }
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s5),
          child: Text(t.pickMineEmpty,
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(color: context.colors.textSecondary)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s2),
      children: rows,
    );
  }

  Widget _catsBody(Section s, Set<String> existing, AppLocalizations t) {
    final cats = _catsOf(s);
    if (cats.isEmpty) {
      return Center(
        child: Text(t.sectionSoon,
            textAlign: TextAlign.center,
            style: AppType.body.copyWith(color: context.colors.textSecondary)),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s2),
      children: [
        for (final k in cats)
          () {
            final ids = _idsOf(_chaptersOf(k)).toList();
            return _row(
              title: k.title,
              subtitle: Nouns.chapter.of(_chaptersOf(k).length),
              checked: _stateOf(ids, existing),
              onCheck: () => _toggle(ids, existing),
              onTap: () => setState(() => _cat = k),
            );
          }(),
      ],
    );
  }

  Widget _chaptersBody(Category k, Set<String> existing, AppLocalizations t) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s2),
      children: [
        for (final ch in _chaptersOf(k))
          _row(
            title: ch.title,
            subtitle: Nouns.item.of(ch.items.length),
            checked: _stateOf(_idsOf([ch]), existing),
            onCheck: () => _toggle(_idsOf([ch]), existing),
            onTap: () => setState(() => _chapter = ch),
          ),
      ],
    );
  }

  Widget _itemsBody(Chapter ch, Set<String> existing, AppLocalizations t) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s2),
      children: [
        for (final it in ch.items)
          _row(
            title: stripDiacritics(it.listLabel),
            subtitle: existing.contains(it.id)
                ? t.pickAlready
                : Nouns.times.of(it.repeat ?? 1),
            checked: existing.contains(it.id) || _picked.contains(it.id),
            onCheck: existing.contains(it.id)
                ? null
                : () => _toggle([it.id], existing),
          ),
      ],
    );
  }

  Widget _searchBody(Set<String> existing, AppLocalizations t) {
    final c = context.colors;
    final hits = ref.watch(searchIndexProvider).value?.search(_q) ?? const [];
    if (hits.isEmpty) {
      return Center(
        child: Text(t.searchNone,
            style: AppType.body.copyWith(color: c.textSecondary)),
      );
    }
    final shown = hits.take(80).toList();
    final ids = [for (final h in shown) h.item.id];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s2),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s3),
          child: Row(
            children: [
              Expanded(
                child: Text(Nouns.item.of(hits.length),
                    style: AppType.caption.copyWith(color: c.textSecondary)),
              ),
              TextButton(
                onPressed: () => _toggle(ids, existing),
                child: Text(_stateOf(ids, existing) == true
                    ? t.pickClearResults
                    : t.pickSelectResults),
              ),
            ],
          ),
        ),
        for (final h in shown)
          _row(
            title: stripDiacritics(h.item.listLabel),
            subtitle: existing.contains(h.item.id)
                ? t.pickAlready
                : h.chapter.title,
            checked: existing.contains(h.item.id) || _picked.contains(h.item.id),
            onCheck: existing.contains(h.item.id)
                ? null
                : () => _toggle([h.item.id], existing),
          ),
      ],
    );
  }

  Widget _reviewBody(Content content, AppLocalizations t) {
    final c = context.colors;
    final groups = <Widget>[];
    for (final s in content.sections) {
      for (final k in s.categories) {
        for (final ch in k.chapters) {
          final its = [for (final i in ch.items) if (_picked.contains(i.id)) i];
          if (its.isEmpty) continue;
          groups.add(Padding(
            padding: const EdgeInsets.only(top: AppSpace.s3, bottom: AppSpace.s2),
            child: Text(ch.title,
                style: AppType.label.copyWith(color: c.textPrimary)),
          ));
          for (final i in its) {
            groups.add(_row(
              title: stripDiacritics(i.listLabel),
              subtitle: Nouns.times.of(i.repeat ?? 1),
              onTap: null,
              checked: true,
              onCheck: () => setState(() {
                _picked.remove(i.id);
                if (_picked.isEmpty) _review = false;
              }),
            ));
          }
        }
      }
    }
    final loc = ref.watch(itemLocatorProvider);
    final own = [
      for (final id in _picked)
        if (id.startsWith(customDuaPrefix) && loc[id] != null) loc[id]!.item,
    ];
    if (own.isNotEmpty) {
      groups.add(Padding(
        padding: const EdgeInsets.only(top: AppSpace.s3, bottom: AppSpace.s2),
        child: Text(t.navMyDuas,
            style: AppType.label.copyWith(color: c.textPrimary)),
      ));
      for (final i in own) {
        groups.add(_row(
          title: stripDiacritics(i.listLabel),
          checked: true,
          onCheck: () => setState(() {
            _picked.remove(i.id);
            if (_picked.isEmpty) _review = false;
          }),
        ));
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s2),
      children: [
        Text(t.pickSelected(arNum(_picked.length)),
            style: AppType.caption.copyWith(color: c.textSecondary)),
        ...groups,
      ],
    );
  }
}
