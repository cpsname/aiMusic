import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import 'take.dart';

/// A recording run's directory name: its UTC start, `20261008T101500Z`.
String runStamp(int epochMs) {
  final t = DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${t.year}${two(t.month)}${two(t.day)}T${two(t.hour)}${two(t.minute)}${two(t.second)}Z';
}

final RegExp _runName = RegExp(r'^(\d{8}T\d{6}Z|legacy)$');

/// The takes of one storefront on one slot
/// (`build/store_preview/<app>/raw/<storefront>/<slot>/`): every recording run
/// in its own directory, and `takes.json` naming the run that holds each
/// script's latest footage. Recording some scripts again replaces only
/// theirs; the previews and creative assets of the others keep their footage
/// (template ADR-0012).
class TakeRegistry {
  TakeRegistry(this.dir);

  final String dir;

  String get file => p.join(dir, 'takes.json');

  /// script id → run directory name.
  Map<String, String> read() {
    final f = File(file);
    if (!f.existsSync()) return {};
    final raw = jsonDecode(f.readAsStringSync());
    if (raw is! Map || raw['schema'] != 1 || raw['scripts'] is! Map) throw ConfigError('${f.path}: not a take registry (schema 1)');
    return {for (final e in (raw['scripts'] as Map).entries) '${e.key}': '${e.value}'};
  }

  /// The directory a new run records into.
  TakeFiles run(String name) => TakeFiles(p.join(dir, name));

  /// The run [name] filmed [scripts] completely: they point at it from now
  /// on, and runs no script points at any more are removed.
  void register(String name, Iterable<String> scripts) {
    final take = run(name);
    if (!take.complete) throw ToolError('the take in ${take.dir} is incomplete');
    final map = read();
    for (final s in scripts) {
      map[s] = name;
    }
    _write(map);
    final used = map.values.toSet();
    for (final d in Directory(dir).listSync().whereType<Directory>()) {
      final n = p.basename(d.path);
      if (_runName.hasMatch(n) && !used.contains(n)) d.deleteSync(recursive: true);
    }
  }

  void _write(Map<String, String> map) {
    final sorted = Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    File(file)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('${const JsonEncoder.withIndent('  ').convert({'schema': 1, 'scripts': sorted})}\n');
  }

  /// The complete take holding [script]'s footage, or null.
  TakeFiles? takeOf(String script) {
    final name = read()[script];
    if (name == null) return null;
    final take = run(name);
    return take.complete ? take : null;
  }

  /// [takeOf], or a [ConfigError] saying how to record it.
  TakeFiles takeFor(String script, {required String what}) =>
      takeOf(script) ?? (throw ConfigError('no take of $script for $what in $dir — record it (render --scripts $script --locales …)'));

  /// A take recorded before runs had directories (its files directly in
  /// [dir]) becomes the run `legacy`, holding the scripts its plan filmed; an
  /// incomplete one is dropped.
  void migrateLegacy() {
    final legacyRecording = File(p.join(dir, 'recording.mov'));
    if (!legacyRecording.existsSync()) return;
    final target = Directory(p.join(dir, 'legacy'));
    if (target.existsSync()) target.deleteSync(recursive: true);
    target.createSync(recursive: true);
    for (final e in Directory(dir).listSync()) {
      final n = p.basename(e.path);
      if (n == 'takes.json' || n == 'legacy' || (e is Directory && _runName.hasMatch(n))) continue;
      e.renameSync(p.join(target.path, n));
    }
    final take = TakeFiles(target.path);
    final planFile = File(take.plan);
    if (!take.complete || !planFile.existsSync()) {
      target.deleteSync(recursive: true);
      return;
    }
    final plan = jsonDecode(planFile.readAsStringSync()) as Map<String, Object?>;
    final scripts = [for (final r in (plan['runs'] as List? ?? const [])) '${(r as Map)['script']}'];
    final map = read();
    for (final s in scripts) {
      map.putIfAbsent(s, () => 'legacy');
    }
    _write(map);
  }
}
