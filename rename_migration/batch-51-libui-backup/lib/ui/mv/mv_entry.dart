import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/localized_formats.dart';
import '../common/messages.dart';
import '../common/test_id.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';
import 'mv_labels.dart';

/// Where a video leads: its progress (or failure) until it is ready, then
/// the player.
AppRoute mvRouteFor(MusicVideo video) => video.isReady
    ? MvPlayerRoute(video.workId, video.id)
    : MvGenerateRoute(video.workId, video.id);

/// Percent label of a platform progress value.
String mvPercent(AppLocalizations l10n, double progress) =>
    l10n.generatingPercent(progressPercent(progress, l10n.localeName));

/// P19 — "Make it a video" on the song page (P09) and the work detail
/// (P13): the song's latest video (making · ready) and the way into the hub.
/// Disabled until the song is finished (the platform would answer
/// `MV_SONG_NOT_READY`).
class MvEntryCard extends ConsumerWidget {
  const MvEntryCard({super.key, required this.work});

  final MusicWork work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final videos = ref.watch(musicVideosOfWorkProvider(work.id));
    final making = videos.where((v) => v.isPending).firstOrNull;
    final ready = videos.where((v) => v.isReady).firstOrNull;
    final available = work.isReady && work.jobId != null;
    final progress = making == null
        ? null
        : ref.watch(mvProgressProvider(making.id)).value?.progress;

    final Widget? status = switch ((making, ready)) {
      (MusicVideo(), _) => StatusPill(
        label: progress == null
            ? l10n.mvChipMaking
            : l10n.mvChipMakingWithProgress(mvPercent(l10n, progress)),
        icon: Icons.hourglass_top_rounded,
      ),
      (null, final MusicVideo r) => StatusPill(
        label: mvLevelName(l10n, r.level),
        tone: PillTone.success,
        icon: Icons.movie_rounded,
      ),
      _ => null,
    };

    return TestId(
      'mv.entry',
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.movie_creation_outlined,
                  color: available ? c.accent : c.inkTertiary,
                  size: SongletSize.iconLg,
                ),
                const SizedBox(width: SongletSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mvEntryTitle,
                        style: SongletType.headline.copyWith(
                          color: available ? c.ink : c.inkTertiary,
                        ),
                      ),
                      Text(
                        available ? l10n.mvEntrySubtitle : l10n.mvEntryDisabled,
                        style: SongletType.footnote.copyWith(
                          color: c.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status != null) ...[
              const SizedBox(height: SongletSpace.x3),
              Align(alignment: AlignmentDirectional.centerStart, child: status),
            ],
            const SizedBox(height: SongletSpace.x3),
            Wrap(
              spacing: SongletSpace.x2,
              runSpacing: SongletSpace.x2,
              children: [
                if (making != null)
                  TestId(
                    'mv.entry.progress',
                    child: SecondaryButton(
                      label: l10n.mvViewProgress,
                      icon: Icons.hourglass_top_rounded,
                      onPressed: () =>
                          context.open(MvGenerateRoute(work.id, making.id)),
                    ),
                  )
                else if (ready != null)
                  TestId(
                    'mv.entry.watch',
                    child: SecondaryButton(
                      label: l10n.mvEntryWatch,
                      icon: Icons.play_circle_outline_rounded,
                      onPressed: () =>
                          context.open(MvPlayerRoute(work.id, ready.id)),
                    ),
                  ),
                TestId(
                  'mv.entry.open',
                  child: SecondaryButton(
                    label: l10n.mvEntryChoose,
                    icon: Icons.movie_filter_outlined,
                    onPressed: available
                        ? () => context.open(MvRoute(work.id))
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// P19 — the video state of a library row (P12): making or ready; nothing
/// when the song has no video.
class MvStatusChip extends ConsumerWidget {
  const MvStatusChip({super.key, required this.workId});

  final String workId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(mvStatusOfWorkProvider(workId))) {
      MusicWorkVideoStatus.none => const SizedBox.shrink(),
      MusicWorkVideoStatus.making => TestId(
        'library.video.$workId',
        child: StatusPill(
          label: l10n.mvChipMaking,
          tone: PillTone.neutral,
          icon: Icons.hourglass_top_rounded,
        ),
      ),
      MusicWorkVideoStatus.ready => TestId(
        'library.video.$workId',
        child: StatusPill(
          label: l10n.mvChipReady,
          tone: PillTone.success,
          icon: Icons.movie_rounded,
        ),
      ),
    };
  }
}

/// P23 — the automatic video of a song, in place on its player (ADR-0022):
/// the countdown (cancellable, nothing charged yet), the video being
/// made with its real progress, then Watch / Make a chorus video.
class AutoVideoBanner extends ConsumerWidget {
  const AutoVideoBanner({super.key, required this.workId});

  final String workId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final task = ref.watch(autoVideoOfWorkProvider(workId));
    if (task == null) return const SizedBox.shrink();
    final coordinator = ref.read(autoVideoCoordinatorProvider.notifier);

    Widget wrap(Widget child) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: SongletSpace.x4),
      child: TestId('mv.auto', child: child),
    );

    if (task.isCountingDown) {
      final left = task.secondsLeft!;
      return wrap(
        InlineProgressBanner(
          icon: Icons.timer_outlined,
          title: l10n.mvAutoCountdown(mvLevelName(l10n, task.level), left),
          detail: l10n.mvAutoChorusDetail,
          value: 1 - left / MusicAutoVideoCoordinator.countdownSeconds,
          actionLabel: l10n.commonCancel,
          onAction: () => coordinator.cancelCountdown(workId),
        ),
      );
    }
    final failure = task.failure;
    if (failure != null) {
      return wrap(
        InlineErrorBanner(
          message: l10n.mvAutoFailureMessage(
            failureMessage(l10n, failure).text,
          ),
          actionLabel: l10n.commonClose,
          onAction: () => coordinator.dismiss(workId),
        ),
      );
    }
    final videoId = task.videoId;
    final video = videoId == null
        ? null
        : ref.watch(musicVideoByIdProvider(videoId));
    if (videoId == null || video == null || video.isPending) {
      final snapshot = videoId == null
          ? null
          : ref.watch(mvProgressProvider(videoId)).value;
      final progress = snapshot?.progress;
      return wrap(
        InlineProgressBanner(
          icon: task.level == MusicMvLevel.lyricVideo
              ? Icons.subtitles_outlined
              : Icons.music_video_outlined,
          title: task.level == MusicMvLevel.lyricVideo
              ? l10n.mvAutoLyricMaking
              : l10n.mvGeneratingTitle,
          detail: mvStageName(l10n, snapshot?.stage),
          value: progress,
          percentLabel: progress == null ? null : mvPercent(l10n, progress),
          actionLabel: videoId == null ? null : l10n.mvAutoView,
          onAction: videoId == null
              ? null
              : () => context.open(MvGenerateRoute(workId, videoId)),
        ),
      );
    }
    if (!video.isReady) {
      return wrap(
        InlineErrorBanner(
          message: l10n.mvFailedTitle,
          actionLabel: l10n.mvAutoView,
          onAction: () {
            coordinator.dismiss(workId);
            context.open(mvRouteFor(video));
          },
        ),
      );
    }
    final c = SongletColors.of(context);
    return wrap(
      SurfaceCard(
        padding: const EdgeInsetsDirectional.all(SongletSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.movie_rounded,
                  color: c.success,
                  size: SongletSize.iconLg,
                ),
                const SizedBox(width: SongletSpace.x3),
                Expanded(
                  child: Text(
                    l10n.mvAutoReady(mvLevelName(l10n, video.level)),
                    style: SongletType.subhead.copyWith(
                      color: c.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.commonClose,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => coordinator.dismiss(workId),
                ),
              ],
            ),
            const SizedBox(height: SongletSpace.x2),
            Wrap(
              spacing: SongletSpace.x2,
              runSpacing: SongletSpace.x2,
              children: [
                TestId(
                  'mv.auto.watch',
                  child: SecondaryButton(
                    label: l10n.mvEntryWatch,
                    icon: Icons.play_circle_outline_rounded,
                    onPressed: () =>
                        context.open(MvPlayerRoute(workId, video.id)),
                  ),
                ),
                if (video.level == MusicMvLevel.lyricVideo)
                  TestId(
                    'mv.auto.upgrade',
                    child: SecondaryButton(
                      label: l10n.mvUpgradeChorus,
                      icon: Icons.music_video_outlined,
                      onPressed: () => context.open(
                        MvRoute(workId, level: MusicMvLevel.chorus, from: video.id),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
