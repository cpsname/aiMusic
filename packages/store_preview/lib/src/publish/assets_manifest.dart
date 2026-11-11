import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../config/app.dart';
import '../core/errors.dart';
import '../core/probe.dart';
import '../creative/composer.dart';
import '../creative/contract.dart';
import '../creative/edl.dart';
import '../creative/review.dart';

/// `dist/<app>/assets-manifest.json`: every creative asset of the app, in the
/// contract ascpub owns (template ADR-0010). Paths are relative to the
/// manifest; every measured value is measured on the final file.
const String assetsManifestName = 'assets-manifest.json';

String _sha256(String path) => sha256.convert(File(path).readAsBytesSync()).toString();

/// `20261008T101500Z` → `2026-10-08T10:15:00Z` (the take's start).
String? runTime(String run) {
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$').firstMatch(run);
  return m == null ? null : '${m[1]}-${m[2]}-${m[3]}T${m[4]}:${m[5]}:${m[6]}Z';
}

/// The tool's name, version and (template) commit.
Future<Map<String, Object?>> generatorInfo({required String packageRoot}) async {
  final pubspec = File(p.join(packageRoot, 'pubspec.yaml')).readAsStringSync();
  final version = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec)?.group(1) ?? '0.0.0';
  final stamp = File(p.join(packageRoot, 'VENDOR.json'));
  String? commit;
  if (stamp.existsSync()) {
    commit = '${(jsonDecode(stamp.readAsStringSync()) as Map)['template_commit']}';
  } else {
    final git = await Process.run('git', ['-C', packageRoot, 'rev-parse', 'HEAD']);
    if (git.exitCode == 0) commit = '${git.stdout}'.trim();
  }
  return {'name': 'store_preview', 'version': version, 'commit': ?commit};
}

/// One manifest entry for [job], from its files and EDL.
Map<String, Object?> manifestEntry(
  CreativeJob job,
  CreativeFiles files, {
  required PreviewApp app,
  required ReviewLog review,
  Prober prober = const FfprobeProber(),
}) {
  final edl = CreativeEdl.load(files.edl);
  final info = prober.probe(files.file) ?? (throw ToolError('cannot probe ${files.file}'));
  final v = info.video ?? (throw ToolError('${files.file} has no picture'));
  String rel(String path) => p.relative(path, from: files.distDir);
  final video = job.asset.isVideo;

  // Authorization: per field, the license id of the primary scene's item
  // first, then the other shown items in timeline order, the backdrop last
  // (template ADR-0014). The EDL (`source.evidence`) lists every one.
  final authorization = <String, Object?>{'interaction_id': null, 'mv_id': null, 'generation_id': null};
  final providers = <String>{};
  final ordered = [for (final id in edl.primaryMedia) edl.media.firstWhere((m) => m.id == id), ...edl.media.where((m) => !edl.primaryMedia.contains(m.id))];
  for (final m in ordered) {
    final field = app.creatives.authorization[m.role];
    if (field == null) throw ConfigError('${job.id}: app.yaml creatives.authorization maps no ${m.role}');
    final id = '${m.license['id'] ?? ''}'.trim();
    if (id.isEmpty) throw ConfigError('${job.id}: ${m.id} is shown without a license id');
    authorization[field] ??= id;
    providers.add('${m.license['provider']}');
  }
  final runs = <String>[for (final s in edl.sources.where((s) => s.kind == 'recording')) '${s.detail['run']}'];
  // Scripts in order of first appearance.
  final scripts = <String>{for (final seg in edl.segments) '${seg.detail['script']}', if (edl.frame != null) '${edl.frame!['script']}'};
  final takes = [for (final r in runs.toSet()) runTime(r) ?? r];
  final realUi = review.realUi(job.slot, job.asset, files: files) ?? false;
  return {
    'id': job.id,
    'type': edl.type,
    'file': rel(files.file),
    'sha256': _sha256(files.file),
    'bytes': File(files.file).lengthSync(),
    'mime': video ? 'video/mp4' : 'image/png',
    'pixels': {'width': v.width, 'height': v.height},
    'aspect_ratio': edl.aspect,
    if (!video) 'has_alpha': v.mayHaveAlpha,
    if (video)
      'video': {
        'duration_s': double.parse(info.duration.toStringAsFixed(3)),
        'fps': double.parse(v.frameRate.toStringAsFixed(3)),
        'has_audio': info.audioStreams > 0,
        'rotation': v.rotation,
        'codec': v.codec,
        'container': info.container,
        'poster': {'file': rel(files.poster), 'sha256': _sha256(files.poster), 'at_s': edl.posterAt},
      },
    'locale': job.storefront,
    'placement_intents': [
      for (final pl in edl.placements)
        for (final t in edl.targets) {'placement': pl, 'target': t},
    ],
    'display_target': job.slot.displayTarget,
    'source': {'kind': 'composited', 'real_ui': realUi, 'script': scripts.join('+'), 'take': takes.join('+'), 'evidence': rel(files.edl)},
    'authorization': {...authorization, 'license_provider': providers.isEmpty ? null : (providers.toList()..sort()).join('+')},
    'experiment_tags': edl.tags,
    // The footage the asset was cut from: the primary scene's recording, by
    // hash; the EDL lists every source with its hash and parameters.
    'derived_from': primaryRecording(edl).sha256,
  };
}

/// The entry of [alias]: its rendered asset's [entry] — the same file,
/// measurements, placements and review — under the localization it serves,
/// derived from that entry (template ADR-0017). ascpub uploads one file once
/// (its assets are keyed by content) and binds it to each localization.
Map<String, Object?> aliasEntry(Map<String, Object?> entry, CreativeAlias alias) => {
  ...entry,
  'id': alias.id,
  'locale': alias.locale,
  'derived_from': alias.job.id,
};

/// The recording the asset's primary scene was cut from: the frame's run
/// (an image), the run of the segment holding the poster frame (a video).
CreativeSource primaryRecording(CreativeEdl edl) {
  final poster = edl.posterAt;
  final run =
      edl.frame?['run'] ??
      edl.segments.where((s) => poster != null && poster >= s.from && poster < s.to).firstOrNull?.detail['run'] ??
      edl.segments.firstOrNull?.detail['run'];
  final recordings = edl.sources.where((s) => s.kind == 'recording');
  return recordings.where((s) => s.detail['run'] == run).firstOrNull ??
      (throw ConfigError('${edl.asset}: the EDL names no recording for its primary scene (run $run)'));
}

/// The manifest for every job in [jobs] (all of the app's assets).
Future<Map<String, Object?>> buildAssetsManifest(
  List<CreativeJob> jobs, {
  required PreviewApp app,
  required String distDir,
  required ReviewLog review,
  required ManifestContract contract,
  required Map<String, Object?> generator,
  required String Function() now,
  Prober prober = const FfprobeProber(),
}) async {
  final missing = <String>[];
  final entries = <Map<String, Object?>>[];
  for (final job in jobs) {
    final files = CreativeFiles(distDir: distDir, id: job.id, storefront: job.storefront, video: job.asset.isVideo);
    if (!File(files.file).existsSync() || !File(files.edl).existsSync()) {
      missing.add(job.id);
      continue;
    }
    entries.add(manifestEntry(job, files, app: app, review: review, prober: prober));
  }
  if (missing.isNotEmpty) {
    throw ConfigError(
      'the assets manifest lists every asset; ${missing.length} not rendered '
      '(${missing.take(6).join(', ')}${missing.length > 6 ? ', …' : ''}) — render them (render --locales all)',
    );
  }
  final byId = {for (final e in entries) e['id']! as String: e};
  for (final alias in creativeAliases(jobs, app)) {
    entries.add(aliasEntry(byId[alias.job.id]!, alias));
  }
  final manifest = <String, Object?>{
    'schema': contract.version,
    'generated_at': now(),
    'generator': generator,
    'app': {'bundle_id': app.bundleId, 'store_preview_app': app.id},
    'entries': entries,
  };
  final violations = contract.violations(jsonDecode(jsonEncode(manifest)));
  if (violations.isNotEmpty) {
    throw ConfigError('the assets manifest breaks the contract (ascpub ${contract.commit}):\n${violations.map((v) => '  ✗ $v').join('\n')}');
  }
  return manifest;
}

/// App Review 2.3.3: in each localization × display target's screenshots,
/// those that show the app in use (`real_ui`, from the human review) are
/// more than half. A mechanical count; the verdicts are people's.
List<String> screenshotMajority(List<Map<String, Object?>> entries) {
  final groups = <String, ({int total, int real})>{};
  for (final e in entries.where((e) => e['type'] == 'screenshot')) {
    final key = '${e['locale'] ?? '*'} × ${e['display_target']}';
    final g = groups[key] ?? (total: 0, real: 0);
    final real = (e['source'] as Map?)?['real_ui'] == true;
    groups[key] = (total: g.total + 1, real: g.real + (real ? 1 : 0));
  }
  return [
    for (final MapEntry(key: k, value: g) in groups.entries)
      if (!(g.real > g.total / 2)) '$k: ${g.real} of ${g.total} screenshots show the app in use (more than half must, App Review 2.3.3)',
  ];
}

/// The written manifest against the contract and against the files it
/// names: hashes, sizes and everything measured, measured again.
List<String> checkAssetsManifest(String path, {required ManifestContract contract, Prober prober = const FfprobeProber()}) {
  final file = File(path);
  if (!file.existsSync()) return ['no $path'];
  final json = jsonDecode(file.readAsStringSync());
  final problems = [for (final v in contract.violations(json)) 'contract: $v'];
  if (problems.isNotEmpty || json is! Map) return problems;
  final dir = p.dirname(path);
  final entries = [for (final e in json['entries'] as List) (e as Map).cast<String, Object?>()];
  final ids = <String>{};
  for (final e in entries) {
    final id = '${e['id']}';
    if (!ids.add(id)) problems.add('$id: duplicate id');
    final f = p.join(dir, '${e['file']}');
    if (!File(f).existsSync()) {
      problems.add('$id: ${e['file']} is missing');
      continue;
    }
    if (_sha256(f) != e['sha256']) problems.add('$id: ${e['file']} changed after the manifest was written (SHA-256)');
    if (File(f).lengthSync() != e['bytes']) problems.add('$id: bytes ≠ the file');
    final v = prober.probe(f)?.video;
    final px = e['pixels'] as Map;
    if (v == null || v.width != px['width'] || v.height != px['height']) problems.add('$id: pixels ≠ the file');
    if (e.containsKey('has_alpha') && v != null && v.mayHaveAlpha != e['has_alpha']) problems.add('$id: has_alpha ≠ the file');
    final video = e['video'] as Map?;
    if (video != null) {
      final info = prober.probe(f)!;
      if ((info.duration - (video['duration_s'] as num)).abs() > 0.01) problems.add('$id: duration_s ≠ the file');
      if (v != null && (v.frameRate - (video['fps'] as num)).abs() > 0.01) problems.add('$id: fps ≠ the file');
      if ((info.audioStreams > 0) != video['has_audio']) problems.add('$id: has_audio ≠ the file');
      if (v != null && v.rotation != video['rotation']) problems.add('$id: rotation ≠ the file');
      final poster = video['poster'] as Map?;
      if (poster != null) {
        final pf = p.join(dir, '${poster['file']}');
        if (!File(pf).existsSync() || _sha256(pf) != poster['sha256']) problems.add('$id: the poster frame ≠ the manifest');
      }
    }
    final evidence = (e['source'] as Map?)?['evidence'];
    if (evidence != null && !File(p.join(dir, '$evidence')).existsSync()) problems.add('$id: evidence $evidence is missing');
  }
  problems.addAll(screenshotMajority(entries));
  return problems;
}
