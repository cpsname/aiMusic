# Architecture decision records

One decision per file, numbered, never renumbered. A superseded record stays in
place with `Status: Superseded by ADR-NNNN`. Template:

```
# ADR-NNNN — <decision>
Status: Accepted | Superseded by ADR-NNNN
Date: YYYY-MM-DD
## Context
## Decision
## Consequences
```

Priority order used to settle conflicts (delivery spec): extensibility >
testability > maintainability > 3–5-year evolution > availability > performance.

| ADR | Decision |
| --- | --- |
| [0001](0001-ios-deployment-target.md) | iOS 26.0 deployment target, iOS 26.5 SDK |
| [0002](0002-stack-lock-deviations.md) | Keep hand-written Riverpod, immutable models, sqflite, `Failure` funnel instead of codegen / freezed / drift / `Result` |
| [0003](0003-go-router-typed-routes.md) | go_router with hand-written typed routes and `songlet://` deep links |
| [0004](0004-design-tokens-in-ui-kit.md) | Design tokens, light + dark, and components live in `ui_kit` |
| [0005](0005-no-client-region-blocking.md) | No client region blocking; `REGION_UNAVAILABLE` uses the upstream-timeout copy |
| [0006](0006-speech-channel.md) | On-device speech on a method/event channel beside the fixed Pigeon bridge |
| [0007](0007-prototype-diff-method.md) | How screens are compared with the prototypes |
| [0008](0008-prototype-vs-prd-conflicts.md) | Where prototypes and the PRD disagree, the PRD wins |
| [0009](0009-missing-designs.md) | Settings (P14) and "temporarily unavailable" (P17) built from the design system |
| [0010](0010-add-to-music-and-share.md) | "Add to Music" uses the system share sheet; WAV via `wav_url` |
| [0011](0011-server-side-ledger.md) | Purchases are accounted server-side; contract handed to the platform repo |
| [0012](0012-job-contract-extensions.md) | Job progress, queue position, lyric glimpse and cancel |
| [0013](0013-icloud-sync.md) | Opt-in iCloud library sync through CloudKit private database — **suspended 2026-10-04** (no iCloud capability) |
| [0014](0014-assets-and-app-icon.md) | Template art, cover art and app icon sources |
| [0015](0015-composer-semantics.md) | Composer card semantics (mode chip, Preview/Full, parameters) — **superseded by ADR-0033** |
| [0016](0016-directory-mapping.md) | Where the spec's directories live in this workspace |
| [0017](0017-playback-seek-channel.md) | Seek and section navigation on a channel beside the Pigeon bridge |
| [0018](0018-dynamic-type-policy.md) | Dynamic Type: chrome caps at xxxLarge, content reflows to AX5 |
| [0019](0019-prototype-scale.md) | iOS text sizes over the prototypes' ≈0.72× drawing scale |
| [0020](0020-music-video.md) | Music videos: stateless `mv_id`, estimate saves the song, real progress only, credit gap → pack purchase + retry, badge burned in server-side |
| [0021](0021-mv-progress-by-video.md) | Music-video progress follows the video (runner bus), the hub session hands a submitted video off |
| [0022](0022-automatic-video.md) | The automatic video after a song: lyric at once, Premier chorus after a cancellable countdown |
| [0023](0023-mv-credit-gap-purchase.md) | A credit gap buys the pack in a sheet and sends the same request (persisted intent, bounded retries) |
| [0024](0024-lyric-video-rendered-server-side.md) | The lyric video stays rendered server-side |
| [0025](0025-mv-background-notifications.md) | Background waiting: ETA local notification, polling in the foreground |
| [0026](0026-mv-capabilities-remote.md) | Video qualities from the remote config (`config.mv.qualities`) |
| [0027](0027-mv-pages-without-prototypes.md) | P19–P30 built from PRD ch.15 without prototypes |
| [0028](0028-mv-schema-v4.md) | Works database v4: video request columns, `works.auto_video` |
| [0029](0029-inspirations.md) | The create home's Inspiration grid: templates and inspirations as one kind of tile (merged, 3-tier cover), one `/templates` fetch, previews by absolute URL, local copy keyed by the English text |
| [0030](0030-inspiration-composer.md) | Inspiration composer (contract 02 v2.1): a picked card becomes a tag above the prompt field, hint and selector defaults from the server, `inspiration:` in the prompt block, `input_required` gates send |
| [0031](0031-credit-paywall.md) | Everything costs credits: no client-side allowance gate, the paywall opens by `QUOTA_EXHAUSTED.offer` (plans with Weekly Pro preselected, or packs), Weekly Pro with the App Store's first-week offer read from StoreKit, free copy removed |
| [0032](0032-single-grid-composer.md) | One grid (the server list by `sort`, photo tiles), one pick held by the draft, the composer unfolds the form fields under the prompt, one send; `/create/template/<id>` deep-links to the pick; contract 02 v2.1 request (scene slug as `inspiration`, facts in the `prompt` block, the card's hint only a placeholder) |
| [0033](0033-three-state-composer.md) | The composer in three states — free input, a picked card in place of the prompt, options under the summary row (`?options=1`) — one primary action, only what is shown is sent; supersedes ADR-0015 |
| [0034](0034-composer-space-and-keyboard.md) | The composer's space: ≤ 35 % folded / 55 % unfolded on phones, a full row of the grid kept, the keyboard folds the grid for a pick or the options, its own pane on iPad |
| [0035](0035-primary-action-and-cost.md) | The primary action's words by length and name; its cost ("free", "1 preview", "1 song") only as the ledger shows it; a purchase outside the sheet still makes the song |
| [0036](0036-pick-starts-at-preview.md) | A picked card starts at a preview (PRD §3.1); `default_model` kept as data |
| [0037](0037-iphone-only-launch.md) | Launch iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), decide on iPad after the first wave's data; one switch `ipadEnabled` gates the two-column layouts, the iPad golden devices and tests, and the iPad App Store previews (kept, not deleted); a governance test ties it to the project file |
| [0038](0038-two-previews-on-the-template-tool.md) | Two 25 s App Store previews per storefront (A, B; C archived, its language claim closes B) with intro and end cards, an image bridge and the purchase disclosure, made by the template's reusable `store_preview` tool (vendored, drift-stamped); `tools/store_preview` removed |
| [0039](0039-creative-assets.md) | Creative assets (product page header, search results; iOS 27+) for the default page and the three custom product pages ascpub holds (birthday, photo, wedding), from the previews' footage plus the capture script W; one `make store-preview` writes the assets manifest in ascpub's contract |
