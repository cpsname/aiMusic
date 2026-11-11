import 'dart:convert';
import 'dart:io';

import '../core/errors.dart';

/// One stretch of a rendered preview.
class EdlSegment {
  const EdlSegment({required this.kind, required this.id, required this.beat, required this.from, required this.to, this.detail = const {}});

  factory EdlSegment.fromJson(Map<String, Object?> j) => EdlSegment(
    kind: '${j['kind']}',
    id: '${j['id']}',
    beat: '${j['beat']}',
    from: (j['from']! as num).toDouble(),
    to: (j['to']! as num).toDouble(),
    detail: (j['detail'] as Map?)?.cast<String, Object?>() ?? const {},
  );

  /// `footage` (app screen capture), `card` or `bridge`.
  final String kind;
  final String id;
  final String beat;
  final double from;
  final double to;

  /// footage: `source_from`, `source_to` (recording seconds), `speed`,
  /// `finished` (the finished product is on screen);
  /// card: `card` (intro/outro), `background` (image/footage/color), `media`;
  /// bridge: `media`.
  final Map<String, Object?> detail;

  double get length => to - from;

  Map<String, Object?> toJson() => {'kind': kind, 'id': id, 'beat': beat, 'from': from, 'to': to, 'detail': detail};
}

/// A transition between two stretches.
class EdlTransition {
  const EdlTransition({required this.at, required this.type, required this.duration, required this.between});

  factory EdlTransition.fromJson(Map<String, Object?> j) => EdlTransition(
    at: (j['at']! as num).toDouble(),
    type: '${j['type']}',
    duration: (j['duration']! as num).toDouble(),
    between: '${j['between']}',
  );

  final double at;

  /// `dissolve`, `fade` or `cut`.
  final String type;
  final double duration;

  /// `<segment>→<segment>`.
  final String between;

  Map<String, Object?> toJson() => {'at': at, 'type': type, 'duration': duration, 'between': between};
}

/// Text on screen.
class EdlText {
  const EdlText({required this.source, required this.key, required this.text, required this.from, required this.to});

  factory EdlText.fromJson(Map<String, Object?> j) => EdlText(
    source: '${j['source']}',
    key: '${j['key']}',
    text: '${j['text']}',
    from: (j['from']! as num).toDouble(),
    to: (j['to']! as num).toDouble(),
  );

  /// `caption`, `claim`, `brand`, `cta`, `disclosure`.
  final String source;
  final String key;
  final String text;
  final double from;
  final double to;

  Map<String, Object?> toJson() => {'source': source, 'key': key, 'text': text, 'from': from, 'to': to};
}

/// A manifest item the preview shows or plays.
class EdlMedia {
  const EdlMedia({required this.id, required this.role, required this.use, required this.license});

  factory EdlMedia.fromJson(Map<String, Object?> j) => EdlMedia(
    id: '${j['id']}',
    role: '${j['role']}',
    use: '${j['use']}',
    license: (j['license'] as Map?)?.cast<String, Object?>() ?? const {},
  );

  final String id;
  final String role;

  /// `soundtrack`, `voiceover`, `card`, `bridge`.
  final String use;
  final Map<String, Object?> license;

  Map<String, Object?> toJson() => {'id': id, 'role': role, 'use': use, 'license': license};
}

/// The edit decision list of one rendered preview (`<script>.edl.json`):
/// what is footage and what is not, every transition, every text, every
/// licensed item — what the compliance and narrative layers check on the
/// output.
class Edl {
  const Edl({
    required this.app,
    required this.script,
    required this.storefront,
    required this.slot,
    required this.duration,
    required this.posterAt,
    required this.footageScale,
    required this.segments,
    required this.transitions,
    required this.texts,
    required this.media,
  });

  factory Edl.fromJson(Map<String, Object?> j) {
    List<Map<String, Object?>> list(String key) => [for (final e in (j[key] as List? ?? const [])) (e as Map).cast<String, Object?>()];
    return Edl(
      app: '${j['app']}',
      script: '${j['script']}',
      storefront: '${j['storefront']}',
      slot: '${j['slot']}',
      duration: (j['duration']! as num).toDouble(),
      posterAt: (j['poster_at']! as num).toDouble(),
      footageScale: (j['footage_scale']! as num).toDouble(),
      segments: [for (final s in list('segments')) EdlSegment.fromJson(s)],
      transitions: [for (final t in list('transitions')) EdlTransition.fromJson(t)],
      texts: [for (final t in list('texts')) EdlText.fromJson(t)],
      media: [for (final m in list('media')) EdlMedia.fromJson(m)],
    );
  }

  factory Edl.load(String path) {
    final file = File(path);
    if (!file.existsSync()) throw ConfigError('no EDL at $path');
    return Edl.fromJson(jsonDecode(file.readAsStringSync()) as Map<String, Object?>);
  }

  final String app;
  final String script;
  final String storefront;
  final String slot;
  final double duration;
  final double posterAt;

  /// The factor the footage was scaled by to fit the slot (≤ 1: never
  /// enlarged).
  final double footageScale;
  final List<EdlSegment> segments;
  final List<EdlTransition> transitions;
  final List<EdlText> texts;
  final List<EdlMedia> media;

  double secondsOf(String kind) => segments.where((s) => s.kind == kind).fold(0, (t, s) => t + s.length);

  /// Share of the timeline that is app footage.
  double get footageRatio => duration <= 0 ? 0 : secondsOf('footage') / duration;

  Map<String, Object?> toJson() => {
    'app': app,
    'script': script,
    'storefront': storefront,
    'slot': slot,
    'duration': duration,
    'poster_at': posterAt,
    'footage_scale': footageScale,
    'segments': [for (final s in segments) s.toJson()],
    'transitions': [for (final t in transitions) t.toJson()],
    'texts': [for (final t in texts) t.toJson()],
    'media': [for (final m in media) m.toJson()],
  };

  void write(String path) => File(path).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(toJson())}\n');
}
