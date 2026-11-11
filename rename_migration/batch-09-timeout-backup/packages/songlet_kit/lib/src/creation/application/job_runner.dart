import 'dart:async';

import 'package:infra_core/infra_core.dart';

import '../../library/domain/work.dart';
import '../../library/domain/work_repository.dart';
import '../domain/music_generation.dart';
import '../domain/generation_repository.dart';

/// Drives a submitted work to its end: polls `/v1/jobs/{id}`, downloads the
/// audio the moment it succeeds (the link lives 24 h, PRD §6.3) and records the
/// outcome in the library. Shared by the live generation flow and the
/// library's resume of jobs left running when the app was closed.
class JobRunner {
  JobRunner({
    required GenerationRepository jobs,
    required AudioStore audio,
    required WorkRepository works,
    this.pollInterval = const Duration(seconds: 2),
    this.timeout = const Duration(minutes: 6),
    DateTime Function()? now,
  })  : _jobs = jobs,
        _audio = audio,
        _works = works,
        _now = now ?? DateTime.now;

  final GenerationRepository _jobs;
  final AudioStore _audio;
  final WorkRepository _works;
  final Duration pollInterval;

  /// Upper bound of one run. Covers PRD §6.5's "queued ≤ 5 min" rate-limit
  /// window; past it the work stays `pending` and is resumed later.
  final Duration timeout;
  final DateTime Function() _now;
  final Set<String> _running = {};

  bool isRunning(String workId) => _running.contains(workId);

  /// Runs [work] (which must carry a job id) to a terminal state. Returns the
  /// stored work (`ready` or `failed`). Throws [JobTimeoutException] past
  /// [timeout], or the last transport error if polling never recovered —
  /// either way the work stays `pending` for a later resume.
  Future<Work> run(
    Work work, {
    void Function(JobSnapshot snapshot)? onSnapshot,
    bool Function()? isCancelled,
  }) async {
    final jobId = work.jobId;
    if (jobId == null || !_running.add(work.id)) {
      throw StateError('work ${work.id} has no job or is already running');
    }
    try {
      final deadline = _now().add(timeout);
      Object? lastError;
      while (_now().isBefore(deadline)) {
        if (isCancelled?.call() ?? false) throw const JobTimeoutException();
        JobSnapshot? snapshot;
        try {
          snapshot = await _jobs.job(jobId);
          lastError = null;
        } on Object catch (error) {
          lastError = error; // transient: keep polling until the deadline
        }
        if (snapshot != null) {
          onSnapshot?.call(snapshot);
          if (isCancelled?.call() ?? false) throw const JobTimeoutException();
          if (snapshot.status == JobStatus.succeeded) {
            return await _complete(work, snapshot);
          }
          if (snapshot.status == JobStatus.failed) {
            final failed = work.copyWith(
              status: WorkStatus.failed,
              errorCode: snapshot.errorCode ?? 'UPSTREAM_TIMEOUT',
            );
            await _works.upsert(failed);
            return failed;
          }
        }
        await Future<void>.delayed(pollInterval);
      }
      if (lastError != null) throw lastError;
      throw const JobTimeoutException();
    } finally {
      _running.remove(work.id);
    }
  }

  Future<Work> _complete(Work work, JobSnapshot snapshot) async {
    final url = snapshot.audioUrl;
    if (url == null || url.isEmpty) {
      throw const ServerFailure(message: '');
    }
    final fileName = await _audio.download(
      url: url,
      workId: work.id,
      title: _title(work),
    );
    final ready = work.copyWith(
      status: WorkStatus.ready,
      lyrics: snapshot.lyrics ?? work.lyrics,
      structure: snapshot.structure.isEmpty ? work.structure : snapshot.structure,
      audioFile: fileName,
    );
    await _works.upsert(ready);
    return ready;
  }

  static String _title(Work work) {
    final seed = work.titleSeed;
    final kind = work.isClip ? 'preview' : 'song';
    return seed.isEmpty ? 'Songlet $kind' : 'Songlet $kind for $seed';
  }
}

/// The job did not finish within [JobRunner.timeout] (the work stays pending).
class JobTimeoutException implements Exception {
  const JobTimeoutException();
}
