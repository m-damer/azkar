import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../shared/widgets.dart';

const _whatsappUrl = 'https://wa.me/963941874763';
const _emailUrl = 'mailto:damermahmoud@gmail.com';

/// Settings → about the developer: portrait, short bio, two ways to reach out.
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  bool _failed = false;

  Future<void> _open(String url) async {
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (mounted) setState(() => _failed = !ok);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: t.setDeveloper),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.s5),
                children: [
                  Center(
                    child: ClipOval(
                      child: SizedBox.square(
                        dimension: AppSize.avatar,
                        child: Image.asset(
                          'assets/images/developer.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: c.surfaceRaised,
                            child: Center(
                              child: Text(t.devName.characters.first,
                                  style: AppType.displayLg
                                      .copyWith(color: c.iconWarm)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Text(t.devName,
                      textAlign: TextAlign.center, style: AppType.titleSm),
                  Text(t.devRole,
                      textAlign: TextAlign.center,
                      style: AppType.body.copyWith(color: c.textSecondary)),
                  const SizedBox(height: AppSpace.s6),
                  Text(t.devBio,
                      textAlign: TextAlign.center, style: AppType.body),
                  const SizedBox(height: AppSpace.s8),
                  WideButton(
                    label: t.devWhatsapp,
                    icon: Icons.chat_bubble_outline,
                    onPressed: () => _open(_whatsappUrl),
                  ),
                  const SizedBox(height: AppSpace.s3),
                  WideButton(
                    label: t.devEmail,
                    icon: Icons.mail_outline,
                    outlined: true,
                    onPressed: () => _open(_emailUrl),
                  ),
                  if (_failed) ...[
                    const SizedBox(height: AppSpace.s3),
                    Text(t.devOpenFailed,
                        textAlign: TextAlign.center,
                        style: AppType.body.copyWith(color: c.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
