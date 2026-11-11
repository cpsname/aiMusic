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

  test('new-app selects unique ASC localizations for Chinese and Norwegian aliases', () {
    final root = appRepo();
    addTearDown(() => Directory(root).deleteSync(recursive: true));
    for (final locale in ['zh_Hans', 'nb', 'no', 'da', 'ms']) {
      File(p.join(root, 'lib/l10n/arb/app_$locale.arb')).writeAsStringSync(jsonEncode({'@@locale': locale, 'title': locale}));
    }
    scaffoldApp(root: root, name: 'demo', packageRoot: pkg);
    final project = Project.load(root: root, appId: 'demo', packageRoot: pkg);
    expect(project.app.storefronts.where((s) => s.id == 'zh-Hans').single.uiLocale, 'zh-Hans');
    expect(project.app.storefronts.where((s) => s.id == 'no').single.uiLocale, 'nb');
    expect(project.app.storefronts.firstWhere((s) => s.id == 'da').simLocale, 'da_DK');
    expect(project.app.storefronts.firstWhere((s) => s.id == 'ms').simLocale, 'ms_MY');
  });

  test('new-app rejects ambiguous bundle IDs before any app configuration is written', () {
    final root = appRepo();
    addTearDown(() => Directory(root).deleteSync(recursive: true));
    File(p.join(root, 'ios/Runner.xcodeproj/project.pbxproj')).writeAsStringSync('\nPRODUCT_BUNDLE_IDENTIFIER = org.example.other;\n', mode: FileMode.append);
    expect(() => scaffoldApp(root: root, name: 'demo', packageRoot: pkg), throwsA(isA<ConfigError>()));
    expect(Directory(p.join(root, 'store_preview')).existsSync(), isFalse);
  });

  test('invalid late ARB leaves no partial new-app configuration or modified earlier ARBs', () {
    final root = appRepo();
    addTearDown(() => Directory(root).deleteSync(recursive: true));
    final en = File(p.join(root, 'lib/l10n/arb/app_en.arb'));
    final before = en.readAsStringSync();
    File(p.join(root, 'lib/l10n/arb/app_zh.arb')).writeAsStringSync('{invalid');
    expect(() => scaffoldApp(root: root, name: 'demo', packageRoot: pkg), throwsA(anything));
    expect(en.readAsStringSync(), before);
    expect(Directory(p.join(root, 'store_preview')).existsSync(), isFalse);
  });

  test('new-creatives plans every ARB before writing definitions', () {
    final root = appRepo();
    addTearDown(() => Directory(root).deleteSync(recursive: true));
    scaffoldApp(root: root, name: 'demo', packageRoot: pkg);
    final entries = [
      for (final l in ['en-US', 'zh-Hans']) entry(id: 'photo.A.$l.1', type: 'image', role: 'photo', locale: l),
    ];
    File(p.join(root, 'store_preview/demo/media/manifest.json')).writeAsStringSync(jsonEncode({'schema': 2, 'entries': entries}));
    for (final e in entries) {
      (File(p.join(root, 'store_preview/demo/media', '${e['file']}'))..parent.createSync(recursive: true)).writeAsStringSync('image');
    }
    final app = File(p.join(root, 'store_preview/demo/app.yaml'));
    final before = app.readAsStringSync();
    File(p.join(root, 'lib/l10n/arb/app_zh.arb')).writeAsStringSync('{invalid');
    expect(() => scaffoldCreatives(root: root, appId: 'demo', packageRoot: pkg, ascpubRoot: testAscpubRoot(pkg)), throwsA(anything));
    expect(app.readAsStringSync(), before);
    expect(Directory(p.join(root, 'store_preview/demo/creatives')).existsSync(), isFalse);
  });

  test('scaffold paths containing a YAML colon and spaces round-trip unchanged', () {
    final root = appRepo();
    addTearDown(() => Directory(root).deleteSync(recursive: true));
    scaffoldApp(root: root, name: 'demo', packageRoot: pkg);
    final entries = [
      for (final l in ['en-US', 'zh-Hans']) entry(id: 'photo.$l', type: 'image', role: 'photo', locale: l),
    ];
    File(p.join(root, 'store_preview/demo/media/manifest.json')).writeAsStringSync(jsonEncode({'schema': 2, 'entries': entries}));
    for (final e in entries) {
      (File(p.join(root, 'store_preview/demo/media', '${e['file']}'))..parent.createSync(recursive: true)).writeAsStringSync('image');
    }
    const listing = 'listings: local/org.example.demo';
    scaffoldCreatives(root: root, appId: 'demo', packageRoot: pkg, ascpubRoot: testAscpubRoot(pkg), listing: listing);
    final project = Project.load(root: root, appId: 'demo', packageRoot: pkg);
    expect(project.app.creatives.ascpub!.listing, listing);
  });

  test('a listing from another bundle is rejected before shelf writes', () {
    final root = Directory.systemTemp.createTempSync('listing_isolation_');
    addTearDown(() => root.deleteSync(recursive: true));
    final dir = Directory(p.join(root.path, 'org.example.other'))..createSync();
    File(p.join(dir.path, 'assets.yaml')).writeAsStringSync('schema: 1\nmanifest: ""\n');
    expect(() => AscpubListing.load(dir.path, bundleId: 'org.example.demo'), throwsA(isA<ConfigError>()));
    final plain = dir.renameSync(p.join(root.path, 'listing'));
    File(p.join(plain.path, 'base.yaml')).writeAsStringSync('bundle_id: org.example.other\n');
    expect(() => AscpubListing.load(plain.path, bundleId: 'org.example.demo'), throwsA(isA<ConfigError>()));
  });
}
