/// User-lyrics rules (PRD F03 / §11.3): a 1,200-character cap (600 for CJK,
/// whose token cost is 3–4× Latin) and automatic `[Verse]` / `[Chorus]` section
/// tags when the user wrote none.
abstract final class LyricsFormatter {
  static const int latinLimit = 1200;
  static const int cjkLimit = 600;

  static final RegExp _tagLine = RegExp(r'^\s*\[[^\]\n]{1,40}\]\s*$', multiLine: true);
  static final RegExp _cjk = RegExp(
    r'[぀-ヿ㐀-䶿一-鿿가-힯豈-﫿]',
  );

  /// True when more than 30 % of the non-space characters are CJK.
  static bool isMostlyCjk(String text) {
    final visible = text.replaceAll(RegExp(r'\s'), '');
    if (visible.isEmpty) return false;
    return _cjk.allMatches(visible).length / visible.length > 0.3;
  }

  /// The character cap for [text] (PRD §11.3).
  static int limitFor(String text) => isMostlyCjk(text) ? cjkLimit : latinLimit;

  /// Adds section tags when [raw] has none: stanzas (blank-line separated)
  /// alternate `[Verse]` / `[Chorus]`; a single stanza is split in half. Lyrics
  /// that already carry tags are only trimmed.
  static String withSectionTags(String raw) {
    final text = raw.replaceAll('\r\n', '\n').trim();
    if (text.isEmpty || _tagLine.hasMatch(text)) return text;

    var stanzas = text
        .split(RegExp(r'\n\s*\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (stanzas.length == 1) {
      final lines = stanzas.single.split('\n');
      if (lines.length >= 2) {
        final half = (lines.length / 2).ceil();
        stanzas = [
          lines.sublist(0, half).join('\n'),
          lines.sublist(half).join('\n'),
        ];
      }
    }
    final buffer = StringBuffer();
    for (var i = 0; i < stanzas.length; i++) {
      if (i > 0) buffer.write('\n\n');
      buffer
        ..write(i.isEven ? '[Verse]' : '[Chorus]')
        ..write('\n')
        ..write(stanzas[i]);
    }
    return buffer.toString();
  }
}
