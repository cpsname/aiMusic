import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:infra_core/infra_core.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../support/music_harness.dart';

/// Leak check (Phase 6): the main flows are driven page to page with Flutter's
/// leak tracker on. A disposable created on the way (controllers, focus nodes,
/// tickers, notifiers, pictures) that is never disposed fails the file; the
/// test harness's own fixtures are exempt.
void main() {
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings
      .withTrackedAll()
      .withIgnored(createdByTestHelpers: true)
      .withCreationStackTrace();
  setUp(mockNativeChannels);
  // Decoded art lives in the global ImageCache by design; empty it so what
  // remains is what the pages themselves failed to dispose.
  tearDown(
    () => imageCache
      ..clear()
      ..clearLiveImages(),
  );

  // Unmounts the app and lets in-flight work (image decodes) finish, so what
  // the tracker sees afterwards is only what was never released.
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await settleFrames(tester);
    imageCache
      ..clear()
      ..clearLiveImages();
  }

  Future<void> go(WidgetTester tester, String location) async {
    GoRouter.of(tester.element(find.byType(Scaffold).last)).go(location);
    await settleFrames(tester);
  }

  testWidgets(
    'create: home → panels → a picked tile (deep link) → region → home',
    (tester) async {
      await pumpRoute(tester, '/create');
      for (final panel in ['length', 'vocals', 'genre']) {
        await go(tester, '/create?panel=$panel');
        await go(tester, '/create');
      }
      await go(tester, '/create/template/birthday_wish');
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('composer.name')),
          matching: find.byType(TextField),
        ),
        'Alex',
      );
      await go(tester, '/create/region');
      await go(tester, '/create?mode=voice');
      await go(tester, '/create');
      await finish(tester);
    },
  );

  testWidgets(
    'listen: preview → paywall → song → download → share → library → detail',
    (tester) async {
      final env = MusicTestEnv()
        ..addWork(sampleClip())
        ..addWork(sampleClip(id: 'song-1', model: MusicSongModel.fullSong));
      await pumpRoute(
        tester,
        '/library/works/clip-1/preview',
        env: env,
        overrides: [
          exportServiceProvider.overrideWithValue(MusicFakeExportService()),
        ],
      );
      await go(tester, '/paywall');
      await go(tester, '/library/works/song-1/play');
      await go(tester, '/library/works/song-1/download');
      await go(tester, '/library/works/song-1/share');
      await go(tester, '/library');
      await go(tester, '/library/works/song-1');
      await go(tester, '/settings');
      await go(tester, '/settings/about');
      await go(tester, '/create/festival/carnival');
      await finish(tester);
    },
  );

  testWidgets('generate: waiting → success → preview', (tester) async {
    final generation = MusicRecordingGeneration(waitingGeneration());
    final env = MusicTestEnv()..addWork(sampleClip());
    await pumpRoute(
      tester,
      '/create/generate',
      env: env,
      overrides: [generationControllerProvider.overrideWith(() => generation)],
    );
    generation.current = MusicGenerationSucceeded(sampleClip());
    await settleFrames(tester);
    await go(tester, '/create');
    await finish(tester);
  });

  testWidgets(
    'video: hub → credits sheet → progress → player → song page entry',
    (tester) async {
      final env = MusicTestEnv()
        ..addWork(sampleClip(id: 'song-1', model: MusicSongModel.fullSong))
        ..addVideo(sampleVideo(id: 'making', status: MusicWorkStatus.pending))
        ..addVideo(sampleVideo());
      env.runner.push(
        'making',
        const MusicMvSnapshot(
          status: MusicJobStatus.running,
          stage: 'rendering',
          progress: 0.5,
        ),
      );
      await pumpRoute(
        tester,
        '/library/works/song-1/mv',
        env: env,
        overrides: [
          mvRetryDelaysProvider.overrideWithValue(const [Duration.zero]),
        ],
      );
      env.mvs.createError = ApiError.fromEnvelope(
        code: 49303,
        message: 'quota exhausted',
        details: {
          'error_code': 'QUOTA_EXHAUSTED',
          'required_credits': '2169',
          'available_credits': '66',
          'recommended_product_id': 'com.songlet.mv.chorus',
        },
      );
      await tester.tap(find.byKey(const ValueKey('mv.level.full_mv')));
      await settleFrames(tester);
      await tester.tap(find.byKey(const ValueKey('mv.create')));
      await settleFrames(tester);
      await tester.tap(find.byKey(const ValueKey('mv.quota.close')));
      await settleFrames(tester);
      await go(tester, '/library/works/song-1/mv/generate/making');
      await go(tester, '/library/works/song-1/mv/video-1');
      await go(tester, '/library/works/song-1/play');
      await finish(tester);
    },
  );
}
