import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  MvWaiting waiting() => MvWaiting(
        workId: 'w',
        videoId: 'v',
        mvId: 'mv',
        level: MvLevel.chorus,
        etaSeconds: 600,
        startedAt: DateTime.utc(2026, 9, 28),
      );

  test('a snapshot drives every field; nothing is interpolated between polls', () {
    final fresh = waiting();
    expect(fresh.progress, isNull);
    expect(fresh.stage, isNull);
    final rendering = fresh.withSnapshot(const MvSnapshot(
      status: JobStatus.running,
      stage: 'rendering',
      progress: 0.661,
      segmentsDone: 1,
      segmentsTotal: 3,
      etaSeconds: 420,
    ));
    expect(rendering.status, JobStatus.running);
    expect(rendering.stage, 'rendering');
    expect(rendering.progress, 0.661);
    expect(rendering.segmentsDone, 1);
    expect(rendering.segmentsTotal, 3);
    expect(rendering.remainingSeconds, 420);
    expect(rendering.isQueued, isFalse);
  });

  test('fields the platform omits keep their last value; segments do not (stage-specific)', () {
    final rendering = waiting().withSnapshot(const MvSnapshot(status: JobStatus.running, stage: 'rendering', progress: 0.5, segmentsDone: 2, segmentsTotal: 3));
    final assembling = rendering.withSnapshot(const MvSnapshot(status: JobStatus.running, stage: 'assembling'));
    expect(assembling.progress, 0.5, reason: 'a snapshot without a value keeps the last real one');
    expect(assembling.segmentsDone, isNull);
    expect(assembling.segmentsTotal, isNull);
  });

  test('a cancel request sticks once acknowledged', () {
    final acked = waiting().withSnapshot(const MvSnapshot(status: JobStatus.running, cancelRequested: true));
    expect(acked.cancelRequested, isTrue);
    expect(acked.withSnapshot(const MvSnapshot(status: JobStatus.running)).cancelRequested, isTrue);
    expect(waiting().copyWith(cancelling: true).cancelling, isTrue);
  });

  test('busy states', () {
    expect(const MvIdle().isBusy, isFalse);
    expect(const MvEstimating(workId: 'w', level: MvLevel.full).isBusy, isTrue);
    expect(waiting().isBusy, isFalse, reason: 'a submitted video runs on while the hub prices and makes others');
    expect(const MvPreparing(workId: 'w', videoId: 'v', level: MvLevel.full, step: MvPreparingStep.submitting).isBusy, isTrue);
  });
}
