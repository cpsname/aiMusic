import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/ui/create/create_home_page.dart';
import 'package:songlet/ui/paywall/paywall_page.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/music_harness.dart';

/// P01 — the create home's free input (state A) and its options (state C,
/// ADR-0033): one prompt field, one summary row, one primary action.
void main() {
  setUp(mockNativeChannels);

  Finder create() => find.byKey(const ValueKey('composer.create'));
  String createLabel(WidgetTester tester) => tester
      .widget<ObsButton>(
        find.descendant(of: create(), matching: find.byType(ObsButton)),
      )
      .label;
  bool createEnabled(WidgetTester tester) =>
      tester
          .widget<ObsButton>(
            find.descendant(of: create(), matching: find.byType(ObsButton)),
          )
          .onPressed !=
      null;
  Finder promptField() => find.descendant(
    of: find.byKey(const ValueKey('composer.prompt')),
    matching: find.byType(TextField),
  );

  testWidgets(
    'P01 default: one grid, the prompt, the summary row and one primary action',
    (tester) async {
      await pumpRoute(tester, '/create');
      expect(find.byKey(const ValueKey('composer')), findsOneWidget);
      expect(find.byType(SliverGrid), findsOneWidget);
      for (final slug in [
        'birthday_wish',
        'love_story',
        'festival',
        'team_anthem',
      ]) {
        expect(
          find.byKey(ValueKey('tile.$slug')),
          findsOneWidget,
          reason: slug,
        );
      }
      expect(
        tester.widget<TextField>(promptField()).decoration!.hintText,
        'Describe the song, or pick an idea above',
      );
      expect(find.byKey(const ValueKey('composer.photos')), findsOneWidget);
      expect(find.byKey(const ValueKey('composer.mic')), findsOneWidget);
      expect(
        find.text('Preview  ·  Vocals on  ·  Indie Pop'),
        findsOneWidget,
        reason: 'the US preset and the client defaults',
      );
      expect(
        createLabel(tester),
        'Create preview · free',
        reason: 'the free account has free previews in its ledger',
      );
      expect(
        createEnabled(tester),
        isFalse,
        reason: 'nothing to make a song from yet',
      );
      expect(find.byKey(const ValueKey('allowance')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'removed: the Music chip, the Preview/Full control, the send arrow, the standing artist note',
    (tester) async {
      await pumpRoute(tester, '/create');
      final composer = find.byKey(const ValueKey('composer'));
      expect(
        find.descendant(
          of: composer,
          matching: find.byType(SegmentedToggle<SongModel>),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: composer, matching: find.text('Music')),
        findsNothing,
      );
      expect(
        find.descendant(of: composer, matching: find.text('Full')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: composer,
          matching: find.byIcon(Icons.arrow_upward_rounded),
        ),
        findsNothing,
      );
      expect(find.text("Artist names can't be used"), findsNothing);
      expect(
        find.descendant(of: composer, matching: find.byType(ObsButton)),
        findsOneWidget,
        reason: 'one primary action',
      );
    },
  );

  testWidgets(
    'a typed prompt enables the action, starts a preview and opens the generating page',
    (tester) async {
      final generation = RecordingGeneration();
      await pumpRoute(
        tester,
        '/create',
        overrides: [
          generationControllerProvider.overrideWith(() => generation),
        ],
      );
      await tester.enterText(
        promptField(),
        'A song for my sister moving to Lisbon',
      );
      await tester.pump();
      expect(createEnabled(tester), isTrue);
      await tester.tap(create());
      await settleFrames(tester);
      expect(
        generation.generated.single.$1.prompt,
        'A song for my sister moving to Lisbon',
      );
      expect(generation.generated.single.$1.model, SongModel.clip);
      expect(currentLocation(tester), '/create/generate');
    },
  );

  testWidgets(
    'an artist in the prompt: the inline error under the field, nothing sent',
    (tester) async {
      final generation = RecordingGeneration();
      await pumpRoute(
        tester,
        '/create',
        overrides: [
          generationControllerProvider.overrideWith(() => generation),
        ],
      );
      await tester.enterText(
        promptField(),
        'A birthday song like Taylor Swift',
      );
      await tester.pump();
      await tester.tap(create());
      await settleFrames(tester);
      expect(generation.generated, isEmpty);
      expect(
        tester.widget<TextField>(promptField()).decoration!.errorText,
        "Artist names can't be used — describe the feeling instead.",
      );
    },
  );

  group('options (state C)', () {
    testWidgets('the summary row unfolds and folds them, as a route', (
      tester,
    ) async {
      await pumpRoute(tester, '/create');
      expect(find.byKey(const ValueKey('composer.options')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('composer.summary')));
      await settleFrames(tester);
      expect(currentLocation(tester), '/create?options=1');
      expect(find.byKey(const ValueKey('composer.options')), findsOneWidget);
      for (final id in [
        'composer.length',
        'composer.vocals',
        'composer.genre',
        'composer.lyrics',
      ]) {
        expect(find.byKey(ValueKey(id)), findsOneWidget, reason: id);
      }
      expect(
        find.byKey(const ValueKey('composer.video')),
        findsNothing,
        reason: 'a preview makes no video',
      );
      await tester.tap(find.byKey(const ValueKey('composer.summary')));
      await settleFrames(tester);
      expect(currentLocation(tester), '/create');
      expect(find.byKey(const ValueKey('composer.options')), findsNothing);
    });

    testWidgets(
      'the selectors open their panels as routes and come back to the options',
      (tester) async {
        final container = await pumpRoute(tester, '/create?options=1');
        await tester.tap(find.byKey(const ValueKey('composer.vocals')));
        await settleFrames(tester);
        expect(currentLocation(tester), '/create?panel=vocals&options=1');
        await tester.tap(
          find.byKey(const ValueKey('panel.vocals.instrumental')),
        );
        await settleFrames(tester);
        expect(
          container.read(creationDraftProvider).draft!.vocals,
          Vocals.instrumental,
        );
        expect(currentLocation(tester), '/create?options=1');
        expect(
          find.byKey(const ValueKey('composer.lyrics')),
          findsNothing,
          reason: 'an instrumental takes no lyrics',
        );

        await tester.tap(find.byKey(const ValueKey('composer.genre')));
        await settleFrames(tester);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('panel.genre.bossaNova')),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.byKey(const ValueKey('panel.genre.bossaNova')));
        await settleFrames(tester);
        expect(
          container.read(creationDraftProvider).draft!.genre,
          'Bossa Nova',
        );
        expect(
          find.text('Preview  ·  Instrumental  ·  Bossa Nova'),
          findsOneWidget,
        );
      },
    );

    testWidgets('a panel deep link opens the options under it', (tester) async {
      await pumpRoute(tester, '/create?panel=length');
      await settleFrames(tester);
      expect(find.byKey(const ValueKey('composer.options')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('panel.length.standard')),
        findsOneWidget,
      );
    });

    testWidgets(
      'Standard: the video switch shows, the action names the full song; no client-side gate',
      (tester) async {
        final container = await pumpRoute(tester, '/create?options=1');
        await tester.tap(find.byKey(const ValueKey('composer.length')));
        await settleFrames(tester);
        await tester.tap(find.byKey(const ValueKey('panel.length.standard')));
        await settleFrames(tester);
        expect(find.byType(PaywallPage), findsNothing);
        expect(
          container.read(creationDraftProvider).draft!.model,
          SongModel.fullSong,
        );
        expect(find.byKey(const ValueKey('composer.video')), findsOneWidget);
        expect(
          createLabel(tester),
          'Create full song',
          reason: 'no songs in the ledger: no cost is promised',
        );

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('composer.video')),
            matching: find.byType(Switch),
          ),
        );
        await settleFrames(tester);
        expect(
          container.read(creationDraftProvider).draft!.autoVideo,
          AutoVideo.lyric,
        );
        await tester.tap(find.byKey(const ValueKey('composer.summary')));
        await settleFrames(tester);
        expect(
          find.text('Full song  ·  Vocals on  ·  Indie Pop  ·  Lyric video'),
          findsOneWidget,
          reason: 'what will be sent stays in sight while folded',
        );
      },
    );
  });

  group('the primary action and the ledger (ADR-0035)', () {
    Future<String> labelFor(
      WidgetTester tester,
      MusicEntitlement entitlement, {
      String location = '/create',
    }) async {
      final env = SongletTestEnv()..entitlement = entitlement;
      await pumpRoute(tester, location, env: env);
      await settleFrames(tester);
      return createLabel(tester);
    }

    testWidgets('a plan: the preview is "1 preview"', (tester) async {
      const pro = MusicEntitlement(
        tier: MusicTier.pro,
        songsLeft: 40,
        clipsLeft: 100,
      );
      expect(await labelFor(tester, pro), 'Create preview · 1 preview');
    });

    testWidgets(
      'nothing left: no cost promised; pressing lets the server answer and the paywall opens',
      (tester) async {
        final env = SongletTestEnv()
          ..entitlement = const MusicEntitlement(
            tier: MusicTier.free,
            songsLeft: 0,
            clipsLeft: 0,
          );
        env.jobs.submitError = MusicErrorCode.quotaExhausted.toApiError(
          details: const {'offer': 'subscription'},
        );
        await pumpRoute(tester, '/create', env: env);
        await settleFrames(tester);
        expect(createLabel(tester), 'Create preview');
        await tester.enterText(promptField(), 'Rain on a tin roof');
        await tester.pump();
        await tester.tap(create());
        await settleFrames(tester);
        await settleFrames(tester);
        expect(
          env.jobs.submitted,
          hasLength(1),
          reason: 'no client-side gate (ADR-0031)',
        );
        expect(find.byType(PaywallPage), findsOneWidget);
      },
    );
  });

  testWidgets('photos: the "+" button says how many are added', (tester) async {
    final container = await pumpRoute(tester, '/create');
    container
        .read(creationDraftProvider.notifier)
        .update(
          (d) => d.copyWith(
            photos: [
              [1, 2, 3],
              [4, 5, 6],
            ],
          ),
        );
    await settleFrames(tester);
    expect(find.byTooltip('2 photos added'), findsOneWidget);
    expect(
      createEnabled(tester),
      isTrue,
      reason: 'photos are enough to make a song',
    );
  });

  testWidgets('dictation without permission explains and leaves voice mode', (
    tester,
  ) async {
    final env = SongletTestEnv();
    env.speech.availabilityResult = SpeechAvailability.denied;
    await pumpRoute(tester, '/create?mode=voice', env: env);
    await settleFrames(tester);
    expect(find.textContaining('Allow the microphone'), findsOneWidget);
    expect(currentLocation(tester), '/create');
    expect(find.byType(CreateHomePage), findsOneWidget);
  });
}
