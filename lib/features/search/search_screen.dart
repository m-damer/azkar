import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/content_provider.dart';
import '../../content/models.dart';
import '../../content/search.dart';
import '../../data/progress.dart';
import '../../design/dimens.dart';
import '../../design/motion.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';

final searchIndexProvider = FutureProvider<SearchIndex>((ref) async {
  final content = await ref.watch(contentProvider.future);
  return SearchIndex(content);
});

const _suggestions = ['الكرب', 'السفر', 'النوم', 'الاستغفار'];
const _sectionOrder = ['s1', 's2', 's3'];

/// Full-text search over every dhikr, dua and adab.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  String _query = '';
  int _filter = 0; // 0 all, 1..3 = section index + 1

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _set(String q) {
    _ctrl.value = TextEditingValue(
      text: q,
      selection: TextSelection.collapsed(offset: q.length),
    );
    setState(() {
      _query = q;
      _filter = 0;
    });
  }

  void _open(SearchHit h) {
    ref.read(recentSearchesProvider.notifier).add(_query);
    context.push('/read/${h.chapter.id}?i=${h.index}');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final index = ref.watch(searchIndexProvider);
    final content = ref.watch(contentProvider).value;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.s5, AppSpace.s3, AppSpace.s5, AppSpace.s3),
              child: Row(
                children: [
                  IconButton.filled(
                    tooltip: t.back,
                    style: IconButton.styleFrom(
                      backgroundColor: c.surfaceRaised,
                      foregroundColor: c.textPrimary,
                      minimumSize: const Size.square(AppSize.touchMin),
                    ),
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      style: AppType.body.copyWith(color: c.textPrimary),
                      onChanged: (v) => setState(() {
                        _query = v;
                        _filter = 0;
                      }),
                      onSubmitted: (v) =>
                          ref.read(recentSearchesProvider.notifier).add(v),
                      decoration: InputDecoration(
                        hintText: t.searchHint,
                        hintStyle:
                            AppType.body.copyWith(color: c.textSecondary),
                        filled: true,
                        fillColor: c.surfaceRaised,
                        prefixIcon: Icon(Icons.search,
                            size: AppSize.iconLg, color: c.textSecondary),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: t.clear,
                                onPressed: () => _set(''),
                                icon: const Icon(Icons.close),
                              ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.s4),
                        border: OutlineInputBorder(
                          borderRadius: pillRadius,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: index.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(child: Text(t.loadError)),
                data: (idx) => _query.trim().isEmpty
                    ? _Start(onPick: _set)
                    : _Results(
                        hits: idx.search(_query),
                        content: content,
                        filter: _filter,
                        onFilter: (f) => setState(() => _filter = f),
                        onOpen: _open,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Start extends ConsumerWidget {
  const _Start({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final recents = ref.watch(recentSearchesProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpace.s5),
      children: [
        if (recents.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(t.searchRecent, style: AppType.label),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(recentSearchesProvider.notifier).clear(),
                child: Text(t.searchClearAll),
              ),
            ],
          ),
          for (final r in recents)
            ListTile(
              minTileHeight: AppSize.touchMin,
              leading: Icon(Icons.history, color: c.textSecondary),
              title: Text(r, style: AppType.body),
              onTap: () => onPick(r),
            ),
          const SizedBox(height: AppSpace.s4),
        ],
        Text(t.searchQuick, style: AppType.label),
        const SizedBox(height: AppSpace.s3),
        Wrap(
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s2,
          children: [
            for (final s in _suggestions)
              ActionChip(
                label: Text(s, style: AppType.label),
                backgroundColor: c.surfaceRaised,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                onPressed: () => onPick(s),
              ),
          ],
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.hits,
    required this.content,
    required this.filter,
    required this.onFilter,
    required this.onOpen,
  });

  final List<SearchHit> hits;
  final Content? content;
  final int filter;
  final ValueChanged<int> onFilter;
  final ValueChanged<SearchHit> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    if (hits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off,
                  size: AppSize.icon2Xl, color: c.textSecondary),
              const SizedBox(height: AppSpace.s3),
              Text(t.searchNone, style: AppType.heading),
              const SizedBox(height: AppSpace.s2),
              Text(t.searchNoneHint,
                  textAlign: TextAlign.center,
                  style: AppType.body.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      );
    }
    final bySection = <String, List<SearchHit>>{
      for (final id in _sectionOrder) id: [],
    };
    for (final h in hits) {
      bySection[h.section.id]?.add(h);
    }
    final labels = [t.searchAll, t.searchAzkar, t.searchDuas, t.searchAdab];
    final counts = [
      hits.length,
      for (final id in _sectionOrder) bySection[id]!.length,
    ];
    final shown = <Widget>[];
    for (var i = 0; i < _sectionOrder.length; i++) {
      if (filter != 0 && filter != i + 1) continue;
      final list = bySection[_sectionOrder[i]]!;
      if (list.isEmpty) continue;
      final title = content?.sectionById(_sectionOrder[i])?.title ?? '';
      shown.add(Padding(
        padding: const EdgeInsets.only(top: AppSpace.s3, bottom: AppSpace.s2),
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppType.label)),
            Text('${list.length}',
                style: AppType.caption.copyWith(color: c.textSecondary)),
          ],
        ),
      ));
      for (final h in list.take(50)) {
        shown.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s2),
          child: _HitRow(hit: h, onTap: () => onOpen(h)),
        ));
      }
    }
    return Column(
      children: [
        SizedBox(
          height: AppSize.touchMin,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
            itemCount: labels.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s2),
            itemBuilder: (_, i) => _FilterChip(
              label: '${labels[i]} · ${counts[i]}',
              selected: filter == i,
              onTap: () => onFilter(i),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s5),
            children: shown,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
          decoration: BoxDecoration(
            color: selected ? c.navActive : c.surfaceRaised,
            borderRadius: pillRadius,
          ),
          child: Text(
            label,
            maxLines: 1,
            style: AppType.label
                .copyWith(color: selected ? c.onNavActive : c.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _HitRow extends StatelessWidget {
  const _HitRow({required this.hit, required this.onTap});

  final SearchHit hit;
  final VoidCallback onTap;

  /// A window of the text around the first match, with highlights.
  TextSpan _span(BuildContext context) {
    final c = context.colors;
    final text = hit.item.text;
    const window = 80;
    var from = 0;
    var to = text.length;
    if (text.length > window * 2 && hit.ranges.isNotEmpty) {
      from = (hit.ranges.first.$1 - window).clamp(0, text.length);
      to = (hit.ranges.first.$1 + window).clamp(0, text.length);
    } else if (text.length > window * 2) {
      to = window * 2;
    }
    final base = AppType.body.copyWith(color: c.textPrimary);
    final mark = base.copyWith(
      backgroundColor: c.accentWarm,
      color: c.onAccentWarm,
    );
    final spans = <TextSpan>[];
    if (from > 0) spans.add(const TextSpan(text: '… '));
    var cursor = from;
    for (final r in hit.ranges) {
      if (r.$2 <= cursor || r.$1 >= to) continue;
      final s = r.$1 < cursor ? cursor : r.$1;
      final e = r.$2 > to ? to : r.$2;
      if (s > cursor) spans.add(TextSpan(text: text.substring(cursor, s)));
      spans.add(TextSpan(text: text.substring(s, e), style: mark));
      cursor = e;
    }
    if (cursor < to) spans.add(TextSpan(text: text.substring(cursor, to)));
    if (to < text.length) spans.add(const TextSpan(text: ' …'));
    return TextSpan(style: base, children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                _span(context),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpace.s1),
              Text(
                '${hit.category.title} · ${hit.chapter.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
