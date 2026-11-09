import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/settings.dart';
import 'design/theme.dart';
import 'features/awrad/awrad_screens.dart';
import 'features/browse/section_screen.dart';
import 'features/favorites/favorites_screens.dart';
import 'features/home/home_screen.dart';
import 'features/reader/reader_routes.dart';
import 'features/reader/session_end_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/reminders/reminder_rows.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screens.dart';
import 'features/sessions/session.dart';
import 'features/shell/app_shell.dart';
import 'l10n/app_localizations.dart';

GoRouter createRouter(bool Function() onboarded) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
      navigatorKey: rootKey,
      redirect: (_, state) {
        final inOnboarding = state.matchedLocation == '/onboarding';
        if (!onboarded() && !inOnboarding) return '/onboarding';
        if (onboarded() && inOnboarding) return '/';
        return null;
      },
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
                    path: 'favs',
                    builder: (_, _) => const FavsScreen(),
                    routes: [
                      GoRoute(
                        path: 'all',
                        builder: (_, _) => const ListDetailScreen(),
                      ),
                      GoRoute(
                        path: 'list/:id',
                        builder: (_, s) =>
                            ListDetailScreen(listId: s.pathParameters['id']),
                        routes: [
                          GoRoute(
                            path: 'add',
                            builder: (_, s) => AddToListScreen(
                                listId: s.pathParameters['id']!),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (_, _) => const SearchScreen(),
                  ),
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
                builder: (_, _) => const AwradScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, _) => const WirdFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (_, s) =>
                        WirdFormScreen(wirdId: s.pathParameters['id']),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, s) =>
                        WirdCounterScreen(wirdId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/reminders',
                builder: (_, _) => const RemindersScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'font',
                    builder: (_, _) => const FontSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'streak',
                    builder: (_, _) => const StreakScreen(),
                  ),
                  GoRoute(
                    path: 'sources',
                    builder: (_, _) => const SourcesScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (_, _) => const AboutScreen(),
                  ),
                ],
              ),
            ]),
          ],
        ),
        GoRoute(
          path: '/read/:chapterId',
          parentNavigatorKey: rootKey,
          builder: (_, s) => ChapterReader(
            chapterId: s.pathParameters['chapterId']!,
            index: int.tryParse(s.uri.queryParameters['i'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: '/onboarding',
          parentNavigatorKey: rootKey,
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/favs/read/:id',
          parentNavigatorKey: rootKey,
          builder: (_, s) => FavReader(
            listId: s.pathParameters['id']!,
            index: int.tryParse(s.uri.queryParameters['i'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: '/done/:kind',
          parentNavigatorKey: rootKey,
          builder: (_, s) => SessionEndScreen(
            kind: SessionKind.fromKey(s.pathParameters['kind']!) ??
                SessionKind.morning,
          ),
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

class AzkarApp extends ConsumerStatefulWidget {
  const AzkarApp({super.key});

  @override
  ConsumerState<AzkarApp> createState() => _AzkarAppState();
}

class _AzkarAppState extends ConsumerState<AzkarApp> {
  late final GoRouter _router =
      createRouter(() => ref.read(settingsProvider).onboarded);

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
      themeMode: ref.watch(settingsProvider).themeMode,
    );
  }
}
