import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  MusicGenerationWaiting waiting(MusicJobStatus status) => MusicGenerationWaiting(
        model: MusicSongModel.clip,
        workId: 'w',
        jobId: 'j',
        etaSeconds: 45,
        startedAt: DateTime.utc(2026, 9, 27),
        status: status,
      );

  group('MusicGenerationWaiting', () {
    test('queued from the status alone — the platform never sends a position', () {
      final queued = waiting(MusicJobStatus.queued).withSnapshot(const MusicJobSnapshot(status: MusicJobStatus.queued));
      expect(queued.isQueued, isTrue);
      expect(queued.queuePosition, isNull);
      expect(waiting(MusicJobStatus.running).isQueued, isFalse);
    });

    test('a position is kept when a server does report one', () {
      final queued = waiting(MusicJobStatus.queued)
          .withSnapshot(const MusicJobSnapshot(status: MusicJobStatus.queued, queuePosition: 2));
      expect(queued.queuePosition, 2);
    });
  });
}
