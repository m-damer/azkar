import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../design/dimens.dart';
import '../../design/extras.dart';
import '../../design/motion.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';

/// Hosts the tab branches and the floating bottom navigation capsule.
///
/// Back button: from another tab it returns to home; on home, a second press
/// within a short window exits the app.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  DateTime? _lastBack;

  void _onBack(bool didPop, Object? result) {
    if (didPop) return;
    final shell = widget.navigationShell;
    if (shell.currentIndex != 0) {
      shell.goBranch(0);
      return;
    }
    final now = DateTime.now();
    final last = _lastBack;
    if (last != null && now.difference(last) < AppMotion.exitWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).exitHint),
      duration: AppMotion.exitWindow,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final navigationShell = widget.navigationShell;
    final items = [
      (Icons.wb_twilight_outlined, t.navToday),
      (Icons.add_circle_outline, t.navAwrad),
      (Icons.tune, t.navSettings),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
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
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.caption.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
