import 'dart:async';

import 'music_core.dart';
import 'music_lyrics.dart';
import 'music_state.dart';

/// Drives job status transitions with real-time timers (the mock clock offset
/// never speeds a job up) and refunds every failed job's credit.
class MusicJobRunner {
  MusicJobRunner(this.state, {required this.onChange});

  final MusicMockState state;

  /// Called after every transition (persistence hook).
  final void Function() onChange;

  final Map<String, List<Timer>> _timers = {};

  /// [planFor]'s plan for a `demo` profile song (never a forced error).
  static const String demo = '__demo__';

  /// The transition plan for a new job. [forced] is a `fail_next` job code.
  static List<MusicJobStep> planFor({required int delayMs, String? forced}) {
    if (forced == demo) {
      // The demo profile: no queue, the wait compressed (music_demo.dart).
      return [const MusicJobStep(0, 'running'), MusicJobStep(delayMs, 'succeeded')];
    }
    final toRunning = delayMs ~/ 4 < 1000 ? delayMs ~/ 4 : 1000;
    return switch (forced) {
      null => [
        const MusicJobStep(0, 'queued'),
        MusicJobStep(toRunning, 'running'),
        MusicJobStep(delayMs, 'succeeded'),
      ],
      // Lyria > 120 s: "retrying" hint while running, then failed + refund.
      MusicErrors.upstreamTimeout => [
        const MusicJobStep(0, 'queued'),
        MusicJobStep(toRunning, 'running'),
        MusicJobStep(delayMs, 'running', MusicErrors.upstreamTimeout),
        MusicJobStep(delayMs * 2, 'failed', MusicErrors.upstreamTimeout),
      ],
      // 429: queued behind the rate limit, then proceeds and succeeds.
      MusicErrors.upstreamRateLimited => [
        const MusicJobStep(0, 'queued', MusicErrors.upstreamRateLimited),
        MusicJobStep(delayMs, 'running'),
        MusicJobStep(delayMs * 2, 'succeeded'),
      ],
      final code => [
        const MusicJobStep(0, 'queued'),
        MusicJobStep(toRunning, 'running'),
        MusicJobStep(delayMs, 'failed', code),
      ],
    };
  }

  /// Applies every step already due and schedules the rest.
  void start(MusicJob job) {
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

  void _apply(MusicJob job, int index, {bool notify = true}) {
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
              prompt: MusicPromptBlock.parse(job.prompt),
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
  void cancel(MusicJob job) {
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
