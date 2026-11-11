import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:songlet/ui/paywall/music_paywall_page.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/music_harness.dart';

void main() {
  setUp(mockNativeChannels);

  group('P07 preview', () {
    testWidgets('autoplays once, with the AI badge, timed lyrics and actions', (
      tester,
    ) async {
      final env = MusicTestEnv()..addWork(sampleClip());
      await pumpRoute(tester, '/library/works/clip-1/preview', env: env);
      expect(env.audio.plays, [('/audio/clip-1.mp3', false)]);
      expect(find.byType(AiGeneratedBadge), findsOneWidget);
      expect(find.text('For Alex'), findsOneWidget);
      expect(find.text('0:12'), findsWidgets);
      await reveal(tester, find.byKey(const ValueKey('player.anotherVersion')));
      expect(find.byKey(const ValueKey('player.fullSong')), findsOneWidget);
    });

    testWidgets('moving to another work gives it its own page and autoplay', (
      tester,
    ) async {
      final env = MusicTestEnv()
        ..addWork(sampleClip())
        ..addWork(sampleClip(id: 'clip-2'));
      await pumpRoute(tester, '/library/works/clip-1/preview', env: env);
      GoRouter.of(
        tester.element(find.byType(Scaffold).last),
      ).go('/library/works/clip-2/preview');
      await settleFrames(tester);
      expect(env.audio.plays.map((p) => p.$1), [
        '/audio/clip-1.mp3',
        '/audio/clip-2.mp3',
      ]);
    });

    testWidgets('loop toggles through the native player; a lyric line seeks', (
      tester,
    ) async {
      final env = MusicTestEnv()..addWork(sampleClip());
      await pumpRoute(tester, '/library/works/clip-1/preview', env: env);
      await tester.tap(find.byKey(const ValueKey('player.loop')));
      await tester.pump();
      expect(env.audio.plays.last, ('/audio/clip-1.mp3', true));
      await reveal(tester, find.text('May your days be brighter'));
      await tester.tap(find.text('May your days be brighter'));
      await tester.pump();
      expect(env.audio.seeks.last, 12);
    });

    testWidgets(
      '"Get the full song" goes straight to generation: the server answers QUOTA_EXHAUSTED when credits are short',
      (tester) async {
        final generation = MusicRecordingGeneration();
        final env = MusicTestEnv()..addWork(sampleClip());
        await pumpRoute(
          tester,
          '/library/works/clip-1/preview',
          env: env,
          overrides: [
            generationControllerProvider.overrideWith(() => generation),
          ],
        );
        await reveal(tester, find.byKey(const ValueKey('player.fullSong')));
        await tester.tap(find.byKey(const ValueKey('player.fullSong')));
        await settleFrames(tester);
        expect(
          find.byType(MusicPaywallPage),
          findsNothing,
          reason: 'no client-side gate on a songs counter',
        );
        expect(generation.generated.single.$2, MusicSongModel.fullSong);
        expect(currentLocation(tester), '/create/generate');
      },
    );

    testWidgets('"Get the full song" generates the full song', (tester) async {
      final generation = MusicRecordingGeneration();
      final env = MusicTestEnv()
        ..addWork(sampleClip())
        ..entitlement = const MusicEntitlement(
          tier: MusicTier.pro,
          songsLeft: 40,
          clipsLeft: 100,
        );
      await pumpRoute(
        tester,
        '/library/works/clip-1/preview',
        env: env,
        overrides: [
          generationControllerProvider.overrideWith(() => generation),
        ],
      );
      await reveal(tester, find.byKey(const ValueKey('player.fullSong')));
      await tester.tap(find.byKey(const ValueKey('player.fullSong')));
      await settleFrames(tester);
      expect(generation.generated.single.$2, MusicSongModel.fullSong);
      expect(currentLocation(tester), '/create/generate');
    });

    testWidgets('a work without audio on the device shows the missing state', (
      tester,
    ) async {
      final env = MusicTestEnv()
        ..addWork(sampleClip().copyWith(status: MusicWorkStatus.failed));
      env.works.works['clip-1'] = MusicWork(
        id: 'clip-1',
        model: MusicSongModel.clip,
        status: MusicWorkStatus.failed,
        occasion: MusicOccasion.birthday,
        region: 'US',
        genre: 'Pop',
        lyricLanguage: 'en',
        createdAt: DateTime.utc(2026),
      );
      await pumpRoute(tester, '/library/works/clip-1/preview', env: env);
      expect(find.byKey(const ValueKey('player.missing')), findsOneWidget);
    });
  });

  group('audio path', () {
    testWidgets(
      'a song whose audio is still being read is not shown as missing',
      (tester) async {
        final env = MusicTestEnv()..addWork(sampleClip());
        env.audioStore.pathGate = Completer<void>();
        await pumpRoute(tester, '/library/works/clip-1/preview', env: env);
        expect(
          find.byKey(const ValueKey('player.audioLoading')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('player.missing')), findsNothing);

        env.audioStore.pathGate!.complete();
        await tester.pump();
        await tester.pump();
        expect(find.byKey(const ValueKey('player.audioLoading')), findsNothing);
        expect(find.byKey(const ValueKey('player.scrubber')), findsOneWidget);
      },
    );
  });

  group('P09 full song', () {
    testWidgets('sections, next / previous section, shuffle and repeat', (
      tester,
    ) async {
      final env = MusicTestEnv()
        ..addWork(sampleClip(id: 'song-1', model: MusicSongModel.fullSong));
      await pumpRoute(tester, '/library/works/song-1/play', env: env);
      expect(find.byKey(const ValueKey('player.sections')), findsOneWidget);
      for (final label in ['Intro', 'Verse', 'Chorus', 'Bridge', 'Outro']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.byTooltip('Next section'));
      await tester.pump();
      expect(env.audio.seeks.last, 10);
      await tester.tap(find.text('Chorus'));
      await tester.pump();
      expect(env.audio.seeks.last, 45);
      await tester.tap(find.byTooltip('Repeat'));
      await tester.pump();
      expect(env.audio.plays.last.$2, isTrue);
      await tester.tap(find.byTooltip('Shuffle sections'));
      await tester.pump();
      final shuffle = tester.widget<PlaybackControls>(
        find.byType(PlaybackControls),
      );
      expect(shuffle.shuffle, isTrue);
    });

    testWidgets('the action tiles route to download and share', (tester) async {
      final env = MusicTestEnv()
        ..addWork(sampleClip(id: 'song-1', model: MusicSongModel.fullSong));
      await pumpRoute(
        tester,
        '/library/works/song-1/play',
        env: env,
        overrides: [
          exportServiceProvider.overrideWithValue(MusicFakeExportService()),
        ],
      );
      await reveal(tester, find.byKey(const ValueKey('player.download')));
      await tester.tap(find.byKey(const ValueKey('player.download')));
      await settleFrames(tester);
      expect(currentLocation(tester), '/library/works/song-1/download');
    });
  });
}
