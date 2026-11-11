import 'package:infra_core/infra_core.dart';
import 'package:meta/meta.dart';

import '../../library/domain/work.dart';
import '../domain/music_creation_draft.dart';
import '../domain/music_generation.dart';
import '../domain/preflight.dart';

/// Where one generation stands (PRD §3.1 E / H, F12 "排队、重试、失败退额").
@immutable
sealed class GenerationState {
  const GenerationState();

  bool get isBusy => switch (this) {
        GenerationPreparing() || GenerationWaiting() => true,
        _ => false,
      };
}

final class GenerationIdle extends GenerationState {
  const GenerationIdle();
}

/// Local steps before the job exists.
enum PreparingStep { checking, polishing, uploadingPhotos, submitting }

final class GenerationPreparing extends GenerationState {
  const GenerationPreparing(this.model, this.step);

  final SongModel model;
  final PreparingStep step;
}

/// Submitted — waiting for Lyria (typically ≤ 45 s for a clip).
final class GenerationWaiting extends GenerationState {
  const GenerationWaiting({
    required this.model,
    required this.workId,
    required this.jobId,
    required this.etaSeconds,
    required this.startedAt,
    this.status = JobStatus.queued,
    this.hint,
    this.progress,
    this.queuePosition,
    this.remainingSeconds,
    this.lyricsPreview = const <String>[],
    this.cancelling = false,
  });

  final SongModel model;
  final String workId;
  final String jobId;
  final int etaSeconds;
  final DateTime startedAt;
  final JobStatus status;

  /// `UPSTREAM_RATE_LIMITED` (queued) / `UPSTREAM_TIMEOUT` (retrying) while
  /// the job is still alive — shown as reassurance, not as an error.
  final String? hint;

  /// Server progress 0–1 when reported (ADR-0012); else the page derives it
  /// from [startedAt] and [etaSeconds].
  final double? progress;

  /// Queue position while queued (docs/ui P06). The platform does not report
  /// one today (contract v2 §3), so this is normally null.
  final int? queuePosition;

  /// Server estimate of the remaining seconds.
  final int? remainingSeconds;

  /// "A glimpse of your song" lines (docs/ui P05).
  final List<String> lyricsPreview;

  /// A cancel request is in flight.
  final bool cancelling;

  /// Queued behind other songs (the P06 banner) — from the status alone.
  bool get isQueued => status == JobStatus.queued;

  /// Applies a poll [snapshot]; fields the server omits keep their value.
  GenerationWaiting withSnapshot(JobSnapshot snapshot) => GenerationWaiting(
        model: model,
        workId: workId,
        jobId: jobId,
        etaSeconds: etaSeconds,
        startedAt: startedAt,
        status: snapshot.status,
        hint: snapshot.errorCode,
        progress: snapshot.progress ?? progress,
        queuePosition:
            snapshot.status == JobStatus.queued ? snapshot.queuePosition : null,
        remainingSeconds: snapshot.etaSeconds ?? remainingSeconds,
        lyricsPreview: snapshot.lyricsPreview.isEmpty
            ? lyricsPreview
            : snapshot.lyricsPreview,
        cancelling: cancelling,
      );

  GenerationWaiting copyWith({bool? cancelling}) => GenerationWaiting(
        model: model,
        workId: workId,
        jobId: jobId,
        etaSeconds: etaSeconds,
        startedAt: startedAt,
        status: status,
        hint: hint,
        progress: progress,
        queuePosition: queuePosition,
        remainingSeconds: remainingSeconds,
        lyricsPreview: lyricsPreview,
        cancelling: cancelling ?? this.cancelling,
      );
}

final class GenerationSucceeded extends GenerationState {
  const GenerationSucceeded(this.work);

  final Work work;
}

/// The draft did not pass the local preflight (PRD §7.4) — nothing was sent.
final class GenerationRejected extends GenerationState {
  const GenerationRejected(this.issues);

  final List<PreflightIssue> issues;
}

final class GenerationFailed extends GenerationState {
  const GenerationFailed(this.failure, {this.model, this.draft, this.workId});

  final Failure failure;
  final SongModel? model;

  /// The draft to retry with.
  final MusicCreationDraft? draft;

  /// Set when a job exists but did not finish in time: it stays `pending` in
  /// the library and completes there.
  final String? workId;
}
