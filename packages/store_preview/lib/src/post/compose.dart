import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/app.dart';
import '../config/captions.dart';
import '../config/defaults.dart';
import '../config/manifest.dart';
import '../config/script.dart';
import '../core/errors.dart';
import '../core/probe.dart';
import '../core/process.dart';
import '../driver/take.dart';
import '../timeline/edl.dart';
import 'cuts.dart';
import 'graph.dart';
import 'layers.dart';
import 'scrim.dart';
import 'soundtrack.dart';
import 'tools.dart';

/// The files one preview leaves in `dist/<app>/<storefront>/`.
class PreviewFiles {
  PreviewFiles(this.dir, this.script, this.slot);

  final String dir;
  final String script;
  final DeviceSlot slot;

  String get video => p.join(dir, '$script${slot.fileSuffix}.mp4');
  String get poster => p.join(dir, '$script${slot.fileSuffix}.poster.png');
  String get captions => p.join(dir, '$script${slot.fileSuffix}.captions.srt');
  String get edl => p.join(dir, '$script${slot.fileSuffix}.edl.json');
}

/// Composes one preview of [script] for [storefront] on [slot] from the
/// take in [take].
class Composer {
  Composer({
    required this.runner,
    required this.app,
    required this.manifest,
    required this.encoding,
    required this.tools,
    required this.root,
    this.prober = const FfprobeProber(),
  });

  final ProcessRunner runner;
  final PreviewApp app;
  final Manifest manifest;
  final Encoding encoding;
  final NativeTools tools;
  final String root;
  final Prober prober;

  Future<PreviewFiles> compose({
    required PreviewScript script,
    required Storefront storefront,
    required DeviceSlot slot,
    required TakeFiles take,
    required Map<String, String> texts,
    required String distDir,
  }) async {
    String text(String key) => texts[key] ?? (throw ConfigError('${storefront.id}: no text for $key (run `store-preview captions`)'));
    final out = PreviewFiles(p.join(distDir, storefront.id), script.id, slot);
    Directory(out.dir).createSync(recursive: true);
    final work = Directory(p.join(take.dir, 'render', script.id, slot.id))..createSync(recursive: true);
    final loaded = take.load();

    // 1. The timeline clip: scenes cut and retimed, held frames under cards
    //    and bridges.
    final cuts = timelineCuts(script, loaded, fps: encoding.fps);
    final clip = p.join(work.path, 'timeline.mov');
    final cutSpec = File(p.join(work.path, 'timeline.json'))
      ..writeAsStringSync(jsonEncode({
        'recording': p.absolute(take.recording),
        'out': clip,
        'fps': encoding.fps,
        'cuts': [for (final c in cuts.cuts) c.toJson()],
      }));
    await runner.run(tools.cutter, [cutSpec.path]);
    final source = prober.probe(clip)?.video ?? (throw ToolError('$clip has no video'));

    // 2. Media: card backdrops, bridges, soundtrack, voiceover.
    final media = <EdlMedia>[];
    void used(MediaEntry e, String use) =>
        media.add(EdlMedia(id: e.id, role: e.role, use: use, license: e.license.toJson()));
    MediaEntry resolve(MediaRef ref) => manifest.resolve(ref, script: script.id, storefront: storefront.id);

    // 3. Text layers: captions on plates measured against their footage,
    //    card foregrounds.
    final band = captionBand(sourceWidth: source.width, sourceHeight: source.height, slot: slot);
    final layers = <Map<String, Object?>>[];
    final captionLayers = <CaptionLayer>[];
    final edlTexts = <EdlText>[];
    for (final (i, c) in script.captions.indexed) {
      final luma = await meanLuma(runner, clip, from: c.from, to: c.to, band: band);
      final png = p.join(work.path, 'caption-$i.png');
      layers.add(captionLayer(
        text: text(c.key),
        out: png,
        slot: slot,
        brand: app.brand,
        opacity: plateOpacity(luma, app.captions),
        radius: app.captions.radius,
        root: root,
      ));
      captionLayers.add(CaptionLayer(png: png, from: c.from, to: c.to));
      edlTexts.add(EdlText(source: 'caption', key: c.key, text: text(c.key), from: c.from, to: c.to));
    }
    final icon = p.join(root, app.brand.icon);
    final cardLayers = <CardLayer>[];
    final cardDetail = <String, Map<String, Object?>>{};
    for (final c in script.cards) {
      final png = p.join(work.path, 'card-${c.kind}.png');
      final List<({String text, double size, String weight})> lines;
      String? footnote;
      if (c.kind == 'intro') {
        lines = [(text: text(c.textKey!), size: 60, weight: 'bold')];
        edlTexts.add(EdlText(source: 'claim', key: c.textKey!, text: text(c.textKey!), from: c.start, to: c.end));
      } else {
        lines = [(text: app.brand.name, size: 72, weight: 'bold'), (text: text(app.brand.ctaKey), size: 44, weight: 'semibold')];
        edlTexts
          ..add(EdlText(source: 'brand', key: 'brand.name', text: app.brand.name, from: c.start, to: c.end))
          ..add(EdlText(source: 'cta', key: app.brand.ctaKey, text: text(app.brand.ctaKey), from: c.start, to: c.end));
        if (app.requiresPurchase) {
          footnote = text(app.brand.disclosureKey!);
          edlTexts.add(EdlText(source: 'disclosure', key: app.brand.disclosureKey!, text: footnote, from: c.start, to: c.end));
        }
      }
      layers.add(cardLayer(out: png, slot: slot, brand: app.brand, icon: icon, lines: lines, footnote: footnote, root: root));
      final CardBackdrop backdrop;
      final Map<String, Object?> background;
      switch (c.background) {
        case ImageBackground(:final image):
          final e = resolve(image);
          used(e, 'card');
          backdrop = ImageBackdrop(e.file);
          background = {'background': 'image', 'media': e.id};
        case FootageBackground():
          backdrop = const FootageBackdrop();
          background = {'background': 'footage'};
        case ColorBackground(:final color):
          final hex = switch (color) {
            'primary' => app.brand.primary,
            'scrim' => app.brand.scrim,
            _ => color,
          };
          backdrop = ColorBackdrop(hex);
          background = {'background': 'color', 'color': hex};
      }
      cardLayers.add(CardLayer(kind: c.kind, start: c.start, end: c.end, foreground: png, backdrop: backdrop));
      cardDetail[c.kind] = background;
    }
    final spec = File(p.join(work.path, 'text.json'))..writeAsStringSync(jsonEncode({'items': layers}));
    await runner.run(tools.textRenderer, [spec.path]);

    final bridgeLayers = <BridgeLayer>[];
    final bridgeMedia = <String, String>{};
    for (final b in script.bridges) {
      final e = resolve(b.image);
      used(e, 'bridge');
      bridgeLayers.add(BridgeLayer(start: b.start, end: b.end, image: e.file));
      bridgeMedia[b.id] = e.id;
    }

    final follows = <({double start, String file, double offset})>[];
    if (script.soundtrack == 'follow') {
      for (final scene in script.scenes.where((s) => s.audio != null)) {
        final w = loaded.window(script.id, scene.id);
        final position = w.position ?? (throw ConfigError('${script.id}/${scene.id} follows playback but its mark has no position'));
        final e = resolve(scene.audio!);
        if (!media.any((m) => m.id == e.id)) used(e, 'soundtrack');
        follows.add((start: scene.start, file: e.file, offset: position - scene.start));
      }
    }
    final voiceovers = manifest.select(role: 'voiceover', script: script.id, locale: storefront.id);
    if (voiceovers.isNotEmpty) used(voiceovers.first, 'voiceover');

    // 4. Encode, poster, captions, EDL.
    final plan = RenderPlan(
      clip: clip,
      sourceWidth: source.width,
      sourceHeight: source.height,
      slot: slot,
      duration: script.duration,
      encoding: encoding,
      cards: cardLayers,
      bridges: bridgeLayers,
      captions: captionLayers,
      audio: audioCues(follows, script.duration),
      voiceover: voiceovers.isEmpty ? null : voiceovers.first.file,
      out: out.video,
    );
    await runner.run('ffmpeg', ffmpegArgs(plan));
    await runner.run('ffmpeg', ['-v', 'error', '-y', '-ss', script.posterAt.toStringAsFixed(3), '-i', out.video, '-frames:v', '1', out.poster]);
    File(out.captions).writeAsStringSync(srt([
      for (final t in edlTexts.where((t) => t.source != 'brand' && t.source != 'cta' && t.source != 'disclosure'))
        (from: t.from, to: t.to, text: t.text),
      for (final c in script.cards.where((c) => c.kind == 'outro'))
        (
          from: c.start,
          to: c.end,
          text: [app.brand.name, text(app.brand.ctaKey), if (app.requiresPurchase) text(app.brand.disclosureKey!)].join('\n'),
        ),
    ]));
    edlOf(
      script: script,
      storefront: storefront,
      slot: slot,
      scale: plan.scale,
      cuts: cuts,
      texts: edlTexts,
      media: media,
      cardDetail: cardDetail,
      bridgeMedia: bridgeMedia,
    ).write(out.edl);
    return out;
  }

  Edl edlOf({
    required PreviewScript script,
    required Storefront storefront,
    required DeviceSlot slot,
    required double scale,
    required TimelineCuts cuts,
    required List<EdlText> texts,
    required List<EdlMedia> media,
    required Map<String, Map<String, Object?>> cardDetail,
    required Map<String, String> bridgeMedia,
  }) {
    final segments = <EdlSegment>[];
    final transitions = <EdlTransition>[];
    for (final (i, s) in script.segments.indexed) {
      switch (s) {
        case SceneSegment():
          final src = cuts.sources[s.id]!;
          segments.add(EdlSegment(
            kind: 'footage',
            id: s.id,
            beat: s.beat,
            from: s.start,
            to: s.end,
            detail: {'source_from': src.from, 'source_to': src.to, 'speed': src.speed, 'finished': s.finished},
          ));
        case CardSegment():
          segments.add(EdlSegment(kind: 'card', id: s.id, beat: s.beat, from: s.start, to: s.end, detail: {'card': s.kind, ...?cardDetail[s.kind]}));
        case BridgeSegment():
          segments.add(EdlSegment(kind: 'bridge', id: s.id, beat: s.beat, from: s.start, to: s.end, detail: {'media': bridgeMedia[s.id]}));
      }
      if (i == 0) continue;
      final prev = script.segments[i - 1];
      final between = '${prev.id}→${s.id}';
      if (s is CardSegment || prev is CardSegment) {
        transitions.add(EdlTransition(at: s.start, type: 'dissolve', duration: encoding.cardTransition, between: between));
      } else if (s is BridgeSegment) {
        transitions.add(EdlTransition(at: s.start, type: 'dissolve', duration: encoding.bridgeIn, between: between));
      } else if (prev is BridgeSegment) {
        transitions.add(EdlTransition(at: s.start, type: 'dissolve', duration: encoding.bridgeOut, between: between));
      } else {
        transitions.add(EdlTransition(at: s.start, type: 'cut', duration: 0, between: between));
      }
    }
    return Edl(
      app: app.id,
      script: script.id,
      storefront: storefront.id,
      slot: slot.id,
      duration: script.duration,
      posterAt: script.posterAt,
      footageScale: scale,
      segments: segments,
      transitions: transitions,
      texts: texts,
      media: media,
    );
  }
}
