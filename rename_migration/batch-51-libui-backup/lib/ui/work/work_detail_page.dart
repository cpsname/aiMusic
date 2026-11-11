import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/art.dart';
import '../common/messages.dart';
import '../common/page_layout.dart';
import '../common/test_id.dart';
import '../create/create_labels.dart';
import '../mv/mv_entry.dart';
import '../mv/mv_labels.dart';
import '../player/lyrics_model.dart';
import '../player/work_actions.dart';
import '../player/work_title.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';

/// P13 — work detail (PRD §5.1 / F10): what the song was made from, its
/// lyrics, the generation id (Lyria `interaction.id`), "Regenerate same style"
/// and delete.
class WorkDetailPage extends ConsumerWidget {
  const WorkDetailPage({super.key, required this.workId});

  final String workId;

  /// Flex weights of the cover and the title column in the header card.
  static const int _coverFlex = 2;
  static const int _infoFlex = 3;

  /// The generation id as shown: "LYR-" and the id's last six characters.
  static String displayId(String jobId) {
    final clean = jobId.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();
    return 'LYR-${clean.length <= 6 ? clean : clean.substring(clean.length - 6)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final work = ref.watch(workByIdProvider(workId));
    if (work == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final actions = WorkActions(context, ref);
    final region = RegionPresets.byCode(work.region);
    final language = MusicLyricLanguage.fromCode(work.lyricLanguage);
    final lyrics = lyricBlocks(
      work.lyrics,
      work.structure,
    ).where((b) => b.lines.isNotEmpty).toList();
    final generated = work.createdAt.toLocal();

    return Scaffold(
      body: PageFrame(
        header: const PushedHeader(),
        children: [
          SurfaceCard(
            onTap: work.isReady
                ? () => context.open(playerRouteFor(work))
                : null,
            child: Row(
              children: [
                Expanded(
                  flex: _coverFlex,
                  child: CoverArt(
                    seed: work.id,
                    image: SongletArt.cover(work),
                    radius: SongletRadius.control,
                  ),
                ),
                const SizedBox(width: SongletSpace.x4),
                Expanded(
                  flex: _infoFlex,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workTitle(l10n, work),
                        style: SongletType.title1.copyWith(color: c.ink),
                      ),
                      MetaLine(
                        textAlign: TextAlign.start,
                        parts: [
                          clockLabel(workDuration(work), l10n.localeName),
                          workGenre(l10n, work),
                          if (language != null) languageName(l10n, language),
                        ],
                      ),
                      const SizedBox(height: SongletSpace.x1),
                      MetaLine(
                        textAlign: TextAlign.start,
                        style: SongletType.footnote.copyWith(
                          color: c.inkSecondary,
                        ),
                        parts: [
                          l10n.detailGeneratedOn(generated),
                          work.isClip ? 'Lyria 3' : 'Lyria 3.5',
                        ],
                      ),
                      const SizedBox(height: SongletSpace.x3),
                      StatusPill(
                        label: switch (work.status) {
                          MusicWorkStatus.pending => l10n.libraryPending,
                          MusicWorkStatus.failed => l10n.libraryFailed,
                          MusicWorkStatus.ready =>
                            work.isClip
                                ? l10n.detailPreviewGenerated
                                : l10n.detailFullGenerated,
                        },
                        tone: work.status == MusicWorkStatus.failed
                            ? PillTone.danger
                            : PillTone.accent,
                        icon: work.status == MusicWorkStatus.ready
                            ? Icons.check_circle_rounded
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SongletSpace.x4),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.detailPromptUsed,
                  style: SongletType.title3.copyWith(color: c.ink),
                ),
                const SizedBox(height: SongletSpace.x3),
                InfoRow(
                  icon: Icons.card_giftcard_rounded,
                  label: l10n.detailOccasion,
                  value: workKindName(
                    l10n,
                    template: work.template,
                    occasion: work.occasion,
                  ),
                ),
                if (region != null)
                  InfoRow(
                    icon: Icons.place_outlined,
                    label: l10n.detailCountry,
                    value: countryName(l10n, region.code),
                  ),
                InfoRow(
                  icon: Icons.music_note_outlined,
                  label: l10n.detailGenre,
                  value: workGenre(l10n, work),
                ),
                if (work.keywords.isNotEmpty)
                  InfoRow(
                    icon: Icons.sell_outlined,
                    label: l10n.detailKeywords,
                    value: work.keywords.join(', '),
                  ),
                if (work.prompt.isNotEmpty)
                  InfoRow(
                    icon: Icons.notes_rounded,
                    label: l10n.detailDescription,
                    value: work.prompt,
                  ),
              ],
            ),
          ),
          if (lyrics.isNotEmpty && !work.isInstrumental) ...[
            const SizedBox(height: SongletSpace.x4),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.detailLyrics,
                    style: SongletType.title3.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: SongletSpace.x2),
                  for (final block in lyrics)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: SongletSpace.x3,
                      ),
                      child: Text(
                        block.lines.join('\n'),
                        style: SongletType.callout.copyWith(color: c.ink),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (work.jobId != null) ...[
            const SizedBox(height: SongletSpace.x4),
            SurfaceCard(
              child: TestId(
                'detail.id',
                child: CopyField(
                  label: l10n.detailGenerationId,
                  value: displayId(work.jobId!),
                  copyLabel: l10n.commonCopy,
                  onCopy: () async {
                    await Clipboard.setData(ClipboardData(text: work.jobId!));
                    ref
                        .read(messageControllerProvider)
                        .success(l10n.commonCopied);
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: SongletSpace.x4),
          _VideosCard(work: work),
          const SizedBox(height: SongletSpace.x5),
          TestId(
            'detail.regenerate',
            child: ObsButton(
              label: l10n.detailRegenerate,
              icon: Icons.autorenew_rounded,
              onPressed: () => actions.anotherVersion(work),
            ),
          ),
          const SizedBox(height: SongletSpace.x3),
          TestId(
            'detail.delete',
            child: SecondaryButton(
              label: l10n.commonDelete,
              icon: Icons.delete_outline_rounded,
              destructive: true,
              onPressed: () => actions.delete(work),
            ),
          ),
        ],
      ),
    );
  }
}

/// The music videos made from this work (PRD ch.15), newest first, and the
/// way to make one. Videos still being made or that failed are listed too so
/// the user sees where their credits went.
class _VideosCard extends ConsumerWidget {
  const _VideosCard({required this.work});

  final MusicWork work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final videos = ref.watch(musicVideosOfWorkProvider(work.id));
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.detailVideos,
            style: SongletType.title3.copyWith(color: c.ink),
          ),
          const SizedBox(height: SongletSpace.x2),
          for (final video in videos)
            TestId(
              'detail.video.${video.id}',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  switch (video.status) {
                    MusicWorkStatus.ready => Icons.movie_rounded,
                    MusicWorkStatus.pending => Icons.hourglass_top_rounded,
                    MusicWorkStatus.failed => Icons.error_outline_rounded,
                  },
                  color: video.status == MusicWorkStatus.failed
                      ? c.danger
                      : c.accent,
                ),
                title: Text(
                  mvLevelName(l10n, video.level),
                  style: SongletType.body.copyWith(color: c.ink),
                ),
                subtitle: Text(
                  [
                    mvStatusName(l10n, video.status),
                    if (video.creditsCharged > 0)
                      l10n.mvPriceCredits(video.creditsCharged),
                    DateFormat.yMMMd(
                      l10n.localeName,
                    ).format(video.createdAt.toLocal()),
                  ].join(' · '),
                  style: SongletType.footnote.copyWith(color: c.inkSecondary),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                // Making → its progress; failed → why (P25); ready → the video.
                onTap: () => context.open(mvRouteFor(video)),
              ),
            ),
          if (videos.isNotEmpty) const SizedBox(height: SongletSpace.x2),
          TestId(
            'detail.makeVideo',
            child: SecondaryButton(
              label: l10n.detailMakeVideo,
              icon: Icons.movie_creation_outlined,
              onPressed: work.isReady
                  ? () => context.open(MvRoute(work.id))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
