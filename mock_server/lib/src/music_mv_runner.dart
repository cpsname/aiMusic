import 'dart:async';

import 'music_catalog.dart';
import 'music_core.dart';
import 'music_state.dart';

/// Drives music videos through the platform's stages on real timers
/// (contract v1.1 §3; platform ADR-043): `queued → slicing → storyboarding
/// → keyframing → rendering (one step per scene) → assembling → done`.
///
/// Progress is the fraction of **completed steps** — it only moves when a
/// step finishes, never between two steps (ADR-0020: no time interpolation),
/// exactly like the platform's snapshot. A cancel requested while rendering
/// is honoured at the next step boundary: scenes already rendered stay
/// charged, the rest is refunded.
class MusicMvRunner {
  MusicMvRunner(this.state, {required this.onChange});

  final MusicMockState state;
  final void Function() onChange;
  final Map<String, List<Timer>> _timers = {};

  /// The stages of a level: a lyric video skips the scene rendering.
  static List<String> stagesFor(String level) => switch (level) {
    'lyric_video' => const ['slicing', 'storyboarding', 'keyframing', 'assembling'],
    _ => const ['slicing', 'storyboarding', 'keyframing', 'rendering', 'assembling'],
  };

  /// Scenes rendered for [level] on a song of [songSeconds]: the chorus is
  /// three scenes (A A B), the full song one 15 s scene per slice, capped at
  /// twelve (platform D-6).
  static int segmentsFor(String level, int songSeconds) => switch (level) {
    'chorus_mv' => 3,
    'full_mv' => ((songSeconds + 14) ~/ 15).clamp(1, 12),
    _ => 0,
  };

  /// The transition plan of a new MV spread evenly over [delayMs].
  /// [forced] is a `fail_next` MV job code: the video fails at the first
  /// rendering scene (or at assembling for a lyric video).
  static List<MusicMvStep> planFor({
    required String level,
    required int songSeconds,
    required int delayMs,
    String? forced,
  }) {
    final stages = stagesFor(level);
    final segments = segmentsFor(level, songSeconds);
    // Work units: one per stage, the rendering stage split into its scenes.
    final units = <(String, int, int)>[];
    for (final stage in stages) {
      if (stage == 'rendering') {
        for (var i = 1; i <= segments; i++) {
          units.add((stage, i, segments));
        }
      } else {
        units.add((stage, 0, 0));
      }
    }
    final toStart = delayMs ~/ (units.length + 2) < 1000 ? delayMs ~/ (units.length + 2) : 1000;
    final span = delayMs - toStart;
    final steps = <MusicMvStep>[
      const MusicMvStep(atMs: 0, status: 'queued', stage: 'queued', stepsDone: 0, stepsTotal: 0),
    ];
    final totalSteps = stages.length;
    for (var i = 0; i < units.length; i++) {
      final (stage, segment, total) = units[i];
      // The step *starts* now; the snapshot reports what is finished so far.
      final at = toStart + (span * i) ~/ units.length;
      final stagesBefore = stages.indexOf(stage);
      final segmentsDone = segment == 0 ? 0 : segment - 1;
      steps.add(MusicMvStep(
        atMs: at,
        status: 'running',
        stage: stage,
        stepsDone: stagesBefore,
        stepsTotal: totalSteps,
        segmentsDone: total == 0 ? null : segmentsDone,
        segmentsTotal: total == 0 ? null : total,
        // The forced failure lands on the first scene (or on assembling when
        // the level has no scenes).
        errorCode: forced != null && ((stage == 'rendering' && segment == 1) || (segments == 0 && stage == 'assembling'))
            ? forced
            : null,
      ));
    }
    steps.add(MusicMvStep(atMs: delayMs, status: 'succeeded', stage: 'done', stepsDone: totalSteps, stepsTotal: totalSteps));
    return steps;
  }

  void start(MusicMvJob job) {
    final elapsed = DateTime.now().millisecondsSinceEpoch - job.createdRealMs;
    final timers = <Timer>[];
    for (var i = job.nextStep; i < job.plan.length; i++) {
      final step = job.plan[i];
      if (step.atMs <= elapsed) {
        _apply(job, i, notify: false);
      } else {
        timers.add(Timer(Duration(milliseconds: step.atMs - elapsed), () => _apply(job, i)));
      }
    }
    if (timers.isNotEmpty) _timers[job.id] = timers;
  }

  void _apply(MusicMvJob job, int index, {bool notify = true}) {
    if (index < job.nextStep || state.mvJobs[job.id] != job || job.terminal) return;
    final step = job.plan[index];
    job.nextStep = index + 1;
    if (job.cancelRequested && step.stage != 'queued') {
      // Honoured at this step boundary: finished steps stay charged.
      _finish(job, status: 'failed', errorCode: MusicErrors.userCancelled, chargedFraction: job.completedFraction);
      return;
    }
    final forced = step.errorCode;
    if (forced != null) {
      _finish(job, status: 'failed', errorCode: forced, chargedFraction: 0);
      return;
    }
    job
      ..status = step.status
      ..stage = step.stage
      ..stepsDone = step.stepsDone
      ..stepsTotal = step.stepsTotal
      ..segmentsDone = step.segmentsDone
      ..segmentsTotal = step.segmentsTotal;
    if (step.status == 'succeeded') {
      job.completedAtMs = state.clock.nowMs();
      _timers.remove(job.id);
    }
    if (notify) onChange();
  }

  /// Ends [job] with a refund of the unfinished share of its credits
  /// ([chargedFraction] of the price stays charged; a platform-side failure
  /// refunds everything).
  void _finish(MusicMvJob job, {required String status, required String errorCode, required double chargedFraction}) {
    cancel(job);
    final keep = (job.credits * chargedFraction).round();
    if (!job.refunded) {
      state.ledger.refundCredits(job.accountId, job.credits - keep);
      job.refunded = true;
    }
    job
      ..status = status
      ..errorCode = errorCode
      ..stage = 'done'
      ..completedAtMs = state.clock.nowMs();
    onChange();
  }

  /// `DELETE /v1/mv/{id}` while queued: stops the job at once, full refund.
  void cancelQueued(MusicMvJob job) {
    _finish(job, status: 'failed', errorCode: MusicErrors.userCancelled, chargedFraction: 0);
  }

  /// Stops [job]'s pending transitions.
  void cancel(MusicMvJob job) {
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

  /// Song length used by the mock's pricing and scene count.
  static int songSecondsOf(MusicJob job) => job.isSong ? 120 : 30;

  static int creditsFor(String level, MusicJob song) => Catalog.mvCredits(level, songSecondsOf(song));
}
