import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';

import 'support/creative_fixture.dart';
import 'support/fixture.dart';
import 'support/scaffold_fixture.dart';

void main() {
  late String pkg;
  setUpAll(() async => pkg = await packageRoot());

  test('reads the repo: bundle id, families, name, icon, l10n', () {
    final root = appRepo();
    addTearDown(() => Directory(root).deleteSync(recursive: true));
    final facts = readRepo(root);
    expect(facts.package, 'demo_app');
    expect(facts.bundleId, 'org.example.demo');
    expect(facts.families, {1, 2});
    expect(facts.displayName, 'Demo Studio');
    expect(facts.icon, 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png');
    expect(facts.arbPattern, 'app_{locale}.arb');
    expect(facts.uiLocales, ['en', 'zh']);
    expect(facts.definesFile, 'config/dev.json');
  });

  test('new-app scaffolds a configuration that passes validation unchanged', () {
    final root = appRepo();
    addTearDown(() => Directory(root).deleteSync(recursive: true));
    final lines = scaffoldApp(root: root, name: 'demo', packageRoot: pkg);
    expect(lines.first, '✓ store_preview/demo for Demo Studio (org.example.demo), storefronts en, zh');
    expect(lines, contains('  + integration_test/store_preview_test.dart'));
    expect(lines.join('\n'), isNot(contains('translate')));

    final project = Project.load(root: root, appId: 'demo', packageRoot: pkg);
    expect(project.app.storefronts.map((s) => '${s.id} ${s.simLanguage} ${s.simLocale}'), ['en-US en en_US', 'zh-Hans zh-Hans zh_CN']);
    expect(project.app.slots.keys, ['iphone']);
    final texts = project.textsFromArb();
    expect(texts['zh-Hans']!['storePreviewCta'], '马上试试', reason: 'an existing key is kept');
    expect(texts['zh-Hans']!['storePreviewAIntro'], '一个应用全搞定');
    expect(project.checkConfig(texts: texts, prober: const FakeProber()).items, isEmpty);
    expect(
      File(p.join(root, 'integration_test/store_preview_test.dart')).readAsStringSync(),
      startsWith("import 'package:demo_app/main.dart' as app;\nimport 'package:store_preview_driver/store_preview_driver.dart';"),
    );
    expect(jsonDecode(File(p.join(root, 'lib/l10n/arb/app_en.arb')).readAsStringSync())['@storePreviewAIntro'], isNotNull);
    expect(File(p.join(root, 'store_preview/demo/captions/zh-Hans.json')).existsSync(), isTrue);
  });

  test('new-creatives scaffolds the shop: shelf, counter, treatment — valid once ascpub has the pages', () async {
    final root = appRepo();
    addTearDown(() => Directory(root).deleteSync(recursive: true));
    scaffoldApp(root: root, name: 'demo', packageRoot: pkg);
    final ascpub = testAscpubRoot(pkg);
    void write(String path, String content) => (File(p.join(root, path))..parent.createSync(recursive: true)).writeAsStringSync(content);

    expect(
      () => scaffoldCreatives(root: root, appId: 'demo', packageRoot: pkg, ascpubRoot: ascpub),
      throwsA(isA<ConfigError>().having((e) => e.message, 'message', contains('holds no licensed image for every storefront'))),
      reason: 'every asset stands on a licensed image',
    );
    final media = [
      for (final l in ['en-US', 'zh-Hans']) entry(id: 'photo.A.$l.1', type: 'image', role: 'photo', locale: l),
    ];
    for (final e in media) {
      write('store_preview/demo/media/${e['file']}', 'x');
    }
    write('store_preview/demo/media/manifest.json', jsonEncode({'schema': manifestSchema, 'entries': media}));

    final lines = scaffoldCreatives(
      root: root,
      appId: 'demo',
      packageRoot: pkg,
      ascpubRoot: ascpub,
      cpp: ['birthday'],
      ppo: [parseTreatment('header-motion:Video')],
    );
    expect(
      lines,
      containsAll([
        '  + store_preview/demo/creatives/store-page.yaml',
        '  + store_preview/demo/creatives/cpp-birthday.yaml',
        '  + store_preview/demo/creatives/ppo-header-motion-video.yaml',
        '  ~ store_preview/demo/app.yaml: creatives',
      ]),
    );
    expect(lines, contains('  1. in ascpub\'s listing (run from this repo): ascpub assets init -b org.example.demo --cpp birthday --ppo header-motion'));
    expect(
      lines.join('\n'),
      contains('translate the English phrases added to app_zh.arb (storeCreativeCppBirthday)'),
      reason: 'only the counter\'s phrase starts in English',
    );
    expect(
      () => scaffoldCreatives(root: root, appId: 'demo', packageRoot: pkg, ascpubRoot: ascpub),
      throwsA(isA<ConfigError>()),
      reason: 'never over an existing set',
    );

    var project = Project.load(root: root, appId: 'demo', packageRoot: pkg);
    expect(project.app.creatives.ascpub!.schemaSha256, contractSha(ascpub));
    expect(project.app.creatives.ascpub!.listing, 'listings/org.example.demo');
    expect(project.textsFromArb()['zh-Hans']!['storeCreativeHeader'], '一个应用全搞定');
    expect(project.shelves.keys, ['app_store_version', 'custom_product_page:birthday', 'ppo:header-motion:Video']);
    expect(project.shelves['ppo:header-motion:Video']!.keys, ['header'], reason: 'a treatment changes one variable');
    expect(
      () => project.checkConfig(texts: project.textsFromArb(), prober: const FakeProber()),
      throwsA(isA<ConfigError>().having((e) => e.message, 'message', contains('`ascpub assets init`'))),
      reason: 'the pages are ascpub\'s to create',
    );

    // What `ascpub assets init -b org.example.demo --cpp birthday --ppo header-motion` writes, filled in.
    write('listings/org.example.demo/assets.yaml', 'schema: 1\nmanifest: ""\n');
    write('listings/org.example.demo/cpp/birthday.yaml', 'schema: 1\nname: "Birthday"\nlocales:\n  en-US: {promotional_text: "", keywords: []}\n');
    write(
      'listings/org.example.demo/ppo/header-motion.yaml',
      'schema: 1\nname: "Header motion"\nvariable: header\nlocales: [en-US, zh-Hans]\ntreatments:\n  - name: "Video"\n',
    );
    expect(await runCli(['listing', '--app', 'demo', '--root', root, '--write'], packageRoot: pkg), 0);
    project = Project.load(root: root, appId: 'demo', packageRoot: pkg);
    expect(project.checkConfig(texts: project.textsFromArb(), prober: const FakeProber()).items, isEmpty);
    final pages = project.listing!.pages;
    expect(pages['ppo:header-motion:Video']!.slots['header']!.locales, {
      'en-US': 'ppo.header-motion.video.header.en-US',
      'zh-Hans': 'ppo.header-motion.video.header.zh-Hans',
    });
    expect(pages['custom_product_page:birthday']!.slots['header']!.locales, {'en-US': 'cpp.birthday.header.en-US'}, reason: 'the counter localizes en-US only');
    expect(pages['app_store_version']!.slots['search_results']!.locales.keys, ['en-US', 'zh-Hans']);
    expect(await runCli(['listing', '--app', 'demo', '--root', root, '--dir'], packageRoot: pkg), 0);
  });

  test('new-creatives refuses wrong input before writing anything, and names what only the app knows', () async {
    final root = appRepo();
    addTearDown(() => Directory(root).deleteSync(recursive: true));
    scaffoldApp(root: root, name: 'demo', packageRoot: pkg);
    final ascpub = testAscpubRoot(pkg);
    void write(String path, String content) => (File(p.join(root, path))..parent.createSync(recursive: true)).writeAsStringSync(content);
    final media = [
      for (final l in ['en-US', 'zh-Hans']) ...[
        entry(id: 'photo.A.$l.1', type: 'image', role: 'photo', locale: l),
        entry(id: 'song.A.$l', type: 'audio', role: 'song', locale: l),
      ],
    ];
    write('store_preview/demo/media/manifest.json', jsonEncode({'schema': manifestSchema, 'entries': media}));
    final script = File(p.join(root, 'store_preview/demo/scripts/A.yaml'));
    script.writeAsStringSync(
      script.readAsStringSync().replaceFirst('    finished: true\n', '    finished: true\n    shows: [{role: song, script: A, index: 0}]\n'),
    );
    final appYaml = File(p.join(root, 'store_preview/demo/app.yaml')).readAsStringSync();

    for (final (cpp, ppo, message) in [
      (['birthday', 'birthday'], <TreatmentRef>[], 'is named once'),
      (<String>[], [(slug: 'motion', name: 'Video B'), (slug: 'motion', name: 'video-b')], 'the same treatment'),
      (<String>[], [(slug: 'Motion', name: 'Video')], '<slug>:<treatment>'),
    ]) {
      expect(
        () => scaffoldCreatives(root: root, appId: 'demo', packageRoot: pkg, ascpubRoot: ascpub, cpp: cpp, ppo: ppo),
        throwsA(isA<ConfigError>().having((e) => e.message, 'message', contains(message))),
      );
      expect(File(p.join(root, 'store_preview/demo/app.yaml')).readAsStringSync(), appYaml, reason: 'nothing written');
      expect(Directory(p.join(root, 'store_preview/demo/creatives')).existsSync(), isFalse);
    }

    final lines = scaffoldCreatives(root: root, appId: 'demo', packageRoot: pkg, ascpubRoot: ascpub, listing: 'store/listings/org.example.demo');
    expect(lines, contains('  1. in ascpub\'s listing (run from this repo): ascpub assets init -l store/listings -b org.example.demo'));
    expect(lines, contains(allOf(contains('map song in app.yaml creatives.authorization'), contains('interaction_id'))));
    final project = Project.load(root: root, appId: 'demo', packageRoot: pkg);
    expect(project.app.creatives.ascpub!.listing, 'store/listings/org.example.demo');
  });

  test('new-creatives on the command line: the ascpub checkout is required', () async {
    final root = appRepo();
    addTearDown(() => Directory(root).deleteSync(recursive: true));
    scaffoldApp(root: root, name: 'demo', packageRoot: pkg);
    expect(await runCli(['new-creatives', '--app', 'demo', '--root', root, '--ascpub', p.join(root, 'nowhere')], packageRoot: pkg), 1);
    expect(await runCli(['new-creatives', '--app', 'demo', '--root', root, '--ppo', 'motion'], packageRoot: pkg), 1);
  });

  test('ARB entries are appended without reflowing the file', () {
    const arb = '{\n  "@@locale": "en",\n  "count": "{n} items",\n  "@count": {\n    "placeholders": { "n": { "type": "int" } }\n  }\n}\n';
    final out = appendArbEntries(arb, {
      'storePreviewCta': 'Try it',
      '@storePreviewCta': {'description': 'd'},
    });
    expect(out, startsWith(arb.substring(0, arb.lastIndexOf('}')).trimRight()));
    expect(out, contains('    "placeholders": { "n": { "type": "int" } }'));
    expect(out, endsWith('  },\n  "storePreviewCta": "Try it",\n  "@storePreviewCta": {\n    "description": "d"\n  }\n}\n'));
    expect(appendArbEntries('{}', {'a': 'b'}), '{\n  "a": "b"\n}\n');
  });

  test('a language without scaffold copy starts from the English and is listed for translation', () {
    final root = appRepo();
    addTearDown(() => Directory(root).deleteSync(recursive: true));
    File(p.join(root, 'lib/l10n/arb/app_de.arb')).writeAsStringSync(jsonEncode({'@@locale': 'de', 'title': 'Demo'}));
    final lines = scaffoldApp(root: root, name: 'demo', packageRoot: pkg);
    expect(lines, contains(contains('translate the English copy added to app_de.arb (6)')));
  });

  test('refuses an existing app, a bad name and a repo that is not an app', () {
    final root = appRepo();
    addTearDown(() => Directory(root).deleteSync(recursive: true));
    scaffoldApp(root: root, name: 'demo', packageRoot: pkg);
    expect(() => scaffoldApp(root: root, name: 'demo', packageRoot: pkg), throwsA(isA<ConfigError>()));
    expect(() => scaffoldApp(root: root, name: 'Demo App', packageRoot: pkg), throwsA(isA<ConfigError>()));
    final empty = Directory.systemTemp.createTempSync('empty').path;
    addTearDown(() => Directory(empty).deleteSync(recursive: true));
    expect(() => scaffoldApp(root: empty, name: 'x', packageRoot: pkg), throwsA(isA<ConfigError>()));
  });
}
