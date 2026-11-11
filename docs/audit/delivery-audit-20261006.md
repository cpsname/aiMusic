# Delivery audit — App Store previews v2: two marketing previews per storefront on the reusable tool (2026-10-06)

Branch `feat/store-preview-v2` (from `main` f781751). The tool itself was
built in the template (`iap_template` branch `feat/store-preview-tool`,
audited in its `docs/audit/delivery-audit-20261006.md`) and vendored here.

## What was delivered

| Repo | Commit | Content |
| --- | --- | --- |
| iap_template | 360e663 … 2d03910 | `packages/store_preview`, `packages/store_preview_driver`, Apple rules, ADR-0001–0008, the studio_app sample |
| genaistudio-products | 2fb72b8 | `cmd/songlet-samples`: manifest schema 2 for scripts A and B (license block, script variables, app data), `-migrate` from schema 1 with the archive of retired scripts; C generation retired |
| songlet | cdc49be (E) | the tool vendored (stamp); `store_preview/songlet/` (app.yaml, generation.yaml, scripts A and B, captions, manifest schema 2 with 84 entries); script C archived with its songs, copy and spec; ARBs: `storePreviewAShare`, `storePreviewCta`, `storePreviewDisclosure`, `CLanguage` → `BLanguage`, C keys archived; mock demo profile on schema 2 |
| songlet | 6426b72 (F) | `integration_test/store_preview_test.dart` on `store_preview_driver` with Songlet's steps; `RunnerUITests/StorePreviewHelper.swift`; `tools/store_preview` removed; Makefile / CLAUDE.md / docs; ADR-0038; the 24 previews rendered and exported |

## The previews

`dist/songlet/<storefront>/{A,B}.mp4` (+ `.poster.png`, `.captions.srt`,
`.edl.json`), 12 storefronts, iPhone 6.9"; `dist/songlet/upload-checklist.md`
(also `docs/store/preview-upload-checklist.md`). Copied into
`listings/com.songlet.ios/locales/<storefront>/previews/iphone-6.9/` (outside
git), where the earlier `A/B/C.mp4` were no longer present.

| | A "A song with their name in it" | B "Your photos set the mood" |
| --- | --- | --- |
| Template / rhythm | input_wait_result_share / 25 s | input_wait_result_share / 25 s |
| Intro card (0–1 s) | icon + claim over the storefront's photo | icon + claim over the storefront's photo |
| Footage | name, three words, the wait, the player on the chorus (real time), the share card | photos picked, lyric video on, the wait, the lyric video (real time), the share sheet, the country and lyric language |
| Generated-image transition | bridge at 10–10.5 s through a photo; image-backed cards | the same |
| End card (23–25 s) | icon, Songlet, call to action, "Requires a subscription or credits" | the same |
| Footage share | 86.0 % | 86.0 % |
| Poster | 13 s, player | 13 s, lyric video |

## Verification

| Check | Result |
| --- | --- |
| `make store-preview` (render A, B, all storefronts) | 24 × PASS in spec (886×1920, 25.01 s, 30 fps, H.264 High@4.0 10.96–11.06 Mbps, AAC stereo 44.1 kHz 256 kbps, ~33.5 MB), compliance and narrative |
| Visual review | every storefront's frames sampled: cards, captions in all 12 scripts (incl. Devanagari, Hangul, CJK), bridge, lyric videos, language tail, localized disclosure |
| `validate --app songlet --config-only` | passes (2 scripts, 12 storefronts, manifest complete, texts checked) |
| `flutter analyze` | No issues |
| `dart run arch_guard` | 0 violations (9 source roots) |
| Package tests (melos) | all pass except ui_kit's 41 goldens — the same 41 fail on a clean `main` (machine font drift, recorded before this work) |
| App tests | 610 passed, 83 failed — all goldens, the same 83 as on a clean `main` |
| `mock_server` tests | 89 passed (incl. schema 1 refusal) |
| `store_preview` vendored copy | `vendor --check` matches (template 2d03910); its 74 tests pass here |
| shellcheck | clean |
| products `go test ./cmd/songlet-samples` | ok (schema 2 resume, re-generation replace, migration with archive) |
| Markers | none (`TODO`/`FIXME`/`HACK`) in the changed files of the three repos |
| Credentials | `DISTRIBUTION_SECRET` appears in no tracked file, log, EDL, caption or config — only inside the compiled debug app under the git-ignored `build/` (the app reads its config as a compile-time define) |

## Completion criteria

| Criterion | Met by |
| --- | --- |
| One command makes Songlet's 2 × 12 iPhone previews passing three layers | `make store-preview` → 24 PASS |
| Cards, motion captions, ≥ 1 generated-image transition, footage ≥ threshold | EDLs: intro/outro cards, captions with fade-rise, bridge + image cards, 86 % ≥ 85 % |
| First 3 s understandable muted | narrative layer: on-screen text 0 → 4 s (claim, then the first caption) |
| studio_app via `new-app` renders a passing sample | template `dist/studio_app/en-US/A.mp4`, PASS |
| C archived, not rendered by default | `store_preview/songlet/archive/C/`; manifest validation rejects inactive scripts |
| No credentials in the repo or logs | scan above |
| No TODO/FIXME/HACK | grep above |
| README: new-app steps and time | `packages/store_preview/README.md` › New app |

## Deviations from the plan

1. **Copy keys.** Beyond `storePreviewCta` and `storePreviewDisclosure`, A's
   share scene got `storePreviewAShare` (13 languages); the intro claims
   reuse `storePreviewAEnd` / `storePreviewBMood`. Translations are mine,
   not reviewed by native speakers.
2. **Media migration.** `songlet-samples -migrate` carried the 87 schema 1
   entries over (84 active, 3 archived) without generating anything — no new
   paid calls.
3. **Script A** waits off camera for the region sheet to close (the
   rehearsal showed the intro dissolving into it).
4. **Listing export.** The first export used a wrong device directory
   (`iphone-6.9` instead of `previews/iphone-6.9`) and created 12 folders in
   `listings/`; they held only copies of the new renders and were removed,
   the config fixed and the tool hardened (template 2d03910). The listing's
   `previews/iphone-6.9` folders had already been emptied of the old A/B/C at
   05:31, before this run.

## Known limitations and follow-ups

- The composer on `feat/composer-three-states` is not on `main`; the scripts
  were rehearsed against `main`'s composer. After that merge, rehearse and
  re-render (`make store-preview`).
- `listings/` is outside git; `base.yaml`'s still frame `00:00:13:00` fits
  both previews.
- Old recordings of the retired tool remain in the git-ignored build folder
  (`build/store_preview/raw`, 20 GB; `build/store_preview/xcode`, 0.8 GB);
  the new takes live under `build/store_preview/songlet/`.
