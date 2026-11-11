import 'dart:convert';
import 'dart:io';

import '../config/app.dart';
import '../config/manifest.dart';
import '../config/script.dart';
import '../core/errors.dart';
import '../device/recorder.dart';
import '../device/simulator.dart';
import '../plan/plan.dart';
import 'backend.dart';
import 'driver.dart';
import 'take.dart';

/// The library photos of [storefront]: the manifest images of the app's
/// library role (and script), by id, de-duplicated by file — in import
/// order, last first, so the picker (newest first) lists them in id order.
List<String> libraryPhotos(PreviewApp app, Manifest manifest, Storefront storefront) {
  final role = app.simulator.libraryRole;
  if (role == null) return const [];
  final files = <String>{};
  final entries = manifest.entries
      .where((e) => e.type == 'image' && e.role == role && e.locale == storefront.id)
      .where((e) => app.simulator.libraryScript == null || e.script == app.simulator.libraryScript)
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  for (final e in entries) {
    files.add(e.file);
  }
  return files.toList().reversed.toList();
}

/// Films one storefront's take on one device: the plan, a clean simulator
/// with the storefront's photos, a fresh backend, the screen recorder, the
/// driver.
class TakeRecorder {
  TakeRecorder({
    required this.app,
    required this.manifest,
    required this.simulator,
    required this.recorder,
    required this.driver,
    this.backend,
  });

  final PreviewApp app;
  final Manifest manifest;
  final SimulatorController simulator;
  final ScreenRecorder recorder;
  final AppDriver driver;
  final BackendController? backend;

  Future<Take> record({
    required Storefront storefront,
    required Iterable<PreviewScript> scripts,
    required DeviceTarget device,
    required TakeFiles files,
  }) async {
    final dir = Directory(files.dir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    Directory(files.sync).createSync(recursive: true);

    final plan = compilePlan(app: app, storefront: storefront, scripts: scripts, manifest: manifest, syncDir: files.sync);
    File(files.plan).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(plan.json));

    await simulator.prepare(
      storefront: storefront,
      setup: app.simulator,
      photos: libraryPhotos(app, manifest, storefront),
      workDir: files.dir,
    );
    await backend?.beforeTake();

    final recording = await recorder.start(udid: device.udid, out: files.recording, logFile: files.recLog);
    DriverSession? session;
    try {
      session = await driver.launch(device: device, storefront: storefront, plan: plan, files: files);
      await session.run();
    } finally {
      await recording.stop();
      await session?.close();
      await simulator.clearStatusBar();
    }
    if (!files.complete) throw ToolError('the take in ${files.dir} is incomplete');
    return files.load();
  }
}
