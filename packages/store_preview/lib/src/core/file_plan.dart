import 'dart:io';

import 'package:path/path.dart' as p;

import 'errors.dart';

/// Plans text edits before touching the repository. Rejects links, concurrent
/// edits and paths outside the selected app; rolls back a failed write batch.
class FilePlan {
  FilePlan(String root) : root = p.normalize(p.absolute(root));

  final String root;
  final Map<String, String?> _before = {};
  final Map<String, String> _after = {};

  String _path(String relative) {
    final full = p.normalize(p.join(root, relative));
    if (!p.isWithin(root, full)) throw ConfigError('file plan: $relative escapes the app repository');
    var at = full;
    while (at != root) {
      if (FileSystemEntity.typeSync(at, followLinks: false) == FileSystemEntityType.link) {
        throw ConfigError('file plan: $relative traverses a symbolic link');
      }
      at = p.dirname(at);
    }
    return full;
  }

  String? read(String relative) {
    final path = _path(relative);
    return _after[relative] ?? (File(path).existsSync() ? File(path).readAsStringSync() : null);
  }

  void set(String relative, String content) {
    final path = _path(relative);
    _before.putIfAbsent(relative, () => File(path).existsSync() ? File(path).readAsStringSync() : null);
    _after[relative] = content;
  }

  List<String> get changed => [
    for (final e in _after.entries)
      if (_before[e.key] != e.value) e.key,
  ];

  void apply() {
    final paths = changed;
    for (final relative in paths) {
      final path = _path(relative);
      final current = File(path).existsSync() ? File(path).readAsStringSync() : null;
      if (current != _before[relative]) throw ConfigError('file plan: $relative changed while planning; run again');
    }
    final staged = <String, File>{};
    final written = <String>[];
    var keepBackups = false;
    try {
      for (final relative in paths) {
        final target = File(_path(relative));
        target.parent.createSync(recursive: true);
        final dir = Directory(target.parent.path).createTempSync('.store-preview-write-');
        if (_before[relative] != null) File(p.join(dir.path, 'previous')).writeAsStringSync(_before[relative]!, flush: true);
        staged[relative] = File(p.join(dir.path, 'content'))..writeAsStringSync(_after[relative]!, flush: true);
      }
      for (final relative in paths) {
        staged[relative]!.renameSync(_path(relative));
        written.add(relative);
      }
    } catch (_) {
      try {
        for (final relative in written.reversed) {
          final file = File(_path(relative));
          final old = _before[relative];
          if (old == null) {
            file.deleteSync();
          } else {
            file.writeAsStringSync(old, flush: true);
          }
        }
      } catch (rollback) {
        keepBackups = true;
        throw ConfigError('file plan: rollback failed ($rollback); original contents retained in ${staged.values.map((f) => f.parent.path).join(', ')}');
      }
      rethrow;
    } finally {
      for (final file in staged.values) {
        if (!keepBackups && file.parent.existsSync()) file.parent.deleteSync(recursive: true);
      }
    }
  }
}
