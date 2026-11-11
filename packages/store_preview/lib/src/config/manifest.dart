import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../core/probe.dart';
import 'app.dart';
import 'script.dart';

/// The manifest schema this tool reads (docs: README › Media manifest).
const int manifestSchema = 2;

/// Media types and the stream each must hold.
const Set<String> mediaTypes = {'audio', 'video', 'image'};

/// Where a piece of media came from, and the proof the app may show it:
/// [id] is the generation's (or license's) identifier at [provider].
class License {
  const License({required this.provider, required this.id, required this.model, required this.generatedAt});

  final String provider;
  final String id;
  final String model;
  final String generatedAt;

  Map<String, Object?> toJson() => {'provider': provider, 'id': id, 'model': model, 'generated_at': generatedAt};
}

/// One manifest entry (schema 2).
class MediaEntry {
  MediaEntry(this.raw, this.dir);

  final Map<String, Object?> raw;

  /// The manifest's directory (files resolve against it).
  final String dir;

  String _s(String key) => raw[key] is String ? raw[key]! as String : '';

  String get id => _s('id');
  String get type => _s('type');
  String get role => _s('role');
  String get locale => _s('locale');
  String get script => _s('script');
  String get relativeFile => _s('file');
  String get file => p.normalize(p.join(dir, relativeFile));

  Map<String, Object?> get _license => raw['license'] is Map ? (raw['license']! as Map).cast<String, Object?>() : const {};

  License get license => License(
    provider: '${_license['provider'] ?? ''}',
    id: '${_license['id'] ?? ''}',
    model: '${_license['model'] ?? ''}',
    generatedAt: '${_license['generated_at'] ?? ''}',
  );

  /// Values the scripts read as `{name}`.
  Map<String, String> get vars => {
    if (raw['vars'] is Map)
      for (final e in (raw['vars']! as Map).entries)
        if (e.value != null) '${e.key}': '${e.value}',
  };

  /// The app's own data about the item (the tool never reads it).
  Map<String, Object?> get data => raw['data'] is Map ? (raw['data']! as Map).cast<String, Object?>() : const {};

  String get label => '$id (${relativeFile.isEmpty ? 'no file' : relativeFile})';
}

class Manifest {
  Manifest(this.path, this.entries);

  /// Reads a manifest; a missing file is an error (nothing is recorded or
  /// rendered without the app's own media).
  factory Manifest.load(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw ConfigError('no media manifest at $path — the app\'s media generator writes it '
          '(README › Media manifest). Nothing is recorded or rendered without it.');
    }
    final Object? raw;
    try {
      raw = jsonDecode(file.readAsStringSync());
    } on FormatException catch (e) {
      throw ConfigError('$path: not JSON (${e.message})');
    }
    if (raw is! Map || raw['schema'] != manifestSchema) {
      throw ConfigError('$path: "schema": $manifestSchema expected (found ${raw is Map ? raw['schema'] : 'no object'})');
    }
    final list = raw['entries'];
    if (list is! List) throw ConfigError('$path: no "entries" list');
    final dir = p.dirname(p.absolute(path));
    return Manifest(path, [
      for (final e in list)
        if (e is Map) MediaEntry(e.cast<String, Object?>(), dir) else throw ConfigError('$path: an entry is not an object'),
    ]);
  }

  final String path;
  final List<MediaEntry> entries;

  /// The entries of a role for a script and storefront, by id.
  List<MediaEntry> select({required String role, required String script, required String locale}) =>
      entries.where((e) => e.role == role && e.script == script && e.locale == locale).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  /// The entry [ref] points at from [script] in [storefront].
  MediaEntry resolve(MediaRef ref, {required String script, required String storefront}) {
    final found = select(role: ref.role, script: ref.scriptFor(script), locale: ref.localeFor(storefront));
    if (ref.index >= found.length) {
      throw ConfigError('no media $ref for ${ref.scriptFor(script)}/${ref.localeFor(storefront)} '
          '(${found.length} ${ref.role} entr${found.length == 1 ? 'y' : 'ies'}) in $path');
    }
    return found[ref.index];
  }
}

/// Validates [manifest] for [app] and its active [scripts]: every entry is
/// well formed, licensed and probes as its type; every script's
/// requirements and references are met in every storefront.
Problems validateManifest(
  Manifest manifest,
  PreviewApp app,
  Map<String, PreviewScript> scripts, {
  Prober prober = const FfprobeProber(),
}) {
  final problems = Problems();
  final locales = {for (final s in app.storefronts) s.id};
  final ids = <String>{};
  for (final e in manifest.entries) {
    for (final key in ['id', 'type', 'role', 'locale', 'script', 'file']) {
      problems.check(e.raw[key] is String && (e.raw[key]! as String).trim().isNotEmpty, '${e.label}: $key is missing or empty');
    }
    problems.check(ids.add(e.id), '${e.label}: duplicate id');
    problems.check(mediaTypes.contains(e.type), '${e.label}: type "${e.type}" (audio | video | image)');
    problems.check(locales.contains(e.locale), '${e.label}: locale ${e.locale} is not a storefront of ${app.id}');
    problems.check(
      scripts.containsKey(e.script),
      '${e.label}: script ${e.script} is not an active script (${scripts.keys.join(', ')}) — move it to the archive',
    );
    final license = e.license;
    problems.check(license.provider.trim().isNotEmpty, '${e.label}: license.provider is empty');
    problems.check(license.id.trim().isNotEmpty, '${e.label}: license.id is empty — no proof the app may show it');
    problems.check(license.model.trim().isNotEmpty, '${e.label}: license.model is empty');
    problems.check(DateTime.tryParse(license.generatedAt) != null, '${e.label}: license.generated_at is not an ISO 8601 time');
    if (e.relativeFile.isEmpty) continue;
    if (!File(e.file).existsSync()) {
      problems.add('${e.label}: file not found (${e.file})');
      continue;
    }
    final info = prober.probe(e.file);
    switch (e.type) {
      case 'audio':
        problems.check(info?.audio != null && info?.video == null, '${e.label}: an audio entry holds one audio stream and no picture');
      case 'video':
        problems.check(info?.video != null, '${e.label}: no video stream');
      case 'image':
        problems.check(
          const {'.jpg', '.jpeg', '.png', '.heic'}.contains(p.extension(e.file).toLowerCase()),
          '${e.label}: images are JPEG, PNG or HEIC',
        );
        problems.check((info?.video?.width ?? 0) >= 512, '${e.label}: the image is under 512 px wide');
    }
  }

  for (final script in scripts.values) {
    for (final r in script.requires) {
      final owner = r.script ?? script.id;
      for (final locale in r.locales ?? locales.toList()) {
        final found = manifest.select(role: r.role, script: owner, locale: locale);
        problems.check(
          found.length == r.count,
          '${script.id}: needs ${r.count} ${r.role} for $owner/$locale, the manifest holds ${found.length}',
        );
        for (final e in found) {
          for (final v in r.vars) {
            problems.check((e.vars[v] ?? '').trim().isNotEmpty, '${e.label}: vars.$v is missing (${script.id} reads it)');
          }
        }
      }
    }
    for (final ref in script.mediaRefs) {
      for (final s in app.storefronts) {
        final found = manifest.select(role: ref.role, script: ref.scriptFor(script.id), locale: ref.localeFor(s.id));
        problems.check(found.length > ref.index, '${script.id}: refers to $ref, missing for ${s.id}');
      }
    }
    for (final sc in script.scenes.where((sc) => sc.audio != null)) {
      for (final s in app.storefronts) {
        final found = manifest.select(role: sc.audio!.role, script: sc.audio!.scriptFor(script.id), locale: sc.audio!.localeFor(s.id));
        if (found.length <= sc.audio!.index) continue;
        final e = found[sc.audio!.index];
        if (!File(e.file).existsSync()) continue;
        problems.check(
          prober.probe(e.file)?.audio != null,
          '${script.id}/${sc.id}: ${e.label} plays under the scene but has no audio stream',
        );
      }
    }
  }
  return problems;
}
