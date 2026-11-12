import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'content/content_provider.dart';
import 'data/library.dart';
import 'data/progress.dart';
import 'data/reminders.dart';
import 'data/widget_entries.dart';
import 'data/settings.dart';
import 'data/update.dart';
import 'services/reminder_service.dart';
import 'services/widget_service.dart';
import 'design/theme.dart';
import 'data/widget_style.dart';
import 'features/awrad/awrad_screens.dart';
import 'features/browse/section_screen.dart';
import 'features/update/update_screen.dart';
import 'features/widget/widget_screen.dart';
import 'features/duas/duas_screens.dart';
import 'features/favorites/favorites_screens.dart';
import 'features/home/home_screen.dart';
import 'features/reader/reader_routes.dart';
import 'features/reader/session_end_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/reminders/reminder_rows.dart';
import 'features/search/search_screen.dart';
import 'features/settings/developer_screen.dart';
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
                    routes: [
                      GoRoute(
                        path: 'c/:cat',
                        builder: (_, s) => SectionScreen(
                          sectionId: s.pathParameters['id']!,
                          categoryId: s.pathParameters['cat'],
                        ),
                      ),
                    ],
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
                    builder: (_, s) =>
                        WirdFormScreen(listId: s.uri.queryParameters['list']),
                  ),
                  GoRoute(
                    path: 'list/:id',
                    builder: (_, s) =>
                        WirdListScreen(listId: s.pathParameters['id']!),
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
                path: '/duas',
                builder: (_, _) => const MyDuasScreen(),
                routes: [
                  GoRoute(
                    path: 'all',
                    builder: (_, _) => const MyListScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        builder: (_, _) => const MyAddPicker(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'list/:id',
                    builder: (_, s) =>
                        MyListScreen(listId: s.pathParameters['id']),
                    routes: [
                      GoRoute(
                        path: 'add',
                        builder: (_, s) =>
                            MyAddPicker(listId: s.pathParameters['id']),
                      ),
                    ],
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'reminders',
                    builder: (_, _) => const RemindersScreen(),
                  ),
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
                    path: 'widget',
                    builder: (_, _) => const WidgetSettingsScreen(),
                    routes: [
                      GoRoute(
                        path: 'list/:id',
                        builder: (_, s) =>
                            WidgetListScreen(listId: s.pathParameters['id']!),
                        routes: [
                          GoRoute(
                            path: 'add',
                            builder: (_, s) =>
                                WidgetAddPicker(listId: s.pathParameters['id']!),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'update',
                    builder: (_, _) => const UpdateScreen(),
                  ),
                  GoRoute(
                    path: 'developer',
                    builder: (_, _) => const DeveloperScreen(),
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
          path: '/duas/read/:id',
          parentNavigatorKey: rootKey,
          builder: (_, s) => MyReader(
            listId: s.pathParameters['id']!,
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(settingsProvider).onboarded) {
        ref
            .read(reminderServiceProvider)
            .schedule(ref.read(remindersProvider));
        // Alarms and the widget's own copy do not travel with a restored
        // backup (new phone), so set them up again at every start.
        ref
            .read(reminderServiceProvider)
            .scheduleAwrad(ref.read(awradProvider).awrad);
        ref.read(contentProvider.future).then((_) {
          if (!mounted) return;
          final lists = ref.read(widgetListsProvider.notifier);
          lists.migrate();
          lists.sync();
          ref.read(widgetStyleProvider.notifier).push();
        });
      }
      _checkUpdate();
      _listenForRoutes();
    });
  }

  /// A quiet check at every start. With «auto update» on, a check due twice a
  /// week also downloads the new build and opens Android's installer (the
  /// system always asks for the final tap).
  Future<void> _checkUpdate() async {
    final n = ref.read(updateProvider.notifier);
    final s = ref.read(settingsProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final last = prefs.getInt('autoUpdateAt') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = s.autoUpdate && now - last >= autoUpdateGapMs;
    await n.check(silent: true);
    if (!due) return;
    await prefs.setInt('autoUpdateAt', now);
    if (ref.read(updateProvider).phase == UpdatePhase.available) {
      await n.downloadAndInstall();
    }
  }

  StreamSubscription<String>? _taps;

  /// Opens the screen a tapped notification (or the Android widget) points to.
  Future<void> _listenForRoutes() async {
    final svc = ref.read(reminderServiceProvider);
    _taps = svc.taps.listen(_open);
    final launch = await svc.launchRoute();
    if (launch != null) _open(launch);
    final native = ref.read(widgetServiceProvider);
    native.onRoute(_open);
    final first = await native.initialRoute();
    if (first != null) _open(first);
  }

  void _open(String route) {
    if (!ref.read(settingsProvider).onboarded) return;
    _router.go(route);
  }

  @override
  void dispose() {
    _taps?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(remindersProvider, (_, times) {
      ref.read(reminderServiceProvider).schedule(times);
    });
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
