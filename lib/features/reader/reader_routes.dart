import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content_provider.dart';
import '../../design/theme.dart';
import '../../l10n/app_localizations.dart';
import '../sessions/session.dart';
import 'reader_screen.dart';

/// Reader for one chapter (opened from a section list).
class ChapterReader extends ConsumerWidget {
  const ChapterReader({super.key, required this.chapterId});

  final String chapterId;

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
            return ReaderScreen(title: chapter.title, items: chapter.items);
          },
        );
  }
}

/// Reader for a home session (morning / evening / sleep), in its colours.
class SessionReader extends ConsumerWidget {
  const SessionReader({super.key, required this.kind});

  final SessionKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
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
              background: kind.background(c),
              foreground: kind.foreground(c),
              sessionKey: kind.key,
            );
          },
        );
  }
}
