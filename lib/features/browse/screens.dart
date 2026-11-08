import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import 'widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentScreen(
      title: (c) => AppLocalizations.of(c).appName,
      builder: (context, content) {
        final t = AppLocalizations.of(context);
        return TileList(children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s2),
            child: Text(
              t.homeGreeting,
              style: AppType.titleMd.copyWith(color: context.colors.textPrimary),
            ),
          ),
          for (final s in content.sections)
            NavTile(
              title: s.title,
              subtitle: t.itemsCount(s.itemCount),
              onTap: () => context.push('/s/${s.id}'),
            ),
        ]);
      },
    );
  }
}

class SectionScreen extends StatelessWidget {
  const SectionScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  Widget build(BuildContext context) {
    return ContentScreen(
      title: (c) => '',
      builder: (context, content) {
        final section = content.sectionById(sectionId);
        if (section == null) return const SizedBox.shrink();
        final t = AppLocalizations.of(context);
        return TileList(children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s2),
            child: Text(
              section.title,
              style: AppType.titleLg.copyWith(color: context.colors.textPrimary),
            ),
          ),
          for (final c in section.categories)
            NavTile(
              title: c.title,
              subtitle: t.chaptersCount(c.chapters.length),
              onTap: () => context.push('/c/${c.id}'),
            ),
        ]);
      },
    );
  }
}

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return ContentScreen(
      title: (c) => '',
      builder: (context, content) {
        final category = content.categoryById(categoryId);
        if (category == null) return const SizedBox.shrink();
        final t = AppLocalizations.of(context);
        return TileList(children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s2),
            child: Text(
              category.title,
              style: AppType.titleMd.copyWith(color: context.colors.textPrimary),
            ),
          ),
          for (final b in category.chapters)
            NavTile(
              title: b.title,
              subtitle: t.itemsCount(b.items.length),
              onTap: () => context.push('/b/${b.id}'),
            ),
        ]);
      },
    );
  }
}

class ChapterScreen extends StatelessWidget {
  const ChapterScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  Widget build(BuildContext context) {
    return ContentScreen(
      title: (c) => '',
      builder: (context, content) {
        final chapter = content.chapterById(chapterId);
        if (chapter == null) return const SizedBox.shrink();
        final t = AppLocalizations.of(context);
        final c = context.colors;
        return ListView(
          padding: const EdgeInsets.all(AppSpace.s5),
          children: [
            Text(chapter.title,
                style: AppType.titleSm.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpace.s4),
            if (chapter.items.isEmpty)
              Text(t.emptyChapter,
                  style: AppType.body.copyWith(color: c.textSecondary)),
            for (final item in chapter.items) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.text,
                          style: AppType.dhikrSm.copyWith(color: c.textPrimary)),
                      const SizedBox(height: AppSpace.s3),
                      Text(item.source,
                          style: AppType.caption
                              .copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s3),
            ],
          ],
        );
      },
    );
  }
}
