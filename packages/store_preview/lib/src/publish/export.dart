import 'dart:io';

import 'package:path/path.dart' as p;

import '../cli/project.dart';
import '../config/app.dart';
import '../core/errors.dart';
import '../post/compose.dart';

const Set<String> _videoExtensions = {'.mp4', '.mov', '.m4v'};

/// Copies the finished previews into the app's store-listing tree
/// (`publish.listings_dir/<localization>/<device dir>/<script>.mp4`) — each
/// storefront's into its own localization and into each one it serves
/// (template ADR-0017) — and removes any other preview video there (a retired
/// script's), so the tree holds exactly the previews this run made. Returns
/// the lines to print.
List<String> exportPreviews(Project project, {required List<Storefront> storefronts}) {
  final app = project.app;
  final listings = app.publish.listingsDir ?? (throw ConfigError('${app.id}: publish.listings_dir is not set'));
  final lines = <String>[];
  for (final s in storefronts) {
    for (final locale in s.locales) {
      lines.addAll(_exportInto(project, listings, storefront: s, locale: locale));
    }
  }
  return lines;
}

/// [storefront]'s previews into [locale]'s listing directories.
List<String> _exportInto(Project project, String listings, {required Storefront storefront, required String locale}) {
  final app = project.app;
  final s = storefront;
  final lines = <String>[];
  for (final slotId in app.devices) {
    final dirName = app.publish.deviceDirs[slotId] ?? (throw ConfigError('${app.id}: publish.device_dirs has no entry for $slotId'));
    final slot = app.slots[slotId]!;
    final dest = Directory(p.join(project.root, listings, locale, dirName));
    // The listing tree belongs to the store tooling: its layout is used as
    // it is, never invented here.
    if (!dest.existsSync()) {
      throw ConfigError('${app.id}: no ${p.join(listings, locale, dirName)} — check publish.listings_dir and publish.device_dirs');
    }
    final keep = <String>{};
    for (final script in project.orderedAll) {
      final files = PreviewFiles(p.join(project.distDir, s.id), script.id, slot);
      if (!File(files.video).existsSync()) throw ConfigError('missing ${files.video} — render it first');
      final name = '${script.id}.mp4';
      File(files.video).copySync(p.join(dest.path, name));
      keep.add(name);
    }
    for (final f in dest.listSync().whereType<File>()) {
      final name = p.basename(f.path);
      if (_videoExtensions.contains(p.extension(name).toLowerCase()) && !keep.contains(name)) {
        f.deleteSync();
        lines.add('  − ${p.relative(f.path, from: project.root)} (no longer a preview)');
      }
    }
    lines.add('✓ ${p.relative(dest.path, from: project.root)}: ${keep.join(', ')}${locale == s.id ? '' : ' (${s.id})'}');
  }
  return lines;
}
