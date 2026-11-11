import '../config/defaults.dart';
import 'soundtrack.dart';

/// What sits behind a card's text.
sealed class CardBackdrop {
  const CardBackdrop();
}

/// A licensed image, cover-scaled, slowly pushed in, blurred, darkened.
class ImageBackdrop extends CardBackdrop {
  const ImageBackdrop(this.path);
  final String path;
}

/// The footage frame under the card, blurred and darkened.
class FootageBackdrop extends CardBackdrop {
  const FootageBackdrop();
}

/// A flat colour (`#RRGGBB`).
class ColorBackdrop extends CardBackdrop {
  const ColorBackdrop(this.hex);
  final String hex;
}

class CardLayer {
  const CardLayer({required this.kind, required this.start, required this.end, required this.foreground, required this.backdrop});

  /// `intro` dissolves out into the footage, `outro` dissolves in from it.
  final String kind;
  final double start;
  final double end;
  final String foreground;
  final CardBackdrop backdrop;
}

class BridgeLayer {
  const BridgeLayer({required this.start, required this.end, required this.image});

  final double start;
  final double end;
  final String image;
}

class CaptionLayer {
  const CaptionLayer({required this.png, required this.from, required this.to});

  final String png;
  final double from;
  final double to;
}

/// Everything one preview's ffmpeg run needs, resolved to files.
class RenderPlan {
  const RenderPlan({
    required this.clip,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.slot,
    required this.duration,
    required this.encoding,
    required this.cards,
    required this.bridges,
    required this.captions,
    required this.audio,
    required this.voiceover,
    required this.out,
  });

  /// The timeline clip (cut_scenes): native resolution, `duration`, CFR.
  final String clip;
  final int sourceWidth;
  final int sourceHeight;
  final DeviceSlot slot;
  final double duration;
  final Encoding encoding;
  final List<CardLayer> cards;
  final List<BridgeLayer> bridges;
  final List<CaptionLayer> captions;

  /// Music cues; empty = a silent track.
  final List<AudioCue> audio;
  final String? voiceover;
  final String out;

  /// The footage's scale to the slot: cover, never above 1 for a native
  /// recording of the slot's device.
  double get scale {
    final sw = slot.width / sourceWidth;
    final sh = slot.height / sourceHeight;
    return sw > sh ? sw : sh;
  }
}

/// ffmpeg inputs, numbered in the order they are added.
class _Inputs {
  final List<String> args = [];
  int _next = 0;

  int file(String path) {
    args.addAll(['-i', path]);
    return _next++;
  }

  int still(String path, double duration, int fps) {
    args.addAll(['-loop', '1', '-framerate', '$fps', '-t', n4(duration), '-i', path]);
    return _next++;
  }

  int lavfi(String source, double duration) {
    args.addAll(['-f', 'lavfi', '-t', n4(duration), '-i', source]);
    return _next++;
  }
}

int _even(double v) => (v / 2).round() * 2;

/// The full ffmpeg command line for [plan].
///
/// Video: the clip scaled (cover, lanczos) and cropped to the slot; each
/// card composited over it (backdrop + foreground, dissolving into / out of
/// the frame held under it); each bridge (a blurred image pushed in,
/// dissolving in and out); each caption (fading and rising in, fading out).
/// Audio: [soundtrackGraph]. Encoded to the targets of [Encoding].
List<String> ffmpegArgs(RenderPlan plan) {
  final e = plan.encoding;
  final w = plan.slot.width;
  final h = plan.slot.height;
  final fps = e.fps;
  final inputs = _Inputs();
  final graph = <String>[];
  final clip = inputs.file(plan.clip);

  final scaledW = _even(plan.sourceWidth * plan.scale);
  final scaledH = _even(plan.sourceHeight * plan.scale);
  final footageCards = plan.cards.where((c) => c.backdrop is FootageBackdrop).toList();
  graph.add('[$clip:v]fps=$fps,scale=$scaledW:$scaledH:flags=lanczos,crop=$w:$h,setsar=1,format=yuv420p'
      '${footageCards.isEmpty ? '[base]' : ',split=${footageCards.length + 1}[base]${[for (var i = 0; i < footageCards.length; i++) '[fb$i]'].join()}'}');
  var label = 'base';

  String pushIn(int input, double duration, {required double zoom, required double sigma, required double brightness}) {
    final frames = (duration * fps).round();
    final bw = _even(w * 1.12);
    final bh = _even(h * 1.12);
    return '[$input:v]scale=$bw:$bh:force_original_aspect_ratio=increase,crop=$bw:$bh,'
        "zoompan=z='1+${zoom.toStringAsFixed(3)}*on/$frames':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=${w}x$h:fps=$fps,"
        'gblur=sigma=$sigma,eq=brightness=$brightness:saturation=0.85,format=rgba';
  }

  var footage = 0;
  for (final (i, c) in plan.cards.indexed) {
    final d = c.end - c.start;
    final String backdrop;
    switch (c.backdrop) {
      case ImageBackdrop(:final path):
        backdrop = '${pushIn(inputs.still(path, d, fps), d, zoom: 0.06, sigma: 26, brightness: -0.22)}[cb$i]';
      case FootageBackdrop():
        backdrop = '[fb${footage++}]trim=start=${n4(c.start)}:end=${n4(c.end)},setpts=PTS-STARTPTS,'
            'gblur=sigma=30,eq=brightness=-0.18:saturation=0.8,format=rgba[cb$i]';
      case ColorBackdrop(:final hex):
        backdrop = '[${inputs.lavfi('color=c=0x${hex.substring(1, 7)}:s=${w}x$h:r=$fps', d)}:v]format=rgba[cb$i]';
    }
    graph.add(backdrop);
    final fg = inputs.still(c.foreground, d, fps);
    final fade = c.kind == 'intro'
        ? 'fade=t=out:st=${n4(d - e.cardTransition)}:d=${e.cardTransition}:alpha=1'
        : 'fade=t=in:st=0:d=${e.cardTransition}:alpha=1';
    graph
      ..add('[$fg:v]format=rgba[cf$i]')
      ..add('[cb$i][cf$i]overlay=0:0:format=auto,format=rgba,$fade,setpts=PTS-STARTPTS+${n4(c.start)}/TB[card$i]')
      ..add("[$label][card$i]overlay=0:0:eof_action=pass:enable='between(t,${n4(c.start)},${n4(c.end)})'[vc$i]");
    label = 'vc$i';
  }

  for (final (i, b) in plan.bridges.indexed) {
    final d = b.end - b.start;
    final image = inputs.still(b.image, d, fps);
    graph
      ..add('${pushIn(image, d, zoom: 0.04, sigma: 30, brightness: -0.1)},'
          'fade=t=in:st=0:d=${e.bridgeIn}:alpha=1,fade=t=out:st=${n4(d - e.bridgeOut)}:d=${e.bridgeOut}:alpha=1,'
          'setpts=PTS-STARTPTS+${n4(b.start)}/TB[br$i]')
      ..add("[$label][br$i]overlay=0:0:eof_action=pass:enable='between(t,${n4(b.start)},${n4(b.end)})'[vb$i]");
    label = 'vb$i';
  }

  final bottom = plan.slot.captionBottom;
  for (final (i, c) in plan.captions.indexed) {
    final d = c.to - c.from;
    final png = inputs.still(c.png, d, fps);
    graph
      ..add('[$png:v]format=rgba,fade=t=in:st=0:d=${e.captionIn}:alpha=1,'
          'fade=t=out:st=${n4(d - e.captionOut)}:d=${e.captionOut}:alpha=1,setpts=PTS-STARTPTS+${n4(c.from)}/TB[cap$i]')
      ..add("[$label][cap$i]overlay=x=(W-w)/2:y='H-h-$bottom+${e.captionRise}*pow(max(0,1-(t-${n4(c.from)})/${e.captionIn}),2)'"
          ":eval=frame:eof_action=pass:enable='between(t,${n4(c.from)},${n4(c.to)})'[vt$i]");
    label = 'vt$i';
  }
  graph.add('[$label]trim=duration=${n4(plan.duration)},format=yuv420p[vout]');

  final audioInputs = <String, int>{};
  for (final cue in plan.audio) {
    audioInputs.putIfAbsent(cue.file, () => inputs.file(cue.file));
  }
  final voiceover = plan.voiceover == null ? null : inputs.file(plan.voiceover!);
  final silent = plan.audio.isEmpty ? inputs.lavfi('anullsrc=r=${e.sampleRate}:cl=stereo', plan.duration) : null;
  graph.addAll(soundtrackGraph(
    cues: plan.audio,
    inputOf: (f) => audioInputs[f]!,
    encoding: e,
    duration: plan.duration,
    voiceover: voiceover,
    silent: silent,
  ));

  return [
    '-v', 'error', '-y', ...inputs.args, //
    '-filter_complex', graph.join(';'),
    '-map', '[vout]', '-map', '[aout]',
    '-c:v', 'libx264', '-profile:v', e.profile, '-level:v', e.level, '-pix_fmt', 'yuv420p',
    '-r', '$fps', '-g', '${fps * e.gopSeconds}',
    '-b:v', '${e.videoBitrate}', '-minrate', '${e.videoBitrate}', '-maxrate', '${e.videoBitrate}', '-bufsize', '${e.videoBitrate}',
    '-x264-params', 'nal-hrd=cbr:force-cfr=1',
    '-c:a', 'aac_at', '-aac_at_mode', 'cbr', '-b:a', '${e.audioBitrate}', '-ar', '${e.sampleRate}', '-ac', '${e.channels}',
    '-t', n4(plan.duration),
    '-movflags', '+faststart',
    plan.out,
  ];
}
