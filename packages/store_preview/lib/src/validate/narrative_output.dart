import '../config/app.dart';
import '../config/captions.dart';
import '../core/errors.dart';
import '../narrative/check.dart';
import '../timeline/edl.dart';

/// The narrative layer on one rendered preview, from its EDL: text from 0
/// through the hook, captions long enough and slow enough to read, the
/// poster frame on finished footage, an image transition where required.
Problems checkNarrativeOutput(Edl edl, PreviewApp app, {double hookSeconds = 3}) {
  final problems = Problems();
  final id = '${edl.storefront}/${edl.script}';
  final intervals = [for (final t in edl.texts) (from: t.from, to: t.to)]..sort((a, b) => a.from.compareTo(b.from));
  var covered = 0.0;
  for (final i in intervals) {
    if (i.from > covered + frameTolerance) break;
    if (i.to > covered) covered = i.to;
  }
  problems.check(covered >= hookSeconds - frameTolerance, '$id: on-screen text covers 0–${covered.toStringAsFixed(2)}s; the muted hook needs 0–${hookSeconds}s');

  final storefront = app.storefronts.where((s) => s.id == edl.storefront).firstOrNull;
  for (final t in edl.texts.where((t) => t.source == 'caption')) {
    final length = t.to - t.from;
    problems.check(length >= app.captions.minSeconds - 1e-6, '$id: caption ${t.key} is on screen ${length.toStringAsFixed(2)}s (≥ ${app.captions.minSeconds}s)');
    if (storefront != null) {
      final cps = textLength(t.text) / length;
      final max = storefront.isCjk ? app.captions.maxCpsCjk : app.captions.maxCps;
      problems.check(cps <= max + 1e-6, '$id: caption ${t.key} reads at ${cps.toStringAsFixed(1)} characters/s (≤ $max)');
    }
  }

  bool finishedAt(double t) => edl.segments.any((s) => s.kind == 'footage' && s.detail['finished'] == true && t >= s.from && t < s.to);
  problems.check(finishedAt(edl.posterAt), '$id: poster_at ${edl.posterAt}s is not on footage of the finished product');
  final shared = app.publish.sharedPosterAt;
  if (shared != null) problems.check(finishedAt(shared), '$id: the shared poster frame ${shared}s is not on footage of the finished product');
  if (app.rules.requireImageTransition) {
    problems.check(
      edl.segments.any((s) => s.kind == 'bridge') || edl.segments.any((s) => s.kind == 'card' && s.detail['background'] == 'image'),
      '$id: no image transition (a bridge or an image-backed card)',
    );
  }
  return problems;
}
