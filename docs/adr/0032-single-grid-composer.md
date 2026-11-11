# ADR-0032 — One grid, one pick, one send: the composer unfolds in place
Status: Accepted
Date: 2026-10-04
Supersedes: the tile behaviour of ADR-0029 (merge, gradient cover, form landing).
Amends ADR-0008: a template is sent as its scene slug (`inspiration`), no `template` field.

## Context
The create home had three tile shapes (template, merged template + inspiration,
unlinked inspiration) and two ways to start a song: the composer's send button and
the P03 form page a template tile pushed. Tapping a tile left the composer, so its
text, length and genre were out of view; "Change" on the form was the way back.
Contract 02 v2.0 already makes the server's `inspirations[]` the single list (the
16 templates are entries of it, named by their template id). Contract 02 v2.1
(the product BFF's client contract, 2026-10-04) fixes the request: eight top-level
fields, the scene as its slug, everything the user filled in inside `prompt`, and
fields outside the eight dropped silently.

## Decision
- **One grid.** `buildIdeas`: the server's list by `sort`, nothing merged on the
  client; with no list (not loaded yet, offline, an older server) the 16 built-in
  templates. Every tile is a photo: `cover_image_url` → the template's bundled
  photo → `assets/inspirations/<slug>.jpg` → the occasion's photo. The gradient +
  icon skin (`coverSeed`, `glyph`, `idea_glyph.dart`) is gone.
- **One pick, held by the draft.** `creationDraftProvider` holds it
  (`inspirationSlug` + `inspirationId`, or `template` on the offline grid);
  `Idea.isPickedIn(draft)` draws the tile's outline and inward scale. Tap picks,
  tap again (or the tag's ✕) unpicks (`clearPick`). The play button only plays
  `preview_audio_url` and never changes the pick.
- **The composer unfolds in place.** A pick shows the tag, then the prompt field (still
  the first thing to type into — with the fields above it users typed their message
  into the name field), then the former form's fields: name (label by
  `requires_recipient`, never required), three words, the folded own-lyrics row
  (hidden for an instrumental, which takes no lyrics), with the P18 errors under them.
  The card's `composer.hint` is the prompt field's **placeholder** only — the card's
  style or hint is never put in the field or sent. Length / Vocals / Genre take
  `default_model` / `default_vocals` (absent → the client default) / `suggested_genre`,
  "also make a video" `default_on_video` if a server ever sends it (absent → the
  occasion rule). Unpicking folds the fields away and keeps what was typed; a
  free-input song does not send them (`CreationDraft.forSubmit`). Names and styles in
  languages other than `en`/`zh` map by **slug** to ARB strings, English fallback.
- **One send.** The composer's button is the only way to start a song from the
  create home. The P03 form page, its "Change" button and `TemplateRoute` are gone;
  `/create/template/<id>` stays a deep link and resolves to `/create?template=<id>`:
  the home picks that tile, scrolls it into view and unfolds the composer
  (`custom` = free input). A template id picked before the list lands is replaced by
  the server's entry of the same slug. The festival landing goes there too.
- **Request (contract 02 v2.1 §2).** `GenerationRequest.fromDraft`: `model`, `occasion`
  (the scene's), `inspiration` (the scene's **slug**, never its `id`; an offline
  template's id, which the server lists as a scene), `region`, `prompt`, `lyrics?`,
  `images?`, `client_ref` — nothing else. `PromptBlock.build`: `inspiration` (the same
  slug, first line), `recipient`, `keywords`, `description` (the user's own text only),
  `genre`, `vocals`, `lyric_language` (both always), `festival`, `photos`, `note`
  (≤ 600), each key once, no control characters. A 40001 with `details.inspiration`
  refetches the list.

## Consequences
- The mock implements the v2.1 rules (slug checks, prompt rules, unknown fields
  ignored) with the product repo's 32 entries.
- Page goldens: P03 is the deep-link state, P18 the composer's validation, and
  `P01-picked` the tapped pick.
