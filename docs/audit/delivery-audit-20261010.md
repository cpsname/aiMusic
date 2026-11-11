# Delivery audit — App Store creative assets (header, search results, CPP) · 2026-10-10

Scope: extend the template's `store_preview` tool with the product page header
and search results creative assets (Apple, 2026-10-05; iOS 27 and later),
three custom product page sets, local validation, and an assets manifest in
ascpub's contract. Production and validation only — no App Store Connect
call, no credential.

## Where the work is

| Repo | Branch | Commits |
| --- | --- | --- |
| `iap_template` (the tool's source) | `feat/store-preview-creative` | `42a127e` baseline of the found WIP · `f2bb77b` steps A–F · `1e8e2f0` ADR-0009–0014, README, CI · `d7ef193` fix: shown item that is also the backdrop · `d8b0e4c` studio_app (step H) |
| `songlet` (worktree `songlet-store-preview`) | `feat/creative-assets` | `30acde7` re-vendored tool at `d7ef193`, Songlet's creatives, W, ADR-0039, runbook, skill |
| `songlet` main checkout (untracked) | — | `listings/com.songlet.ios/assets.yaml` + `cpp/{birthday,photo,wedding}.yaml` (ascpub's listing; 2.1 GB of listing media, never committed) |

Nothing was pushed or merged.

## Completion criteria

| Criterion | Evidence | Result |
| --- | --- | --- |
| One command makes 12 storefronts' header / search images and videos and 3 CPP sets | `make store-preview` 09:09:47 → 10:11:04 (61 min), `EXIT=0`: `✓ 24 previews pass …`, `✓ 127 creative assets pass the spec, compliance and narrative layers` | ✅ |
| Every asset passes spec, compliance and narrative | 127 / 127 rows `PASS` (header videos 12.00 s 30.00 fps, loop seam 43–48 dB; search videos 15.00 s; images 3840×1646, 3840×2560, 5244×2950) | ✅ |
| `assets-manifest.json` passes ascpub's schema | the tool (ascpub `fc973cb`, schema 1, `7f117bc7…`): `127 entries match the contract … and their files`; ajv 2020 with ascpub's own `node_modules`: `valid: true` | ✅ |
| studio_app produces a passing set | `render --app studio_app --scripts A,S --locales all` (5 min): 2 previews + 6 creative assets `PASS`; `dist/studio_app/assets-manifest.json: 6 entries match the contract`; no tool change | ✅ |
| Each header / search video understandable muted in its first 2 s | mechanical: phrase on screen 0 → end, first scene ≥ 2 s, poster on finished footage (all 24 videos pass); `dist/songlet/creative/sheets/*.first2s.png` checked visually for header and search videos in all 12 languages | ✅ mechanically; a person's sign-off is open (below) |
| No TODO / FIXME / HACK, no credential values | `git grep -nE "\b(TODO\|FIXME\|HACK)\b"` over both repos' changed areas: none. Key-pattern grep: one hit, `packages/store_preview/test/validate_test.dart:164` — the secret scanner's own fake-key fixture (pre-existing, required to test the scanner) | ✅ |
| ascpub reads the output with zero errors | `ascpub assets validate -b com.songlet.ios` (from ascpub source, full video decode): **0 errors**, 1 warning (`规格目录使用随包快照(2026-10-08)` — ascpub's own offline-catalog notice) | ✅ |

Manifest composition: 52 `header_image`, 51 `search_image`, 12 `header_video`,
12 `search_video`; targets: `app_store_version` 50,
`custom_product_page:birthday|photo|wedding` 26 each; every entry carries at
least one license id; `real_ui` 0 of 127 (no review yet — by design).

## What changed in the tool (template)

- **Contract (ADR-0010)**: schema read from the ascpub checkout
  (`creatives.ascpub.root`, `$ASCPUB_ROOT`), held to a SHA-256 pin; the
  copied `contracts/` directory and the `contract --from` import were
  removed; `contract --app` reports commit, pin, listing pages and runs
  ascpub's example.
- **Listing (ADR-0009)**: targets must name pages ascpub's listing declares;
  every id a page binds must be made for that page and slot; deep links are
  never read or written.
- **Authorization (ADR-0014)**: per field, the primary scene's item first;
  scenes declare `shows:`; `derived_from` = the primary scene's recording;
  EDL keeps one entry per item and use.
- **Validation**: App Store Connect locales (`asc_locales`), opening scene ≥
  hook (2 s), EDL placements/targets present, every shown item's role mapped;
  first-2-seconds sheets per video; layouts tightenable per app only.
- **Specs (ADR-0013)**: header 10–30 s, search 15–30 s, PNG headers, exact
  pixels for fixed sizes, integer ratio for ranges; loop rhythms 8/12
  required, `search_card` adds 15 s.
- **Docs**: `docs/store/creative-assets-specs.md` re-fetched 2026-10-10 (the
  iOS 27 statement is in Apple's best-practices page — the draft wrongly said
  no source states it); every rule has source + review date.
- **Tests**: 112 store_preview tests (was 80): ascpub's example and its 16
  negatives on this side, pin / override, listing agreement, tightening,
  locales, opening, durations 9.9 / 10.0 / 14.9 / 15.0 / 30.0 / 30.5 s,
  29.97 fps, 60 fps, alpha, disguised formats, rotation, truncated files,
  screenshot majority, stale reviews; the fixture backdrop is now
  deterministic (lavfi `gradients` is random unless seeded).

## Gates run

| Gate | Result |
| --- | --- |
| template `packages/store_preview` `flutter test` | 112 passed |
| template `store_preview_driver` tests | 4 passed |
| template `make analyze` · `dart run arch_guard` | no issues · 0 violations |
| template `make test` (app) | 6 golden failures (`profile`, `upload`, `network_error` × ltr/rtl, 2–6 px) — **pre-existing**: identical pixel counts on `d7ef193`, before this work's ARB change |
| Songlet `vendor --check` · `make analyze` · `arch_guard` | ✓ · no issues · 0 violations |
| Songlet vendored `store_preview` tests | 112 passed |
| Songlet `make test` (app) | 808 passed, 5 skipped, 2 failed (`golden_test.dart` profile ltr/rtl, 0.41 %) — **pre-existing**: same failure on a clean worktree at `a9641e4`; `make test` stops there, so later package stages did not run in that invocation |

## Deviations from the confirmed plan

- Decision 6 recommended committing `listings/` — the bundle holds 2.1 GB of
  listing media, so only `assets.yaml` and `cpp/*.yaml` were added there,
  untracked; store_preview reaches it as `../songlet/listings/com.songlet.ios`.
  `assets.yaml` is ascpub's example with its manifest path corrected
  (`../../../songlet-store-preview/…`; the example has one `../` too many).
  The three `cpp/*.yaml` are byte-identical to ascpub's examples.
- studio_app got a capture script `S` (its preview scenes are too short for
  a 12 s loop) instead of reusing A's footage; A is unchanged.
- Two additions not in the plan's file list: the scene field `shows:` and
  `primary_media` in the creative EDL (both serve decision 4).

## Open items

Closed on 2026-10-10, after the owner's confirmation:

1. **`real_ui` review** — the owner (lintion) approved the contact sheets and
   the `*.first2s.png` sheets; all 17 definitions recorded with
   `review --real-ui true` (`store_preview/songlet/creative_review.yaml`).
   `manifest`: `127 entries match the contract (ascpub 753bca4 …); real_ui
   from the review: 127 of 127`. ascpub `assets validate`: 0 errors.
2. **Muted first 2 s sign-off** — part of the same approval.
3. **ascpub example path** — fixed in ASOShip `753bca4`; the listing's
   `assets.yaml` is now byte-identical to the example.
4. **`ascpub assets push --dry-run -b com.songlet.ios`** — with the project's
   ASC key: live spec catalog `没有发现任何问题`; plan = 7 `reserve_upload`
   (the 7 ids the listing binds: `header.universal.tool` and the six
   `cpp.<slug>.header|search`); `dry-run 完成(零远端写入)`, exit 0.
5. **Merges** — both branches merged into `main` locally; nothing pushed.

Still open:

- **CI** — the template's `gates.yml` checks out `vars.ASCPUB_REPOSITORY`;
  ASOShip has no git remote, so set a reachable repository (and
  `ASCPUB_TOKEN` if private) before CI can run the contract tests.
- **Pre-existing golden drift** in both repos (above) — re-baseline is a
  separate decision.
