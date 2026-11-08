import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models.dart';
import '../../data/progress.dart';
import '../../design/dimens.dart';
import '../../design/extras.dart';
import '../../design/motion.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';

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
  });

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
  final PageController _pages = PageController();
  int _index = 0;

  Item get _item => widget.items[_index];
  int _total(Item i) => (i.repeat ?? 1) < 1 ? 1 : (i.repeat ?? 1);
  String _ck(Item i) => '${widget.sessionKey ?? 'r'}:${i.id}';
  int _count(Item i) => ref.read(progressProvider).counts[_ck(i)] ?? 0;
  bool _done(Item i) => _count(i) >= _total(i);

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
    if (key != null && widget.items.every(_done)) notifier.completeSession(key);
  }

  void _go(int page) {
    if (page < 0 || page >= widget.items.length) return;
    _pages.animateToPage(page,
        duration: AppMotion.normal, curve: AppMotion.standard);
  }

  void _openList() {
    final t = AppLocalizations.of(context);
    final c = context.colors;
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
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpace.s5),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppType.titleSm),
                        Text(
                          t.sessionListSubtitle(_index + 1),
                          style: AppType.caption
                              .copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: t.close,
                    onPressed: () => Navigator.of(sheet).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.s5, 0, AppSpace.s5, AppSpace.s5),
                itemCount: widget.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s2),
                itemBuilder: (_, n) {
                  final it = widget.items[n];
                  final current = n == _index;
                  return Material(
                    color: current ? c.accentWarm : c.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      onTap: () {
                        Navigator.of(sheet).pop();
                        _pages.jumpToPage(n);
                      },
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(minHeight: AppSize.controlLg),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.s4, vertical: AppSpace.s3),
                          child: Row(
                            children: [
                              SizedBox(
                                width: AppSize.iconXl,
                                child: _done(it)
                                    ? Icon(Icons.check_circle,
                                        size: AppSize.iconLg, color: c.accent)
                                    : Text('${n + 1}',
                                        style: AppType.label.copyWith(
                                            color: current
                                                ? c.onAccentWarm
                                                : c.textSecondary)),
                              ),
                              Expanded(
                                child: Text(
                                  it.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.body.copyWith(
                                      color: current
                                          ? c.onAccentWarm
                                          : c.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    ref.watch(progressProvider);
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final bg = widget.background ?? c.surfaceBase;
    final fg = widget.foreground ?? c.textPrimary;
    final item = _item;
    final total = _total(item);
    final done = _done(item);
    final last = _index == widget.items.length - 1;
    final progress = (_index + (done ? 1 : 0)) / widget.items.length;

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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
          child: Column(
            children: [
              const SizedBox(height: AppSpace.s2),
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
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.label.copyWith(color: fg),
                    ),
                  ),
                  Text(
                    t.readerPosition(_index + 1, widget.items.length),
                    style: AppType.caption.copyWith(color: fg),
                  ),
                  const SizedBox(width: AppSpace.s1),
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
              ),
              const SizedBox(height: AppSpace.s2),
              ClipRRect(
                borderRadius: pillRadius,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: AppSize.barSm,
                  color: fg,
                  backgroundColor: fg.withValues(alpha: AppAlpha.track),
                ),
              ),
              const SizedBox(height: AppSpace.s3),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: widget.items.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => DhikrCard(item: widget.items[i]),
                ),
              ),
              const SizedBox(height: AppSpace.s3),
              Row(
                children: [
                  circle(Icons.chevron_right, t.previous,
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
                  circle(Icons.chevron_left, t.next,
                      last ? null : () => _go(_index + 1),
                      filled: done && !last),
                ],
              ),
              const SizedBox(height: AppSpace.s6),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fixed-size card. The dhikr and its small texts scroll together inside it.
class DhikrCard extends StatelessWidget {
  const DhikrCard({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasSplit = item.intro != null ||
        item.virtue != null ||
        item.takhrij != null ||
        item.note != null;
    final small = <String>[
      if (item.intro != null) item.intro!,
      if (item.virtue != null) item.virtue!,
      if (item.takhrij != null) item.takhrij!,
      if (item.note != null) item.note!,
      if (!hasSplit && item.source.isNotEmpty) item.source,
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
                Text(
                  item.text,
                  textAlign: TextAlign.center,
                  style: AppType.dhikrLg.copyWith(color: c.textPrimary),
                ),
                for (final s in small) ...[
                  const SizedBox(height: AppSpace.s3),
                  Text(
                    s,
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
      label: done ? t.counterDone : t.counterLabel(count, total),
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
                    if (done)
                      Icon(Icons.check, size: AppSize.icon2Xl, color: on)
                    else
                      Text('$count',
                          style: AppType.displayLg.copyWith(color: on)),
                    const SizedBox(width: AppSpace.s3),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(done ? t.counterDone : t.counterTap,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.label.copyWith(color: on)),
                          Text(
                            total == 1 ? t.counterOnce : t.counterOf(total),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.caption.copyWith(color: on),
                          ),
                        ],
                      ),
                    ),
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
