import 'package:infra_core/infra_core.dart';
import 'package:meta/meta.dart';

import '../../creation/domain/music_generation.dart';
import '../domain/music_video.dart';
import '../domain/music_mv.dart';

/// Where one music video stands (PRD ch.15; ADR-0020).
@immutable
sealed class MusicMvState {
  const MusicMvState();

  /// The hub session cannot start anything else right now. A submitted
  /// video ([MusicMvWaiting]) is not busy: it runs on (followed by id, ADR-0021)
  /// while the hub prices and makes other videos.
  bool get isBusy => switch (this) {
        MusicMvEstimating() || MusicMvPreparing() => true,
        _ => false,
      };
}

final class MusicMvIdle extends MusicMvState {
  const MusicMvIdle();
}

/// `POST /v1/mv/estimate` in flight.
final class MusicMvEstimating extends MusicMvState {
  const MusicMvEstimating({required this.workId, required this.level});

  final String workId;
  final MusicMvLevel level;
}

/// Prices are known; the hub shows them and offers Make video (or the
/// pack). [estimates] holds every level priced so far for [workId] — all
/// three after `estimateAll` (docs/ui P20), a level that failed to price is
/// absent; [level] is the one priced last.
final class MusicMvEstimated extends MusicMvState {
  const MusicMvEstimated({required this.workId, required this.level, required this.estimates});

  final String workId;
  final MusicMvLevel level;
  final Map<MusicMvLevel, MusicMvEstimate> estimates;

  /// The estimate of [level].
  MusicMvEstimate get estimate => estimates[level]!;

  MusicMvEstimate? of(MusicMvLevel level) => estimates[level];
}

/// Local steps before the MV exists (upload of reference photos, submit).
enum MusicMvPreparingStep { uploadingPhotos, submitting }

final class MusicMvPreparing extends MusicMvState {
  const MusicMvPreparing({required this.workId, required this.videoId, required this.level, required this.step});

  final String workId;

  /// The id the video will have (= the request's `client_ref`).
  final String videoId;
  final MusicMvLevel level;
  final MusicMvPreparingStep step;
}

/// Submitted — polling the platform. Every field comes from the last
/// snapshot; nothing here is derived from the clock.
final class MusicMvWaiting extends MusicMvState {
  const MusicMvWaiting({
    required this.workId,
    required this.videoId,
    required this.mvId,
    required this.level,
    required this.etaSeconds,
    required this.startedAt,
    this.status = MusicJobStatus.queued,
    this.stage,
    this.progress,
    this.segmentsDone,
    this.segmentsTotal,
    this.cancelRequested = false,
    this.remainingSeconds,
    this.cancelling = false,
  });

  final String workId;

  /// Local [MusicVideo] id.
  final String videoId;
  final String mvId;
  final MusicMvLevel level;
  final int etaSeconds;
  final DateTime startedAt;
  final MusicJobStatus status;
  final String? stage;

  /// Platform progress 0–1 when reported; null = no snapshot yet (the page
  /// shows the queued anchor, never a time-based guess).
  final double? progress;
  final int? segmentsDone;
  final int? segmentsTotal;

  /// The platform acknowledged a cancel and will stop at the next gap.
  final bool cancelRequested;
  final int? remainingSeconds;

  /// A cancel request is in flight.
  final bool cancelling;

  bool get isQueued => status == MusicJobStatus.queued;

  MusicMvWaiting withSnapshot(MusicMvSnapshot snapshot) => MusicMvWaiting(
        workId: workId,
        videoId: videoId,
        mvId: mvId,
        level: level,
        etaSeconds: etaSeconds,
        startedAt: startedAt,
        status: snapshot.status,
        stage: snapshot.stage ?? stage,
        progress: snapshot.progress ?? progress,
        segmentsDone: snapshot.segmentsDone,
        segmentsTotal: snapshot.segmentsTotal,
        cancelRequested: snapshot.cancelRequested || cancelRequested,
        remainingSeconds: snapshot.etaSeconds ?? remainingSeconds,
        cancelling: cancelling,
      );

  MusicMvWaiting copyWith({bool? cancelling, bool? cancelRequested}) => MusicMvWaiting(
        workId: workId,
        videoId: videoId,
        mvId: mvId,
        level: level,
        etaSeconds: etaSeconds,
        startedAt: startedAt,
        status: status,
        stage: stage,
        progress: progress,
        segmentsDone: segmentsDone,
        segmentsTotal: segmentsTotal,
        cancelRequested: cancelRequested ?? this.cancelRequested,
        remainingSeconds: remainingSeconds,
        cancelling: cancelling ?? this.cancelling,
      );
}

/// The platform refused the video for credits and said what to buy
/// (`QuotaExhaustedDetails`, docs/ui P22; ADR-0023). The request — photos
/// already uploaded — is kept as a pending intent; buying [gap]'s pack and
/// calling `retryIntent` sends it again.
final class MusicMvQuotaGap extends MusicMvState {
  const MusicMvQuotaGap({
    required this.failure,
    required this.workId,
    required this.request,
    required this.gap,
  });

  final Failure failure;
  final String workId;
  final MusicMvRequest request;
  final MusicQuotaGap gap;

  MusicMvLevel get level => request.level;
}

final class MusicMvSucceeded extends MusicMvState {
  const MusicMvSucceeded(this.video);

  final MusicVideo video;
}

/// The video was not made. [request] lets the page retry the same video. A
/// `QUOTA_EXHAUSTED` with its gap is never a failure — it is [MusicMvQuotaGap].
final class MusicMvFailed extends MusicMvState {
  const MusicMvFailed(
    this.failure, {
    required this.workId,
    required this.level,
    this.request,
    this.videoId,
  });

  final Failure failure;
  final String workId;
  final MusicMvLevel level;
  final MusicMvRequest? request;

  /// Set when an MV existed and ended `failed` (kept in the library with its
  /// error code).
  final String? videoId;
}
