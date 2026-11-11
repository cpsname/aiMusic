# ADR-0033 — The composer in three states, one primary action
Status: Accepted
Date: 2026-10-05
Supersedes: ADR-0015 (the mode chip, Preview/Full beside Length).
Amends: ADR-0032 (the prompt field stays under a pick; lyrics fold away with free input; the send button).

## Context
A first session met nine decisions on the create home: a tile, the prompt, the
"Music" source chip, the Preview/Full control, Length, Vocals and Genre chips, and —
once a tile was picked — a name and three words; then a send arrow inside the prompt
field. Preview/Full and Length were one state shown twice; "Music" had no alternative
anyone chose; with a tile picked the free prompt stayed on screen next to the card's
own fields, so it was unclear which text the song was made from. The product's model
is one sentence: **who it is for → what to say → how it sounds → start.**

## Decision
- **Three states, one draft.** The composer shows
  - **A — free input** (no pick): the prompt field with "+" (photos, P04) at its start
    and the mic (P03a) at its end; placeholder "Describe the song, or pick an idea
    above" ("…or pick an idea" beside the grid on iPad);
  - **B — a picked card** (`CreationDraft.hasPick`): the card's head (photo, name, ✕)
    and its fields — name ("Their name" / "Name (optional)" by `requires_recipient`)
    and three words; a card with `input_required` adds **"Your words"** (its hint as
    the placeholder) — in place of the prompt field. No photos, no mic;
  - **C — options**, over A or B, unfolded by the **summary row** ("Preview · Vocals on
    · Indie Pop ›"): the Length / Vocals / Genre selectors (`ParamChip` with its value,
    opening the P02a–c panels), own lyrics (not for an instrumental) and, under Standard
    only, "Also make a lyric video" (moved out of the Length panel).
- **State C is a route parameter**, `/create?options=1` (ADR-0003): it deep-links, a
  panel opens from it (`?panel=` implies it) and closes back to it, and the goldens
  render it by location. A and B are derived from the draft, never stored twice.
- **Mutually exclusive text, one assembler.** Both inputs live in `creationDraftProvider`;
  `CreationDraft.forSubmit()` sends only what the composer shows — free input: the
  description, photos, own lyrics; a pick: name, three words, own lyrics, and the
  description only for an `input_required` card (`pickInputRequired`, also rebuilt by
  `draftFromWork` for "full song" / "another version"). Everything else stays in the
  draft for the way back; a preview never carries the automatic video. The request
  (contract 02 v2.1 §2) is unchanged.
- **One primary action**, under the fields and outside their scroll (`ObsButton`,
  `composer.create`): its words follow the length, the name and the ledger (ADR-0035).
  The send arrow, the source chip and its sheet, the Preview/Full control and the
  standing "Artist names can't be used" note are gone; preflight issues show under the
  field that holds the text (`Preflight.screen` attributes an artist or imitation to
  the description, the three words or the lyrics), the rest in the message banner.
- **Dictation is free input**: its one action puts the words in the prompt
  (`VoiceCapturePanel.actions`).
- **Motion**: state switches animate over a new token, `SongletMotion.state` (200 ms),
  with `emphasizedCurve`; reduce-motion collapses them to none.

## Consequences
- The first session is three decisions: the tile, the name, the action.
- Own lyrics can go with free input (the server counts them as material).
- `ComposerCard` takes `head / body / summary / options / primaryAction`; `ComposerActions`
  and `SourceChip` are removed; `ComposerSummary` is new; `ComposerTag` shows the card's
  photo (`CoverFallback`, shared with `TemplateTile`).
- ARB: new composer and action keys; the source chip copy, `composerCreate`,
  `inputArtistNote` and the keyword / lyrics dictation actions are removed (13 locales).
