import 'dart:async';

import 'core.dart';
import 'lyrics.dart';
import 'state.dart';

/// Drives job status transitions with real-time timers (the mock clock offset
/// never speeds a job up) and refunds every failed job's credit.
class JobRunner {
  JobRunner(this.state, {required this.onChange});

  final MockState state;

  /// Called after every transition (persistence hook).
  final void Function() onChange;

  final Map<String, List<Timer>> _timers = {};

  /// [planFor]'s plan for a `demo` profile song (never a forced error).
  static const String demo = '__demo__';

  /// The transition plan for a new job. [forced] is a `fail_next` job code.
  static List<JobStep> planFor({required int delayMs, String? forced}) {
    if (forced == demo) {
      // The demo profile: no queue, the wait compressed (demo.dart).
      return [const JobStep(0, 'running'), JobStep(delayMs, 'succeeded')];
    }
    final toRunning = delayMs ~/ 4 < 1000 ? delayMs ~/ 4 : 1000;
    return switch (forced) {
      null => [
        const JobStep(0, 'queued'),
        JobStep(toRunning, 'running'),
        JobStep(delayMs, 'succeeded'),
      ],
      // Lyria > 120 s: "retrying" hint while running, then failed + refund.
      SongletErrors.upstreamTimeout => [
        const JobStep(0, 'queued'),
        JobStep(toRunning, 'running'),
        JobStep(delayMs, 'running', SongletErrors.upstreamTimeout),
        JobStep(delayMs * 2, 'failed', SongletErrors.upstreamTimeout),
      ],
      // 429: queued behind the rate limit, then proceeds and succeeds.
      SongletErrors.upstreamRateLimited => [
        const JobStep(0, 'queued', SongletErrors.upstreamRateLimited),
        JobStep(delayMs, 'running'),
        JobStep(delayMs * 2, 'succeeded'),
      ],
      final code => [
        const JobStep(0, 'queued'),
        JobStep(toRunning, 'running'),
        JobStep(delayMs, 'failed', code),
      ],
    };
  }

  /// Applies every step already due and schedules the rest.
  void start(Job job) {
    final elapsed = DateTime.now().millisecondsSinceEpoch - job.createdRealMs;
    final timers = <Timer>[];
    for (var i = job.nextStep; i < job.plan.length; i++) {
      final step = job.plan[i];
      if (step.atMs <= elapsed) {
        _apply(job, i, notify: false);
      } else {
        timers.add(
          Timer(Duration(milliseconds: step.atMs - elapsed), () {
            _apply(job, i);
          }),
        );
      }
    }
    if (timers.isNotEmpty) _timers[job.id] = timers;
  }

  void _apply(Job job, int index, {bool notify = true}) {
    if (index < job.nextStep || state.jobs[job.id] != job) return;
    final step = job.plan[index];
    job
      ..nextStep = index + 1
      ..status = step.status
      ..errorCode = step.errorCode;
    if (step.status == 'succeeded') {
      job
        ..lyrics = job.draftLyrics ??
            generateLyrics(
              prompt: PromptBlock.parse(job.prompt),
              isSong: job.isSong,
              userLyrics: job.userLyrics,
            )
        ..structure = job.fixedStructure ?? structureFor(isSong: job.isSong)
        ..completedAtMs = state.clock.nowMs();
    } else if (step.status == 'failed' && !job.refunded) {
      state.ledger.refund(job.accountId, job.charge);
      job
        ..refunded = true
        ..completedAtMs = state.clock.nowMs();
    }
    if (job.terminal) _timers.remove(job.id);
    if (notify) onChange();
  }

  /// Stops [job]'s pending transitions (user cancel, ADR-0012).
  void cancel(Job job) {
    for (final t in _timers.remove(job.id) ?? const <Timer>[]) {
      t.cancel();
    }
    job.nextStep = job.plan.length;
  }

  void cancelAll() {
    for (final timers in _timers.values) {
      for (final t in timers) {
        t.cancel();
      }
    }
    _timers.clear();
  }
}
