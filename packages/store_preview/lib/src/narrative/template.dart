import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../core/fields.dart';

/// The rhythms a template of a format must offer (seconds) and the window
/// any further rhythm of it lies in: an App Preview (`preview`, 15–30 s) or a
/// creative asset's muted loop (`loop`, the product page header and search
/// results videos, 5–30 s; 8 and 12 s are the short loops Apple's "start
/// strong" suits, a template may add longer ones for a spec with a higher
/// floor — defaults/creative.yaml).
const Map<String, ({List<int> required, int min, int max})> rhythmPolicy = {
  'preview': (required: [15, 22, 25], min: 15, max: 30),
  'loop': (required: [8, 12], min: 5, max: 30),
};

/// One beat of a narrative template.
class Beat {
  const Beat({required this.id, required this.kind, required this.optional, required this.finished});

  factory Beat.read(Fields f) {
    f.only({'id', 'kind', 'optional', 'finished'});
    final kind = f.string('kind');
    if (!const {'card', 'scene', 'bridge'}.contains(kind)) throw ConfigError('${f.where} › kind: card, scene or bridge');
    return Beat(
      id: f.string('id'),
      kind: kind,
      optional: f.boolean('optional', fallback: false),
      finished: f.boolean('finished', fallback: false),
    );
  }

  final String id;

  /// The segment kind that plays it: card, scene or bridge.
  final String kind;
  final bool optional;

  /// Its scenes show the finished product (and may hold the poster frame).
  final bool finished;
}

/// A narrative template (`templates/<id>.yaml`): ordered beats, three rhythms
/// with each beat's nominal seconds, and the muted-autoplay hook rule.
class NarrativeTemplate {
  const NarrativeTemplate({
    required this.id,
    required this.format,
    required this.title,
    required this.description,
    required this.beats,
    required this.rhythms,
    required this.flex,
    required this.hookSeconds,
  });

  factory NarrativeTemplate.read(Fields f, String fileId) {
    f.only({'id', 'format', 'title', 'description', 'beats', 'rhythms', 'flex', 'hook'});
    final id = f.string('id');
    if (id != fileId) throw ConfigError('${f.where} › id: must equal the file name');
    final format = f.optString('format') ?? 'preview';
    final policy = rhythmPolicy[format] ?? (throw ConfigError('${f.where} › format: ${rhythmPolicy.keys.join(' or ')}'));
    final beats = [for (final b in f.maps('beats', required: true)) Beat.read(b)];
    final beatIds = beats.map((b) => b.id).toSet();
    if (beatIds.length != beats.length) throw ConfigError('${f.where} › beats: duplicate id');
    final rhythmsField = f.map('rhythms');
    final rhythms = <int, Map<String, double>>{};
    for (final key in rhythmsField.raw.keys) {
      final seconds = int.tryParse(key) ?? (throw ConfigError('${rhythmsField.where} › $key: not whole seconds'));
      final r = rhythmsField.map(key);
      r.only(beatIds);
      rhythms[seconds] = {for (final b in r.raw.keys) b: r.number(b)};
    }
    for (final s in policy.required) {
      if (!rhythms.containsKey(s)) throw ConfigError('${rhythmsField.where}: the $s s rhythm is missing (every $format template offers ${policy.required.join(' / ')})');
    }
    for (final s in rhythms.keys) {
      if (s < policy.min || s > policy.max) throw ConfigError('${rhythmsField.where} › $s: a $format lasts ${policy.min}–${policy.max} s');
      for (final b in beats.where((b) => !b.optional)) {
        if (!rhythms[s]!.containsKey(b.id)) throw ConfigError('${rhythmsField.where} › $s: the required beat ${b.id} has no seconds');
      }
    }
    if (format == 'loop' && beats.any((b) => b.kind != 'scene')) {
      throw ConfigError('${f.where} › beats: a loop plays app footage only (kind: scene)');
    }
    final hook = f.optMap('hook');
    hook?.only({'seconds'});
    return NarrativeTemplate(
      id: id,
      format: format,
      title: f.string('title'),
      description: f.string('description'),
      beats: beats,
      rhythms: rhythms,
      flex: f.optNumber('flex', 2.0),
      hookSeconds: hook?.optNumber('seconds', 3) ?? 3,
    );
  }

  final String id;

  /// `preview` (an App Preview: cards, scenes, bridges) or `loop` (a creative
  /// asset's muted loop: scenes only, its end dissolving into its start).
  final String format;
  final String title;
  final String description;
  final List<Beat> beats;

  /// rhythm seconds → beat → nominal seconds. A beat a rhythm leaves out is
  /// not played in it.
  final Map<int, Map<String, double>> rhythms;

  /// How far a script may stretch or squeeze any beat (seconds).
  final double flex;

  /// The first seconds a muted autoplay must explain with on-screen text.
  final double hookSeconds;

  Beat? beat(String id) => beats.where((b) => b.id == id).firstOrNull;
}

/// The templates shipped with the tool (`<package>/templates`) plus an
/// app's own (`store_preview/<app>/templates`, same schema): an app may add
/// templates, never redefine a shipped one.
Map<String, NarrativeTemplate> loadTemplates(String packageRoot, {String? appTemplatesDir}) {
  final out = <String, NarrativeTemplate>{};
  void from(String dir, {required bool shipped}) {
    final d = Directory(dir);
    if (!d.existsSync()) return;
    final files = d.listSync().whereType<File>().where((f) => f.path.endsWith('.yaml')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      final id = p.basenameWithoutExtension(f.path);
      if (!shipped && out.containsKey(id)) throw ConfigError('${f.path}: template $id is shipped with the tool — pick another id');
      out[id] = NarrativeTemplate.read(readYamlFile(f.path), id);
    }
  }

  from(p.join(packageRoot, 'templates'), shipped: true);
  if (appTemplatesDir != null) from(appTemplatesDir, shipped: false);
  return out;
}
