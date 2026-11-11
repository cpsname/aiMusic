import 'package:meta/meta.dart';

import 'occasion.dart';
import 'song_options.dart';
import 'song_template.dart';

/// Copy the server sends in two languages (contract 02 `LocalizedText`;
/// `zh` is Simplified Chinese). Other languages are mapped on the client,
/// keyed by [en] (ADR-0029).
@immutable
class LocalizedText {
  const LocalizedText({required this.en, required this.zh});

  final String en;
  final String zh;

  @override
  bool operator ==(Object other) => other is LocalizedText && other.en == en && other.zh == zh;

  @override
  int get hashCode => Object.hash(en, zh);
}

/// What the composer shows once an inspiration is picked (contract 02 v2.1
/// `composer`): the hint in the empty prompt field and whether sending needs
/// text.
@immutable
class InspirationComposer {
  const InspirationComposer({required this.hint, required this.inputRequired});

  final LocalizedText hint;

  /// False: the song can be made without typing anything.
  final bool inputRequired;

  @override
  bool operator ==(Object other) =>
      other is InspirationComposer && other.hint == hint && other.inputRequired == inputRequired;

  @override
  int get hashCode => Object.hash(hint, inputRequired);
}

/// One entry of the create home's Inspiration row (contract 02 v1.2
/// `Inspiration`, ADR-0029): a short preview to listen to and a way into a
/// song — its linked template, or a prompt prefilled with its style.
@immutable
class Inspiration {
  const Inspiration({
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
  final LocalizedText name;
  final LocalizedText style;

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
  /// (`custom` | `vocals` | `instrumental`) and `suggested_genre`: Vocals and
  /// Genre jump to the last two when the card is picked; Length starts at a
  /// preview whatever `default_model` says (ADR-0036), which is kept as data.
  final String? defaultModelWire;
  final String? defaultVocalsWire;
  final String? suggestedGenre;

  /// Contract 02 v2.1 `composer`. Present = picking the card turns it into a
  /// tag above the prompt field; absent (an older server) = the template form
  /// or a prefilled prompt, as before.
  final InspirationComposer? composer;

  /// `requires_recipient`: whether the composer asks for a name; null = the
  /// occasion's rule.
  final bool? requiresRecipient;

  /// `default_on_video`, not in contract 02 v2.1 (parsed in case the server
  /// adds it): where "also make a video" starts when the card is picked; null
  /// = the occasion's rule.
  final bool? defaultOnVideo;

  Occasion? get occasion {
    for (final o in Occasion.values) {
      if (o.wire == occasionWire) return o;
    }
    return null;
  }

  SongModel? get defaultModel => SongModel.tryFromWire(defaultModelWire);

  Vocals? get defaultVocals {
    for (final v in Vocals.values) {
      if (v.wire == defaultVocalsWire) return v;
    }
    return null;
  }

  /// The player state while this preview plays (shared with [Idea.key]).
  String get playKey => 'inspiration:$id';

  /// The template this entry stands for when this client knows it: the one
  /// the server links, else the one whose id is this slug (the server now
  /// lists the 16 templates as inspirations named by their template id). Null
  /// opens the composer with [style]'s English text as the prompt.
  SongTemplate? get linkedTemplate => SongTemplate.fromId(linkedTemplateId) ?? SongTemplate.fromId(slug);
}

/// The inspirations and their previews (`GET /v1/templates`).
abstract interface class InspirationSource {
  /// Sorted by `sort`; empty when the server sends none (an older server).
  Future<List<Inspiration>> inspirations();

  /// Local path of [inspiration]'s preview, downloaded on first use.
  Future<String> previewPath(Inspiration inspiration);
}
