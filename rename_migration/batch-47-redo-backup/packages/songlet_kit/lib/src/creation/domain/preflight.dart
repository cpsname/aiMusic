import 'package:meta/meta.dart';

import 'creation_draft.dart';
import 'lyrics_fingerprint.dart';
import 'lyrics_formatter.dart';
import 'prompt_block.dart';

/// Why a draft cannot be submitted (PRD §7.4 / F03 / F04 / §9.1). Every check
/// runs locally, before any network call, so a doomed request is never billed.
enum PreflightIssue {
  promptTooLong,
  recipientMissing,
  recipientTooLong,

  /// The name field carries an artist reference ("Taylor Swift style"),
  /// docs/ui P18.
  recipientArtistName,
  /// No scene and nothing to write a song from: the request would carry no
  /// keywords, description, lyrics or photos (the server's rule, contract 02
  /// v2.1 §2.3 — it answers 40001 `details.prompt`).
  briefMissing,
  keywordTooLong,
  tooManyKeywords,
  artistName,
  styleImitation,
  lyricsTooLong,
  lyricsNotOriginal,
  lyricsOwnershipUnconfirmed,
  tooManyPhotos,
}

@immutable
class PreflightResult {
  const PreflightResult(this.issues, {this.draft});

  /// The draft to submit (trimmed, lyrics section-tagged) when [isOk].
  final CreationDraft? draft;
  final List<PreflightIssue> issues;

  bool get isOk => issues.isEmpty;
}

/// Client-side prompt preflight (PRD §7.4):
/// * free-text description ≤ 300 characters;
/// * name ≤ 24 characters, up to 3 keywords of ≤ 20 characters;
/// * artist-name blocklist and "sound like / in the style of / voice of" + name;
/// * own lyrics ≤ 1,200 characters (600 CJK), auto section tags, the
///   originality checkbox, and a public-lyrics fingerprint similarity > 0.8;
/// * at most 10 photos.
/// The model's safety filter stays the second line of defence (server).
class Preflight {
  Preflight({
    Set<String>? artistBlocklist,
    LyricsFingerprintIndex? fingerprints,
  })  : _artists = (artistBlocklist ?? defaultArtistBlocklist)
            .map((a) => a.toLowerCase())
            .toSet(),
        _fingerprints = fingerprints ?? LyricsFingerprintIndex.publicDomain();

  static const int maxPrompt = 300;
  static const int maxRecipient = 24;
  static const int maxKeyword = 20;
  static const int maxKeywords = 3;
  static const int maxPhotos = 10;
  static const double similarityThreshold = 0.8;

  /// Seed blocklist. Production refreshes it daily from the backend config
  /// (PRD §7.4); the bundled copy keeps the check working offline.
  static const Set<String> defaultArtistBlocklist = {
    'taylor swift', 'beyonce', 'beyoncé', 'drake', 'adele', 'ed sheeran',
    'bts', 'blackpink', 'billie eilish', 'the weeknd', 'ariana grande',
    'justin bieber', 'rihanna', 'bruno mars', 'eminem', 'kanye west',
    'lady gaga', 'coldplay', 'the beatles', 'beatles', 'michael jackson',
    'elvis presley', 'madonna', 'shakira', 'bad bunny', 'dua lipa',
    'harry styles', 'olivia rodrigo', 'sabrina carpenter', 'post malone',
    'kendrick lamar', 'travis scott', 'imagine dragons', 'maroon 5',
    'arijit singh', 'shreya ghoshal', 'anitta', 'kenshi yonezu', 'yoasobi',
    'newjeans', 'stray kids', 'rammstein', 'stromae', 'céline dion',
    'celine dion', 'karol g', 'peso pluma', 'tarkan',
  };

  /// "sound like / in the style of / voice of" **followed by a name** (PRD
  /// §7.4) — a capitalized word, or a blocklisted artist (checked separately).
  /// "your laugh sounds like summer" stays allowed.
  static final RegExp _imitation = RegExp(
    r'\b(?:[Ss]ounds?\s+like|[Ii]n\s+the\s+style\s+of|[Vv]oice\s+of|[Ss]tyle\s+of|[Ll]ike\s+the\s+voice\s+of)\s+(?:the\s+)?\p{Lu}',
    unicode: true,
  );

  final Set<String> _artists;
  final LyricsFingerprintIndex _fingerprints;

  PreflightResult check(CreationDraft draft) {
    final issues = <PreflightIssue>[];
    final recipient = draft.recipient.trim();
    final keywords = draft.keywords
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList(growable: false);

    final prompt = draft.prompt.trim();

    if (prompt.characters > maxPrompt) issues.add(PreflightIssue.promptTooLong);
    // A scene decides itself whether text is needed (`input_required`,
    // enforced by the composer's send button) and its name is optional
    // (contract 02 v2.1 §1.3), so nothing is missing for it — an offline
    // template is sent as its scene too.
    final fromInspiration = PromptBlock.inspirationOf(draft) != null;
    // A free-form prompt names whoever it is for; a template form asks.
    if (recipient.isEmpty &&
        !fromInspiration &&
        draft.requiresRecipient &&
        !draft.usesPhotos &&
        prompt.isEmpty) {
      issues.add(PreflightIssue.recipientMissing);
    }
    if (recipient.characters > maxRecipient) {
      issues.add(PreflightIssue.recipientTooLong);
    }
    if (_recipientImitates(recipient)) {
      issues.add(PreflightIssue.recipientArtistName);
    }
    // Checked on what the prompt block will actually carry (cleaned values),
    // so a draft that passes here is never refused by the server for it.
    if (!fromInspiration && !PromptBlock.hasBrief(draft)) {
      issues.add(PreflightIssue.briefMissing);
    }
    if (keywords.length > maxKeywords) issues.add(PreflightIssue.tooManyKeywords);
    if (keywords.any((k) => k.characters > maxKeyword)) {
      issues.add(PreflightIssue.keywordTooLong);
    }
    if (draft.photos.length > maxPhotos || draft.imageBids.length > maxPhotos) {
      issues.add(PreflightIssue.tooManyPhotos);
    }

    final lyrics = draft.hasUserLyrics
        ? LyricsFormatter.withSectionTags(draft.userLyrics!)
        : null;
    // The recipient is a person's name (a friend may well be called Adele),
    // so only the descriptive text is screened for artists / imitation.
    final freeText = [
      ...keywords,
      if (prompt.isNotEmpty) prompt,
      ?lyrics,
    ].join('\n');
    issues.addAll(screen(freeText));

    if (lyrics != null) {
      final body = _stripTags(lyrics);
      if (body.characters > LyricsFormatter.limitFor(body)) {
        issues.add(PreflightIssue.lyricsTooLong);
      }
      if (!draft.lyricsOwnershipConfirmed) {
        issues.add(PreflightIssue.lyricsOwnershipUnconfirmed);
      }
      if (_fingerprints.maxSimilarity(body) > similarityThreshold) {
        issues.add(PreflightIssue.lyricsNotOriginal);
      }
    }

    if (issues.isNotEmpty) return PreflightResult(issues);
    return PreflightResult(
      const [],
      draft: draft.copyWith(
        recipient: recipient,
        keywords: keywords,
        prompt: prompt,
        userLyrics: lyrics,
        clearUserLyrics: lyrics == null,
      ),
    );
  }

  /// The artist and imitation checks of [check] over one piece of free text —
  /// a description, the three words, own lyrics — so the composer can show
  /// the error under the field that holds it (docs/ui P18, ADR-0033).
  Set<PreflightIssue> screen(String text) => {
        if (_mentionsArtist(text)) PreflightIssue.artistName,
        if (_imitation.hasMatch(text) || _imitatesArtist(text)) PreflightIssue.styleImitation,
      };

  /// The recipient is a person's name, so a single-word artist name (a friend
  /// called Adele) stays allowed; an imitation phrase, a style word next to an
  /// artist, or a multi-word artist name is not (docs/ui P18, ADR-0008).
  bool _recipientImitates(String recipient) {
    if (recipient.isEmpty) return false;
    if (_imitation.hasMatch(recipient) || _imitatesArtist(recipient)) return true;
    final normalized = ' ${_normalize(recipient)} ';
    for (final artist in _artists) {
      final needle = _normalize(artist);
      if (!normalized.contains(' $needle ')) continue;
      if (needle.contains(' ')) return true;
      if (RegExp(r'\b(style|vibe|vibes|voice|type|like)\b').hasMatch(normalized)) {
        return true;
      }
    }
    return false;
  }

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  /// An imitation phrase directly followed by a blocklisted artist, in any case.
  bool _imitatesArtist(String text) {
    final lower = text.toLowerCase();
    final phrase = RegExp(r'(sounds?\s+like|in\s+the\s+style\s+of|voice\s+of|style\s+of)\s+(?:the\s+)?');
    for (final match in phrase.allMatches(lower)) {
      final rest = lower.substring(match.end);
      if (_artists.any(rest.startsWith)) return true;
    }
    return false;
  }

  bool _mentionsArtist(String text) {
    final normalized = ' ${text.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')} ';
    for (final artist in _artists) {
      final needle = artist.replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ');
      if (normalized.contains(' $needle ')) return true;
    }
    return false;
  }

  static String _stripTags(String lyrics) => lyrics
      .split('\n')
      .where((line) => !RegExp(r'^\s*\[[^\]]*\]\s*$').hasMatch(line))
      .join('\n')
      .trim();
}

extension on String {
  /// Length in user-perceived characters (approximated by code points, so an
  /// emoji or a CJK character counts once — what the counter shows).
  int get characters => runes.length;
}
