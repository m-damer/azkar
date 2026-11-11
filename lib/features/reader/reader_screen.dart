import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/arabic.dart';
import '../../content/models.dart';
import '../../data/alt_repeat.dart';
import '../../data/library.dart';
import '../../data/list_prefs.dart';
import '../../data/progress.dart';
import '../../data/settings.dart';
import '../../design/dimens.dart';
import '../../design/dhikr_weight.dart';
import '../../design/extras.dart';
import '../../design/motion.dart';
import '../../design/mushaf.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/numbers.dart';
import '../favorites/favorites_screens.dart';
import 'item_list_sheet.dart';

/// Reads a list of items one at a time. The card has a fixed size and its
/// text scrolls inside it; the user moves between items with the previous /
/// next buttons or by swiping the screen sideways.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.title,
    required this.items,
    this.background,
    this.foreground,
    this.sessionKey,
    this.initialIndex = 0,
    this.headings,
    this.listKey,
    this.onDelete,
  });

  /// Names this list in the user's saved order / hidden items. Null: the list
  /// cannot be reordered.
  final String? listKey;

  /// When set, the item list sheet offers a delete button per item.
  final void Function(Item)? onDelete;

  /// One heading per item, shown in a small box above the text card.
  final List<String>? headings;

  /// Item shown first (e.g. when opened from a search result).
  final int initialIndex;

  /// When set, finishing every item marks that session done for today.
  final String? sessionKey;

  final String title;
  final List<Item> items;

  /// Page colours; default to the app surface.
  final Color? background;
  final Color? foreground;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late List<Item> _items = _visible(ref.read(listPrefsProvider));
  late String _currentId = widget.items.isEmpty
      ? ''
      : widget.items[widget.initialIndex.clamp(0, widget.items.length - 1)].id;
  late int _index = _startIndex();
  late final PageController _pages = PageController(initialPage: _index);

  List<Item> _visible(ListPrefs prefs) =>
      prefs.visible(widget.listKey, widget.items, (e) => e.id);

  int _startIndex() {
    final i = _items.indexWhere((e) => e.id == _currentId);
    if (i >= 0) return i;
    return 0;
  }

  /// Follows changes of the saved order / hidden items and of the items
  /// themselves, keeping the dhikr on screen when it is still visible.
  void _sync(ListPrefs prefs) {
    final next = _visible(prefs);
    _items = next;
    if (next.isEmpty) return;
    var i = next.indexWhere((e) => e.id == _currentId);
    if (i < 0) i = _index.clamp(0, next.length - 1);
    final moved = i != _index || next[i].id != _currentId;
    _index = i;
    _currentId = next[i].id;
    if (moved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(_index);
      });
    }
  }

  Item get _item => _items[_index];
  bool _hasMeta(Item i) =>
      i.virtue != null ||
      i.takhrij != null ||
      i.source.isNotEmpty;
  int _total(Item i) {
    final alt = i.repeatAlt != null && ref.read(altRepeatProvider).contains(i.id);
    final n = alt ? i.repeatAlt! : (i.repeat ?? 1);
    return n < 1 ? 1 : n;
  }
  String _ck(Item i) => '${widget.sessionKey ?? 'r'}:${i.id}';
  int _count(Item i) => ref.read(progressProvider).counts[_ck(i)] ?? 0;
  bool _done(Item i) => _count(i) >= _total(i);

  String? _headingOf(Item i) {
    final h = widget.headings;
    if (h == null) return null;
    final n = widget.items.indexWhere((e) => e.id == i.id);
    return n < 0 || n >= h.length ? null : h[n];
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _tap() {
    final i = _item;
    if (_done(i)) return;
    HapticFeedback.selectionClick();
    final notifier = ref.read(progressProvider.notifier);
    notifier.setCount(_ck(i), _count(i) + 1);
    final key = widget.sessionKey;
    if (key != null && _items.every(_done)) {
      notifier.completeSession(key);
      context.pushReplacement('/done/$key');
      return;
    }
    if (_done(i) &&
        ref.read(settingsProvider).autoAdvance &&
        _index < _items.length - 1) {
      _go(_index + 1);
    }
  }

  void _go(int page) {
    if (page < 0 || page >= _items.length) return;
    _pages.animateToPage(page,
        duration: AppMotion.normal, curve: AppMotion.standard);
  }

  void _openMeta(Item item) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final tashkeel = ref.read(settingsProvider).tashkeel;
    String fmt(String v) => arDigits(tashkeel ? v : stripDiacritics(v));
    final parts = <(String, String)>[
      if (item.virtue != null) (t.metaVirtue, item.virtue!),
      if (item.takhrij != null) (t.metaTakhrij, item.takhrij!),
      if (item.virtue == null && item.takhrij == null && item.source.isNotEmpty)
        (t.metaTakhrij, item.source),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surfaceBase,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(AppSpace.s5),
          children: [
            Row(
              children: [
                Expanded(child: Text(t.readerMeta, style: AppType.titleSm)),
                IconButton(
                  tooltip: t.close,
                  onPressed: () => Navigator.of(sheet).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            for (final p in parts) ...[
              const SizedBox(height: AppSpace.s4),
              Text(p.$1,
                  style: AppType.label.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpace.s2),
              Text(fmt(p.$2), style: AppType.body),
            ],
          ],
        ),
      ),
    );
  }

  void _openList() {
    showItemListSheet(
      context,
      title: widget.title,
      listKey: widget.listKey,
      itemsOf: () => widget.items,
      currentId: _currentId,
      isDone: _done,
      onDelete: widget.onDelete,
      headingOf: _headingOf,
      onPick: (it) {
        final n = _items.indexWhere((e) => e.id == it.id);
        if (n >= 0) _pages.jumpToPage(n);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(progressProvider);
    _sync(ref.watch(listPrefsProvider));
    ref.watch(altRepeatProvider);
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final bg = widget.background ?? c.surfaceBase;
    final fg = widget.foreground ?? c.textPrimary;
    if (_items.isEmpty) {
      return Scaffold(
          body: SafeArea(
              child: Center(child: Text(AppLocalizations.of(context).notFound))));
    }
    final item = _item;
    final total = _total(item);
    final done = _done(item);
    final last = _index == _items.length - 1;
    final progress = (_index + (done ? 1 : 0)) / _items.length;

    Widget circle(IconData icon, String label, VoidCallback? onTap,
        {bool filled = false}) {
      final enabled = onTap != null;
      return Tooltip(
        message: label,
        child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: onTap,
            child: Opacity(
              opacity: enabled ? 1 : AppAlpha.disabled,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? fg : null,
                  border: Border.all(color: fg, width: AppStroke.md),
                ),
                child: SizedBox(
                  width: AppSize.controlLg,
                  height: AppSize.controlLg,
                  child: Icon(icon,
                      size: AppSize.iconLg, color: filled ? bg : fg),
                ),
              ),
            ),
          ),
        ),
        ),
      );
    }

    // The text card runs edge to edge; everything else keeps the side margin.
    Widget pad(Widget w) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
          child: w,
        );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpace.s2),
              pad(Row(
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
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.label.copyWith(color: fg),
                    ),
                  ),
                  Text(
                    t.readerPosition(arNum(_index + 1), arNum(_items.length)),
                    style: AppType.caption.copyWith(color: fg),
                  ),
                  const SizedBox(width: AppSpace.s1),
                  IconButton(
                    tooltip: t.saveTitle,
                    color: fg,
                    onPressed: () => showSaveSheet(context, item.id),
                    icon: Icon(
                      ref.watch(libraryProvider).isSaved(item.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: t.listAll,
                    style: IconButton.styleFrom(
                      foregroundColor: fg,
                      side: BorderSide(color: fg, width: AppStroke.md),
                      minimumSize: const Size.square(AppSize.touchMin),
                    ),
                    onPressed: _openList,
                    icon: const Icon(Icons.format_list_bulleted),
                  ),
                ],
              )),
              const SizedBox(height: AppSpace.s2),
              pad(ClipRRect(
                borderRadius: pillRadius,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: AppSize.barSm,
                  color: fg,
                  backgroundColor: fg.withValues(alpha: AppAlpha.track),
                ),
              )),
              const SizedBox(height: AppSpace.s3),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _items.length,
                  onPageChanged: (i) => setState(() {
                    _index = i;
                    _currentId = _items[i].id;
                  }),
                  itemBuilder: (_, i) {
                    final h = _headingOf(_items[i]);
                    if (h == null) return DhikrCard(item: _items[i]);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        pad(_HeadingBox(text: h)),
                        const SizedBox(height: AppSpace.s2),
                        Expanded(child: DhikrCard(item: _items[i])),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpace.s3),
              if (item.repeatAlt != null) ...[
                pad(SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    foregroundColor: fg,
                    selectedForegroundColor: bg,
                    selectedBackgroundColor: fg,
                    side: BorderSide(color: fg, width: AppStroke.md),
                    minimumSize: const Size.fromHeight(AppSize.touchMin),
                  ),
                  segments: [
                    ButtonSegment(
                        value: false,
                        label: Text(Nouns.times.of(item.repeat ?? 1))),
                    ButtonSegment(
                        value: true,
                        label: Text(Nouns.times.of(item.repeatAlt!))),
                  ],
                  selected: {ref.watch(altRepeatProvider).contains(item.id)},
                  onSelectionChanged: (v) => ref
                      .read(altRepeatProvider.notifier)
                      .set(item.id, v.first),
                )),
                const SizedBox(height: AppSpace.s2),
              ],
              pad(Opacity(
                opacity: _hasMeta(item) ? 1 : AppAlpha.disabled,
                child: SizedBox(
                  width: double.infinity,
                  height: AppSize.controlLg,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: fg,
                      side: BorderSide(color: fg, width: AppStroke.md),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _hasMeta(item) ? () => _openMeta(item) : null,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(t.readerMeta, style: AppType.label),
                  ),
                ),
              )),
              const SizedBox(height: AppSpace.s3),
              pad(Row(
                children: [
                  circle(Icons.chevron_left, t.previous,
                      _index > 0 ? () => _go(_index - 1) : null),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: _CounterButton(
                      count: _count(item),
                      total: total,
                      done: done,
                      fg: fg,
                      bg: bg,
                      onTap: _tap,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s3),
                  circle(Icons.chevron_right, t.next,
                      last ? null : () => _go(_index + 1),
                      filled: done && !last),
                ],
              )),
              const SizedBox(height: AppSpace.s6),
            ],
          ),
      ),
    );
  }
}

/// Fixed-size card. The dhikr and its small texts scroll together inside it.
/// Small white box with the heading of the dhikr being read.
class _HeadingBox extends StatelessWidget {
  const _HeadingBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s4, vertical: AppSpace.s3),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppType.label.copyWith(color: c.textPrimary),
          ),
        ),
      ),
    );
  }
}

class DhikrCard extends ConsumerWidget {
  const DhikrCard({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    String fmt(String v) =>
        arDigits(settings.tashkeel ? v : stripDiacritics(v));
    final c = context.colors;
    final small = <String>[
      if (item.intro != null) item.intro!,
    ];
    return Material(
      color: c.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s6),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: box.maxHeight - AppSpace.s6 * 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.mushaf != null)
                  MushafBlock(
                    item: item,
                    verseBase: settings.verseScale.dhikrStyle.fontSize!,
                    headerBase: settings.headerScale.dhikrStyle.fontSize!,
                    color: c.textPrimary,
                  )
                else
                  DhikrText(
                    fmt(item.text),
                    style: settings.fontScale.dhikrStyle,
                    color: c.textPrimary,
                    weight: settings.weight,
                  ),
                for (final s in small) ...[
                  const SizedBox(height: AppSpace.s3),
                  Text(
                    fmt(s),
                    textAlign: TextAlign.center,
                    style: AppType.body.copyWith(color: c.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.count,
    required this.total,
    required this.done,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  final int count;
  final int total;
  final bool done;
  final Color fg;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final fill = done ? c.tileDone : fg;
    final on = done ? c.onTileDone : bg;
    return Semantics(
      button: true,
      label: done ? t.counterDone : t.counterLabel(arNum(count), arNum(total)),
      child: ExcludeSemantics(
        child: Material(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            onTap: onTap,
            child: SizedBox(
              height: AppExtra.counterHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(done ? t.counterDone : t.counterTap,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.label.copyWith(color: on)),
                          Text(
                            Nouns.times.of(total),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.caption.copyWith(color: on),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.s3),
                    if (done)
                      Icon(Icons.check, size: AppSize.icon2Xl, color: on)
                    else
                      Text(arNum(count),
                          style: AppType.displayLg.copyWith(color: on)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Verses drawn with the mushaf glyph fonts, under the ornamental basmala or
/// ta'awwudh line.
class MushafBlock extends StatelessWidget {
  const MushafBlock({
    super.key,
    required this.item,
    required this.verseBase,
    required this.headerBase,
    required this.color,
  });

  final Item item;
  final double verseBase;
  final double headerBase;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final glyphs = switch (item.header) {
      'basmala' => MushafType.basmala,
      'taawwudh' => MushafType.taawwudh,
      _ => const <String>[],
    };
    return Column(
      children: [
        if (glyphs.isNotEmpty) ...[
          Wrap(
            textDirection: TextDirection.rtl,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MushafType.headerGap(headerBase),
            children: [
              for (final g in glyphs)
                Text(g, style: MushafType.header(headerBase, color)),
            ],
          ),
          const SizedBox(height: AppSpace.s5),
        ],
        Text.rich(
          TextSpan(
            children: [
              for (final r in item.mushaf!)
                TextSpan(
                  text: r.glyphs,
                  style: MushafType.verse(r.page, verseBase, color),
                ),
            ],
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          semanticsLabel: item.text,
        ),
      ],
    );
  }
}
