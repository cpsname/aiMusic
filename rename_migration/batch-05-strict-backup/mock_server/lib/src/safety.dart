/// Server-side safety pre-check (PRD §5.1 / §7.4 / §12.3): artist imitation
/// phrasings and a small artist blocklist → SAFETY_BLOCKED before charging.
library;

const List<String> _imitationPhrases = [
  'in the style of',
  'sound like',
  'sounds like',
  'voice of',
];

const List<String> _artistBlocklist = [
  'taylor swift',
  'drake',
  'beyonce',
  'beyoncé',
  'bts',
  'adele',
  'ed sheeran',
  'billie eilish',
  'the weeknd',
  'ariana grande',
  'bad bunny',
  'blackpink',
];

final List<RegExp> _artistPatterns = [
  for (final name in _artistBlocklist)
    RegExp(
      '(^|[^\\p{L}\\p{N}])${RegExp.escape(name)}(\$|[^\\p{L}\\p{N}])',
      unicode: true,
    ),
];

/// Returns the matched rule when [texts] must be blocked, else null.
String? safetyViolation(Iterable<String?> texts) {
  for (final raw in texts) {
    if (raw == null || raw.isEmpty) continue;
    final text = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    for (final phrase in _imitationPhrases) {
      if (text.contains(phrase)) return 'phrase:$phrase';
    }
    for (var i = 0; i < _artistPatterns.length; i++) {
      if (_artistPatterns[i].hasMatch(text)) {
        return 'artist:${_artistBlocklist[i]}';
      }
    }
  }
  return null;
}
