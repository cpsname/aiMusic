import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/creation/application/music_job_runner.dart';

import '../../support/music_fakes.dart';

class FakeCloud implements MusicCloudSyncGateway {
  MusicCloudAccount status = MusicCloudAccount.available;
  final List<String> pushed = [];
  final List<String> removed = [];
  List<MusicCloudWorkChange> remote = const [];
  final List<DateTime?> pulls = [];

  @override
  Future<MusicCloudAccount> account() async => status;

  @override
  Future<void> push(MusicWork work, {String? audioPath}) async => pushed.add(work.id);

  @override
  Future<void> remove(String workId) async => removed.add(workId);

  @override
  Future<List<MusicCloudWorkChange>> pull({DateTime? since}) async {
    pulls.add(since);
    return remote;
  }
}

class _NoJobs implements MusicGenerationRepository {
  @override
  Future<MusicGenerationTicket> submit(MusicGenerationRequest request) => throw StateError('unused');
  @override
  Future<MusicJobSnapshot> job(String jobId) => throw StateError('unused');
  @override
  Future<MusicCancelOutcome> cancel(String jobId) => throw StateError('unused');
}

void main() {
  late FakeCloud cloud;
  late FakeWorkRepository works;
  late FakeAudioStore audio;
  late InMemoryKeyValueStore prefs;
  late ProviderContainer container;

  MusicWork ready(String id) => sampleWork(id: id, status: MusicWorkStatus.ready).copyWith(audioFile: '$id.mp3');

  setUp(() {
    cloud = FakeCloud();
    works = FakeWorkRepository();
    audio = FakeAudioStore();
    prefs = InMemoryKeyValueStore();
    container = ProviderContainer(overrides: [
      cloudSyncGatewayProvider.overrideWithValue(cloud),
      workRepositoryProvider.overrideWithValue(works),
      audioStoreProvider.overrideWithValue(audio),
      keyValueStoreProvider.overrideWithValue(prefs),
      telemetrySinkProvider.overrideWithValue(const NoopTelemetrySink()),
      jobRunnerProvider.overrideWithValue(MusicJobRunner(jobs: _NoJobs(), audio: audio, works: works)),
    ]);
  });

  tearDown(() => container.dispose());

  MusicLibrarySyncController sync() => container.read(librarySyncProvider.notifier);
  MusicLibrarySyncState state() => container.read(librarySyncProvider);

  test('off by default (PRD F10)', () {
    expect(state().enabled, isFalse);
  });

  test('without an iCloud account the toggle stays off and says why', () async {
    cloud.status = MusicCloudAccount.noAccount;
    await sync().setEnabled(enabled: true);
    expect(state().enabled, isFalse);
    expect(state().unavailable, isTrue);
    expect(prefs.getBool(MusicLibrarySyncController.enabledKey), isNull);
  });

  test('enabling pushes each ready work once and pulls new ones with their audio', () async {
    works.works['a'] = ready('a');
    works.works['p'] = sampleWork(id: 'p');
    cloud.remote = [MusicCloudWorkChange.upsert(ready('remote'), audioPath: '/tmp/remote.mp3')];

    await sync().setEnabled(enabled: true);
    expect(cloud.pushed, ['a']);
    expect(works.works['remote']!.audioFile, 'remote.mp3');
    expect(audio.imported, ['/tmp/remote.mp3']);
    expect(state().lastSyncedAt, isNotNull);

    final firstSync = state().lastSyncedAt;
    await sync().syncNow();
    expect(cloud.pushed, ['a'], reason: 'already pushed');
    expect(cloud.pulls.last, firstSync, reason: 'pulls only what changed since the last sync');
  });

  test('remote deletions remove the local work; local deletions tombstone', () async {
    works.works['gone'] = ready('gone');
    cloud.remote = [const MusicCloudWorkChange.deleted('gone')];
    await sync().setEnabled(enabled: true);
    expect(works.works.containsKey('gone'), isFalse);

    await sync().onDeleted(ready('x'));
    expect(cloud.removed, ['x']);
  });

  test('turning it off stops syncing', () async {
    await sync().setEnabled(enabled: true);
    await sync().setEnabled(enabled: false);
    cloud.pulls.clear();
    await sync().syncNow();
    expect(cloud.pulls, isEmpty);
  });
}
