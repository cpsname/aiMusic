import 'dart:convert';
import 'dart:io';

import '../core/errors.dart';
import '../timeline/edl.dart';
import 'layout.dart';

/// A file a creative asset is made from, by its SHA-256: a take's recording,
/// the backdrop image, the brand icon (the lineage the manifest's
/// `derived_from` points into).
class CreativeSource {
  const CreativeSource({required this.kind, required this.file, required this.sha256, this.detail = const {}});

  factory CreativeSource.fromJson(Map<String, Object?> j) => CreativeSource(
    kind: '${j['kind']}',
    file: '${j['file']}',
    sha256: '${j['sha256']}',
    detail: (j['detail'] as Map?)?.cast<String, Object?>() ?? const {},
  );

  /// `recording`, `backdrop`, `icon`.
  final String kind;

  /// Repo-relative.
  final String file;
  final String sha256;

  /// recording: `script`, `run`, `storefront`.
  final Map<String, Object?> detail;

  Map<String, Object?> toJson() => {'kind': kind, 'file': file, 'sha256': sha256, 'detail': detail};
}

/// The edit decision list of one creative asset (`<id>.edl.json`, next to
/// it): where every element sits, which footage plays when, every text,
/// every licensed item, every source file with its hash and the parameters it
/// went through, and what was measured — what the compliance and narrative
/// layers check, and the evidence the manifest points at.
class CreativeEdl {
  const CreativeEdl({
    required this.app,
    required this.asset,
    required this.definition,
    required this.type,
    required this.storefront,
    required this.placements,
    required this.targets,
    required this.spec,
    required this.aspect,
    required this.width,
    required this.height,
    required this.duration,
    required this.posterAt,
    required this.template,
    required this.rhythm,
    required this.composition,
    required this.frame,
    required this.segments,
    required this.transitions,
    required this.texts,
    required this.media,
    this.primaryMedia = const [],
    required this.sources,
    required this.parameters,
    required this.measurements,
    required this.tags,
  });

  factory CreativeEdl.fromJson(Map<String, Object?> j) {
    List<Map<String, Object?>> list(String key) => [for (final e in (j[key] as List? ?? const [])) (e as Map).cast<String, Object?>()];
    return CreativeEdl(
      app: '${j['app']}',
      asset: '${j['asset']}',
      definition: '${j['definition']}',
      type: '${j['type']}',
      storefront: j['storefront'] as String?,
      placements: [for (final v in j['placements'] as List) '$v'],
      targets: [for (final v in j['targets'] as List) '$v'],
      spec: '${j['spec']}',
      aspect: '${j['aspect']}',
      width: (j['width']! as num).toInt(),
      height: (j['height']! as num).toInt(),
      duration: (j['duration']! as num).toDouble(),
      posterAt: (j['poster_at'] as num?)?.toDouble(),
      template: j['template'] as String?,
      rhythm: (j['rhythm'] as num?)?.toInt(),
      composition: Composition.fromJson((j['composition']! as Map).cast<String, Object?>()),
      frame: (j['frame'] as Map?)?.cast<String, Object?>(),
      segments: [for (final s in list('segments')) EdlSegment.fromJson(s)],
      transitions: [for (final t in list('transitions')) EdlTransition.fromJson(t)],
      texts: [for (final t in list('texts')) EdlText.fromJson(t)],
      media: [for (final m in list('media')) EdlMedia.fromJson(m)],
      primaryMedia: [for (final v in (j['primary_media'] as List? ?? const [])) '$v'],
      sources: [for (final s in list('sources')) CreativeSource.fromJson(s)],
      parameters: (j['parameters'] as Map?)?.cast<String, Object?>() ?? const {},
      measurements: {for (final e in ((j['measurements'] as Map?) ?? const {}).entries) '${e.key}': (e.value as num).toDouble()},
      tags: [for (final v in (j['tags'] as List? ?? const [])) '$v'],
    );
  }

  factory CreativeEdl.load(String path) {
    final file = File(path);
    if (!file.existsSync()) throw ConfigError('no EDL at $path');
    return CreativeEdl.fromJson(jsonDecode(file.readAsStringSync()) as Map<String, Object?>);
  }

  final String app;

  /// The manifest entry id.
  final String asset;
  final String definition;

  /// The contract type: `header_image`, `search_video`, ….
  final String type;

  /// The storefront, or null for a universal asset.
  final String? storefront;
  final List<String> placements;
  final List<String> targets;
  final String spec;
  final String aspect;
  final int width;
  final int height;

  /// Seconds (0 for an image).
  final double duration;
  final double? posterAt;
  final String? template;
  final int? rhythm;
  final Composition composition;

  /// image: the frame shown — `script`, `scene`, `at` (into the scene),
  /// `source_at` (recording seconds), `run`, `finished`.
  final Map<String, Object?>? frame;

  /// video: footage segments (`detail`: `script`, `scene`, `run`,
  /// `source_from`, `source_to`, `finished`).
  final List<EdlSegment> segments;
  final List<EdlTransition> transitions;
  final List<EdlText> texts;
  final List<EdlMedia> media;

  /// The ids of [media] shown in the asset's primary scene — the poster
  /// frame's scene of a video, the frame of an image — first in the order
  /// the manifest's `authorization` takes them (template ADR-0014).
  final List<String> primaryMedia;
  final List<CreativeSource> sources;

  /// The backdrop's treatment and the encode.
  final Map<String, Object?> parameters;

  /// `contrast_mean`, `contrast_p90`, `loop_psnr`, ….
  final Map<String, double> measurements;
  final List<String> tags;

  bool get isVideo => type.endsWith('_video');

  Map<String, Object?> toJson() => {
    'app': app,
    'asset': asset,
    'definition': definition,
    'type': type,
    'storefront': storefront,
    'placements': placements,
    'targets': targets,
    'spec': spec,
    'aspect': aspect,
    'width': width,
    'height': height,
    'duration': duration,
    'poster_at': posterAt,
    'template': template,
    'rhythm': rhythm,
    'composition': composition.toJson(),
    'frame': frame,
    'segments': [for (final s in segments) s.toJson()],
    'transitions': [for (final t in transitions) t.toJson()],
    'texts': [for (final t in texts) t.toJson()],
    'media': [for (final m in media) m.toJson()],
    'primary_media': primaryMedia,
    'sources': [for (final s in sources) s.toJson()],
    'parameters': parameters,
    'measurements': measurements,
    'tags': tags,
  };

  void write(String path) => File(path).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(toJson())}\n');
}
