import 'dart:async';

import 'package:dio/dio.dart';
import 'package:infra_core/infra_core.dart';

import '../../library/domain/work.dart';
import '../domain/music_video.dart';
import '../domain/mv.dart';
import '../domain/mv_intent.dart';
import '../domain/mv_repository.dart';
import 'mv_notifications.dart';

/// Submits one music video and records it as pending (ADR-0021): the one
/// path both the hub session (`MvController`) and the automatic video after
/// a song (`AutoVideoCoordinator`, ADR-0022) take, so the two can never
/// disagree on idempotency, retries or what is stored.
class MvLauncher {
  MvLauncher({
    required MvRepository mvs,
    required MusicVideoRepository library,
    required MvIntentStore intents,
    required MvNotifications notifications,
  })  : _mvs = mvs,
        _library = library,
        _intents = intents,
        _notifications = notifications;

  static const String quotaExhausted = 'QUOTA_EXHAUSTED';

  final MvRepository _mvs;
  final MusicVideoRepository _library;
  final MvIntentStore _intents;
  final MvNotifications _notifications;

  /// `POST /v1/works/{job_id}/mv` for [work], once per [attemptDelays] entry
  /// while the answer is a `QUOTA_EXHAUSTED` (same `client_ref`: never charged
  /// twice). On a ticket the pending intent is cleared, the video stored as
  /// `pending` and its ETA notification scheduled; the error of the last
  /// attempt is rethrown otherwise.
  Future<(MusicVideo, MvTicket)> submit(
    Work work,
    MvRequest request, {
    List<Duration> attemptDelays = const [Duration.zero],
    bool Function()? isStopped,
  }) async {
    final jobId = work.jobId;
    if (jobId == null) throw StateError('work ${work.id} has no job');
    final attempts = attemptDelays.isEmpty ? const [Duration.zero] : attemptDelays;
    MvTicket? ticket;
    for (var i = 0; ticket == null; i++) {
      if (attempts[i] > Duration.zero) await Future<void>.delayed(attempts[i]);
      try {
        ticket = await _mvs.create(jobId, request);
      } on Object catch (error) {
        final refused = apiErrorOf(error)?.errorCode == quotaExhausted;
        if (!refused || i == attempts.length - 1 || (isStopped?.call() ?? false)) rethrow;
      }
    }
    await _intents.clear();
    final video = MusicVideo(
      id: request.clientRef,
      workId: work.id,
      mvId: ticket.mvId,
      level: request.level,
      status: WorkStatus.pending,
      createdAt: DateTime.now().toUtc(),
      creditsCharged: ticket.creditsCharged,
      aspectRatio: request.aspectRatio ?? MvAspectRatio.portrait,
      quality: request.quality ?? MvQuality.standard,
      chorus: request.chorus,
      source: request.source,
      photoCount: request.photoBids.length,
    );
    await _library.upsert(video);
    unawaited(_notifications.scheduleFor(video, etaSeconds: ticket.etaSeconds));
    return (video, ticket);
  }

  /// The backend envelope error behind [error] (the envelope interceptor
  /// attaches it to a `DioException`); null for a transport failure.
  static ApiError? apiErrorOf(Object error) => switch (error) {
        ApiError() => error,
        DioException(error: final ApiError inner) => inner,
        _ => null,
      };
}
