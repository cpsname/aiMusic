import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/music_harness.dart';

/// The create home's single grid (ADR-0032): the server's list by `sort`,
/// every tile a photo; the 16 built-in templates only while the list is not
/// loaded.
void main() {
  setUp(mockNativeChannels);

  Finder tile(String slug) => find.byKey(ValueKey('tile.$slug'));

  /// Scrolls the grid from the top until the tile is built, then onto the
  /// screen (the grid builds only what is near the viewport).
  Future<void> show(WidgetTester tester, String slug) async {
    final page =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position
          ..jumpTo(0);
    await tester.pump();
    while (tile(slug).evaluate().isEmpty &&
        page.pixels < page.maxScrollExtent) {
      page.jumpTo((page.pixels + 200).clamp(0, page.maxScrollExtent));
      await tester.pump();
    }
    await tester.ensureVisible(tile(slug));
    await settleFrames(tester);
  }

  TemplateTile widgetOf(WidgetTester tester, String slug) =>
      tester.widget<TemplateTile>(
        find.descendant(of: tile(slug), matching: find.byType(TemplateTile)),
      );

  testWidgets(
    'one grid under one heading: the server list alone, in sort order',
    (tester) async {
      final container = await pumpRoute(tester, '/create');
      expect(find.text('Inspiration'), findsOneWidget);
      expect(find.byType(SliverGrid), findsOneWidget, reason: 'one grid');
      expect(container.read(ideasProvider).map((i) => i.slug), [
        'birthday_wish',
        'love_story',
        'festival',
        'team_anthem',
        'soundscape',
        'background_music',
        'say_it_with_a_track',
        'weather_report',
      ]);
      expect(
        container.read(ideasProvider).every((i) => i.template == null),
        isTrue,
        reason: 'no client-side merge',
      );
      expect(find.text('Birthday Wish'), findsOneWidget);
      await show(tester, 'weather_report');
      expect(find.text('Weather Report'), findsOneWidget);
    },
  );

  testWidgets(
    'no server list (offline, an older server): the 16 templates, still under the heading',
    (tester) async {
      final env = SongletTestEnv()..inspirations.items = const [];
      final container = await pumpRoute(tester, '/create', env: env);
      expect(find.text('Inspiration'), findsOneWidget);
      for (final t in SongTemplate.values) {
        await show(tester, t.id);
        expect(tile(t.id), findsOneWidget, reason: t.id);
      }
      expect(
        container.read(ideasProvider),
        hasLength(SongTemplate.values.length),
      );
    },
  );

  group('every tile is a photo', () {
    testWidgets(
      'the server cover first; it falls back to the template\'s photo, else the occasion\'s',
      (tester) async {
        await pumpRoute(tester, '/create');
        await show(tester, 'team_anthem');
        final anthem = widgetOf(tester, 'team_anthem');
        expect(
          (anthem.image! as NetworkImage).url,
          'https://cdn.songlet.example/covers/team_anthem.jpg',
        );
        expect(
          (anthem.fallbackImage! as AssetImage).assetName,
          'assets/templates/team_anthem.jpg',
        );
        await show(tester, 'say_it_with_a_track');
        final track = widgetOf(tester, 'say_it_with_a_track');
        expect(
          (track.fallbackImage! as AssetImage).assetName,
          'assets/occasions/confession.jpg',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'an unreachable cover is silent',
        );
      },
    );

    testWidgets(
      'no cover: the template\'s bundled photo, else the occasion\'s; never an icon on a gradient',
      (tester) async {
        await pumpRoute(tester, '/create');
        expect(
          (widgetOf(tester, 'birthday_wish').image! as AssetImage).assetName,
          'assets/templates/birthday_wish.jpg',
        );
        await show(tester, 'weather_report');
        expect(widgetOf(tester, 'weather_report').image, isNotNull);
        expect(
          find.descendant(
            of: tile('weather_report'),
            matching: find.byIcon(Icons.cloud_rounded),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('an unknown slug still gets a photo', (tester) async {
      final env = SongletTestEnv();
      env.inspirations.items = [
        ...sampleInspirations(),
        const Inspiration(
          id: 'id-new',
          slug: 'new_thing',
          name: LocalizedText(en: 'Brand New Idea', zh: '新点子'),
          style: LocalizedText(en: 'Something fresh', zh: '新鲜的东西'),
          previewAudioUrl: 'https://cdn.songlet.example/new.mp3',
          sort: 99,
        ),
      ];
      await pumpRoute(tester, '/create', env: env);
      await show(tester, 'new_thing');
      expect(
        (widgetOf(tester, 'new_thing').image! as AssetImage).assetName,
        'assets/occasions/festival.jpg',
      );
    });
  });

  group('copy per language', () {
    Future<void> openIn(
      WidgetTester tester,
      Locale locale, {
      List<Inspiration>? items,
    }) async {
      final env = SongletTestEnv();
      if (items != null) env.inspirations.items = items;
      await pumpRoute(tester, '/create', env: env, locale: locale);
    }

    testWidgets(
      'Simplified Chinese: the server text, and the style for assistive technology',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await openIn(
          tester,
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        );
        expect(find.text('灵感'), findsOneWidget);
        await show(tester, 'soundscape');
        expect(find.text('环境音景'), findsOneWidget);
        expect(find.bySemanticsLabel('环境音景, 氛围音色，纯音乐'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets(
      'Traditional Chinese: the local translation, not the Simplified text',
      (tester) async {
        await openIn(
          tester,
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        );
        await show(tester, 'soundscape');
        expect(find.text('環境音景'), findsOneWidget);
      },
    );

    testWidgets(
      'German: mapped by the English text (template entries by their own name); unknown stays English',
      (tester) async {
        const unknown = Inspiration(
          id: 'id-new',
          slug: 'new_thing',
          name: LocalizedText(en: 'Brand New Idea', zh: '新点子'),
          style: LocalizedText(en: 'Something fresh', zh: '新鲜的东西'),
          previewAudioUrl: 'https://cdn.songlet.example/new.mp3',
          sort: 99,
        );
        await openIn(
          tester,
          const Locale('de'),
          items: [...sampleInspirations(), unknown],
        );
        expect(
          find.text('Geburtstagsgruß'),
          findsOneWidget,
          reason: 'the template\'s own German name',
        );
        await show(tester, 'new_thing');
        expect(find.text('Brand New Idea'), findsOneWidget);
        await show(tester, 'soundscape');
        expect(find.text('Klangwelt'), findsOneWidget);
      },
    );
  });

  group('play', () {
    testWidgets(
      'the button plays preview_audio_url from its own host; again stops it',
      (tester) async {
        final env = SongletTestEnv()..samples = MissingSamples();
        final container = await pumpRoute(tester, '/create', env: env);
        await show(tester, 'soundscape');
        final play = find.descendant(
          of: tile('soundscape'),
          matching: find.byIcon(Icons.play_arrow_rounded),
        );
        await tester.tap(play);
        await settleFrames(tester);
        expect(env.inspirations.previews, [
          'https://cdn.songlet.example/inspirations/soundscape.mp3',
        ]);
        expect(
          (env.samples as MissingSamples).requested,
          isEmpty,
          reason: 'the preview only',
        );
        expect(
          container.read(templateSampleProvider),
          'inspiration:id-soundscape',
        );
        final stop = find.descendant(
          of: tile('soundscape'),
          matching: find.byIcon(Icons.pause_rounded),
        );
        await tester.tap(stop);
        await settleFrames(tester);
        expect(container.read(templateSampleProvider), isNull);
      },
    );

    testWidgets(
      'a preview that fails reads as a plain error, not a connection problem',
      (tester) async {
        final env = SongletTestEnv();
        env.inspirations.failing = true;
        final container = await pumpRoute(tester, '/create', env: env);
        await tester.tap(
          find.descendant(
            of: tile('birthday_wish'),
            matching: find.byIcon(Icons.play_arrow_rounded),
          ),
        );
        await settleFrames(tester);
        expect(container.read(templateSampleProvider), isNull);
        expect(find.text('Something went wrong.'), findsOneWidget);
        expect(find.textContaining('Network error'), findsNothing);
      },
    );

    testWidgets('offline grid: a template plays its own sample', (
      tester,
    ) async {
      final env = SongletTestEnv()..inspirations.items = const [];
      final container = await pumpRoute(tester, '/create', env: env);
      await tester.tap(
        find.descendant(
          of: tile('love_story'),
          matching: find.byIcon(Icons.play_arrow_rounded),
        ),
      );
      await settleFrames(tester);
      expect((env.samples as NoSamples).requested, ['love_story']);
      expect(container.read(templateSampleProvider), 'love_story');
    });
  });

  testWidgets('accessibility text sizes: one full-width tile per row', (
    tester,
  ) async {
    await pumpRoute(
      tester,
      '/create',
      textScale: TextScale.largestAccessibility,
    );
    await show(tester, 'soundscape');
    expect(tester.getSize(tile('soundscape')).width, greaterThan(300));
    expect(tester.takeException(), isNull);
  });
}
