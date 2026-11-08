import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'design/theme.dart';
import 'features/browse/screens.dart';
import 'l10n/app_localizations.dart';

GoRouter createRouter() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/s/:id',
          builder: (_, s) => SectionScreen(sectionId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/c/:id',
          builder: (_, s) =>
              CategoryScreen(categoryId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/b/:id',
          builder: (_, s) => ChapterScreen(chapterId: s.pathParameters['id']!),
        ),
      ],
    );

class AzkarApp extends StatefulWidget {
  const AzkarApp({super.key});

  @override
  State<AzkarApp> createState() => _AzkarAppState();
}

class _AzkarAppState extends State<AzkarApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      onGenerateTitle: (c) => AppLocalizations.of(c).appName,
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
    );
  }
}
