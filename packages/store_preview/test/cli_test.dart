import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';

import 'support/fixture.dart';

void main() {
  late String pkg;
  late FixtureRepo repo;

  setUpAll(() async => pkg = await packageRoot());
  setUp(() => repo = FixtureRepo.create());
  tearDown(() => repo.delete());

  group('template library', () {
    test('every rhythm of every template adds up to its seconds and keeps ≥ 85 % footage', () {
      final templates = loadTemplates(pkg);
      expect(templates.keys, containsAll(['input_wait_result_share', 'hook_problem_result_cta', 'feature_triptych']));
      for (final t in templates.values) {
        for (final MapEntry(key: seconds, value: beats) in t.rhythms.entries) {
          final total = beats.values.fold<double>(0, (a, b) => a + b);
          expect(total, closeTo(seconds, 1e-9), reason: '${t.id} $seconds');
          final nonFootage = beats.entries.where((e) => t.beat(e.key)!.kind != 'scene').fold<double>(0, (a, e) => a + e.value);
          expect((total - nonFootage) / total, greaterThanOrEqualTo(Rules.defaults.minFootageRatio), reason: '${t.id} $seconds');
          expect(beats.entries.where((e) => t.beat(e.key)!.kind == 'card').every((e) => e.value <= Rules.defaults.maxCardSeconds), isTrue);
        }
      }
    });

    test('an app may add a template, not redefine a shipped one', () {
      repo.write('store_preview/demo/templates/feature_triptych.yaml', 'id: feature_triptych\n');
      expect(
        () => loadTemplates(pkg, appTemplatesDir: repo.path('store_preview/demo/templates')),
        throwsA(isA<ConfigError>().having((e) => e.message, 'm', contains('is shipped with the tool'))),
      );
    });
  });

  group('project', () {
    test('the configuration check covers scripts, narrative, compliance, texts, manifest, files, secrets', () {
      repo.manifest(completeManifest());
      final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
      final texts = project.textsFromArb();
      expect(project.checkConfig(texts: texts, prober: const FakeProber()).items, isEmpty);

      repo.write('store_preview/demo/app.yaml', fixtureAppYaml.replaceFirst('assets/icon.png', 'assets/missing.png'));
      repo.write('store_preview/demo/scripts/A.yaml', '$fixtureScriptA# client_secret: "0123456789abcdef0123"\n');
      final broken = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
      final items = broken.checkConfig(texts: texts, prober: const FakeProber()).items;
      expect(items, contains('brand.icon assets/missing.png does not exist'));
      expect(items, contains(endsWith('A.yaml:${'\n'.allMatches(fixtureScriptA).length + 1} holds a secret-named value')));
    });

    test('scripts can be picked; an unknown one fails', () {
      final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg, only: ['A']);
      expect(project.scripts.keys, ['A']);
      expect(() => Project.load(root: repo.root, appId: 'demo', packageRoot: pkg, only: ['C']), throwsA(isA<ConfigError>()));
    });
  });

  group('publishing', () {
    test('the checklist quotes ASO names, the disclosure and the shared poster frame', () {
      final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
      final text = uploadChecklist(project, texts: project.textsFromArb());
      expect(text, contains('| `ja` | Demo: 歌 | 作ろう | `A` | ☐ |'));
      expect(text, contains('"Requires a subscription or credits"'));
      expect(text, contains('`00:00:08:00`: it lies on the finished product in every preview (A: player)'));
      expect(text, contains('| A | 00:00:08:00 | scene `player` |'));
      expect(text, contains('1. `A.mp4` — A song for them (15 s)'));
    });

    test('a run of some scripts still writes the whole checklist and exports every script', () {
      repo.write('store_preview/demo/scripts/B.yaml', fixtureScriptA.replaceFirst('id: A', 'id: B').replaceFirst('title: A song for them', 'title: Second'));
      repo.write('store_preview/demo/app.yaml', '$fixtureAppYaml  listings_dir: listings\n  device_dirs: {iphone: iphone-6.9}\n');
      final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg, only: ['A']);
      expect(project.ordered.map((s) => s.id), ['A']);
      final text = uploadChecklist(project, texts: project.textsFromArb());
      expect(text, contains('2. `B.mp4` — Second (15 s)'));
      for (final l in ['en-US', 'ja']) {
        repo.write('dist/demo/$l/A.mp4', 'a');
        repo.write('dist/demo/$l/B.mp4', 'b');
        repo.write('listings/$l/iphone-6.9/B.mp4', 'old b');
      }
      exportPreviews(project, storefronts: project.app.storefronts);
      expect(File(repo.path('listings/ja/iphone-6.9/B.mp4')).readAsStringSync(), 'b');
    });

    test('export copies each preview into the listing and removes retired ones', () {
      repo.write('store_preview/demo/app.yaml', '$fixtureAppYaml  listings_dir: listings\n  device_dirs: {iphone: iphone-6.9}\n');
      final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
      for (final l in ['en-US', 'ja']) {
        repo.write('dist/demo/$l/A.mp4', 'video $l');
        repo.write('listings/$l/iphone-6.9/C.mp4', 'old');
        repo.write('listings/$l/iphone-6.9/.gitkeep', '');
      }
      final lines = exportPreviews(project, storefronts: project.app.storefronts);
      expect(File(repo.path('listings/ja/iphone-6.9/A.mp4')).readAsStringSync(), 'video ja');
      expect(File(repo.path('listings/ja/iphone-6.9/C.mp4')).existsSync(), isFalse);
      expect(File(repo.path('listings/ja/iphone-6.9/.gitkeep')).existsSync(), isTrue);
      expect(lines, contains('  − listings/ja/iphone-6.9/C.mp4 (no longer a preview)'));
    });

    test('a served localization gets its storefront\'s previews and a checklist row (ADR-0017)', () {
      final yaml = fixtureAppYaml.replaceFirst('vars: {region: US}}', 'vars: {region: US}, serves: [en-GB]}');
      repo.write('store_preview/demo/app.yaml', '$yaml  listings_dir: listings\n  device_dirs: {iphone: iphone-6.9}\n');
      final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
      for (final l in ['en-US', 'ja']) {
        repo.write('dist/demo/$l/A.mp4', 'video $l');
      }
      for (final l in ['en-US', 'en-GB', 'ja']) {
        repo.write('listings/$l/iphone-6.9/.gitkeep', '');
      }
      repo.write('listings/en-GB/iphone-6.9/C.mp4', 'old');
      final lines = exportPreviews(project, storefronts: project.app.storefronts);
      expect(File(repo.path('listings/en-GB/iphone-6.9/A.mp4')).readAsStringSync(), 'video en-US');
      expect(File(repo.path('listings/en-GB/iphone-6.9/C.mp4')).existsSync(), isFalse);
      expect(lines, contains('✓ listings/en-GB/iphone-6.9: A.mp4 (en-US)'));
      expect(Directory(repo.path('dist/demo/en-GB')).existsSync(), isFalse, reason: 'nothing is rendered for a served localization');

      final text = uploadChecklist(project, texts: project.textsFromArb());
      expect(text, contains('| `en-US` | Demo: Songs | Make one | `A` | ☐ |\n| `en-GB` | — | — | `A` (`en-US`\'s) | ☐ |'));

      // Its listing directory belongs to the store tooling like any other.
      Directory(repo.path('listings/en-GB')).deleteSync(recursive: true);
      expect(
        () => exportPreviews(project, storefronts: project.app.storefronts),
        throwsA(isA<ConfigError>().having((e) => e.message, 'm', contains('no listings/en-GB/iphone-6.9'))),
      );
    });

    test('export never invents the listing layout', () {
      repo.write('store_preview/demo/app.yaml', '$fixtureAppYaml  listings_dir: listings\n  device_dirs: {iphone: previews/iphone-6.9}\n');
      final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
      repo.write('listings/en-US/listing.yaml', 'name: x');
      expect(
        () => exportPreviews(project, storefronts: project.app.storefronts),
        throwsA(isA<ConfigError>().having((e) => e.message, 'm', contains('no listings/en-US/previews/iphone-6.9'))),
      );
      expect(Directory(repo.path('listings/en-US/previews')).existsSync(), isFalse);
    });
  });

  group('vendoring', () {
    test('a copy matches its stamp until a file of it changes', () async {
      final template = p.dirname(p.dirname(pkg));
      final app = repo.root;
      final stamp = await vendor(from: template, to: app);
      expect(stamp['files'], greaterThan(30));
      for (final shared in ['docs/store/apple-preview-rules.md', 'docs/store/asset-library-playbook.zh-CN.md', 'scripts/asset_library_check.sh']) {
        expect(File(p.join(app, shared)).existsSync(), isTrue, reason: shared);
      }
      expect(Directory(p.join(app, 'packages', 'store_preview', '.dart_tool')).existsSync(), isFalse);
      expect(vendorDrift(app), isNull);
      File(p.join(app, 'packages', 'store_preview', 'templates', 'feature_triptych.yaml')).writeAsStringSync('edited');
      expect(vendorDrift(app), contains('differs from its stamp'));
      expect(jsonDecode(File(p.join(app, 'packages', 'store_preview', vendorStampName)).readAsStringSync())['sha256'], stamp['sha256']);
    });

    test('this checkout is the template or an untouched copy', () {
      expect(vendorDrift(p.dirname(p.dirname(pkg))), isNull);
    });
  });

  group('cli', () {
    test('help, a missing --app and an unknown app are reported, not thrown', () async {
      expect(await runCli(['--help'], packageRoot: pkg), 0);
      expect(await runCli(['validate'], packageRoot: pkg), 1);
      expect(await runCli(['validate', '--app', 'nope', '--root', repo.root], packageRoot: pkg), 1);
      expect(await runCli(['frobnicate', '--app', 'demo', '--root', repo.root], packageRoot: pkg), 64);
    });

    test('captions exports the texts once they pass', () async {
      expect(await runCli(['captions', '--app', 'demo', '--root', repo.root], packageRoot: pkg), 0);
      final ja = jsonDecode(File(repo.path('store_preview/demo/captions/ja.json')).readAsStringSync()) as Map;
      expect(ja['storePreviewAHook'], '名前から始めよう');
    });
  });
}
