# ADR-0029 — The create home's Inspiration row
Status: Accepted — tile behaviour superseded by ADR-0032
Date: 2026-10-01

## Context
Contract 02 v1.2 adds `inspirations[]` to `GET /v1/templates`: 24 entries
(`id, slug, name{en,zh}, style{en,zh}, preview_audio_url, duration_sec?, sort,
linked_template_id?`). The client renders them in `sort` order, plays the preview
URL as given, opens the linked template or prefills the prompt with `style.en`,
and localizes other languages itself, keyed by `name.en`, falling back to
English. The field may be absent; the endpoint has no ETag or version.

## Decision
- **One fetch for both lists.** `RemoteTemplateCatalog` (was
  `RemoteTemplateSamples`) implements `TemplateSampleSource` and the new
  `InspirationSource` over one per-session `/templates` response; a failed fetch
  is retried on the next use. `inspirationsProvider` turns an absent field or a
  failure into an empty list, and the row is then not shown.
- **Defensive parsing.** An entry missing a required field, or whose preview is
  not an absolute http(s) URL, is left out; ties in `sort` keep slug order. A
  `linked_template_id` this build does not know opens the composer like an
  unlinked entry.
- **Previews** download through the bare audio Dio from their absolute URL and
  are cached under a UUID v5 of the URL: when the platform moves the previews to
  its own storage (ADR-S12) the new audio is fetched, not the old file replayed.
  They play through the shared player as the template samples do (one preview at
  a time, never over a song).
- **Copy.** English and Simplified Chinese (`zh`, `zh-Hans`) come from the
  server. Every other language — Traditional Chinese included, since the server's
  `zh` is Simplified — looks up the English text in a local table
  (`inspiration_labels.dart`) whose ARB keys are named after the slug
  (`inspirationNameHappyBirthday`, `inspirationStyleHappyBirthday`), because an
  English sentence is not a valid ARB key. An entry the table does not know (a
  new server entry) shows its English text. Styles are translated the same way.
- **Tap.** Linked → the template form (P03). Unlinked → the composer, template
  cleared, prompt = `style.en` (English on purpose: it feeds the model).
- **Layout.** A horizontal row of `InspirationCard`s (ui_kit) under the template
  grid, in the same scroll; at accessibility text sizes a column of full-width
  cards. Card height scales with the text.

## Consequences
The 24 names and styles are translated in the app (11 languages beyond en/zh);
adding an entry on the server shows it in English until the table learns it.

## Amendment — 2026-10-03: one grid, one kind of tile
The separate Inspiration row (and `InspirationCard`) is retired: the 16 templates
and the server's inspirations are one grid of one tile (`TemplateTile`) under one
heading (`inspirationHeader`).

- **Merge.** `buildIdeas` (songlet_kit) yields an `Idea` per tile: the 16
  templates in their P01 order, each carrying the inspiration the server links to
  it (13 of the 24), then the remaining inspirations in `sort` order — 27 tiles,
  not 40. A template tile keeps the template's own (translated) name and photo;
  the linked inspiration lends its preview and style line. A link to a template
  this build lacks, or a second link to one template, stays a tile of its own
  (a second link still leads to the form). The templates need no network, so the
  grid is never empty and the server's tiles are only ever appended: nothing above
  them moves when `/templates` lands.
- **Cover, best source first:** a template's bundled photo
  (`assets/templates/`); an inspiration's bundled photo
  (`assets/inspirations/<slug>.jpg`, optional, read from the asset manifest);
  the server's optional `cover_url` (contract 02 v1.4 proposal, absolute http(s),
  `NetworkImage`); else a gradient from `CoverGradients` (FNV hash of the tile key,
  stable across launches) with an icon by slug (`ideaGlyph`; unknown slug → music
  note). A photo that is slow or fails leaves the gradient showing.
- **Play.** See the later amendment below: the inspiration's preview first, the
  template's own sample as fallback. A tile with neither says so (the generic
  error — only a transport failure reads "Network error"). The player state is
  the template id for template tiles, `inspiration:<id>` otherwise.
- **Tap.** Unchanged in effect: a tile with a template (its own or linked) opens
  the form; one without fills the composer with `style.en`. Such a tile shows as
  selected while the draft has no template and its prompt is that style.
- **Columns.** The existing label-fit rule (start at four, drop a column while a
  translated label would clip or break a word) now also reserves room for the 11
  standalone inspirations' names (`knownInspirationNames`), loaded or not, so the
  count is decided on the first frame and never reflows when they arrive. On a
  402 pt phone English now gets three columns (four on a Pro Max); German two.
- The style line is not drawn on the tile (it is the accessibility label's second
  half, and what the composer is prefilled with).
- `templatesHeader` (the old accessibility heading) is removed from the 13 ARBs.

## Amendment — 2026-10-03 (later): the server lists the templates as inspirations
Observed on the products backend the same day: `GET /v1/templates` no longer
carries `templates[]` and `linked_template_id` is gone. `inspirations[]` is now 32
entries: the 16 templates (slug = template id, `preview_audio_url` = the old
sample file under `r2.showsapp.org/Songlet/samples/`, which now exist) followed by
16 others, each with new optional fields `occasion`, `requires_recipient`,
`suggested_genre`, `default_vocals` (not used by the client yet).

- `Inspiration.linkedTemplate` = the template named by `linked_template_id`, else
  the one whose id is the slug. `buildIdeas` therefore merges all 16 template
  entries into their tiles by slug; the other 16 are standalone tiles (32 tiles).
- **Play order reversed:** the inspiration's preview first, the template's own
  sample (`templates[]`, older servers) only when there is no preview or it fails;
  both failing reports the preview's failure. The earlier "sample first, remember
  the failure" rule caused `Bad state: no sample for <id>` on every template tile
  once `templates[]` disappeared.
- `knownInspirationNames` (column reservation) now covers the 16 standalone names.

