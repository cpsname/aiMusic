import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

import 'mv_fakes.dart';

void main() {
  late FakeMusicVideoRepository library;
  late FakeVideoStore videos;

  setUp(() {
    library = FakeMusicVideoRepository();
    videos = FakeVideoStore();
  });

  MusicMvRunner runnerFor(ScriptedMvRepository mvs, {DateTime Function()? now}) =>
      MusicMvRunner(mvs: mvs, videos: videos, library: library, pollInterval: const Duration(milliseconds: 1), now: now);

  const queued = MusicMvSnapshot(status: MusicJobStatus.queued, stage: 'queued', progress: 0.02);
  const rendering = MusicMvSnapshot(status: MusicJobStatus.running, stage: 'rendering', progress: 0.661, segmentsDone: 1, segmentsTotal: 3);
  const succeeded = MusicMvSnapshot(
    status: MusicJobStatus.succeeded,
    stage: 'done',
    progress: 1,
    videoUrl: 'https://cdn.example.com/mv.mp4',
    durationMs: 30000,
    aiLabel: 'burned_in',
  );

  test('queued → rendering → succeeded downloads the MP4 and stores a ready video', () async {
    final mvs = ScriptedMvRepository(script: [queued, rendering, succeeded]);
    final seen = <String?>[];
    final result = await runnerFor(mvs).run(pendingVideo(), etaSeconds: 600, onSnapshot: (s) => seen.add(s.stage));
    expect(seen, ['queued', 'rendering', 'done']);
    expect(mvs.polled, ['mv-1', 'mv-1', 'mv-1']);
    expect(videos.downloads, [('https://cdn.example.com/mv.mp4', 'v1')]);
    expect(result.status, MusicWorkStatus.ready);
    expect(result.videoFile, 'v1.mp4');
    expect(result.durationMs, 30000);
    expect(library.videos['v1']!.isReady, isTrue);
  });

  test('a failed MV stores the job-level code; rendering failures are refunded codes', () async {
    final mvs = ScriptedMvRepository(script: const [rendering, MusicMvSnapshot(status: MusicJobStatus.failed, errorCode: 'MV_RENDER_FAILED')]);
    final result = await runnerFor(mvs).run(pendingVideo(), etaSeconds: 600);
    expect(result.status, MusicWorkStatus.failed);
    expect(result.errorCode, 'MV_RENDER_FAILED');
    expect(MusicErrorCode.fromWire(result.errorCode)!.isRefunded, isTrue);
    expect(videos.downloads, isEmpty);
  });

  test('a cancel confirmed at a gap ends as USER_CANCELLED', () async {
    final mvs = ScriptedMvRepository(script: const [
      MusicMvSnapshot(status: MusicJobStatus.running, stage: 'rendering', cancelRequested: true),
      MusicMvSnapshot(status: MusicJobStatus.failed, errorCode: 'USER_CANCELLED', balances: MusicMvBalances(songsLeft: 0, clipsLeft: 3)),
    ]);
    final result = await runnerFor(mvs).run(pendingVideo(), etaSeconds: 600);
    expect(result.errorCode, 'USER_CANCELLED');
  });

  test('a success whose 24 h object is already gone is recorded as MV_NOT_FOUND', () async {
    final mvs = ScriptedMvRepository(script: const [MusicMvSnapshot(status: MusicJobStatus.succeeded, stage: 'done', progress: 1)]);
    final result = await runnerFor(mvs).run(pendingVideo(), etaSeconds: 600);
    expect(result.status, MusicWorkStatus.failed);
    expect(result.errorCode, 'MV_NOT_FOUND');
  });

  test('transport errors are retried until the deadline, then the video stays pending', () async {
    var now = DateTime.utc(2026, 9, 28, 10);
    final mvs = ScriptedMvRepository(script: [StateError('boom')]);
    final runner = runnerFor(mvs, now: () {
      now = now.add(const Duration(minutes: 1));
      return now;
    });
    await expectLater(runner.run(pendingVideo(), etaSeconds: 60), throwsA(isA<StateError>()));
    expect(library.upserts, isEmpty, reason: 'nothing terminal was recorded');
  });

  test('past the deadline with no terminal snapshot a MusicJobTimeoutException is thrown', () async {
    var now = DateTime.utc(2026, 9, 28, 10);
    final mvs = ScriptedMvRepository(script: const [rendering]);
    final runner = runnerFor(mvs, now: () {
      now = now.add(const Duration(minutes: 1));
      return now;
    });
    await expectLater(runner.run(pendingVideo(), etaSeconds: 60), throwsA(isA<MusicJobTimeoutException>()));
  });

  test('the caller can stop polling; the same video cannot run twice', () async {
    final mvs = ScriptedMvRepository(script: const [rendering]);
    final runner = runnerFor(mvs);
    await expectLater(runner.run(pendingVideo(), etaSeconds: 600, isCancelled: () => true), throwsA(isA<MusicJobTimeoutException>()));
    expect(mvs.polled, isEmpty);
    final long = ScriptedMvRepository(script: const [rendering]);
    final again = runnerFor(long);
    final first = again.run(pendingVideo(), etaSeconds: 600, isCancelled: () => long.polled.length > 2);
    expect(again.isRunning('v1'), isTrue);
    await expectLater(again.run(pendingVideo(), etaSeconds: 600), throwsA(isA<StateError>()));
    await expectLater(first, throwsA(isA<MusicJobTimeoutException>()));
    expect(again.isRunning('v1'), isFalse);
  });

  test('the run budget is three ETAs, clamped between 2 and 90 minutes', () {
    expect(MusicMvRunner.timeoutFor(10), const Duration(minutes: 2));
    expect(MusicMvRunner.timeoutFor(600), const Duration(minutes: 30));
    expect(MusicMvRunner.timeoutFor(3600), const Duration(minutes: 90));
  });

  test('every snapshot is published per video and kept as latest while the run lasts', () async {
    final mvs = ScriptedMvRepository(script: [queued, rendering, succeeded]);
    final runner = runnerFor(mvs);
    final mine = <String?>[];
    final other = <String?>[];
    final subs = [
      runner.snapshots('v1').listen((s) => mine.add(s.stage)),
      runner.snapshots('v2').listen((s) => other.add(s.stage)),
    ];
    MusicMvSnapshot? latestDuringRun;
    await runner.run(pendingVideo(), etaSeconds: 600, onSnapshot: (_) => latestDuringRun = runner.latest('v1'));
    expect(mine, ['queued', 'rendering', 'done']);
    expect(other, isEmpty);
    expect(latestDuringRun?.stage, 'done');
    expect(runner.latest('v1'), isNull, reason: 'cleared once the run ends');
    for (final sub in subs) {
      await sub.cancel();
    }
    await runner.dispose();
  });

  test('an abandoned run ends without writing the video back', () async {
    final gate = Completer<void>();
    final mvs = ScriptedMvRepository(script: [rendering, succeeded])..gate = gate;
    final runner = runnerFor(mvs);
    final run = runner.run(pendingVideo(), etaSeconds: 600);
    await Future<void>.delayed(Duration.zero);
    runner.abandon('v1');
    gate.complete();
    await expectLater(run, throwsA(isA<MusicJobTimeoutException>()));
    expect(library.upserts, isEmpty);
    expect(videos.downloads, isEmpty);
    expect(runner.isRunning('v1'), isFalse);
    runner.abandon('v1'); // not running: a no-op that leaves no trace
    final again = await runnerFor(ScriptedMvRepository(script: const [succeeded])).run(pendingVideo(), etaSeconds: 600);
    expect(again.isReady, isTrue);
  });
}
