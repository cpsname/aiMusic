import 'package:flutter/foundation.dart';
import 'package:songlet_kit/songlet_kit.dart';

/// What the composer is built from (ADR-0033): free input (state A) or a
/// picked card's fields (state B). The options (state C) unfold over either.
enum ComposerSubject {
  /// The prompt field with "+" (photos) and the mic.
  free,

  /// The card's head, its name and three words (and "Your words" for a card
  /// that asks for them).
  picked;

  static ComposerSubject of(CreationDraft? draft) =>
      (draft?.hasPick ?? false) ? picked : free;
}

/// The primary action's verb (ADR-0035).
enum CreateActionKind {
  /// "Create preview".
  preview,

  /// "Create {name}'s preview": a picked card with a name.
  previewFor,

  /// "Create full song" (with or without Premier's chorus video).
  fullSong,
}

/// What the primary action says it spends, read from the server's ledger
/// (ADR-0035, ADR-0031): never claimed when the ledger does not show it.
enum CreateCost {
  /// A free account with free previews left.
  free,

  /// A plan's included preview.
  preview,

  /// An included full song (plan or pack).
  song,

  /// Nothing to promise: no allowance left, or the ledger is not known yet.
  /// The server answers `QUOTA_EXHAUSTED` and the paywall opens.
  none,
}

/// The composer's one primary action: its words and whether it can be
/// pressed. Pure — built from the draft and the ledger, so every row of the
/// label table is unit-tested without a widget.
@immutable
class CreateAction {
  const CreateAction({
    required this.kind,
    required this.cost,
    required this.enabled,
    this.name,
  });

  /// [draft] as the composer shows it; [entitlement] null while the ledger is
  /// loading or failed; [busy] while a generation is in flight.
  factory CreateAction.of({
    required CreationDraft? draft,
    required MusicEntitlement? entitlement,
    bool busy = false,
  }) {
    if (draft == null) {
      return const CreateAction(
        kind: CreateActionKind.preview,
        cost: CreateCost.none,
        enabled: false,
      );
    }
    final full = draft.model == SongModel.fullSong;
    final name = draft.hasPick ? draft.recipient.trim() : '';
    return CreateAction(
      kind: full
          ? CreateActionKind.fullSong
          : (name.isEmpty
                ? CreateActionKind.preview
                : CreateActionKind.previewFor),
      name: full || name.isEmpty ? null : name,
      cost: _cost(full: full, entitlement: entitlement),
      enabled: !busy && hasMaterial(draft),
    );
  }

  final CreateActionKind kind;

  /// The picked card's name for [CreateActionKind.previewFor].
  final String? name;
  final CreateCost cost;
  final bool enabled;

  static CreateCost _cost({
    required bool full,
    required MusicEntitlement? entitlement,
  }) {
    if (entitlement == null) return CreateCost.none;
    if (full)
      return entitlement.canMakeSong ? CreateCost.song : CreateCost.none;
    if (!entitlement.canMakeClip) return CreateCost.none;
    return entitlement.tier.isPaid ? CreateCost.preview : CreateCost.free;
  }

  /// Whether what would be sent can make a song: free input needs words,
  /// photos or own lyrics; a picked card is enough by itself unless it asks
  /// for the user's words (`input_required`), then those or own lyrics. The
  /// finer rules (lengths, artists, the material rule) stay with preflight.
  static bool hasMaterial(CreationDraft draft) {
    final sent = draft.forSubmit();
    if (draft.hasPick) {
      return !draft.sendsPromptWithPick || sent.hasPrompt || sent.hasUserLyrics;
    }
    return sent.hasPrompt || sent.usesPhotos || sent.hasUserLyrics;
  }

  @override
  bool operator ==(Object other) =>
      other is CreateAction &&
      other.kind == kind &&
      other.name == name &&
      other.cost == cost &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(kind, name, cost, enabled);

  @override
  String toString() => 'CreateAction($kind, $name, $cost, enabled: $enabled)';
}

/// One value of the composer's summary row ("Preview · Vocals on · Indie
/// Pop ›", ADR-0033): a projection of the draft, labelled by the app.
enum SummaryPart {
  preview,
  fullSong,
  songAndChorus,
  vocalsOn,
  instrumental,
  anyVocals,
  genre,
  anyGenre,
  ownLyrics,
  video,
}

/// The summary row's parts for [draft]: length, vocals, genre, then — while
/// the options are folded, so nothing that will be sent is out of sight —
/// own lyrics and the automatic video when they apply.
List<SummaryPart> summaryParts(
  CreationDraft draft, {
  required bool optionsShown,
}) {
  final full = draft.model == SongModel.fullSong;
  final sent = draft.forSubmit();
  return [
    if (!full)
      SummaryPart.preview
    else if (draft.autoVideo == AutoVideo.chorus)
      SummaryPart.songAndChorus
    else
      SummaryPart.fullSong,
    switch (draft.vocals) {
      Vocals.vocals => SummaryPart.vocalsOn,
      Vocals.instrumental => SummaryPart.instrumental,
      Vocals.custom => SummaryPart.anyVocals,
    },
    if ((draft.genre ?? '').trim().isEmpty)
      SummaryPart.anyGenre
    else
      SummaryPart.genre,
    if (!optionsShown && sent.hasUserLyrics) SummaryPart.ownLyrics,
    if (!optionsShown && sent.autoVideo == AutoVideo.lyric) SummaryPart.video,
  ];
}
