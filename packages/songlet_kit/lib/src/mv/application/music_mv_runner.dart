import 'dart:async';

import '../../creation/application/music_job_runner.dart' show MusicJobTimeoutException;
import '../../creation/domain/music_generation.dart';
import '../../library/domain/music_work.dart';
import '../domain/music_video.dart';
import '../domain/music_mv.dart';
import '../domain/music_mv_repository.dart';

/// Drives a submitted music video to its end: polls `GET /v1/mv/{id}` every
/// [pollInterval], downloads the MP4 the moment it succeeds (the link lives
/// 1 h) and records the outcome in the library. Progress comes only from the
/// snapshots — the runner never advances it on its own (ADR-0020).
///
/// Shared by the live MV flow and the library's resume of videos left
/// pending when the app was closed. Every snapshot of every run is published
/// on [snapshots] and kept as [latest] while the run lasts, so a progress
/// page follows a video whichever path started its run (ADR-0021).
class MusicMvRunner {
  MusicMvRunner({
    required MusicMvRepository mvs,
    required MusicVideoStore videos,
    required MusicVideoRepository library,
    this.pollInterval = const Duration(seconds: 5),
    DateTime Function()? now,
    this.onSettled,
  })  : _mvs = mvs,
        _videos = videos,
        _library = library,
        _now = now ?? DateTime.now;

  final MusicMvRepository _mvs;
  final MusicVideoStore _videos;
  final MusicVideoRepository _library;
  final Duration pollInterval;

  /// Called once a video ended — ready, failed, or abandoned with its work —
  /// (its ETA notification is cancelled there, ADR-0025). Not called when a
  /// run only stopped polling: the video is still being made.
  final void Function(String videoId)? onSettled;
  final DateTime Function() _now;
  final Set<String> _running = {};
  final Set<String> _abandoned = {};
  final Map<String, MusicMvSnapshot> _latest = {};
  final StreamController<(String, MusicMvSnapshot)> _bus = StreamController.broadcast(sync: true);

  /// Bounds of one run: three times the platform's ETA, but never shorter
  /// than a lyric video takes nor longer than the platform's own message
  /// budget (90 min, ADR-036).
  static const Duration minTimeout = Duration(minutes: 2);
  static const Duration maxTimeout = Duration(minutes: 90);
  static const int etaMultiplier = 3;

  static Duration timeoutFor(int etaSeconds) {
    final scaled = Duration(seconds: etaSeconds * etaMultiplier);
    if (scaled < minTimeout) return minTimeout;
    if (scaled > maxTimeout) return maxTimeout;
    return scaled;
  }

  bool isRunning(String videoId) => _running.contains(videoId);

  /// The last snapshot of [videoId]'s current run; null before the first
  /// poll answered or when it is not running.
  MusicMvSnapshot? latest(String videoId) => _latest[videoId];

  /// Snapshots of [videoId], from now on, across runs (a resumed run
  /// publishes here too). Never closes on its own.
  Stream<MusicMvSnapshot> snapshots(String videoId) =>
      _bus.stream.where((e) => e.$1 == videoId).map((e) => e.$2);

  /// Stops [videoId]'s run without recording anything (its work was
  /// deleted): the run ends at its next poll with [MusicJobTimeoutException] and
  /// never writes the video back.
  void abandon(String videoId) {
    if (_running.contains(videoId)) _abandoned.add(videoId);
  }

  Future<void> dispose() => _bus.close();

  /// Runs [video] to a terminal state. Returns the stored video (`ready` or
  /// `failed`). Throws [MusicJobTimeoutException] past the timeout, or the last
  /// transport error if polling never recovered — either way the video stays
  /// `pending` for a later resume.
  Future<MusicVideo> run(
    MusicVideo video, {
    required int etaSeconds,
    void Function(MusicMvSnapshot snapshot)? onSnapshot,
    bool Function()? isCancelled,
  }) async {
    if (!_running.add(video.id)) {
      throw StateError('video ${video.id} is already running');
    }
    bool stopped() => _abandoned.contains(video.id) || (isCancelled?.call() ?? false);
    try {
      final deadline = _now().add(timeoutFor(etaSeconds));
      Object? lastError;
      while (_now().isBefore(deadline)) {
        if (stopped()) throw const MusicJobTimeoutException();
        MusicMvSnapshot? snapshot;
        try {
          snapshot = await _mvs.mv(video.mvId);
          lastError = null;
        } on Object catch (error) {
          lastError = error; // transient: keep polling until the deadline
        }
        if (snapshot != null) {
          if (_abandoned.contains(video.id)) throw const MusicJobTimeoutException();
          _latest[video.id] = snapshot;
          if (!_bus.isClosed) _bus.add((video.id, snapshot));
          onSnapshot?.call(snapshot);
          if (stopped()) throw const MusicJobTimeoutException();
          if (snapshot.status == MusicJobStatus.succeeded) {
            final done = await _complete(video, snapshot);
            onSettled?.call(video.id);
            return done;
          }
          if (snapshot.status == MusicJobStatus.failed) {
            final failed = video.copyWith(
              status: MusicWorkStatus.failed,
              errorCode: snapshot.errorCode ?? 'UPSTREAM_TIMEOUT',
            );
            await _library.upsert(failed);
            onSettled?.call(video.id);
            return failed;
          }
        }
        await Future<void>.delayed(pollInterval);
      }
      if (lastError != null) throw lastError;
      throw const MusicJobTimeoutException();
    } finally {
      _running.remove(video.id);
      if (_abandoned.remove(video.id)) onSettled?.call(video.id);
      _latest.remove(video.id);
    }
  }

  Future<MusicVideo> _complete(MusicVideo video, MusicMvSnapshot snapshot) async {
    final url = snapshot.videoUrl;
    if (url == null) {
      // Succeeded, but the 24 h object is gone: nothing to keep on this device.
      final expired = video.copyWith(status: MusicWorkStatus.failed, errorCode: 'MV_NOT_FOUND');
      await _library.upsert(expired);
      return expired;
    }
    final file = await _videos.download(url: url, videoId: video.id);
    if (_abandoned.contains(video.id)) {
      // The work went away during the download: keep nothing.
      await _videos.delete(file);
      throw const MusicJobTimeoutException();
    }
    final ready = video.copyWith(
      status: MusicWorkStatus.ready,
      videoFile: file,
      durationMs: snapshot.durationMs ?? video.durationMs,
    );
    await _library.upsert(ready);
    return ready;
  }
}
