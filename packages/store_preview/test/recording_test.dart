import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';

import 'support/fake_runner.dart';
import 'support/fixture.dart';

void main() {
  late Map<String, DeviceSlot> slots;
  late FixtureRepo repo;
  late PreviewApp app;
  late Map<String, PreviewScript> scripts;
  late Manifest manifest;

  setUpAll(() async => slots = loadSlots(await packageRoot()));

  setUp(() {
    repo = FixtureRepo.create(
      scripts: {
        'A': fixtureScriptA,
        'B': fixtureScriptA
            .replaceFirst('id: A', 'id: B')
            .replaceFirst('requires:\n  - {role: song, vars: [recipient]}\n  - {role: photo, count: 2}', 'requires: []')
            .replaceFirst('setup:\n  - {do: use, role: song}', 'ends_on_system_ui: true\nsetup:\n  - {do: use, role: song, script: A}')
            .replaceFirst('{do: tap, key: share}', '{do: pickPhotos, count: 2}, {do: waitSync, name: alert.done}')
            .replaceFirst('    beat: share\n', '    beat: share\n    shoot_order: -1\n'),
      },
    );
    app = PreviewApp.load(root: repo.root, id: 'demo', slots: slots);
    scripts = loadScripts(app.scriptsDir);
    repo.manifest(completeManifest());
    manifest = Manifest.load(app.manifestPath);
  });
  tearDown(() => repo.delete());

  test('default recording simulators are isolated by bundle and app configuration', () {
    final first = recordingSimulatorName(app, 'iPhone');
    repo.write('store_preview/demo/app.yaml', fixtureAppYaml.replaceFirst('com.example.demo', 'com.example.other'));
    final other = PreviewApp.load(root: repo.root, id: 'demo', slots: slots);
    expect(recordingSimulatorName(other, 'iPhone'), isNot(first));
    repo.write('store_preview/variant/app.yaml', fixtureAppYaml.replaceFirst('app: demo', 'app: variant'));
    final variant = PreviewApp.load(root: repo.root, id: 'variant', slots: slots);
    expect(recordingSimulatorName(variant, 'iPhone'), isNot(first));
    expect(recordingSimulatorName(app, 'iPad'), isNot(first));
  });

  group('plan', () {
    RecordingPlan compile(String storefront) =>
        compilePlan(app: app, storefront: app.storefront(storefront), scripts: scripts.values, manifest: manifest, syncDir: '/sync');

    test('a use step selects media and expands to on_use; variables come from it', () {
      final plan = compile('ja');
      final runs = (plan.json['runs']! as List).cast<Map<String, Object?>>();
      final setup = runs.first['setup']! as List;
      expect(setup, [
        {
          'do': 'admin',
          'path': 'next',
          'body': {'script': 'A', 'locale': 'ja'},
        },
      ]);
      final type = ((runs.first['scenes']! as List).first as Map)['steps'] as List;
      expect(type.single, {'do': 'type', 'key': 'name', 'text': 'Alex'});
      expect(plan.json['admin'], 'http://localhost:8799/admin/');
      expect(plan.json['ready'], {'key': 'home'});
      expect(plan.json['prelude'], [
        {'do': 'waitFor', 'key': 'home'},
      ]);
    });

    test('scripts that end on system UI go last; scenes run in filming order', () {
      final plan = compile('en-US');
      final runs = (plan.json['runs']! as List).cast<Map<String, Object?>>();
      expect(runs.map((r) => r['script']), ['A', 'B']);
      expect(((runs.last['scenes']! as List).cast<Map<String, Object?>>()).map((s) => s['id']), ['share', 'name', 'wait', 'player']);
      final player = (runs.first['scenes']! as List).cast<Map<String, Object?>>().firstWhere((s) => s['id'] == 'player');
      expect(player['locked'], isTrue);
      expect(player['follow'], 'song');
    });

    test('picker sessions are numbered; the helper is awaited and answers the prompt', () {
      final plan = compile('en-US');
      expect(plan.picks, ['2@0']);
      expect(plan.allowNotifications, isTrue);
      expect(plan.needsHelper, isTrue);
      expect(plan.json['afterReady'], [
        {'do': 'waitHelper'},
      ]);
      final share = ((plan.json['runs']! as List).last as Map)['scenes'] as List;
      expect(((share.first as Map)['steps'] as List).first, {'do': 'pickPhotos', 'count': 2, 'session': 0});
    });

    test('a whole-string integer variable becomes an integer; an unknown one fails', () {
      repo.manifest([
        for (final e in completeManifest())
          if (e['role'] == 'song')
            {
              ...e,
              'vars': {'recipient': 'Alex', 'chorus_index': '2'},
            }
          else
            e,
      ]);
      repo.write(
        'store_preview/demo/scripts/A.yaml',
        fixtureScriptA.replaceFirst('{do: type, key: name, text: "{recipient}"}', '{do: tap, key: sections, index: "{chorus_index}"}'),
      );
      final plan = compilePlan(
        app: app,
        storefront: app.storefront('ja'),
        scripts: [loadScripts(app.scriptsDir)['A']!],
        manifest: Manifest.load(app.manifestPath),
        syncDir: '/s',
      );
      final step = ((((plan.json['runs']! as List).first as Map)['scenes'] as List).first as Map)['steps'] as List;
      expect(step.single, {'do': 'tap', 'key': 'sections', 'index': 2});

      repo.write('store_preview/demo/scripts/A.yaml', fixtureScriptA.replaceFirst('"{recipient}"', '"{nickname}"'));
      expect(
        () => compilePlan(app: app, storefront: app.storefront('ja'), scripts: [loadScripts(app.scriptsDir)['A']!], manifest: manifest, syncDir: '/s'),
        throwsA(isA<ConfigError>().having((e) => e.message, 'm', contains('no value for {nickname}'))),
      );
    });

    test('storefront vars fill what the media does not carry', () {
      repo.write('store_preview/demo/scripts/A.yaml', fixtureScriptA.replaceFirst('"{recipient}"', '"{region}-{storefront}"'));
      final plan = compilePlan(app: app, storefront: app.storefront('ja'), scripts: [loadScripts(app.scriptsDir)['A']!], manifest: manifest, syncDir: '/s');
      final step = ((((plan.json['runs']! as List).first as Map)['scenes'] as List).first as Map)['steps'] as List;
      expect((step.single as Map)['text'], 'JP-ja');
    });
  });

  group('simulator', () {
    test('prepares a clean device in the storefront\'s language, as record.sh did', () async {
      final runner = FakeRunner();
      final devices = Directory.systemTemp.createTempSync('sims').path;
      addTearDown(() => Directory(devices).deleteSync(recursive: true));
      Directory(p.join(devices, 'U1', 'data', 'Media', 'DCIM')).createSync(recursive: true);
      final sim = SimulatorController(runner, 'U1', devicesRoot: devices);
      await sim.prepare(storefront: app.storefront('ja'), setup: app.simulator, photos: ['/m/2.png', '/m/1.png'], workDir: p.join(devices, 'take'));
      expect(runner.calls.take(5), [
        'xcrun simctl shutdown U1',
        'xcrun simctl erase U1',
        'xcrun simctl boot U1',
        'xcrun simctl bootstatus U1 -b',
        'xcrun simctl spawn U1 defaults write -g AppleLanguages -array ja',
      ]);
      expect(runner.calls, contains('xcrun simctl spawn U1 defaults write -g AppleLocale -string ja_JP'));
      expect(runner.calls, contains('xcrun simctl spawn U1 defaults write com.apple.keyboard.preferences MultilingualKeyboardTip -bool true'));
      expect(runner.calls.where((c) => c.contains('-bool true')), hasLength(6));
      expect(Directory(p.join(devices, 'U1', 'data', 'Media', 'DCIM')).existsSync(), isFalse);
      expect(runner.calls, contains('xcrun simctl ui U1 appearance light'));
      expect(runner.calls.firstWhere((c) => c.contains('status_bar')), contains('--time 9:41'));
      final adds = runner.calls.where((c) => c.contains('addmedia')).toList();
      expect(adds, hasLength(2));
      expect(adds.first, endsWith('/take/photos/1.jpg'));
      expect(runner.calls.firstWhere((c) => c.startsWith('ffmpeg')), contains('-i /m/2.png -map_metadata -1'));
    });

    test('library photos: the role\'s images of the storefront, imported last first', () {
      expect(libraryPhotos(app, manifest, app.storefront('ja')).map(p.basename), ['photo.A.ja.2.png', 'photo.A.ja.1.png']);
    });

    test('a dedicated simulator is created on the newest iOS runtime when missing', () async {
      final runner = FakeRunner(
        answers: {
          'list devices': ProcessOutcome(
            0,
            jsonEncode({
              'devices': {'r': <Object>[]},
            }),
            '',
          ),
          'list runtimes': ProcessOutcome(
            0,
            jsonEncode({
              'runtimes': [
                {'platform': 'iOS', 'isAvailable': true, 'version': '26.5', 'identifier': 'ios-26-5'},
                {'platform': 'iOS', 'isAvailable': true, 'version': '26.10', 'identifier': 'ios-26-10'},
              ],
            }),
            '',
          ),
          'list devicetypes': ProcessOutcome(
            0,
            jsonEncode({
              'devicetypes': [
                {'name': 'iPhone 17 Pro Max', 'identifier': 'type-17pm'},
              ],
            }),
            '',
          ),
          'simctl create': const ProcessOutcome(0, 'NEW-UDID\n', ''),
        },
      );
      final udid = await SimulatorController.dedicated(runner, deviceType: 'iPhone 17 Pro Max', name: 'Store Preview (iPhone)');
      expect(udid, 'NEW-UDID');
      expect(runner.calls.last, 'xcrun simctl create Store Preview (iPhone) type-17pm ios-26-10');
    });
  });

  group('recorder and take', () {
    test('the recorder starts once "Recording started" is logged and stops on SIGINT', () async {
      final runner = FakeRunner(onStart: (cmd, log, process) => File(log).writeAsStringSync('1700000000123 Recording started\n'));
      final dir = Directory.systemTemp.createTempSync('rec').path;
      addTearDown(() => Directory(dir).deleteSync(recursive: true));
      final recording = await ScreenRecorder(runner).start(udid: 'U1', out: '$dir/r.mov', logFile: '$dir/rec.log');
      expect(runner.calls.single, 'start xcrun simctl io U1 recordVideo --codec=h264 --force $dir/r.mov');
      await recording.stop();
      expect(runner.started.single.signals, ['INT']);
    });

    test('a take pairs scene edges and keeps the playback position', () {
      final take = parseTake(
        recLog: 'x note\n1000 Recording started\n',
        testLog: [
          'noise',
          '$markTag{"t":1500,"edge":"ready"}',
          '$markTag{"t":2000,"script":"A","scene":"name","edge":"start"}',
          '$markTag{"t":5000,"script":"A","scene":"name","edge":"end"}',
          '$markTag{"t":6000,"script":"A","scene":"player","edge":"start","pos":41.25}',
          '$markTag{"t":11500,"script":"A","scene":"player","edge":"end"}',
        ].join('\n'),
      );
      expect(take.at(take.window('A', 'name').startMs), 1.0);
      expect(take.window('A', 'player').position, 41.25);
      expect(() => take.window('A', 'share'), throwsA(isA<ConfigError>()));
    });
  });

  group('flutter driver', () {
    test('device families come from TARGETED_DEVICE_FAMILY; iPad is refused when missing', () async {
      expect(declaredDeviceFamilies('A = 1;\nTARGETED_DEVICE_FAMILY = 1;\nTARGETED_DEVICE_FAMILY = "1,2";'), {1});
      expect(declaredDeviceFamilies('TARGETED_DEVICE_FAMILY = "1,2";'), {1, 2});
      expect(declaredDeviceFamilies(''), {1});
      repo.write('ios/Runner.xcodeproj/project.pbxproj', 'TARGETED_DEVICE_FAMILY = 1;');
      final driver = FlutterIntegrationTestDriver(runner: FakeRunner(), app: app, root: repo.root);
      await expectLater(
        driver.prepare(DriverContext(root: repo.root, buildDir: repo.path('build'), slots: [slots['ipad']!])),
        throwsA(isA<ConfigError>().having((e) => e.message, 'm', contains('does not ship for the ipad slot'))),
      );
    });

    test('the attach xctestrun keeps only the UI target, hosted by its runner, without the app', () {
      final out = attachXctestrun({
        '__xctestrun_metadata__': {'FormatVersion': 1},
        'RunnerTests': {'x': 1},
        'RunnerUITests': {
          'TestHostPath': 'h',
          'DependentProductPaths': ['__TESTROOT__/Debug-iphonesimulator/Runner.app', '__TESTROOT__/Debug-iphonesimulator/RunnerUITests-Runner.app'],
        },
      }, uiTarget: 'RunnerUITests');
      expect(out.keys, ['__xctestrun_metadata__', 'RunnerUITests']);
      final ui = out['RunnerUITests']! as Map;
      expect(ui['UITargetAppPath'], '__TESTROOT__/Debug-iphonesimulator/RunnerUITests-Runner.app');
      expect(ui['DependentProductPaths'], ['__TESTROOT__/Debug-iphonesimulator/RunnerUITests-Runner.app']);
    });

    test('prepare builds the helper and its attach xctestrun; a take starts it on "ready"', () async {
      repo.write('store_preview/demo/app.yaml', fixtureAppYaml.replaceFirst('  ready: {key: home}\n', '  ready: {key: home}\n  helper: {}\n'));
      final helperApp = PreviewApp.load(root: repo.root, id: 'demo', slots: slots);
      final build = repo.path('build/store_preview/demo');
      repo.write('build/store_preview/demo/xcode/Build/Products/Runner_iphonesimulator26.5-arm64.xctestrun', 'plist');
      repo.write(
        'sdk/SDKSettings.json',
        jsonEncode({
          'SupportedTargets': {
            'iphonesimulator': {'MinimumDeploymentTarget': '15.0', 'MaximumDeploymentTarget': '27.0.99'},
          },
        }),
      );
      final runner = FakeRunner(
        answers: {
          'xcrun --sdk': ProcessOutcome(0, repo.path('sdk'), ''),
          'xcodebuild -showBuildSettings': ProcessOutcome(
            0,
            jsonEncode([
              {
                'buildSettings': {
                  'PRODUCT_TYPE': 'com.apple.product-type.application',
                  'PRODUCT_BUNDLE_IDENTIFIER': 'com.example.demo',
                  'IPHONEOS_DEPLOYMENT_TARGET': '15.0',
                },
              },
            ]),
            '',
          ),
          'plutil -convert json': ProcessOutcome(
            0,
            jsonEncode({
              'RunnerTests': <String, Object?>{},
              'RunnerUITests': {
                'DependentProductPaths': ['__TESTROOT__/Debug-iphonesimulator/Runner.app'],
              },
            }),
            '',
          ),
          'plutil -extract CFBundleIdentifier': const ProcessOutcome(0, 'com.example.demo\n', ''),
        },
        onStart: (cmd, log, process) {
          if (cmd.startsWith('flutter test')) File(log).writeAsStringSync('$markTag{"t":1,"edge":"ready"}\n');
        },
      );
      final driver = FlutterIntegrationTestDriver(runner: runner, app: helperApp, root: repo.root);
      await driver.prepare(DriverContext(root: repo.root, buildDir: build, slots: [slots['iphone']!]));
      expect(runner.calls.first, 'flutter build ios --config-only --simulator --debug');
      expect(runner.calls, contains(startsWith('xcodebuild build-for-testing -workspace ios/Runner.xcworkspace -scheme Runner')));
      final attach = jsonDecode(File('$build/xcode/Build/Products/attach.json').readAsStringSync()) as Map;
      expect(attach.keys, ['RunnerUITests']);
      expect(runner.calls, contains('plutil -convert xml1 $build/xcode/Build/Products/attach.json -o $build/xcode/Build/Products/attach.xctestrun'));

      final plan = compilePlan(app: helperApp, storefront: helperApp.storefront('en-US'), scripts: scripts.values, manifest: manifest, syncDir: '/sync');
      final files = TakeFiles(repo.path('take'));
      Directory(files.dir).createSync(recursive: true);
      final session = await driver.launch(
        device: DeviceTarget(udid: 'U1', slot: slots['iphone']!),
        storefront: helperApp.storefront('en-US'),
        plan: plan,
        files: files,
      );
      expect(runner.calls.last, startsWith('start flutter test integration_test/store_preview_test.dart -d U1 --dart-define=STORE_PREVIEW_PLAN='));
      final running = session.run();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      File(files.driverLog).writeAsStringSync('$markTag{"t":1,"edge":"ready"}\n$markTag{"t":2,"edge":"done"}\n');
      runner.started.first.finish(0);
      final marks = await running;
      expect(marks.map((m) => m.edge), ['ready', 'done']);
      expect(runner.calls.last, contains('xcodebuild test-without-building -xctestrun $build/xcode/Build/Products/attach.xctestrun -destination id=U1'));
      expect(runner.calls.last, endsWith('-only-testing:RunnerUITests/StorePreviewHelper/testServe'));
      expect(runner.environments.last!['TEST_RUNNER_STORE_PREVIEW_PICKS'], '2@0');
      expect(runner.environments.last!['TEST_RUNNER_STORE_PREVIEW_ALLOW_NOTIFICATIONS'], '1');
      expect(runner.environments.last!['TEST_RUNNER_STORE_PREVIEW_BUNDLE_ID'], 'com.example.demo');
      runner.started.last.finish(0);
      await session.close();
    });

    test('a plan that needs system UI fails fast without a helper', () async {
      final plan = compilePlan(app: app, storefront: app.storefront('en-US'), scripts: scripts.values, manifest: manifest, syncDir: '/sync');
      final driver = FlutterIntegrationTestDriver(runner: FakeRunner(), app: app, root: repo.root);
      await expectLater(
        driver.launch(
          device: DeviceTarget(udid: 'U1', slot: slots['iphone']!),
          storefront: app.storefront('en-US'),
          plan: plan,
          files: TakeFiles(repo.path('t')),
        ),
        throwsA(isA<ConfigError>().having((e) => e.message, 'm', contains('declares no driver.helper'))),
      );
    });

    test('a failed mark stops the test and fails the take with its error', () async {
      final runner = FakeRunner(onStart: (cmd, log, process) => File(log).writeAsStringSync('$markTag{"t":1,"edge":"failed","error":"no tile"}\n'));
      final noHelper = FlutterIntegrationTestDriver(runner: runner, app: app, root: repo.root);
      final files = TakeFiles(repo.path('take'));
      Directory(files.dir).createSync(recursive: true);
      final plan = compilePlan(app: app, storefront: app.storefront('en-US'), scripts: [scripts['A']!], manifest: manifest, syncDir: '/s');
      final session = await noHelper.launch(
        device: DeviceTarget(udid: 'U1', slot: slots['iphone']!),
        storefront: app.storefront('en-US'),
        plan: plan,
        files: files,
      );
      await expectLater(session.run(), throwsA(isA<ToolError>().having((e) => e.message, 'm', contains('no tile'))));
      expect(runner.started.single.signals, ['TERM']);
    });
  });

  group('backend', () {
    test('refuses a port someone else serves; posts before_take with the manifest filled in', () async {
      final http = _FakeHttp(healthy: true);
      final backend = BackendController(
        runner: FakeRunner(),
        config: app.backend!,
        root: repo.root,
        manifest: '/m.json',
        logFile: repo.path('b.log'),
        http: http,
      );
      await expectLater(backend.start(), throwsA(isA<ToolError>().having((e) => e.message, 'm', contains('already serves'))));
      await backend.beforeTake();
      expect(http.sent, ['POST http://localhost:8799/admin/reset null', 'POST http://localhost:8799/admin/media {"manifest":"/m.json"}']);
    });

    test('starts the command and waits for health', () async {
      final http = _FakeHttp(healthy: false);
      final runner = FakeRunner(onStart: (cmd, log, process) => http.healthy = true);
      final backend = BackendController(runner: runner, config: app.backend!, root: repo.root, manifest: '/m.json', logFile: repo.path('b.log'), http: http);
      http.healthyAfterFirst = true;
      await backend.start();
      expect(runner.calls.single, 'start /bin/sh -c dart run mock/server.dart --port 8799 --manifest /m.json');
      await backend.stop();
      expect(runner.started.single.signals, ['TERM']);
    });
  });
}

class _FakeHttp implements HttpGateway {
  _FakeHttp({required this.healthy});

  bool healthy;
  bool healthyAfterFirst = false;
  final List<String> sent = [];

  @override
  Future<int?> get(String url) async => healthy ? 200 : null;

  @override
  Future<(int, String)> send(String method, String url, Map<String, Object?>? body) async {
    sent.add('$method $url ${body == null ? null : jsonEncode(body)}');
    return (200, '{}');
  }
}
