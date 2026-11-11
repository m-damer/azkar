import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content_provider.dart';
import '../../l10n/app_localizations.dart';
import '../sessions/session.dart';
import 'reader_screen.dart';

/// Reader for one chapter (opened from a section list).
class ChapterReader extends ConsumerWidget {
  const ChapterReader({super.key, required this.chapterId, this.index = 0});

  final String chapterId;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return ref.watch(contentProvider).when(
          loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(body: Center(child: Text(t.loadError))),
          data: (content) {
            final chapter = content.chapterById(chapterId);
            if (chapter == null || chapter.items.isEmpty) {
              return Scaffold(body: Center(child: Text(t.notFound)));
            }
            return ReaderScreen(
              title: chapter.title,
              items: chapter.items,
              headings: [
                for (final i in chapter.items) i.title ?? chapter.title
              ],
              initialIndex: index.clamp(0, chapter.items.length - 1),
              listKey: 'chapter:$chapterId',
            );
          },
        );
  }
}

/// Reader for a home session (morning / evening / sleep).
class SessionReader extends ConsumerWidget {
  const SessionReader({super.key, required this.kind});

  final SessionKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return ref.watch(contentProvider).when(
          loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(body: Center(child: Text(t.loadError))),
          data: (content) {
            final chapter = content.chapterById(kind.chapterId);
            if (chapter == null || chapter.items.isEmpty) {
              return Scaffold(body: Center(child: Text(t.notFound)));
            }
            return ReaderScreen(
              title: kind.name(t),
              items: chapter.items,
              headings: [
                for (final i in chapter.items) i.title ?? chapter.title
              ],
              sessionKey: kind.key,
              listKey: 'session:${kind.key}',
            );
          },
        );
  }
}
