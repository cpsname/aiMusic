import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet/ui/create/create_home_page.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/songlet_harness.dart';

/// Picking a tile on the create home (ADR-0032, ADR-0033): a single pick held
/// by the draft, the composer switching from free input (A) to the card's
/// fields (B) and back without losing a word, the former form's deep links,
/// and what `/v1/generate` receives (contract 02 v2.1).
void main() {
  setUp(mockNativeChannels);

  Finder tile(String slug) => find.byKey(ValueKey('tile.$slug'));
  Finder fields() => find.byKey(const ValueKey('composer.fields'));
  Finder head() => find.byType(ComposerTag);
  Finder promptField() =>
      find.descendant(of: find.byKey(const ValueKey('composer.prompt')), matching: find.byType(TextField));
  Finder wordsField() =>
      find.descendant(of: find.byKey(const ValueKey('composer.words')), matching: find.byType(TextField));
  Finder nameField() =>
      find.descendant(of: find.byKey(const ValueKey('composer.name')), matching: find.byType(TextField));
  Finder keywordField() =>
      find.descendant(of: find.byKey(const ValueKey('composer.keywords')), matching: find.byType(TextField));
  Finder create() => find.byKey(const ValueKey('composer.create'));
  ObsButton createButton(WidgetTester tester) =>
      tester.widget<ObsButton>(find.descendant(of: create(), matching: find.byType(ObsButton)));
  Map<String, String> promptLines(GenerationRequest request) => {
        for (final line in request.prompt.split('\n')) line.substring(0, line.indexOf(':')): line.substring(line.indexOf(':') + 1).trim(),
      };

  bool picked(WidgetTester tester, String slug) =>
      tester.widget<TemplateTile>(find.descendant(of: tile(slug), matching: find.byType(TemplateTile))).selected;

  Future<void> show(WidgetTester tester, String slug) async {
    final grid = tester.state<ScrollableState>(find.byType(Scrollable).first).position..jumpTo(0);
    await tester.pump();
    while (tile(slug).evaluate().isEmpty && grid.pixels < grid.maxScrollExtent) {
      grid.jumpTo((grid.pixels + 200).clamp(0, grid.maxScrollExtent));
      await tester.pump();
    }
    await tester.ensureVisible(tile(slug));
    await settleFrames(tester);
  }

  Future<void> tapTile(WidgetTester tester, String slug) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await settleFrames(tester);
    await show(tester, slug);
    await tester.tap(find.descendant(of: tile(slug), matching: find.byType(InkWell)).first);
    await settleFrames(tester);
  }

  Future<void> addKeyword(WidgetTester tester, String word) async {
    await tester.ensureVisible(keywordField());
    await tester.enterText(keywordField(), word);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  Future<void> send(WidgetTester tester) async {
    await settleFrames(tester);
    await tester.ensureVisible(create());
    await settleFrames(tester);
    await tester.tap(create());
    await settleFrames(tester);
    await settleFrames(tester);
  }

  /// Stops the run a send started, so no poller outlives the test: the
  /// cancel, then past the poll the run may be waiting on.
  Future<void> stopRun(WidgetTester tester, ProviderContainer container) async {
    await container.read(generationControllerProvider.notifier).cancel();
    await settleFrames(tester);
    await tester.pump(container.read(jobRunnerProvider).pollInterval);
    await settleFrames(tester);
  }

  group('single pick', () {
    testWidgets('tap picks, tap again unpicks; one pick at a time; the draft holds it', (tester) async {
      final container = await pumpRoute(tester, '/create');
      expect(fields(), findsNothing, reason: 'free input');
      await tapTile(tester, 'birthday_wish');
      expect(picked(tester, 'birthday_wish'), isTrue);
      expect(container.read(creationDraftProvider).draft!.inspirationSlug, 'birthday_wish');
      expect(currentLocation(tester), '/create', reason: 'no page to go to');

      await tapTile(tester, 'love_story');
      expect(picked(tester, 'love_story'), isTrue);
      await show(tester, 'birthday_wish');
      expect(picked(tester, 'birthday_wish'), isFalse, reason: 'single pick');

      await tapTile(tester, 'love_story');
      expect(picked(tester, 'love_story'), isFalse);
      final draft = container.read(creationDraftProvider).draft!;
      expect(draft.hasPick, isFalse);
      expect(draft.occasion, Occasion.custom);
      expect(fields(), findsNothing);
      expect(head(), findsNothing);
    });

    testWidgets('the play button previews without touching the pick', (tester) async {
      final env = SongletTestEnv();
      final container = await pumpRoute(tester, '/create', env: env);
      await tapTile(tester, 'birthday_wish');
      await show(tester, 'love_story');
      await tester.tap(find.descendant(of: tile('love_story'), matching: find.byIcon(Icons.play_arrow_rounded)));
      await settleFrames(tester);
      expect(env.inspirations.previews, ['https://cdn.songlet.example/inspirations/love_story.mp3']);
      expect(container.read(creationDraftProvider).draft!.inspirationSlug, 'birthday_wish');
      expect(picked(tester, 'love_story'), isFalse);
      await show(tester, 'birthday_wish');
      await tester.tap(find.descendant(of: tile('birthday_wish'), matching: find.byIcon(Icons.play_arrow_rounded)));
      await settleFrames(tester);
      expect(picked(tester, 'birthday_wish'), isTrue);
    });

    testWidgets("the head's close button unpicks too", (tester) async {
      final container = await pumpRoute(tester, '/create');
      await tapTile(tester, 'birthday_wish');
      await tester.tap(find.descendant(of: head(), matching: find.byIcon(Icons.close_rounded)));
      await settleFrames(tester);
      expect(container.read(creationDraftProvider).draft!.hasPick, isFalse);
      expect(picked(tester, 'birthday_wish'), isFalse);
    });
  });

  group('state B: the card in place of the prompt', () {
    testWidgets('head, name and three words; no free prompt, no photos, no mic; the card sets vocals and genre', (tester) async {
      final container = await pumpRoute(tester, '/create');
      await tapTile(tester, 'soundscape');
      expect(find.descendant(of: head(), matching: find.text('Soundscape')), findsOneWidget);
      expect(fields(), findsOneWidget);
      expect(nameField(), findsOneWidget);
      expect(find.byKey(const ValueKey('composer.keywords')), findsOneWidget);
      expect(find.text('Name (optional)'), findsOneWidget, reason: 'requires_recipient false');
      expect(promptField(), findsNothing, reason: 'free input and the card are exclusive');
      expect(wordsField(), findsNothing, reason: 'input_required false');
      expect(find.byKey(const ValueKey('composer.photos')), findsNothing);
      expect(find.byKey(const ValueKey('composer.mic')), findsNothing);
      final draft = container.read(creationDraftProvider).draft!;
      expect(draft.model, SongModel.clip);
      expect(draft.vocals, Vocals.instrumental);
      expect(draft.genre, 'Ambient');
      expect(find.text('Preview  ·  Instrumental  ·  Ambient'), findsOneWidget, reason: 'the card\'s defaults in the summary');
      expect(createButton(tester).label, 'Create preview · free');
      expect(createButton(tester).onPressed, isNotNull, reason: 'the card alone is enough');
    });

    testWidgets('a pick starts at a preview whatever default_model says (ADR-0036); the name goes on the action', (tester) async {
      final container = await pumpRoute(tester, '/create');
      await tapTile(tester, 'birthday_wish');
      expect(container.read(creationDraftProvider).draft!.model, SongModel.clip, reason: 'default_model lyria-3.5 is not the start');
      expect(find.text('Their name'), findsOneWidget, reason: 'requires_recipient true');
      await tester.enterText(nameField(), 'Alex');
      await tester.pump();
      expect(createButton(tester).label, 'Create Alex’s preview · free');
      await tester.enterText(nameField(), '');
      await tester.pump();
      expect(createButton(tester).label, 'Create preview · free');
    });

    testWidgets('the third word closes the keyboard', (tester) async {
      await pumpRoute(tester, '/create');
      await tapTile(tester, 'birthday_wish');
      await addKeyword(tester, 'coffee');
      await addKeyword(tester, 'hiking');
      expect(tester.testTextInput.isVisible, isTrue);
      await addKeyword(tester, 'Sunday');
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets("input_required: 'Your words' with the card's hint, the action waits for them", (tester) async {
      await pumpRoute(tester, '/create');
      await tapTile(tester, 'background_music');
      expect(wordsField(), findsOneWidget);
      expect(find.text('Your words'), findsOneWidget);
      expect(tester.widget<TextField>(wordsField()).decoration!.hintText, 'What is the video about?');
      expect(tester.widget<TextField>(wordsField()).controller!.text, isEmpty, reason: 'nothing prefilled');
      expect(createButton(tester).onPressed, isNull);
      await tester.enterText(wordsField(), 'A cozy cooking vlog');
      await tester.pump();
      expect(createButton(tester).onPressed, isNotNull);
    });

    testWidgets('the hint follows the language: server zh, English for the rest', (tester) async {
      await pumpRoute(tester, '/create', locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
      await tapTile(tester, 'background_music');
      expect(tester.widget<TextField>(wordsField()).decoration!.hintText, '视频讲什么？');
    });

    testWidgets('switching between free input and cards keeps every word', (tester) async {
      final container = await pumpRoute(tester, '/create');
      await tester.enterText(promptField(), 'Thirty and thriving');
      await tester.pump();

      await tapTile(tester, 'birthday_wish');
      expect(promptField(), findsNothing);
      await tester.enterText(nameField(), 'Alex');
      await addKeyword(tester, 'coffee');
      expect(container.read(creationDraftProvider).draft!.prompt, 'Thirty and thriving', reason: 'hidden, kept');

      await tapTile(tester, 'birthday_wish');
      expect(fields(), findsNothing);
      expect(tester.widget<TextField>(promptField()).controller!.text, 'Thirty and thriving', reason: 'A comes back as it was');
      var draft = container.read(creationDraftProvider).draft!;
      expect(draft.recipient, 'Alex');
      expect(draft.keywords, ['coffee']);

      await tapTile(tester, 'love_story');
      expect(tester.widget<TextField>(nameField()).controller!.text, 'Alex', reason: 'B comes back as it was, on another card');
      draft = container.read(creationDraftProvider).draft!;
      expect(draft.keywords, ['coffee']);
      expect(draft.prompt, 'Thirty and thriving');
    });

    testWidgets('dictation is free input: a picked card drops the voice route', (tester) async {
      final container = await pumpRoute(tester, '/create');
      await tapTile(tester, 'birthday_wish');
      GoRouter.of(tester.element(find.byType(Navigator).first)).go('/create?mode=voice');
      await settleFrames(tester);
      expect(currentLocation(tester), '/create');
      expect(container.read(creationDraftProvider).draft!.inspirationSlug, 'birthday_wish');
      expect(find.byType(VoiceCapturePanel), findsNothing);
    });

    testWidgets('dictation in free input: the words are the prompt', (tester) async {
      final env = SongletTestEnv();
      final container = await pumpRoute(tester, '/create?mode=voice', env: env);
      env.speech.session!.add(const SpeechPartial('A song for my sister'));
      await settleFrames(tester);
      expect(find.text('Use as keywords'), findsNothing);
      await tester.tap(find.text('Use this text'));
      await settleFrames(tester);
      expect(container.read(creationDraftProvider).draft!.prompt, 'A song for my sister');
      expect(currentLocation(tester), '/create');
    });

    testWidgets("the video switch follows the card's default under Standard", (tester) async {
      final container = await pumpRoute(tester, '/create?options=1');
      await tapTile(tester, 'soundscape');
      expect(find.byKey(const ValueKey('composer.video')), findsNothing, reason: 'a preview makes no video');
      expect(container.read(creationDraftProvider).draft!.autoVideo, AutoVideo.lyric, reason: 'the occasion rule, kept for Standard');
      container.read(creationDraftProvider.notifier).setModel(SongModel.fullSong);
      await settleFrames(tester);
      expect(
        tester.widget<SwitchListTile>(find.descendant(of: find.byKey(const ValueKey('composer.video')), matching: find.byType(SwitchListTile))).value,
        isTrue,
      );
    });
  });

  group('deep links (the former form) restore state B', () {
    testWidgets('/create/template/<id>: the home, that tile picked and in view, its fields in the composer', (tester) async {
      final container = await pumpRoute(tester, '/create/template/background_music');
      await settleFrames(tester);
      expect(find.byType(CreateHomePage), findsOneWidget);
      expect(currentLocation(tester), '/create', reason: 'the pick is applied once');
      expect(container.read(creationDraftProvider).draft!.inspirationSlug, 'background_music');
      expect(tile('background_music').hitTestable(), findsOneWidget, reason: 'scrolled into view');
      expect(picked(tester, 'background_music'), isTrue);
      expect(fields(), findsOneWidget);
      expect(head(), findsOneWidget);
    });

    testWidgets('?template=<id>&options=1 keeps the options open', (tester) async {
      final container = await pumpRoute(tester, '/create?template=team_anthem&options=1');
      await settleFrames(tester);
      expect(container.read(creationDraftProvider).draft!.inspirationSlug, 'team_anthem');
      expect(currentLocation(tester), '/create?options=1');
      expect(find.byKey(const ValueKey('composer.options')), findsOneWidget);
      expect(fields(), findsOneWidget);
    });

    testWidgets('offline: a template id picks the built-in template; the server entry takes over when the list lands', (tester) async {
      final env = SongletTestEnv()..inspirations.items = const [];
      final container = await pumpRoute(tester, '/create/template/pet_anthem', env: env);
      await settleFrames(tester);
      var draft = container.read(creationDraftProvider).draft!;
      expect(draft.template, SongTemplate.petAnthem);
      expect(draft.inspirationSlug, isNull);
      expect(tile('pet_anthem').hitTestable(), findsOneWidget);
      expect(picked(tester, 'pet_anthem'), isTrue);
      await tester.enterText(nameField(), 'Biscuit');
      await tester.pump();

      env.inspirations.items = [
        ...sampleInspirations(),
        const Inspiration(
          id: 'id-pet_anthem',
          slug: 'pet_anthem',
          name: LocalizedText(en: 'Pet Anthem', zh: '宠物之歌'),
          style: LocalizedText(en: 'Affectionate, bouncy theme for a pet', zh: '亲昵蹦跳的宠物主题曲'),
          previewAudioUrl: 'https://cdn.songlet.example/inspirations/pet_anthem.mp3',
          sort: 14,
          occasionWire: 'confession',
        ),
      ];
      container.invalidate(inspirationsProvider);
      await settleFrames(tester);
      draft = container.read(creationDraftProvider).draft!;
      expect(draft.inspirationSlug, 'pet_anthem');
      expect(draft.recipient, 'Biscuit', reason: 'what was typed survives the swap');
      expect(tester.widget<TextField>(nameField()).controller!.text, 'Biscuit');
    });

    testWidgets('/create/template/custom: free input', (tester) async {
      final container = await pumpRoute(tester, '/create');
      await tapTile(tester, 'birthday_wish');
      GoRouter.of(tester.element(find.byType(Navigator).first)).go('/create/template/custom');
      await settleFrames(tester);
      expect(container.read(creationDraftProvider).draft!.hasPick, isFalse);
      expect(fields(), findsNothing);
      expect(promptField(), findsOneWidget);
    });
  });

  group('what /v1/generate receives (contract 02 v2.1)', () {
    testWidgets('the first session in three decisions: pick, name, press — and the body is right', (tester) async {
      final env = SongletTestEnv();
      final container = await pumpRoute(tester, '/create', env: env);
      await tapTile(tester, 'birthday_wish'); // 1. who it is for
      await tester.enterText(nameField(), 'Alex'); // 2. what to say
      await tester.pump();
      await send(tester); // 3. start
      final request = env.jobs.submitted.single;
      final body = request.toJson();
      expect(body.keys.toSet(), {'model', 'occasion', 'inspiration', 'region', 'prompt', 'client_ref'});
      expect(body['model'], 'lyria-3-clip-preview');
      expect(body['inspiration'], 'birthday_wish', reason: 'the slug, never the id');
      expect(body['occasion'], 'birthday', reason: "the scene's occasion");
      expect(request.prompt.split('\n').first, 'inspiration: birthday_wish');
      expect(promptLines(request), {
        'inspiration': 'birthday_wish',
        'recipient': 'Alex',
        'genre': 'Indie Pop',
        'vocals': 'vocals',
        'lyric_language': 'en',
      });
      expect(currentLocation(tester), '/create/generate');
      await settleFrames(tester);
      expect(tester.takeException(), isNull, reason: 'the ledger and library refresh outside any build');
      final work = (await env.works.all()).single;
      expect(work.inspiration, 'birthday_wish');
      await stopRun(tester, container);
    });

    testWidgets('a card never sends the free prompt left behind', (tester) async {
      final env = SongletTestEnv();
      final container = await pumpRoute(tester, '/create', env: env);
      await tester.enterText(promptField(), 'typed before the pick');
      await tester.pump();
      await tapTile(tester, 'birthday_wish');
      await tester.enterText(nameField(), 'Alex');
      await addKeyword(tester, 'coffee');
      await send(tester);
      final lines = promptLines(env.jobs.submitted.single);
      expect(lines['recipient'], 'Alex');
      expect(lines['keywords'], 'coffee');
      expect(lines.containsKey('description'), isFalse);
      await stopRun(tester, container);
    });

    testWidgets("input_required: 'Your words' are the description", (tester) async {
      final env = SongletTestEnv();
      final container = await pumpRoute(tester, '/create', env: env);
      await tapTile(tester, 'background_music');
      await tester.enterText(wordsField(), 'A cozy cooking vlog');
      await tester.pump();
      await send(tester);
      expect(promptLines(env.jobs.submitted.single)['description'], 'A cozy cooking vlog');
      await stopRun(tester, container);
    });

    testWidgets('input_required false: the card alone — never the style or hint', (tester) async {
      final env = SongletTestEnv();
      final container = await pumpRoute(tester, '/create', env: env);
      await tapTile(tester, 'soundscape');
      await send(tester);
      final request = env.jobs.submitted.single;
      expect(request.inspiration, 'soundscape');
      expect(request.prompt, 'inspiration: soundscape\ngenre: Ambient\nvocals: instrumental\nlyric_language: en');
      await stopRun(tester, container);
    });

    testWidgets('the offline grid: the template id is the scene slug', (tester) async {
      final env = SongletTestEnv()..inspirations.items = const [];
      final container = await pumpRoute(tester, '/create', env: env);
      await tapTile(tester, 'love_story');
      await send(tester);
      final request = env.jobs.submitted.single;
      expect(request.inspiration, 'love_story');
      expect(promptLines(request)['inspiration'], 'love_story');
      expect(request.prompt, isNot(contains('template')));
      await stopRun(tester, container);
    });

    testWidgets('free input: no scene, and the folded name and words are not sent', (tester) async {
      final env = SongletTestEnv();
      final container = await pumpRoute(tester, '/create', env: env);
      await tapTile(tester, 'birthday_wish');
      await tester.enterText(nameField(), 'Alex');
      await tapTile(tester, 'birthday_wish');
      await tester.enterText(promptField(), 'A song for my sister moving to Lisbon');
      await tester.pump();
      await send(tester);
      final request = env.jobs.submitted.single;
      expect(request.inspiration, isNull);
      final lines = promptLines(request);
      expect(lines.containsKey('inspiration'), isFalse);
      expect(lines.containsKey('recipient'), isFalse);
      expect(lines['description'], 'A song for my sister moving to Lisbon');
      expect(request.occasion, 'custom');
      expect(currentLocation(tester), '/create/generate');
      await stopRun(tester, container);
    });

    testWidgets('an unknown scene refetches the list (40001 details.inspiration)', (tester) async {
      final env = SongletTestEnv();
      final container = await pumpRoute(tester, '/create', env: env);
      var fetches = 0;
      container.listen(inspirationsProvider, (_, _) => fetches++);
      env.jobs.submitError = const ValidationApiError(
        code: 40001,
        message: 'validation failed',
        details: {'inspiration': 'unknown inspiration'},
      );
      await tapTile(tester, 'soundscape');
      await send(tester);
      expect(fetches, greaterThan(0));
    });
  });

  group('validation in the composer (P18)', () {
    testWidgets('a picked card never asks for a name or words (§1.3): the card alone is sent', (tester) async {
      final generation = RecordingGeneration();
      final env = SongletTestEnv()..inspirations.items = const [];
      await pumpRoute(tester, '/create', env: env, overrides: [generationControllerProvider.overrideWith(() => generation)]);
      await tapTile(tester, 'birthday_wish');
      await send(tester);
      expect(find.text('Add their name.'), findsNothing);
      expect(generation.generated, hasLength(1));
    });

    testWidgets('an artist in the name: the inline error under it, nothing sent', (tester) async {
      final generation = RecordingGeneration();
      await pumpRoute(tester, '/create', overrides: [generationControllerProvider.overrideWith(() => generation)]);
      await tapTile(tester, 'birthday_wish');
      await tester.enterText(nameField(), 'Taylor Swift style');
      await send(tester);
      expect(find.text('Artist names can’t be used.'), findsOneWidget);
      expect(generation.generated, isEmpty);
    });

    testWidgets('an artist in the three words: the error under them, not in a banner', (tester) async {
      final generation = RecordingGeneration();
      await pumpRoute(tester, '/create', overrides: [generationControllerProvider.overrideWith(() => generation)]);
      await tapTile(tester, 'birthday_wish');
      await addKeyword(tester, 'Beyonce');
      await send(tester);
      expect(generation.generated, isEmpty);
      expect(
        find.descendant(of: find.byType(FormFieldSection), matching: find.text("Artist names can't be used — describe the feeling instead.")),
        findsOneWidget,
      );
    });

    testWidgets('own lyrics need the ownership confirmation; the options open to show it', (tester) async {
      final generation = RecordingGeneration();
      await pumpRoute(tester, '/create?options=1', overrides: [generationControllerProvider.overrideWith(() => generation)]);
      await tapTile(tester, 'birthday_wish');
      await tester.ensureVisible(find.text('Write your own lyrics (optional)'));
      await tester.tap(find.text('Write your own lyrics (optional)'));
      await settleFrames(tester);
      await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('composer.lyrics')), matching: find.byType(TextField)),
        'Coffee in the morning light',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await settleFrames(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('composer.summary')));
      await settleFrames(tester);
      await tester.tap(find.byKey(const ValueKey('composer.summary')));
      await settleFrames(tester);
      expect(find.byKey(const ValueKey('composer.lyrics')), findsNothing, reason: 'folded');
      await send(tester);
      expect(currentLocation(tester), '/create?options=1');
      expect(find.text('Confirm the lyrics are yours to use.'), findsOneWidget);
      expect(generation.generated, isEmpty);
    });

    testWidgets('once the song opens, the Create tab is back on its home, draft kept', (tester) async {
      final generation = RecordingGeneration();
      final env = SongletTestEnv()..addWork(sampleClip());
      final container =
          await pumpRoute(tester, '/create', env: env, overrides: [generationControllerProvider.overrideWith(() => generation)]);
      await tapTile(tester, 'birthday_wish');
      await tester.enterText(nameField(), 'Alex');
      await send(tester);
      expect(generation.generated.single.$1.recipient, 'Alex');
      generation.current = GenerationSucceeded(sampleClip());
      await settleFrames(tester);
      expect(currentLocation(tester), '/library/works/clip-1/preview');
      await tester.tap(find.byKey(const ValueKey('nav.create')));
      await settleFrames(tester);
      expect(currentLocation(tester), '/create');
      expect(container.read(creationDraftProvider).draft!.inspirationSlug, 'birthday_wish');
    });
  });
}
