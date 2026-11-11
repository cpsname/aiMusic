import 'music_creation_draft.dart';

/// Builds the user-side `prompt` block of `/v1/generate` (contract 02 v2.1
/// §2.2): line-oriented `key: value` facts the server drops into its own
/// prompt with the occasion's flavour, the inspiration's recipe and the region
/// preset. The client never writes the Lyria prompt itself (PRD §7); the block
/// carries only what the user gave.
abstract final class MusicPromptBlock {
  /// The block's longest note (code points).
  static const int maxNote = 600;

  /// The block for [draft], keys in the contract's order, each at most once.
  /// `description` is the user's own text only — never a card's style or hint.
  static String build(MusicCreationDraft draft, {String note = ''}) {
    final genre = draft.genre;
    final inspiration = inspirationOf(draft);
    final recipient = _clean(draft.recipient);
    final keywords = [for (final k in draft.keywords) if (_clean(k).isNotEmpty) _clean(k)];
    final cleanNote = _clean(note);
    final lines = <String>[
      if (inspiration != null) 'inspiration: $inspiration',
      if (recipient.isNotEmpty) 'recipient: $recipient',
      if (keywords.isNotEmpty) 'keywords: ${keywords.join(' | ')}',
      if (_clean(draft.prompt).isNotEmpty) 'description: ${_clean(draft.prompt)}',
      // Absent genre = "Custom — based on your prompt" (docs/ui P02c).
      if (genre != null && genre.trim().isNotEmpty) 'genre: ${genre.trim()}',
      'vocals: ${draft.vocals.wire}',
      'lyric_language: ${draft.lyricLanguage.code}',
      if (draft.festival != null) 'festival: ${draft.festival!.wire}',
      if (draft.usesPhotos) 'photos: ${draft.imageBids.length}',
      if (cleanNote.isNotEmpty) 'note: ${String.fromCharCodes(cleanNote.runes.take(maxNote))}',
    ];
    return lines.join('\n');
  }

  /// Whether the request for [draft] carries something to write a song from
  /// besides a name — keywords, a description, own lyrics or photos — as the
  /// server checks it on a request without a scene (`HasBrief`, contract 02
  /// v2.1 §2.3). Counts the values [build] writes (cleaned), not the raw
  /// fields. The polisher's `note` also counts there but is never relied on.
  static bool hasBrief(MusicCreationDraft draft) =>
      draft.keywords.any((k) => _clean(k).isNotEmpty) ||
      _clean(draft.prompt).isNotEmpty ||
      draft.hasUserLyrics ||
      draft.usesPhotos;

  /// The scene's slug sent as `inspiration` (top level and first line, the
  /// same value): the picked server entry, or a built-in template picked on
  /// the offline grid (the server lists the 16 templates under their ids).
  /// Null = free input.
  static String? inspirationOf(MusicCreationDraft draft) => draft.inspirationSlug ?? draft.template?.id;

  /// The raw brief handed to the on-device polisher (SystemLanguageModel):
  /// "birthday wish song for Alex: coffee, hiking, Sunday". Its answer is the
  /// block's `note`.
  static String brief(MusicCreationDraft draft) {
    final kind = inspirationOf(draft)?.replaceAll('_', ' ') ?? draft.occasion.wire;
    final subject = draft.recipient.isEmpty ? kind : '$kind song for ${draft.recipient}';
    final withKeywords = draft.keywords.isEmpty ? subject : '$subject: ${draft.keywords.join(', ')}';
    return draft.hasPrompt ? '$withKeywords. ${draft.prompt.trim()}' : withKeywords;
  }

  /// One line: no `key:` injection through user text, no control characters.
  static String _clean(String value) =>
      value.replaceAll(RegExp(r'[\r\n|]+'), ' ').replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), '').trim();
}
