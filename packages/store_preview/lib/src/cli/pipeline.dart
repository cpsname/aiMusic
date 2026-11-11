import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/app.dart';
import '../config/captions.dart';
import '../config/defaults.dart';
import '../core/errors.dart';
import '../core/process.dart';
import '../creative/composer.dart';
import '../creative/validate.dart';
import '../device/recorder.dart';
import '../device/simulator.dart';
import '../driver/backend.dart';
import '../driver/driver.dart';
import '../driver/flutter_driver.dart';
import '../driver/take_recorder.dart';
import '../driver/take_registry.dart';
import '../post/compose.dart';
import '../post/tools.dart';
import '../publish/assets_manifest.dart';
import '../publish/checklist.dart';
import '../publish/creative_release.dart';
import '../validate/report.dart';
import 'project.dart';

typedef Say = void Function(String line);

/// One run over an app's storefronts, scripts and devices.
class Pipeline {
  Pipeline({required this.project, required this.storefronts, required this.slots, required this.say, this.runner = const SystemProcessRunner()});

  final Project project;
  final List<Storefront> storefronts;
  final List<DeviceSlot> slots;
  final Say say;
  final ProcessRunner runner;

  PreviewApp get app => project.app;
  String? _creativeDistDir;
  String get creativeDistDir => _creativeDistDir ?? project.distDir;

  /// The texts from the app's ARBs, checked with everything else that needs
  /// no recording; exported to `captions/`. Stops on any problem.
  Map<String, Map<String, String>> checkConfiguration() {
    final texts = project.textsFromArb();
    project.checkConfig(texts: texts).throwIfAny('${app.id}: the configuration does not pass');
    writeCaptionFiles(app.captionsDir, texts);
    say('✓ configuration: ${project.allScripts.length} script(s), ${app.storefronts.length} storefront(s), manifest complete, texts checked');
    return texts;
  }

  Future<void> prerequisites({required bool recording}) async {
    final needed = [
      'ffmpeg',
      'ffprobe',
      'swiftc',
      if (recording) ...['xcrun', 'flutter', 'plutil'],
    ];
    for (final tool in needed) {
      final found = await runner.run('which', [tool], check: false);
      if (found.exitCode != 0) throw ToolError('$tool not found${tool.startsWith('ff') ? ' (brew install ffmpeg)' : ''}');
    }
    final encoders = await runner.run('ffmpeg', ['-hide_banner', '-encoders']);
    if (!encoders.stdout.contains('aac_at')) throw ToolError('this ffmpeg has no AudioToolbox AAC (aac_at): use a macOS build');
  }

  Future<NativeTools> tools() => NativeTools.ensure(runner, packageRoot: project.packageRoot, binDir: p.join(project.buildDir, 'bin'));

  /// Films every storefront's take on every slot.
  Future<void> record() async {
    final manifest = project.manifest();
    final backend = app.backend == null
        ? null
        : BackendController(
            runner: runner,
            config: app.backend!,
            root: project.root,
            manifest: manifest.path,
            logFile: p.join(project.buildDir, 'backend.log'),
          );
    Directory(project.buildDir).createSync(recursive: true);
    final driver = FlutterIntegrationTestDriver(runner: runner, app: app, root: project.root);
    say('▶ driver: preparing ${app.driver.type}${app.driver.helper == null ? '' : ' and the system-UI helper'}');
    await driver.prepare(DriverContext(root: project.root, buildDir: project.buildDir, slots: slots));
    if (backend != null) {
      say('▶ backend on :${app.backend!.port}');
      await backend.start();
    }
    try {
      for (final slot in slots) {
        final udid =
            Platform.environment['STORE_PREVIEW_SIM_${slot.id.toUpperCase()}'] ??
            await SimulatorController.dedicated(runner, deviceType: slot.simulator, name: recordingSimulatorName(app, slot.simulator));
        final simulator = SimulatorController(runner, udid);
        final recorder = TakeRecorder(app: app, manifest: manifest, simulator: simulator, recorder: ScreenRecorder(runner), driver: driver, backend: backend);
        try {
          for (final s in storefronts) {
            say('▶ record ${s.id} on ${slot.id} ($udid)');
            final registry = TakeRegistry(project.takeDir(s.id, slot.id))..migrateLegacy();
            final run = runStamp(runner.now());
            final files = registry.run(run);
            await recorder.record(
              storefront: s,
              scripts: project.scripts.values,
              device: DeviceTarget(udid: udid, slot: slot),
              files: files,
            );
            registry.register(run, project.scripts.keys);
            say('  ✓ ${files.dir}');
          }
        } finally {
          await simulator.shutdown();
        }
      }
    } finally {
      await backend?.stop();
    }
  }

  /// Composes every preview from the takes.
  Future<void> compose() async {
    final native = await tools();
    final composer = Composer(runner: runner, app: app, manifest: project.manifest(), encoding: project.encoding, tools: native, root: project.root);
    for (final slot in slots) {
      for (final s in storefronts) {
        final registry = TakeRegistry(project.takeDir(s.id, slot.id))..migrateLegacy();
        for (final script in project.ordered) {
          final take = registry.takeFor(script.id, what: '${s.id}/${slot.id}');
          final out = await composer.compose(script: script, storefront: s, slot: slot, take: take, texts: project.texts(s.id), distDir: project.distDir);
          say('  ✓ ${p.relative(out.video, from: project.root)}');
        }
      }
    }
  }

  /// The three layers on every expected output; true when all pass.
  bool validate() {
    final reports = project.checkOutputs(storefronts: storefronts, slots: slots);
    say(reportTable(reports).trimRight());
    final failed = reports.where((r) => !r.ok).length;
    if (failed > 0) {
      say('✗ $failed of ${reports.length} previews fail');
      return false;
    }
    say('✓ ${reports.length} previews pass the spec, compliance and narrative layers');
    return true;
  }

  /// This run's creative jobs: its definitions, its storefronts.
  List<CreativeJob> get creativeJobsOfRun => creativeJobs(project.creatives, app, storefronts: storefronts);

  CreativeFiles creativeFiles(CreativeJob job) => CreativeFiles(distDir: creativeDistDir, id: job.id, storefront: job.storefront, video: job.asset.isVideo);

  /// Removes what `dist/<app>/creative/` holds for no asset of the app's
  /// definitions in any storefront — a retired or renamed asset, its EDL,
  /// poster and sheets — so the directory holds what the definitions make and
  /// a reviewer meets no retired sheet. A run of some definitions or
  /// storefronts keeps every other current asset. Returns the files removed.
  List<String> pruneRetiredCreatives() {
    final dir = Directory(p.join(creativeDistDir, 'creative'));
    if (!dir.existsSync()) return const [];
    final jobs = creativeJobs(project.allCreatives, app, storefronts: app.storefronts);
    final sheets = p.join(dir.path, 'sheets');
    final keep = {
      for (final j in jobs) ...[
        creativeFiles(j).file,
        creativeFiles(j).edl,
        if (j.asset.isVideo) creativeFiles(j).poster,
        for (final suffix in [
          '.png',
          '.txt',
          if (j.asset.isVideo) ...['.first2s.png', '.first2s.txt'],
        ])
          p.join(sheets, '${j.asset.id.replaceAll('{storefront}', 'all')}$suffix'),
      ],
    };
    final retired = [
      for (final f in dir.listSync(recursive: true).whereType<File>())
        if (!keep.contains(p.normalize(f.path))) f.path,
    ]..sort();
    for (final f in retired) {
      File(f).deleteSync();
    }
    return retired;
  }

  /// Renders this run's creative assets from the takes, then a contact sheet
  /// per asset (`dist/<app>/creative/sheets/`) for the human review; first
  /// removes the outputs of retired assets.
  Future<void> renderCreatives() async {
    for (final f in pruneRetiredCreatives()) {
      say('  − ${p.relative(f, from: project.root)} (no asset of the definitions)');
    }
    final native = await tools();
    final composer = CreativeComposer(
      runner: runner,
      app: app,
      scripts: project.allScripts,
      manifest: project.manifest(),
      defaults: project.creativeDefaults,
      templates: project.templates,
      tools: native,
      root: project.root,
      buildDir: project.buildDir,
    );
    final jobs = creativeJobsOfRun;
    for (final job in jobs) {
      final source = job.storefront ?? universalSource(job.definition, app);
      final out = await composer.render(job, texts: project.texts(source), distDir: creativeDistDir, slotId: project.creativeSlot);
      say('  ✓ ${p.relative(out.file, from: project.root)}');
    }
    await contactSheets(jobs);
  }

  /// One image per asset with every storefront's version (a video's poster
  /// frame), in storefront order — what a reviewer looks at.
  Future<void> contactSheets(List<CreativeJob> jobs) async {
    final dir = Directory(p.join(creativeDistDir, 'creative', 'sheets'))..createSync(recursive: true);
    final byAsset = <String, List<CreativeJob>>{};
    for (final j in jobs) {
      (byAsset['${j.definition.id}|${j.asset.id}'] ??= []).add(j);
    }
    for (final group in byAsset.values) {
      final files = [
        for (final j in group)
          if (File(j.asset.isVideo ? creativeFiles(j).poster : creativeFiles(j).file).existsSync())
            j.asset.isVideo ? creativeFiles(j).poster : creativeFiles(j).file,
      ];
      if (files.isEmpty) continue;
      final name = group.first.asset.id.replaceAll('{storefront}', 'all');
      final out = p.join(dir.path, '$name.png');
      const tileWidth = 960;
      const columns = 4;
      final first = project.creativeDefaults.specs[group.first.slot.spec]!.rule(group.first.asset.type)!.size;
      final tileHeight = (tileWidth * first.renderHeight / first.renderWidth / 2).round() * 2;
      final inputs = [
        for (final f in files) ...['-i', f],
      ];
      final scaled = [for (var i = 0; i < files.length; i++) '[$i:v]scale=$tileWidth:$tileHeight,setsar=1[t$i]'];
      final layout = [for (var i = 0; i < files.length; i++) '${(i % columns) * tileWidth}_${(i ~/ columns) * tileHeight}'].join('|');
      final graph = files.length == 1
          ? '[0:v]scale=$tileWidth:$tileHeight,setsar=1[out]'
          : '${scaled.join(';')};${[for (var i = 0; i < files.length; i++) '[t$i]'].join()}xstack=inputs=${files.length}:layout=$layout:fill=black[out]';
      await runner.run('ffmpeg', ['-v', 'error', '-y', ...inputs, '-filter_complex', graph, '-map', '[out]', '-frames:v', '1', out]);
      File(p.join(dir.path, '$name.txt')).writeAsStringSync('${[for (final j in group) j.storefront ?? 'universal'].join('\n')}\n');
    }
    say('  ✓ ${p.relative(dir.path, from: project.root)} (one sheet per asset, storefronts left to right, top to bottom)');
    await openingSheets(byAsset.values, dir.path);
  }

  /// The muted opening a reviewer reads: per video asset, one row per
  /// storefront of the frames at 0, 0.5, 1, 1.5 and 2 s
  /// (`<asset>.first2s.png`) — the search results play muted and cannot be
  /// unmuted, so these two seconds must explain themselves.
  Future<void> openingSheets(Iterable<List<CreativeJob>> groups, String dir) async {
    const times = [0.0, 0.5, 1.0, 1.5, 2.0];
    const tileWidth = 640;
    for (final group in groups.where((g) => g.first.asset.isVideo)) {
      final files = [
        for (final j in group)
          if (File(creativeFiles(j).file).existsSync()) creativeFiles(j).file,
      ];
      if (files.isEmpty) continue;
      final size = project.creativeDefaults.specs[group.first.slot.spec]!.rule('video')!.size;
      final tileHeight = (tileWidth * size.renderHeight / size.renderWidth / 2).round() * 2;
      final inputs = <String>[];
      final scaled = <String>[];
      final positions = <String>[];
      var n = 0;
      for (final (row, f) in files.indexed) {
        for (final (col, t) in times.indexed) {
          inputs.addAll(['-ss', t.toStringAsFixed(2), '-i', f]);
          scaled.add('[$n:v]scale=$tileWidth:$tileHeight,setsar=1[t$n]');
          positions.add('${col * tileWidth}_${row * tileHeight}');
          n++;
        }
      }
      final graph = '${scaled.join(';')};${[for (var i = 0; i < n; i++) '[t$i]'].join()}xstack=inputs=$n:layout=${positions.join('|')}:fill=black[out]';
      final name = group.first.asset.id.replaceAll('{storefront}', 'all');
      await runner.run('ffmpeg', [
        '-v',
        'error',
        '-y',
        ...inputs,
        '-filter_complex',
        graph,
        '-map',
        '[out]',
        '-frames:v',
        '1',
        p.join(dir, '$name.first2s.png'),
      ]);
      File(
        p.join(dir, '$name.first2s.txt'),
      ).writeAsStringSync('rows: ${[for (final j in group) j.storefront ?? 'universal'].join(', ')}\ncolumns: ${times.map((t) => '${t}s').join(', ')}\n');
    }
  }

  /// The three layers on this run's creative assets; true when all pass.
  Future<bool> validateCreatives() async {
    final reports = <CreativeReport>[];
    for (final job in creativeJobsOfRun) {
      reports.add(
        await checkCreative(
          job,
          creativeFiles(job),
          app: app,
          defaults: project.creativeDefaults,
          templates: project.templates,
          runner: runner,
          workDir: p.join(project.buildDir, 'creative', 'check', job.id),
        ),
      );
    }
    say(creativeTable(reports).trimRight());
    final failed = reports.where((r) => !r.ok).length;
    if (failed > 0) {
      say('✗ $failed of ${reports.length} creative assets fail');
      return false;
    }
    say('✓ ${reports.length} creative assets pass the spec, compliance and narrative layers');
    return true;
  }

  String get assetsManifestPath => p.join(creativeDistDir, assetsManifestName);
  bool _manifestNeedsReview = false;

  /// Publish a new local generation only after all checks succeed. Initial
  /// partial runs can accumulate files (without a delivery manifest), as before.
  Future<bool> produceCreatives() async {
    final run = CreativeReleaseRun.begin(project.distDir, app: app.id, bundleId: app.bundleId);
    final hadManifest = File(project.assetsManifestPath).existsSync();
    _creativeDistDir = run.stage.path;
    try {
      if (run.archive != null) say('  ✓ previous delivery preserved at ${p.relative(run.archive!, from: project.root)}');
      await renderCreatives();
      if (!await validateCreatives()) return false;
      final complete = await writeAssetsManifest(preservePrevious: false);
      if (complete || (!hadManifest && !File(assetsManifestPath).existsSync())) {
        run.commit();
      } else if (_manifestNeedsReview) {
        run.commit(awaitingReview: true);
        say(
          '✗ screenshots await human review: new working files have NO delivery manifest; previous delivery is in ${run.archive}. '
          'Review the new contact sheets, record the verdict, then run manifest and asset-library.',
        );
      } else if (hadManifest) {
        say('✗ incomplete generation: previous delivery kept; render the complete set');
      }
      return complete;
    } finally {
      _creativeDistDir = null;
      run.close();
    }
  }

  /// Writes `dist/<app>/assets-manifest.json` over every asset of the app
  /// (all definitions, all storefronts) and checks it against the contract
  /// and the files; false (and nothing written) when an asset is missing.
  Future<bool> writeAssetsManifest({bool preservePrevious = true}) async {
    final lock = preservePrevious ? lockCreativeRelease(creativeDistDir, app: app.id) : null;
    try {
      return await _writeAssetsManifest(preservePrevious: preservePrevious);
    } finally {
      lock?.closeSync();
    }
  }

  Future<bool> _writeAssetsManifest({required bool preservePrevious}) async {
    _manifestNeedsReview = false;
    final jobs = creativeJobs(project.allCreatives, app, storefronts: app.storefronts);
    final Map<String, Object?> manifest;
    try {
      if (preservePrevious) archiveCreativeRelease(creativeDistDir, app: app.id, bundleId: app.bundleId);
      manifest = await buildAssetsManifest(
        jobs,
        app: app,
        distDir: creativeDistDir,
        review: project.review(),
        contract: project.contract,
        generator: await generatorInfo(packageRoot: project.packageRoot),
        now: () => '${DateTime.now().toUtc().toIso8601String().split('.').first}Z',
      );
    } on ConfigError catch (e) {
      say('✗ ${p.relative(assetsManifestPath, from: project.root)} not written: ${e.message}');
      return false;
    }
    final file = File(assetsManifestPath);
    final staged = File('$assetsManifestPath.next');
    staged.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(manifest)}\n', flush: true);
    final reviewIssues = screenshotMajority((manifest['entries']! as List).cast<Map<String, Object?>>());
    if (reviewIssues.isNotEmpty) {
      final issues = checkAssetsManifest(staged.path, contract: project.contract);
      _manifestNeedsReview = issues.length == reviewIssues.length && issues.every(reviewIssues.contains);
    }
    if (!checkManifest(path: staged.path)) {
      staged.deleteSync();
      return false;
    }
    staged.renameSync(file.path);
    return true;
  }

  /// The written manifest against the contract and its files.
  bool checkManifest({String? path}) {
    final checked = path ?? assetsManifestPath;
    final problems = checkAssetsManifest(checked, contract: project.contract);
    final rel = p.relative(checked, from: project.root);
    if (problems.isEmpty) {
      final data = jsonDecode(File(checked).readAsStringSync()) as Map;
      if ((data['app'] as Map)['bundle_id'] != app.bundleId || (data['app'] as Map)['store_preview_app'] != app.id) {
        problems.add('manifest belongs to another app; expected ${app.id} (${app.bundleId})');
      }
      final all = creativeJobs(project.allCreatives, app, storefronts: app.storefronts);
      // Every entry the definitions make: each rendered asset under its own
      // storefront, and under each localization that storefront serves
      // (an alias: the same files, derived from the rendered entry).
      final entriesMade = <String, ({CreativeJob job, String? locale, String? parent})>{
        for (final j in all) j.id: (job: j, locale: j.storefront, parent: null),
        for (final a in creativeAliases(all, app)) a.id: (job: a.job, locale: a.locale, parent: a.job.id),
      };
      final seen = <String>{};
      for (final entry in data['entries'] as List) {
        final e = entry as Map;
        final id = e['id'] as String;
        seen.add(id);
        final made = entriesMade[id];
        if (made == null) {
          problems.add('$id is not defined by this app');
          continue;
        }
        final job = made.job;
        if (e['locale'] != made.locale || e['file'] != p.relative(creativeFiles(job).file, from: creativeDistDir)) {
          problems.add('$id: file or locale differs from this app definition');
        }
        if (made.parent != null && e['derived_from'] != made.parent) {
          problems.add('$id: serves ${made.locale} with ${made.parent}\'s files, so it derives from ${made.parent}');
        }
        final expected = {
          for (final placement in job.slot.placements)
            for (final target in job.definition.targets) '$placement|$target',
        };
        final actual = {for (final intent in e['placement_intents'] as List) '${intent['placement']}|${intent['target']}'};
        if (expected.length != actual.length || !expected.containsAll(actual)) problems.add('$id: placement intents differ from this app definition');
        if ((e['source'] as Map)['real_ui'] == true && project.review().realUi(job.slot, job.asset, files: creativeFiles(job)) != true) {
          problems.add('$id: real_ui has no current human review of these rendered bytes');
        }
      }
      for (final id in entriesMade.keys.where((id) => !seen.contains(id))) {
        problems.add('$id is missing from the manifest');
      }
    }
    if (problems.isNotEmpty) {
      say('✗ $rel:\n${problems.map((x) => '  ✗ $x').join('\n')}');
      return false;
    }
    final entries = (jsonDecode(File(checked).readAsStringSync()) as Map)['entries'] as List;
    final reviewed = entries.where((e) => ((e as Map)['source'] as Map)['real_ui'] == true).length;
    say(
      '✓ $rel: ${entries.length} entries match the contract (${project.contract.describe()}) and their files; '
      'real_ui from the review: $reviewed of ${entries.length}',
    );
    return true;
  }

  void checklist(Map<String, Map<String, String>> texts) {
    final text = uploadChecklist(project, texts: texts);
    final file = File(p.join(project.distDir, 'upload-checklist.md'))..parent.createSync(recursive: true);
    file.writeAsStringSync(text);
    say('✓ ${p.relative(file.path, from: project.root)}');
    final doc = app.publish.checklistDoc;
    if (doc != null) {
      File(p.join(project.root, doc))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(text);
      say('✓ $doc');
    }
  }
}
