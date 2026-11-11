import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../config/app.dart';
import '../config/manifest.dart';
import '../config/script.dart';
import '../core/errors.dart';
import '../core/probe.dart';
import '../core/process.dart';
import '../driver/take_registry.dart';
import '../narrative/template.dart';
import '../post/cuts.dart';
import '../post/tools.dart';
import '../timeline/edl.dart';
import 'definition.dart';
import 'edl.dart';
import 'graph.dart';
import 'layout.dart';
import 'measure.dart';
import 'specs.dart';

/// Where one creative asset's files go:
/// `dist/<app>/creative/<storefront | universal>/<id>.png|.mp4`, with the
/// video's `<id>.poster.png` and the `<id>.edl.json`.
class CreativeFiles {
  CreativeFiles({required this.distDir, required this.id, required this.storefront, required this.video});

  /// `dist/<app>` (the assets manifest's directory).
  final String distDir;
  final String id;
  final String? storefront;
  final bool video;

  String get dir => p.join(distDir, 'creative', storefront ?? 'universal');
  String get file => p.join(dir, '$id.${video ? 'mp4' : 'png'}');
  String get poster => p.join(dir, '$id.poster.png');
  String get edl => p.join(dir, '$id.edl.json');
}

/// One asset of one definition for one storefront (null = universal).
class CreativeJob {
  const CreativeJob({required this.definition, required this.slot, required this.asset, required this.storefront});

  final CreativeDefinition definition;
  final CreativeSlot slot;
  final CreativeAsset asset;
  final String? storefront;

  String get id => asset.idFor(storefront);
}

/// Every job of [definitions] for [storefronts]: per-storefront assets for
/// each of them, universal ones once when their source storefront is among
/// them.
List<CreativeJob> creativeJobs(Map<String, CreativeDefinition> definitions, PreviewApp app, {required List<Storefront> storefronts}) {
  final ids = storefronts.map((s) => s.id).toSet();
  return [
    for (final d in definitions.values)
      for (final slot in d.slots)
        for (final a in slot.assets)
          if (a.perStorefront)
            for (final s in storefronts) CreativeJob(definition: d, slot: slot, asset: a, storefront: s.id)
          else if (ids.contains(universalSource(d, app)))
            CreativeJob(definition: d, slot: slot, asset: a, storefront: null),
  ];
}

/// A per-storefront asset under a localization its storefront serves
/// ([Storefront.serves], template ADR-0017): `header.en-GB` naming
/// `header.en-US`'s files. Nothing is rendered for it; the assets manifest
/// lists it as its own entry (its locale, its id) derived from [job].
class CreativeAlias {
  const CreativeAlias({required this.job, required this.locale});

  /// The rendered asset it names.
  final CreativeJob job;

  /// The App Store Connect localization it serves.
  final String locale;

  String get id => job.asset.idFor(locale);
}

/// The aliases of [jobs]: each per-storefront job under every localization
/// its storefront serves.
List<CreativeAlias> creativeAliases(List<CreativeJob> jobs, PreviewApp app) => [
  for (final j in jobs)
    if (j.storefront != null)
      for (final l in app.storefront(j.storefront!).serves) CreativeAlias(job: j, locale: l),
];

/// The storefront whose take and media a universal asset of [d] shows.
String universalSource(CreativeDefinition d, PreviewApp app) => d.universalFrom ?? app.storefronts.first.id;

/// The manifest type of an asset in [slot]: by its first placement.
String creativeType(CreativeSlot slot, CreativeAsset asset, CreativeDefaults defaults) => defaults.placements[slot.placements.first]!.typeFor(asset.type);

/// Renders creative assets from the storefronts' takes.
class CreativeComposer {
  CreativeComposer({
    required this.runner,
    required this.app,
    required this.scripts,
    required this.manifest,
    required this.defaults,
    required this.templates,
    required this.tools,
    required this.root,
    required this.buildDir,
    this.prober = const FfprobeProber(),
  });

  final ProcessRunner runner;
  final PreviewApp app;

  /// Every script of the app (a scene's `finished` and its media).
  final Map<String, PreviewScript> scripts;
  final Manifest manifest;
  final CreativeDefaults defaults;
  final Map<String, NarrativeTemplate> templates;
  final NativeTools tools;
  final String root;

  /// `build/store_preview/<app>` (takes and the work directories).
  final String buildDir;
  final Prober prober;

  final Map<String, String> _hashes = {};

  /// SHA-256 of a file, once per run.
  String hashOf(String path) => _hashes.putIfAbsent(p.absolute(path), () => sha256.convert(File(path).readAsBytesSync()).toString());

  String _rel(String path) => p.relative(p.absolute(path), from: root);

  /// Renders [job] into [distDir]; [texts] are the job's storefront's.
  Future<CreativeFiles> render(CreativeJob job, {required Map<String, String> texts, required String distDir, required String slotId}) async {
    final asset = job.asset;
    final slot = job.slot;
    final source = app.storefront(job.storefront ?? universalSource(job.definition, app));
    final spec = defaults.specs[slot.spec] ?? (throw ConfigError('${job.definition.id}: no spec ${slot.spec}'));
    final rule = spec.rule(asset.type) ?? (throw ConfigError('${job.definition.id}: spec ${spec.id} has no ${asset.type}'));
    final layout = defaults.layouts[spec.aspect]!;
    final encoding = defaults.encoding;
    final fps = encoding.fps;
    final width = rule.size.renderWidth;
    final height = rule.size.renderHeight;
    final out = CreativeFiles(distDir: distDir, id: job.id, storefront: job.storefront, video: asset.isVideo);
    Directory(out.dir).createSync(recursive: true);
    final work = Directory(p.join(buildDir, 'creative', job.storefront ?? 'universal', job.id))..createSync(recursive: true);
    final recordingSlot = slot.device ?? slotId;
    final registry = TakeRegistry(p.join(buildDir, 'raw', source.id, recordingSlot))..migrateLegacy();
    final media = <EdlMedia>[];
    final primaryMedia = <String>[];
    final sources = <CreativeSource>[];
    void used(MediaEntry e, String use, {bool primary = false}) {
      if (primary && !primaryMedia.contains(e.id)) primaryMedia.add(e.id);
      // One entry per item and use: a photo on screen may also be the
      // backdrop, and the EDL says both.
      if (media.any((m) => m.id == e.id && m.use == use)) return;
      media.add(EdlMedia(id: e.id, role: e.role, use: use, license: e.license.toJson()));
    }

    // 1. Footage: each scene (or the frame) cut from its take in real time.
    final scenes = <PanelScene>[];
    final segments = <EdlSegment>[];
    Map<String, Object?>? frame;
    ({int width, int height})? recordingSize;
    final spans = <({String run, String recording, double from, double to})>[];
    final pieces = asset.isVideo
        ? [for (final s in asset.scenes) (ref: s.footage, duration: s.duration, beat: s.beat)]
        : [(ref: asset.frame!, duration: 1 / fps, beat: 'frame')];
    var at = 0.0;
    for (final (i, piece) in pieces.indexed) {
      final ref = piece.ref;
      final script = scripts[ref.script] ?? (throw ConfigError('${job.definition.id}: no script ${ref.script}'));
      final scene =
          script.scenes.where((s) => s.id == ref.scene).firstOrNull ??
          (throw ConfigError('${job.definition.id}: script ${ref.script} has no scene ${ref.scene}'));
      final take = registry.takeFor(ref.script, what: '${source.id}/$recordingSlot');
      final loaded = take.load();
      final window = loaded.window(ref.script, ref.scene);
      final start = loaded.at(window.startMs);
      final end = loaded.at(window.endMs);
      final filmed = end - start;
      final offset = ref.from >= 0 ? ref.from : filmed + ref.from;
      final from = start + offset;
      final to = from + piece.duration;
      if (offset < 0 || to > end + 1e-6) {
        throw ConfigError(
          '${job.id}: $ref was filmed for ${filmed.toStringAsFixed(2)} s in ${take.dir}; '
          '${asset.isVideo ? '${piece.duration} s from ${ref.from}' : 'the frame at ${ref.from}'} does not fit — adjust the creative',
        );
      }
      final clip = p.join(work.path, 'footage-$i.mov');
      final cut = Cut(from: from, to: to, frames: (piece.duration * fps).round(), fps: fps);
      final cutSpec = File(p.join(work.path, 'footage-$i.json'))
        ..writeAsStringSync(
          jsonEncode({
            'recording': p.absolute(take.recording),
            'out': clip,
            'fps': fps,
            'cuts': [cut.toJson()],
          }),
        );
      await runner.run(tools.cutter, [cutSpec.path]);
      final probe = prober.probe(clip)?.video ?? (throw ToolError('$clip has no video'));
      recordingSize ??= (width: probe.width, height: probe.height);
      final run = p.basename(take.dir);
      spans.add((run: run, recording: take.recording, from: from, to: to));
      if (!sources.any((s) => s.file == _rel(take.recording))) {
        sources.add(
          CreativeSource(
            kind: 'recording',
            file: _rel(take.recording),
            sha256: hashOf(take.recording),
            detail: {'storefront': source.id, 'run': run, 'script': ref.script},
          ),
        );
      }
      // What the scene shows: its playback and the licensed items on screen.
      // The primary scene: the poster frame's (a video), the frame (an image).
      final primary = !asset.isVideo || (asset.posterAt! >= at - 1e-9 && asset.posterAt! < at + piece.duration - 1e-9);
      for (final shown in [?scene.audio, ...scene.shows]) {
        used(
          manifest.resolve(shown, script: script.id, storefront: source.id),
          'footage',
          primary: primary,
        );
      }
      if (asset.isVideo) {
        scenes.add(PanelScene(clip: clip, duration: piece.duration, dissolveAfter: false));
        segments.add(
          EdlSegment(
            kind: 'footage',
            id: ref.scene,
            beat: piece.beat,
            from: at,
            to: at + piece.duration,
            detail: {
              'script': ref.script,
              'scene': ref.scene,
              'run': run,
              'source_from': from,
              'source_to': to, //
              'speed': 1.0, 'finished': scene.finished,
            },
          ),
        );
        at += piece.duration;
      } else {
        scenes.add(PanelScene(clip: clip, duration: 0, dissolveAfter: false));
        frame = {'script': ref.script, 'scene': ref.scene, 'at': ref.from, 'source_at': from, 'run': run, 'finished': scene.finished};
      }
    }
    // A cut where the next scene's footage runs on in the same recording.
    for (var i = 0; i + 1 < scenes.length; i++) {
      final continuous = spans[i].recording == spans[i + 1].recording && (spans[i + 1].from - spans[i].to).abs() <= 1.5 / fps;
      scenes[i] = PanelScene(clip: scenes[i].clip, duration: scenes[i].duration, dissolveAfter: !continuous);
    }

    // 2. Layers: the text block beside the panel, the panel's mask and shadow.
    final plan = CompositionPlan(width: width, height: height, layout: layout, sourceWidth: recordingSize!.width, sourceHeight: recordingSize.height);
    final phrase = asset.perStorefront && slot.text != null
        ? (texts[slot.text!] ?? (throw ConfigError('${source.id}: no text for ${slot.text} (run `store-preview captions`)')))
        : null;
    final direction = job.storefront == null ? 'ltr' : directionOf(source);
    final icon = p.join(root, app.brand.icon);
    final layers = (
      text: p.join(work.path, 'text.png'),
      mask: p.join(work.path, 'mask.png'),
      shadow: p.join(work.path, 'shadow.png'),
      layout: p.join(work.path, 'layout.json'),
    );
    final item = plan.textItem(
      brand: app.brand,
      icon: icon,
      root: root,
      phrase: phrase,
      direction: direction,
      out: layers.text,
      maskOut: layers.mask,
      shadowOut: layers.shadow,
      layoutOut: layers.layout,
    );
    final spec0 = File(p.join(work.path, 'layers.json'))
      ..writeAsStringSync(
        jsonEncode({
          'items': [item],
        }),
      );
    try {
      await runner.run(tools.textRenderer, [spec0.path]);
    } on ToolError catch (e) {
      throw ConfigError('${job.id}: ${e.message.replaceFirst(RegExp(r'^.*render_text: '), '')}');
    }
    final composition = Composition.read(layers.layout, safe: plan.safe, scale: plan.scale, direction: direction);

    // 3. The backdrop, then the encode.
    final backdrop = manifest.resolve(slot.backdrop, script: slot.backdrop.script!, storefront: source.id);
    used(backdrop, 'backdrop');
    sources
      ..add(CreativeSource(kind: 'backdrop', file: _rel(backdrop.file), sha256: hashOf(backdrop.file), detail: {'media': backdrop.id}))
      ..add(CreativeSource(kind: 'icon', file: _rel(icon), sha256: hashOf(icon)));
    final renderPlan = CreativeRenderPlan(
      width: width,
      height: height,
      backdrop: backdrop.file,
      layout: layout,
      panel: composition.panel,
      scenes: scenes,
      mask: layers.mask,
      shadow: layers.shadow,
      text: layers.text,
      encoding: encoding,
      out: out.file,
    );
    await runner.run('ffmpeg', creativeArgs(renderPlan));

    // 4. Poster frame, measurements, EDL.
    final duration = asset.isVideo ? asset.duration : 0.0;
    final luma = await backdropLuma(
      runner,
      backdrop: backdrop.file,
      width: width,
      height: height,
      layout: layout,
      fps: fps,
      block: composition.block,
      duration: asset.isVideo ? duration : null,
    );
    final ink = luminanceOfHex(app.brand.onPrimary);
    final measurements = <String, double>{
      'backdrop_luma_mean': luma.mean,
      'backdrop_luma_p90': luma.p90,
      'contrast_mean': contrastRatio(ink, luminance8(luma.mean)),
      'contrast_p90': contrastRatio(ink, luminance8(luma.p90)),
    };
    final transitions = <EdlTransition>[];
    if (asset.isVideo) {
      await runner.run('ffmpeg', ['-v', 'error', '-y', '-ss', asset.posterAt!.toStringAsFixed(3), '-i', out.file, '-frames:v', '1', out.poster]);
      final psnr = await loopPsnr(runner, out.file, work.path);
      measurements['loop_psnr'] = psnr.isFinite ? psnr : 999;
      for (var i = 0; i + 1 < scenes.length; i++) {
        final s = segments[i + 1];
        transitions.add(
          EdlTransition(
            at: s.from,
            type: scenes[i].dissolveAfter ? 'dissolve' : 'cut',
            duration: scenes[i].dissolveAfter ? encoding.sceneDissolve : 0,
            between: '${segments[i].id}→${s.id}',
          ),
        );
      }
      transitions.add(
        EdlTransition(
          at: duration - encoding.loopDissolve - 1 / fps,
          type: 'dissolve',
          duration: encoding.loopDissolve,
          between: '${segments.last.id}→${segments.first.id} (loop)',
        ),
      );
    } else if (File(out.poster).existsSync()) {
      File(out.poster).deleteSync();
    }
    final texts0 = <EdlText>[
      EdlText(source: 'brand', key: 'brand.name', text: app.brand.name, from: 0, to: duration),
      if (phrase != null) EdlText(source: 'creative', key: slot.text!, text: phrase, from: 0, to: duration),
    ];
    CreativeEdl(
      app: app.id,
      asset: job.id,
      definition: job.definition.id,
      type: creativeType(slot, asset, defaults),
      storefront: job.storefront,
      placements: slot.placements,
      targets: job.definition.targets,
      spec: spec.id,
      aspect: spec.aspect,
      width: width,
      height: height,
      duration: duration,
      posterAt: asset.posterAt,
      template: asset.template,
      rhythm: asset.rhythm,
      composition: composition,
      frame: frame,
      segments: segments,
      transitions: transitions,
      texts: texts0,
      media: media,
      primaryMedia: primaryMedia,
      sources: sources,
      parameters: {
        'backdrop': {
          'zoom': asset.isVideo ? layout.zoom : 0,
          'blur_sigma': height * layout.blur,
          'brightness': layout.brightness, //
          'saturation': layout.saturation,
        },
        'panel': {'scale': composition.scale, 'corner': layout.panelCorner},
        if (asset.isVideo)
          'encode': {
            'codec': 'h264',
            'profile': encoding.profile,
            'level': encoding.level,
            'crf': encoding.crf, //
            'max_bitrate': encoding.maxBitrate,
            'fps': fps,
            'gop': fps * encoding.gopSeconds,
            'audio': 'none',
          }
        else
          'encode': {'codec': 'png', 'pix_fmt': 'rgb24'},
      },
      measurements: measurements,
      tags: slot.tags,
    ).write(out.edl);
    return out;
  }
}
