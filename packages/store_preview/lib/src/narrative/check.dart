import '../config/app.dart';
import '../config/captions.dart';
import '../config/script.dart';
import '../core/errors.dart';
import 'template.dart';

/// A frame at 30 fps: the tolerance for "covered" and "touching".
const double frameTolerance = 1 / 30;

/// The narrative layer: the script plays its template's beats in its
/// rhythm, the first seconds explain themselves muted, captions can be read,
/// the poster frame shows the finished product.
///
/// [texts]: storefront → key → text, for the reading-speed rule (skipped for
/// a storefront without texts).
Problems checkNarrative(
  PreviewScript script,
  PreviewApp app,
  Map<String, NarrativeTemplate> templates, {
  Map<String, Map<String, String>> texts = const {},
}) {
  final problems = Problems();
  final id = script.id;
  final template = templates[script.template];
  if (template == null) {
    problems.add('$id: template "${script.template}" is not in the library (${templates.keys.join(', ')})');
    return problems;
  }
  if (template.format != 'preview') {
    problems.add('$id: ${template.id} is a ${template.format} template; a preview follows a preview template');
    return problems;
  }
  final rhythm = template.rhythms[script.rhythm];
  if (rhythm == null) {
    problems.add('$id: ${template.id} has no ${script.rhythm} s rhythm (${template.rhythms.keys.join(' / ')})');
    return problems;
  }
  problems.check(
    (script.duration - script.rhythm).abs() < 1e-6,
    '$id: the segments last ${script.duration}s, the ${script.rhythm} s rhythm needs ${script.rhythm}s',
  );

  // Beats: known, in order, of the right kind, within the rhythm.
  var last = -1;
  final perBeat = <String, double>{};
  for (final s in script.segments) {
    final beat = template.beat(s.beat);
    if (beat == null) {
      problems.add('$id/${s.id}: beat "${s.beat}" is not in ${template.id} (${template.beats.map((b) => b.id).join(', ')})');
      continue;
    }
    final kind = switch (s) {
      CardSegment() => 'card',
      SceneSegment() => 'scene',
      BridgeSegment() => 'bridge',
    };
    problems.check(beat.kind == kind, '$id/${s.id}: beat ${beat.id} is played by a ${beat.kind}, not a $kind');
    final index = template.beats.indexOf(beat);
    problems.check(index >= last, '$id/${s.id}: beat ${beat.id} comes after ${template.beats[last < 0 ? 0 : last].id} in ${template.id}');
    last = index > last ? index : last;
    perBeat[beat.id] = (perBeat[beat.id] ?? 0) + s.duration;
    if (beat.finished && s is SceneSegment) {
      problems.check(s.finished, '$id/${s.id}: beat ${beat.id} shows the finished product (finished: true)');
    }
  }
  for (final b in template.beats.where((b) => !b.optional)) {
    problems.check(perBeat.containsKey(b.id), '$id: the required beat ${b.id} of ${template.id} is missing');
  }
  for (final MapEntry(key: beat, value: seconds) in perBeat.entries) {
    final nominal = rhythm[beat];
    if (nominal == null) {
      problems.add('$id: beat $beat is not played in the ${script.rhythm} s rhythm of ${template.id}');
      continue;
    }
    problems.check(
      (seconds - nominal).abs() <= template.flex + 1e-6,
      '$id: beat $beat lasts ${seconds}s, the ${script.rhythm} s rhythm allows $nominal ± ${template.flex}s',
    );
  }

  // The hook: on-screen text from 0 through hookSeconds without a gap.
  final intervals = <({double from, double to})>[
    for (final c in script.cards)
      if (c.kind == 'intro' && c.textKey != null) (from: c.start, to: c.end) else if (c.kind == 'outro') (from: c.start, to: c.end),
    for (final c in script.captions) (from: c.from, to: c.to),
  ]..sort((a, b) => a.from.compareTo(b.from));
  var covered = 0.0;
  for (final i in intervals) {
    if (i.from > covered + frameTolerance) break;
    if (i.to > covered) covered = i.to;
  }
  problems.check(
    covered >= template.hookSeconds - frameTolerance,
    '$id: on-screen text covers only 0–${covered.toStringAsFixed(2)}s; the muted hook needs 0–${template.hookSeconds}s',
  );

  // Captions are read: long enough on screen, not too fast.
  for (final c in script.captions) {
    final length = c.to - c.from;
    problems.check(
      length >= app.captions.minSeconds - 1e-6,
      '$id: caption ${c.key} is on screen ${length.toStringAsFixed(2)}s (≥ ${app.captions.minSeconds}s)',
    );
    for (final s in app.storefronts) {
      final text = texts[s.id]?[c.key];
      if (text == null) continue;
      final cps = textLength(text) / length;
      final max = s.isCjk ? app.captions.maxCpsCjk : app.captions.maxCps;
      problems.check(cps <= max + 1e-6, '$id: ${s.id} ${c.key} "$text" reads at ${cps.toStringAsFixed(1)} characters/s (≤ $max)');
    }
  }

  // The finished product: on screen, and the poster frame shows it.
  problems.check(script.scenes.any((s) => s.finished), '$id: no scene shows the finished product (finished: true)');
  bool finishedAt(double t) {
    final s = script.segmentAt(t);
    return s is SceneSegment && s.finished && s.contains(t);
  }

  problems.check(finishedAt(script.posterAt), '$id: poster_at ${script.posterAt}s is not inside a finished scene');
  final shared = app.publish.sharedPosterAt;
  if (shared != null) {
    problems.check(finishedAt(shared), '$id: the shared poster frame ${shared}s (publish.shared_poster_at) is not inside a finished scene');
  }

  // Imagery between the footage: a bridge, or a card on a licensed image.
  if (app.rules.requireImageTransition) {
    problems.check(
      script.bridges.isNotEmpty || script.cards.any((c) => c.background is ImageBackground),
      '$id: no image transition — add a bridge or an image-backed card (rules.require_image_transition)',
    );
  }
  return problems;
}
