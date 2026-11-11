import '../config/app.dart';
import '../config/captions.dart';
import '../config/script.dart';
import '../core/errors.dart';
import '../timeline/edl.dart';

/// Transitions Apple's guidance allows ("straightforward transitions, like
/// dissolves and fades"); a cut is the plainest of all.
const Set<String> allowedTransitions = {'cut', 'dissolve', 'fade'};

/// The compliance thresholds against a script's timeline — checked before
/// anything is recorded, so a script that cannot pass never films.
Problems checkScriptCompliance(PreviewScript script, PreviewApp app) {
  final problems = Problems();
  final rules = app.rules;
  final cards = script.cards.fold<double>(0, (t, c) => t + c.duration);
  final nonFootage = cards + script.bridges.fold<double>(0, (t, b) => t + b.duration);
  final ratio = (script.duration - nonFootage) / script.duration;
  problems.check(
    ratio >= rules.minFootageRatio - 1e-9,
    '${script.id}: app footage is ${(ratio * 100).toStringAsFixed(1)} % of the timeline (≥ ${(rules.minFootageRatio * 100).toStringAsFixed(0)} %)',
  );
  for (final c in script.cards) {
    problems.check(c.duration <= rules.maxCardSeconds + 1e-9, '${script.id}: the ${c.kind} card lasts ${c.duration}s (≤ ${rules.maxCardSeconds}s)');
  }
  problems.check(cards <= rules.maxCardsTotal + 1e-9, '${script.id}: cards last ${cards}s together (≤ ${rules.maxCardsTotal}s)');
  return problems;
}

/// The compliance layer for one rendered preview, from its EDL: footage
/// share, card lengths, transitions, scale, the texts shown (prices, "free",
/// dates, other apps), the purchase disclosure, licensed media.
Problems checkCompliance(Edl edl, PreviewApp app) {
  final problems = Problems();
  final rules = app.rules;
  final id = '${edl.storefront}/${edl.script}';
  final covered = edl.segments.fold<double>(0, (t, s) => t + s.length);
  problems.check((covered - edl.duration).abs() < 1e-3, '$id: the EDL covers ${covered}s of ${edl.duration}s');
  problems.check(
    edl.footageRatio >= rules.minFootageRatio - 1e-9,
    '$id: app footage is ${(edl.footageRatio * 100).toStringAsFixed(1)} % (≥ ${(rules.minFootageRatio * 100).toStringAsFixed(0)} %)',
  );
  for (final s in edl.segments.where((s) => s.kind == 'card')) {
    problems.check(s.length <= rules.maxCardSeconds + 1e-9, '$id: card ${s.id} lasts ${s.length}s (≤ ${rules.maxCardSeconds}s)');
  }
  problems.check(edl.secondsOf('card') <= rules.maxCardsTotal + 1e-9, '$id: cards last ${edl.secondsOf('card')}s (≤ ${rules.maxCardsTotal}s)');
  for (final t in edl.transitions) {
    problems.check(allowedTransitions.contains(t.type), '$id: transition ${t.between} is a ${t.type} (cut, dissolve or fade)');
  }
  problems.check(edl.footageScale <= 1 + 1e-9, '$id: the footage is enlarged ×${edl.footageScale.toStringAsFixed(3)} (record on the slot\'s device)');

  final storefront = app.storefronts.where((s) => s.id == edl.storefront).firstOrNull;
  final banned = [...builtInBannedWords, ...app.captions.bannedWords];
  for (final t in edl.texts) {
    final content = contentProblem(t.text, banned);
    problems.check(content == null, '$id: ${t.source} "${t.text}" $content');
    if (storefront != null && t.source != 'brand') {
      final limit = t.source == 'disclosure'
          ? (storefront.isCjk ? app.captions.maxDisclosureCharsCjk : app.captions.maxDisclosureChars)
          : (storefront.isCjk ? app.captions.maxCharsCjk : app.captions.maxChars);
      problems.check(textLength(t.text) <= limit, '$id: ${t.source} "${t.text}" is ${textLength(t.text)} characters (≤ $limit)');
    }
  }
  if (app.requiresPurchase) {
    final outro = edl.segments.where((s) => s.kind == 'card' && s.detail['card'] == 'outro').firstOrNull;
    final disclosed = outro != null &&
        edl.texts.any((t) => t.source == 'disclosure' && t.text.trim().isNotEmpty && t.from <= outro.from + 1e-6 && t.to >= outro.to - 1e-6);
    problems.check(disclosed, '$id: the end card does not disclose the purchase (Apple: "you must disclose this … in the end frame")');
  }
  for (final m in edl.media) {
    problems.check('${m.license['id'] ?? ''}'.trim().isNotEmpty, '$id: ${m.id} (${m.use}) is shown without a license id');
  }
  return problems;
}
