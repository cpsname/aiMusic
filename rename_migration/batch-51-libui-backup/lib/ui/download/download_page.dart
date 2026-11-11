import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infra_core/infra_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/art.dart';
import '../common/error_retry_view.dart';
import '../common/messages.dart';
import '../common/page_layout.dart';
import '../common/remote_flags.dart';
import '../common/test_id.dart';
import '../create/create_labels.dart';
import '../player/lyrics_model.dart';
import '../player/work_title.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';

/// P11 — download & license (PRD F09 / §9.1): MP3, the Premier WAV
/// (ADR-0010), the commercial-license PDF and what it allows, Save to Files,
/// and "Add to Music" through the share sheet (ADR-0010). The license
/// endpoint is the gate: a locked work (`DOWNLOAD_LOCKED`, PRD §8.4) keeps
/// playing but offers the plans instead.
class DownloadPage extends ConsumerStatefulWidget {
  const DownloadPage({super.key, required this.workId});

  final String workId;

  /// Flex weights of the cover and the status column beside it (docs/ui P09).
  static const int coverFlex = 5;
  static const int statusFlex = 6;

  @override
  ConsumerState<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends ConsumerState<DownloadPage> {
  Future<MusicLicenseDocument>? _license;
  String? _busy;

  void _load(MusicWork work) {
    _license ??= ref.read(exportServiceProvider).license(work);
  }

  void _reload(MusicWork work) => setState(() {
    _license = null;
    _load(work);
  });

  Future<void> _perform(String id, Future<void> Function() action) async {
    if (_busy != null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = id);
    try {
      await action();
    } on Object catch (error, stackTrace) {
      final failure = ref.read(errorHandlerProvider).handle(error, stackTrace);
      if (MusicErrorCode.of(failure) == MusicErrorCode.downloadLocked &&
          id == 'wav') {
        // Premier already: this song has no WAV render (made before WAV was
        // offered, or past the 24 h the file is kept) — no upsell.
        if (ref.read(musicEntitlementProvider).value?.tier ==
            MusicTier.premier) {
          ref.read(messageControllerProvider).info(l10n.wavUnavailable);
          return;
        }
        ref.read(messageControllerProvider).info(l10n.wavNeedsPremier);
        if (mounted) await context.openPaywall(PaywallReason.wav);
      } else {
        ref.read(messageControllerProvider).show(failureMessage(l10n, failure));
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _saveFile(MusicWork work, MusicExportFile file) =>
      _perform(file.name, () async {
        final l10n = AppLocalizations.of(context);
        final outcome = await ref
            .read(exportServiceProvider)
            .saveFile(work, file, name: workFileName(l10n, work));
        if (outcome == MusicExportOutcome.saved) {
          ref.read(messageControllerProvider).success(l10n.downloadSaved);
        }
      });

  Future<void> _saveFolder(MusicWork work) => _perform('files', () async {
    final l10n = AppLocalizations.of(context);
    final outcome = await ref
        .read(exportServiceProvider)
        .export(work, folderName: workFileName(l10n, work));
    if (outcome == MusicExportOutcome.saved) {
      ref.read(messageControllerProvider).success(l10n.downloadSaved);
    }
  });

  Future<void> _addToMusic(MusicWork work) => _perform('music', () async {
    final path = await ref.read(exportServiceProvider).shareableAudio(work);
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'audio/mpeg')],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final work = ref.watch(workByIdProvider(widget.workId));
    if (work == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _load(work);
    final tier =
        ref.watch(musicEntitlementProvider).value?.tier ?? MusicTier.free;
    final language = MusicLyricLanguage.fromCode(work.lyricLanguage);

    return Scaffold(
      body: PageFrame(
        header: const PushedHeader(),
        footer: TestId(
          'download.done',
          child: ObsButton(
            label: l10n.commonDone,
            onPressed: () => context.canPop() ? context.pop() : null,
          ),
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: DownloadPage.coverFlex,
                child: CoverArt(
                  seed: work.id,
                  image: SongletArt.cover(work),
                  badgeLabel: l10n.playerAiGenerated,
                ),
              ),
              const SizedBox(width: SongletSpace.x4),
              Expanded(
                flex: DownloadPage.statusFlex,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(
                      label: work.isClip
                          ? l10n.playerPreviewLabel
                          : l10n.downloadReady,
                      icon: Icons.check_circle_rounded,
                      large: true,
                    ),
                    const SizedBox(height: SongletSpace.x2),
                    Text(
                      l10n.downloadTitle,
                      style: SongletType.title1.copyWith(color: c.ink),
                    ),
                    Text(
                      workTitle(l10n, work),
                      style: SongletType.callout.copyWith(
                        color: c.inkSecondary,
                      ),
                    ),
                    MetaLine(
                      textAlign: TextAlign.start,
                      parts: [
                        clockLabel(workDuration(work), l10n.localeName),
                        workGenre(l10n, work),
                        if (language != null) languageName(l10n, language),
                      ],
                    ),
                    const SizedBox(height: SongletSpace.x2),
                    Text(
                      l10n.downloadIntro,
                      style: SongletType.subhead.copyWith(
                        color: c.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: SongletSpace.x6),
          FutureBuilder<MusicLicenseDocument>(
            future: _license,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final failure = ref
                    .read(errorHandlerProvider)
                    .handle(snapshot.error!, snapshot.stackTrace);
                if (MusicErrorCode.of(failure) ==
                    MusicErrorCode.downloadLocked) {
                  return TestId(
                    'download.locked',
                    child: _Locked(
                      onPlans: () =>
                          context.openPaywall(PaywallReason.download),
                    ),
                  );
                }
                return ErrorRetryView(
                  failure: failure,
                  onRetry: () => _reload(work),
                  fullScreen: false,
                );
              }
              return _Unlocked(
                work: work,
                license: snapshot.data!,
                premier: tier == MusicTier.premier,
                wav: wavExportEnabled(ref),
                busy: _busy,
                onFile: (file) => _saveFile(work, file),
                onFolder: () => _saveFolder(work),
                onMusic: () => _addToMusic(work),
              );
            },
          ),
          const SizedBox(height: SongletSpace.x4),
          NoteBanner(
            icon: Icons.shield_outlined,
            message: l10n.synthIdNote,
            linkLabel: l10n.commonLearnMore,
            onLink: () => context.open(const AboutRoute()),
          ),
        ],
      ),
    );
  }
}

class _Unlocked extends StatelessWidget {
  const _Unlocked({
    required this.work,
    required this.license,
    required this.premier,
    required this.wav,
    required this.busy,
    required this.onFile,
    required this.onFolder,
    required this.onMusic,
  });

  final MusicWork work;
  final MusicLicenseDocument license;
  final bool premier;

  /// WAV export is offered at all (remote switch, contract v2 §7).
  final bool wav;
  final String? busy;
  final ValueChanged<MusicExportFile> onFile;
  final VoidCallback onFolder;
  final VoidCallback onMusic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final issued = license.issuedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.downloadAudioHeader,
          trailing: l10n.downloadAudioNote,
        ),
        const SizedBox(height: SongletSpace.x3),
        TestId(
          'download.mp3',
          child: DownloadRow(
            icon: Icons.audio_file_outlined,
            title: l10n.downloadMp3Title,
            subtitle: l10n.downloadMp3Subtitle,
            actionLabel: l10n.downloadMp3Action,
            busy: busy == MusicExportFile.mp3.name,
            onPressed: () => onFile(MusicExportFile.mp3),
          ),
        ),
        if (!work.isClip && wav) ...[
          const SizedBox(height: SongletSpace.x3),
          TestId(
            'download.wav',
            child: DownloadRow(
              icon: Icons.graphic_eq_rounded,
              title: l10n.downloadWavTitle,
              subtitle: l10n.downloadWavSubtitle,
              actionLabel: l10n.downloadWavAction,
              locked: !premier,
              busy: busy == MusicExportFile.wav.name,
              onPressed: () => onFile(MusicExportFile.wav),
            ),
          ),
        ],
        const SizedBox(height: SongletSpace.x6),
        SectionHeader(
          title: l10n.licenseHeader,
          trailing: l10n.licenseIncluded,
        ),
        const SizedBox(height: SongletSpace.x3),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TestId(
                'download.license',
                child: DownloadRow(
                  icon: Icons.picture_as_pdf_outlined,
                  title: l10n.licensePdfTitle,
                  subtitle: issued == null
                      ? l10n.licenseIncluded
                      : l10n.licenseGenerated(issued.toLocal()),
                  detail: license.id == null
                      ? null
                      : l10n.licenseId(license.id!),
                  actionLabel: l10n.downloadLicenseAction,
                  busy: busy == MusicExportFile.license.name,
                  onPressed: () => onFile(MusicExportFile.license),
                ),
              ),
              const SizedBox(height: SongletSpace.x4),
              Text(l10n.licenseUsesTitle, style: SongletType.callout),
              const SizedBox(height: SongletSpace.x3),
              UsageGrid(
                items: [
                  (l10n.usePersonal, l10n.usePersonalDetail),
                  (l10n.useAds, l10n.useAdsDetail),
                  (l10n.useSocial, l10n.useSocialDetail),
                  (l10n.usePodcasts, l10n.usePodcastsDetail),
                ],
              ),
              const SizedBox(height: SongletSpace.x4),
              NoteBanner(
                icon: Icons.info_outline_rounded,
                message: l10n.licenseDetailsNote,
              ),
            ],
          ),
        ),
        const SizedBox(height: SongletSpace.x6),
        SectionHeader(title: l10n.saveEnjoyHeader),
        const SizedBox(height: SongletSpace.x3),
        Row(
          children: [
            Expanded(
              child: TestId(
                'download.files',
                child: CardButton(
                  icon: Icons.folder_outlined,
                  label: l10n.saveToFiles,
                  busy: busy == 'files',
                  onPressed: onFolder,
                ),
              ),
            ),
            const SizedBox(width: SongletSpace.x3),
            Expanded(
              child: TestId(
                'download.music',
                child: CardButton(
                  icon: Icons.music_note_rounded,
                  label: l10n.addToMusic,
                  busy: busy == 'music',
                  onPressed: onMusic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({required this.onPlans});

  final VoidCallback onPlans;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SurfaceCard(
      child: EmptyState(
        icon: Icons.lock_outline_rounded,
        title: l10n.licenseNotIncluded,
        message: l10n.errorDownloadLocked,
        actionLabel: l10n.paywallSeePlans,
        onAction: onPlans,
      ),
    );
  }
}
