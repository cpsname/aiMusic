import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  GenerationWaiting waiting(JobStatus status) => GenerationWaiting(
        model: SongModel.clip,
        workId: 'w',
        jobId: 'j',
        etaSeconds: 45,
        startedAt: DateTime.utc(2026, 9, 27),
        status: status,
      );

  group('GenerationWaiting', () {
    test('queued from the status alone — the platform never sends a position', () {
      final queued = waiting(JobStatus.queued).withSnapshot(const JobSnapshot(status: JobStatus.queued));
      expect(queued.isQueued, isTrue);
      expect(queued.queuePosition, isNull);
      expect(waiting(JobStatus.running).isQueued, isFalse);
    });

    test('a position is kept when a server does report one', () {
      final queued = waiting(JobStatus.queued)
          .withSnapshot(const JobSnapshot(status: JobStatus.queued, queuePosition: 2));
      expect(queued.queuePosition, 2);
    });
  });
}
