import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/content_provider.dart';
import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../sessions/session.dart';

/// A section (azkar / duas / adab). With several categories it first lists
/// them as a main menu; each opens its own list of chapters. A section with a
/// single category lists its chapters directly. Chapters that already have a
/// home tile (morning / evening / sleep) are not repeated here.
class SectionScreen extends ConsumerWidget {
  const SectionScreen({super.key, required this.sectionId, this.categoryId});

  final String sectionId;
  final String? categoryId;

  static final _onHome = {for (final k in SessionKind.values) k.chapterId};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final content = ref.watch(contentProvider);
    return Scaffold(
      body: SafeArea(
        child: content.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(t.loadError)),
          data: (data) {
            final section = data.sectionById(sectionId);
            if (section == null) return Center(child: Text(t.notFound));
            final cats = [
              for (final k in section.categories)
                (
                  cat: k,
                  chapters: [
                    for (final ch in k.chapters)
                      if (!_onHome.contains(ch.id)) ch,
                  ],
                ),
            ].where((e) => e.chapters.isNotEmpty).toList();
            if (cats.isEmpty) return Center(child: Text(t.notFound));
            final picked = categoryId == null
                ? (cats.length == 1 ? cats.first : null)
                : cats.where((e) => e.cat.id == categoryId).firstOrNull;
            final title = picked?.cat.title ?? section.title;
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
                        child: Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.titleLg),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s2),
                  child: Text(
                    picked == null
                        ? t.categoriesCount(cats.length)
                        : t.chaptersCount(picked.chapters.length),
                    style: AppType.caption.copyWith(color: c.textSecondary),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s5),
                    itemCount: picked == null ? cats.length : picked.chapters.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.s3),
                    itemBuilder: (_, i) {
                      if (picked == null) {
                        final e = cats[i];
                        return _ListRow(
                          title: e.cat.title,
                          subtitle: t.chaptersCount(e.chapters.length),
                          onTap: () => context
                              .push('/s/$sectionId/c/${e.cat.id}'),
                        );
                      }
                      final ch = picked.chapters[i];
                      return _ListRow(
                        title: ch.title,
                        subtitle: t.itemsCount(ch.items.length),
                        onTap: () => context.push('/read/${ch.id}'),
                      );
                    },
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

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
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
                      Text(title,
                          style:
                              AppType.label.copyWith(color: c.textPrimary)),
                      Text(subtitle,
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
