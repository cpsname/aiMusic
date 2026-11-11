# ADR-0038 — Two previews per storefront, made by the template's reusable tool; script C archived
Status: Accepted
Date: 2026-10-06
Supersedes the three-script pipeline of `tools/store_preview` (2026-10-05); amends
ADR-0037's preview paragraph (the iPad slot lives in the new tool).

## Context
The first App Store previews (three per storefront, 36 files) were faithful
screen recordings with captions: they showed operation, not a pitch. No
brand, no claim before the first tap, nothing but footage. The pipeline was
also Songlet-only code (`tools/store_preview`, bash orchestration), so the
next app on the template would have had to fork it.

Apple allows overlays, transitions, graphics, an end frame and a single
soundtrack, while "previews may only use video screen captures of the app
itself" (2.3.4) and features behind a purchase must be disclosed.

## Decision
- **The tool is the template's** (`iap_template/packages/store_preview` and
  `store_preview_driver`, template ADR-0001–0008), vendored here with a drift
  stamp (`packages/store_preview/VENDOR.json`, checked by the package's test).
  Songlet is its first consumer: `store_preview/songlet/` holds app.yaml,
  the scripts, generation.yaml, the media manifest (schema 2) and the
  exported captions; `integration_test/store_preview_test.dart` registers
  Songlet's own steps; `RunnerUITests/StorePreviewHelper.swift` is the tool's
  system-UI helper. `tools/store_preview` is removed.
- **Two previews, 25 s each, on the input → wait → result → share
  template**: A "a song for them" and B "photos become a song and a video".
  Each opens on an intro card (icon + claim over the storefront's licensed
  photo), cuts through the footage, dissolves through a photo before the
  finished product (the poster frame, 13 s), and closes on an end card
  (icon, name, call to action, "Requires a subscription or credits").
  Footage is 86 % of each timeline.
- **Script C is archived** (`store_preview/songlet/archive/C/`: the script,
  its three Lyria songs with their license ids, its copy, its generation
  spec). Its claim — lyrics in your language — closes B: the country and
  lyric language picked, filmed before the rest of B's take.
- Copy: `storePreviewAShare`, `storePreviewCta`, `storePreviewDisclosure`
  added in the 13 ARBs; `storePreviewCLanguage` became
  `storePreviewBLanguage`; the other C keys moved to the archive.

## Consequences
- 24 files instead of 36; each carries its EDL, so the footage share, card
  lengths, transitions, texts and licensed media are checked on the output.
- A change to the tool is made in the template and re-vendored; editing the
  copy here fails the package's test.
- The products repo's `cmd/songlet-samples` writes manifest schema 2 for
  scripts A and B; its `-migrate` carried the 87 schema 1 entries over (84
  active, 3 archived) without generating anything.
