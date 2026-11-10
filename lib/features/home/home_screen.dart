import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/library.dart';
import '../../data/progress.dart';
import '../../data/settings.dart';
import '../../design/colors.dart';
import '../../design/dimens.dart';
import '../../design/extras.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../update/update_screen.dart';
import '../sessions/session.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final current = SessionKind.at(ref.watch(nowProvider));
    final order = SessionKind.cycleFrom(current);
    final progress = ref.watch(progressProvider);
    final streak = progress.streak(ref.watch(nowProvider),
        grace: ref.watch(settingsProvider).grace);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s5),
          children: [
            _StreakBar(days: streak),
            const SizedBox(height: AppSpace.s3),
            const UpdateBanner(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    current.greeting(t),
                    style: AppType.titleMd.copyWith(color: c.textPrimary),
                  ),
                ),
                IconButton.filled(
                  tooltip: t.searchTooltip,
                  style: IconButton.styleFrom(
                    backgroundColor: c.surfaceRaised,
                    foregroundColor: c.textPrimary,
                    minimumSize: const Size.square(AppSize.touchMin),
                  ),
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s3),
            SessionTile(
              kind: order[0],
              hero: true,
              done: progress.doneSessions.contains(order[0].key),
              onTap: () => context.push('/session/${order[0].key}'),
            ),
            const SizedBox(height: AppSpace.s3),
            Row(
              children: [
                for (var i = 1; i <= 2; i++) ...[
                  if (i > 1) const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: SessionTile(
                      kind: order[i],
                      hero: false,
                      done: progress.doneSessions.contains(order[i].key),
                      onTap: () => context.push('/session/${order[i].key}'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.s3),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SessionTile(
                    kind: order[3],
                    hero: false,
                    done: progress.doneSessions.contains(order[3].key),
                    onTap: () => context.push('/session/${order[3].key}'),
                  ),
                ),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  flex: 2,
                  child: _FavTile(count: ref.watch(libraryProvider).favorites.length),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s3),
            LinkBlock(
              icon: Icons.list,
              title: t.homeMoreAzkar,
              onTap: () => context.push('/s/s1'),
            ),
            const SizedBox(height: AppSpace.s3),
            LinkBlock(
              icon: Icons.menu_book_outlined,
              title: t.homeDuas,
              subtitle: t.homeDuasHint,
              background: c.tileEvening,
              foreground: c.onTileEvening,
              onTap: () => context.push('/s/s2'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavTile extends StatelessWidget {
  const _FavTile({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Material(
      color: c.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        onTap: () => context.push('/favs'),
        child: SizedBox(
          height: AppSize.tileHalf,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.favorite_border,
                    size: AppSize.iconXl, color: c.iconWarm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.favsTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.heading.copyWith(color: c.textPrimary)),
                    Text(t.itemsCount(count),
                        style: AppType.caption
                            .copyWith(color: c.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim bar at the top of the home screen showing the current streak.
class _StreakBar extends StatelessWidget {
  const _StreakBar({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Row(
      children: [
        Icon(Icons.local_fire_department_outlined,
            size: AppSize.iconMd, color: c.iconWarm),
        const SizedBox(width: AppSpace.s2),
        Text(
          days == 0 ? t.streakNone : t.streakDays(days),
          style: AppType.caption.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}

/// A session tile: the hero (current session) or a half tile.
class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.kind,
    required this.hero,
    required this.onTap,
    this.done = false,
  });

  final SessionKind kind;
  final bool hero;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final bg = done ? c.tileDone : kind.background(c);
    final fg = done ? c.onTileDone : kind.foreground(c);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        onTap: onTap,
        child: SizedBox(
          height: hero ? AppSize.tileHero : AppSize.tileHalf,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(done ? Icons.check_circle_outline : kind.icon,
                        size: hero ? AppSize.icon2Xl : AppSize.iconXl,
                        color: fg),
                    if (hero) _NowBadge(label: t.sessionNow, color: fg),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kind.name(t),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (hero ? AppType.titleMd : AppType.heading)
                                .copyWith(color: fg),
                          ),
                          Text(
                            done ? t.counterDone : kind.hint(t),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.caption.copyWith(color: fg),
                          ),
                        ],
                      ),
                    ),
                    if (hero)
                      DecoratedBox(
                        decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                        child: SizedBox(
                          width: AppSize.controlMd,
                          height: AppSize.controlMd,
                          child: Icon(Icons.chevron_left,
                              size: AppSize.iconLg, color: bg),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NowBadge extends StatelessWidget {
  const _NowBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: pillRadius,
        border: Border.all(color: color, width: AppStroke.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s3, vertical: AppSpace.s1),
        child: Text(label, style: AppType.caption.copyWith(color: color)),
      ),
    );
  }
}

/// Full-width pill link to a section.
class LinkBlock extends StatelessWidget {
  const LinkBlock({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.outlined = false,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool outlined;
  final Color? background;
  final Color? foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final fg = foreground ?? c.textPrimary;
    return Material(
      color: outlined ? c.surfaceBase : (background ?? c.surfaceRaised),
      shape: StadiumBorder(
        side: outlined
            ? BorderSide(color: fg, width: AppStroke.md)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: AppSize.controlXl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
            child: Row(
              children: [
                Icon(icon, size: AppSize.iconLg, color: fg),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.label.copyWith(color: fg)),
                      if (subtitle != null)
                        Text(subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.caption.copyWith(color: fg)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, size: AppSize.iconLg, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
