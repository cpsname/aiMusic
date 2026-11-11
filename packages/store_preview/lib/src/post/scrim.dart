import '../config/app.dart';
import '../config/defaults.dart';
import '../core/process.dart';

/// The caption band in the clip's (source) pixels: where a caption of the
/// slot will sit, mapped back through the cover scale and crop.
({int x, int y, int w, int h}) captionBand({required int sourceWidth, required int sourceHeight, required DeviceSlot slot}) {
  final scale = (slot.width / sourceWidth) > (slot.height / sourceHeight) ? slot.width / sourceWidth : slot.height / sourceHeight;
  final cropX = (sourceWidth * scale - slot.width) / 2;
  final cropY = (sourceHeight * scale - slot.height) / 2;
  final bandH = slot.captionSize * 2.6;
  final top = slot.height - slot.captionBottom - bandH;
  final left = slot.width * 0.07;
  int s(double v) => (v / scale).round();
  return (x: s(left + cropX), y: s(top + cropY), w: s(slot.width * 0.86), h: s(bandH));
}

/// The plate opacity that keeps a caption legible over its footage: the
/// mean luma of the band under it during [from]–[to], mapped from video
/// range (16–235) onto the app's opacity range — brighter footage, darker
/// plate.
double plateOpacity(double meanLuma, CaptionRules rules) {
  final t = ((meanLuma - 16) / (235 - 16)).clamp(0.0, 1.0);
  return rules.plateOpacityMin + (rules.plateOpacityMax - rules.plateOpacityMin) * t;
}

/// Mean luma of a region of [clip] between [from] and [to].
Future<double> meanLuma(ProcessRunner runner, String clip, {required double from, required double to, required ({int x, int y, int w, int h}) band}) async {
  final out = await runner.run('ffmpeg', [
    '-v', 'error', '-ss', from.toStringAsFixed(3), '-t', (to - from).toStringAsFixed(3), '-i', clip, //
    '-vf', 'fps=6,crop=${band.w}:${band.h}:${band.x}:${band.y},signalstats,metadata=print:key=lavfi.signalstats.YAVG:file=-',
    '-f', 'null', '-',
  ]);
  final values = [
    for (final m in RegExp(r'lavfi\.signalstats\.YAVG=([0-9.]+)').allMatches(out.stdout)) double.parse(m.group(1)!),
  ];
  if (values.isEmpty) return 128;
  return values.reduce((a, b) => a + b) / values.length;
}
