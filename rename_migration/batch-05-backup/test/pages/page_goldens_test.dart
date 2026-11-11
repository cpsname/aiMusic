import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:songlet_kit/songlet_kit.dart';

import '../support/music_harness.dart';

/// One golden per prototype page (docs/ui P01–P18, ADR-0007; P03 / P18 are the
/// create home with a tile picked since ADR-0032) at the design
/// device (393-pt class, iPhone 17 Pro), light, reduce-motion.
class PageCase {
  const PageCase(
    this.id,
    this.location, {
    this.overrides = const [],
    this.setup,
    this.prepare,
    this.device,
  });

  final String id;
  final String location;
  final List<Override> overrides;
  final void Function(SongletTestEnv env)? setup;

  /// The device of this page's golden when the page is defined by it (the
  /// P21 two-pane hub, the P27 landscape video); the design device otherwise.
  /// The device matrix renders every case on every device regardless.
  final TestDevice? device;

  /// Drives the page into the state the prototype shows.
  final Future<void> Function(WidgetTester tester)? prepare;
}

/// The account ID the settings goldens show (the device session's `abid`).
const String _sampleAccountId = '6b29fc40-ca47-1067-b31d-00dd010662da';

final List<PageCase> pageCases = [
  const PageCase('P01', '/create'),
  const PageCase('P02a', '/create?panel=length'),
  // The server's inspirations at the end of the one Inspiration grid
  // (contract 02 v1.2, ADR-0029 amended).
  PageCase(
    'P01-inspirations',
    '/create',
    prepare: (tester) async {
      final page = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      page.jumpTo(page.maxScrollExtent);
      await tester.pump();
    },
  ),
  const PageCase('P02b', '/create?panel=vocals'),
  const PageCase('P02c', '/create?panel=genre'),
  const PageCase('P02', '/create/region'),
  // A tile picked by tapping it (ADR-0032, ADR-0033 state B): the accent
  // outline, the card's head and its fields in place of the prompt.
  PageCase(
    'P01-picked',
    '/create',
    prepare: (tester) async {
      await reveal(tester, find.byKey(const ValueKey('tile.love_story')));
      await tester.tap(
        find
            .descendant(
              of: find.byKey(const ValueKey('tile.love_story')),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await settleFrames(tester);
    },
  ),
  // P03 is the former form's deep link: the create home with that tile
  // picked, in view, and the composer's fields filled in.
  PageCase(
    'P03',
    '/create/template/birthday_wish',
    prepare: (tester) async {
      await settleFrames(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('composer.name')),
          matching: find.byType(TextField),
        ),
        'Alex',
      );
      for (final word in ['coffee', 'hiking', 'Sunday']) {
        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey('composer.keywords')),
            matching: find.byType(TextField),
          ),
          word,
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await settleFrames(tester);
    },
  ),
  // The composer's options (ADR-0033 state C) over free input and over a
  // picked card.
  const PageCase('P01-options', '/create?options=1'),
  PageCase(
    'P03-options',
    '/create?template=birthday_wish&options=1',
    prepare: (tester) async {
      await settleFrames(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('composer.name')),
          matching: find.byType(TextField),
        ),
        'Alex',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await settleFrames(tester);
      // Typing scrolled the name into view; the state shows its selectors.
      await tester.ensureVisible(
        find.byKey(const ValueKey('composer.summary')),
      );
      await settleFrames(tester);
    },
  ),
  // The keyboard up (ADR-0034): free input keeps a row of the grid; a picked
  // card folds the grid, its head stays in the composer.
  PageCase(
    'P01-keyboard',
    '/create',
    prepare: (tester) async {
      await showKeyboard(tester);
      await settleFrames(tester);
    },
  ),
  PageCase(
    'P03-keyboard',
    '/create/template/birthday_wish',
    prepare: (tester) async {
      await settleFrames(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('composer.name')),
          matching: find.byType(TextField),
        ),
        'Alex',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await showKeyboard(tester);
      await settleFrames(tester);
    },
  ),
  const PageCase('P03a', '/create?mode=voice'),
  const PageCase('P04', '/create/photos'),
  PageCase(
    'P05',
    '/create/generate',
    overrides: [
      generationControllerProvider.overrideWith(
        () => FixedGeneration(waitingGeneration()),
      ),
    ],
    setup: (env) => env.addWork(sampleClip()),
  ),
  PageCase(
    'P06',
    '/create/generate',
    overrides: [
      generationControllerProvider.overrideWith(
        () => FixedGeneration(waitingGeneration(queued: true)),
      ),
    ],
    setup: (env) => env.addWork(sampleClip()),
  ),
  PageCase(
    'P07',
    '/library/works/clip-1/preview',
    setup: (env) => env.addWork(sampleClip()),
  ),
  const PageCase('P08', '/paywall'),
  PageCase(
    'P09',
    '/library/works/song-1/play',
    setup: (env) =>
        env.addWork(sampleClip(id: 'song-1', model: SongModel.fullSong)),
  ),
  PageCase(
    'P10',
    '/library/works/song-1/share',
    setup: (env) =>
        env.addWork(sampleClip(id: 'song-1', model: SongModel.fullSong)),
  ),
  PageCase(
    'P11',
    '/library/works/song-1/download',
    overrides: [exportServiceProvider.overrideWithValue(FakeExportService())],
    setup: (env) =>
        env.addWork(sampleClip(id: 'song-1', model: SongModel.fullSong)),
  ),
  PageCase(
    'P12',
    '/library',
    setup: (env) {
      env
        ..addWork(sampleClip())
        ..addWork(sampleClip(id: 'song-1', model: SongModel.fullSong))
        ..addWork(sampleClip(id: 'wed-1', template: SongTemplate.wedding))
        ..addWork(sampleClip(id: 'free-1', template: null));
    },
  ),
  PageCase(
    'P13',
    '/library/works/song-1',
    setup: (env) =>
        env.addWork(sampleClip(id: 'song-1', model: SongModel.fullSong)),
  ),
  PageCase(
    'P14',
    '/settings',
    overrides: [appAccountTokenProvider.overrideWithValue(_sampleAccountId)],
  ),
  const PageCase('P15', '/settings/about'),
  const PageCase('P16', '/create/festival/carnival'),
  const PageCase('P17', '/unavailable'),
  // Music videos (PRD ch.15; docs/ui P19–P30, ADR-0027).
  PageCase(
    'P19',
    '/library/works/song-1/play',
    setup: (env) {
      env
        ..addWork(sampleClip(id: 'song-1', model: SongModel.fullSong))
        ..addVideo(sampleVideo(id: 'making', status: WorkStatus.pending))
        ..runner.push('making', _rendering);
    },
    prepare: (tester) async {
      // The entry sits at the end of the song page (far down at AX5, where a
      // drag would land on the nested lyrics list): move the page itself.
      final entry = find.byKey(const ValueKey('mv.entry'));
      final page = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      for (var i = 0; i < 20 && entry.evaluate().isEmpty; i++) {
        page.jumpTo(page.maxScrollExtent);
        await tester.pump();
      }
      await tester.ensureVisible(entry);
      await tester.pump();
    },
  ),
  PageCase(
    'P20',
    '/library/works/song-1/mv',
    overrides: [mvControllerProvider.overrideWith(() => FixedMv(_estimated))],
    setup: _song,
  ),
  PageCase(
    'P21',
    '/library/works/song-1/mv?level=chorus_mv',
    overrides: [mvControllerProvider.overrideWith(() => FixedMv(_estimated))],
    setup: _song,
    device: TestDevice.iPadPro13.landscape,
  ),
  PageCase(
    'P22',
    '/library/works/song-1/mv',
    setup: (env) {
      _song(env);
      env.mvs.createError = ApiError.fromEnvelope(
        code: 49303,
        message: 'quota exhausted',
        details: {
          'error_code': 'QUOTA_EXHAUSTED',
          'reason': 'insufficient',
          'required_credits': '2169',
          'available_credits': '66',
          'recommended_product_id': 'com.songlet.mv.chorus',
        },
      );
    },
    prepare: (tester) async {
      await reveal(tester, find.byKey(const ValueKey('mv.create')));
      await tester.tap(find.byKey(const ValueKey('mv.create')));
      await settleFrames(tester);
    },
  ),
  PageCase(
    'P23',
    '/library/works/song-1/play',
    overrides: [
      autoVideoCoordinatorProvider.overrideWith(
        () => FixedAutoVideo({
          'song-1': const AutoVideoTask(
            workId: 'song-1',
            level: MvLevel.lyricVideo,
            videoId: 'lyric-1',
          ),
        }),
      ),
    ],
    setup: (env) {
      env
        ..addWork(sampleClip(id: 'song-1', model: SongModel.fullSong))
        ..addVideo(
          sampleVideo(
            id: 'lyric-1',
            level: MvLevel.lyricVideo,
            status: WorkStatus.pending,
            source: MvSource.autoLyric,
          ),
        )
        ..runner.push(
          'lyric-1',
          const MvSnapshot(
            status: JobStatus.running,
            stage: 'storyboarding',
            progress: 0.4,
          ),
        );
    },
  ),
  PageCase(
    'P24',
    '/library/works/song-1/mv/generate/video-1',
    setup: (env) {
      env
        ..addWork(sampleClip(id: 'song-1', model: SongModel.fullSong))
        ..addVideo(sampleVideo(status: WorkStatus.pending))
        ..runner.push('video-1', _rendering);
    },
  ),
  PageCase(
    'P25',
    '/library/works/song-1/mv/generate/video-1',
    setup: (env) {
      env
        ..addWork(sampleClip(id: 'song-1', model: SongModel.fullSong))
        ..addVideo(
          sampleVideo(
            status: WorkStatus.failed,
            errorCode: 'IMAGE_REJECTED',
            photoCount: 3,
          ),
        );
    },
  ),
  PageCase(
    'P26',
    '/library/works/song-1/mv/video-1',
    setup: (env) {
      env
        ..addWork(sampleClip(id: 'song-1', model: SongModel.fullSong))
        ..addVideo(sampleVideo(level: MvLevel.full));
    },
  ),
  PageCase(
    'P27',
    '/library/works/song-1/mv/video-1',
    setup: (env) {
      env
        ..addWork(sampleClip(id: 'song-1', model: SongModel.fullSong))
        ..addVideo(
          sampleVideo(
            level: MvLevel.full,
            aspectRatio: MvAspectRatio.landscape,
          ),
        );
    },
    device: TestDevice.iPadPro13.landscape,
  ),
  // Standard in the composer's options: "also make a lyric video" switched on
  // (ADR-0022, ADR-0033), the action naming the full song from the ledger.
  PageCase(
    'P28',
    '/create?panel=length',
    setup: (env) {
      env.entitlement = const MusicEntitlement(
        tier: MusicTier.premier,
        songsLeft: 120,
        clipsLeft: 200,
      );
    },
    prepare: (tester) async {
      await settleFrames(tester);
      // At the largest text sizes the panel scrolls: bring the row into view.
      await tester.ensureVisible(
        find.byKey(const ValueKey('panel.length.standard')),
      );
      await settleFrames(tester);
      await tester.tap(find.byKey(const ValueKey('panel.length.standard')));
      await settleFrames(tester);
      final video = find.descendant(
        of: find.byKey(const ValueKey('composer.video')),
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(video);
      await settleFrames(tester);
      await tester.tap(video);
      await settleFrames(tester);
    },
  ),
  const PageCase('P29', '/paywall?reason=mv&product=com.songlet.mv.chorus'),
  PageCase(
    'P30',
    '/settings',
    overrides: [appAccountTokenProvider.overrideWithValue(_sampleAccountId)],
    setup: (env) {
      env.entitlement = const MusicEntitlement(
        tier: MusicTier.premier,
        songsLeft: 118,
        clipsLeft: 196,
        creditsAvailable: 1850,
      );
    },
  ),
  // P18 in the composer: an artist reference in the name, sent.
  PageCase(
    'P18',
    '/create/template/birthday_wish',
    prepare: (tester) async {
      await settleFrames(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('composer.name')),
          matching: find.byType(TextField),
        ),
        'Taylor Swift style',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('composer.keywords')),
          matching: find.byType(TextField),
        ),
        'coffee',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      FocusManager.instance.primaryFocus?.unfocus();
      await settleFrames(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('composer.create')));
      await settleFrames(tester);
      await tester.tap(find.byKey(const ValueKey('composer.create')));
      await settleFrames(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('composer.name')));
      await settleFrames(tester);
    },
  ),
];

const MvSnapshot _rendering = MvSnapshot(
  status: JobStatus.running,
  stage: 'rendering',
  progress: 0.661,
  segmentsDone: 1,
  segmentsTotal: 3,
  etaSeconds: 420,
);

const MvEstimated _estimated = MvEstimated(
  workId: 'song-1',
  level: MvLevel.chorus,
  estimates: {
    MvLevel.lyricVideo: MvEstimate(
      level: MvLevel.lyricVideo,
      credits: 0,
      availableCredits: 3000,
      affordable: true,
      gapCredits: 0,
      songLocked: true,
    ),
    MvLevel.chorus: MvEstimate(
      level: MvLevel.chorus,
      credits: 2169,
      availableCredits: 3000,
      affordable: true,
      gapCredits: 0,
      songLocked: true,
    ),
    MvLevel.full: MvEstimate(
      level: MvLevel.full,
      credits: 8763,
      availableCredits: 3000,
      affordable: false,
      gapCredits: 5763,
      songLocked: true,
      recommendedProductId: 'com.songlet.mv.full',
    ),
  },
);

void _song(SongletTestEnv env) =>
    env.addWork(sampleClip(id: 'song-1', model: SongModel.fullSong));

void main() {
  setUp(mockNativeChannels);

  for (final page in pageCases) {
    // A page defined by an iPad layout (P21, P27) runs only while the app
    // ships for iPad (ADR-0037).
    testWidgets('${page.id} golden', skip: page.device?.skipped ?? false, (
      tester,
    ) async {
      final env = SongletTestEnv();
      page.setup?.call(env);
      await pumpRoute(
        tester,
        page.location,
        env: env,
        overrides: page.overrides,
        device: page.device ?? TestDevice.iPhone17Pro,
      );
      if (page.id == 'P03a') {
        env.speech.session?.add(
          const SpeechPartial(
            "It's Alex's thirtieth birthday, she loves hiking and Sunday coffee",
          ),
        );
        for (var i = 0; i < 40; i++) {
          env.speech.session?.add(SpeechLevel(0.2 + (i * 37 % 17) / 20));
        }
      }
      await page.prepare?.call(tester);
      await settleFrames(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/pages/${page.id}.png'),
      );
    });
  }
}
