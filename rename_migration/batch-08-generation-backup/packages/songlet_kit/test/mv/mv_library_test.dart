import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/creation/application/job_runner.dart';
import 'package:songlet_kit/src/mv/data/kv_mv_intent_store.dart';

import '../support/music_fakes.dart';
import 'mv_fakes.dart';

class _NoJobs implements GenerationRepository {
  @override
  Future<GenerationTicket> submit(GenerationRequest request) => throw StateError('unused');
  @override
  Future<JobSnapshot> job(String jobId) => throw StateError('unused');
  @override
  Future<CancelOutcome> cancel(String jobId) => throw StateError('unused');
}

class _RecordingVideoStore extends FakeVideoStore {
  final List<String> deletedFiles = [];

  @override
  Future<void> delete(String fileName) async => deletedFiles.add(fileName);
}

void main() {
  group('KvMvIntentStore', () {
    test('round-trips the whole request, source included', () async {
      final prefs = InMemoryKeyValueStore();
      final store = KvMvIntentStore(prefs);
      expect(store.read(), isNull);
      await store.save(MvIntent(
        workId: 'w1',
        createdAt: DateTime.utc(2026, 9, 29, 8),
        request: const MvRequest(
          level: MvLevel.full,
          clientRef: 'ref-1',
          aspectRatio: MvAspectRatio.landscape,
          quality: MvQuality.high,
          subtitles: false,
          photoBids: ['b1', 'b2'],
          source: MvSource.upgrade,
        ),
      ));
      final back = store.read()!;
      expect(back.workId, 'w1');
      expect(back.createdAt, DateTime.utc(2026, 9, 29, 8));
      expect(back.request.level, MvLevel.full);
      expect(back.request.clientRef, 'ref-1');
      expect(back.request.aspectRatio, MvAspectRatio.landscape);
      expect(back.request.quality, MvQuality.high);
      expect(back.request.subtitles, isFalse);
      expect(back.request.photoBids, ['b1', 'b2']);
      expect(back.request.source, MvSource.upgrade);
      expect(back.request.chorus, isNull);

      await store.save(MvIntent(
        workId: 'w2',
        createdAt: DateTime.utc(2026, 9, 29, 9),
        request: const MvRequest(level: MvLevel.chorus, clientRef: 'ref-2', chorus: MvChorusWindow(startMs: 1000, endMs: 31000)),
      ));
      expect(store.read()!.workId, 'w2', reason: 'one pending intent: the newer replaces it');
      expect(store.read()!.request.chorus, const MvChorusWindow(startMs: 1000, endMs: 31000));

      await store.clear();
      expect(store.read(), isNull);
    });

    test('a record that no longer parses reads as absent', () async {
      final prefs = InMemoryKeyValueStore();
      await prefs.setString(KvMvIntentStore.key, '{"level":"hologram","work_id":"w1"}');
      expect(KvMvIntentStore(prefs).read(), isNull);
      await prefs.setString(KvMvIntentStore.key, 'not json');
      expect(KvMvIntentStore(prefs).read(), isNull);
    });

    test('freshness: an hour', () {
      final now = DateTime.utc(2026, 9, 29, 12);
      MvIntent at(Duration age) => MvIntent(workId: 'w', request: const MvRequest(level: MvLevel.chorus, clientRef: 'r'), createdAt: now.subtract(age));
      expect(at(const Duration(minutes: 60)).isFresh(now), isTrue);
      expect(at(const Duration(minutes: 61)).isFresh(now), isFalse);
    });
  });

  group('library', () {
    late FakeWorkRepository works;
    late FakeMusicVideoRepository videos;
    late _RecordingVideoStore files;
    late ScriptedMvRepository mvs;
    late ProviderContainer container;

    setUp(() {
      works = FakeWorkRepository();
      videos = FakeMusicVideoRepository();
      files = _RecordingVideoStore();
      final audio = FakeAudioStore();
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      mvs = ScriptedMvRepository(script: const [MvSnapshot(status: JobStatus.running, stage: 'rendering', progress: 0.4)])..gate = gate;
      container = ProviderContainer(overrides: [
        workRepositoryProvider.overrideWithValue(works),
        audioStoreProvider.overrideWithValue(audio),
        keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
        telemetrySinkProvider.overrideWithValue(const NoopTelemetrySink()),
        jobRunnerProvider.overrideWithValue(JobRunner(jobs: _NoJobs(), audio: audio, works: works)),
        mvRepositoryProvider.overrideWithValue(mvs),
        musicVideoRepositoryProvider.overrideWithValue(videos),
        videoStoreProvider.overrideWithValue(files),
        mvRunnerProvider.overrideWith(
          (ref) => MvRunner(mvs: mvs, videos: files, library: videos, pollInterval: const Duration(milliseconds: 1)),
        ),
      ]);
      addTearDown(container.dispose);
    });

    test('deleting a work deletes its videos and files and abandons one being made', () async {
      final song = readySong();
      await works.upsert(song);
      await works.upsert(readySong(id: 'w2'));
      await videos.upsert(MusicVideo(
        id: 'ready',
        workId: 'w1',
        mvId: 'mv-r',
        level: MvLevel.lyricVideo,
        status: WorkStatus.ready,
        videoFile: 'ready.mp4',
        createdAt: DateTime.utc(2026, 9, 29),
      ));
      await videos.upsert(pendingVideo(id: 'making'));
      await videos.upsert(pendingVideo(id: 'other', workId: 'w2', mvId: 'mv-o'));

      // Loading the library resumes the pending videos (their polls wait on the gate).
      await container.read(musicVideosProvider.future);
      final runner = container.read(mvRunnerProvider);
      expect(runner.isRunning('making'), isTrue);

      await container.read(libraryProvider.future);
      await container.read(libraryProvider.notifier).delete(song);

      expect(videos.deleted, unorderedEquals(['ready', 'making']));
      expect(files.deletedFiles, ['ready.mp4']);
      expect(videos.videos.keys, ['other']);
      expect(await works.byId('w1'), isNull);
    });

    test('a work\'s video status: making while pending, then ready', () async {
      await videos.upsert(pendingVideo(id: 'making'));
      await container.read(musicVideosProvider.future);
      expect(container.read(mvStatusOfWorkProvider('w1')), WorkVideoStatus.making);
      expect(container.read(mvStatusOfWorkProvider('w2')), WorkVideoStatus.none);

      container.read(mvRunnerProvider).abandon('making');
      await videos.upsert(pendingVideo(id: 'making').copyWith(status: WorkStatus.ready, videoFile: 'making.mp4'));
      container.invalidate(musicVideosProvider);
      await container.read(musicVideosProvider.future);
      expect(container.read(mvStatusOfWorkProvider('w1')), WorkVideoStatus.ready);
    });

    test('progress of a resumed video reaches its page through the runner', () async {
      await videos.upsert(pendingVideo(id: 'making'));
      final seen = <String?>[];
      container.listen(mvProgressProvider('making'), (_, next) => seen.add(next.value?.stage), fireImmediately: true);
      await container.read(musicVideosProvider.future);
      final gate = mvs.gate!;
      gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(seen, contains('rendering'));
      expect(container.read(mvProgressProvider('making')).value?.progress, 0.4);
    });
  });
}
