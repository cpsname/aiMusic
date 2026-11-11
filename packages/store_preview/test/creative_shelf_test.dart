import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';
import 'package:yaml/yaml.dart';

import 'support/creative_fixture.dart';
import 'support/fixture.dart';

/// The shelves (template ADR-0015): the definition that makes a page's
/// assets declares what the page shows in each of ascpub's slots; the
/// listing's bindings are derived from it, written back by `listing --write`
/// (those blocks and `assets.yaml` › `manifest`, nothing else), and a listing
/// that differs fails the configuration.
void main() {
  late String pkg;
  setUpAll(() async => pkg = await packageRoot());

  const shelf = '''
shelf:
  header: {default: header.universal, locales: "header.{storefront}"}
  search_results: {default: header.universal, locales: "search.{storefront}"}
''';

  CreativeDefinition definition(String yaml) {
    final dir = Directory.systemTemp.createTempSync('shelf_definition');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'page.yaml'))..writeAsStringSync(yaml);
    return loadCreative(file.path);
  }

  group('derived', () {
    test('per slot: the default, and the locales expanded over the storefronts', () {
      final shelves = deriveShelves([definition(fixtureCreative + shelf)], ['en-US', 'ja']);
      expect(shelves.keys, ['app_store_version']);
      final header = shelves['app_store_version']!['header']!;
      expect(header.defaultId, 'header.universal');
      expect(header.locales, {'en-US': 'header.en-US', 'ja': 'header.ja'});
      expect(shelves['app_store_version']!['search_results']!.locales, {'en-US': 'search.en-US', 'ja': 'search.ja'});
    });

    test('a definition without a shelf stocks none', () {
      expect(deriveShelves([definition(fixtureCreative)], ['en-US']), isEmpty);
    });

    test('a shelf names a default, locales or both', () {
      expect(() => definition('$fixtureCreative\nshelf:\n  header: {}\n'), throwsA(isA<ConfigError>()));
    });
  });

  group('declarations', () {
    List<String> problems(String yaml) => checkShelfDeclarations([definition(yaml)]);

    test('the fixture\'s shelf is sound', () => expect(problems(fixtureCreative + shelf), isEmpty));

    test('each rule names its place', () {
      expect(problems('$fixtureCreative\nshelf:\n  banner: {default: header.universal}\n'), [contains('shelf.banner: not an ascpub slot')]);
      expect(problems('$fixtureCreative\nshelf:\n  header: {default: header.nope}\n'), [contains('shelf.header.default: header.nope is not an asset of creatives/page')]);
      expect(problems('$fixtureCreative\nshelf:\n  header: {default: "header.{storefront}"}\n'), [contains('the default shows in every localization')]);
      expect(problems('$fixtureCreative\nshelf:\n  header: {locales: header.universal}\n'), [contains('the locales take an asset made per {storefront}')]);
      expect(problems('$fixtureCreative\nshelf:\n  header: {locales: "search.{storefront}"}\n'), [contains('is made for app_store_search_results, not product_page_header')]);
    });

    test('one definition stocks a page\'s slot', () {
      final dir = Directory.systemTemp.createTempSync('shelf_owner');
      addTearDown(() => dir.deleteSync(recursive: true));
      final a = File(p.join(dir.path, 'page.yaml'))..writeAsStringSync(fixtureCreative + shelf);
      final b = File(p.join(dir.path, 'other.yaml'))..writeAsStringSync((fixtureCreative + shelf).replaceFirst('id: page', 'id: other'));
      expect(checkShelfDeclarations([loadCreative(a.path), loadCreative(b.path)]), [
        contains('app_store_version\'s header is also declared by creatives/page'),
        contains('app_store_version\'s search_results is also declared by creatives/page'),
      ]);
    });
  });

  group('written into ascpub\'s listing', () {
    late Directory dir;
    late String manifest;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('shelf_listing');
      manifest = p.join(dir.path, 'repo', 'dist', 'demo', 'assets-manifest.json');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    String listingDir() => p.join(dir.path, 'listings', 'org.example.demo');
    File file(String path) => File(p.join(listingDir(), path));
    void write(String path, String text) => (file(path)..createSync(recursive: true)).writeAsStringSync(text);

    const assetsYaml = '''
# The Asset Library configuration (ascpub).
schema: 1
manifest: ""
store_page:
  # The default product page.
  header:
    default: ""
    locales: {}
  search_results:
    default: ""
    locales: {}
deep_links:
  info_plist: ""
  allowed: [demo://app/create]
''';
    const cppYaml = '''
# Birthday songs.
schema: 1
name: "Birthday Songs"
deep_link: "demo://app/create?template=birthday"
visible: false
locales:
  en-US:
    promotional_text: ""
    keywords: [birthday]
header:
  default: ""
  locales: {}
search_results:
  default: ""
  locales: {}
''';
    const ppoYaml = '''
schema: 1
name: "Header motion"
target: product_page
traffic_proportion: 30
hypothesis: "A moving header converts better"
primary_metric: conversion_rate
variable: header
bundle_note: ""
locales: [en-US]
treatments:
  - name: "Still"
    header: {default: "", locales: {}}
  - name: "Video"
    header:
      default: ""
      locales: {}
''';

    Map<String, Shelf> shelves() => {
      'app_store_version': {
        'header': const SlotBinding(defaultId: 'header.universal', locales: {'en-US': 'header.en-US', 'ja': 'header.ja'}),
        'search_results': const SlotBinding(defaultId: 'header.universal', locales: {}),
      },
      'custom_product_page:birthday': {
        'header': const SlotBinding(defaultId: 'cpp.birthday.header', locales: {'en-US': 'cpp.birthday.header.en-US'}),
      },
      'ppo:header-motion:Video': {
        'header': const SlotBinding(defaultId: null, locales: {'en-US': 'ppo.video.en-US'}),
      },
    };

    test('only the shelved slot blocks and the manifest change; the rest stays as written', () {
      write('assets.yaml', assetsYaml);
      write('cpp/birthday.yaml', cppYaml);
      write('ppo/header-motion.yaml', ppoYaml);
      var listing = AscpubListing.load(listingDir());
      expect(shelfDrift(listing, shelves(), manifestPath: manifest, fix: 'FIX'), hasLength(5));

      final changed = writeShelves(listing, shelves(), manifestPath: manifest);
      expect(changed.map(p.basename), unorderedEquals(['assets.yaml', 'birthday.yaml', 'header-motion.yaml']));

      listing = AscpubListing.load(listingDir());
      expect(shelfDrift(listing, shelves(), manifestPath: manifest, fix: 'FIX'), isEmpty);
      expect(listing.manifest, '../../repo/dist/demo/assets-manifest.json');
      expect(listing.pages['ppo:header-motion:Still']!.slots['header']!.ids, isEmpty, reason: 'an unshelved treatment is left alone');

      final assets = file('assets.yaml').readAsStringSync();
      expect(assets, startsWith('# The Asset Library configuration (ascpub).\nschema: 1\n'));
      expect(assets, contains('# The default product page.'));
      expect(assets, contains('allowed: [demo://app/create]'));
      final cpp = loadYaml(file('cpp/birthday.yaml').readAsStringSync()) as YamlMap;
      expect(cpp['name'], 'Birthday Songs');
      expect(cpp['deep_link'], 'demo://app/create?template=birthday');
      expect((cpp['locales'] as YamlMap)['en-US']['keywords'], ['birthday']);
      expect(cpp['search_results'], {'default': '', 'locales': <String, String>{}}, reason: 'a slot the shelf does not declare is not touched');
      final ppo = loadYaml(file('ppo/header-motion.yaml').readAsStringSync()) as YamlMap;
      expect(ppo['hypothesis'], 'A moving header converts better');
      expect((ppo['treatments'] as YamlList).map((t) => t['name']), ['Still', 'Video']);

      expect(writeShelves(listing, shelves(), manifestPath: manifest), isEmpty, reason: 'a second write changes nothing');
    });

    test('a listing without the maps gets them', () {
      write('assets.yaml', 'schema: 1\n');
      final listing = AscpubListing.load(listingDir());
      writeShelves(listing, {'app_store_version': shelves()['app_store_version']!}, manifestPath: manifest);
      final assets = loadYaml(file('assets.yaml').readAsStringSync()) as YamlMap;
      expect(assets['store_page']['header']['locales'], {'en-US': 'header.en-US', 'ja': 'header.ja'});
      expect(assets['manifest'], '../../repo/dist/demo/assets-manifest.json');
    });

    test('a treatment without the slot gets it (a map inside a list)', () {
      write('assets.yaml', assetsYaml);
      write('ppo/header-motion.yaml', 'schema: 1\nname: "Header motion"\nlocales: [en-US]\ntreatments:\n  - name: "Still"\n  - name: "Video"\n');
      final video = {'ppo:header-motion:Video': shelves()['ppo:header-motion:Video']!};
      writeShelves(AscpubListing.load(listingDir()), video, manifestPath: manifest);
      final treatments = (loadYaml(file('ppo/header-motion.yaml').readAsStringSync()) as YamlMap)['treatments'] as YamlList;
      expect(treatments.map((t) => t['name']), ['Still', 'Video']);
      expect(treatments[1]['header'], {'default': '', 'locales': {'en-US': 'ppo.video.en-US'}});
      expect(shelfDrift(AscpubListing.load(listingDir()), video, manifestPath: manifest, fix: 'FIX'), isEmpty);
    });

    test('an empty id binds nothing, as ascpub reads it', () {
      write('assets.yaml', 'schema: 1\nstore_page:\n  header: {default: "", locales: {en-US: "", ja: header.ja}}\n');
      final header = AscpubListing.load(listingDir()).pages['app_store_version']!.slots['header']!;
      expect(header.defaultId, isNull);
      expect(header.locales, {'ja': 'header.ja'});
    });

    test('a page gets the locales it localizes: ascpub places nothing on another, yet would upload it', () {
      write('assets.yaml', assetsYaml);
      write('cpp/birthday.yaml', cppYaml);
      write('ppo/header-motion.yaml', ppoYaml);
      final wide = {
        'custom_product_page:birthday': {
          'header': const SlotBinding(defaultId: 'cpp.birthday.header', locales: {'en-US': 'cpp.birthday.header.en-US', 'ja': 'cpp.birthday.header.ja'}),
        },
        'ppo:header-motion:Video': {
          'header': const SlotBinding(defaultId: null, locales: {'en-US': 'ppo.video.en-US', 'ja': 'ppo.video.ja'}),
        },
      };
      var listing = AscpubListing.load(listingDir());
      expect(listing.pages['custom_product_page:birthday']!.localizations, {'en-US'});
      expect(listing.pages['ppo:header-motion:Video']!.localizations, {'en-US'});
      expect(listing.pages['app_store_version']!.localizations, isNull, reason: 'the default page has every localization');
      writeShelves(listing, wide, manifestPath: manifest);
      listing = AscpubListing.load(listingDir());
      expect(listing.pages['custom_product_page:birthday']!.slots['header']!.locales, {'en-US': 'cpp.birthday.header.en-US'});
      expect(listing.pages['ppo:header-motion:Video']!.slots['header']!.locales, {'en-US': 'ppo.video.en-US'});
      expect(shelfDrift(listing, wide, manifestPath: manifest, fix: 'FIX'), isEmpty);
    });

    test('a page the listing lacks is ascpub\'s to create', () {
      write('assets.yaml', assetsYaml);
      expect(
        () => writeShelves(AscpubListing.load(listingDir()), shelves(), manifestPath: manifest),
        throwsA(isA<ConfigError>().having((e) => e.message, 'message', contains('ascpub assets init --cpp <slug> --ppo <slug>'))),
      );
      expect(file('assets.yaml').readAsStringSync(), assetsYaml, reason: 'nothing is written when a page is missing');
    });

    test('drift names the first difference', () {
      write('assets.yaml', assetsYaml.replaceFirst('manifest: ""', 'manifest: ../elsewhere/assets-manifest.json'));
      final drift = shelfDrift(AscpubListing.load(listingDir()), {'app_store_version': shelves()['app_store_version']!}, manifestPath: manifest, fix: 'FIX');
      expect(drift, [
        contains('manifest: ../elsewhere/assets-manifest.json is not this checkout\'s ../../repo/dist/demo/assets-manifest.json — FIX'),
        contains('header: default is (empty), the shelf says header.universal — FIX'),
        contains('search_results: default is (empty), the shelf says header.universal — FIX'),
      ]);
    });
  });

  group('the configuration', () {
    late FixtureRepo repo;
    tearDown(() => repo.delete());

    List<String> problems() {
      final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
      return project.checkConfig(texts: project.textsFromArb(), withManifest: false).items;
    }

    test('a shelved app needs a listing', () {
      repo = creativeRepo(pkg, creative: fixtureCreative + shelf);
      expect(problems(), [contains('creatives declare shelves for app_store_version: app.yaml creatives.ascpub.listing')]);
    });

    test('the listing fails the check until `listing --write`; then it holds the shelves', () async {
      repo = creativeRepo(pkg, creative: fixtureCreative + shelf, listing: 'listings/demo');
      repo.write('listings/demo/assets.yaml', 'schema: 1\n');
      expect(problems(), [
        contains('manifest: not set'),
        contains('header: default is (empty), the shelf says header.universal'),
        contains('search_results: default is (empty), the shelf says header.universal'),
      ]);
      expect(await runCli(['listing', '--app', 'demo', '--root', repo.root], packageRoot: pkg), 1);

      expect(await runCli(['listing', '--app', 'demo', '--root', repo.root, '--write'], packageRoot: pkg), 0);
      expect(problems(), isEmpty);
      expect(await runCli(['listing', '--app', 'demo', '--root', repo.root], packageRoot: pkg), 0);
      final assets = loadYaml(File(repo.path('listings/demo/assets.yaml')).readAsStringSync()) as YamlMap;
      expect(assets['manifest'], '../../dist/demo/assets-manifest.json');
      expect(assets['store_page']['search_results'], {
        'default': 'header.universal',
        'locales': {'en-US': 'search.en-US', 'ja': 'search.ja'},
      });
    });

    test('a served localization is shelved with its own id (ADR-0017)', () async {
      repo = creativeRepo(pkg, creative: fixtureCreative + shelf, listing: 'listings/demo');
      final app = File(repo.path('store_preview/demo/app.yaml'));
      app.writeAsStringSync(app.readAsStringSync().replaceFirst('vars: {region: US}}', 'vars: {region: US}, serves: [en-GB]}'));
      repo.write('listings/demo/assets.yaml', 'schema: 1\n');
      expect(await runCli(['listing', '--app', 'demo', '--root', repo.root, '--write'], packageRoot: pkg), 0);
      expect(problems(), isEmpty, reason: 'header.en-GB is made (as en-US\'s alias) for the page and slot it is bound to');
      final assets = loadYaml(File(repo.path('listings/demo/assets.yaml')).readAsStringSync()) as YamlMap;
      expect(assets['store_page']['header'], {
        'default': 'header.universal',
        'locales': {'en-GB': 'header.en-GB', 'en-US': 'header.en-US', 'ja': 'header.ja'},
      });

      // A served locale App Store Connect does not have binds nothing.
      app.writeAsStringSync(app.readAsStringSync().replaceFirst('serves: [en-GB]', 'serves: [en-XX]'));
      expect(problems(), contains(contains('en-US serves en-XX, which is not an App Store Connect locale')));
    });

    test('the warehouse holds what the definitions make: a retired asset\'s outputs go', () {
      repo = creativeRepo(pkg);
      final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
      final pipeline = Pipeline(project: project, storefronts: [project.app.storefronts.last], slots: const [], say: (_) {});
      final current = [
        'creative/ja/header.ja.png', 'creative/ja/header.ja.edl.json', 'creative/en-US/header.en-US.video.mp4', //
        'creative/en-US/header.en-US.video.poster.png', 'creative/universal/header.universal.png',
        'creative/sheets/header.all.png', 'creative/sheets/header.all.video.first2s.png', 'creative/sheets/search.all.txt',
      ];
      final retired = ['creative/ja/header.ja.loop.mp4', 'creative/en-US/old.en-US.png', 'creative/sheets/old.all.png', 'creative/sheets/header.all.png.bak'];
      for (final f in [...current, ...retired]) {
        repo.write('dist/demo/$f', 'x');
      }
      expect(pipeline.pruneRetiredCreatives().map((f) => p.relative(f, from: repo.path('dist/demo'))), unorderedEquals(retired),
          reason: 'a run of one storefront keeps the others\' current assets');
      for (final f in current) {
        expect(File(repo.path('dist/demo/$f')).existsSync(), isTrue, reason: f);
      }
      expect(pipeline.pruneRetiredCreatives(), isEmpty);
    });

    test('without a shelf the bindings are the person\'s, and `listing` says so', () async {
      repo = creativeRepo(pkg);
      expect(await runCli(['listing', '--app', 'demo', '--root', repo.root], packageRoot: pkg), 0);
    });
  });
}
