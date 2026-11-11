import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:store_preview/store_preview.dart';

import 'support/fixture.dart';

void main() {
  late Map<String, DeviceSlot> slots;
  late Map<String, NarrativeTemplate> templates;
  late FixtureRepo repo;
  late PreviewApp app;

  setUpAll(() async {
    final pkg = await packageRoot();
    slots = loadSlots(pkg);
    templates = loadTemplates(pkg);
  });
  setUp(() {
    repo = FixtureRepo.create();
    app = PreviewApp.load(root: repo.root, id: 'demo', slots: slots);
  });
  tearDown(() => repo.delete());

  PreviewScript script([String yaml = fixtureScriptA]) {
    repo.write('store_preview/demo/scripts/A.yaml', yaml);
    return loadScripts(app.scriptsDir)['A']!;
  }

  /// The fixture's rendered EDL: intro 0–0.8 on an image, footage to 13.6
  /// (player finished 5.5–11.0), outro with the disclosure.
  Edl edl({
    double introEnd = 0.8,
    String disclosure = 'Requires a subscription or credits',
    String transition = 'dissolve',
    double scale = 0.67,
    String license = 'gen-1',
    double captionFrom = 0.8,
    double captionTo = 4.3,
  }) => Edl(
    app: 'demo',
    script: 'A',
    storefront: 'en-US',
    slot: 'iphone',
    duration: 15,
    posterAt: 8,
    footageScale: scale,
    segments: [
      EdlSegment(kind: 'card', id: 'intro', beat: 'intro', from: 0, to: introEnd, detail: const {'card': 'intro', 'background': 'image'}),
      EdlSegment(kind: 'footage', id: 'name', beat: 'input', from: introEnd, to: 5.5),
      const EdlSegment(kind: 'footage', id: 'player', beat: 'result', from: 5.5, to: 11.0, detail: {'finished': true}),
      const EdlSegment(kind: 'footage', id: 'share', beat: 'share', from: 11.0, to: 13.6),
      const EdlSegment(kind: 'card', id: 'outro', beat: 'outro', from: 13.6, to: 15, detail: {'card': 'outro', 'background': 'color'}),
    ],
    transitions: [EdlTransition(at: introEnd, type: transition, duration: 0.25, between: 'intro→name')],
    texts: [
      EdlText(source: 'claim', key: 'storePreviewAIntro', text: 'A song with their name', from: 0, to: introEnd),
      EdlText(source: 'caption', key: 'storePreviewAHook', text: 'Start with their name', from: captionFrom, to: captionTo),
      const EdlText(source: 'brand', key: 'brand.name', text: 'Demo', from: 13.6, to: 15),
      if (disclosure.isNotEmpty) EdlText(source: 'disclosure', key: 'storePreviewDisclosure', text: disclosure, from: 13.6, to: 15),
    ],
    media: [EdlMedia(id: 'photo.A.en-US.1', role: 'photo', use: 'card', license: {'id': license})],
  );

  group('compliance', () {
    test('the fixture passes', () {
      expect(checkCompliance(edl(), app).items, isEmpty);
      expect(checkScriptCompliance(script(), app).items, isEmpty);
    });

    test('too little footage, a long card, a wipe, enlarged footage, an unlicensed image fail', () {
      final items = checkCompliance(edl(introEnd: 2.4, transition: 'wipe', scale: 1.2, license: ''), app).items;
      expect(items, contains(contains('app footage is 74.7 %')));
      expect(items, contains(contains('card intro lasts 2.4s')));
      expect(items, contains(contains('is a wipe')));
      expect(items, contains(contains('enlarged')));
      expect(items, contains(contains('without a license id')));
    });

    test('a missing disclosure and a price on screen fail', () {
      final items = checkCompliance(edl(disclosure: ''), app).items;
      expect(items, contains(contains('does not disclose the purchase')));
      final priced = checkCompliance(edl(disclosure: r'Only $4.99 a week'), app).items;
      expect(priced, contains(contains('looks like a price')));
    });

    test('the script is checked before anything is filmed', () {
      final s = script(fixtureScriptA.replaceFirst('    duration: 0.8\n', '    duration: 2.1\n').replaceFirst('    duration: 3.5\n', '    duration: 2.2\n'));
      final items = checkScriptCompliance(s, app).items;
      expect(items, contains(contains('the intro card lasts 2.1s')));
      expect(items, contains(contains('app footage is 76.7 %')));
    });
  });

  group('narrative on the output', () {
    test('the fixture passes', () {
      expect(checkNarrativeOutput(edl(), app).items, isEmpty);
    });

    test('a gap in the muted hook, a short caption, a poster off the result fail', () {
      final gap = checkNarrativeOutput(edl(captionFrom: 1.5, captionTo: 2.4), app).items;
      expect(gap, contains(contains('covers 0–0.80s')));
      expect(gap, contains(contains('on screen 0.90s')));
      final poster = Edl.fromJson({...edl().toJson(), 'poster_at': 12.0});
      expect(checkNarrativeOutput(poster, app).items, contains(contains('poster_at 12.0s')));
    });
  });

  group('narrative on the script', () {
    test('the fixture plays its template\'s 15 s rhythm', () {
      final texts = {for (final s in app.storefronts) s.id: captionsFromArb(repo.root, app, s)};
      expect(checkNarrative(script(), app, templates, texts: texts).items, isEmpty);
    });

    test('a beat out of order, outside its rhythm or played by the wrong kind fails', () {
      final items = checkNarrative(
        script(fixtureScriptA.replaceFirst('    beat: wait\n', '    beat: share\n').replaceFirst('    beat: share\n    duration: 2.6', '    beat: wait\n    duration: 2.6')),
        app,
        templates,
      ).items;
      expect(items, contains(contains('beat result comes after share')));
    });

    test('a rhythm the template lacks, a missing required beat and a stretched beat fail', () {
      expect(
        checkNarrative(script(fixtureScriptA.replaceFirst('rhythm: 15', 'rhythm: 20')), app, templates).items,
        contains(contains('has no 20 s rhythm')),
      );
      final items = checkNarrative(
        script(fixtureScriptA
            .replaceFirst('    beat: result\n    duration: 5.5', '    beat: share\n    duration: 5.5')
            .replaceFirst('    finished: true\n', '')),
        app,
        templates,
      ).items;
      expect(items, contains(contains('required beat result')));
      expect(items, contains(contains('beat share lasts 8.1s')));
      expect(items, contains(contains('no scene shows the finished product')));
    });

    test('reading speed is checked per storefront', () {
      final texts = {
        'en-US': {...fixtureTexts('en'), 'storePreviewAWait': 'Writing it, writing it, writing!'},
        'ja': fixtureTexts('ja'),
      };
      expect(checkNarrative(script(), app, templates, texts: texts).items, contains(contains('reads at 20.0 characters/s (≤ 17.0)')));
    });

    test('no image transition fails where the app requires one', () {
      final items = checkNarrative(script(fixtureScriptA.replaceFirst('    background: {image: {role: photo, index: 0}}\n', '')), app, templates).items;
      expect(items, contains(contains('no image transition')));
    });

    test('the shared poster frame must be on the result in every script', () {
      repo.write('store_preview/demo/app.yaml', fixtureAppYaml.replaceFirst('shared_poster_at: 8', 'shared_poster_at: 12'));
      final shared = PreviewApp.load(root: repo.root, id: 'demo', slots: slots);
      expect(checkNarrative(script(), shared, templates).items, contains(contains('shared poster frame 12.0s')));
    });
  });

  group('secrets', () {
    test('credentials in configuration or logs are found; license ids are not', () {
      repo.write('store_preview/demo/scripts/B.yaml', 'body: {api_key: "abcdef0123456789xyz"}\n');
      repo.write('logs/take.log', 'token AKIAABCDEFGHIJKLMNOP\n');
      repo.write('logs/manifest.json', '{"license": {"id": "v1_ChdCR2JEYXZuUkJyTHJ6N0lQdDR5OG9RbxIX"}}');
      final items = scanForSecrets([repo.path('store_preview/demo/scripts'), repo.path('logs')]).items;
      expect(items, hasLength(2));
      expect(items, contains(contains('B.yaml:1 holds a secret-named value')));
      expect(items, contains(contains('take.log:1 holds an AWS access key')));
      File(repo.path('store_preview/demo/scripts/B.yaml')).deleteSync();
    });
  });
}
