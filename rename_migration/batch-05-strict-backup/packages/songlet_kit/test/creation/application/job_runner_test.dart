import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/creation/application/job_runner.dart';

import '../../support/music_fakes.dart';

/// Answers `job()` from a script: each entry is a [JobSnapshot] to return or an
/// object to throw; the last entry repeats forever.
class ScriptedGenerationRepository implements GenerationRepository {
  ScriptedGenerationRepository(this.script);

  final List<Object> script;
  final List<String> polled = [];
  Completer<void>? gate;

  @override
  Future<GenerationTicket> submit(GenerationRequest request) =>
      throw StateError('submit is not called by JobRunner');

  @override
  Future<JobSnapshot> job(String jobId) async {
    final pending = gate;
    if (pending != null) await pending.future;
    final step = script[polled.length < script.length ? polled.length : script.length - 1];
    polled.add(jobId);
    if (step is JobSnapshot) return step;
    throw step;
  }

  @override
  Future<CancelOutcome> cancel(String jobId) =>
      throw StateError('cancel is not called by JobRunner');
}

void main() {
  late FakeWorkRepository works;
  late FakeAudioStore audio;

  setUp(() {
    works = FakeWorkRepository();
    audio = FakeAudioStore();
  });

  JobRunner runnerFor(
    ScriptedGenerationRepository jobs, {
    Duration timeout = const Duration(seconds: 5),
  }) =>
      JobRunner(
        jobs: jobs,
        audio: audio,
        works: works,
        pollInterval: const Duration(milliseconds: 1),
        timeout: timeout,
      );

  const queued = JobSnapshot(status: JobStatus.queued);
  const running = JobSnapshot(status: JobStatus.running);
  const succeeded = JobSnapshot(
    status: JobStatus.succeeded,
    audioUrl: 'https://cdn.example.com/w1.mp3',
    lyrics: '[Verse]\nhappy day',
    structure: [
      LyricSection(label: 'Verse', start: 0, end: 12.5),
      LyricSection(label: 'Chorus', start: 12.5, end: 30),
    ],
  );

  test('queued → running → succeeded downloads and stores a ready work', () async {
    final jobs = ScriptedGenerationRepository([queued, running, succeeded]);
    final snapshots = <JobStatus>[];

    final result = await runnerFor(jobs).run(
      sampleWork(),
      onSnapshot: (s) => snapshots.add(s.status),
    );

    expect(snapshots, [JobStatus.queued, JobStatus.running, JobStatus.succeeded]);
    expect(jobs.polled, ['job-1', 'job-1', 'job-1']);

    expect(audio.downloads, hasLength(1));
    expect(audio.downloads.single.url, 'https://cdn.example.com/w1.mp3');
    expect(audio.downloads.single.workId, 'w1');
    expect(audio.downloads.single.title, 'Songlet preview for Alex');

    expect(result.status, WorkStatus.ready);
    expect(result.isReady, isTrue);
    expect(result.audioFile, 'w1.mp3');
    expect(result.lyrics, '[Verse]\nhappy day');
    expect(result.structure.map((s) => s.label), ['Verse', 'Chorus']);
    expect(result.structure.last.end, 30);

    expect(works.upserts, hasLength(1));
    final stored = works.works['w1']!;
    expect(stored.status, WorkStatus.ready);
    expect(stored.audioFile, 'w1.mp3');
    expect(stored.lyrics, '[Verse]\nhappy day');
    expect(stored.structure, hasLength(2));
  });

  test('a full song without a recipient is titled from its keywords', () async {
    final jobs = ScriptedGenerationRepository([succeeded]);
    await runnerFor(jobs).run(
      sampleWork(model: SongModel.fullSong, recipient: '', keywords: ['beach', 'sun']),
    );
    expect(audio.downloads.single.title, 'Songlet song for beach, sun');
  });

  test('keeps the existing lyrics/structure when the job returns none', () async {
    final jobs = ScriptedGenerationRepository([
      const JobSnapshot(status: JobStatus.succeeded, audioUrl: 'https://x/a.mp3'),
    ]);
    final result = await runnerFor(jobs).run(sampleWork());
    expect(result.lyrics, '');
    expect(result.structure, isEmpty);
    expect(result.status, WorkStatus.ready);
  });

  test('a failed job stores a failed work with the error code', () async {
    final jobs = ScriptedGenerationRepository([
      queued,
      const JobSnapshot(status: JobStatus.failed, errorCode: 'SAFETY_BLOCKED'),
    ]);

    final result = await runnerFor(jobs).run(sampleWork());

    expect(result.status, WorkStatus.failed);
    expect(result.errorCode, 'SAFETY_BLOCKED');
    expect(works.works['w1']!.status, WorkStatus.failed);
    expect(works.works['w1']!.errorCode, 'SAFETY_BLOCKED');
    expect(audio.downloads, isEmpty);
  });

  test('a failed job without a code is recorded as UPSTREAM_TIMEOUT', () async {
    final jobs = ScriptedGenerationRepository([
      const JobSnapshot(status: JobStatus.failed),
    ]);
    final result = await runnerFor(jobs).run(sampleWork());
    expect(result.errorCode, 'UPSTREAM_TIMEOUT');
  });

  test('transient poll errors are retried', () async {
    final jobs = ScriptedGenerationRepository([
      const NetworkFailure(message: '', kind: NetworkFailureKind.offline),
      StateError('boom'),
      running,
      succeeded,
    ]);

    final result = await runnerFor(jobs).run(sampleWork());

    expect(jobs.polled, hasLength(4));
    expect(result.status, WorkStatus.ready);
  });

  test('hints on a live job are forwarded to onSnapshot', () async {
    final jobs = ScriptedGenerationRepository([
      const JobSnapshot(status: JobStatus.queued, errorCode: 'UPSTREAM_RATE_LIMITED'),
      succeeded,
    ]);
    final hints = <String?>[];
    await runnerFor(jobs).run(sampleWork(), onSnapshot: (s) => hints.add(s.errorCode));
    expect(hints, ['UPSTREAM_RATE_LIMITED', null]);
  });

  test('timeout throws JobTimeoutException and leaves the work pending', () async {
    final jobs = ScriptedGenerationRepository([queued]);

    await expectLater(
      runnerFor(jobs, timeout: const Duration(milliseconds: 30)).run(sampleWork()),
      throwsA(isA<JobTimeoutException>()),
    );

    expect(jobs.polled, isNotEmpty);
    expect(works.upserts, isEmpty, reason: 'the pending row is left untouched');
    expect(audio.downloads, isEmpty);
  });

  test('when polling never recovers, the last transport error is rethrown', () async {
    final jobs = ScriptedGenerationRepository([
      const NetworkFailure(message: '', kind: NetworkFailureKind.timeout),
    ]);

    await expectLater(
      runnerFor(jobs, timeout: const Duration(milliseconds: 30)).run(sampleWork()),
      throwsA(isA<NetworkFailure>()),
    );
    expect(works.upserts, isEmpty);
  });

  test('a succeeded job without an audio URL throws and stores nothing', () async {
    final jobs = ScriptedGenerationRepository([
      const JobSnapshot(status: JobStatus.succeeded),
    ]);
    final runner = runnerFor(jobs);

    await expectLater(runner.run(sampleWork()), throwsA(isA<ServerFailure>()));
    expect(works.upserts, isEmpty);
    expect(runner.isRunning('w1'), isFalse);
  });

  test('a cancelled run stops polling with JobTimeoutException', () async {
    final jobs = ScriptedGenerationRepository([queued]);
    var cancelled = false;

    final run = runnerFor(jobs).run(
      sampleWork(),
      isCancelled: () => cancelled,
      onSnapshot: (_) => cancelled = true,
    );

    await expectLater(run, throwsA(isA<JobTimeoutException>()));
    expect(jobs.polled, hasLength(1));
    expect(works.upserts, isEmpty);
  });

  group('isRunning guard', () {
    test('is true while running and cleared afterwards', () async {
      final jobs = ScriptedGenerationRepository([succeeded])..gate = Completer<void>();
      final runner = runnerFor(jobs);

      final run = runner.run(sampleWork());
      expect(runner.isRunning('w1'), isTrue);
      expect(runner.isRunning('other'), isFalse);

      jobs.gate!.complete();
      await run;
      expect(runner.isRunning('w1'), isFalse);
    });

    test('a second run of the same work is refused', () async {
      final jobs = ScriptedGenerationRepository([succeeded])..gate = Completer<void>();
      final runner = runnerFor(jobs);

      final first = runner.run(sampleWork());
      await expectLater(runner.run(sampleWork()), throwsStateError);

      jobs.gate!.complete();
      await first;
      expect(works.upserts, hasLength(1), reason: 'only one poller finished the work');
    });

    test('a work without a job id is refused', () async {
      final runner = runnerFor(ScriptedGenerationRepository([succeeded]));
      await expectLater(runner.run(sampleWork(jobId: null)), throwsStateError);
      expect(runner.isRunning('w1'), isFalse);
    });

    test('is cleared after a timeout, so the work can be resumed', () async {
      final jobs = ScriptedGenerationRepository([queued]);
      final runner = runnerFor(jobs, timeout: const Duration(milliseconds: 10));

      await expectLater(runner.run(sampleWork()), throwsA(isA<JobTimeoutException>()));
      expect(runner.isRunning('w1'), isFalse);
    });
  });

  test('the deadline follows the injected clock', () async {
    var now = DateTime.utc(2026);
    final jobs = ScriptedGenerationRepository([queued]);
    final runner = JobRunner(
      jobs: jobs,
      audio: audio,
      works: works,
      pollInterval: const Duration(milliseconds: 1),
      now: () => now,
    );

    final run = runner.run(
      sampleWork(),
      onSnapshot: (_) => now = now.add(const Duration(minutes: 2)),
    );

    await expectLater(run, throwsA(isA<JobTimeoutException>()));
    expect(jobs.polled, hasLength(3), reason: '0, 2 and 4 minutes are before 6');
  });
}
