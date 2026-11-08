import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/content_provider.dart';
import '../../content/models.dart';
import '../../design/dimens.dart';
import '../../design/motion.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';

/// A section (azkar / duas / adab): scrollable category chips, then the
/// chapters of the selected category. Tapping a chapter opens the reader.
class SectionScreen extends ConsumerStatefulWidget {
  const SectionScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  ConsumerState<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends ConsumerState<SectionScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final content = ref.watch(contentProvider);
    return Scaffold(
      body: SafeArea(
        child: content.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(t.loadError)),
          data: (data) {
            final section = data.sectionById(widget.sectionId);
            if (section == null || section.categories.isEmpty) {
              return Center(child: Text(t.notFound));
            }
            final cat = section.categories[_tab.clamp(0, section.categories.length - 1)];
            return Column(
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
                        child: Text(section.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.titleLg),
                      ),
                    ],
                  ),
                ),
                if (section.categories.length > 1)
                  SizedBox(
                    height: AppSize.touchMin,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpace.s5),
                      itemCount: section.categories.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpace.s2),
                      itemBuilder: (_, i) => _CategoryChip(
                        label: section.categories[i].title,
                        selected: i == _tab,
                        onTap: () => setState(() => _tab = i),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.s5, AppSpace.s4, AppSpace.s5, AppSpace.s2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(cat.title,
                            style: AppType.label
                                .copyWith(color: c.textPrimary)),
                      ),
                      Text(t.chaptersCount(cat.chapters.length),
                          style: AppType.caption
                              .copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s5),
                    itemCount: cat.chapters.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.s3),
                    itemBuilder: (_, i) => _ChapterRow(chapter: cat.chapters[i]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
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

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Material(
      color: c.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: () => context.push('/read/${chapter.id}'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.row),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s4, vertical: AppSpace.s3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chapter.title,
                          style:
                              AppType.label.copyWith(color: c.textPrimary)),
                      Text(t.itemsCount(chapter.items.length),
                          style: AppType.caption
                              .copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left,
                    size: AppSize.iconLg, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
