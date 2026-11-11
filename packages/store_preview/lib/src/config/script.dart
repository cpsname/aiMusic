import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../core/fields.dart';

/// Apple's App Preview length window (docs/store/apple-preview-rules.md).
const double minPreviewSeconds = 15;
const double maxPreviewSeconds = 30;

/// How far an interaction scene is sped up at most, unless it says otherwise
/// (`max_speed`, at most [maxSpeedLimit]).
const double defaultMaxSpeed = 3;
const double maxSpeedLimit = 5;

/// A manifest entry a script points at: by role, the script and storefront
/// it belongs to (default: this script, the storefront being rendered) and
/// its index among them (by id).
class MediaRef {
  const MediaRef({required this.role, this.script, this.locale, this.index = 0});

  factory MediaRef.read(Fields f) {
    f.only({'role', 'script', 'locale', 'index'});
    return MediaRef(
      role: f.string('role'),
      script: f.optString('script'),
      locale: f.optString('locale'),
      index: f.optInteger('index', 0),
    );
  }

  final String role;
  final String? script;
  final String? locale;
  final int index;

  String scriptFor(String current) => script ?? current;
  String localeFor(String storefront) => locale ?? storefront;

  Map<String, Object?> toJson() => {'role': role, 'script': ?script, 'locale': ?locale, 'index': index};

  @override
  String toString() => '$role${script == null ? '' : '/$script'}${locale == null ? '' : '@$locale'}#$index';
}

/// Media a script needs in every storefront (or in [locales]), with the
/// variables each entry must carry.
class Requirement {
  const Requirement({required this.role, required this.count, required this.script, required this.locales, required this.vars});

  factory Requirement.read(Fields f) {
    f.only({'role', 'count', 'script', 'locales', 'vars'});
    final count = f.optInteger('count', 1);
    if (count < 1) throw ConfigError('${f.where} › count: at least 1');
    return Requirement(
      role: f.string('role'),
      count: count,
      script: f.optString('script'),
      locales: f.has('locales') ? f.strings('locales') : null,
      vars: f.strings('vars'),
    );
  }

  final String role;

  /// Exactly this many entries per storefront.
  final int count;

  /// Whose entries (default: the script's own).
  final String? script;

  /// Fixed storefronts (the same media everywhere); `null` = each storefront.
  final List<String>? locales;

  /// Variables each entry carries (non-empty).
  final List<String> vars;
}

/// What a card shows behind its text.
sealed class CardBackground {
  const CardBackground();

  factory CardBackground.read(Fields? f) {
    if (f == null) return const ColorBackground('primary');
    f.only({'image', 'footage', 'color'});
    final set = [f.has('image'), f.has('footage'), f.has('color')].where((b) => b).length;
    if (set != 1) throw ConfigError('${f.where}: one of image / footage / color');
    if (f.has('image')) return ImageBackground(MediaRef.read(f.map('image')));
    if (f.has('footage')) return const FootageBackground();
    final color = f.string('color');
    if (!const {'primary', 'scrim'}.contains(color) && !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
      throw ConfigError('${f.where} › color: primary, scrim or #RRGGBB');
    }
    return ColorBackground(color);
  }
}

/// A licensed manifest image, blurred, darkened and slowly pushed in.
class ImageBackground extends CardBackground {
  const ImageBackground(this.image);

  final MediaRef image;
}

/// The neighbouring footage frame, blurred and darkened.
class FootageBackground extends CardBackground {
  const FootageBackground();
}

/// A flat brand colour (`primary`, `scrim`) or `#RRGGBB`.
class ColorBackground extends CardBackground {
  const ColorBackground(this.color);

  final String color;
}

/// One stretch of the preview's timeline.
sealed class Segment {
  Segment({required this.id, required this.beat, required this.duration});

  final String id;

  /// The narrative template's beat this segment plays.
  final String beat;
  final double duration;

  /// Set when the timeline is laid out.
  double start = 0;
  double get end => start + duration;

  bool contains(double t) => t >= start - 1e-9 && t < end - 1e-9;
}

/// A brand card: `intro` (icon + the script's claim) or `outro` (icon, name,
/// call to action, purchase disclosure). Full frame, not app footage.
class CardSegment extends Segment {
  CardSegment({required this.kind, required super.duration, required this.textKey, required this.background})
    : super(id: kind, beat: kind);

  /// `intro` or `outro`.
  final String kind;

  /// The intro's claim (an ARB key); the outro's lines come from app.yaml.
  final String? textKey;
  final CardBackground background;
}

/// Footage of the app, filmed by the recording: what the steps do on
/// screen.
class SceneSegment extends Segment {
  SceneSegment({
    required super.id,
    required super.beat,
    required super.duration,
    required this.retime,
    required this.maxSpeed,
    required this.finished,
    required this.follow,
    required this.audio,
    required this.before,
    required this.steps,
    required this.shootOrder,
    this.shows = const [],
  });

  /// The footage may be sped up to fit (interaction); `false` = real time.
  final bool retime;

  /// How far [retime] may speed the footage up.
  final double maxSpeed;

  /// The finished product is on screen: a poster frame may come from here.
  final bool finished;

  /// The playback the scene shows (`song`, `video`, … — the name of a
  /// position reader the app's driver registers): the soundtrack follows
  /// its position. Such a scene runs in real time.
  final String? follow;

  /// The manifest audio (or video soundtrack) that [follow] plays.
  final MediaRef? audio;

  /// Licensed manifest items on screen in this scene besides [audio] (the
  /// photos a picker shows, a generated image in the app's UI): what a
  /// creative asset cut from this scene shows and must license.
  final List<MediaRef> shows;

  /// Off-camera steps before the scene starts, and the scene's own steps.
  final List<Map<String, Object?>> before;
  final List<Map<String, Object?>> steps;

  /// Filming order within the script's take (default: timeline order). A
  /// scene may be filmed before an earlier one, e.g. when the earlier one
  /// ends on system UI the app cannot leave.
  final int shootOrder;
}

/// A short dissolve through a licensed, blurred manifest image between two
/// scenes. Not app footage.
class BridgeSegment extends Segment {
  BridgeSegment({required super.id, required super.beat, required super.duration, required this.image});

  final MediaRef image;
}

class CaptionCue {
  const CaptionCue({required this.key, required this.from, required this.to});

  /// ARB key (the caption prefix).
  final String key;
  final double from;
  final double to;
}

/// A script (`store_preview/<app>/scripts/<id>.yaml`): a `preview` (an App
/// Preview's timeline) or a `capture` (scenes filmed only as footage for
/// creative assets, never a preview of its own).
class PreviewScript {
  PreviewScript({
    required this.id,
    this.kind = 'preview',
    required this.title,
    required this.template,
    required this.rhythm,
    required this.posterAt,
    required this.endsOnSystemUi,
    required this.soundtrack,
    required this.requires,
    required this.setup,
    required this.segments,
    required this.captions,
  }) {
    var at = 0.0;
    for (final s in segments) {
      s.start = at;
      at += s.duration;
    }
  }

  final String id;

  /// `preview` or `capture`.
  final String kind;
  final String title;

  bool get isCapture => kind == 'capture';

  /// The narrative template (`templates/<id>.yaml`) and its rhythm (seconds).
  final String template;
  final int rhythm;

  /// The poster frame's time code.
  final double posterAt;

  /// The take ends on system UI the app cannot dismiss (a share sheet):
  /// filmed after the app's other scripts.
  final bool endsOnSystemUi;

  /// `follow` (scenes that follow playback carry the audio) or `none` (a
  /// silent stereo track).
  final String soundtrack;
  final List<Requirement> requires;
  final List<Map<String, Object?>> setup;
  final List<Segment> segments;
  final List<CaptionCue> captions;

  double get duration => segments.fold(0, (t, s) => t + s.duration);

  Iterable<SceneSegment> get scenes => segments.whereType<SceneSegment>();
  Iterable<CardSegment> get cards => segments.whereType<CardSegment>();
  Iterable<BridgeSegment> get bridges => segments.whereType<BridgeSegment>();

  /// Scenes in filming order.
  List<SceneSegment> get shootingOrder {
    final list = scenes.toList();
    final index = {for (final (i, s) in list.indexed) s.id: i};
    list.sort((a, b) {
      final c = a.shootOrder.compareTo(b.shootOrder);
      return c != 0 ? c : index[a.id]!.compareTo(index[b.id]!);
    });
    return list;
  }

  Segment segmentAt(double t) => segments.firstWhere((s) => s.contains(t), orElse: () => segments.last);

  /// Every media reference the script makes (backgrounds, bridges, audio).
  Iterable<MediaRef> get mediaRefs sync* {
    for (final s in segments) {
      switch (s) {
        case CardSegment(background: ImageBackground(:final image)):
          yield image;
        case BridgeSegment(:final image):
          yield image;
        case SceneSegment(audio: final MediaRef audio):
          yield audio;
        default:
      }
    }
  }
}

PreviewScript loadScript(String path) {
  final f = readYamlFile(path);
  final kind = f.optString('kind') ?? 'preview';
  if (kind == 'capture') return _loadCapture(f, path);
  if (kind != 'preview') throw ConfigError('${f.where} › kind: preview or capture');
  f.only({
    'id', 'kind', 'title', 'template', 'rhythm', 'poster_at', 'ends_on_system_ui', 'soundtrack', 'requires', 'setup', //
    'segments', 'captions',
  });
  final id = f.string('id');
  if (id != p.basenameWithoutExtension(path)) throw ConfigError('${f.where} › id: must equal the file name');
  final soundtrack = f.optString('soundtrack') ?? 'follow';
  if (soundtrack != 'follow' && soundtrack != 'none') throw ConfigError('${f.where} › soundtrack: follow or none');

  final segments = <Segment>[];
  final ids = <String>{};
  for (final (i, s) in f.maps('segments', required: true).indexed) {
    final kinds = ['card', 'scene', 'bridge'].where(s.has).toList();
    if (kinds.length != 1) throw ConfigError('${s.where}: one of card / scene / bridge');
    final Segment segment;
    switch (kinds.single) {
      case 'card':
        s.only({'card', 'duration', 'text', 'background'});
        final kind = s.string('card');
        if (kind != 'intro' && kind != 'outro') throw ConfigError('${s.where} › card: intro or outro');
        segment = CardSegment(
          kind: kind,
          duration: s.number('duration'),
          textKey: s.optString('text'),
          background: CardBackground.read(s.optMap('background')),
        );
      case 'bridge':
        s.only({'bridge', 'beat', 'duration', 'image'});
        segment = BridgeSegment(
          id: s.string('bridge'),
          beat: s.optString('beat') ?? 'bridge',
          duration: s.number('duration'),
          image: MediaRef.read(s.map('image')),
        );
      default:
        segment = _readScene(s, i, beat: s.string('beat'));
    }
    if (!ids.add(segment.id)) throw ConfigError('${s.where}: duplicate segment id "${segment.id}"');
    segments.add(segment);
  }
  return PreviewScript(
    id: id,
    title: f.string('title'),
    template: f.string('template'),
    rhythm: f.integer('rhythm'),
    posterAt: f.number('poster_at'),
    endsOnSystemUi: f.boolean('ends_on_system_ui', fallback: false),
    soundtrack: soundtrack,
    requires: [for (final r in f.maps('requires')) Requirement.read(r)],
    setup: f.steps('setup'),
    segments: segments,
    captions: [
      for (final c in f.maps('captions'))
        () {
          c.only({'key', 'from', 'to'});
          return CaptionCue(key: c.string('key'), from: c.number('from'), to: c.number('to'));
        }(),
    ],
  );
}

SceneSegment _readScene(Fields s, int index, {required String beat}) {
  s.only({
    'scene', 'beat', 'duration', 'retime', 'max_speed', 'finished', 'follow', 'audio', 'shows', 'before', 'steps', //
    'shoot_order',
  });
  final follow = s.optString('follow');
  return SceneSegment(
    id: s.string('scene'),
    beat: beat,
    duration: s.number('duration'),
    retime: s.boolean('retime', fallback: follow == null),
    maxSpeed: s.optNumber('max_speed', defaultMaxSpeed),
    finished: s.boolean('finished', fallback: false),
    follow: follow,
    audio: s.has('audio') ? MediaRef.read(s.map('audio')) : null,
    before: s.steps('before'),
    steps: s.steps('steps'),
    shootOrder: s.optInteger('shoot_order', index),
    shows: [for (final m in s.maps('shows')) MediaRef.read(m)],
  );
}

/// A capture script: scenes only, filmed in the storefront's take with the
/// previews, shown only as creative assets' footage (template ADR-0012).
PreviewScript _loadCapture(Fields f, String path) {
  f.only({'id', 'kind', 'title', 'ends_on_system_ui', 'requires', 'setup', 'segments'});
  final id = f.string('id');
  if (id != p.basenameWithoutExtension(path)) throw ConfigError('${f.where} › id: must equal the file name');
  final segments = <Segment>[];
  final ids = <String>{};
  for (final (i, s) in f.maps('segments', required: true).indexed) {
    if (!s.has('scene')) throw ConfigError('${s.where}: a capture script holds scenes only');
    final scene = _readScene(s, i, beat: s.optString('beat') ?? 'capture');
    if (!ids.add(scene.id)) throw ConfigError('${s.where}: duplicate segment id "${scene.id}"');
    segments.add(scene);
  }
  return PreviewScript(
    id: id,
    kind: 'capture',
    title: f.string('title'),
    template: '',
    rhythm: 0,
    posterAt: 0,
    endsOnSystemUi: f.boolean('ends_on_system_ui', fallback: false),
    soundtrack: 'none',
    requires: [for (final r in f.maps('requires')) Requirement.read(r)],
    setup: f.steps('setup'),
    segments: segments,
    captions: const [],
  );
}

/// The scripts in [dir], by id; [only] picks some (in that order).
Map<String, PreviewScript> loadScripts(String dir, {List<String>? only}) {
  final directory = Directory(dir);
  if (!directory.existsSync()) throw ConfigError('$dir: no scripts directory');
  final files = directory.listSync().whereType<File>().where((f) => f.path.endsWith('.yaml')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final all = {for (final f in files) p.basenameWithoutExtension(f.path): loadScript(f.path)};
  if (only == null) return all;
  return {for (final id in only) id: all[id] ?? (throw ConfigError('no script $id in $dir (${all.keys.join(', ')})'))};
}

/// Structural rules every script obeys (the narrative template's rules are
/// checked in narrative/).
Problems checkScriptStructure(PreviewScript s, {required String captionPrefix}) {
  final problems = Problems();
  final id = s.id;
  if (s.isCapture) {
    problems.check(s.scenes.isNotEmpty, '$id: a capture script films at least one scene');
    for (final sc in s.scenes) {
      problems.check(sc.duration > 0, '$id/${sc.id}: duration must be positive');
      problems.check(sc.audio == null, '$id/${sc.id}: a capture script plays no audio (it is never a preview)');
      problems.check(sc.maxSpeed >= 1 && sc.maxSpeed <= maxSpeedLimit, '$id/${sc.id}: max_speed ${sc.maxSpeed} outside 1–$maxSpeedLimit');
    }
    return problems;
  }
  problems.check(
    s.duration >= minPreviewSeconds - 1e-6 && s.duration <= maxPreviewSeconds + 1e-6,
    '$id: duration ${s.duration}s is outside $minPreviewSeconds–$maxPreviewSeconds s',
  );
  problems.check(s.scenes.isNotEmpty, '$id: no scene — a preview is app footage first');
  for (final seg in s.segments) {
    problems.check(seg.duration > 0, '$id/${seg.id}: duration must be positive');
  }
  for (final sc in s.scenes) {
    problems.check(sc.follow == null || !sc.retime, '$id/${sc.id}: a scene that follows playback runs in real time (retime: false)');
    problems.check(sc.follow == null || sc.audio != null || s.soundtrack == 'none', '$id/${sc.id}: follows ${sc.follow} but names no audio');
    problems.check(sc.audio == null || sc.follow != null, '$id/${sc.id}: audio without follow (its position would be unknown)');
    problems.check(sc.maxSpeed >= 1 && sc.maxSpeed <= maxSpeedLimit, '$id/${sc.id}: max_speed ${sc.maxSpeed} outside 1–$maxSpeedLimit');
  }
  if (s.soundtrack == 'follow') {
    problems.check(s.scenes.any((sc) => sc.audio != null), '$id: no scene follows playback with audio (or set soundtrack: none)');
  }
  final intro = s.cards.where((c) => c.kind == 'intro');
  final outro = s.cards.where((c) => c.kind == 'outro');
  problems.check(intro.length == 1 && s.segments.first == intro.first, '$id: the timeline opens with one intro card');
  problems.check(outro.length == 1 && s.segments.last == outro.first, '$id: the timeline closes with one outro card');
  for (final c in intro) {
    problems.check(c.textKey != null, '$id: the intro card states the claim (text: <key>) — not only the brand');
  }
  for (final c in outro) {
    problems.check(c.textKey == null, '$id: the outro card\'s lines come from app.yaml (brand, cta_key, disclosure_key), not text:');
  }
  for (final b in s.bridges) {
    final i = s.segments.indexOf(b);
    problems.check(
      i > 0 && i < s.segments.length - 1 && s.segments[i - 1] is SceneSegment && s.segments[i + 1] is SceneSegment,
      '$id/${b.id}: a bridge sits between two scenes',
    );
  }
  for (final c in s.captions) {
    problems.check(c.key.startsWith(captionPrefix), '$id: caption key ${c.key} lacks the $captionPrefix prefix');
    problems.check(c.from >= 0 && c.to <= s.duration + 1e-6 && c.to > c.from, '$id: caption ${c.key} ${c.from}–${c.to}s is outside the preview');
    for (final card in s.cards) {
      problems.check(c.to <= card.start + 1e-6 || c.from >= card.end - 1e-6, '$id: caption ${c.key} overlaps the ${card.kind} card (cards carry their own text)');
    }
  }
  final sorted = [...s.captions]..sort((a, b) => a.from.compareTo(b.from));
  for (var i = 1; i < sorted.length; i++) {
    problems.check(sorted[i].from >= sorted[i - 1].to - 1e-6, '$id: captions ${sorted[i - 1].key} and ${sorted[i].key} overlap');
  }
  return problems;
}
