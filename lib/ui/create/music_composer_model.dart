import 'package:flutter/foundation.dart';
import 'package:songlet_kit/songlet_kit.dart';

/// What the composer is built from (ADR-0033): free input (state A) or a
/// picked card's fields (state B). The options (state C) unfold over either.
enum MusicComposerSubject {
  /// The prompt field with "+" (photos) and the mic.
  free,

  /// The card's head, its name and three words (and "Your words" for a card
  /// that asks for them).
  picked;

  static MusicComposerSubject of(MusicCreationDraft? draft) =>
      (draft?.hasPick ?? false) ? picked : free;
}

/// The primary action's verb (ADR-0035).
enum MusicCreateActionKind {
  /// "Create preview".
  preview,

  /// "Create {name}'s preview": a picked card with a name.
  previewFor,

  /// "Create full song" (with or without Premier's chorus video).
  fullSong,
}

/// What the primary action says it spends, read from the server's ledger
/// (ADR-0035, ADR-0031): never claimed when the ledger does not show it.
enum MusicCreateCost {
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
class MusicCreateAction {
  const MusicCreateAction({
    required this.kind,
    required this.cost,
    required this.enabled,
    this.name,
  });

  /// [draft] as the composer shows it; [entitlement] null while the ledger is
  /// loading or failed; [busy] while a generation is in flight.
  factory MusicCreateAction.of({
    required MusicCreationDraft? draft,
    required MusicEntitlement? entitlement,
    bool busy = false,
  }) {
    if (draft == null) {
      return const MusicCreateAction(
        kind: MusicCreateActionKind.preview,
        cost: MusicCreateCost.none,
        enabled: false,
      );
    }
    final full = draft.model == MusicSongModel.fullSong;
    final name = draft.hasPick ? draft.recipient.trim() : '';
    return MusicCreateAction(
      kind: full
          ? MusicCreateActionKind.fullSong
          : (name.isEmpty
                ? MusicCreateActionKind.preview
                : MusicCreateActionKind.previewFor),
      name: full || name.isEmpty ? null : name,
      cost: _cost(full: full, entitlement: entitlement),
      enabled: !busy && hasMaterial(draft),
    );
  }

  final MusicCreateActionKind kind;

  /// The picked card's name for [MusicCreateActionKind.previewFor].
  final String? name;
  final MusicCreateCost cost;
  final bool enabled;

  static MusicCreateCost _cost({
    required bool full,
    required MusicEntitlement? entitlement,
  }) {
    if (entitlement == null) return MusicCreateCost.none;
    if (full)
      return entitlement.canMakeSong ? MusicCreateCost.song : MusicCreateCost.none;
    if (!entitlement.canMakeClip) return MusicCreateCost.none;
    return entitlement.tier.isPaid ? MusicCreateCost.preview : MusicCreateCost.free;
  }

  /// Whether what would be sent can make a song: free input needs words,
  /// photos or own lyrics; a picked card is enough by itself unless it asks
  /// for the user's words (`input_required`), then those or own lyrics. The
  /// finer rules (lengths, artists, the material rule) stay with preflight.
  static bool hasMaterial(MusicCreationDraft draft) {
    final sent = draft.forSubmit();
    if (draft.hasPick) {
      return !draft.sendsPromptWithPick || sent.hasPrompt || sent.hasUserLyrics;
    }
    return sent.hasPrompt || sent.usesPhotos || sent.hasUserLyrics;
  }

  @override
  bool operator ==(Object other) =>
      other is MusicCreateAction &&
      other.kind == kind &&
      other.name == name &&
      other.cost == cost &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(kind, name, cost, enabled);

  @override
  String toString() => 'MusicCreateAction($kind, $name, $cost, enabled: $enabled)';
}

/// One value of the composer's summary row ("Preview · MusicVocals on · Indie
/// Pop ›", ADR-0033): a projection of the draft, labelled by the app.
enum MusicSummaryPart {
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
List<MusicSummaryPart> summaryParts(
  MusicCreationDraft draft, {
  required bool optionsShown,
}) {
  final full = draft.model == MusicSongModel.fullSong;
  final sent = draft.forSubmit();
  return [
    if (!full)
      MusicSummaryPart.preview
    else if (draft.autoVideo == MusicAutoVideo.chorus)
      MusicSummaryPart.songAndChorus
    else
      MusicSummaryPart.fullSong,
    switch (draft.vocals) {
      MusicVocals.vocals => MusicSummaryPart.vocalsOn,
      MusicVocals.instrumental => MusicSummaryPart.instrumental,
      MusicVocals.custom => MusicSummaryPart.anyVocals,
    },
    if ((draft.genre ?? '').trim().isEmpty)
      MusicSummaryPart.anyGenre
    else
      MusicSummaryPart.genre,
    if (!optionsShown && sent.hasUserLyrics) MusicSummaryPart.ownLyrics,
    if (!optionsShown && sent.autoVideo == MusicAutoVideo.lyric) MusicSummaryPart.video,
  ];
}
