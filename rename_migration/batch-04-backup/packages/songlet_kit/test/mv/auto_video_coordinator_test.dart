import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/creation/application/job_runner.dart';

import '../support/songlet_fakes.dart';
import 'mv_fakes.dart';

class _NoJobs implements GenerationRepository {
  @override
  Future<GenerationTicket> submit(GenerationRequest request) => throw StateError('unused');
  @override
  Future<JobSnapshot> job(String jobId) => throw StateError('unused');
  @override
  Future<CancelOutcome> cancel(String jobId) => throw StateError('unused');
}

class _Generation extends GenerationController {
  @override
  GenerationState build() => const GenerationIdle();

  void emit(GenerationState next) => state = next;
}

class _RecordingNotifications implements LocalNotifications {
  final List<LocalNotification> scheduled = [];
  final List<String> cancelled = [];

  @override
  Future<bool> requestAuthorization() async => true;
  @override
  Future<void> schedule(LocalNotification notification) async => scheduled.add(notification);
  @override
  Future<void> cancel(String id) async => cancelled.add(id);
  @override
  Stream<String> get opened => const Stream.empty();
}

void main() {
  late FakeWorkRepository works;
  late ScriptedMvRepository mvs;
  late FakeMusicVideoRepository videos;
  late _RecordingNotifications notifications;
  late _Generation generation;
  late ProviderContainer container;

  const ticket = MvTicket(mvId: 'mv-auto', etaSeconds: 120, creditsCharged: 0);
  const succeeded = MvSnapshot(status: JobStatus.succeeded, progress: 1, videoUrl: 'https://cdn/l2.mp4', durationMs: 118000);

  Work song({String id = 'w1', AutoVideo autoVideo = AutoVideo.lyric}) =>
      readySong(id: id).copyWith(autoVideo: autoVideo);

  ProviderContainer start() {
    final audio = FakeAudioStore();
    final created = ProviderContainer(overrides: [
      workRepositoryProvider.overrideWithValue(works),
      audioStoreProvider.overrideWithValue(audio),
      keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
      telemetrySinkProvider.overrideWithValue(const NoopTelemetrySink()),
      jobRunnerProvider.overrideWithValue(JobRunner(jobs: _NoJobs(), audio: audio, works: works)),
      generationControllerProvider.overrideWith(() => generation),
      authControllerProvider.overrideWith(SignedInAuth.new),
      walletSnapshotProvider.overrideWith((ref) => WalletSnapshot.empty),
      mvRepositoryProvider.overrideWithValue(mvs),
      musicVideoRepositoryProvider.overrideWithValue(videos),
      videoStoreProvider.overrideWithValue(FakeVideoStore()),
      localNotificationsProvider.overrideWithValue(notifications),
      autoVideoTickProvider.overrideWithValue(const Duration(milliseconds: 1)),
      mvRunnerProvider.overrideWith(
        // As bound in mv_providers.dart, with a fast poll.
        (ref) => MvRunner(
          mvs: mvs,
          videos: FakeVideoStore(),
          library: videos,
          pollInterval: const Duration(milliseconds: 1),
          onSettled: (id) => ref.read(mvNotificationsProvider).cancelFor(id),
        ),
      ),
    ]);
    addTearDown(created.dispose);
    created.read(autoVideoCoordinatorProvider);
    created.read(mvNotificationsProvider).bind((video) => (title: 'Ready', body: video.level.wire, location: '/v/${video.id}'));
    return created;
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 40));

  setUp(() {
    works = FakeWorkRepository();
    mvs = ScriptedMvRepository(createResult: ticket, script: const [succeeded]);
    videos = FakeMusicVideoRepository();
    notifications = _RecordingNotifications();
    generation = _Generation();
  });

  test('a finished song with the lyric toggle gets its lyric video after a countdown, once, with a derived client_ref', () async {
    container = start();
    await works.upsert(song());
    generation.emit(GenerationSucceeded(song()));
    container.invalidate(libraryProvider); // the library reload after success must not start it twice
    await Future<void>.delayed(Duration.zero);
    final counting = container.read(autoVideoOfWorkProvider('w1'))!;
    expect(counting.isCountingDown, isTrue, reason: 'it costs credits: cancellable first');
    expect(counting.level, MvLevel.lyricVideo);
    expect(mvs.created, isEmpty, reason: 'nothing charged during the countdown');
    await settle();

    expect(mvs.created, hasLength(1));
    final request = mvs.created.single.$2;
    expect(request.level, MvLevel.lyricVideo);
    expect(request.source, MvSource.autoLyric);
    expect(request.clientRef, AutoVideoCoordinator.clientRefFor('w1', MvLevel.lyricVideo));
    expect(container.read(autoVideoOfWorkProvider('w1'))?.videoId, request.clientRef);
    expect((await works.byId('w1'))!.autoVideo, AutoVideo.none, reason: 'the intent is spent');
    expect(videos.videos[request.clientRef]!.source, MvSource.autoLyric);
    expect(notifications.scheduled.single.id, MvNotifications.idFor(request.clientRef));
    expect(notifications.cancelled, [MvNotifications.idFor(request.clientRef)], reason: 'settled in the foreground');
  });

  test('a lyric video the app was closed before starting is dropped, not charged on the next launch', () async {
    await works.upsert(song());
    container = start();
    await container.read(libraryProvider.future);
    await settle();
    expect(mvs.created, isEmpty, reason: 'it costs credits and the user would not see the countdown');
    expect((await works.byId('w1'))!.autoVideo, AutoVideo.none);
  });

  test('cancelling the lyric countdown starts nothing and drops the intent', () async {
    container = start();
    await works.upsert(song());
    generation.emit(GenerationSucceeded(song()));
    await Future<void>.delayed(Duration.zero);
    await container.read(autoVideoCoordinatorProvider.notifier).cancelCountdown('w1');
    await settle();
    expect(mvs.created, isEmpty);
    expect(container.read(autoVideoOfWorkProvider('w1')), isNull);
    expect((await works.byId('w1'))!.autoVideo, AutoVideo.none);
  });

  test('Premier chorus: a cancellable countdown, then the chorus video', () async {
    container = start();
    await works.upsert(song(autoVideo: AutoVideo.chorus));
    generation.emit(GenerationSucceeded(song(autoVideo: AutoVideo.chorus)));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(autoVideoOfWorkProvider('w1'))!.isCountingDown, isTrue);
    expect(mvs.created, isEmpty, reason: 'nothing charged during the countdown');
    await settle();
    expect(mvs.created.single.$2.level, MvLevel.chorus);
  });

  test('cancelling the countdown submits nothing and drops the intent', () async {
    container = start();
    await works.upsert(song(autoVideo: AutoVideo.chorus));
    generation.emit(GenerationSucceeded(song(autoVideo: AutoVideo.chorus)));
    await Future<void>.delayed(Duration.zero);
    await container.read(autoVideoCoordinatorProvider.notifier).cancelCountdown('w1');
    await settle();
    expect(mvs.created, isEmpty);
    expect(container.read(autoVideoOfWorkProvider('w1')), isNull);
    expect((await works.byId('w1'))!.autoVideo, AutoVideo.none);
  });

  test('a chorus intent found after a restart is dropped, never charged unseen', () async {
    await works.upsert(song(autoVideo: AutoVideo.chorus));
    container = start();
    await container.read(libraryProvider.future);
    await settle();
    expect(mvs.created, isEmpty);
    expect((await works.byId('w1'))!.autoVideo, AutoVideo.none);
  });

  test('a refused automatic video surfaces its failure and ends the intent', () async {
    mvs.createResult = ApiError.fromEnvelope(code: 49312, message: 'not ready', details: {'error_code': 'MV_SONG_NOT_READY'});
    container = start();
    await works.upsert(song());
    generation.emit(GenerationSucceeded(song()));
    await settle();
    expect(container.read(autoVideoOfWorkProvider('w1'))!.failure?.errorCode, 'MV_SONG_NOT_READY');
    expect((await works.byId('w1'))!.autoVideo, AutoVideo.none);
    container.read(autoVideoCoordinatorProvider.notifier).dismiss('w1');
    expect(container.read(autoVideoOfWorkProvider('w1')), isNull);
  });

  test('the automatic lyric video and a chorus video from the hub run side by side', () async {
    final gate = Completer<void>();
    mvs = ScriptedMvRepository(createResult: ticket, script: const [MvSnapshot(status: JobStatus.running, stage: 'rendering', progress: 0.3)])
      ..gate = gate;
    container = start();
    await works.upsert(song());
    generation.emit(GenerationSucceeded(song()));
    await Future<void>.delayed(const Duration(milliseconds: 40)); // the countdown, then the submit
    final lyricId = AutoVideoCoordinator.clientRefFor('w1', MvLevel.lyricVideo);

    final hub = container.read(mvControllerProvider.notifier);
    unawaited(hub.create(readySong(), const MvRequest(level: MvLevel.chorus, clientRef: 'hub-chorus')));
    await Future<void>.delayed(const Duration(milliseconds: 5));

    final runner = container.read(mvRunnerProvider);
    expect(runner.isRunning(lyricId), isTrue);
    expect(runner.isRunning('hub-chorus'), isTrue);
    expect(container.read(mvControllerProvider), isA<MvWaiting>(), reason: 'the hub session is not blocked by the automatic video');
    expect(videos.videos.keys, containsAll([lyricId, 'hub-chorus']));
    gate.complete();
  });
}
