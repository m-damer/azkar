import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'design/theme.dart';
import 'features/browse/section_screen.dart';
import 'features/home/home_screen.dart';
import 'features/reader/reader_routes.dart';
import 'features/sessions/session.dart';
import 'features/shell/app_shell.dart';
import 'features/shell/coming_soon_screen.dart';
import 'l10n/app_localizations.dart';

GoRouter createRouter() {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
      navigatorKey: rootKey,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 's/:id',
                    builder: (_, s) =>
                        SectionScreen(sectionId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/awrad',
                builder: (c, _) =>
                    ComingSoonScreen(title: AppLocalizations.of(c).navAwrad),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/reminders',
                builder: (c, _) => ComingSoonScreen(
                    title: AppLocalizations.of(c).navReminders),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/settings',
                builder: (c, _) => ComingSoonScreen(
                    title: AppLocalizations.of(c).navSettings),
              ),
            ]),
          ],
        ),
        GoRoute(
          path: '/read/:chapterId',
          parentNavigatorKey: rootKey,
          builder: (_, s) =>
              ChapterReader(chapterId: s.pathParameters['chapterId']!),
        ),
        GoRoute(
          path: '/session/:kind',
          parentNavigatorKey: rootKey,
          builder: (_, s) => SessionReader(
            kind: SessionKind.fromKey(s.pathParameters['kind']!) ??
                SessionKind.morning,
          ),
        ),
      ],
    );
}

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
