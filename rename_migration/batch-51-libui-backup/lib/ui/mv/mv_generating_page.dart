import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/error_retry_view.dart';
import '../common/localized_formats.dart';
import '../common/messages.dart';
import '../common/page_layout.dart';
import '../common/test_id.dart';
import '../player/work_actions.dart';
import '../player/work_title.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';
import 'mv_labels.dart';

/// P24 — one music video being made (PRD §15.2 step 4), followed by id
/// whichever path started it (ADR-0021): the platform's stage, its real
/// progress (never advanced by a clock), scenes, time left, and Cancel with
/// its two outcomes. The user can leave: the video goes on, a notification
/// says when it should be ready (ADR-0025).
///
/// P25 — the same page once the video failed: what happened, the credits
/// that came back, and the way on (adjust the photos, a chorus video instead
/// of a too-long full one, make the song again, or try again).
class MvGeneratingPage extends ConsumerStatefulWidget {
  const MvGeneratingPage({
    super.key,
    required this.workId,
    required this.videoId,
  });

  final String workId;
  final String videoId;

  @override
  ConsumerState<MvGeneratingPage> createState() => _MvGeneratingPageState();
}

class _MvGeneratingPageState extends ConsumerState<MvGeneratingPage> {
  bool _cancelling = false;
  bool _left = false;

  /// The queued anchor shown before the first snapshot (contract 04 §3).
  static const double queuedProgress = 0.02;

  MusicMvController get _controller => ref.read(mvControllerProvider.notifier);

  void _leaveFor(AppRoute route) {
    if (_left) return;
    _left = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.goTo(route);
    });
  }

  Future<void> _cancel({required bool queued}) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.mvCancelTitle),
        content: Text(queued ? l10n.mvCancelQueued : l10n.mvCancelStarted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.commonKeepGoing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.mvCancelConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messages = ref.read(messageControllerProvider);
    setState(() => _cancelling = true);
    try {
      final outcome = await _controller.cancelVideo(widget.videoId);
      if (!mounted || outcome == null) return;
      switch (outcome.result) {
        case MusicMvCancelResult.cancelled:
          messages.info(l10n.mvCancelledRefunded);
          _leaveFor(MvRoute(widget.workId));
        case MusicMvCancelResult.cancelRequested:
          messages.info(l10n.mvCancelRequested);
      }
    } on Object catch (error, stackTrace) {
      final failure = ref.read(errorHandlerProvider).handle(error, stackTrace);
      if (MusicErrorCode.of(failure) == MusicErrorCode.jobAlreadyFinished) {
        messages.info(l10n.errorJobAlreadyFinished);
      } else {
        messages.show(failureMessage(l10n, failure));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final work = ref.watch(workByIdProvider(widget.workId));
    final videos = ref.watch(musicVideosProvider);
    final video = ref.watch(musicVideoByIdProvider(widget.videoId));
    final snapshot = ref.watch(mvProgressProvider(widget.videoId)).value;
    final session = ref.watch(mvControllerProvider);
    final preparing =
        session is MusicMvPreparing && session.videoId == widget.videoId
        ? session
        : null;
    final failedBeforeTicket =
        session is MusicMvFailed &&
            session.request?.clientRef == widget.videoId &&
            session.videoId == null
        ? session
        : null;

    final Widget body;
    if (video == null) {
      if (preparing != null) {
        body = _Progress(
          level: preparing.level,
          work: work,
          stage: switch (preparing.step) {
            MusicMvPreparingStep.uploadingPhotos => l10n.mvPreparingPhotos,
            MusicMvPreparingStep.submitting => l10n.mvPreparingSubmit,
          },
          progress: null,
        );
      } else if (failedBeforeTicket != null) {
        body = _FailureView(
          code: MusicErrorCode.of(failedBeforeTicket.failure),
          failure: failedBeforeTicket.failure,
          creditsBack: 0,
          photoCount: failedBeforeTicket.request?.photoBids.length ?? 0,
          workId: widget.workId,
          level: failedBeforeTicket.level,
          videoId: null,
        );
      } else if (videos.isLoading) {
        body = const Center(child: CircularProgressIndicator());
      } else {
        body = TestId(
          'mv.nothing',
          child: StatusView(
            title: l10n.mvNothing,
            icon: Icons.movie_outlined,
            actionLabel: l10n.commonBack,
            onAction: () => context.goTo(MvRoute(widget.workId)),
            expand: false,
          ),
        );
      }
    } else if (video.isReady) {
      _leaveFor(MvPlayerRoute(widget.workId, video.id));
      body = const Center(child: CircularProgressIndicator());
    } else if (video.status == MusicWorkStatus.failed) {
      final code = MusicErrorCode.fromWire(video.errorCode);
      body = code == MusicErrorCode.userCancelled
          ? TestId(
              'mv.stopped',
              child: StatusView(
                title: l10n.mvCancelled,
                message: l10n.mvCancelStarted,
                icon: Icons.stop_circle_outlined,
                actionLabel: l10n.commonBack,
                onAction: () => context.goTo(MvRoute(widget.workId)),
                expand: false,
              ),
            )
          : _FailureView(
              code: code,
              failure: code == null
                  ? ServerFailure(message: '', errorCode: video.errorCode)
                  : ref.read(errorHandlerProvider).handle(code.toApiError()),
              creditsBack: code != null && code.isRefunded
                  ? video.creditsCharged
                  : 0,
              photoCount: video.photoCount,
              workId: widget.workId,
              level: video.level,
              videoId: video.id,
            );
    } else {
      final queued = snapshot == null || snapshot.status == MusicJobStatus.queued;
      final cancelRequested = snapshot?.cancelRequested ?? false;
      body = _Progress(
        level: video.level,
        work: work,
        stage:
            mvStageName(l10n, queued ? 'queued' : snapshot.stage) ??
            l10n.mvGeneratingTitle,
        progress: snapshot?.progress ?? queuedProgress,
        showPercent: snapshot?.progress != null,
        segments: (snapshot?.segmentsDone, snapshot?.segmentsTotal),
        remainingSeconds: snapshot?.etaSeconds,
        cancelRequested: cancelRequested,
        onCancel: cancelRequested || _cancelling
            ? null
            : () => _cancel(queued: queued),
        cancelling: _cancelling,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: SongletSize.contentMaxWidth,
            ),
            child: TestId('mv.generating', child: body),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.level,
    required this.work,
    required this.stage,
    required this.progress,
    this.showPercent = false,
    this.segments = (null, null),
    this.remainingSeconds,
    this.cancelRequested = false,
    this.onCancel,
    this.cancelling = false,
  });

  final MusicMvLevel level;
  final MusicWork? work;
  final String stage;

  /// Null while nothing exists on the platform yet (upload / submit).
  final double? progress;
  final bool showPercent;
  final (int?, int?) segments;
  final int? remainingSeconds;
  final bool cancelRequested;
  final VoidCallback? onCancel;
  final bool cancelling;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final gutter = pageGutter(context);
    final value = progress;
    final (done, total) = segments;
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        gutter,
        SongletSpace.x3,
        gutter,
        SongletSpace.x8,
      ),
      children: [
        const PushedHeader(),
        const SizedBox(height: SongletSpace.x4),
        if (cancelRequested) ...[
          TestId(
            'mv.cancelRequested',
            child: NoteBanner(
              icon: Icons.stop_circle_outlined,
              message: l10n.mvCancelRequested,
            ),
          ),
          const SizedBox(height: SongletSpace.x4),
        ],
        Center(child: PulsingMark(label: l10n.mvGeneratingTitle)),
        TestId(
          'mv.progressTitle',
          child: Text(
            l10n.mvGeneratingTitle,
            textAlign: TextAlign.center,
            style: SongletType.title1.copyWith(color: c.ink),
          ),
        ),
        const SizedBox(height: SongletSpace.x2),
        TestId(
          'mv.stage',
          child: Text(
            stage,
            textAlign: TextAlign.center,
            style: SongletType.body.copyWith(color: c.inkSecondary),
          ),
        ),
        const SizedBox(height: SongletSpace.x5),
        if (value == null)
          InlineProgressBanner(icon: Icons.cloud_upload_outlined, title: stage)
        else
          TestId(
            'mv.progress',
            child: ProgressMeter(
              value: value,
              percentLabel: showPercent
                  ? l10n.generatingPercent(
                      progressPercent(value, l10n.localeName),
                    )
                  : null,
              semanticsLabel: l10n.generatingProgress,
            ),
          ),
        if (total != null && total > 0) ...[
          const SizedBox(height: SongletSpace.x2),
          TestId(
            'mv.scenes',
            child: Text(
              l10n.mvScenes(done ?? 0, total),
              textAlign: TextAlign.center,
              style: SongletType.footnote.copyWith(color: c.inkSecondary),
            ),
          ),
        ],
        const SizedBox(height: SongletSpace.x4),
        MetaLine(
          parts: [
            mvLevelName(l10n, level),
            if (work != null) workTitle(l10n, work!),
            if (remainingSeconds case final remaining? when remaining > 0)
              l10n.mvUsuallyMinutes(
                (remaining / Duration.secondsPerMinute).ceil().clamp(1, 99),
              ),
          ],
        ),
        const SizedBox(height: SongletSpace.x4),
        TestId(
          'mv.leaveHint',
          child: Text(
            l10n.mvLeaveHint,
            textAlign: TextAlign.center,
            style: SongletType.footnote.copyWith(color: c.inkTertiary),
          ),
        ),
        const SizedBox(height: SongletSpace.x2),
        if (onCancel != null || cancelling)
          Center(
            child: TestId(
              'mv.cancel',
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: c.accent),
                child: Text(l10n.commonCancel),
              ),
            ),
          ),
      ],
    );
  }
}

/// P25 — the video failed. The credits line only states what the platform
/// refunded (a refunded code on a charged video); nothing is computed here.
class _FailureView extends ConsumerWidget {
  const _FailureView({
    required this.code,
    required this.failure,
    required this.creditsBack,
    required this.photoCount,
    required this.workId,
    required this.level,
    required this.videoId,
  });

  final MusicErrorCode? code;
  final Failure failure;
  final int creditsBack;
  final int photoCount;
  final String workId;
  final MusicMvLevel level;

  /// The failed video (its options prefill the retry); null when it never
  /// reached the platform.
  final String? videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final retry = MvRoute(workId, level: level, from: videoId);
    final rejected =
        code == MusicErrorCode.imageRejected ||
        code == MusicErrorCode.safetyBlocked;
    final described = describeFailure(l10n, failure);
    void regenerateSong() {
      final work = ref.read(workByIdProvider(workId));
      if (work != null) {
        unawaited(WorkActions(context, ref).anotherVersion(work));
      }
    }

    final (
      String title,
      String message,
      IconData icon,
      String actionLabel,
      VoidCallback onPressed,
    ) = switch (code) {
      _ when rejected && photoCount > 0 => (
        l10n.mvRejectedTitle,
        l10n.mvRejectedBody,
        Icons.no_photography_outlined,
        l10n.mvAdjustPhotos,
        () => context.goTo(retry),
      ),
      MusicErrorCode.mvSongTooLong => (
        l10n.mvFailedTitle,
        described.message,
        Icons.timer_off_outlined,
        l10n.mvTryChorus,
        () =>
            context.goTo(MvRoute(workId, level: MusicMvLevel.chorus, from: videoId)),
      ),
      MusicErrorCode.mvSongExpired || MusicErrorCode.mvSongNotReady => (
        l10n.mvFailedTitle,
        described.message,
        Icons.music_off_outlined,
        l10n.mvSongExpiredAction,
        regenerateSong,
      ),
      MusicErrorCode.mvPhotosExpired => (
        l10n.mvFailedTitle,
        described.message,
        Icons.photo_library_outlined,
        l10n.mvAdjustPhotos,
        () => context.goTo(retry),
      ),
      _ => (
        l10n.mvFailedTitle,
        described.message,
        described.icon,
        l10n.commonRetry,
        () => context.goTo(retry),
      ),
    };
    final gutter = pageGutter(context);
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        gutter,
        SongletSpace.x3,
        gutter,
        SongletSpace.x8,
      ),
      children: [
        const PushedHeader(),
        const SizedBox(height: SongletSpace.x6),
        TestId(
          rejected ? 'mv.rejected' : 'mv.failure',
          child: StatusView(
            title: title,
            message: message,
            icon: icon,
            expand: false,
          ),
        ),
        if (creditsBack > 0) ...[
          const SizedBox(height: SongletSpace.x3),
          Center(
            child: TestId(
              'mv.creditsBack',
              child: StatusPill(
                label: l10n.mvCreditsBack(creditsBack),
                tone: PillTone.success,
                icon: Icons.undo_rounded,
              ),
            ),
          ),
        ],
        if (rejected && photoCount > 0) ...[
          const SizedBox(height: SongletSpace.x3),
          Text(
            l10n.mvPhotosCount(photoCount),
            textAlign: TextAlign.center,
            style: SongletType.footnote.copyWith(color: c.inkSecondary),
          ),
        ],
        const SizedBox(height: SongletSpace.x5),
        TestId(
          'mv.failureAction',
          child: ObsButton(label: actionLabel, onPressed: onPressed),
        ),
      ],
    );
  }
}
