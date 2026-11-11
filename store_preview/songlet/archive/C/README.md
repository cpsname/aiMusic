# Script C — archived (ADR-0038)

"Your language, your style" (你的语言，你的风格): the country picker switching
Japan → Brazil → India, one song each in Japanese, Brazilian Portuguese and
Hindi, the download page and the commercial license. It shipped as the third
preview of each storefront until 2026-10-06; its claim (lyrics in your
language) now closes script B, and C is no longer rendered.

What is kept, as the record of what was generated and shown:

| File | What |
| --- | --- |
| `C.schema1.yaml` | the script as it was filmed, in the schema of the old `tools/store_preview` (the current tool does not load it) |
| `generation.yaml` | what `cmd/songlet-samples` generated for it (`c_songs`) |
| `captions.json` | its on-screen copy in the 13 ARB languages (keys removed from `lib/l10n/arb`) |
| `media/manifest.json` | its three Lyria songs (schema 2, each with its Lyria interaction id); the MP3s sit next to it, git-ignored like all media |

Bringing it back means porting the script to the current schema (a timeline
of cards, scenes and bridges on a narrative template — `feature_triptych`
fits), moving its entries back into `media/manifest.json`, its keys back into
the ARBs, and restoring `c_songs` generation in the products repo's
`cmd/songlet-samples` (removed in the same change; see its git history).
