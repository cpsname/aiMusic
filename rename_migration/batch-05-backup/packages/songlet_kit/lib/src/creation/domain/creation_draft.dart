import 'package:meta/meta.dart';

import 'occasion.dart';
import 'region_preset.dart';
import 'song_options.dart';
import 'song_template.dart';

export 'song_options.dart' show SongModel;

/// Everything the user chose on the create home, its composer, panels and
/// region sheet (PRD §3.1; docs/ui P01–P04). The raw material the prompt block
/// is built from; persisted with the work so the full song (or "another
/// version", F14) reuses it. It holds the free input and the picked card's
/// fields side by side; [forSubmit] decides which of them a song is made from
/// (ADR-0033).
@immutable
class CreationDraft {
  const CreationDraft({
    required this.occasion,
    required this.region,
    required this.genre,
    required this.lyricLanguage,
    this.template,
    this.inspirationSlug,
    this.pickRequiresRecipient,
    this.pickInputRequired,
    this.model = SongModel.clip,
    this.vocals = Vocals.vocals,
    this.prompt = '',
    this.festival,
    this.recipient = '',
    this.keywords = const <String>[],
    this.userLyrics,
    this.lyricsOwnershipConfirmed = false,
    this.photos = const <List<int>>[],
    this.imageBids = const <String>[],
    this.autoVideo = AutoVideo.none,
  });

  final Occasion occasion;
  final RegionPreset region;

  /// A region preset genre or a `Genre.label`; null = "Custom — based on your
  /// prompt" (docs/ui P02c).
  final String? genre;
  final LyricLanguage lyricLanguage;

  /// The create-home template (docs/ui P01), null for a free-form prompt.
  final SongTemplate? template;

  /// The inspiration the draft started from (its slug; contract 02 v2.1):
  /// shown as a tag above the prompt field and sent as `inspiration:`. The
  /// tag's name, hint and whether text is required come from the server's
  /// entry (looked up by this slug), not from the draft.
  final String? inspirationSlug;

  /// The picked entry's `requires_recipient`; null = the template's or the
  /// occasion's rule.
  final bool? pickRequiresRecipient;

  /// The picked entry's `composer.input_required`: the card asks for the
  /// user's own words, so the composer shows [prompt] as its "Your words"
  /// field and sends it. Null or false = the card's fields only (ADR-0033).
  final bool? pickInputRequired;

  /// Length: Short = clip, Standard = full song (docs/ui P02a; the composer's
  /// summary row shows it — ADR-0033).
  final SongModel model;
  final Vocals vocals;

  /// The composer's free-text description (≤ `Preflight.maxPrompt`): the
  /// free input's prompt field, or a card's "Your words" field.
  final String prompt;
  final Festival? festival;
  final String recipient;
  final List<String> keywords;

  /// Optional own lyrics (PRD F03), already section-tagged by the preflight.
  final String? userLyrics;

  /// "These lyrics are mine or I have the right to use them" (PRD §9.1).
  final bool lyricsOwnershipConfirmed;

  /// Picked photos, JPEG bytes (≤ 1024 px, q 0.8 — done natively). In memory
  /// only; never written to disk (PRD F04).
  final List<List<int>> photos;

  /// Upload bids of [photos] once uploaded (valid server-side for 24 h).
  final List<String> imageBids;

  /// Make a music video automatically once the song is ready (docs/ui P28).
  final AutoVideo autoVideo;

  bool get usesPhotos => photos.isNotEmpty || imageBids.isNotEmpty;

  bool get hasUserLyrics => (userLyrics ?? '').trim().isNotEmpty;

  bool get hasPrompt => prompt.trim().isNotEmpty;

  /// A tile is picked: the server entry ([inspirationSlug]) or, on the
  /// offline grid, a built-in [template]. The composer then shows the name,
  /// three words and lyrics fields.
  bool get hasPick => inspirationSlug != null || template != null;

  /// Whether the picked card sends [prompt] as the user's words.
  bool get sendsPromptWithPick => pickInputRequired ?? false;

  /// What is sent and saved (ADR-0033). The composer shows either the free
  /// input or the picked card's fields, and only what it shows is sent; the
  /// rest stays in the draft for the way back:
  /// * free input: the description, photos and own lyrics — no name or words;
  /// * a pick: the name, three words and own lyrics, the description only for
  ///   a card that asks for the user's words ([pickInputRequired]), no photos;
  /// * an instrumental takes no lyrics (the server rejects both together,
  ///   contract 02 v2.1 §2.4), and a preview no automatic video (the switch
  ///   is offered with the full song only).
  CreationDraft forSubmit() {
    var sent = hasPick
        ? copyWith(
            prompt: sendsPromptWithPick ? null : '',
            photos: const <List<int>>[],
            imageBids: const <String>[],
          )
        : copyWith(recipient: '', keywords: const <String>[]);
    if (vocals == Vocals.instrumental && userLyrics != null) {
      sent = sent.copyWith(clearUserLyrics: true, lyricsOwnershipConfirmed: false);
    }
    if (model == SongModel.clip && autoVideo.isOn) {
      sent = sent.copyWith(autoVideo: AutoVideo.none);
    }
    return sent;
  }

  /// Whether the form asks for a recipient name.
  bool get requiresRecipient =>
      pickRequiresRecipient ?? template?.requiresRecipient ?? occasion.requiresRecipient;

  CreationDraft copyWith({
    Occasion? occasion,
    RegionPreset? region,
    String? genre,
    bool customGenre = false,
    LyricLanguage? lyricLanguage,
    SongTemplate? template,
    bool clearTemplate = false,
    String? inspirationSlug,
    bool clearInspiration = false,
    bool? pickRequiresRecipient,
    bool? pickInputRequired,
    SongModel? model,
    Vocals? vocals,
    String? prompt,
    Festival? festival,
    bool clearFestival = false,
    String? recipient,
    List<String>? keywords,
    String? userLyrics,
    bool clearUserLyrics = false,
    bool? lyricsOwnershipConfirmed,
    List<List<int>>? photos,
    List<String>? imageBids,
    AutoVideo? autoVideo,
  }) =>
      CreationDraft(
        occasion: occasion ?? this.occasion,
        region: region ?? this.region,
        genre: customGenre ? null : (genre ?? this.genre),
        lyricLanguage: lyricLanguage ?? this.lyricLanguage,
        template: clearTemplate ? null : (template ?? this.template),
        inspirationSlug: clearInspiration ? null : (inspirationSlug ?? this.inspirationSlug),
        pickRequiresRecipient: clearInspiration ? null : (pickRequiresRecipient ?? this.pickRequiresRecipient),
        pickInputRequired: clearInspiration ? null : (pickInputRequired ?? this.pickInputRequired),
        model: model ?? this.model,
        vocals: vocals ?? this.vocals,
        prompt: prompt ?? this.prompt,
        festival: clearFestival ? null : (festival ?? this.festival),
        recipient: recipient ?? this.recipient,
        keywords: keywords ?? this.keywords,
        userLyrics: clearUserLyrics ? null : (userLyrics ?? this.userLyrics),
        lyricsOwnershipConfirmed:
            lyricsOwnershipConfirmed ?? this.lyricsOwnershipConfirmed,
        photos: photos ?? this.photos,
        imageBids: imageBids ?? this.imageBids,
        autoVideo: autoVideo ?? this.autoVideo,
      );
}
