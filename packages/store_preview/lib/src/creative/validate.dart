import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/app.dart';
import '../config/captions.dart';
import '../core/errors.dart';
import '../core/probe.dart';
import '../core/process.dart';
import '../narrative/check.dart' show frameTolerance;
import '../narrative/template.dart';
import '../validate/compliance.dart' show allowedTransitions;
import '../validate/secrets.dart';
import 'composer.dart';
import 'edl.dart';
import 'measure.dart';
import 'specs.dart';

/// The real format behind a file extension.
bool formatMatches(String extension, MediaInfo info, {required bool video}) {
  final codec = info.video?.codec ?? '';
  return switch (extension) {
    '.png' => !video && codec == 'png',
    '.jpg' || '.jpeg' => !video && codec == 'mjpeg',
    '.mp4' || '.m4v' => video && info.container == 'mp4',
    '.mov' => video && info.container == 'quicktime',
    _ => false,
  };
}

/// The spec layer on one file, and what it measured.
class FileCheck {
  final Problems problems = Problems();
  MediaInfo? info;
  String resolution = '-';
  String duration = '-';
  String fps = '-';
  String size = '-';
}

/// The spec layer on [path] for [rule] of [spec]: the extension and the real
/// format, a complete decode, the size (exact pixels, or the range's exact
/// ratio), the byte size; an image without alpha; a video at exactly an
/// accepted frame rate, within the length window (and [duration], when
/// given), in an accepted codec, `yuv420p`, one video stream, no audio, no
/// rotation, its [poster] at its own size.
Future<FileCheck> checkCreativeFile(
  String path, {
  required CreativeSpec spec,
  required MediaRule rule,
  required bool video,
  required int maxBytes,
  required List<String> videoCodecs,
  required ProcessRunner runner,
  double? duration,
  String? poster,
  Prober prober = const FfprobeProber(),
}) async {
  final c = FileCheck();
  final problems = c.problems;
  if (!File(path).existsSync()) {
    problems.add('missing $path');
    return c;
  }
  final ext = p.extension(path).toLowerCase();
  final info = prober.probe(path);
  if (info == null || info.video == null) {
    problems.add('unreadable $path');
    return c;
  }
  c.info = info;
  final v = info.video!;
  final bytes = File(path).lengthSync();
  c
    ..resolution = '${v.width}×${v.height}'
    ..size = '${(bytes / 1048576).toStringAsFixed(1)}MB';
  problems
    ..check(rule.extensions.contains(ext), '$ext is not accepted (${rule.extensions.join(', ')})')
    ..check(formatMatches(ext, info, video: video), '$ext holds ${video ? info.container : v.codec}: extension and format disagree')
    ..check(rule.size.fits(v.width, v.height, spec.aspect), '${c.resolution} is not ${rule.size.describe(spec.aspect)}')
    ..check(bytes <= maxBytes, 'size ${c.size} is over ${maxBytes ~/ 1048576} MB');
  final decode = await runner.run('ffmpeg', ['-v', 'error', '-xerror', '-i', path, '-f', 'null', '-'], check: false);
  problems.check(decode.exitCode == 0 && decode.stderr.trim().isEmpty, 'does not decode cleanly: ${decode.stderr.trim().split('\n').last}');
  if (video) {
    c
      ..duration = '${info.duration.toStringAsFixed(2)}s'
      ..fps = v.frameRate.toStringAsFixed(2);
    final fpsOk = rule.fps.any((f) => (v.frameRate - f).abs() < 1e-3 && (v.realFrameRate - f).abs() < 1e-3);
    problems
      ..check(fpsOk, 'frame rate ${v.frameRate.toStringAsFixed(3)} (base ${v.realFrameRate.toStringAsFixed(3)}) is not exactly ${rule.fps.join(' or ')}')
      ..check(
        info.duration >= rule.minSeconds! - 1e-6 && info.duration <= rule.maxSeconds! + 1e-6,
        'duration ${c.duration} is outside ${rule.minSeconds}–${rule.maxSeconds} s',
      )
      ..check(duration == null || (info.duration - duration).abs() <= 1 / v.frameRate + 1e-6, 'duration ${c.duration} ≠ the loop\'s ${duration}s')
      ..check(videoCodecs.contains(v.codec), 'codec ${v.codec} (${videoCodecs.join(', ')})')
      ..check(v.pixFmt == 'yuv420p', 'pixel format ${v.pixFmt} is not yuv420p')
      ..check(info.audioStreams == 0, 'holds an audio stream: the placements play muted (search results cannot unmute)')
      ..check(info.videoStreams == 1, 'holds ${info.videoStreams} video streams')
      ..check(v.rotation == 0, 'carries ${v.rotation}° rotation metadata');
    if (poster != null) {
      final frame = File(poster).existsSync() ? prober.probe(poster)?.video : null;
      problems.check(frame != null && frame.width == v.width && frame.height == v.height, 'poster frame missing or not ${c.resolution}');
    }
  } else {
    problems
      ..check(!v.mayHaveAlpha, 'pixel format ${v.pixFmt} carries alpha (images may not)')
      ..check(info.videoStreams == 1, 'not a single image');
  }
  return c;
}

/// The three layers on one rendered creative asset.
class CreativeReport {
  CreativeReport(this.id);

  final String id;
  final Problems spec = Problems();
  final Problems compliance = Problems();
  final Problems narrative = Problems();
  String type = '-';
  String resolution = '-';
  String duration = '-';
  String fps = '-';
  String size = '-';
  String contrast = '-';
  String loop = '-';

  bool get ok => spec.isEmpty && compliance.isEmpty && narrative.isEmpty;

  List<String> get failures => [
    for (final f in spec.items) 'spec: $f',
    for (final f in compliance.items) 'compliance: $f',
    for (final f in narrative.items) 'narrative: $f',
  ];
}

/// Checks one rendered asset: the spec layer on the file (extension and real
/// format, a full decode, exact size or the range's exact ratio, alpha, frame
/// rate, length, codec, no audio, no rotation, size in bytes), compliance and
/// narrative on its EDL (safe area, never-enlarged footage, texts, licenses,
/// sources; the muted hook, the poster frame on finished footage, legibility
/// as measured, and the loop's seam measured again on the file).
Future<CreativeReport> checkCreative(
  CreativeJob job,
  CreativeFiles files, {
  required PreviewApp app,
  required CreativeDefaults defaults,
  required Map<String, NarrativeTemplate> templates,
  required ProcessRunner runner,
  required String workDir,
  Prober prober = const FfprobeProber(),
}) async {
  final r = CreativeReport(job.id);
  final spec = defaults.specs[job.slot.spec]!;
  final rule = spec.rule(job.asset.type)!;
  final video = job.asset.isVideo;
  r.type = creativeType(job.slot, job.asset, defaults);

  // Spec.
  final file = await checkCreativeFile(
    files.file,
    spec: spec,
    rule: rule,
    video: video,
    duration: video ? job.asset.duration : null,
    poster: video ? files.poster : null,
    maxBytes: defaults.maxBytes,
    videoCodecs: defaults.videoCodecs,
    runner: runner,
    prober: prober,
  );
  r.spec.addAll(file.problems);
  r
    ..resolution = file.resolution
    ..duration = file.duration
    ..fps = file.fps
    ..size = file.size;
  if (file.info == null) return r;
  final v = file.info!.video!;
  if (!File(files.edl).existsSync()) {
    r.compliance.add('no EDL — nothing to check');
    return r;
  }
  final edl = CreativeEdl.load(files.edl);
  r.spec.check(edl.width == v.width && edl.height == v.height, 'the EDL says ${edl.width}×${edl.height}');

  // Compliance.
  final c = r.compliance;
  for (final problem in edl.composition.problems()) {
    c.add(problem);
  }
  final storefront = app.storefronts.where((s) => s.id == edl.storefront).firstOrNull;
  c.check(edl.storefront == null || storefront != null, 'storefront ${edl.storefront} is not one of ${app.id}');
  c.check(
    edl.storefront == null || defaults.ascLocales.contains(edl.storefront),
    'locale ${edl.storefront} is not an App Store Connect locale (defaults/creative.yaml asc_locales)',
  );
  c.check(edl.placements.isNotEmpty && edl.targets.isNotEmpty, 'the EDL names no placement or target');
  for (final pl in edl.placements) {
    c.check(spec.placements.contains(pl), 'spec ${spec.id} does not serve $pl');
  }
  final banned = [...builtInBannedWords, ...app.captions.bannedWords];
  for (final t in edl.texts) {
    final problem = contentProblem(t.text, banned);
    c.check(problem == null, '${t.source} "${t.text}" $problem');
    if (t.source == 'creative') {
      c.check(storefront != null, 'a universal asset shows "${t.text}" (it shows in every language: no text)');
      if (storefront != null) {
        final limit = textLimit(TextUse.creative, storefront, app.captions);
        c.check(textLength(t.text) <= limit, '"${t.text}" is ${textLength(t.text)} characters (≤ $limit)');
      }
    }
  }
  c.check(edl.composition.lines <= defaults.layouts[spec.aspect]!.maxLines, 'the phrase sets in ${edl.composition.lines} lines');
  for (final m in edl.media) {
    c.check('${m.license['id'] ?? ''}'.trim().isNotEmpty, '${m.id} (${m.use}) is shown without a license id');
    c.check(app.creatives.authorization.containsKey(m.role), '${m.id} is ${m.role} media, which app.yaml creatives.authorization maps to no manifest field');
  }
  for (final id in edl.primaryMedia) {
    c.check(edl.media.any((m) => m.id == id), 'primary item $id is not among the shown media');
  }
  c.check(edl.media.any((m) => m.use == 'backdrop'), 'the backdrop is not a licensed manifest item');
  c.check(edl.sources.any((s) => s.kind == 'recording'), 'no recording behind the footage (real app use only)');
  for (final s in edl.sources) {
    c.check(RegExp(r'^[a-f0-9]{64}$').hasMatch(s.sha256), 'source ${s.file} has no SHA-256');
  }
  if (video) {
    for (final t in edl.transitions) {
      c.check(allowedTransitions.contains(t.type), 'transition ${t.between} is a ${t.type}');
    }
    final covered = edl.segments.fold<double>(0, (t, s) => t + s.length);
    c.check((covered - edl.duration).abs() < 1e-3, 'footage covers ${covered}s of ${edl.duration}s');
    c.check(edl.segments.every((s) => s.kind == 'footage'), 'a loop shows app footage only');
  }
  c.addAll(scanForSecrets([files.edl]));

  // Narrative.
  final n = r.narrative;
  final checks = defaults.checks;
  final mean = edl.measurements['contrast_mean'] ?? 0;
  final p90 = edl.measurements['contrast_p90'] ?? 0;
  r.contrast = '${mean.toStringAsFixed(1)}/${p90.toStringAsFixed(1)}';
  n
    ..check(mean >= checks.minContrastMean - 1e-9, 'the text block\'s backdrop gives a mean contrast of ${mean.toStringAsFixed(2)}:1 (≥ ${checks.minContrastMean}:1) — darken layouts.${spec.aspect}.backdrop or pick another backdrop')
    ..check(p90 >= checks.minContrastP90 - 1e-9, 'the text block\'s backdrop gives a 90th-percentile contrast of ${p90.toStringAsFixed(2)}:1 (≥ ${checks.minContrastP90}:1)');
  if (video) {
    final template = templates[edl.template];
    final hook = template?.hookSeconds ?? 2;
    final phrase = edl.texts.where((t) => t.source == 'creative');
    n.check(phrase.any((t) => t.from <= frameTolerance && t.to >= hook - frameTolerance), 'the phrase is not on screen from 0 to ${hook}s (muted autoplay)');
    final first = edl.segments.firstOrNull;
    n.check(first != null && first.from <= frameTolerance && first.to >= hook - frameTolerance, 'the opening cuts before ${hook}s (muted, one scene holds the first ${hook}s)');
    final poster = edl.posterAt ?? -1;
    n.check(
      edl.segments.any((s) => s.detail['finished'] == true && poster >= s.from && poster < s.to),
      'poster_at ${poster}s is not on footage of the finished product',
    );
    final psnr = await loopPsnr(runner, files.file, workDir);
    r.loop = psnr.isFinite ? '${psnr.toStringAsFixed(1)}dB' : 'inf';
    n.check(psnr >= checks.minLoopPsnr, 'the loop\'s seam: last→first frame PSNR ${r.loop} (≥ ${checks.minLoopPsnr} dB)');
  } else {
    n.check(edl.frame != null, 'no frame recorded in the EDL');
  }
  return r;
}

/// A plain-text table of [reports], then every failure.
String creativeTable(List<CreativeReport> reports) {
  String mark(bool ok) => ok ? 'pass' : 'FAIL';
  final rows = <List<String>>[
    ['asset', 'type', 'resolution', 'duration', 'fps', 'size', 'contrast', 'loop', 'spec', 'compliance', 'narrative', 'result'],
    for (final r in reports)
      [
        r.id, r.type, r.resolution, r.duration, r.fps, r.size, r.contrast, r.loop, //
        mark(r.spec.isEmpty), mark(r.compliance.isEmpty), mark(r.narrative.isEmpty), r.ok ? 'PASS' : 'FAIL',
      ],
  ];
  final widths = [for (var i = 0; i < rows.first.length; i++) rows.map((r) => r[i].runes.length).reduce((a, b) => a > b ? a : b)];
  final out = StringBuffer();
  for (final (n, r) in rows.indexed) {
    out.writeln([for (var i = 0; i < r.length; i++) r[i].padRight(widths[i] + r[i].length - r[i].runes.length)].join('  ').trimRight());
    if (n == 0) out.writeln([for (final w in widths) '─' * w].join('  '));
  }
  for (final r in reports.where((r) => !r.ok)) {
    for (final f in r.failures) {
      out.writeln('✗ ${r.id} $f');
    }
  }
  return out.toString();
}
