import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';

import 'support/creative_fixture.dart';
import 'support/fixture.dart';

/// The creative assets' configuration and contract, without rendering: the
/// assets-manifest contract read from ascpub (never a copy) and held to the
/// app's pin, ascpub's own example and negative cases, ascpub's listing pages
/// against the definitions, layouts an app may only tighten, App Store
/// Connect locales, the muted opening, the screenshot majority, and reviews
/// that go stale.
void main() {
  late String pkg;
  late String ascpub;
  setUpAll(() async {
    pkg = await packageRoot();
    ascpub = testAscpubRoot(pkg);
  });

  Object? clone(Object? v) => jsonDecode(jsonEncode(v));

  group('the contract is ascpub\'s', () {
    test('read from the checkout and held to the pin', () {
      final contract = ManifestContract.load(ascpub, pinnedSha256: contractSha(ascpub));
      expect(contract.version, 1);
      expect(contract.root, ascpub);
      expect(contract.types, containsAll(['header_image', 'header_video', 'search_image', 'search_video', 'screenshot']));
      expect(contract.authorizationFields, ['interaction_id', 'mv_id', 'generation_id']);
      expect(contract.targetPattern.hasMatch('custom_product_page:birthday'), isTrue);
      expect(contract.targetPattern.hasMatch('cpp birthday'), isFalse);
      expect(contract.describe(), startsWith('ascpub '));
    });

    test('a moved contract stops the tool until the pin moves', () {
      expect(
        () => ManifestContract.load(ascpub, pinnedSha256: '0' * 64),
        throwsA(isA<ConfigError>().having((e) => e.message, 'message', contains('the contract changed'))),
      );
      expect(
        () => ManifestContract.load(p.join(ascpub, 'nowhere'), pinnedSha256: contractSha(ascpub)),
        throwsA(isA<ConfigError>().having((e) => e.message, 'message', contains(ascpubRootVariable))),
      );
    });

    test('ASCPUB_ROOT overrides the app\'s root', () {
      const config = AscpubConfig(root: '../../Tools/ASOShip', schemaSha256: '');
      expect(ascpubRoot('/repo/app', config, environment: const {}), '/Tools/ASOShip');
      expect(ascpubRoot('/work/repo', config, environment: const {ascpubRootVariable: '/ci/ascpub'}), '/ci/ascpub');
    });

    test('the package carries no copy of it', () {
      expect(Directory(p.join(pkg, 'contracts')).existsSync(), isFalse);
      final copies = Directory(pkg)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => !f.path.contains('${p.separator}.dart_tool${p.separator}') && p.basename(f.path) == contractSchemaFile);
      expect(copies, isEmpty);
    });

    group('ascpub\'s own cases, on this side', () {
      late ManifestContract contract;
      late Map<String, Object?> example;
      setUp(() {
        contract = ManifestContract.load(ascpub, pinnedSha256: contractSha(ascpub));
        example = (contract.example()! as Map).cast<String, Object?>();
      });

      test('its example passes', () => expect(contract.violations(example), isEmpty));

      // The same mutations as ascpub's src/schema/assets-manifest.test.ts:
      // what ascpub refuses, this tool refuses before writing.
      final negatives = <String, void Function(Map<String, dynamic>)>{
        'unknown version': (d) => d['schema'] = 2,
        'bytes as a string': (d) => d['entries'][0]['bytes'] = '123',
        'unknown top-level field': (d) => d['entires'] = <Object?>[],
        'unknown entry field': (d) => d['entries'][0]['sha'] = 'x',
        'sha256 not 64 lower-case hex': (d) => d['entries'][0]['sha256'] = 'ABC',
        'an absolute path': (d) => d['entries'][0]['file'] = '/etc/passwd',
        'a .. traversal': (d) => d['entries'][0]['file'] = 'a/../../b.png',
        'an image without has_alpha': (d) => (d['entries'][0] as Map).remove('has_alpha'),
        'a video without video': (d) => (d['entries'][1] as Map).remove('video'),
        'an image with video': (d) => d['entries'][0]['video'] = clone(d['entries'][1]['video']),
        'a video with an image mime': (d) => d['entries'][1]['mime'] = 'image/png',
        'generated without generation_id': (d) => d['entries'][2]['authorization']['generation_id'] = null,
        'an unknown type': (d) => d['entries'][0]['type'] = 'banner',
        'a malformed target': (d) => d['entries'][0]['placement_intents'][0]['target'] = 'cpp birthday',
        'no entries': (d) => d['entries'] = <Object?>[],
        'generated_at without a zone': (d) => d['generated_at'] = '2026-10-08T07:00:00',
      };
      for (final MapEntry(key: name, value: mutate) in negatives.entries) {
        test('refuses: $name', () {
          final d = clone(example)! as Map<String, dynamic>;
          mutate(d);
          expect(contract.violations(d), isNotEmpty);
        });
      }
    });
  });

  group('ascpub\'s listing', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('listing'));
    tearDown(() => dir.deleteSync(recursive: true));

    void write(String path, String text) => (File(p.join(dir.path, path))..createSync(recursive: true)).writeAsStringSync(text);

    test('targets address its pages; every bound id is made for that page and slot', () {
      write('assets.yaml', 'schema: 1\nstore_page:\n  header: {default: header.universal, locales: {}}\n  search_results: {default: "", locales: {}}\n');
      write(
        'cpp/birthday.yaml',
        'schema: 1\nname: Birthday\ndeep_link: "app://x"\nheader: {default: cpp.birthday.header, locales: {ja: cpp.birthday.header.ja}}\nsearch_results: {default: cpp.birthday.search}\n',
      );
      final listing = AscpubListing.load(dir.path);
      expect(listing.pages.keys, ['app_store_version', 'custom_product_page:birthday']);
      final made = <String, ({Set<String> targets, Set<String> placements})>{
        'header.universal': (targets: {'app_store_version'}, placements: {'product_page_header', 'app_store_search_results'}),
        'cpp.birthday.header': (targets: {'custom_product_page:birthday'}, placements: {'product_page_header'}),
        'cpp.birthday.header.ja': (targets: {'custom_product_page:birthday'}, placements: {'product_page_header'}),
        'cpp.birthday.search': (targets: {'custom_product_page:birthday'}, placements: {'app_store_search_results'}),
      };
      expect(checkListing(listing, made, targets: {'app_store_version', 'custom_product_page:birthday'}), isEmpty);

      expect(checkListing(listing, made, targets: {'custom_product_page:wedding'}), [
        contains('declares no such page'),
      ], reason: 'a page is ascpub\'s to create');
      final missing = {...made}..remove('cpp.birthday.header.ja');
      expect(checkListing(listing, missing, targets: {'custom_product_page:birthday'}), [
        contains('header.locales.ja binds cpp.birthday.header.ja, which no creative definition makes'),
      ]);
      final wrongSlot = {
        ...made,
        'cpp.birthday.search': (targets: {'custom_product_page:birthday'}, placements: {'product_page_header'}),
      };
      expect(checkListing(listing, wrongSlot, targets: {'custom_product_page:birthday'}), [
        contains('not custom_product_page:birthday (app_store_search_results)'),
      ]);
    });

    test('no assets.yaml: not a listing', () {
      expect(() => AscpubListing.load(dir.path), throwsA(isA<ConfigError>()));
    });
  });

  group('the configuration', () {
    late FixtureRepo repo;
    tearDown(() => repo.delete());

    List<String> problems(Project project) => project.checkConfig(texts: project.textsFromArb(), withManifest: false).items;

    test('the fixture passes', () {
      repo = creativeRepo(pkg);
      expect(problems(Project.load(root: repo.root, appId: 'demo', packageRoot: pkg)), isEmpty);
    });

    test('a custom product page target needs ascpub\'s listing, and the page there', () {
      const cpp = '''
id: page
title: Birthday Songs
targets: ["custom_product_page:birthday"]
universal_from: en-US
backdrop: {role: photo, script: A, index: 0}
text: storeCreativeHeader
slots:
  - placements: [product_page_header]
    spec: header_21x9
    assets:
      - {id: cpp.birthday.header, type: image, frame: {script: A, scene: player, at: 1.0}}
''';
      repo = creativeRepo(pkg, creative: cpp);
      expect(problems(Project.load(root: repo.root, appId: 'demo', packageRoot: pkg)), contains(contains('creatives.ascpub.listing')));
      repo.delete();

      repo = creativeRepo(pkg, creative: cpp, listing: 'listings/demo');
      repo.write('listings/demo/assets.yaml', 'schema: 1\n');
      expect(problems(Project.load(root: repo.root, appId: 'demo', packageRoot: pkg)), contains(contains('declares no such page')));
      repo.write(
        'listings/demo/cpp/birthday.yaml',
        'schema: 1\nname: B\nheader: {default: cpp.birthday.header}\nsearch_results: {default: cpp.birthday.search}\n',
      );
      expect(problems(Project.load(root: repo.root, appId: 'demo', packageRoot: pkg)), [
        contains('binds cpp.birthday.search, which no creative definition makes'),
      ]);
    });

    test('a layout is only tightened', () {
      repo = creativeRepo(pkg, layouts: '  layouts:\n    "21:9": {safe: {width: 0.6}, text: {max_lines: 1}, backdrop: {brightness: -0.4}}\n');
      final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
      final layout = project.creativeDefaults.layouts['21:9']!;
      expect(layout.safeWidth, 0.6);
      expect(layout.maxLines, 1);
      expect(layout.brightness, -0.4);
      expect(project.creativeDefaults.layouts['3:2']!.safeWidth, loadCreativeDefaults(pkg).layouts['3:2']!.safeWidth);
      repo.delete();

      repo = creativeRepo(pkg, layouts: '  layouts:\n    "21:9": {safe: {width: 0.9}}\n');
      expect(
        () => Project.load(root: repo.root, appId: 'demo', packageRoot: pkg),
        throwsA(isA<ConfigError>().having((e) => e.message, 'message', contains('loosens'))),
      );
      repo.delete();
      repo = creativeRepo(pkg, layouts: '  layouts:\n    "21:9": {backdrop: {brightness: 0.1}}\n');
      expect(() => Project.load(root: repo.root, appId: 'demo', packageRoot: pkg), throwsA(isA<ConfigError>()));
      repo.delete();
      repo = creativeRepo(pkg, layouts: '  layouts:\n    "21:9": {panel: {height: 0.5}}\n');
      expect(
        () => Project.load(root: repo.root, appId: 'demo', packageRoot: pkg),
        throwsA(isA<ConfigError>()),
        reason: 'only the safe area, the phrase and the backdrop',
      );
    });

    test('a per-storefront asset\'s storefront is an App Store Connect locale', () {
      repo = creativeRepo(pkg);
      final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
      final d = project.creativeDefaults;
      final withoutJa = CreativeDefaults(
        placements: d.placements,
        specs: d.specs,
        layouts: d.layouts,
        maxBytes: d.maxBytes,
        videoCodecs: d.videoCodecs,
        encoding: d.encoding,
        checks: d.checks,
        ascLocales: [
          for (final l in d.ascLocales)
            if (l != 'ja') l,
        ],
      );
      final found = checkCreatives(
        project.allCreatives,
        app: project.app,
        scripts: project.allScripts,
        templates: project.templates,
        defaults: withoutJa,
        contract: project.contract,
      ).items;
      expect(found, contains(contains('storefront ja is not an App Store Connect locale')));
      expect(d.ascLocales, containsAll(['en-US', 'ja', 'zh-Hans', 'pt-BR', 'es-MX', 'hi', 'id', 'tr', 'vi', 'ko', 'de-DE', 'fr-FR']));
    });

    test('muted, the opening holds one scene for the hook\'s 2 s', () {
      repo = creativeRepo(
        pkg,
        creative: fixtureCreative.replaceFirst(
          '          - {beat: hero, script: A, scene: player, duration: 6.0}',
          '          - {beat: hero, script: A, scene: player, duration: 1.5}\n          - {beat: hero, script: A, scene: player, from: 1.5, duration: 4.5}',
        ),
      );
      expect(problems(Project.load(root: repo.root, appId: 'demo', packageRoot: pkg)), [contains('the first scene lasts 1.5s')]);
    });

    test('a video\'s length: the rhythm, the spec\'s floor', () {
      repo = creativeRepo(
        pkg,
        creative: fixtureCreative
            .replaceFirst('rhythm: 12', 'rhythm: 8')
            .replaceFirst(
              'duration: 6.0}\n          - {beat: detail, script: W, scene: hold, duration: 6.0}',
              'duration: 5.5}\n          - {beat: detail, script: W, scene: hold, duration: 2.5}',
            ),
      );
      expect(problems(Project.load(root: repo.root, appId: 'demo', packageRoot: pkg)), [
        contains('8.0s is outside the spec\'s 10.0–30.0 s'),
      ], reason: 'the header video\'s floor is 10 s (ADR-0013)');
    });
  });

  group('loop templates', () {
    test('the search card\'s rhythms fit the 15 s floor', () {
      final template = loadTemplates(pkg)['search_card']!;
      expect(template.rhythms.keys, [8, 12, 15]);
      final spec = loadCreativeDefaults(pkg).specs['search_3x2']!.video!;
      expect(template.rhythms.keys.where((r) => r >= spec.minSeconds!), [15]);
    });
  });

  group('real_ui', () {
    test('screenshots: more than half of each set shows the app in use', () {
      Map<String, Object?> shot(String locale, bool real) => {
        'type': 'screenshot',
        'locale': locale,
        'display_target': 'APP_IPHONE_67',
        'source': {'real_ui': real},
      };
      expect(screenshotMajority([shot('en-US', true), shot('en-US', true), shot('en-US', false)]), isEmpty, reason: '2 of 3');
      expect(screenshotMajority([shot('en-US', true), shot('en-US', true), shot('en-US', false), shot('en-US', false)]), [contains('2 of 4')]);
      expect(screenshotMajority([shot('en-US', true), shot('ja', false)]), [contains('ja')], reason: 'per localization');
      expect(
        screenshotMajority([
          {
            'type': 'header_image',
            'locale': 'en-US',
            'display_target': 'universal',
            'source': {'real_ui': false},
          },
        ]),
        isEmpty,
      );
    });

    test('only a person\'s review sets it, and a changed asset makes it stale', () {
      final dir = Directory.systemTemp.createTempSync('review');
      addTearDown(() => dir.deleteSync(recursive: true));
      final definition = loadCreativeFrom(dir, fixtureCreative);
      final slot = definition.slots[1];
      final log = ReviewLog.load(p.join(dir.path, 'creative_review.yaml'));
      expect(log.realUi(slot, slot.assets[0]), isNull, reason: 'no review: the manifest says false');
      log.record(CreativeReview(asset: slot.assets[0].id, realUi: true, reviewer: 'A Person', date: '2026-10-10', basis: reviewBasis(slot, slot.assets[0])));
      expect(ReviewLog.load(log.path).realUi(slot, slot.assets[0]), isTrue);
      final moved = loadCreativeFrom(
        dir,
        fixtureCreative.replaceFirst(
          'frame: {script: A, scene: player, at: 1.0}}\n      - id: "header',
          'frame: {script: A, scene: player, at: 2.0}}\n      - id: "header',
        ),
      );
      expect(ReviewLog.load(log.path).realUi(moved.slots[1], moved.slots[1].assets[0]), isNull, reason: 'it shows another frame now');
    });
  });
}

/// [yaml] as `<dir>/page.yaml`, loaded.
CreativeDefinition loadCreativeFrom(Directory dir, String yaml) {
  final f = File(p.join(dir.path, 'page.yaml'))..writeAsStringSync(yaml);
  return loadCreative(f.path);
}
