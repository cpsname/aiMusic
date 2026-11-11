import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:infra_core/infra_core.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:songlet/l10n/generated/app_localizations.dart';
import 'package:songlet/ui/mv/mv_music_generating_page.dart';
import 'package:songlet/ui/mv/music_mv_hub_page.dart';
import 'package:songlet/ui/mv/music_mv_notification_binding.dart';
import 'package:songlet/ui/mv/music_mv_player_page.dart';
import 'package:songlet/ui/paywall/music_paywall_page.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../support/music_harness.dart';

/// The music-video pages (PRD ch.15; docs/ui P19–P30, ADR-0027).
void main() {
  setUp(mockNativeChannels);

  MusicTestEnv songEnv() =>
      MusicTestEnv()
        ..addWork(sampleClip(id: 'song-1', model: MusicSongModel.fullSong));

  ApiError quotaError({String available = '66'}) => ApiError.fromEnvelope(
    code: 49303,
    message: 'quota exhausted',
    details: {
      'error_code': 'QUOTA_EXHAUSTED',
      'reason': 'insufficient',
      'required_credits': '2169',
      'available_credits': available,
      'recommended_product_id': 'com.songlet.mv.chorus',
    },
  );

  /// The real controller, with the post-purchase retries shortened.
  List<Override> fastRetries() => [
    mvRetryDelaysProvider.overrideWithValue(const [
      Duration.zero,
      Duration.zero,
      Duration.zero,
    ]),
  ];

  const rendering = MusicMvSnapshot(
    status: MusicJobStatus.running,
    stage: 'rendering',
    progress: 0.661,
    segmentsDone: 1,
    segmentsTotal: 3,
    etaSeconds: 420,
  );

  group('P20 / P21 hub', () {
    testWidgets(
      'prices the three levels on entry; chorus is preselected and recommended',
      (tester) async {
        final mv = MusicRecordingMv();
        await pumpRoute(
          tester,
          '/library/works/song-1/mv',
          env: songEnv(),
          overrides: [mvControllerProvider.overrideWith(() => mv)],
        );
        expect(find.byType(MusicMvHubPage), findsOneWidget);
        expect(
          mv.estimates.map((e) => e.$2),
          MusicMvLevel.values,
          reason: 'all three priced at once',
        );
        expect(find.text('Make a video'), findsOneWidget);
        expect(
          find.text('Turn “For Alex” into a music video.'),
          findsOneWidget,
        );
        expect(find.text('57 credits'), findsOneWidget);
        expect(find.text('2,169 credits'), findsNWidgets(2));
        expect(
          find.text('You have 3,000 credits'),
          findsNWidgets(3),
          reason: 'every level costs credits, the lyric video too',
        );
        expect(find.text('Recommended'), findsOneWidget);
        await reveal(tester, find.byKey(const ValueKey('mv.chorus')));
        expect(
          find.byKey(const ValueKey('mv.chorus')),
          findsOneWidget,
          reason: 'the chorus window belongs to the chorus level',
        );
        expect(
          find.byKey(const ValueKey('mv.quality')),
          findsNothing,
          reason: 'no remote qualities: standard only, no choice',
        );
      },
    );

    testWidgets(
      'picking the lyric video needs no new estimate and drops the chorus and subtitle options',
      (tester) async {
        final mv = MusicRecordingMv();
        await pumpRoute(
          tester,
          '/library/works/song-1/mv',
          env: songEnv(),
          overrides: [mvControllerProvider.overrideWith(() => mv)],
        );
        await tester.tap(find.byKey(const ValueKey('mv.level.lyric_video')));
        await settleFrames(tester);
        expect(mv.estimates, hasLength(3));
        expect(find.byKey(const ValueKey('mv.chorus')), findsNothing);
        expect(
          find.byKey(const ValueKey('mv.subtitles')),
          findsNothing,
          reason: 'a lyric video always has its lyrics',
        );
      },
    );

    testWidgets(
      'Make video sends the options with a fresh client_ref and follows that video',
      (tester) async {
        final mv = MusicRecordingMv();
        final env = songEnv()
          ..remoteConfig = {
            'mv': {
              'qualities': ['standard', 'high'],
            },
          };
        await pumpRoute(
          tester,
          '/library/works/song-1/mv',
          env: env,
          overrides: [mvControllerProvider.overrideWith(() => mv)],
        );
        await reveal(tester, find.byKey(const ValueKey('mv.aspect')));
        await tester.tap(find.text('Landscape'));
        await reveal(tester, find.byKey(const ValueKey('mv.quality')));
        await tester.tap(find.text('High'));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('mv.create')));
        await settleFrames(tester);
        final (work, request, photos) = mv.creates.single;
        expect(work.id, 'song-1');
        expect(request.level, MusicMvLevel.chorus);
        expect(request.aspectRatio, MusicMvAspectRatio.landscape);
        expect(request.quality, MusicMvQuality.high);
        expect(request.subtitles, isTrue);
        expect(request.chorus, isNull, reason: 'automatic chorus by default');
        expect(request.source, MusicMvSource.library);
        expect(request.clientRef, isNotEmpty);
        expect(photos, 0);
        expect(
          currentLocation(tester),
          '/library/works/song-1/mv/generate/${request.clientRef}',
        );
      },
    );

    testWidgets(
      '?level preselects; ?from prefills the options and an upgrade of a lyric video is recorded as such',
      (tester) async {
        final mv = MusicRecordingMv();
        final env = songEnv()
          ..addVideo(
            sampleVideo(
              id: 'lyric-1',
              level: MusicMvLevel.lyricVideo,
              aspectRatio: MusicMvAspectRatio.square,
              creditsCharged: 0,
            ),
          );
        await pumpRoute(
          tester,
          '/library/works/song-1/mv?level=chorus_mv&from=lyric-1',
          env: env,
          overrides: [mvControllerProvider.overrideWith(() => mv)],
        );
        await tester.tap(find.byKey(const ValueKey('mv.create')));
        await settleFrames(tester);
        final request = mv.creates.single.$2;
        expect(request.level, MusicMvLevel.chorus);
        expect(request.aspectRatio, MusicMvAspectRatio.square);
        expect(request.source, MusicMvSource.upgrade);
      },
    );

    testWidgets(
      'a level already being made is not offered twice: its card says so, the action follows it',
      (tester) async {
        final mv = MusicRecordingMv();
        final env = songEnv()
          ..addVideo(sampleVideo(id: 'making', status: MusicWorkStatus.pending));
        await pumpRoute(
          tester,
          '/library/works/song-1/mv',
          env: env,
          overrides: [mvControllerProvider.overrideWith(() => mv)],
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('mv.level.chorus_mv')),
            matching: find.text('Making…'),
          ),
          findsOneWidget,
        );
        expect(find.text('See progress'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('mv.create')));
        await settleFrames(tester);
        expect(mv.creates, isEmpty);
        expect(
          currentLocation(tester),
          '/library/works/song-1/mv/generate/making',
        );
      },
    );

    testWidgets('an estimate that fails offers a retry', (tester) async {
      final env = songEnv()
        ..mvs.estimateError = const ErrorHandler().handle(StateError('down'));
      await pumpRoute(tester, '/library/works/song-1/mv', env: env);
      expect(find.byKey(const ValueKey('mv.price')), findsOneWidget);
      env.mvs.estimateError = null;
      await tester.tap(find.text('Retry'));
      await settleFrames(tester);
      expect(find.byKey(const ValueKey('mv.price')), findsNothing);
      expect(find.text('2,169 credits'), findsNWidgets(2));
    });

    testWidgets(
      'regular width: levels and options side by side',
      skip: MusicTestDevice.iPadPro13.landscape.skipped,
      (tester) async {
        await pumpRoute(
          tester,
          '/library/works/song-1/mv',
          env: songEnv(),
          device: MusicTestDevice.iPadPro13.landscape,
          overrides: [mvControllerProvider.overrideWith(MusicRecordingMv.new)],
        );
        final level = tester.getTopLeft(
          find.byKey(const ValueKey('mv.level.chorus_mv')),
        );
        final aspect = tester.getTopLeft(
          find.byKey(const ValueKey('mv.aspect')),
        );
        expect(aspect.dx, greaterThan(level.dx + 200));
      },
    );
  });

  testWidgets(
    'hub → a lyric video → Make another → the chorus level is ready to make',
    (tester) async {
      final env = songEnv();
      await pumpRoute(tester, '/library/works/song-1/play', env: env);
      await reveal(tester, find.byKey(const ValueKey('mv.entry.open')));
      await tester.tap(find.byKey(const ValueKey('mv.entry.open')));
      await settleFrames(tester);
      await tester.tap(find.byKey(const ValueKey('mv.level.lyric_video')));
      await settleFrames(tester);
      await tester.tap(find.byKey(const ValueKey('mv.create')));
      await settleFrames(tester);
      final videoId = env.mvs.created.single.$2.clientRef;
      expect(find.byType(MusicMvGeneratingPage), findsOneWidget);

      // The platform finishes the video.
      final done = (await env.videos.byId(
        videoId,
      ))!.copyWith(status: MusicWorkStatus.ready, videoFile: '$videoId.mp4');
      await env.videos.upsert(done);
      env.runner.runs[videoId]!.complete(done);
      await settleFrames(tester);
      expect(find.byType(MusicMvPlayerPage), findsOneWidget);

      await reveal(tester, find.byKey(const ValueKey('mv.regenerate')));
      await tester.tap(find.byKey(const ValueKey('mv.regenerate')));
      await settleFrames(tester);
      expect(find.byType(MusicMvHubPage), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mv.level.chorus_mv')));
      await settleFrames(tester);
      final create = tester.widget<ObsButton>(
        find.descendant(
          of: find.byKey(const ValueKey('mv.create')),
          matching: find.byType(ObsButton),
        ),
      );
      expect(create.onPressed, isNotNull);
    },
  );

  group('P22 credits sheet', () {
    testWidgets(
      'not enough credits: the sheet buys the pack and the same request goes again',
      (tester) async {
        final env = songEnv()..mvs.createError = quotaError();
        final purchase = MusicScriptedPurchase(IapCompleted.new);
        final container = await pumpRoute(
          tester,
          '/library/works/song-1/mv',
          env: env,
          overrides: [
            ...fastRetries(),
            iapPurchaseOrchestratorProvider.overrideWith(() => purchase),
          ],
        );
        await tester.tap(find.byKey(const ValueKey('mv.create')));
        await settleFrames(tester);
        expect(find.byKey(const ValueKey('mv.quota')), findsOneWidget);
        expect(
          find.text('Chorus video needs 2,169 credits. You have 66 credits.'),
          findsOneWidget,
        );
        expect(find.text(r'$14.99'), findsOneWidget);
        expect(
          container.read(mvIntentStoreProvider).read()?.workId,
          'song-1',
          reason: 'kept across the purchase',
        );

        env.mvs.createError = null;
        await tester.tap(find.byKey(const ValueKey('mv.quota.buy')));
        await settleFrames(tester);
        expect(purchase.bought, ['com.songlet.mv.chorus']);
        expect(env.mvs.created, hasLength(2));
        expect(
          env.mvs.created.map((c) => c.$2.clientRef).toSet(),
          hasLength(1),
          reason: 'one client_ref: never charged twice',
        );
        final videoId = env.mvs.created.last.$2.clientRef;
        expect(
          currentLocation(tester),
          '/library/works/song-1/mv/generate/$videoId',
        );
        expect(find.byType(MusicMvGeneratingPage), findsOneWidget);
        expect(container.read(mvIntentStoreProvider).read(), isNull);
      },
    );

    testWidgets(
      'after a finished video, "Make another" and short of credits: the sheet',
      (tester) async {
        final env = songEnv()
          ..addVideo(sampleVideo())
          ..mvs.createError = quotaError();
        await pumpRoute(
          tester,
          '/library/works/song-1/mv/video-1',
          env: env,
          overrides: fastRetries(),
        );
        await reveal(tester, find.byKey(const ValueKey('mv.regenerate')));
        await tester.tap(find.byKey(const ValueKey('mv.regenerate')));
        await settleFrames(tester);
        await tester.tap(find.byKey(const ValueKey('mv.level.chorus_mv')));
        await settleFrames(tester);
        await reveal(tester, find.byKey(const ValueKey('mv.create')));
        await tester.tap(find.byKey(const ValueKey('mv.create')));
        await settleFrames(tester);
        expect(env.mvs.created, hasLength(1));
        expect(find.byKey(const ValueKey('mv.quota')), findsOneWidget);
      },
    );

    testWidgets(
      'a cancelled purchase closes the sheet and keeps every choice; leaving the hub gives it up',
      (tester) async {
        final env = songEnv()..mvs.createError = quotaError();
        final container = await pumpRoute(
          tester,
          '/library/works/song-1/mv',
          env: env,
          overrides: [
            ...fastRetries(),
            iapPurchaseOrchestratorProvider.overrideWith(
              () => MusicScriptedPurchase(IapCancelled.new),
            ),
          ],
        );
        await reveal(tester, find.byKey(const ValueKey('mv.aspect')));
        await tester.tap(find.text('Square'));
        await tester.tap(find.byKey(const ValueKey('mv.create')));
        await settleFrames(tester);
        await tester.tap(find.byKey(const ValueKey('mv.quota.buy')));
        await settleFrames(tester);
        expect(find.byKey(const ValueKey('mv.quota')), findsNothing);
        expect(find.byType(MusicMvHubPage), findsOneWidget);
        await tester.fling(
          find.byType(Scrollable).first,
          const Offset(0, 2000),
          4000,
        );
        await settleFrames(tester);
        expect(
          find.byKey(const ValueKey('mv.intent')),
          findsOneWidget,
          reason: 'the video waits for credits',
        );
        expect(env.mvs.created, hasLength(1));

        // Continue asks again at once; still short → the sheet again.
        await tester.tap(find.text('Continue'));
        await settleFrames(tester);
        expect(find.byKey(const ValueKey('mv.quota')), findsOneWidget);
        expect(env.mvs.created.last.$2.aspectRatio, MusicMvAspectRatio.square);
        await tester.tap(find.byKey(const ValueKey('mv.quota.close')));
        await settleFrames(tester);

        GoRouter.of(tester.element(find.byType(MusicMvHubPage))).pop();
        await settleFrames(tester);
        expect(container.read(mvIntentStoreProvider).read(), isNull);
      },
    );

    testWidgets(
      'where one pack may not cover it the sheet says so; no recommended pack → the plans',
      (tester) async {
        final env = songEnv()
          ..mvs.createError = ApiError.fromEnvelope(
            code: 49303,
            message: 'quota exhausted',
            details: {
              'error_code': 'QUOTA_EXHAUSTED',
              'reason': 'insufficient',
              'required_credits': '8280',
              'available_credits': '66',
              'recommended_product_id': 'com.songlet.mv.chorus',
            },
          );
        await pumpRoute(
          tester,
          '/library/works/song-1/mv',
          env: env,
          overrides: fastRetries(),
        );
        await tester.tap(find.byKey(const ValueKey('mv.create')));
        await settleFrames(tester);
        expect(
          find.text(
            'Where you are, one pack may not cover it — you may need two.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('mv.quota.plans')));
        await settleFrames(tester);
        expect(find.byType(MusicPaywallPage), findsOneWidget);
        expect(
          currentLocation(tester),
          '/paywall?reason=mv&product=com.songlet.mv.chorus',
        );
      },
    );
  });

  group('P24 / P25 making', () {
    Future<MusicTestEnv> open(
      WidgetTester tester, {
      MusicVideo? video,
      MusicMvSnapshot? snapshot,
      List<Override> overrides = const [],
    }) async {
      final env = songEnv()
        ..addVideo(video ?? sampleVideo(status: MusicWorkStatus.pending));
      await pumpRoute(
        tester,
        '/library/works/song-1/mv/generate/video-1',
        env: env,
        overrides: overrides,
      );
      if (snapshot != null) {
        env.runner.push('video-1', snapshot);
        await settleFrames(tester);
      }
      return env;
    }

    testWidgets(
      'rendering: the platform stage, its real percent, the scenes and the time left; the user may leave',
      (tester) async {
        await open(tester, snapshot: rendering);
        expect(find.text('Filming the scenes'), findsOneWidget);
        expect(find.text('66%'), findsOneWidget);
        expect(find.text('Scene 1 of 3'), findsOneWidget);
        expect(find.textContaining('Usually about 7 minutes'), findsOneWidget);
        expect(find.byKey(const ValueKey('mv.leaveHint')), findsOneWidget);
        expect(find.byKey(const ValueKey('mv.cancel')), findsOneWidget);
      },
    );

    testWidgets(
      'queued (or no snapshot yet): the queued anchor, no percent, no scenes',
      (tester) async {
        await open(tester);
        expect(find.text('Waiting to start'), findsOneWidget);
        expect(find.text('2%'), findsNothing);
        expect(find.byKey(const ValueKey('mv.scenes')), findsNothing);
      },
    );

    testWidgets(
      'cancel while queued: asks, refunds, removes the video and returns to the hub',
      (tester) async {
        final env = await open(
          tester,
          overrides: [mvControllerProvider.overrideWith(MusicMvController.new)],
        );
        await tester.tap(find.byKey(const ValueKey('mv.cancel')));
        await settleFrames(tester);
        expect(
          find.text("It hasn't started yet, so nothing will be used."),
          findsOneWidget,
        );
        await tester.tap(find.text('Stop video'));
        await settleFrames(tester);
        expect(env.mvs.cancelled, ['mv-video-1']);
        expect(env.videos.videos, isEmpty);
        expect(env.runner.abandoned, ['video-1']);
        expect(find.text('Video stopped — nothing was used'), findsOneWidget);
        expect(currentLocation(tester), '/library/works/song-1/mv');
      },
    );

    testWidgets(
      'cancel while rendering: the platform stops after the scene; the banner replaces Cancel',
      (tester) async {
        final env = await open(tester, snapshot: rendering);
        env.mvs.cancelOutcome = const MusicMvCancelOutcome(
          mvId: 'mv-video-1',
          result: MusicMvCancelResult.cancelRequested,
          refunded: false,
        );
        await tester.tap(find.byKey(const ValueKey('mv.cancel')));
        await settleFrames(tester);
        expect(
          find.text(
            'It has already started. Scenes already made are charged; the rest comes back.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Stop video'));
        await settleFrames(tester);
        expect(env.videos.videos.containsKey('video-1'), isTrue);
        env.runner.push(
          'video-1',
          const MusicMvSnapshot(
            status: MusicJobStatus.running,
            stage: 'rendering',
            progress: 0.7,
            cancelRequested: true,
          ),
        );
        await settleFrames(tester);
        expect(
          find.byKey(const ValueKey('mv.cancelRequested')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('mv.cancel')), findsNothing);
      },
    );

    testWidgets('a finished video opens the player', (tester) async {
      final env = await open(tester, snapshot: rendering);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MusicMvGeneratingPage)),
      );
      env.addVideo(sampleVideo());
      container.invalidate(musicVideosProvider);
      await settleFrames(tester);
      expect(find.byType(MusicMvPlayerPage), findsOneWidget);
      expect(currentLocation(tester), '/library/works/song-1/mv/video-1');
    });

    testWidgets(
      'P25 a declined photo: the credits back, the photo count, adjust and try again',
      (tester) async {
        await open(
          tester,
          video: sampleVideo(
            status: MusicWorkStatus.failed,
            errorCode: 'IMAGE_REJECTED',
            photoCount: 3,
          ),
        );
        expect(find.byKey(const ValueKey('mv.rejected')), findsOneWidget);
        expect(find.text('A photo couldn’t be used'), findsOneWidget);
        expect(find.text('Your 2,169 credits are back.'), findsOneWidget);
        expect(find.text('3 photos'), findsOneWidget);
        await tester.tap(find.text('Adjust photos and try again'));
        await settleFrames(tester);
        expect(
          currentLocation(tester),
          '/library/works/song-1/mv?level=chorus_mv&from=video-1',
        );
      },
    );

    testWidgets(
      'P25 a render failure is refunded and retried with the same options',
      (tester) async {
        await open(tester, video: sampleVideo(status: MusicWorkStatus.failed));
        expect(
          find.text(
            "We couldn't finish this video. Your credits are back — try again.",
          ),
          findsOneWidget,
        );
        expect(find.text('Your 2,169 credits are back.'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('mv.failureAction')));
        await settleFrames(tester);
        expect(find.byType(MusicMvHubPage), findsOneWidget);
      },
    );

    testWidgets('P25 a song too long for a full video offers a chorus video', (
      tester,
    ) async {
      await open(
        tester,
        video: sampleVideo(
          level: MusicMvLevel.full,
          status: MusicWorkStatus.failed,
          errorCode: 'MV_SONG_TOO_LONG',
        ),
      );
      expect(
        find.text(
          'This song is too long for a full video — try a chorus video.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Make a chorus video instead'));
      await settleFrames(tester);
      expect(
        currentLocation(tester),
        '/library/works/song-1/mv?level=chorus_mv&from=video-1',
      );
    });

    testWidgets('a video stopped by the user says so', (tester) async {
      await open(
        tester,
        video: sampleVideo(
          status: MusicWorkStatus.failed,
          errorCode: 'USER_CANCELLED',
        ),
      );
      expect(find.byKey(const ValueKey('mv.stopped')), findsOneWidget);
    });

    testWidgets('an unknown video id leads back to the hub', (tester) async {
      await pumpRoute(
        tester,
        '/library/works/song-1/mv/generate/nope',
        env: songEnv(),
      );
      expect(find.byKey(const ValueKey('mv.nothing')), findsOneWidget);
    });
  });

  group('P26 / P27 video', () {
    testWidgets(
      'immersive: the file, the AI disclosure, the meta line and the actions',
      (tester) async {
        final env = songEnv()..addVideo(sampleVideo());
        await pumpRoute(tester, '/library/works/song-1/mv/video-1', env: env);
        expect(find.byType(MusicMvPlayerPage), findsOneWidget);
        expect(find.byKey(const ValueKey('mv.player')), findsOneWidget);
        expect(find.byType(AiGeneratedBadge), findsWidgets);
        expect(find.textContaining('Chorus video'), findsWidgets);
        await reveal(tester, find.byKey(const ValueKey('mv.aiLabel')));
        expect(
          find.text('AI generated — the badge is part of the video'),
          findsOneWidget,
        );
        await reveal(tester, find.byKey(const ValueKey('mv.regenerate')));
        for (final id in ['share', 'save', 'files', 'regenerate']) {
          expect(find.byKey(ValueKey('mv.$id')), findsOneWidget);
        }
        final context = tester.element(find.byKey(const ValueKey('mv.player')));
        expect(
          Theme.of(context).brightness,
          Brightness.dark,
          reason: 'the video page is dark',
        );
        await tester.tap(find.byKey(const ValueKey('mv.toggle')));
        await settleFrames(tester);
        expect(
          (VideoPlayerPlatform.instance as MusicFakeVideoPlayerPlatform).calls,
          contains('play'),
        );
      },
    );

    testWidgets(
      'a full video shows the song sections and synced lyrics; a chorus video without a window shows neither',
      (tester) async {
        final env = songEnv()
          ..addVideo(sampleVideo(id: 'full', level: MusicMvLevel.full))
          ..addVideo(sampleVideo(id: 'chorus'));
        await pumpRoute(tester, '/library/works/song-1/mv/full', env: env);
        await reveal(tester, find.byKey(const ValueKey('mv.sections')));
        expect(
          tester.widget<SectionTrack>(find.byType(SectionTrack)).sections,
          hasLength(5),
        );
        await reveal(tester, find.byKey(const ValueKey('mv.lyrics')));
        expect(find.text('Happy birthday, Alex'), findsOneWidget);

        GoRouter.of(
          tester.element(find.byType(MusicMvPlayerPage)),
        ).go('/library/works/song-1/mv/chorus');
        await settleFrames(tester);
        expect(find.byKey(const ValueKey('mv.lyrics')), findsNothing);
        expect(find.byKey(const ValueKey('mv.sections')), findsNothing);
      },
    );

    testWidgets(
      'a chorus video with its window has the sections of that window',
      (tester) async {
        final env = songEnv()
          ..addVideo(
            sampleVideo(
              chorus: const MusicMvChorusWindow(startMs: 40000, endMs: 70000),
            ),
          );
        await pumpRoute(tester, '/library/works/song-1/mv/video-1', env: env);
        await reveal(tester, find.byKey(const ValueKey('mv.sections')));
        final track = tester.widget<SectionTrack>(find.byType(SectionTrack));
        expect(track.sections.map((s) => s.label), ['Verse', 'Chorus']);
      },
    );

    testWidgets('Make another opens the hub with this video’s options', (
      tester,
    ) async {
      final env = songEnv()..addVideo(sampleVideo());
      await pumpRoute(
        tester,
        '/library/works/song-1/mv/video-1',
        env: env,
        overrides: [mvControllerProvider.overrideWith(MusicRecordingMv.new)],
      );
      await reveal(tester, find.byKey(const ValueKey('mv.regenerate')));
      await tester.tap(find.byKey(const ValueKey('mv.regenerate')));
      await settleFrames(tester);
      expect(find.byType(MusicMvHubPage), findsOneWidget);
      expect(
        currentLocation(tester),
        '/library/works/song-1/mv?level=chorus_mv&from=video-1',
      );
    });

    testWidgets('Save to Photos goes through the native saver', (tester) async {
      final env = songEnv()..addVideo(sampleVideo());
      await pumpRoute(tester, '/library/works/song-1/mv/video-1', env: env);
      await reveal(tester, find.byKey(const ValueKey('mv.save')));
      await tester.tap(find.byKey(const ValueKey('mv.save')));
      await settleFrames(tester);
      expect(env.saver.saved, ['/video/video-1.mp4']);
      expect(find.text('Saved to Photos'), findsOneWidget);
    });

    testWidgets(
      'landscape: the video beside its panel',
      skip: MusicTestDevice.iPadPro13.landscape.skipped,
      (tester) async {
        final env = songEnv()
          ..addVideo(sampleVideo(aspectRatio: MusicMvAspectRatio.landscape));
        await pumpRoute(
          tester,
          '/library/works/song-1/mv/video-1',
          env: env,
          device: MusicTestDevice.iPadPro13.landscape,
        );
        final video = tester.getCenter(find.byKey(const ValueKey('mv.player')));
        final actions = tester.getCenter(
          find.byKey(const ValueKey('mv.share')),
        );
        expect(actions.dx, greaterThan(video.dx));
      },
    );

    testWidgets('a video whose file is gone says so', (tester) async {
      final env = songEnv()..addVideo(sampleVideo(status: MusicWorkStatus.failed));
      await pumpRoute(tester, '/library/works/song-1/mv/video-1', env: env);
      expect(
        find.text("This video isn't on this device anymore."),
        findsOneWidget,
      );
    });
  });

  group('P19 entries', () {
    testWidgets('the song page card opens the hub', (tester) async {
      await pumpRoute(
        tester,
        '/library/works/song-1/play',
        env: songEnv(),
        overrides: [mvControllerProvider.overrideWith(MusicRecordingMv.new)],
      );
      await reveal(tester, find.byKey(const ValueKey('mv.entry.open')));
      expect(find.text('Make it a video'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mv.entry.open')));
      await settleFrames(tester);
      expect(find.byType(MusicMvHubPage), findsOneWidget);
    });

    testWidgets(
      'while a video is made the card shows its progress and follows it',
      (tester) async {
        final env = songEnv()
          ..addVideo(sampleVideo(status: MusicWorkStatus.pending));
        await pumpRoute(tester, '/library/works/song-1/play', env: env);
        env.runner.push('video-1', rendering);
        await settleFrames(tester);
        await reveal(tester, find.byKey(const ValueKey('mv.entry.progress')));
        expect(find.text('Making video · 66%'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('mv.entry.progress')));
        await settleFrames(tester);
        expect(find.byType(MusicMvGeneratingPage), findsOneWidget);
      },
    );

    testWidgets('an unfinished song cannot be filmed yet', (tester) async {
      final env = MusicTestEnv()
        ..addWork(
          sampleClip(
            id: 'song-1',
            model: MusicSongModel.fullSong,
          ).copyWith(status: MusicWorkStatus.failed),
        );
      await pumpRoute(tester, '/library/works/song-1', env: env);
      await reveal(tester, find.byKey(const ValueKey('detail.makeVideo')));
      final button = tester.widget<SecondaryButton>(
        find.descendant(
          of: find.byKey(const ValueKey('detail.makeVideo')),
          matching: find.byType(SecondaryButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'the work detail lists every video; each opens where it stands',
      (tester) async {
        final env = songEnv()
          ..addVideo(sampleVideo())
          ..addVideo(
            sampleVideo(
              id: 'video-2',
              level: MusicMvLevel.full,
              status: MusicWorkStatus.failed,
            ),
          );
        await pumpRoute(tester, '/library/works/song-1', env: env);
        await reveal(tester, find.byKey(const ValueKey('detail.makeVideo')));
        expect(find.text('Videos'), findsOneWidget);
        expect(find.textContaining("Didn't finish"), findsOneWidget);
        await reveal(
          tester,
          find.byKey(const ValueKey('detail.video.video-2')),
        );
        await tester.tap(find.byKey(const ValueKey('detail.video.video-2')));
        await settleFrames(tester);
        expect(
          find.byType(MusicMvGeneratingPage),
          findsOneWidget,
          reason: 'a failed video opens its failure (P25)',
        );
      },
    );

    testWidgets('the library row carries the video chip', (tester) async {
      final env = songEnv()..addVideo(sampleVideo());
      await pumpRoute(tester, '/library', env: env);
      expect(
        find.byKey(const ValueKey('library.video.song-1')),
        findsOneWidget,
      );
      expect(find.text('Video'), findsOneWidget);
    });
  });

  group('P23 automatic video', () {
    Future<MusicFixedAutoVideo> open(
      WidgetTester tester,
      MusicAutoVideoTask task, {
      MusicTestEnv? env,
    }) async {
      final auto = MusicFixedAutoVideo({'song-1': task});
      await pumpRoute(
        tester,
        '/library/works/song-1/play',
        env: env ?? songEnv(),
        overrides: [autoVideoCoordinatorProvider.overrideWith(() => auto)],
      );
      return auto;
    }

    testWidgets('Premier countdown: nothing charged yet, Cancel stops it', (
      tester,
    ) async {
      final auto = await open(
        tester,
        const MusicAutoVideoTask(
          workId: 'song-1',
          level: MusicMvLevel.chorus,
          secondsLeft: 7,
        ),
      );
      expect(find.text('Chorus video starts in 7 s'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settleFrames(tester);
      expect(auto.cancelledCountdowns, ['song-1']);
      expect(find.byKey(const ValueKey('mv.auto')), findsNothing);
    });

    testWidgets(
      'the lyric video counts down too — it costs credits, so it never starts unseen',
      (tester) async {
        final auto = await open(
          tester,
          const MusicAutoVideoTask(
            workId: 'song-1',
            level: MusicMvLevel.lyricVideo,
            secondsLeft: 9,
          ),
        );
        expect(find.text('Lyric video starts in 9 s'), findsOneWidget);
        expect(
          find.text('Made from this song with your credits'),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancel'));
        await settleFrames(tester);
        expect(auto.cancelledCountdowns, ['song-1']);
      },
    );

    testWidgets(
      'the lyric video being made shows its real progress and opens it',
      (tester) async {
        final env = songEnv()
          ..addVideo(
            sampleVideo(
              level: MusicMvLevel.lyricVideo,
              status: MusicWorkStatus.pending,
              source: MusicMvSource.autoLyric,
            ),
          );
        await open(
          tester,
          const MusicAutoVideoTask(
            workId: 'song-1',
            level: MusicMvLevel.lyricVideo,
            videoId: 'video-1',
          ),
          env: env,
        );
        env.runner.push(
          'video-1',
          const MusicMvSnapshot(
            status: MusicJobStatus.running,
            stage: 'storyboarding',
            progress: 0.4,
          ),
        );
        await settleFrames(tester);
        expect(find.text('Making your lyric video'), findsOneWidget);
        expect(find.text('Writing the storyboard'), findsOneWidget);
        expect(find.text('40%'), findsOneWidget);
        await tester.tap(find.text('View'));
        await settleFrames(tester);
        expect(find.byType(MusicMvGeneratingPage), findsOneWidget);
      },
    );

    testWidgets(
      'a finished lyric video offers Watch and the upgrade to a chorus video',
      (tester) async {
        final env = songEnv()
          ..addVideo(
            sampleVideo(
              level: MusicMvLevel.lyricVideo,
              source: MusicMvSource.autoLyric,
              creditsCharged: 0,
            ),
          );
        await open(
          tester,
          const MusicAutoVideoTask(
            workId: 'song-1',
            level: MusicMvLevel.lyricVideo,
            videoId: 'video-1',
          ),
          env: env,
        );
        expect(find.text('Lyric video is ready'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('mv.auto.upgrade')));
        await settleFrames(tester);
        expect(
          currentLocation(tester),
          '/library/works/song-1/mv?level=chorus_mv&from=video-1',
        );
      },
    );

    testWidgets(
      'an automatic video that could not start says so and can be dismissed',
      (tester) async {
        await open(
          tester,
          MusicAutoVideoTask(
            workId: 'song-1',
            level: MusicMvLevel.lyricVideo,
            failure: const ErrorHandler().handle(
              MusicErrorCode.mvSongNotReady.toApiError(),
            ),
          ),
        );
        expect(find.textContaining('The video couldn’t start'), findsOneWidget);
        await tester.tap(find.text('Dismiss'));
        await settleFrames(tester);
        expect(find.byKey(const ValueKey('mv.auto')), findsNothing);
      },
    );
  });

  group('P28 length panel and the video switch', () {
    testWidgets(
      'off Premier, a Premier-only song + chorus video; the lyric-video switch sits with Standard in the options',
      (tester) async {
        final container = await pumpRoute(
          tester,
          '/create?panel=length',
          env: MusicTestEnv(),
        );
        expect(find.textContaining('Song + chorus video'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('panel.length.songChorus')),
            matching: find.text('Premier'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('panel.length.autoVideo')),
          findsNothing,
          reason: 'moved to the composer (ADR-0033)',
        );
        await tester.tap(find.byKey(const ValueKey('panel.length.standard')));
        await settleFrames(tester);
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('composer.video')),
            matching: find.byType(Switch),
          ),
        );
        await settleFrames(tester);
        expect(
          container.read(creationDraftProvider).draft!.autoVideo,
          MusicAutoVideo.lyric,
        );
        await tester.tap(find.byKey(const ValueKey('composer.length')));
        await settleFrames(tester);
        await tester.tap(find.byKey(const ValueKey('panel.length.songChorus')));
        await settleFrames(tester);
        expect(find.byType(MusicPaywallPage), findsOneWidget);
      },
    );

    testWidgets(
      'on Premier the bundle sets the full song and the chorus video',
      (tester) async {
        final env = MusicTestEnv()
          ..entitlement = const MusicEntitlement(
            tier: MusicTier.premier,
            songsLeft: 120,
            clipsLeft: 200,
          );
        final container = await pumpRoute(
          tester,
          '/create?panel=length',
          env: env,
        );
        await tester.tap(find.byKey(const ValueKey('panel.length.songChorus')));
        await settleFrames(tester);
        final draft = container.read(creationDraftProvider).draft!;
        expect(draft.model, MusicSongModel.fullSong);
        expect(draft.autoVideo, MusicAutoVideo.chorus);
        expect(
          find.byKey(const ValueKey('composer.video')),
          findsNothing,
          reason: 'the chorus video is already coming',
        );
      },
    );

    testWidgets('templates made to be posted start with the lyric video on', (
      tester,
    ) async {
      final container = await pumpRoute(
        tester,
        '/create/template/festival',
        env: MusicTestEnv(),
      );
      expect(
        container.read(creationDraftProvider).draft!.autoVideo,
        MusicAutoVideo.lyric,
      );
      GoRouter.of(
        tester.element(find.byType(Scaffold).last),
      ).go('/create/template/birthday_wish');
      await settleFrames(tester);
      expect(
        container.read(creationDraftProvider).draft!.autoVideo,
        MusicAutoVideo.none,
      );
    });
  });

  group('P29 paywall / P30 settings', () {
    testWidgets(
      'opened for a video, the video packs lead under their own title; Premier says it also makes videos',
      (tester) async {
        await pumpRoute(
          tester,
          '/paywall?reason=mv&product=com.songlet.mv.chorus',
          env: MusicTestEnv(),
        );
        expect(
          find.byKey(const ValueKey('paywall.videoGroup')),
          findsOneWidget,
        );
        final group = tester.getTopLeft(
          find.byKey(const ValueKey('paywall.videoGroup')),
        );
        final premier = tester.getTopLeft(
          find.byKey(
            const ValueKey('paywall.product.com.songlet.premier.monthly'),
          ),
        );
        expect(group.dy, lessThan(premier.dy));
        await reveal(
          tester,
          find.text('Your allowance also makes music videos'),
        );
        expect(
          find.text('Your allowance also makes music videos'),
          findsOneWidget,
        );
        await settleFrames(tester);
      },
    );

    testWidgets('otherwise the video packs follow the song packs', (
      tester,
    ) async {
      await pumpRoute(tester, '/paywall', env: MusicTestEnv());
      await reveal(tester, find.byKey(const ValueKey('paywall.videoGroup')));
      final group = tester.getTopLeft(
        find.byKey(const ValueKey('paywall.videoGroup')),
      );
      final pack = tester.getTopLeft(
        find.byKey(const ValueKey('paywall.product.com.songlet.pack.10')),
      );
      expect(group.dy, greaterThan(pack.dy));
      await settleFrames(tester);
    });

    testWidgets(
      'settings profile shows unknown credits while the platform does not report them',
      (tester) async {
        await pumpRoute(tester, '/settings', env: MusicTestEnv());
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('settings.credits')),
            matching: find.text('—'),
          ),
          findsOneWidget,
        );
        await settleFrames(tester);
      },
    );

    testWidgets('settings profile shows the credits the platform reports', (
      tester,
    ) async {
      final env = MusicTestEnv()
        ..entitlement = const MusicEntitlement(
          tier: MusicTier.premier,
          songsLeft: 120,
          clipsLeft: 200,
          creditsAvailable: 1850,
        );
      await pumpRoute(tester, '/settings', env: env);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('settings.credits')),
          matching: find.text('1,850'),
        ),
        findsOneWidget,
      );
      await settleFrames(tester);
    });
  });

  group('notifications', () {
    testWidgets('the copy is localized and opening one goes to the video', (
      tester,
    ) async {
      final env = songEnv();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SizedBox()),
          GoRoute(
            path: '/library/works/:id/mv/generate/:videoId',
            builder: (context, state) => const Text('progress'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await env.overrides(),
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
            builder: (context, child) =>
                MusicMvNotificationBinding(router: router, child: child!),
          ),
        ),
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MusicMvNotificationBinding)),
      );
      await container
          .read(mvNotificationsProvider)
          .scheduleFor(
            sampleVideo(status: MusicWorkStatus.pending),
            etaSeconds: 600,
          );
      final scheduled = env.notifications.scheduled.single;
      expect(scheduled.title, 'Your video should be ready');
      expect(scheduled.body, 'Chorus video — tap to watch.');
      expect(scheduled.after, const Duration(minutes: 10));
      expect(scheduled.location, '/library/works/song-1/mv/generate/video-1');

      env.notifications.taps.add(scheduled.location);
      await tester.pump();
      await tester.pump();
      expect(find.text('progress'), findsOneWidget);
    });
  });
}
