# ADR-0030 — Inspiration composer (contract 02 v2.1)
Status: Accepted
Date: 2026-10-03

## Context
Contract 02 v2.1 (product ADR-S14 / S15, shipped together with the server) gives
every `Inspiration` a `cover_image_url`, a `default_model`
(`lyria-3-clip-preview` | `lyria-3.5`) and a `composer` block
(`hint{en,zh}`, `input_required`), next to the `occasion`, `default_vocals` and
`suggested_genre` it already sent. The server lists the 16 templates as
inspirations too (ADR-0029 amendment), so one card kind now starts every song.
Production does not send the new fields yet: the client must work both before
and after the release.

## Decision
- **A card with a `composer` block does not open a form.** Tapping it
  (`CreationDraftController.applyInspiration`) turns the card into a tag above the
  prompt field (`ComposerTag`, closable), shows `composer.hint` as the field's hint
  (English, or Simplified Chinese from the server; other languages show the
  English hint until the app has a translation), and moves the three selectors to
  `default_model` / `default_vocals` / `suggested_genre` (a value the card does not
  set stays as the user chose). The draft keeps the card's template, when it stands
  for one, only for the library's cover art. Picking another card starts the prompt
  afresh; picking the same one again keeps the text; the tag's close button returns
  to a free-form draft. A card without `composer` (an older server) behaves as in
  ADR-0029.
- **Send.** `input_required: false` → the send button works with nothing typed;
  `true` → it is there but disabled until there is text. Preflight asks for no
  recipient / keywords / text of an inspiration draft (the button enforces it).
  The request's prompt block starts with `inspiration: <slug>`; the typed text is
  `description:`. `template:` and the request's `template` field are not sent for
  an inspiration draft. The slug is stored with the work (works DB v5,
  `works.inspiration`, also in the sync record), so "another version" sends it
  again.
- **Voice.** With a card picked, the dictation panel has one action, "Use this
  text": the words go into the prompt field and the user stays on the composer
  (no keywords / lyrics split, no form).
- **Cover.** `cover_image_url` is the tile photo for every card, a template's
  included; when it fails to load the tile falls back to the template's own bundled
  photo, else the occasion's generic picture (`assets/occasions/<occasion>.jpg`).
  Without the field (older server) ADR-0029's sources apply.
- **Parsing is defensive:** an unknown `occasion`, `default_model` or
  `default_vocals` is left unset; a `composer` with no usable hint is no composer.

## Consequences
`SongModel` moved to `song_options.dart` (re-exported by `creation_draft.dart`)
so `Inspiration` can type `default_model` without an import cycle. The template
form (P03) stays for older servers and for the Festival tile. The mock server
still speaks contract 02 v1.2.
