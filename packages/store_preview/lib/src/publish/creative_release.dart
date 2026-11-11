import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../core/errors.dart';

String fileSha256(String path) => sha256.convert(File(path).readAsBytesSync()).toString();

/// All manifest paths stay inside this app's release, including through links.
String releasePath(String root, String relative) {
  final normalized = p.normalize(p.absolute(root));
  final full = p.normalize(p.join(normalized, relative));
  if (p.isAbsolute(relative) || !p.isWithin(normalized, full)) {
    throw ConfigError('creative release: $relative escapes its app directory');
  }
  var at = full;
  while (at != normalized) {
    if (FileSystemEntity.typeSync(at, followLinks: false) == FileSystemEntityType.link) {
      throw ConfigError('creative release: $relative traverses a symbolic link');
    }
    at = p.dirname(at);
  }
  return full;
}

/// Verifies the previous bytes before allowing any regeneration. A rewritten
/// manifest must never turn an unexplained change into a trusted delivery.
Map<String, String> releaseFiles(String dist, {required String app, required String bundleId}) {
  final manifest = File(p.join(dist, 'assets-manifest.json'));
  if (!manifest.existsSync()) return {};
  final data = jsonDecode(manifest.readAsStringSync()) as Map;
  if ((data['app'] as Map?)?['bundle_id'] != bundleId || (data['app'] as Map?)?['store_preview_app'] != app) {
    throw ConfigError('creative release: the existing manifest belongs to another app; expected $app ($bundleId)');
  }
  final files = <String, String>{'assets-manifest.json': fileSha256(manifest.path)};
  final errors = <String>[];
  void include(String relative, {String? expected}) {
    final file = File(releasePath(dist, relative));
    if (!file.existsSync()) {
      errors.add('$relative is missing');
      return;
    }
    final hash = fileSha256(file.path);
    if (expected != null && expected != hash) errors.add('$relative differs from the delivered manifest (SHA-256)');
    files[relative] = hash;
  }

  for (final entry in data['entries'] as List) {
    final e = entry as Map;
    include(e['file'] as String, expected: e['sha256'] as String);
    final poster = (e['video'] as Map?)?['poster'] as Map?;
    if (poster != null) include(poster['file'] as String, expected: poster['sha256'] as String);
    final evidence = (e['source'] as Map?)?['evidence'] as String?;
    if (evidence != null) include(evidence);
  }
  if (errors.isNotEmpty) {
    throw ConfigError(
      'creative release: ${errors.length} existing delivery file(s) drifted; restore the original bytes before rendering or writing manifest. '
      'No hashes were rewritten.\n  ${errors.take(8).join('\n  ')}',
    );
  }
  return files;
}

/// Immutable, content-addressed local copy of the previous manifest and its
/// files. Deliberately independent of ascpub upload state or credentials.
String? archiveCreativeRelease(String dist, {required String app, required String bundleId}) {
  final files = releaseFiles(dist, app: app, bundleId: bundleId);
  if (files.isEmpty) return null;
  final archive = releasePath(dist, p.join('.releases', files['assets-manifest.json']!));
  final receipt = File(releasePath(dist, p.join('.releases', files['assets-manifest.json']!, 'receipt.json')));
  if (Directory(archive).existsSync()) {
    if (!receipt.existsSync()) throw ConfigError('creative release: incomplete archive at $archive');
    final saved = (jsonDecode(receipt.readAsStringSync()) as Map)['files'] as Map;
    if (saved.length != files.length || files.entries.any((e) => saved[e.key] != e.value)) {
      throw ConfigError('creative release: existing archive and current delivery evidence differ; archive kept for diagnosis');
    }
    for (final entry in saved.entries) {
      final file = File(releasePath(archive, entry.key as String));
      if (!file.existsSync() || fileSha256(file.path) != entry.value) {
        throw ConfigError('creative release: archived ${entry.key} was modified; archive kept for diagnosis');
      }
    }
    if (saved['assets-manifest.json'] != files['assets-manifest.json']) throw ConfigError('creative release: archive identity mismatch');
    return archive;
  }
  Directory(p.dirname(archive)).createSync(recursive: true);
  final stage = Directory(p.dirname(archive)).createTempSync('.pending-');
  try {
    for (final e in files.entries) {
      final target = File(releasePath(stage.path, e.key));
      target.parent.createSync(recursive: true);
      File(releasePath(dist, e.key)).copySync(target.path);
      if (fileSha256(target.path) != e.value) throw ConfigError('creative release: ${e.key} changed while archiving');
    }
    File(p.join(stage.path, 'receipt.json')).writeAsStringSync(jsonEncode({'schema': 1, 'app': app, 'bundle_id': bundleId, 'files': files}), flush: true);
    stage.renameSync(archive);
  } finally {
    if (stage.existsSync()) stage.deleteSync(recursive: true);
  }
  return archive;
}

void _copyDirectory(String from, String to) {
  final dir = Directory(from);
  if (!dir.existsSync()) return;
  for (final f in dir.listSync(recursive: true, followLinks: false)) {
    if (f is Link) throw ConfigError('creative release: output contains a symbolic link: ${f.path}');
    if (f is! File) continue;
    final target = File(p.join(to, p.relative(f.path, from: from)));
    target.parent.createSync(recursive: true);
    f.copySync(target.path);
  }
}

/// Rendering and standalone manifest writes share one app-local lock.
RandomAccessFile lockCreativeRelease(String dist, {required String app}) {
  Directory(dist).createSync(recursive: true);
  final lock = File(releasePath(dist, '.creative-release.lock')).openSync(mode: FileMode.append);
  try {
    lock.lockSync();
    return lock;
  } on FileSystemException {
    lock.closeSync();
    throw ConfigError('creative release: another process is working on $app; wait for it to finish');
  }
}

/// One local creative render. Builds and validates in isolation; a failed run
/// cannot replace the current files. The app-specific file lock prevents two
/// CLI runs from publishing competing generations.
class CreativeReleaseRun {
  CreativeReleaseRun._(this.dist, this.stage, this._lock, this.archive);

  factory CreativeReleaseRun.begin(String dist, {required String app, required String bundleId}) {
    final lock = lockCreativeRelease(dist, app: app);
    Directory? stage;
    try {
      final archive = archiveCreativeRelease(dist, app: app, bundleId: bundleId);
      stage = Directory(p.dirname(dist)).createTempSync('.$app-creative-run-');
      _copyDirectory(p.join(dist, 'creative'), p.join(stage.path, 'creative'));
      final manifest = File(p.join(dist, 'assets-manifest.json'));
      if (manifest.existsSync()) manifest.copySync(p.join(stage.path, 'assets-manifest.json'));
      return CreativeReleaseRun._(dist, stage, lock, archive);
    } catch (_) {
      if (stage?.existsSync() ?? false) stage!.deleteSync(recursive: true);
      lock.closeSync();
      rethrow;
    }
  }

  final String dist;
  final Directory stage;
  final RandomAccessFile _lock;
  final String? archive;
  bool _keepStage = false;

  void commit({bool awaitingReview = false}) {
    final saved = <String>[];
    final installed = <String>[];
    void move(String from, String to) {
      if (Directory(from).existsSync()) {
        Directory(from).renameSync(to);
      } else {
        File(from).renameSync(to);
      }
    }

    try {
      // A technically valid screenshot set must be visible to its human
      // reviewer. It is a working set, not a delivery: never leave the old
      // manifest next to new, unreviewed bytes. The old release is archived.
      if (awaitingReview) {
        final manifest = File(p.join(stage.path, 'assets-manifest.json'));
        if (manifest.existsSync()) manifest.deleteSync();
      }
      for (final name in ['creative', 'assets-manifest.json']) {
        final fresh = p.join(stage.path, name);
        final exists = FileSystemEntity.isFileSync(fresh) || Directory(fresh).existsSync();
        if (!exists && !(awaitingReview && name == 'assets-manifest.json')) continue;
        final current = p.join(dist, name);
        if (FileSystemEntity.typeSync(current) != FileSystemEntityType.notFound) {
          move(current, p.join(stage.path, 'previous-$name'));
          saved.add(name);
        }
        if (exists) {
          move(fresh, current);
          installed.add(name);
        }
      }
    } catch (_) {
      try {
        for (final name in installed.reversed) {
          move(p.join(dist, name), p.join(stage.path, name));
        }
        for (final name in saved.reversed) {
          move(p.join(stage.path, 'previous-$name'), p.join(dist, name));
        }
      } catch (rollback) {
        _keepStage = true;
        throw ConfigError('creative release: rollback failed ($rollback); recovery files retained at ${stage.path}; previous delivery: $archive');
      }
      rethrow;
    }
  }

  void close() {
    try {
      if (!_keepStage && stage.existsSync()) stage.deleteSync(recursive: true);
    } finally {
      _lock.closeSync();
    }
  }
}
