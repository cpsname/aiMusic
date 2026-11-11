import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:uuid/uuid.dart';

import '../../creation/application/music_creation_providers.dart';
import '../../creation/application/music_job_runner.dart' show MusicJobTimeoutException;
import '../../creation/domain/music_error_code.dart';
import '../../library/application/music_library_providers.dart';
import '../../library/domain/music_work.dart';
import '../domain/music_mv.dart';
import '../domain/music_mv_intent.dart';
import 'music_mv_launcher.dart';
import 'music_mv_providers.dart';
import 'music_mv_runner.dart';
import 'music_mv_state.dart';

/// One music video, end to end (PRD ch.15): price check → device attestation
/// → reference-photo upload → `POST /v1/works/{job_id}/mv` → poll → download
/// → library. Charging and refunds are server-side; after every terminal
/// outcome the entitlement is refreshed so the counters follow the ledger.
///
/// A `QUOTA_EXHAUSTED` carries the credit gap (contract v1.1
/// `QuotaExhaustedDetails`): the controller keeps the request as a pending
/// [MusicMvIntent] and settles in [MusicMvQuotaGap]; once the recommended pack is
/// bought, [retryIntent] sends the same request again (ADR-0023).
class MusicMvController extends Notifier<MusicMvState> {
  /// Attempts of [retryIntent]: right away, then after 2 s and 5 s — the
  /// ledger may credit a verified purchase a moment after StoreKit returns.
  static const List<Duration> purchaseRetryDelays = [
    Duration.zero,
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  bool _disposed = false;

  /// Videos cancelled from this session: their runs stop polling.
  final Set<String> _cancelledVideos = {};

  @override
  MusicMvState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const MusicMvIdle();
  }

  bool _stopped(String videoId) => _disposed || _cancelledVideos.contains(videoId);

  /// Whether the session still shows [videoId] (the hub may have moved on to
  /// pricing or another video; the run then goes on without writing here).
  bool _follows(String videoId) => switch (state) {
        MusicMvWaiting(videoId: final id) => id == videoId,
        _ => false,
      };

  MusicMvRunner get _runner => ref.read(mvRunnerProvider);
  ErrorHandler get _errors => ref.read(errorHandlerProvider);
  MusicMvIntentStore get _intents => ref.read(mvIntentStoreProvider);

  void reset() {
    if (!state.isBusy) state = const MusicMvIdle();
  }

  /// Prices [level] for [work] (locks the song on the platform), keeping the
  /// prices already known for the work. A failure lands in [MusicMvFailed] with
  /// no request to retry.
  Future<void> estimate(MusicWork work, MusicMvLevel level) async {
    if (state.isBusy) return;
    final jobId = _jobIdOrFail(work, level);
    if (jobId == null) return;
    final known = switch (state) {
      MusicMvEstimated(:final workId, :final estimates) when workId == work.id => estimates,
      _ => const <MusicMvLevel, MusicMvEstimate>{},
    };
    state = MusicMvEstimating(workId: work.id, level: level);
    try {
      await ref.read(authControllerProvider.notifier).ensureAuthenticated();
      final estimate = await ref.read(mvRepositoryProvider).estimate(jobId, level);
      if (_disposed) return;
      state = MusicMvEstimated(workId: work.id, level: level, estimates: {...known, level: estimate});
    } on Object catch (error, stackTrace) {
      if (_disposed) return;
      state = MusicMvFailed(_errors.handle(error, stackTrace), workId: work.id, level: level);
    }
  }

  /// Prices every level of [levels] at once (docs/ui P20 shows all three
  /// cards with their price). A level that fails to price is left out;
  /// only when none could be priced does the hub see [MusicMvFailed].
  Future<void> estimateAll(
    MusicWork work, {
    MusicMvLevel selected = MusicMvLevel.chorus,
    List<MusicMvLevel> levels = MusicMvLevel.values,
  }) async {
    if (state.isBusy) return;
    final jobId = _jobIdOrFail(work, selected);
    if (jobId == null) return;
    state = MusicMvEstimating(workId: work.id, level: selected);
    try {
      await ref.read(authControllerProvider.notifier).ensureAuthenticated();
      final repository = ref.read(mvRepositoryProvider);
      final results = await Future.wait([
        for (final level in levels)
          repository.estimate(jobId, level).then<Object>((e) => e, onError: (Object error, StackTrace stack) => (error, stack)),
      ]);
      if (_disposed) return;
      final estimates = <MusicMvLevel, MusicMvEstimate>{
        for (final result in results)
          if (result is MusicMvEstimate) result.level: result,
      };
      if (estimates.isEmpty) {
        final (error, stack) = results.first as (Object, StackTrace);
        state = MusicMvFailed(_errors.handle(error, stack), workId: work.id, level: selected);
        return;
      }
      state = MusicMvEstimated(
        workId: work.id,
        level: estimates.containsKey(selected) ? selected : estimates.keys.first,
        estimates: estimates,
      );
    } on Object catch (error, stackTrace) {
      if (_disposed) return;
      state = MusicMvFailed(_errors.handle(error, stackTrace), workId: work.id, level: selected);
    }
  }

  /// Makes the video. [photos] are picked JPEGs still to upload; [request]
  /// carries their bids once uploaded. A `QUOTA_EXHAUSTED` is tried again
  /// after each of [attemptDelays] beyond the first (same `client_ref`, so
  /// it can never charge twice) before settling in [MusicMvQuotaGap].
  Future<void> create(
    MusicWork work,
    MusicMvRequest request, {
    List<List<int>> photos = const [],
    List<Duration> attemptDelays = const [Duration.zero],
  }) async {
    if (state.isBusy) return;
    final jobId = _jobIdOrFail(work, request.level);
    if (jobId == null) return;
    var ready = request;
    String? videoId;
    try {
      await ref.read(authControllerProvider.notifier).ensureAuthenticated();

      if (photos.isNotEmpty) {
        state = MusicMvPreparing(workId: work.id, videoId: request.clientRef, level: request.level, step: MusicMvPreparingStep.uploadingPhotos);
        final uploader = ref.read(photoUploaderProvider);
        final bids = <String>[...request.photoBids];
        for (var i = 0; i < photos.length; i++) {
          bids.add(await uploader.upload(photos[i], filename: 'mv_photo_${i + 1}.jpg'));
        }
        ready = request.copyWith(photoBids: bids);
      }

      state = MusicMvPreparing(workId: work.id, videoId: ready.clientRef, level: request.level, step: MusicMvPreparingStep.submitting);
      final (video, ticket) = await ref.read(mvLauncherProvider).submit(
            work,
            ready,
            attemptDelays: attemptDelays,
            isStopped: () => _disposed,
          );
      if (_disposed) return;
      videoId = video.id;

      state = MusicMvWaiting(
        workId: work.id,
        videoId: video.id,
        mvId: ticket.mvId,
        level: ready.level,
        etaSeconds: ticket.etaSeconds,
        startedAt: DateTime.now(),
      );

      final running = _runner.run(
        video,
        etaSeconds: ticket.etaSeconds,
        isCancelled: () => _stopped(video.id),
        onSnapshot: (snapshot) {
          final current = state;
          if (_stopped(video.id) || current is! MusicMvWaiting || current.videoId != video.id) return;
          state = current.withSnapshot(snapshot);
        },
      );
      ref.invalidate(musicVideosProvider);
      // The platform froze the credits at creation.
      ref.invalidate(walletSnapshotProvider);
      final done = await running;
      if (_stopped(video.id)) return;
      ref.invalidate(musicVideosProvider);
      ref.invalidate(walletSnapshotProvider);
      if (!_follows(video.id)) return;

      if (done.status == MusicWorkStatus.ready) {
        state = MusicMvSucceeded(done);
      } else {
        final code = done.errorCode ?? MusicErrorCode.upstreamTimeout.wire;
        final typed = MusicErrorCode.fromWire(code);
        state = MusicMvFailed(
          typed == null
              ? ServerFailure(message: '', errorCode: code)
              : _errors.handle(typed.toApiError(), StackTrace.current),
          workId: work.id,
          level: ready.level,
          request: ready,
          videoId: done.id,
        );
      }
    } on MusicJobTimeoutException {
      if (_stopped(ready.clientRef) || (videoId != null && !_follows(videoId))) return;
      state = MusicMvFailed(
        _errors.handle(MusicErrorCode.upstreamTimeout.toApiError(), StackTrace.current),
        workId: work.id,
        level: ready.level,
        request: ready,
        videoId: videoId,
      );
    } on Object catch (error, stackTrace) {
      if (_stopped(ready.clientRef) || (videoId != null && !_follows(videoId))) return;
      final failure = _errors.handle(error, stackTrace);
      final gap = videoId == null ? MusicQuotaGap.of(failure) : null;
      if (gap != null) {
        await _intents.save(MusicMvIntent(workId: work.id, request: ready, createdAt: DateTime.now().toUtc()));
        state = MusicMvQuotaGap(failure: failure, workId: work.id, request: ready, gap: gap);
        return;
      }
      // A business refusal ends the intent; a transport failure keeps it for
      // a later resume.
      if (videoId == null && MusicMvLauncher.apiErrorOf(error) != null) await _intents.clear();
      state = MusicMvFailed(failure, workId: work.id, level: ready.level, request: ready, videoId: videoId);
      if (videoId != null) ref.invalidate(musicVideosProvider);
    }
  }

  /// The pending intent of [workId] (a refused video waiting for a pack), if
  /// any — the hub offers to finish it after a restart.
  MusicMvIntent? pendingIntent(String workId) {
    final intent = _intents.read();
    return intent?.workId == workId ? intent : null;
  }

  /// Sends the pending intent again after its pack was bought (docs/ui P22):
  /// the one in [MusicMvQuotaGap], else the stored one for [work]. Same
  /// `client_ref` while fresh ([MusicMvIntent.freshFor]); a new one past it — the
  /// refused attempt charged nothing. Retried per [mvRetryDelaysProvider]
  /// while the ledger has not yet credited the purchase.
  ///
  /// [attemptDelays] replaces the post-purchase schedule when the user asks
  /// again themselves (one attempt: the answer is wanted now).
  Future<void> retryIntent(MusicWork work, {List<Duration>? attemptDelays}) async {
    if (state.isBusy) return;
    final current = state;
    final intent = pendingIntent(work.id) ??
        (current is MusicMvQuotaGap && current.workId == work.id
            ? MusicMvIntent(workId: work.id, request: current.request, createdAt: DateTime.now().toUtc())
            : null);
    if (intent == null) return;
    final request = intent.isFresh(DateTime.now().toUtc())
        ? intent.request
        : intent.request.copyWith(clientRef: newMvClientRef());
    state = const MusicMvIdle();
    await create(work, request, attemptDelays: attemptDelays ?? ref.read(mvRetryDelaysProvider));
  }

  /// At launch (PRD §15.4 "购买中途 App 被杀仍能续做"): a fresh intent — the
  /// app was closed while its pack was being bought — is sent again; if the
  /// purchase did not land the platform refuses it again, charging nothing,
  /// and the hub offers it. A stale one is dropped: past an hour it no longer
  /// reflects a choice the user is waiting on.
  Future<void> resumeIntent() async {
    final intent = _intents.read();
    if (intent == null) return;
    if (!intent.isFresh(DateTime.now().toUtc())) {
      await _intents.clear();
      return;
    }
    final work = await ref.read(workRepositoryProvider).byId(intent.workId);
    if (work == null || !work.isReady) {
      await _intents.clear();
      return;
    }
    await retryIntent(work);
  }

  /// The user gave up on the pending intent (left the hub without buying).
  Future<void> discardIntent() async {
    await _intents.clear();
    if (state is MusicMvQuotaGap) state = const MusicMvIdle();
  }

  /// Re-submits the failed request (same `client_ref`, so a video the
  /// platform did accept is returned rather than made twice).
  Future<void> retry(MusicWork work) async {
    final current = state;
    if (current is! MusicMvFailed || current.request == null) return;
    state = const MusicMvIdle();
    await create(work, current.request!);
  }

  /// Cancels the video being made (platform ADR-037). Queued → cancelled and
  /// refunded at once (the local record is removed). Rendering →
  /// `cancel_requested`: the platform stops at the next gap and the run ends
  /// `failed / USER_CANCELLED`, whose terminal balances carry the partial
  /// refund. Returns the platform's answer; null when nothing was running.
  Future<MusicMvCancelOutcome?> cancel() async {
    final current = state;
    if (current is! MusicMvWaiting || current.cancelling) return null;
    state = current.copyWith(cancelling: true);
    try {
      final outcome = await ref.read(mvRepositoryProvider).cancel(current.mvId);
      if (outcome.result == MusicMvCancelResult.cancelled) {
        _cancelledVideos.add(current.videoId);
        unawaited(ref.read(mvNotificationsProvider).cancelFor(current.videoId));
        await ref.read(musicVideoRepositoryProvider).delete(current.videoId);
        ref.invalidate(musicVideosProvider);
        ref.invalidate(walletSnapshotProvider);
        state = const MusicMvIdle();
      } else {
        final latest = state;
        if (latest is MusicMvWaiting) {
          state = latest.copyWith(cancelling: false, cancelRequested: true);
        }
      }
      return outcome;
    } on Object catch (error, stackTrace) {
      _errors.handle(error, stackTrace);
      final latest = state;
      if (latest is MusicMvWaiting) state = latest.copyWith(cancelling: false);
      rethrow;
    }
  }

  /// Cancels [videoId] whoever runs it — this session, the automatic path
  /// or the resume after a restart (docs/ui P24, ADR-0021). Queued →
  /// cancelled and refunded: the run is abandoned and the record removed.
  /// Rendering → `cancel_requested`: the run goes on to `USER_CANCELLED`.
  /// Returns null when there is no such pending video.
  Future<MusicMvCancelOutcome?> cancelVideo(String videoId) async {
    final current = state;
    if (current is MusicMvWaiting && current.videoId == videoId) return cancel();
    final repository = ref.read(musicVideoRepositoryProvider);
    final video = await repository.byId(videoId);
    if (video == null || !video.isPending) return null;
    try {
      final outcome = await ref.read(mvRepositoryProvider).cancel(video.mvId);
      if (outcome.result == MusicMvCancelResult.cancelled) {
        _runner.abandon(videoId);
        unawaited(ref.read(mvNotificationsProvider).cancelFor(videoId));
        await repository.delete(videoId);
        ref
          ..invalidate(musicVideosProvider)
          ..invalidate(walletSnapshotProvider);
      }
      return outcome;
    } on Object catch (error, stackTrace) {
      _errors.handle(error, stackTrace);
      rethrow;
    }
  }

  String? _jobIdOrFail(MusicWork work, MusicMvLevel level) {
    final jobId = work.jobId;
    if (jobId == null) {
      state = MusicMvFailed(
        const ServerFailure(message: '', errorCode: 'MV_SONG_NOT_READY'),
        workId: work.id,
        level: level,
      );
    }
    return jobId;
  }
}

/// A fresh `client_ref` for one video attempt.
String newMvClientRef() => const Uuid().v4();
