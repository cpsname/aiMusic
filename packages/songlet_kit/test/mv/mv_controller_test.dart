import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../support/music_fakes.dart';
import 'mv_fakes.dart';

ApiError quotaError({String required = '2169', String available = '66'}) => ApiError.fromEnvelope(
      code: 49303,
      message: 'quota exhausted',
      details: {'error_code': 'QUOTA_EXHAUSTED', 'reason': 'insufficient', 'required_credits': required, 'available_credits': available, 'recommended_product_id': 'com.songlet.mv.chorus'},
    );

void main() {
  late ScriptedMvRepository mvs;
  late MemoryMvIntentStore intents;
  late FakeWorkRepository works;
  late FakeMusicVideoRepository library;
  late FakeVideoStore videos;
  late FakePhotoUploader uploader;
  late ProviderContainer container;

  const ticket = MusicMvTicket(mvId: 'mv-1', etaSeconds: 600, creditsCharged: 2169);
  const succeeded = MusicMvSnapshot(status: MusicJobStatus.succeeded, stage: 'done', progress: 1, videoUrl: 'https://cdn/mv.mp4', durationMs: 30000);

  ProviderContainer containerFor(ScriptedMvRepository repository, {Duration poll = const Duration(milliseconds: 1)}) {
    final created = ProviderContainer(
      overrides: [
        mvRepositoryProvider.overrideWithValue(repository),
        musicVideoRepositoryProvider.overrideWithValue(library),
        videoStoreProvider.overrideWithValue(videos),
        photoUploaderProvider.overrideWithValue(uploader),
        mvIntentStoreProvider.overrideWithValue(intents),
        workRepositoryProvider.overrideWithValue(works),
        mvRetryDelaysProvider.overrideWithValue(const [Duration.zero, Duration(milliseconds: 1), Duration(milliseconds: 2)]),
        authControllerProvider.overrideWith(MusicSignedInAuth.new),
        walletSnapshotProvider.overrideWith((ref) => WalletSnapshot.empty),
        mvRunnerProvider.overrideWith(
          (ref) => MusicMvRunner(mvs: repository, videos: videos, library: library, pollInterval: poll),
        ),
      ],
    );
    addTearDown(created.dispose);
    return created;
  }

  setUp(() {
    mvs = ScriptedMvRepository(createResult: ticket, script: const [succeeded]);
    library = FakeMusicVideoRepository();
    videos = FakeVideoStore();
    uploader = FakePhotoUploader();
    intents = MemoryMvIntentStore();
    works = FakeWorkRepository();
    container = containerFor(mvs);
  });

  MusicMvController controller() => container.read(mvControllerProvider.notifier);
  MusicMvState state() => container.read(mvControllerProvider);
  MusicMvRequest request({MusicMvLevel level = MusicMvLevel.chorus}) => MusicMvRequest(level: level, clientRef: 'v1');

  test('estimate prices the level and exposes the result', () async {
    mvs.estimateResult = const MusicMvEstimate(level: MusicMvLevel.full, credits: 8280, availableCredits: 66, affordable: false, gapCredits: 8214, songLocked: true, recommendedProductId: 'com.songlet.mv.full');
    await controller().estimate(readySong(), MusicMvLevel.full);
    expect(mvs.estimated, [('job-1', MusicMvLevel.full)]);
    final estimated = state() as MusicMvEstimated;
    expect(estimated.estimate.recommendedProductId, 'com.songlet.mv.full');
    expect(estimated.estimate.affordable, isFalse);
  });

  test('a work without a job id cannot be priced or filmed', () async {
    await controller().estimate(readySong(jobId: null), MusicMvLevel.chorus);
    expect((state() as MusicMvFailed).failure.errorCode, 'MV_SONG_NOT_READY');
    expect(mvs.estimated, isEmpty);
  });

  test('create → waiting with the ticket → succeeded with the downloaded video', () async {
    final seen = <MusicMvState>[];
    container.listen(mvControllerProvider, (_, next) => seen.add(next));
    await controller().create(readySong(), request());
    expect(mvs.created.single.$1, 'job-1');
    expect(mvs.created.single.$2.clientRef, 'v1');
    expect(seen.whereType<MusicMvPreparing>().map((s) => s.step), [MusicMvPreparingStep.submitting]);
    final waiting = seen.whereType<MusicMvWaiting>().first;
    expect(waiting.mvId, 'mv-1');
    expect(waiting.etaSeconds, 600);
    expect(waiting.progress, isNull);
    final done = state() as MusicMvSucceeded;
    expect(done.video.isReady, isTrue);
    expect(done.video.creditsCharged, 2169);
    expect(library.videos['v1']!.status, MusicWorkStatus.ready);
    expect(videos.downloads.single.$2, 'v1');
  });

  test('reference photos are uploaded first and travel as bids', () async {
    await controller().create(readySong(), request(), photos: [
      [1, 2, 3],
      [4, 5, 6],
    ]);
    expect(uploader.uploaded, ['mv_photo_1.jpg', 'mv_photo_2.jpg']);
    expect(mvs.created.single.$2.photoBids, ['bid-1', 'bid-2']);
  });

  test('QUOTA_EXHAUSTED settles in MusicMvQuotaGap and keeps the request as a pending intent', () async {
    mvs.createResult = quotaError();
    await controller().create(readySong(), request());
    final gap = state() as MusicMvQuotaGap;
    expect(gap.failure.errorCode, 'QUOTA_EXHAUSTED');
    expect(gap.gap.recommendedProductId, 'com.songlet.mv.chorus');
    expect(gap.gap.gapCredits, 2103);
    expect(gap.request.clientRef, 'v1');
    expect(intents.intent?.workId, 'w1');
    expect(intents.intent?.request.clientRef, 'v1');
    expect(controller().pendingIntent('w1'), isNotNull);
    expect(controller().pendingIntent('other'), isNull);
    expect(library.videos, isEmpty, reason: 'nothing was accepted');
    expect(mvs.created, hasLength(1), reason: 'a plain create does not retry a refusal');
  });

  test('retryIntent after the purchase resends the same client_ref until the ledger credits it', () async {
    mvs.createResult = quotaError();
    await controller().create(readySong(), request(), photos: [
      [1, 2, 3],
    ]);
    expect(state(), isA<MusicMvQuotaGap>());

    // The pack was bought; the ledger answers QUOTA_EXHAUSTED once more, then accepts.
    mvs
      ..createQueue = [quotaError()]
      ..createResult = ticket;
    await controller().retryIntent(readySong());
    expect(mvs.created, hasLength(3));
    expect(mvs.created.map((c) => c.$2.clientRef).toSet(), {'v1'}, reason: 'one client_ref: never charged twice');
    expect(mvs.created.last.$2.photoBids, ['bid-1'], reason: 'photos are not uploaded again');
    expect(uploader.uploaded, hasLength(1));
    expect(state(), isA<MusicMvSucceeded>());
    expect(intents.intent, isNull, reason: 'the accepted intent is cleared');
  });

  test('retryIntent gives up after the bounded attempts and shows the gap again', () async {
    mvs.createResult = quotaError();
    await controller().create(readySong(), request());
    mvs.createResult = quotaError(available: '2000');
    await controller().retryIntent(readySong());
    expect(mvs.created, hasLength(1 + 3));
    final gap = state() as MusicMvQuotaGap;
    expect(gap.gap.gapCredits, 169);
    expect(intents.intent, isNotNull);
  });

  test('a stored intent survives a restart; past an hour it is resent under a new client_ref', () async {
    intents.intent = MusicMvIntent(workId: 'w1', request: request(), createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)));
    await controller().retryIntent(readySong());
    expect(mvs.created.single.$2.clientRef, 'v1');
    expect(state(), isA<MusicMvSucceeded>());

    intents.intent = MusicMvIntent(workId: 'w1', request: request(), createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 61)));
    container.read(mvControllerProvider.notifier).reset();
    await controller().retryIntent(readySong());
    expect(mvs.created.last.$2.clientRef, isNot('v1'));
    expect(mvs.created.last.$2.level, MusicMvLevel.chorus);
  });

  test('a business refusal ends the intent; a transport failure keeps it', () async {
    intents.intent = MusicMvIntent(workId: 'w1', request: request(), createdAt: DateTime.now().toUtc());
    mvs.createResult = DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError);
    await controller().retryIntent(readySong());
    expect(state(), isA<MusicMvFailed>());
    expect(intents.intent, isNotNull);

    mvs.createResult = DioException(
      requestOptions: RequestOptions(),
      error: ApiError.fromEnvelope(code: 49314, message: 'rejected', details: {'error_code': 'IMAGE_REJECTED'}),
    );
    await controller().retryIntent(readySong());
    expect((state() as MusicMvFailed).failure.errorCode, 'IMAGE_REJECTED');
    expect(intents.intent, isNull);
  });

  test('discardIntent drops the pending intent and leaves the gap', () async {
    mvs.createResult = quotaError();
    await controller().create(readySong(), request());
    await controller().discardIntent();
    expect(intents.intent, isNull);
    expect(state(), isA<MusicMvIdle>());
  });

  test('estimateAll prices the levels together; one that fails is left out', () async {
    mvs.estimateByLevel = {
      MusicMvLevel.lyricVideo: const MusicMvEstimate(level: MusicMvLevel.lyricVideo, credits: 0, availableCredits: 66, affordable: true, gapCredits: 0, songLocked: true),
      MusicMvLevel.chorus: const MusicMvEstimate(level: MusicMvLevel.chorus, credits: 2169, availableCredits: 66, affordable: false, gapCredits: 2103, songLocked: true, recommendedProductId: 'com.songlet.mv.chorus'),
      MusicMvLevel.full: StateError('down'),
    };
    await controller().estimateAll(readySong());
    final estimated = state() as MusicMvEstimated;
    expect(estimated.estimates.keys, unorderedEquals([MusicMvLevel.lyricVideo, MusicMvLevel.chorus]));
    expect(estimated.level, MusicMvLevel.chorus);
    expect(estimated.of(MusicMvLevel.full), isNull);

    // Pricing one more level keeps the others.
    mvs.estimateByLevel[MusicMvLevel.full] = const MusicMvEstimate(level: MusicMvLevel.full, credits: 8280, availableCredits: 66, affordable: false, gapCredits: 8214, songLocked: true);
    await controller().estimate(readySong(), MusicMvLevel.full);
    expect((state() as MusicMvEstimated).estimates, hasLength(3));

    mvs.estimateByLevel = {for (final level in MusicMvLevel.values) level: StateError('down')};
    await controller().estimateAll(readySong());
    expect(state(), isA<MusicMvFailed>());
  });

  test('the created video records what was asked for', () async {
    await controller().create(
      readySong(),
      const MusicMvRequest(
        level: MusicMvLevel.chorus,
        clientRef: 'v1',
        aspectRatio: MusicMvAspectRatio.square,
        quality: MusicMvQuality.high,
        chorus: MusicMvChorusWindow(startMs: 30000, endMs: 60000),
        source: MusicMvSource.upgrade,
        photoBids: ['b1', 'b2'],
      ),
    );
    final video = library.videos['v1']!;
    expect(video.aspectRatio, MusicMvAspectRatio.square);
    expect(video.quality, MusicMvQuality.high);
    expect(video.chorus, const MusicMvChorusWindow(startMs: 30000, endMs: 60000));
    expect(video.source, MusicMvSource.upgrade);
    expect(video.photoCount, 2);
    expect(mvs.created.single.$2.toJson().containsKey('source'), MusicMvRequest.sendsSource);
  });

  test('a rendering failure ends failed with the refunded code and the local record', () async {
    mvs = ScriptedMvRepository(createResult: ticket, script: const [MusicMvSnapshot(status: MusicJobStatus.failed, errorCode: 'MV_RENDER_FAILED')]);
    container = containerFor(mvs);
    await controller().create(readySong(), request());
    final failed = state() as MusicMvFailed;
    expect(failed.failure.errorCode, 'MV_RENDER_FAILED');
    expect(failed.videoId, 'v1');
    expect(library.videos['v1']!.status, MusicWorkStatus.failed);
  });

  test('cancel while queued removes the local record; while rendering it marks cancel_requested', () async {
    final gate = Completer<void>();
    mvs = ScriptedMvRepository(createResult: ticket, script: const [MusicMvSnapshot(status: MusicJobStatus.queued)])..gate = gate;
    container = containerFor(mvs);
    final run = controller().create(readySong(), request());
    await Future<void>.delayed(Duration.zero);
    expect(state(), isA<MusicMvWaiting>());

    mvs.cancelResult = const MusicMvCancelOutcome(mvId: 'mv-1', result: MusicMvCancelResult.cancelled, refunded: true);
    final outcome = await controller().cancel();
    expect(outcome?.refunded, isTrue);
    expect(library.deleted, ['v1']);
    expect(state(), isA<MusicMvIdle>());
    gate.complete();
    await run;
    expect(state(), isA<MusicMvIdle>(), reason: 'the stopped run does not overwrite the state');

    // Rendering: the platform only acknowledges; the run continues to USER_CANCELLED.
    mvs = ScriptedMvRepository(
      createResult: ticket,
      cancelResult: const MusicMvCancelOutcome(mvId: 'mv-1', result: MusicMvCancelResult.cancelRequested, refunded: false),
      script: const [
        MusicMvSnapshot(status: MusicJobStatus.running, stage: 'rendering', progress: 0.4),
        MusicMvSnapshot(status: MusicJobStatus.failed, errorCode: 'USER_CANCELLED'),
      ],
    );
    container = containerFor(mvs, poll: const Duration(milliseconds: 20));
    final second = controller().create(readySong(), request());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final acked = await controller().cancel();
    expect(acked?.result, MusicMvCancelResult.cancelRequested);
    expect((state() as MusicMvWaiting).cancelRequested, isTrue);
    await second;
    expect((state() as MusicMvFailed).failure.errorCode, 'USER_CANCELLED');
  });

  test('at launch a fresh intent is sent again; a stale or orphaned one is dropped', () async {
    await works.upsert(readySong());
    intents.intent = MusicMvIntent(workId: 'w1', request: request(), createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 3)));
    await controller().resumeIntent();
    expect(mvs.created.single.$2.clientRef, 'v1');
    expect(state(), isA<MusicMvSucceeded>());

    intents.intent = MusicMvIntent(workId: 'w1', request: request(), createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)));
    await controller().resumeIntent();
    expect(mvs.created, hasLength(1), reason: 'stale: not sent');
    expect(intents.intent, isNull);

    intents.intent = MusicMvIntent(workId: 'gone', request: request(), createdAt: DateTime.now().toUtc());
    await controller().resumeIntent();
    expect(mvs.created, hasLength(1));
    expect(intents.intent, isNull);
  });

  test('cancelVideo cancels a video this session did not start', () async {
    await library.upsert(pendingVideo(id: 'auto'));
    mvs.cancelResult = const MusicMvCancelOutcome(mvId: 'mv-1', result: MusicMvCancelResult.cancelled, refunded: true);
    final outcome = await controller().cancelVideo('auto');
    expect(outcome?.refunded, isTrue);
    expect(mvs.cancelled, ['mv-1']);
    expect(library.videos.containsKey('auto'), isFalse);

    await library.upsert(pendingVideo(id: 'rendering', mvId: 'mv-2'));
    mvs.cancelResult = const MusicMvCancelOutcome(mvId: 'mv-2', result: MusicMvCancelResult.cancelRequested, refunded: false);
    expect((await controller().cancelVideo('rendering'))?.result, MusicMvCancelResult.cancelRequested);
    expect(library.videos.containsKey('rendering'), isTrue, reason: 'the run goes on to USER_CANCELLED');
    expect(await controller().cancelVideo('unknown'), isNull);
  });

  test('while a video renders the hub prices again and makes another; the first run stops writing the state', () async {
    final gate = Completer<void>();
    mvs = ScriptedMvRepository(
      createResult: ticket,
      script: const [MusicMvSnapshot(status: MusicJobStatus.running, stage: 'rendering', progress: 0.3), succeeded],
      estimateResult: const MusicMvEstimate(level: MusicMvLevel.full, credits: 8280, availableCredits: 9000, affordable: true, gapCredits: 0, songLocked: true),
    )..gate = gate;
    container = containerFor(mvs);
    final first = controller().create(readySong(), request());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(state(), isA<MusicMvWaiting>());

    await controller().estimate(readySong(), MusicMvLevel.full);
    expect(state(), isA<MusicMvEstimated>(), reason: 'pricing is not blocked by the video being made');
    unawaited(controller().create(readySong(), const MusicMvRequest(level: MusicMvLevel.full, clientRef: 'v2')));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(mvs.created.map((c) => c.$2.clientRef), ['v1', 'v2']);
    expect((state() as MusicMvWaiting).videoId, 'v2');

    gate.complete();
    await first;
    final shown = switch (state()) {
      MusicMvWaiting(:final videoId) => videoId,
      MusicMvSucceeded(:final video) => video.id,
      _ => null,
    };
    expect(shown, 'v2', reason: 'the first run no longer writes the session');
    expect(library.videos['v1']!.isReady, isTrue, reason: 'it still finished and was stored');
  });
}
