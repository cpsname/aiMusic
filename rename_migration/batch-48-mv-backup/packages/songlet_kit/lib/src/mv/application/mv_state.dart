import 'package:infra_core/infra_core.dart';
import 'package:meta/meta.dart';

import '../../creation/domain/music_generation.dart';
import '../domain/music_video.dart';
import '../domain/mv.dart';

/// Where one music video stands (PRD ch.15; ADR-0020).
@immutable
sealed class MvState {
  const MvState();

  /// The hub session cannot start anything else right now. A submitted
  /// video ([MvWaiting]) is not busy: it runs on (followed by id, ADR-0021)
  /// while the hub prices and makes other videos.
  bool get isBusy => switch (this) {
        MvEstimating() || MvPreparing() => true,
        _ => false,
      };
}

final class MvIdle extends MvState {
  const MvIdle();
}

/// `POST /v1/mv/estimate` in flight.
final class MvEstimating extends MvState {
  const MvEstimating({required this.workId, required this.level});

  final String workId;
  final MvLevel level;
}

/// Prices are known; the hub shows them and offers Make video (or the
/// pack). [estimates] holds every level priced so far for [workId] — all
/// three after `estimateAll` (docs/ui P20), a level that failed to price is
/// absent; [level] is the one priced last.
final class MvEstimated extends MvState {
  const MvEstimated({required this.workId, required this.level, required this.estimates});

  final String workId;
  final MvLevel level;
  final Map<MvLevel, MvEstimate> estimates;

  /// The estimate of [level].
  MvEstimate get estimate => estimates[level]!;

  MvEstimate? of(MvLevel level) => estimates[level];
}

/// Local steps before the MV exists (upload of reference photos, submit).
enum MvPreparingStep { uploadingPhotos, submitting }

final class MvPreparing extends MvState {
  const MvPreparing({required this.workId, required this.videoId, required this.level, required this.step});

  final String workId;

  /// The id the video will have (= the request's `client_ref`).
  final String videoId;
  final MvLevel level;
  final MvPreparingStep step;
}

/// Submitted — polling the platform. Every field comes from the last
/// snapshot; nothing here is derived from the clock.
final class MvWaiting extends MvState {
  const MvWaiting({
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
  final MvLevel level;
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

  MvWaiting withSnapshot(MvSnapshot snapshot) => MvWaiting(
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

  MvWaiting copyWith({bool? cancelling, bool? cancelRequested}) => MvWaiting(
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
final class MvQuotaGap extends MvState {
  const MvQuotaGap({
    required this.failure,
    required this.workId,
    required this.request,
    required this.gap,
  });

  final Failure failure;
  final String workId;
  final MvRequest request;
  final QuotaGap gap;

  MvLevel get level => request.level;
}

final class MvSucceeded extends MvState {
  const MvSucceeded(this.video);

  final MusicVideo video;
}

/// The video was not made. [request] lets the page retry the same video. A
/// `QUOTA_EXHAUSTED` with its gap is never a failure — it is [MvQuotaGap].
final class MvFailed extends MvState {
  const MvFailed(
    this.failure, {
    required this.workId,
    required this.level,
    this.request,
    this.videoId,
  });

  final Failure failure;
  final String workId;
  final MvLevel level;
  final MvRequest? request;

  /// Set when an MV existed and ended `failed` (kept in the library with its
  /// error code).
  final String? videoId;
}
