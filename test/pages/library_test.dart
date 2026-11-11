import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/ui/work/music_work_detail_page.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../support/music_harness.dart';

MusicTestEnv _library() => MusicTestEnv()
  ..addWork(sampleClip())
  ..addWork(sampleClip(id: 'song-1', model: MusicSongModel.fullSong))
  ..addWork(sampleClip(id: 'b-3'))
  ..addWork(sampleClip(id: 'wed-1', template: MusicSongTemplate.wedding))
  ..addWork(sampleClip(id: 'free-1', template: null));

void main() {
  setUp(mockNativeChannels);

  testWidgets('P12 empty: the empty state leads to create', (tester) async {
    await pumpRoute(tester, '/library');
    expect(find.byKey(const ValueKey('library.empty')), findsOneWidget);
    await tester.tap(find.text('Make your first song'));
    await settleFrames(tester);
    expect(currentLocation(tester), '/create');
  });

  testWidgets(
    'P12 grouped by occasion, badges, See all; no iCloud sync status',
    (tester) async {
      await pumpRoute(tester, '/library', env: _library());
      expect(find.text('Birthday'), findsWidgets);
      expect(find.text('Wedding'), findsWidgets);
      expect(find.text('Preview'), findsWidgets);
      expect(find.text('Full song'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('library.sync')),
        findsNothing,
        reason: 'iCloud sync is suspended (ADR-0013)',
      );
      await tester.tap(find.text('See all'));
      await settleFrames(tester);
      expect(currentLocation(tester), '/library/occasion/birthday');
    },
  );

  testWidgets(
    'filters narrow to one occasion; "Just because" holds free-form songs',
    (tester) async {
      await pumpRoute(tester, '/library', env: _library());
      await tester.tap(find.byKey(const ValueKey('library.filter.wedding')));
      await tester.pump();
      expect(find.byKey(const ValueKey('library.work.wed-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('library.work.clip-1')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('library.filter.all')));
      await tester.pump();
      await reveal(tester, find.byKey(const ValueKey('library.work.free-1')));
      expect(find.text('Just because'), findsWidgets);
    },
  );

  testWidgets('play toggles the native player inline', (tester) async {
    final env = _library();
    await pumpRoute(tester, '/library', env: env);
    await tester.tap(find.byTooltip('Play For Alex').first);
    await tester.pump();
    expect(env.audio.plays, isNotEmpty);
  });

  testWidgets('more → Details opens P13; delete confirms and removes', (
    tester,
  ) async {
    final env = _library();
    await pumpRoute(tester, '/library', env: env);
    await tester.tap(find.byTooltip('Actions for For Alex').first);
    await settleFrames(tester);
    await tester.tap(find.text('Details'));
    await settleFrames(tester);
    expect(find.byType(MusicWorkDetailPage), findsOneWidget);
    await reveal(tester, find.byKey(const ValueKey('detail.delete')));
    await tester.tap(find.byKey(const ValueKey('detail.delete')));
    await settleFrames(tester);
    expect(find.text('Delete this song?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await settleFrames(tester);
    expect(currentLocation(tester), '/library');
    expect(env.works.works.length, 4);
  });

  testWidgets('P13 shows the prompt used, lyrics and the generation id', (
    tester,
  ) async {
    final env = MusicTestEnv()
      ..addWork(sampleClip(id: 'song-1', model: MusicSongModel.fullSong));
    await pumpRoute(tester, '/library/works/song-1', env: env);
    expect(find.text('Prompt used'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);
    expect(find.text('coffee, hiking, Sunday'), findsOneWidget);
    await reveal(tester, find.byKey(const ValueKey('detail.id')));
    expect(find.text(MusicWorkDetailPage.displayId('job-song-1')), findsOneWidget);
    await tester.tap(find.byTooltip('Copy text'));
    await settleFrames(tester);
    expect(find.text('Copied'), findsOneWidget);
  });
}
