import '../post/soundtrack.dart' show n4;
import 'layout.dart';
import 'specs.dart';

/// One scene of a creative video: its footage clip (cut from a take, exactly
/// [duration] long at the encode's frame rate) and how it hands over to the
/// next scene.
class PanelScene {
  const PanelScene({required this.clip, required this.duration, required this.dissolveAfter});

  final String clip;
  final double duration;

  /// A dissolve into the next scene (else a cut: the footage runs on in the
  /// same recording).
  final bool dissolveAfter;
}

/// Everything one creative asset's ffmpeg run needs, resolved to files.
class CreativeRenderPlan {
  const CreativeRenderPlan({
    required this.width,
    required this.height,
    required this.backdrop,
    required this.layout,
    required this.panel,
    required this.scenes,
    required this.mask,
    required this.shadow,
    required this.text,
    required this.encoding,
    required this.out,
  });

  final int width;
  final int height;

  /// The licensed backdrop image.
  final String backdrop;
  final CreativeLayout layout;

  /// Where the panel goes (from the renderer's layout).
  final Box panel;

  /// video: the scenes in order; image: one scene of one frame.
  final List<PanelScene> scenes;
  final String mask;
  final String shadow;
  final String text;
  final CreativeEncoding encoding;
  final String out;

  bool get isVideo => out.endsWith('.mp4');
  double get duration => scenes.fold(0, (t, s) => t + s.duration);
  int get panelWidth => panel.w.round();
  int get panelHeight => panel.h.round();
}

/// The backdrop chain: the image cover-scaled, blurred, darkened; in a video
/// pushed in and back out once over [frames] (zoom 1 → 1 + zoom → 1), so the
/// last frame meets the first.
String backdropChain(int input, {required int width, required int height, required CreativeLayout layout, required int fps, int? frames}) {
  final sigma = (height * layout.blur).toStringAsFixed(1);
  final motion = frames == null
      ? ''
      : "zoompan=z='1+${layout.zoom}*(1-cos(2*PI*on/$frames))/2':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=${width}x$height:fps=$fps,";
  return '[$input:v]scale=$width:$height:force_original_aspect_ratio=increase,crop=$width:$height,setsar=1,$motion'
      'gblur=sigma=$sigma,eq=brightness=${layout.brightness}:saturation=${layout.saturation}';
}

/// The full ffmpeg command line for [plan].
///
/// The backdrop (moving in a video), the panel's shadow, the footage —
/// scaled into the panel with lanczos, its corners rounded by the mask;
/// scene to scene a dissolve (the outgoing scene's last frame and the
/// incoming one's first held for half the dissolve each, so no scene needs
/// footage beyond its window) or a cut; at the end a dissolve into the very
/// first frame, which the last frame then equals — then the text block.
/// Composited in RGB; a video is encoded to H.264 (BT.709, no audio), an
/// image to 8-bit RGB PNG (no alpha).
List<String> creativeArgs(CreativeRenderPlan plan) {
  final e = plan.encoding;
  final fps = e.fps;
  final w = plan.width;
  final h = plan.height;
  final args = <String>['-v', 'error', '-y'];
  final graph = <String>[];
  final d = plan.duration;
  final frames = (d * fps).round();
  final px = plan.panelWidth;
  final ph = plan.panelHeight;

  if (plan.isVideo) {
    args.addAll(['-loop', '1', '-framerate', '$fps', '-t', n4(d), '-i', plan.backdrop]);
  } else {
    args.addAll(['-i', plan.backdrop]);
  }
  final sceneInputs = <int>[];
  for (final s in plan.scenes) {
    args.addAll(['-i', s.clip]);
    sceneInputs.add(sceneInputs.length + 1);
  }
  final next = sceneInputs.length + 1;
  final (mask, shadow, text) = (next, next + 1, next + 2);
  for (final layer in [plan.mask, plan.shadow, plan.text]) {
    if (plan.isVideo) {
      args.addAll(['-loop', '1', '-framerate', '$fps', '-t', n4(d), '-i', layer]);
    } else {
      args.addAll(['-i', layer]);
    }
  }

  graph.add('${backdropChain(0, width: w, height: h, layout: plan.layout, fps: fps, frames: plan.isVideo ? frames : null)},format=rgba[bg]');
  final prepare = 'fps=$fps,scale=$px:$ph:flags=lanczos,setsar=1,format=rgba,settb=AVTB';
  if (!plan.isVideo) {
    graph.add('[${sceneInputs.single}:v]scale=$px:$ph:flags=lanczos,setsar=1,format=rgba[panel]');
  } else {
    final x = e.sceneDissolve;
    final clips = <String>[];
    for (final (i, s) in plan.scenes.indexed) {
      final before = i > 0 && plan.scenes[i - 1].dissolveAfter;
      final after = i < plan.scenes.length - 1 && s.dissolveAfter;
      final pads = [
        if (before) 'tpad=start_mode=clone:start_duration=${n4(x / 2)}',
        if (after) 'tpad=stop_mode=clone:stop_duration=${n4(x / 2)}',
      ];
      final input = sceneInputs[i];
      if (i == 0) {
        graph.add('[$input:v]$prepare,trim=duration=${n4(s.duration)},setpts=PTS-STARTPTS,split[c0][first0]');
        if (pads.isNotEmpty) {
          graph.add('[c0]${pads.join(',')}[c0p]');
          clips.add('c0p');
        } else {
          clips.add('c0');
        }
      } else {
        graph.add('[$input:v]$prepare,trim=duration=${n4(s.duration)},setpts=PTS-STARTPTS${pads.isEmpty ? '' : ',${pads.join(',')}'}[c$i]');
        clips.add('c$i');
      }
    }
    var acc = clips.first;
    var at = plan.scenes.first.duration;
    for (var i = 1; i < clips.length; i++) {
      final out = 'j$i';
      if (plan.scenes[i - 1].dissolveAfter) {
        graph.add('[$acc][${clips[i]}]xfade=transition=fade:duration=${n4(x)}:offset=${n4(at - x / 2)}[$out]');
      } else {
        graph.add('[$acc][${clips[i]}]concat=n=2:v=1:a=0[$out]');
      }
      acc = out;
      at += plan.scenes[i].duration;
    }
    // The loop: the last frames dissolve into the first frame, held to the
    // end, so the last frame is the first.
    final l = e.loopDissolve;
    final frame = 1 / fps;
    graph
      ..add('[first0]trim=end_frame=1,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=${n4(l)}[firstframe]')
      ..add('[$acc][firstframe]xfade=transition=fade:duration=${n4(l)}:offset=${n4(d - l - frame)}[panel]');
  }
  graph
    ..add('[$mask:v]format=gray,scale=$px:$ph[mask]')
    ..add('[panel][mask]alphamerge[rounded]')
    ..add('[bg][$shadow:v]overlay=0:0:format=rgb[shadowed]')
    ..add('[shadowed][rounded]overlay=${plan.panel.x.round()}:${plan.panel.y.round()}:format=rgb[composed]');
  if (plan.isVideo) {
    graph.add('[composed][$text:v]overlay=0:0:format=rgb,trim=duration=${n4(d)},'
        'scale=out_color_matrix=bt709:out_range=tv,format=yuv420p[vout]');
    return [
      ...args,
      '-filter_complex', graph.join(';'),
      '-map', '[vout]', '-an',
      '-c:v', 'libx264', '-preset', e.preset, '-profile:v', e.profile, '-level:v', e.level, '-pix_fmt', 'yuv420p',
      '-crf', '${e.crf}', '-maxrate', '${e.maxBitrate}', '-bufsize', '${e.maxBitrate * 2}',
      '-r', '$fps', '-g', '${fps * e.gopSeconds}',
      '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709', '-color_range', 'tv',
      '-t', n4(d), '-movflags', '+faststart',
      plan.out,
    ];
  }
  graph.add('[composed][$text:v]overlay=0:0:format=rgb,format=rgb24[vout]');
  return [...args, '-filter_complex', graph.join(';'), '-map', '[vout]', '-frames:v', '1', '-c:v', 'png', '-pix_fmt', 'rgb24', plan.out];
}
