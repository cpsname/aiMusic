import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/app.dart';
import '../core/errors.dart';
import '../core/process.dart';
import '../plan/plan.dart';
import 'driver.dart';
import 'simulator_preflight.dart';
import 'take.dart';

/// The UIDeviceFamily values the app's Runner targets declare
/// (`TARGETED_DEVICE_FAMILY` in project.pbxproj): the intersection over every
/// build configuration that sets it, `{1}` when none does.
Set<int> declaredDeviceFamilies(String pbxproj) {
  Set<int>? families;
  for (final m in RegExp(r'TARGETED_DEVICE_FAMILY = "?([0-9,]+)"?;').allMatches(pbxproj)) {
    final values = m.group(1)!.split(',').map(int.parse).toSet();
    families = families == null ? values : families.intersection(values);
  }
  return families ?? {1};
}

/// An `.xctestrun` (as JSON) rewritten to attach to the app the recording
/// launched: only the UI test target, hosted by its own runner app, with no
/// dependency on (and so no reinstall of) the app.
Map<String, Object?> attachXctestrun(Map<String, Object?> xctestrun, {required String uiTarget}) {
  final ui = xctestrun[uiTarget];
  if (ui is! Map) throw ToolError('the xctestrun has no target $uiTarget (${xctestrun.keys.join(', ')})');
  final target = ui.cast<String, Object?>();
  final dependent = (target['DependentProductPaths'] as List? ?? const []).map((e) => '$e');
  return {
    for (final e in xctestrun.entries)
      if (e.key.startsWith('__')) e.key: e.value,
    uiTarget: {
      ...target,
      'UITargetAppPath': '__TESTROOT__/Debug-iphonesimulator/$uiTarget-Runner.app',
      'DependentProductPaths': [
        for (final d in dependent)
          if (!d.endsWith('/Runner.app')) d,
      ],
    },
  };
}

/// Drives a Flutter app with its `integration_test` entry (which runs
/// `store_preview_driver`), and serves system UI with the XCUITest helper
/// (native/ios/StorePreviewHelper.swift) when the app declares one.
class FlutterIntegrationTestDriver implements AppDriver {
  FlutterIntegrationTestDriver({required this.runner, required this.app, required this.root});

  final ProcessRunner runner;
  final PreviewApp app;
  final String root;

  String? _xctestrun;
  String? _bundleId;

  List<String> get _defines => [if (app.driver.dartDefinesFile != null) '--dart-define-from-file=${app.driver.dartDefinesFile}'];

  @override
  Future<void> prepare(DriverContext context) async {
    final pbxproj = File(p.join(root, 'ios', 'Runner.xcodeproj', 'project.pbxproj'));
    final families = pbxproj.existsSync() ? declaredDeviceFamilies(pbxproj.readAsStringSync()) : {1};
    for (final slot in context.slots) {
      if (!families.contains(slot.deviceFamily)) {
        throw ConfigError(
          '${app.id} does not ship for the ${slot.id} slot (TARGETED_DEVICE_FAMILY ${families.join(',')} lacks '
          '${slot.deviceFamily}): a recording would film a compatibility window. Record --devices '
          '${app.devices.where((d) => d != slot.id).join(',')} or ship the app for it first.',
        );
      }
    }
    final helper = app.driver.helper;
    if (helper == null) {
      await preflightSimulatorBuild(runner: runner, app: app, root: root);
      return;
    }
    await runner.run('flutter', ['build', 'ios', '--config-only', '--simulator', '--debug', ..._defines], workingDirectory: root);
    await preflightSimulatorBuild(runner: runner, app: app, root: root);
    final derived = p.join(context.buildDir, 'xcode');
    final build = await runner.run(
      'xcodebuild',
      [
        'build-for-testing', '-workspace', helper.workspace, '-scheme', helper.scheme, '-configuration', 'Debug', //
        '-destination', 'generic/platform=iOS Simulator', 'ARCHS=arm64', 'ONLY_ACTIVE_ARCH=NO', '-derivedDataPath', derived,
      ],
      workingDirectory: root,
      check: false,
    );
    File(p.join(context.buildDir, 'xcode.log')).writeAsStringSync('${build.stdout}\n${build.stderr}');
    if (build.exitCode != 0) throw ToolError('xcodebuild build-for-testing failed (see ${p.join(context.buildDir, 'xcode.log')})');
    final products = p.join(derived, 'Build', 'Products');
    final source = Directory(
      products,
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.xctestrun') && !p.basename(f.path).startsWith('attach')).firstOrNull;
    if (source == null) throw ToolError('no .xctestrun in $products');
    final json = jsonDecode((await runner.run('plutil', ['-convert', 'json', '-o', '-', source.path])).stdout) as Map<String, Object?>;
    final attach = attachXctestrun(json, uiTarget: helper.test.split('/').first);
    final jsonFile = p.join(products, 'attach.json');
    File(jsonFile).writeAsStringSync(jsonEncode(attach));
    _xctestrun = p.join(products, 'attach.xctestrun');
    await runner.run('plutil', ['-convert', 'xml1', jsonFile, '-o', _xctestrun!]);
    final info = p.join(products, 'Debug-iphonesimulator', 'Runner.app', 'Info.plist');
    _bundleId = (await runner.run('plutil', ['-extract', 'CFBundleIdentifier', 'raw', info])).stdout.trim();
    if (_bundleId != app.bundleId) {
      throw ConfigError('app.yaml bundle_id is ${app.bundleId}, the built app is $_bundleId');
    }
  }

  @override
  Future<DriverSession> launch({required DeviceTarget device, required Storefront storefront, required RecordingPlan plan, required TakeFiles files}) async {
    if (plan.needsHelper && (app.driver.helper == null || _xctestrun == null)) {
      throw ConfigError('${app.id}: the scripts use system UI (pickPhotos / alert.done) but app.yaml declares no driver.helper');
    }
    final test = await runner.start(
      'flutter',
      ['test', app.driver.target, '-d', device.udid, ..._defines, '--dart-define=STORE_PREVIEW_PLAN=${plan.encoded}'],
      workingDirectory: root,
      logFile: files.driverLog,
    );
    return _FlutterSession(this, device, plan, files, test);
  }
}

class _FlutterSession implements DriverSession {
  _FlutterSession(this.driver, this.device, this.plan, this.files, this.test);

  final FlutterIntegrationTestDriver driver;
  final DeviceTarget device;
  final RecordingPlan plan;
  final TakeFiles files;
  final RunningProcess test;
  RunningProcess? _helper;

  ProcessRunner get _runner => driver.runner;

  String _log() => File(files.driverLog).existsSync() ? File(files.driverLog).readAsStringSync() : '';

  @override
  Future<void> waitStable() async {
    final ok = await pollUntil(
      _runner,
      () => _log().contains('"edge":"ready"') || _log().contains('"edge":"failed"'),
      timeout: const Duration(minutes: 10),
      step: const Duration(milliseconds: 500),
    );
    if (!ok || !_log().contains('"edge":"ready"')) throw ToolError('the app never reported ready (see ${files.driverLog})');
  }

  Future<void> _startHelper() async {
    final helper = driver.app.driver.helper!;
    _helper = await _runner.start(
      'xcodebuild',
      ['test-without-building', '-xctestrun', driver._xctestrun!, '-destination', 'id=${device.udid}', '-only-testing:${helper.test}'],
      workingDirectory: driver.root,
      logFile: files.helperLog,
      environment: {
        'TEST_RUNNER_STORE_PREVIEW_PICKS': plan.picks.join(','),
        'TEST_RUNNER_STORE_PREVIEW_BUNDLE_ID': driver._bundleId!,
        'TEST_RUNNER_STORE_PREVIEW_SYNC_DIR': files.sync,
        'TEST_RUNNER_STORE_PREVIEW_ALLOW_NOTIFICATIONS': plan.allowNotifications ? '1' : '0',
      },
    );
  }

  @override
  Future<List<SceneMark>> run() async {
    var exited = false;
    int? code;
    test.exitCode.then((c) {
      exited = true;
      code = c;
    }).ignore();
    final deadline = _runner.now() + driver.app.driver.timeoutSeconds * 1000;
    var stopped = '';
    while (!exited) {
      final log = _log();
      if (plan.needsHelper && _helper == null && log.contains('"edge":"ready"')) await _startHelper();
      if (log.contains('"edge":"failed"')) {
        // A failed test does not end by itself (the app's error hooks hold
        // it): stop it once the failure is in the log.
        await _runner.sleep(const Duration(seconds: 2));
        stopped = 'a step failed';
        await test.terminate();
        break;
      }
      if (_runner.now() > deadline) {
        stopped = 'the take ran past ${driver.app.driver.timeoutSeconds} s';
        await test.terminate();
        break;
      }
      await _runner.sleep(const Duration(seconds: 1));
    }
    code ??= await test.exitCode;
    final marks = parseMarks(_log());
    final failed = marks.where((m) => m.edge == 'failed').firstOrNull;
    if (failed != null || code != 0 || !marks.any((m) => m.edge == 'done')) {
      final why = failed?.error ?? (stopped.isNotEmpty ? stopped : 'the test exited $code without a done mark');
      throw ToolError(
        'the recording run failed: ${why.length > 600 ? '${why.substring(0, 600)}…' : why} (see ${files.driverLog}'
        '${_helper == null ? '' : ' and ${files.helperLog}'})',
      );
    }
    return marks;
  }

  @override
  Future<void> close() async {
    final helper = _helper;
    if (helper == null) return;
    // The helper ends after its sessions; one still waiting once the take
    // is over has nothing left to serve.
    await helper.exitCode.timeout(
      const Duration(seconds: 15),
      onTimeout: () async {
        await helper.terminate();
        return helper.exitCode.timeout(const Duration(seconds: 10), onTimeout: () => -1);
      },
    );
    _helper = null;
  }
}
