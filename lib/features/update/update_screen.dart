import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_info.dart';
import '../../data/update.dart';
import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../shared/widgets.dart';

/// Settings → update: check for a newer build, download and install it.
class UpdateScreen extends ConsumerStatefulWidget {
  const UpdateScreen({super.key});

  @override
  ConsumerState<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends ConsumerState<UpdateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(updateProvider);
      if (s.phase == UpdatePhase.idle || s.phase == UpdatePhase.error) {
        ref.read(updateProvider.notifier).check();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final s = ref.watch(updateProvider);
    final n = ref.read(updateProvider.notifier);
    final busy = s.phase == UpdatePhase.checking ||
        s.phase == UpdatePhase.downloading;
    final headline = switch (s.phase) {
      UpdatePhase.idle || UpdatePhase.checking => t.updateChecking,
      UpdatePhase.upToDate => t.updateUpToDate,
      UpdatePhase.available => t.updateAvailable,
      UpdatePhase.downloading => t.updateDownloading,
      UpdatePhase.error => t.updateError,
    };
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: t.setUpdate),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.s5),
                children: [
                  Material(
                    color: c.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.s6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(headline,
                              style: AppType.titleMd
                                  .copyWith(color: c.textPrimary)),
                          const SizedBox(height: AppSpace.s2),
                          Text(
                            t.updateCurrent(appVersion, buildNumber),
                            style: AppType.caption
                                .copyWith(color: c.textSecondary),
                          ),
                          if (s.info != null &&
                              (s.phase == UpdatePhase.available ||
                                  s.phase == UpdatePhase.downloading)) ...[
                            const SizedBox(height: AppSpace.s2),
                            Text(
                              t.updateNew(s.info!.build),
                              style: AppType.caption
                                  .copyWith(color: c.textSecondary),
                            ),
                            if (s.info!.notes.isNotEmpty) ...[
                              const SizedBox(height: AppSpace.s3),
                              Text(s.info!.notes, style: AppType.body),
                            ],
                          ],
                          if (s.phase == UpdatePhase.downloading) ...[
                            const SizedBox(height: AppSpace.s4),
                            BarProgress(value: s.progress),
                          ],
                          if (s.installFailed) ...[
                            const SizedBox(height: AppSpace.s3),
                            Text(t.updateInstallFailed,
                                style: AppType.body
                                    .copyWith(color: c.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  if (s.phase == UpdatePhase.available)
                    WideButton(
                      label: t.updateInstall,
                      icon: Icons.system_update,
                      onPressed: n.downloadAndInstall,
                    )
                  else
                    WideButton(
                      label: t.updateCheck,
                      icon: Icons.refresh,
                      outlined: true,
                      onPressed: busy ? null : n.check,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card on home when a newer build is available.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(updateProvider);
    if (s.phase != UpdatePhase.available) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s3),
      child: InfoRow(
        title: t.updateAvailable,
        subtitle: t.updateBannerHint,
        leading: Icon(Icons.system_update, color: c.textPrimary),
        onTap: () => context.push('/settings/update'),
      ),
    );
  }
}
