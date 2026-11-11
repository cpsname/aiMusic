import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/app.dart';
import '../core/errors.dart';
import '../core/process.dart';

/// The one-time keyboard tips a used phone has dismissed: "slide to type",
/// and the multilingual keyboard's "type both languages" (Hindi and other
/// transliterating keyboards). Each would cover a typing scene.
const List<String> keyboardTips = ['DidShowContinuousPathIntroduction', 'MultilingualKeyboardTip', 'MultilingualSettingTip'];
const List<String> keyboardTipDomains = ['com.apple.Preferences', 'com.apple.keyboard.preferences'];

/// Recording erases a device. Namespace the default by both identities so
/// separate apps (or recording configurations) cannot erase each other's take.
String recordingSimulatorName(PreviewApp app, String device) => 'Store Preview ${app.bundleId}/${app.id} ($device)';

/// A simulator the recordings own: every take erases it.
class SimulatorController {
  SimulatorController(this.runner, this.udid, {String? devicesRoot})
    : devicesRoot = devicesRoot ?? p.join(Platform.environment['HOME'] ?? '', 'Library', 'Developer', 'CoreSimulator', 'Devices');

  final ProcessRunner runner;
  final String udid;

  /// CoreSimulator's device directories (the photo library is removed there).
  final String devicesRoot;

  Future<void> _simctl(List<String> args, {bool check = true}) => runner.run('xcrun', ['simctl', ...args], check: check);

  /// A dedicated simulator named [name] of [deviceType], created on the
  /// newest iOS runtime when missing. Never one a person works on: takes
  /// erase it.
  static Future<String> dedicated(ProcessRunner runner, {required String deviceType, required String name}) async {
    final list = jsonDecode((await runner.run('xcrun', ['simctl', 'list', 'devices', 'available', '-j'])).stdout) as Map<String, Object?>;
    for (final devices in ((list['devices'] as Map?) ?? const {}).values) {
      for (final d in (devices as List)) {
        final m = (d as Map).cast<String, Object?>();
        if (m['name'] == name) return '${m['udid']}';
      }
    }
    final runtimes = jsonDecode((await runner.run('xcrun', ['simctl', 'list', 'runtimes', '-j'])).stdout) as Map<String, Object?>;
    final ios = [
      for (final r in (runtimes['runtimes'] as List? ?? const []))
        if (r is Map && r['platform'] == 'iOS' && r['isAvailable'] == true) r.cast<String, Object?>(),
    ];
    if (ios.isEmpty) throw ToolError('no iOS simulator runtime installed (Xcode › Settings › Components)');
    List<int> version(Map<String, Object?> r) => '${r['version']}'.split('.').map((v) => int.tryParse(v) ?? 0).toList();
    ios.sort((a, b) {
      final va = version(a), vb = version(b);
      for (var i = 0; i < va.length && i < vb.length; i++) {
        if (va[i] != vb[i]) return va[i].compareTo(vb[i]);
      }
      return va.length.compareTo(vb.length);
    });
    final types = jsonDecode((await runner.run('xcrun', ['simctl', 'list', 'devicetypes', '-j'])).stdout) as Map<String, Object?>;
    final type = (types['devicetypes'] as List? ?? const []).whereType<Map<Object?, Object?>>().where((t) => t['name'] == deviceType).firstOrNull;
    if (type == null) throw ToolError('no simulator device type "$deviceType" (xcrun simctl list devicetypes)');
    final created = await runner.run('xcrun', ['simctl', 'create', name, '${type['identifier']}', '${ios.last['identifier']}']);
    return created.stdout.trim();
  }

  /// A clean device in [storefront]'s language and region, its photo
  /// library holding exactly [photos] (imported in this order: the picker
  /// lists the last imported first), the status bar at [SimulatorSetup.time].
  Future<void> prepare({required Storefront storefront, required SimulatorSetup setup, required List<String> photos, required String workDir}) async {
    await _simctl(['shutdown', udid], check: false);
    await _simctl(['erase', udid]);
    await _boot();
    await _simctl(['spawn', udid, 'defaults', 'write', '-g', 'AppleLanguages', '-array', storefront.simLanguage]);
    await _simctl(['spawn', udid, 'defaults', 'write', '-g', 'AppleLocale', '-string', storefront.simLocale]);
    if (setup.keyboardTipsSeen) {
      for (final key in keyboardTips) {
        for (final domain in keyboardTipDomains) {
          await _simctl(['spawn', udid, 'defaults', 'write', domain, key, '-bool', 'true']);
        }
      }
    }
    await _simctl(['shutdown', udid]);
    // An empty photo library: the simulator's sample photos are not the
    // app's to show; only the app's licensed images go in.
    final media = p.join(devicesRoot, udid, 'data', 'Media');
    for (final dir in ['DCIM', 'PhotoData']) {
      final d = Directory(p.join(media, dir));
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
    await _boot();
    await _simctl(['ui', udid, 'appearance', setup.appearance]);
    await _simctl([
      'status_bar', udid, 'override', '--time', setup.time, '--dataNetwork', 'wifi', '--wifiMode', 'active', //
      '--wifiBars', '3', '--cellularMode', 'active', '--cellularBars', '4', '--batteryState', 'charged', '--batteryLevel', '100',
    ]);
    final dir = Directory(p.join(workDir, 'photos'))..createSync(recursive: true);
    for (final (i, photo) in photos.indexed) {
      // Metadata stripped, so the library orders by import time.
      final jpg = p.join(dir.path, '${i + 1}.jpg');
      await runner.run('ffmpeg', ['-nostdin', '-v', 'error', '-y', '-i', photo, '-map_metadata', '-1', '-q:v', '2', jpg]);
      await _simctl(['addmedia', udid, jpg]);
      await runner.sleep(const Duration(milliseconds: 1200));
    }
  }

  Future<void> _boot() async {
    await _simctl(['boot', udid]);
    await _simctl(['bootstatus', udid, '-b']);
  }

  Future<void> clearStatusBar() => _simctl(['status_bar', udid, 'clear'], check: false);

  Future<void> shutdown() => _simctl(['shutdown', udid], check: false);
}
