import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';
import 'support/creative_fixture.dart';
import 'support/fixture.dart';

void main() {
  test(
    'portrait screenshot uses its declared recording device, fits safely and exports its group',
    () async {
      final pkg = await packageRoot();
      final definition = '''
id: page
title: A screenshot
targets: [custom_product_page:products]
backdrop: {role: photo, script: A, index: 0}
slots:
  - placements: [app_screenshot]
    spec: screenshot_iphone_6_9
    device: iphone
    display_target: IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE
    text: storeCreativeHeader
    assets:
      - {id: "shot.{storefront}", type: image, frame: {script: W, scene: hold, at: 1}}
''';
      final repo = creativeRepo(pkg, creative: definition);
      addTearDown(repo.delete);
      await synthesizeCreativeTakes(repo);
      final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
      final texts = project.textsFromArb();
      writeCaptionFiles(project.app.captionsDir, texts);
      const runner = SystemProcessRunner();
      final native = await NativeTools.ensure(runner, packageRoot: pkg, binDir: p.join(pkg, '.dart_tool', 'store_preview_test_bin'));
      final composer = CreativeComposer(
        runner: runner,
        app: project.app,
        scripts: project.allScripts,
        manifest: project.manifest(),
        defaults: project.creativeDefaults,
        templates: project.templates,
        tools: native,
        root: repo.root,
        buildDir: project.buildDir,
      );
      final jobs = creativeJobs(project.creatives, project.app, storefronts: [project.app.storefront('en-US')]);
      final files = await composer.render(jobs.single, texts: project.texts('en-US'), distDir: project.distDir, slotId: 'missing-default-device');
      final edl = CreativeEdl.load(files.edl);
      expect(edl.composition.text!.y + edl.composition.text!.h, lessThan(edl.composition.panel.y));
      expect(edl.composition.scale, lessThanOrEqualTo(1));
      final report = await checkCreative(
        jobs.single,
        files,
        app: project.app,
        defaults: project.creativeDefaults,
        templates: project.templates,
        runner: runner,
        workDir: p.join(project.buildDir, 'check', jobs.single.id),
      );
      expect(report.failures, isEmpty);
      final manifest = await buildAssetsManifest(
        jobs,
        app: project.app,
        distDir: project.distDir,
        review: project.review(),
        contract: project.contract,
        generator: {'name': 'store_preview', 'version': 'test'},
        now: () => '2026-10-12T00:00:00Z',
      );
      final entry = (manifest['entries'] as List).single as Map;
      expect(entry['type'], 'screenshot');
      expect(entry['display_target'], 'IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE');
      expect(entry['pixels'], {'width': 1320, 'height': 2868});
      expect((entry['source'] as Map)['real_ui'], false);
      final originalBytes = File(files.file).readAsBytesSync();
      final overflow = Map<String, String>.from(project.texts('en-US'))..['storeCreativeHeader'] = List.filled(80, 'Overflow').join(' ');
      await expectLater(composer.render(jobs.single, texts: overflow, distDir: project.distDir, slotId: 'iphone'), throwsA(isA<ConfigError>()));
      expect(File(files.file).readAsBytesSync(), originalBytes, reason: 'overflow reports failure; no automatic shrink or image repair');
    },
    skip: !Platform.isMacOS,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
