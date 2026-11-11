import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/music_page_layout.dart';

/// P15 — "About generation" (PRD §9.4 / §10.1; App Review 5.1.2(i)): the
/// third-party model, the SynthID watermark, no artist imitation, data
/// retention, and the promise that every shared song is labelled.
class MusicAboutPage extends ConsumerWidget {
  const MusicAboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final version = ref.watch(deviceProfileProvider).value?.appVersion ?? '';
    return Scaffold(
      body: MusicPageFrame(
        header: const MusicPushedHeader(showBrand: false),
        children: [
          MusicPageTitle(title: l10n.aboutTitle, subtitle: l10n.aboutSubtitle),
          for (final (icon, title, body) in [
            (
              Icons.music_note_outlined,
              l10n.aboutLyriaTitle,
              l10n.aboutLyriaBody,
            ),
            (
              Icons.fingerprint_rounded,
              l10n.aboutWatermarkTitle,
              l10n.aboutWatermarkBody,
            ),
            (
              Icons.person_off_outlined,
              l10n.aboutImitationTitle,
              l10n.aboutImitationBody,
            ),
            (
              Icons.photo_camera_back_outlined,
              l10n.aboutPrivacyTitle,
              l10n.aboutPrivacyBody,
            ),
          ]) ...[
            FeatureCard(icon: icon, title: title, body: body),
            const SizedBox(height: SongletSpace.x4),
          ],
          HighlightBanner(message: l10n.aboutBanner),
          const SizedBox(height: SongletSpace.x4),
          Text(
            l10n.aboutFooter(version),
            textAlign: TextAlign.center,
            style: SongletType.footnote.copyWith(color: c.inkSecondary),
          ),
        ],
      ),
    );
  }
}
