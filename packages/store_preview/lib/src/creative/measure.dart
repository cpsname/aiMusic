import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import '../core/process.dart';
import 'graph.dart';
import 'layout.dart';
import 'specs.dart';

/// Relative luminance of an 8-bit sRGB value (WCAG 2).
double luminance8(double v) {
  final c = v / 255;
  return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

/// Relative luminance of `#RRGGBB`.
double luminanceOfHex(String hex) {
  final v = int.parse(hex.substring(1, 7), radix: 16);
  return 0.2126 * luminance8(((v >> 16) & 0xFF).toDouble()) +
      0.7152 * luminance8(((v >> 8) & 0xFF).toDouble()) +
      0.0722 * luminance8((v & 0xFF).toDouble());
}

/// WCAG 2 contrast ratio of two luminances.
double contrastRatio(double a, double b) => (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);

/// The backdrop's luma where the text block sits: its mean and 90th
/// percentile (8-bit), the brightest over the frames sampled — the backdrop
/// alone, rendered through the same chain as the asset (the panel and text
/// never stand under the block).
Future<({double mean, double p90})> backdropLuma(
  ProcessRunner runner, {
  required String backdrop,
  required int width,
  required int height,
  required CreativeLayout layout,
  required int fps,
  required Box block,
  double? duration,
}) async {
  final frames = duration == null ? null : (duration * fps).round();
  final input = duration == null ? ['-i', backdrop] : ['-loop', '1', '-framerate', '$fps', '-t', duration.toStringAsFixed(4), '-i', backdrop];
  // The start and the push-in's widest point.
  final pick = frames == null ? '' : "select='eq(n\\,0)+eq(n\\,${frames ~/ 2})',";
  final crop = 'crop=${block.w.round()}:${block.h.round()}:${block.x.round()}:${block.y.round()}';
  final out = await runner.run('ffmpeg', [
    '-v', 'error', ...input, //
    '-vf', '${backdropChain(0, width: width, height: height, layout: layout, fps: fps, frames: frames).substring('[0:v]'.length)},'
        '$pick$crop,format=gray,signalstats,metadata=print:file=-',
    '-f', 'null', '-',
  ]);
  double worst(String key) {
    final values = [for (final m in RegExp('lavfi\\.signalstats\\.$key=([0-9.]+)').allMatches(out.stdout)) double.parse(m.group(1)!)];
    return values.isEmpty ? 255 : values.reduce(math.max);
  }

  return (mean: worst('YAVG'), p90: worst('YHIGH'));
}

/// PSNR (dB) between a video's last and first frame: how visible the loop's
/// seam is (infinite = identical).
Future<double> loopPsnr(ProcessRunner runner, String video, String workDir) async {
  Directory(workDir).createSync(recursive: true);
  final first = p.join(workDir, 'loop-first.png');
  final last = p.join(workDir, 'loop-last.png');
  await runner.run('ffmpeg', ['-v', 'error', '-y', '-i', video, '-frames:v', '1', first]);
  await runner.run('ffmpeg', ['-v', 'error', '-y', '-sseof', '-0.5', '-i', video, '-update', '1', last]);
  final out = await runner.run('ffmpeg', ['-hide_banner', '-i', first, '-i', last, '-lavfi', 'psnr', '-f', 'null', '-']);
  final m = RegExp(r'average:(inf|[0-9.]+)').firstMatch('${out.stderr}${out.stdout}');
  if (m == null) return 0;
  return m.group(1) == 'inf' ? double.infinity : double.parse(m.group(1)!);
}
