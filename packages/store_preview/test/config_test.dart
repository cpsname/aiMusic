import 'package:flutter_test/flutter_test.dart';
import 'package:store_preview/store_preview.dart';

import 'support/fixture.dart';

void main() {
  late String pkg;
  late Map<String, DeviceSlot> slots;

  setUpAll(() async {
    pkg = await packageRoot();
    slots = loadSlots(pkg);
  });

  group('defaults', () {
    test('the iPhone slot is Apple\'s 6.9" portrait size, the iPad 13" slot 1200×1600', () {
      expect(slots['iphone']!.width, 886);
      expect(slots['iphone']!.height, 1920);
      expect(slots['ipad']!.width, 1200);
      expect(slots['ipad']!.height, 1600);
      expect(slots['ipad']!.deviceFamily, 2);
    });

    test('encoding targets sit inside Apple\'s ranges', () {
      final e = loadEncoding(pkg);
      expect(e.videoBitrate, inInclusiveRange(10000000, 12000000));
      expect(e.fps, lessThanOrEqualTo(30));
      expect(e.audioBitrate, 256000);
      expect({44100, 48000}, contains(e.sampleRate));
      expect(e.channels, 2);
    });
  });

  group('app.yaml', () {
    test('loads storefronts, brand, driver, backend and rules', () {
      final repo = FixtureRepo.create();
      addTearDown(repo.delete);
      final app = PreviewApp.load(root: repo.root, id: 'demo', slots: slots);
      expect(app.storefronts.map((s) => s.id), ['en-US', 'ja']);
      expect(app.storefront('ja').isCjk, isTrue);
      expect(app.captions.arbName('pt-BR'), 'app_pt_BR.arb');
      expect(app.brand.disclosureKey, 'storePreviewDisclosure');
      expect(app.backend!.fill(app.backend!.start, manifest: '/m.json'), contains('--port 8799 --manifest /m.json'));
      expect(app.rules.minFootageRatio, 0.85);
      expect(app.publish.sharedPosterAt, 8);
      expect(app.slots.keys, ['iphone']);
    });

    test('rejects unknown keys, a missing disclosure and loosened rules', () {
      void fails(String yaml, Matcher message) {
        final repo = FixtureRepo.create(appYaml: yaml);
        addTearDown(repo.delete);
        expect(
          () => PreviewApp.load(root: repo.root, id: 'demo', slots: slots),
          throwsA(isA<ConfigError>().having((e) => e.message, 'message', message)),
        );
      }

      fails('$fixtureAppYaml\ncolour: red\n', contains('unknown key(s) colour'));
      fails(fixtureAppYaml.replaceFirst('  disclosure_key: storePreviewDisclosure\n', ''), contains('disclosure_key: required'));
      fails('$fixtureAppYaml\nrules: {min_footage_ratio: 0.6}\n', contains('may only be raised'));
      fails('$fixtureAppYaml\nrules: {max_cards_total: 6}\n', contains('at most 4.0'));
      fails(fixtureAppYaml.replaceFirst('devices: [iphone]', 'devices: [watch]'), contains('unknown slot "watch"'));
      fails(fixtureAppYaml.replaceFirst('#D9482B', 'red'), contains('not #RRGGBB'));
    });
  });

  group('served localizations (ADR-0017)', () {
    String serving(String serves, {String? ja}) {
      var yaml = fixtureAppYaml.replaceFirst('vars: {region: US}}', 'vars: {region: US}, serves: $serves}');
      if (ja != null) yaml = yaml.replaceFirst('vars: {region: JP}}', 'vars: {region: JP}, serves: $ja}');
      return yaml;
    }

    test('a storefront serves other localizations; the app ships media for all of them', () {
      final repo = FixtureRepo.create(appYaml: serving('[en-GB, en-AU]'));
      addTearDown(repo.delete);
      final app = PreviewApp.load(root: repo.root, id: 'demo', slots: slots);
      expect(app.storefront('en-US').serves, ['en-GB', 'en-AU']);
      expect(app.storefront('en-US').locales, ['en-US', 'en-GB', 'en-AU']);
      expect(app.storefront('ja').serves, isEmpty);
      expect(app.ascLocales, ['en-US', 'en-GB', 'en-AU', 'ja']);
      expect(app.storefronts.map((s) => s.id), ['en-US', 'ja'], reason: 'a served localization is not a storefront: nothing is recorded for it');
    });

    test('a served localization is not a storefront, itself, or served twice', () {
      void fails(String yaml, Matcher message) {
        final repo = FixtureRepo.create(appYaml: yaml);
        addTearDown(repo.delete);
        expect(
          () => PreviewApp.load(root: repo.root, id: 'demo', slots: slots),
          throwsA(isA<ConfigError>().having((e) => e.message, 'message', message)),
        );
      }

      fails(serving('[ja]'), contains('en-US › serves: ja is a storefront of its own'));
      fails(serving('[en-US]'), contains('serves: en-US is the storefront itself'));
      fails(serving('[en-GB, en-GB]'), contains('serves: duplicate locale'));
      fails(serving('[en-GB]', ja: '[en-GB]'), contains('ja › serves: en-GB is already served by en-US'));
    });
  });

  group('scripts', () {
    test('lays the segments out back to back and orders filming', () {
      final repo = FixtureRepo.create();
      addTearDown(repo.delete);
      final s = loadScripts(repo.path('store_preview/demo/scripts'))['A']!;
      expect(s.duration, closeTo(15, 1e-9));
      expect(s.segments.map((x) => x.start), [0, 0.8, closeTo(4.3, 1e-9), closeTo(5.5, 1e-9), closeTo(11.0, 1e-9), closeTo(13.6, 1e-9)]);
      expect(s.cards.map((c) => c.kind), ['intro', 'outro']);
      expect(s.shootingOrder.map((x) => x.id), ['name', 'wait', 'player', 'share']);
      expect(s.mediaRefs.map((r) => r.role), ['photo', 'song']);
      expect(checkScriptStructure(s, captionPrefix: 'storePreview').items, isEmpty);
    });

    test('a scene may be filmed before an earlier one', () {
      final repo = FixtureRepo.create(
        scripts: {'A': fixtureScriptA.replaceFirst('    beat: share\n', '    beat: share\n    shoot_order: -1\n')},
      );
      addTearDown(repo.delete);
      final s = loadScripts(repo.path('store_preview/demo/scripts'))['A']!;
      expect(s.shootingOrder.map((x) => x.id), ['share', 'name', 'wait', 'player']);
    });

    test('structure: one intro and one outro around the footage, captions clear of the cards', () {
      final repo = FixtureRepo.create(
        scripts: {
          'A': fixtureScriptA
              .replaceFirst('{key: storePreviewAHook, from: 0.8,', '{key: storePreviewAHook, from: 0.5,')
              .replaceFirst('    text: storePreviewAIntro\n', ''),
        },
      );
      addTearDown(repo.delete);
      final problems = checkScriptStructure(loadScripts(repo.path('store_preview/demo/scripts'))['A']!, captionPrefix: 'storePreview');
      expect(problems.items, contains(contains('intro card states the claim')));
      expect(problems.items, contains(contains('overlaps the intro card')));
    });

    test('a follow scene runs in real time and names its audio', () {
      final repo = FixtureRepo.create(scripts: {'A': fixtureScriptA.replaceFirst('    audio: {role: song}\n', '    retime: true\n')});
      addTearDown(repo.delete);
      final problems = checkScriptStructure(loadScripts(repo.path('store_preview/demo/scripts'))['A']!, captionPrefix: 'storePreview');
      expect(problems.items, contains(contains('runs in real time')));
      expect(problems.items, contains(contains('names no audio')));
    });
  });

  group('manifest', () {
    late FixtureRepo repo;
    late PreviewApp app;
    late Map<String, PreviewScript> scripts;

    setUp(() {
      repo = FixtureRepo.create();
      app = PreviewApp.load(root: repo.root, id: 'demo', slots: slots);
      scripts = loadScripts(app.scriptsDir);
    });
    tearDown(() => repo.delete());

    test('a complete, licensed manifest passes', () {
      repo.manifest(completeManifest());
      final problems = validateManifest(Manifest.load(app.manifestPath), app, scripts, prober: const FakeProber());
      expect(problems.items, isEmpty);
    });

    test('schema 1 or a missing file stops everything', () {
      expect(() => Manifest.load(app.manifestPath), throwsA(isA<ConfigError>()));
      repo.write('store_preview/demo/media/manifest.json', '{"entries": []}');
      expect(() => Manifest.load(app.manifestPath), throwsA(isA<ConfigError>().having((e) => e.message, 'm', contains('"schema": 2'))));
    });

    test('an empty license id, a missing var, a short count and an archived script fail', () {
      final entries = completeManifest();
      entries[0] = entry(id: 'song.A.en-US', type: 'audio', role: 'song', locale: 'en-US', licenseId: ' ');
      entries.removeAt(2);
      entries.add(entry(id: 'song.C.ja', type: 'audio', role: 'song', locale: 'ja', script: 'C'));
      repo.manifest(entries);
      final items = validateManifest(Manifest.load(app.manifestPath), app, scripts, prober: const FakeProber()).items;
      expect(items, contains(contains('license.id is empty')));
      expect(items, contains(contains('vars.recipient is missing')));
      expect(items, contains(contains('needs 2 photo for A/en-US, the manifest holds 1')));
      expect(items, contains(contains('script C is not an active script')));
    });

    test('resolves a reference by role, script, storefront and index', () {
      repo.manifest(completeManifest());
      final m = Manifest.load(app.manifestPath);
      expect(m.resolve(const MediaRef(role: 'photo', index: 1), script: 'A', storefront: 'ja').id, 'photo.A.ja.2');
      expect(
        () => m.resolve(const MediaRef(role: 'photo', index: 2), script: 'A', storefront: 'ja'),
        throwsA(isA<ConfigError>()),
      );
    });
  });

  group('captions', () {
    late FixtureRepo repo;
    late PreviewApp app;
    late Map<String, PreviewScript> scripts;

    setUp(() {
      repo = FixtureRepo.create();
      app = PreviewApp.load(root: repo.root, id: 'demo', slots: slots);
      scripts = loadScripts(app.scriptsDir);
    });
    tearDown(() => repo.delete());

    Map<String, Map<String, String>> texts() => {for (final s in app.storefronts) s.id: captionsFromArb(repo.root, app, s)};

    test('reads every prefix key of each storefront\'s ARB and passes the fixture', () {
      final t = texts();
      expect(t['ja']!['storePreviewAHook'], '名前から始めよう');
      expect(t['en-US']!.containsKey('title'), isFalse);
      expect(checkCaptions(t, app, scripts.values).items, isEmpty);
    });

    test('length, "free" in any language, prices, dates and banned app names fail', () {
      final t = texts();
      t['en-US']!['storePreviewAHook'] = 'Start with their name, it is free to try';
      t['en-US']!['storePreviewAWait'] = r'Only $4.99';
      t['en-US']!['storePreviewAShare'] = 'New for 2026';
      t['ja']!['storePreviewAWait'] = '無料で作曲';
      t['ja']!['storePreviewAShare'] = 'rivalapp より速い';
      t['ja']!['storePreviewAResult'] = 'サビで名前を歌う、とても長い字幕です';
      final items = checkCaptions(t, app, scripts.values).items;
      expect(items, contains(contains('is 40 characters (≤ 28)')));
      expect(items, contains(contains('contains "free"')));
      expect(items, contains(contains('looks like a price')));
      expect(items, contains(contains('date or seasonal reference')));
      expect(items, contains(contains('contains "無料"')));
      expect(items, contains(contains('contains "rivalapp"')));
      expect(items, contains(contains('(≤ 14)')));
    });

    test('the disclosure has its own budget; a missing key names its ARB', () {
      final t = texts();
      t['en-US']!['storePreviewDisclosure'] = 'Requires a subscription or credits to make full songs';
      t['ja']!.remove('storePreviewCta');
      final items = checkCaptions(t, app, scripts.values).items;
      expect(items.where((i) => i.contains('storePreviewDisclosure')), isEmpty);
      expect(items, contains(contains('storePreviewCta is missing (add it to app_ja.arb)')));
    });

    test('SubRip lists cues in time order', () {
      final out = srt([(from: 4.3, to: 5.5, text: 'b'), (from: 0, to: 0.8, text: 'a')]);
      expect(out, '1\n00:00:00,000 --> 00:00:00,800\na\n\n2\n00:00:04,300 --> 00:00:05,500\nb\n\n');
    });
  });
}
