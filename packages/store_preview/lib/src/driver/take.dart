import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';

/// The line prefix the driver prints its marks with
/// (`store_preview_driver`).
const String markTag = 'STORE_PREVIEW_MARK ';

/// One mark the app's driver printed: host-clock ms, the edge (`ready`,
/// `start`, `end`, `failed`, `done`), the scene and, for a scene that
/// follows playback, the position at its start.
class SceneMark {
  const SceneMark({required this.t, required this.edge, this.script, this.scene, this.position, this.error});

  factory SceneMark.parse(Map<String, Object?> json) => SceneMark(
    t: (json['t']! as num).toInt(),
    edge: '${json['edge']}',
    script: json['script'] as String?,
    scene: json['scene'] as String?,
    position: (json['pos'] as num?)?.toDouble(),
    error: json['error'] as String?,
  );

  final int t;
  final String edge;
  final String? script;
  final String? scene;
  final double? position;
  final String? error;
}

/// Every mark in a driver log.
List<SceneMark> parseMarks(String log) => [
  for (final line in log.split('\n'))
    if (line.contains(markTag)) SceneMark.parse(jsonDecode(line.substring(line.indexOf(markTag) + markTag.length)) as Map<String, Object?>),
];

/// One scene as filmed: host-clock ms of its edges, and the playback
/// position (s) at its start when it follows playback.
class SceneWindow {
  const SceneWindow({required this.startMs, required this.endMs, this.position});

  final int startMs;
  final int endMs;
  final double? position;
}

/// A recording take: when the recorder started, and every scene's window.
class Take {
  const Take({required this.recordStartMs, required this.scenes});

  final int recordStartMs;

  /// script → scene → window.
  final Map<String, Map<String, SceneWindow>> scenes;

  SceneWindow window(String script, String scene) =>
      scenes[script]?[scene] ?? (throw ConfigError('the take has no scene $script/$scene'));

  /// Seconds into the recording at host-clock [ms].
  double at(int ms) => (ms - recordStartMs) / 1000;
}

/// Reads a take from its logs: `rec.log` (the recorder's lines, each
/// prefixed with host-clock ms) and the driver log's marks.
Take parseTake({required String testLog, required String recLog}) {
  int? started;
  for (final line in recLog.split('\n')) {
    if (line.contains('Recording started')) {
      started = int.tryParse(line.split(' ').first);
      break;
    }
  }
  if (started == null) throw ConfigError('rec.log has no "Recording started" line');
  final open = <String, SceneMark>{};
  final scenes = <String, Map<String, SceneWindow>>{};
  for (final mark in parseMarks(testLog)) {
    if (mark.script == null || mark.scene == null) continue;
    final key = '${mark.script}/${mark.scene}';
    if (mark.edge == 'start') {
      open[key] = mark;
    } else if (mark.edge == 'end') {
      final begun = open.remove(key) ?? (throw ConfigError('scene $key ends without starting'));
      (scenes[mark.script!] ??= {})[mark.scene!] = SceneWindow(startMs: begun.t, endMs: mark.t, position: begun.position);
    }
  }
  return Take(recordStartMs: started, scenes: scenes);
}

/// The files a take leaves in its directory.
class TakeFiles {
  const TakeFiles(this.dir);

  final String dir;

  String get recording => p.join(dir, 'recording.mov');
  String get recLog => p.join(dir, 'rec.log');
  String get driverLog => p.join(dir, 'test.log');
  String get helperLog => p.join(dir, 'helper.log');
  String get plan => p.join(dir, 'plan.json');
  String get sync => p.join(dir, 'sync');

  bool get complete =>
      File(recording).existsSync() &&
      File(driverLog).existsSync() &&
      parseMarks(File(driverLog).readAsStringSync()).any((m) => m.edge == 'done');

  Take load() => parseTake(testLog: File(driverLog).readAsStringSync(), recLog: File(recLog).readAsStringSync());
}
