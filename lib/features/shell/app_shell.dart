import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/dimens.dart';
import '../../design/extras.dart';
import '../../design/motion.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';

/// Hosts the tab branches and the floating bottom navigation capsule.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final items = [
      (Icons.wb_twilight_outlined, t.navToday),
      (Icons.add_circle_outline, t.navAwrad),
      (Icons.notifications_none, t.navReminders),
      (Icons.tune, t.navSettings),
    ];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.s5, AppSpace.s2, AppSpace.s5, AppSpace.s3),
          child: NavCapsule(
            items: items,
            index: navigationShell.currentIndex,
            onTap: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
          ),
        ),
      ),
    );
  }
}

class NavCapsule extends StatelessWidget {
  const NavCapsule({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<(IconData, String)> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: pillRadius,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s1),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavItem(
                  icon: items[i].$1,
                  label: items[i].$2,
                  active: i == index,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = active ? c.onNavActive : c.textSecondary;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            height: AppSize.controlXl - AppSpace.s2,
            decoration: BoxDecoration(
              color: active ? c.navActive : null,
              borderRadius: pillRadius,
              border: active
                  ? null
                  : Border.all(color: c.surfaceRaised, width: AppStroke.md),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: AppSize.iconLg, color: fg),
                Text(label, style: AppType.caption.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
