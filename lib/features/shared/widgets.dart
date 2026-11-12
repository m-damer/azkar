import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/colors.dart';
import '../../design/dimens.dart';
import '../../design/extras.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';

/// Header with a back button, a title and optional trailing actions.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader(
      {super.key, required this.title, this.actions = const [], this.onBack});

  final VoidCallback? onBack;
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.s5, AppSpace.s3, AppSpace.s5, AppSpace.s3),
      child: Row(
        children: [
          IconButton.filled(
            tooltip: t.back,
            style: IconButton.styleFrom(
              backgroundColor: c.surfaceRaised,
              foregroundColor: c.textPrimary,
              minimumSize: const Size.square(AppSize.touchMin),
            ),
            onPressed: onBack ?? () => context.pop(),
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.titleSm.copyWith(color: c.textPrimary),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Round icon button used in headers.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IconButton.filled(
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: c.surfaceRaised,
        foregroundColor: c.textPrimary,
        minimumSize: const Size.square(AppSize.touchMin),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

/// Full-width pill button (filled or outlined).
class WideButton extends StatelessWidget {
  const WideButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bg = danger ? c.danger : c.navActive;
    final fg = danger ? c.onDanger : c.onNavActive;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSize.iconLg),
          const SizedBox(width: AppSpace.s2),
        ],
        Flexible(
          child: Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.label),
        ),
      ],
    );
    return SizedBox(
      width: double.infinity,
      height: AppSize.controlLg,
      child: outlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: danger ? c.danger : c.textPrimary,
                side: BorderSide(
                    color: danger ? c.danger : c.textPrimary,
                    width: AppStroke.md),
                shape: const StadiumBorder(),
              ),
              onPressed: onPressed,
              child: child,
            )
          : FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
                shape: const StadiumBorder(),
              ),
              onPressed: onPressed,
              child: child,
            ),
    );
  }
}

/// A raised row with title, subtitle and optional leading / trailing.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.titleStyle,
    this.titleMaxLines,
  });

  final TextStyle? titleStyle;
  final int? titleMaxLines;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.row),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s4, vertical: AppSpace.s3),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpace.s3),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: titleMaxLines,
                          overflow: titleMaxLines == null
                              ? null
                              : TextOverflow.ellipsis,
                          style: (titleStyle ?? AppType.label)
                              .copyWith(color: c.textPrimary)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: AppType.caption
                                .copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                trailing ??
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

/// Dashed-looking add tile.
class AddTile extends StatelessWidget {
  const AddTile({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surfaceBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: c.borderStrong, width: AppStroke.md),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        onTap: onTap,
        child: SizedBox(
          height: AppSize.row,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: AppSize.iconLg, color: c.textPrimary),
              const SizedBox(width: AppSpace.s2),
              Text(label,
                  style: AppType.label.copyWith(color: c.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered empty state.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    this.action,
  });

  final IconData icon;
  final String title;
  final String hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSize.icon2Xl, color: c.textSecondary),
            const SizedBox(height: AppSpace.s3),
            Text(title,
                textAlign: TextAlign.center,
                style: AppType.heading.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpace.s2),
            Text(hint,
                textAlign: TextAlign.center,
                style: AppType.body.copyWith(color: c.textSecondary)),
            if (action != null) ...[
              const SizedBox(height: AppSpace.s5),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Progress bar track + fill.
class BarProgress extends StatelessWidget {
  const BarProgress({super.key, required this.value, this.color, this.track});

  final double value;
  final Color? color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: pillRadius,
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: AppSize.barMd,
        color: color ?? c.accent,
        backgroundColor: track ?? c.borderSubtle,
      ),
    );
  }
}

/// Every prompt in the app is a bottom sheet (never a popup dialog).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext sheet, void Function(T?) close) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surfaceBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (sheet) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: AppType.titleSm),
              const SizedBox(height: AppSpace.s4),
              builder(sheet, (v) => Navigator.of(sheet).pop(v)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Asks for a name; returns it or null.
Future<String?> askName(
  BuildContext context, {
  required String title,
  required String confirm,
  String initial = '',
}) {
  final t = AppLocalizations.of(context);
  final ctrl = TextEditingController(text: initial);
  return showAppSheet<String>(
    context,
    title: title,
    builder: (sheet, close) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: ctrl,
          autofocus: true,
          style: AppType.body,
          decoration: InputDecoration(hintText: t.nameHint),
          onSubmitted: close,
        ),
        const SizedBox(height: AppSpace.s4),
        WideButton(label: confirm, onPressed: () => close(ctrl.text)),
        const SizedBox(height: AppSpace.s2),
        TextButton(onPressed: () => close(null), child: Text(t.cancel)),
      ],
    ),
  );
}

/// Asks for confirmation; true when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
}) async {
  final t = AppLocalizations.of(context);
  final r = await showAppSheet<bool>(
    context,
    title: title,
    builder: (sheet, close) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: AppType.body),
        const SizedBox(height: AppSpace.s4),
        WideButton(label: confirm, danger: true, onPressed: () => close(true)),
        const SizedBox(height: AppSpace.s2),
        TextButton(onPressed: () => close(false), child: Text(t.cancel)),
      ],
    ),
  );
  return r ?? false;
}
