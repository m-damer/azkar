import 'package:flutter/material.dart';

import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';

/// Placeholder for tabs that are built in later phases.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.s6),
              Text(title, style: AppType.titleLg),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_empty,
                          size: AppSize.icon2Xl, color: c.textSecondary),
                      const SizedBox(height: AppSpace.s3),
                      Text(t.comingSoon, style: AppType.heading),
                      const SizedBox(height: AppSpace.s2),
                      Text(
                        t.comingSoonHint,
                        textAlign: TextAlign.center,
                        style: AppType.body.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
