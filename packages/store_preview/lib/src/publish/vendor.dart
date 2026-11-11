import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../core/errors.dart';

/// What an app repo holds a copy of (repo-relative).
const List<String> vendoredPaths = [
  'packages/store_preview',
  'packages/store_preview_driver',
  'docs/store/apple-preview-rules.md',
  'docs/store/creative-assets-specs.md',
  'docs/store/asset-library-playbook.zh-CN.md',
  'docs/store/asset-library-reuse.zh-CN.md',
  'docs/store/asset-library-troubleshooting.zh-CN.md',
  'docs/store/ai-studio-engineering-retrospective.zh-CN.md',
  'docs/store/examples/reuse-notes',
  'scripts/asset_library_check.sh',
];

/// The stamp a vendored copy carries.
const String vendorStampName = 'VENDOR.json';

bool _skipped(String relative, {bool includeGeneratedMetadata = false}) {
  final parts = p.split(relative);
  return parts.contains('.dart_tool') ||
      parts.contains('build') ||
      parts.last == vendorStampName ||
      parts.last == '.DS_Store' ||
      parts.last == 'pubspec_overrides.yaml' ||
      (!includeGeneratedMetadata && const {'.flutter-plugins', '.flutter-plugins-dependencies'}.contains(parts.last));
}

/// The files of the vendored paths under [root], repo-relative, sorted.
List<String> vendoredFiles(String root) => _vendoredFiles(root);

List<String> _vendoredFiles(String root, {bool includeGeneratedMetadata = false}) {
  final out = <String>[];
  for (final path in vendoredPaths) {
    final full = p.join(root, path);
    if (FileSystemEntity.typeSync(full, followLinks: false) == FileSystemEntityType.link) {
      throw ConfigError('vendor: $path is a symbolic link; only template files can be vendored');
    }
    if (File(full).existsSync()) {
      out.add(path);
    } else if (Directory(full).existsSync()) {
      for (final f in Directory(full).listSync(recursive: true, followLinks: false)) {
        final relative = p.relative(f.path, from: root);
        if (_skipped(relative, includeGeneratedMetadata: includeGeneratedMetadata)) continue;
        if (f is Link) throw ConfigError('vendor: $relative is a symbolic link; only template files can be vendored');
        if (f is File) out.add(relative);
      }
    }
  }
  return out..sort();
}

/// SHA-256 over every vendored file's path and bytes.
String vendorDigest(String root) => _vendorDigest(root);

String _vendorDigest(String root, {bool includeGeneratedMetadata = false}) {
  final sink = AccumulatorSink<Digest>();
  final input = sha256.startChunkedConversion(sink);
  for (final f in _vendoredFiles(root, includeGeneratedMetadata: includeGeneratedMetadata)) {
    input
      ..add(utf8.encode('$f\n'))
      ..add(File(p.join(root, f)).readAsBytesSync());
  }
  input.close();
  return sink.events.single.toString();
}

/// Copies the tool from the template at [from] into the repo at [to] and
/// stamps it. Returns the stamp.
Future<Map<String, Object?>> vendor({required String from, required String to}) async {
  if (!File(p.join(from, 'packages', 'store_preview', 'pubspec.yaml')).existsSync()) {
    throw ConfigError('$from is not a template checkout (no packages/store_preview)');
  }
  from = Directory(from).resolveSymbolicLinksSync();
  to = Directory(to).resolveSymbolicLinksSync();
  if (p.equals(from, to) || p.isWithin(from, to) || p.isWithin(to, from)) {
    throw ConfigError('vendor: source and destination must be separate, non-nested repositories');
  }
  final drift = vendorDrift(to);
  if (drift != null) throw ConfigError(drift);
  for (final path in vendoredPaths) {
    if (!File(p.join(from, path)).existsSync() && !Directory(p.join(from, path)).existsSync()) {
      throw ConfigError('vendor: template is incomplete: $path is missing');
    }
    var target = p.join(to, path);
    while (target != to) {
      if (FileSystemEntity.typeSync(target, followLinks: false) == FileSystemEntityType.link) {
        throw ConfigError('vendor: destination $path traverses a symbolic link');
      }
      target = p.dirname(target);
    }
  }
  final sourceDigest = vendorDigest(from);
  final commit = await Process.run('git', ['-C', from, 'rev-parse', 'HEAD']);
  final dirty = await Process.run('git', ['-C', from, 'status', '--porcelain', '--', ...vendoredPaths]);
  final stamp = {'template_commit': '${commit.stdout}'.trim(), 'template_dirty': '${dirty.stdout}'.trim().isNotEmpty, 'sha256': sourceDigest, 'files': vendoredFiles(from).length};
  final staging = Directory(to).createTempSync('.store-preview-vendor-');
  final fresh = p.join(staging.path, 'new');
  final previous = p.join(staging.path, 'previous');
  final installed = <String>[];
  final saved = <String>[];
  var keepBackups = false;
  void move(String source, String destination) {
    Directory(p.dirname(destination)).createSync(recursive: true);
    if (Directory(source).existsSync()) {
      Directory(source).renameSync(destination);
    } else {
      File(source).renameSync(destination);
    }
  }

  try {
    for (final f in vendoredFiles(from)) {
      File(p.join(from, f)).copySync(_ensureParent(p.join(fresh, f)));
    }
    if (vendorDigest(fresh) != sourceDigest || vendorDigest(from) != sourceDigest) {
      throw ConfigError('vendor: template changed during copying; destination kept, run again');
    }
    File(p.join(fresh, 'packages', 'store_preview', vendorStampName)).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(stamp)}\n');
    for (final path in vendoredPaths) {
      final target = p.join(to, path);
      if (FileSystemEntity.typeSync(target) != FileSystemEntityType.notFound) {
        move(target, p.join(previous, path));
        saved.add(path);
      }
      move(p.join(fresh, path), target);
      installed.add(path);
    }
  } catch (_) {
    try {
      for (final path in installed.reversed) {
        final target = p.join(to, path);
        if (Directory(target).existsSync()) {
          Directory(target).deleteSync(recursive: true);
        } else if (File(target).existsSync()) {
          File(target).deleteSync();
        }
      }
      for (final path in saved.reversed) {
        move(p.join(previous, path), p.join(to, path));
      }
    } catch (rollback) {
      keepBackups = true;
      throw ConfigError('vendor: rollback failed ($rollback); recovery files retained at ${staging.path}');
    }
    rethrow;
  } finally {
    if (!keepBackups) staging.deleteSync(recursive: true);
  }
  return stamp;
}

String _ensureParent(String path) {
  File(path).parent.createSync(recursive: true);
  return path;
}

/// `null` when the copy under [root] matches its stamp (or carries none: the
/// template itself); otherwise why not.
String? vendorDrift(String root) {
  final stampFile = File(p.join(root, 'packages', 'store_preview', vendorStampName));
  if (!stampFile.existsSync()) return null;
  final stamp = jsonDecode(stampFile.readAsStringSync()) as Map<String, Object?>;
  final digest = vendorDigest(root);
  if (stamp['sha256'] == digest) return null;
  // Older stamps included ignored Flutter plugin metadata. Only an exact
  // legacy digest permits migration; edits to source files still fail.
  if (stamp['sha256'] == _vendorDigest(root, includeGeneratedMetadata: true)) return null;
  return 'the vendored store_preview copy differs from its stamp (template ${stamp['template_commit']}): '
      'change the tool in the template and re-vendor (`store-preview vendor --from <template>`), never the copy';
}

/// A chunked-conversion sink that keeps what it receives.
class AccumulatorSink<T> implements Sink<T> {
  final List<T> events = [];

  @override
  void add(T event) => events.add(event);

  @override
  void close() {}
}
