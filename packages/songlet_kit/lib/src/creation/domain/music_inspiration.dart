import 'package:meta/meta.dart';

import 'music_occasion.dart';
import 'music_song_options.dart';
import 'music_song_template.dart';

/// Copy the server sends in two languages (contract 02 `MusicLocalizedText`;
/// `zh` is Simplified Chinese). Other languages are mapped on the client,
/// keyed by [en] (ADR-0029).
@immutable
class MusicLocalizedText {
  const MusicLocalizedText({required this.en, required this.zh});

  final String en;
  final String zh;

  @override
  bool operator ==(Object other) => other is MusicLocalizedText && other.en == en && other.zh == zh;

  @override
  int get hashCode => Object.hash(en, zh);
}

/// What the composer shows once an inspiration is picked (contract 02 v2.1
/// `composer`): the hint in the empty prompt field and whether sending needs
/// text.
@immutable
class MusicInspirationComposer {
  const MusicInspirationComposer({required this.hint, required this.inputRequired});

  final MusicLocalizedText hint;

  /// False: the song can be made without typing anything.
  final bool inputRequired;

  @override
  bool operator ==(Object other) =>
      other is MusicInspirationComposer && other.hint == hint && other.inputRequired == inputRequired;

  @override
  int get hashCode => Object.hash(hint, inputRequired);
}

/// One entry of the create home's MusicInspiration row (contract 02 v1.2
/// `MusicInspiration`, ADR-0029): a short preview to listen to and a way into a
/// song — its linked template, or a prompt prefilled with its style.
@immutable
class MusicInspiration {
  const MusicInspiration({
    required this.id,
    required this.slug,
    required this.name,
    required this.style,
    required this.previewAudioUrl,
    required this.sort,
    this.durationSec,
    this.linkedTemplateId,
    this.coverImageUrl,
    this.occasionWire,
    this.defaultModelWire,
    this.defaultVocalsWire,
    this.suggestedGenre,
    this.composer,
    this.requiresRecipient,
    this.defaultOnVideo,
  });

  /// Stable across releases (UUID v5 of the slug): usable as a key.
  final String id;
  final String slug;
  final MusicLocalizedText name;
  final MusicLocalizedText style;

  /// Absolute https URL, played as given (never joined to a base URL).
  final String previewAudioUrl;
  final int sort;

  /// Preview length; null = unknown.
  final int? durationSec;

  /// The template this inspiration stands for, as the server names it.
  final String? linkedTemplateId;

  /// Absolute https URL of the cover photo (contract 02 v2.1
  /// `cover_image_url`); null on an older server = the tile draws its own cover.
  final String? coverImageUrl;

  /// `occasion` as sent (`birthday`, `soundtrack`…): what the song is for, and
  /// the generic picture a failed cover falls back to.
  final String? occasionWire;

  /// `default_model` (`lyria-3-clip-preview` | `lyria-3.5`), `default_vocals`
  /// (`custom` | `vocals` | `instrumental`) and `suggested_genre`: MusicVocals and
  /// MusicGenre jump to the last two when the card is picked; Length starts at a
  /// preview whatever `default_model` says (ADR-0036), which is kept as data.
  final String? defaultModelWire;
  final String? defaultVocalsWire;
  final String? suggestedGenre;

  /// Contract 02 v2.1 `composer`. Present = picking the card turns it into a
  /// tag above the prompt field; absent (an older server) = the template form
  /// or a prefilled prompt, as before.
  final MusicInspirationComposer? composer;

  /// `requires_recipient`: whether the composer asks for a name; null = the
  /// occasion's rule.
  final bool? requiresRecipient;

  /// `default_on_video`, not in contract 02 v2.1 (parsed in case the server
  /// adds it): where "also make a video" starts when the card is picked; null
  /// = the occasion's rule.
  final bool? defaultOnVideo;

  MusicOccasion? get occasion {
    for (final o in MusicOccasion.values) {
      if (o.wire == occasionWire) return o;
    }
    return null;
  }

  MusicSongModel? get defaultModel => MusicSongModel.tryFromWire(defaultModelWire);

  MusicVocals? get defaultVocals {
    for (final v in MusicVocals.values) {
      if (v.wire == defaultVocalsWire) return v;
    }
    return null;
  }

  /// The player state while this preview plays (shared with [MusicIdea.key]).
  String get playKey => 'inspiration:$id';

  /// The template this entry stands for when this client knows it: the one
  /// the server links, else the one whose id is this slug (the server now
  /// lists the 16 templates as inspirations named by their template id). Null
  /// opens the composer with [style]'s English text as the prompt.
  MusicSongTemplate? get linkedTemplate => MusicSongTemplate.fromId(linkedTemplateId) ?? MusicSongTemplate.fromId(slug);
}

/// The inspirations and their previews (`GET /v1/templates`).
abstract interface class MusicInspirationSource {
  /// Sorted by `sort`; empty when the server sends none (an older server).
  Future<List<MusicInspiration>> inspirations();

  /// Local path of [inspiration]'s preview, downloaded on first use.
  Future<String> previewPath(MusicInspiration inspiration);
}
