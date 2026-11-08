import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content_provider.dart';
import '../../content/models.dart';
import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';

/// A full-width tappable row: title, optional subtitle, forward chevron.
class NavTile extends StatelessWidget {
  const NavTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.row),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppType.label.copyWith(color: c.textPrimary)),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpace.s1),
                        Text(subtitle!,
                            style: AppType.caption
                                .copyWith(color: c.textSecondary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s2),
                Icon(Icons.chevron_right,
                    size: AppSize.iconLg, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared screen frame: app bar, gutter padding, loading and error states.
class ContentScreen extends ConsumerWidget {
  const ContentScreen({
    super.key,
    required this.title,
    required this.builder,
  });

  final String Function(BuildContext) title;
  final Widget Function(BuildContext, Content) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title(context))),
      body: SafeArea(
        child: content.when(
          data: (data) => builder(context, data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(t.loadError)),
        ),
      ),
    );
  }
}

/// Vertical list with the standard gutter and row gap.
class TileList extends StatelessWidget {
  const TileList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpace.s5),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s3),
      itemBuilder: (_, i) => children[i],
    );
  }
}
