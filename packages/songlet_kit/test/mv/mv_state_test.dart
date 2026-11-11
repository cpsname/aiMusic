import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  MusicMvWaiting waiting() => MusicMvWaiting(
        workId: 'w',
        videoId: 'v',
        mvId: 'mv',
        level: MusicMvLevel.chorus,
        etaSeconds: 600,
        startedAt: DateTime.utc(2026, 9, 28),
      );

  test('a snapshot drives every field; nothing is interpolated between polls', () {
    final fresh = waiting();
    expect(fresh.progress, isNull);
    expect(fresh.stage, isNull);
    final rendering = fresh.withSnapshot(const MusicMvSnapshot(
      status: MusicJobStatus.running,
      stage: 'rendering',
      progress: 0.661,
      segmentsDone: 1,
      segmentsTotal: 3,
      etaSeconds: 420,
    ));
    expect(rendering.status, MusicJobStatus.running);
    expect(rendering.stage, 'rendering');
    expect(rendering.progress, 0.661);
    expect(rendering.segmentsDone, 1);
    expect(rendering.segmentsTotal, 3);
    expect(rendering.remainingSeconds, 420);
    expect(rendering.isQueued, isFalse);
  });

  test('fields the platform omits keep their last value; segments do not (stage-specific)', () {
    final rendering = waiting().withSnapshot(const MusicMvSnapshot(status: MusicJobStatus.running, stage: 'rendering', progress: 0.5, segmentsDone: 2, segmentsTotal: 3));
    final assembling = rendering.withSnapshot(const MusicMvSnapshot(status: MusicJobStatus.running, stage: 'assembling'));
    expect(assembling.progress, 0.5, reason: 'a snapshot without a value keeps the last real one');
    expect(assembling.segmentsDone, isNull);
    expect(assembling.segmentsTotal, isNull);
  });

  test('a cancel request sticks once acknowledged', () {
    final acked = waiting().withSnapshot(const MusicMvSnapshot(status: MusicJobStatus.running, cancelRequested: true));
    expect(acked.cancelRequested, isTrue);
    expect(acked.withSnapshot(const MusicMvSnapshot(status: MusicJobStatus.running)).cancelRequested, isTrue);
    expect(waiting().copyWith(cancelling: true).cancelling, isTrue);
  });

  test('busy states', () {
    expect(const MusicMvIdle().isBusy, isFalse);
    expect(const MusicMvEstimating(workId: 'w', level: MusicMvLevel.full).isBusy, isTrue);
    expect(waiting().isBusy, isFalse, reason: 'a submitted video runs on while the hub prices and makes others');
    expect(const MusicMvPreparing(workId: 'w', videoId: 'v', level: MusicMvLevel.full, step: MusicMvPreparingStep.submitting).isBusy, isTrue);
  });
}
