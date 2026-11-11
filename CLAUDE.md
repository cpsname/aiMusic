# CLAUDE.md — Songlet (built on iap_template)

Authoritative guide for working in this repo. Keep it in sync with the real
architecture (it is the contract for future collaboration).

## What this is

**Songlet (小曲)** — an iOS app that writes an occasion song with Google Lyria 3
(product spec: `docs/design/songlet-prd.md`; prototypes `docs/ui/P01–P18.png` plus
the panels P02a/b/c and voice mode P03a, inventoried in `docs/ui/inventory.md`;
the music-video pages P19–P30 have no prototypes, ADR-0027).
Flow: create home (one grid of photo tiles — the server's list, the 16 templates
offline — and the three-state composer: free input typed, dictated on-device, or 1–10
photos; a picked tile's name / three words in place of the prompt; options under the
summary row — length / vocals / genre panels, own lyrics, the video switch; one primary
action; region sheet) → generating (progress, queue, lyric glimpse, cancel) → free 30 s preview → hard
paywall → ≈2 min full song (sections, shuffle, seek) → download page (MP3, WAV on
Premier behind the `wav_export` remote switch, lyrics, license PDF, Files / share sheet) / 9:16 share card. Library with
occasion filters, work detail, settings (profile: credits + account ID with copy; plan, restore, language),
about, festival landing.

It is built **on top of the iap_template** (this repo started as a copy of it):
infra_core, ui_kit, commerce_kit, app_config, media_kit and arch_guard are reused
unchanged in design; Songlet binds its own StoreKit bridge and backend into them
through provider overrides (`songletKitOverrides()`). Everything below the
"Songlet" section describes that reused infrastructure and still holds.

Decisions live in `docs/adr/` (0001–0039); read the index before changing a
convention it records.

## Songlet

### Where things are
```
pigeons/songlet_api.dart            # PRD §6.4 Pigeon interface, verbatim (make pigeon)
ios/Runner/SongletApi.g.swift       # generated host/flutter API
ios/Runner/Songlet/*.swift          # StoreKitService, AppAttestService, PhotoPickerService,
                                    #   AudioPlaybackService (+ seek), FileExportService,
                                    #   PromptPolisher (SystemLanguageModel), ShareCardComposer
                                    #   (+ saveToPhotos), SpeechService (on-device SFSpeechRecognizer),
                                    #   NotificationService
                                    #   (ETA local notifications), DebugLaunchReset (DEBUG)
ios/Runner/Songlet.storekit         # the PRD §8.1 products + Weekly Pro (scheme Run action)
packages/songlet_kit/               # business core: creation, speech, library (+ sync), store
                                    #   binding, mv (music videos: /v1/mv/*, local video library),
                                    #   playback, export, share (domain / data / application)
packages/ui_kit/lib/src/tokens/     # Songlet design tokens (colours, space, size, radius, motion, type)
packages/ui_kit/lib/src/components/ # Songlet components (pure presentation)
lib/ui/routing/                     # typed routes + go_router table + navigation helpers
lib/ui/{create,player,library,work,download,share,paywall,settings,festival,shell,common}/
lib/ui/mv/                          # music videos (PRD ch.15, ADR-0020–0028): entries P19, hub P20/P21,
                                    #   credits sheet P22, auto banner P23, making P24/P25, video P26/P27
mock_server/                        # dev mock of the Songlet backend (Dart, never shipped; `demo` profile for previews)
integration_test/                   # first-session integration test (make integration / make perf);
                                    #   store_preview_test.dart = the App Store preview recordings
                                    #   (store_preview_driver + Songlet's own steps)
packages/store_preview{,_driver}/   # the template's App Store preview tool, vendored (VENDOR.json
                                    #   stamp; change it in the template, then re-vendor)
store_preview/songlet/              # Songlet's previews (make store-preview): app.yaml, scripts/A,B,W,
                                    #   generation.yaml, media/manifest.json (schema 2, license ids),
                                    #   captions/ (exported from the ARBs), archive/C (ADR-0038),
                                    #   creatives/ (header + search results assets, ADR-0039),
                                    #   creative_review.yaml (people's real_ui verdicts)
docs/store/                         # apple-preview-rules.md (Apple, verbatim), preview-specs.md
                                    #   (Songlet's previews), preview-upload-checklist.md (generated),
                                    #   creative-assets-specs.md (header/search rules, vendored)
tool/diff_report/                   # prototype fidelity report (make diff-report)
docs/songlet/backend-contract.md    # wire contract v2 (client + mock); §7 = hand-off change set
docs/songlet/acceptance.md          # simulator acceptance run + StoreKit checklist
docs/perf/performance.md            # performance method + results
```

### Toolchain / identity
iOS **26.0** minimum (ADR-0001; the PRD says 27.0, waived by the product owner).
Bundle id `com.songlet.ios`. **No capabilities / entitlements** (2026-10-04: the
provisioning profile carries none; `Runner.entitlements` is an empty dict): no iCloud
(sync off, ADR-0013), no Push (ETA notifications are local), no App Groups (the
library lives in Application Support), no App Attest — `AppAttestService` answers
`{unsupported:true}` (also when `isSupported` is true but key generation fails), so
`/v1/attest` works only while the platform's `attest.mode` for the distribution is
`off` / `optional` (`required` → 40140). `UIBackgroundModes: audio`. Deep links
`songlet://app/<path>` (`FlutterDeepLinkingEnabled`). No third-party analytics, ads
or crash SDK (telemetry stays the template's no-op/console sink).

### Bridge semantics (fixed interface, PRD §6.4)
The Pigeon signatures are verbatim; what they cannot express is pinned in
`pigeons/songlet_api.dart` and mirrored in Swift:
- `playAudio(path, loop)`: new path → play from 0; same path + same loop → toggle
  pause/resume; same path + other loop → change looping; `''` → stop.
  `onPlaybackProgress` sends seconds, `-1` paused, `-2` ended (lock-screen commands
  change state natively, Dart learns only through this).
- `appAttestAssertion` returns JSON: `{key_id, attestation}` first, then
  `{key_id, assertion}`; `{unsupported:true}` on the simulator.
- There is **no finish call**: Swift finishes a purchase right after StoreKit
  verification (its JWS returns in the same reply) and finishes an update only after
  `onTransactionUpdated` was delivered to Dart; `NativeBridge` writes every JWS to a
  durable outbox inside the handler. `PigeonStoreClient.complete` is a no-op.
- What the fixed bridge cannot carry runs on named side channels, each with an ADR:
  `songlet/share_card` (video + save to Photos), `songlet/speech` (+ `/events`,
  ADR-0006), `songlet/playback` (seek, ADR-0017), `songlet/cloud_sync` (ADR-0013;
  no native handler while the app has no iCloud capability — Dart reads `unavailable`),
  `songlet/notifications` (+ `/events`, ADR-0025).

### How Songlet plugs into the template
- **Store**: `PigeonStoreClient` implements commerce_kit's `StoreClient`, so
  `IapPurchaseOrchestrator` / `IapBackgroundReconciler` / restore are reused.
  `SongletIapRepository` = static PRD §8.1 catalog + local orders + `verify` = an
  entitlement sync. `SongletWalletRepository` / `SongletAccountRepository` map
  `/v1/entitlements/sync` onto the wallet/account the template UI and pre-gates read.
  `songletEntitlementProvider` exposes `{tier, songsLeft, clipsLeft, resetAt}`; the
  ledger is server-side and the client only mirrors it (ADR-0011). After the paywall
  closes, `CreateFlow` re-reads the ledger (`invalidate(walletSnapshotProvider)`)
  whatever the sheet returned — purchases can land out of band.
- **Identity**: `AttestAuthRepository` implements `AuthRepository`: guest-register /
  refresh = App Attest exchange at `/v1/attest`; `app_account_token` = the Keychain
  device UUID (`abid` of the device-token JWT) = the StoreKit `appAccountToken`.
  `AuthController`, the auth interceptor and the HMAC signature chain are unchanged.
- **Errors**: PRD §6.5 codes travel as envelope `details.error_code` →
  `ApiError.errorCode` / `Failure.errorCode`; `SongletErrorCode` maps them,
  `failure_copy.dart` shows the table's copy first.
- **Backend contract v2** (`docs/songlet/backend-contract.md`, reviewed by the
  platform 2026-09-27): `queue_position` is never sent (queue banner from the
  status, ETA only); cancelling a finished job answers `49309` /
  `JOB_ALREADY_FINISHED` (a note, not an error — match the string); signed audio
  URLs live 1 h, objects 24 h (download on success, re-read the job before any
  later fetch); `wav_url` stays absent until the platform's WAV probe passes and
  the UI offers WAV only while `config.wav_export` is on (ADR-0010).
- **Music videos** (ADR-0020–0028, contract v1.1 §3.1): the client keeps no server
  state (`mv_id` = platform task id; `music_videos` table, works DB v4, only after
  the fact); `POST /v1/mv/estimate` saves the song (the hub prices all three levels
  on entry); progress is the platform's real completion, never a timer, published
  per video by `MvRunner` and followed by id (`mvProgressProvider`,
  `/mv/generate/:videoId`) — `MvController` is only the hub session and hands a
  submitted video off; submitting goes through `MvLauncher` for the hub and the
  automatic video alike. `QUOTA_EXHAUSTED` (`QuotaExhaustedDetails` → `QuotaGap`)
  is the `MvQuotaGap` state: the request is persisted (`MvIntent`), the P22 sheet
  buys the recommended pack through `IapPurchaseOrchestrator`, and the same
  `client_ref` is sent again (0/2/5 s; new ref only past 60 min). The length
  panel's toggle stores `Work.autoVideo`; `AutoVideoCoordinator` (started by
  `StartupGate`) makes the free lyric video once the song is ready, or Premier's
  chorus video after a cancellable 10 s countdown (never after a restart). ETA
  local notifications on `songlet/notifications` (ADR-0025); qualities from
  `config.mv.qualities` (ADR-0026); optional contract fields and gaps G1–G9 in
  backend-contract §7.1. The AI badge is burned in server-side and labelled again
  in the player.
- **Create home** (ADR-0032, contract 02 v2.1; supersedes ADR-0029's tiles and the P03
  form): **one grid** — `buildIdeas` = the server's `GET /v1/templates` `inspirations[]`
  by `sort` (the 16 templates are entries named by their template id; nothing merged on
  the client), or the 16 built-in templates while the list is not loaded / offline;
  `inspirationsProvider` waits for attestation (bearer-authed route), one per-session
  fetch (`RemoteTemplateCatalog`). Every tile is a photo: `cover_image_url` → the
  template's bundled photo → `assets/inspirations/<slug>.jpg` → the occasion's photo.
  Names / styles: `en`/`zh` from the server, other locales mapped by **slug** to ARB
  strings (`inspiration_labels.dart`), English fallback.
  **One pick, held by the draft** (`creationDraftProvider`: `inspirationSlug`, or
  `template` on the offline grid; `Idea.isPickedIn`): tap picks / tap again or the head's
  ✕ unpicks (`clearPick`); the tile's play button only plays `preview_audio_url`.
  **The composer in three states** (ADR-0033): **A** free input — the prompt field with
  "+" (photos) and the mic; **B** a pick — the card's head (photo, name, ✕) and its
  fields **in place of** the prompt: name (label by `requires_recipient`, never required),
  three words (the third closes the keyboard), and "Your words" only for an
  `input_required` card (`pickInputRequired`; `composer.hint` is its placeholder, never
  sent); **C** options over A or B — the summary row ("Preview · Vocals on · Indie Pop ›")
  unfolds them as the route `?options=1` (a `?panel=` implies it): Length / Vocals /
  Genre selectors (`ParamChip` + P02a–c panels), own lyrics (not for an instrumental),
  and "Also make a lyric video" under Standard only. Only what is shown is sent
  (`CreationDraft.forSubmit`: free input → description, photos, lyrics; a pick → name,
  three words, lyrics, the description only for `input_required`; a preview never carries
  the automatic video); the rest stays in the draft for the way back. A pick starts at a
  preview (ADR-0036); Vocals / Genre / the video take `default_vocals` (absent → the client
  default) / `suggested_genre` / `default_on_video` (else the occasion rule).
  **One primary action** (`composer.create`, ADR-0035): "Create preview", "Create {name}'s
  preview", "Create full song", with "· free / · 1 preview / · 1 song" only as the ledger
  shows it; preflight errors under the field holding the text (`Preflight.screen`).
  **Space** (ADR-0034, `ComposerBudget`): on phones the composer takes ≤ 35 % of the
  screen folded and ≤ 55 % unfolded, never leaving the grid less than its heading and a
  full row (`IdeaGridLayout`); with the keyboard up the header steps aside and a pick or
  the options fold the grid; on iPad the composer has its own pane; AX sizes scroll as one
  column. There is no form page. `/create/template/<id>` stays a deep link →
  `/create?template=<id>`: the home picks the tile, scrolls it into view, shows its fields
  (`custom` = free input); an offline template pick becomes the server entry of the same
  slug when the list lands. **Request** (contract 02 v2.1 §2, `GenerationRequest.fromDraft`): only
  `model, occasion (the scene's), inspiration (slug, never id), region, prompt, lyrics?,
  images?, client_ref` — the server drops any other field silently; `PromptBlock.build`
  puts the same slug on the first line, then `recipient, keywords, description (user
  text only), genre, vocals, lyric_language (always), festival, photos, note (≤ 600)`,
  each key once. A 40001 `details.inspiration` refetches the list. The slug is stored
  with the work (works DB v5). The mock implements the v2.1 rules over the product
  repo's 32 entries.
  **Credits** (ADR-0031): nothing is free — no client-side allowance gate or counter
  pill; the server answers `QUOTA_EXHAUSTED` and the paywall opens by its `offer`
  (plans with Weekly Pro `com.songlet.pro.weekly` preselected, or credit packs with the
  recommended one preselected and "See subscriptions" below); the first-week discount
  and its disclosure are read from StoreKit's introductory offer; every video, the lyric
  video included, starts after a cancellable countdown. A purchase that lands outside the
  paywall (granted server-side, approved later) still makes the refused song once the
  re-read ledger covers it. The ADR index is 0001–0039.
- **Region** (ADR-0005): the client never blocks by region — every template and all
  18 genres are open everywhere; presets only shape culture (lyric language,
  genres, festivals). A server `REGION_UNAVAILABLE` is presented with the
  `UPSTREAM_TIMEOUT` copy. `X-Storefront` + `X-Device-Region` still travel as
  request meta headers.
- **Uploads**: photos go through media_kit's presigned upload; `images[]` = bids.
- **Governance**: app_config maintenance / kill switch (paywall) / promo banner reused.
- **App Store previews** (ADR-0038, `docs/store/preview-specs.md`, the template's tool in
  `packages/store_preview`): two 25 s previews per storefront (A "a song for them", B "photos
  become a song and a video", B closing on the lyric-language pick; C archived), each an intro
  card, simulator footage (≥ 85 % of the timeline), an image bridge, the finished product at
  13 s and an end card with the purchase disclosure. `integration_test/store_preview_test.dart`
  registers Songlet's steps with `store_preview_driver`; `RunnerUITests/StorePreviewHelper.swift`
  serves the photo picker and the notification prompt. The mock's `demo` profile serves the
  manifest's Lyria songs and platform lyric videos (9 s jobs announcing the real 45 s ETA).
  Texts are the `storePreview*` ARB keys. Nothing records or renders without every manifest
  item and its license id; every output passes the spec, compliance and narrative layers.
  The shelves (template ADR-0015) put the localized header / search images on the default page
  and the three CPPs, the universal image elsewhere; `serves` (template ADR-0017) lets en-US,
  fr-FR, pt-BR and es-MX also serve en-GB/en-AU/en-CA, fr-CA, pt-PT and es-ES (previews and
  assets, nothing recorded for them).
- **Creative assets** (ADR-0039; template ADR-0009–0015, `docs/store/creative-assets-specs.md`,
  the flow in `docs/store/asset-library-playbook.zh-CN.md`):
  the product page header (21:9, + universal 16:9) and search results (3:2) images and muted
  loops (header 12 s, search 15 s) for the default page and ascpub's three custom product pages
  (`birthday`, `photo`, `wedding`), 127 assets over 12 storefronts, cut from A/B and the capture
  script W (the Wedding card). `make store-preview` writes `dist/songlet/assets-manifest.json`
  in ascpub's contract, read from the ascpub checkout and pinned (`app.yaml creatives.ascpub`;
  `$ASCPUB_ROOT` overrides); page slugs and bound ids come from ascpub's listing
  (`../songlet/listings/com.songlet.ios`), never invented here. `real_ui` is false until a
  person records a review (all 127 reviewed 2026-10-10). Texts are the `storeCreative*` ARB keys.
  Each definition's `shelf:` (template ADR-0015) declares what the store shows: the universal
  images uploaded to the Asset Library (default page + the three CPPs, 7 assets); the
  configuration check fails when the listing drifts. Shelving the localized assets changes what
  the store shows and is the product owner's call.
  `make asset-library` is the offline acceptance (assets, manifest, ascpub's listing checks).
- **DEV-only Keychain reset** (Settings → "Developer (DEV only)"): deletes the Keychain
  keys (device id + session tokens) and signs in as a new guest
  (`AuthController.deleteAccount`), after a confirmation dialog. Gated by the
  compile-time `devKeychainResetAvailable` = `kDebugMode && ENV define == 'dev'`
  (exactly `dev` — not `mock`, not an absent define): UI entry, provider
  (`devKeychainResetProvider` → null) and `DevKeychainReset.run()` all check it, so
  profile/release builds carry no reachable code. `make test` runs its test with and
  without `--dart-define=ENV=dev`.
- **Startup**: only preferences hold the splash; attestation/sync run behind the
  shell so the library works offline (PRD §6.5 NETWORK_OFFLINE).

### UI conventions (Songlet)
- **Routing** (ADR-0003): go_router `StatefulShellRoute` (Create · Library ·
  Settings); typed `AppRoute` classes in `lib/ui/routing/routes.dart`; panels, voice
  mode, the tile to pick (`?template=`), region sheet and paywall are routes. Pages built from path parameters are
  keyed by location (`_keyed`) — go_router keys pages by pattern. Starting a song
  `go`es to `/create/generate`, which redirects home when nothing is in flight.
- **Tokens & components** (ADR-0004): `SongletColors` / `SongletElevation` theme
  extensions (light + dark), `SongletSpace` (4-pt grid; compact gutter 16, create
  home 12, sheets 20), `SongletSize`, `SongletRadius`, `SongletMotion`, `SongletType`
  (iOS text styles, ADR-0019). No literals in pages.
- **iPhone-only launch** (ADR-0037): `ipadEnabled` (`lib/ui/common/device_family.dart`) is
  the one switch for the two-column layouts (`WindowClass.regular`), the iPad golden
  devices / tests and the iPad previews. It is off and must equal "Runner's
  TARGETED_DEVICE_FAMILY contains 2" (governance test). Flip both together.
- **Dynamic Type** (ADR-0018): chrome caps at xxxLarge; content reflows to AX5
  (`SongletType.isAccessibilitySize`).
- **Automation ids**: `TestId('<area>.<name>')` = widget-test key + iOS
  accessibility identifier (XCUITest).
- **Copy**: 13 ARBs in `lib/l10n/arb/`; genre display labels are localized, while
  protocol values keep the English Lyria vocabulary. See `docs/l10n/README.md`.

### Commands
```
cp config/mock.example.json config/mock.json   # once (ENV=mock → dev behaviour)
make mock                    # mock backend on :8787 (admin API: /__admin/*)
make run ENV=mock            # app on a simulator against the mock
make acceptance SIM=<udid>   # XCUITest acceptance run (docs/songlet/acceptance.md)
make integration SIM=<udid>  # first-session integration test on a simulator (debug)
make perf DEVICE=<id>        # same test, profile mode, on a device (docs/perf/performance.md)
make diff-report             # prototype fidelity report → docs/ui/diff-report.md
make store-preview           # App Store previews (12 × A/B) + creative assets + assets-manifest.json → dist/songlet (ARGS=…)
make pigeon                  # regenerate the bridge after editing pigeons/
make test                    # app + packages + mock_server tests
```

### Tests that guard the UI
`test/pages/page_goldens_test.dart` (40 page goldens: P01–P30 plus `P01-inspirations` / `P01-picked` / `P01-options` /
`P03-options` / `P01-keyboard` / `P03-keyboard`; P03 / P18 are the
home with a tile picked, at the design device or
the page's own device),
`test/pages/device_matrix_test.dart` (every page × the device matrix — 3 iPhones, plus 3 iPad
configurations only while `ipadEnabled` (ADR-0037) — × default and AX5 text,
plus the review goldens at 1×), `test/pages/composer_layout_test.dart` (the composer's
space rules, ADR-0034, measured per device × state × keyboard), `test/perf/leak_test.dart` (leak tracker over the main
flows), per-page state tests under `test/pages/`, component goldens (light · dark ·
RTL) in `packages/ui_kit/test/components/`. Goldens need SF Pro, New York and Apple
Color Emoji from macOS (`package:ui_kit/testing.dart`).

### Known limitations
- Headless StoreKit Testing is refused by the simulator for XCUITest-launched apps
  ("not installed for development"); the acceptance and integration runs grant
  purchases server-side, and the on-device purchase/restore is a manual Xcode-run
  checklist (docs/songlet/acceptance.md).
- On-device speech is implemented and builds, but is verified only on the simulator
  paths the tests cover; a signed device run is pending. iCloud sync (ADR-0013) is
  switched off: the native `CloudSyncService` was removed with the iCloud
  capability; the Dart side (`LibrarySyncController`) stays and reads the missing
  channel as `unavailable`.
- The first-frame ≤ 300 ms budget needs a profile/release device run
  (docs/perf/performance.md).
- The template's profile/upload demo screens remain in `lib/ui/me`, `lib/ui/upload`
  but are not routed.

---

# Template infrastructure (reused)

Backend HTTP contracts of the template's own monolith endpoints live in `docs/api/*`.

## Layout (app at root + pub workspace + melos)

**One repo = one app.** The app lives at the repo root; the reusable libraries are
workspace members under `packages/`. (No `apps/` collection — to start a new
project you copy this whole repo and rename it; you never accumulate N apps here.)

```
songlet/                 # = the app AND the pub workspace root
├── pubspec.yaml         # app deps + path deps to packages + workspace: + melos
├── melos.yaml           # packages: [".", packages/*]
├── lib/                 # the app: ui/ + providers + l10n. → all three packages
├── ios/ macos/ android/ linux/ web/ windows/   # platform dirs
├── config/              # dev/staging/prod.json (git-ignored secrets)
├── test/                # app widget tests
└── packages/
    ├── infra_core/   # network · crypto · error · config · storage · device. No business, no UI.
    ├── commerce_kit/ # auth + iap + wallet (domain/data/application). → infra_core
    ├── ui_kit/       # Aura visual primitives + tokens. Pure presentation; no providers.
    ├── arch_guard/   # dev-only: machine-enforces the layering below (Gate 6). Not shipped.
    ├── app_config/   # runtime governance: maintenance / kill-switch / remote config (/app/config). → infra_core
    ├── songlet_kit/  # Songlet business core (creation, library, store binding, playback, export, share). → infra_core, commerce_kit, media_kit
    └── media_kit/    # file upload: two-stage presigned R2 direct-upload (/uploads/sign → PUT → /uploads/finalize). → infra_core
```

### Dependency direction (one-way; reverse deps are forbidden)

`ui → app/providers → commerce_kit(application → domain ← data) → infra_core`
`ui → app/providers → app_config(application → domain ← data) → infra_core`
`ui → app/providers → media_kit(application → domain ← data) → infra_core`
`ui → ui_kit` · `* → infra_core`

Enforced by `path:` deps in each `pubspec.yaml` **and** by `arch_guard` (Gate 6),
which fails the build on any reverse/cross-layer import (see "Architecture
enforcement" below). For external reuse, switch member `path:` deps to
`git: { url, ref: <tag> }`.

## Layering & state (DDD + hand-written Riverpod)

- **domain** — pure Dart (models, repository interfaces, domain services). No Flutter, no Dio.
- **data** — DTOs (`fromJson`/`toJson`/`toDomain`), data sources, repository impls.
- **application** — Riverpod providers + `Notifier`/`AsyncNotifier`/`FutureProvider`.
- **No code generation.** Providers are written by hand (Riverpod 3.x).
- UI lives only under `lib/ui/` (the root app) and reuses `ui_kit`. No second theme system.
- No new providers in the UI layer — reuse `commerce_kit`'s application layer.

### Architecture enforcement (`arch_guard`, Gate 6)

`packages/arch_guard` is a dev-only, pure-Dart checker (built on the analyzer's
public parsing API) that turns the layering above into a build gate. Run `make arch`
/ `dart run arch_guard`; it also runs as a test (arch_guard's "real workspace has
zero violations") under Gate 2b. Rules: no reverse deps (`packages → studio_app`);
no `ui_kit` in business code (`infra_core`/`commerce_kit`); a pure `domain/`
(no Flutter UI / Dio / Riverpod / `data` / `application` imports); and **every**
package's application layer reaches `data/` **only** through `domain` interfaces —
concrete impls are bound solely in `*_providers.dart` (the composition root). Hence
`PendingOrderRepository` (domain) ← `PendingOrderStore` (data, bound in
`iap_providers.dart`), `AppConfigRepository` ← `AppConfigRepositoryImpl` (bound in
`app_config_providers.dart`), and the pure `JwtUtils` lives in `auth/domain/`, not `data/`.
A `presentation/` dir anywhere also fails the gate.

> **Why `arch_guard`, not `custom_lint`:** the spec named `custom_lint`, but its
> builder caps at `analyzer ^8` while the pinned toolchain (Flutter 3.44 / Dart
> 3.12) resolves `analyzer 12.x` — irreconcilable without downgrading Flutter
> (forbidden) or force-overriding `analyzer` (which breaks the analysis toolchain).
> `arch_guard` delivers exactly what DEEP_FOUNDATIONS_SPEC §3 asks for (build-red on
> a deliberate violation + rule fixtures) on an API that tracks the toolchain.
> Revisit `custom_lint` for in-IDE squiggles once it supports analyzer 12.

## Toolchain & platform constraints

- Flutter ≥ 3.44 (SwiftPM **on by default — never disable it**). Verified: Flutter 3.44.2 / Dart 3.12.2 / Xcode 26.5.
- iOS deployment target ≥ 15.0 (StoreKit 2). macOS ≥ 10.14.
- `device_info_plus` pinned `>=11.0.0 <12.4.0` per contract (holds `win32` at ^5.x;
  `package_info_plus` aligned to the 8.x line to match). Xcode 26.5 would allow
  relaxing this, but it is kept pinned as specified.

## Config & secrets

`EnvConfig` (dev/staging/prod) reads every value via `String.fromEnvironment` only —
**zero hardcoded secrets**. Inject at run/build time:

```
flutter run  --dart-define-from-file=config/dev.json
flutter build ios --dart-define-from-file=config/dev.json
```

`config/*.json` is git-ignored; copy `dev.example.json` → `dev.json`
and fill `DISTRIBUTION_SECRET` etc. Production `BASE_URL` must be the Songlet **BFF** on the
products domain (`https://genaistudio-products.showsapp.org/v1`, or
`http://localhost:9910/v1` for a local product-api) — the platform domain has none of
the Songlet routes. Production config and store builds enforce `SONGLET_RULES`
(platform hosts forbidden, `APP_CODE=songlet`, dotted `DISTRIBUTION_CODE`) in make
and the Xcode "Verify Build Config" phase. Debug builds using dev/staging/mock may
override the app identity and backend for debugging; required keys, environment
matching, and xcconfig consistency checks remain active. **One domain:** the
platform repo (genaistudio.showsapp.org) holds the capabilities every app
shares (identity, wallet and credits, IAP, tasks and models, storage, billing)
and no product logic; the products repo (genaistudio-products.showsapp.org)
holds each product's business and client-facing endpoints, which call the
platform. `BASE_URL` is the product backend. `GET /v1/app/config` goes to
`PLATFORM_BASE_URL` (optional, falls back to `BASE_URL`; `songletPlatformPaths`).
The product backend's distribution gate runs first: a `DISTRIBUTION_CODE` it
does not know is answered `40404` on every path, which reads like a missing
route. `PRODUCT_BASE_URL` in a config file is a reference value equal to
`BASE_URL`; the app does not read it. Keys: `ENV`, `BASE_URL`, `DISTRIBUTION_CODE`,
`DISTRIBUTION_SECRET`, `APP_CODE`, `BUNDLE_ID`, `IAP_CHANNEL`, plus the legal-link
fallbacks `TERMS_URL` / `PRIVACY_URL` (App Review 3.1.2): the paywall renders
server legal links from `/app/init` first, these compile-time URLs as backup, and
(terms only, Apple platforms) Apple's standard EULA as last resort — see
`effectiveLegalInfo` in `lib/ui/common/external_links.dart`. They are **optional in
dev, required by every store build** (`GUARD_SHIP`), and deliberately not part of
`EnvConfig.missingKeys` (a missing marketing URL must never block boot).

## Commands & gates

All commands run from the repo root.

```
flutter pub get                              # resolve the whole workspace
flutter analyze                              # Gate 1: app + all packages (root analyze descends into members)
flutter test                                 # Gate 2a: app tests
dart run melos exec --ignore=songlet_mock_server -- flutter test   # Gate 2b: each Flutter package's tests
(cd mock_server && dart test)                # the mock backend's own (pure Dart) tests
flutter build ios --config-only --dart-define-from-file=config/dev.json   # Gate 3
dart run arch_guard                          # Gate 6: architecture-boundary check (0 reverse/cross-layer imports)
```

**`make` is the config-aware entrypoint** (raw commands above still work). The portable
`scripts/` toolkit stays config-agnostic; the root `Makefile` injects `config/<env>.json`
via `--dart-define-from-file` for run **and** store builds, and fails fast if that file is
missing **or ill-filled** — every config-consuming target first runs
`scripts/check_config.sh` (all required keys non-empty, no `REPLACE_*` placeholders,
`ENV` field matches the target env; store builds additionally require an **https,
non-localhost** `BASE_URL` **and** the `SHIP_KEYS` legal-link fallbacks
`TERMS_URL`/`PRIVACY_URL`), so you never run/ship with an empty or dev `BASE_URL`,
and a store package can never lack functional Terms/Privacy links. The key lists
live in the Makefile (`REQUIRED_KEYS` + store-only `SHIP_KEYS`); the checker
itself is generic:

```
make run [DEVICE=<id>] [ENV=dev]   # flutter run via scripts/dev.sh  ← config/dev.json
make logcat [ARGS=...]             # Android system-layer logs via scripts/logcat.sh
make ipa | aab | apk               # store builds                    ← config/prod.json
make xcconfig                      # prep iOS Generated.xcconfig as prod for an Xcode Archive
make ios                           # Gate 3 (config-only, no-codesign)
make macos                         # macOS config-only build (gate)  ← config/dev.json
make macos-app                     # macOS release .app              ← config/prod.json
make macos-xcconfig                # prep macOS Flutter-Generated.xcconfig as prod for an Xcode Archive
make arch                          # Gate 6 (architecture-boundary check)
make shellcheck                    # lint scripts/ toolkit (auto-skips when not installed; part of gates)
make analyze | test | l10n | get | clean
```

`make ipa`/`aab`/`apk` default `ENV=prod` → need `config/prod.json` (copy `dev.example.json`).
Store **signing/upload** (certs, provisioning, export options, Play signing) and **product
identity** (bundle id / applicationId / display name) are deliberately **per-product
release-time setup, not template concerns** — the full step list lives in
`docs/RELEASE_CHECKLIST.md`; the Makefile only injects config + runs `flutter build`.

**CI**: `.github/workflows/gates.yml` runs the exact local entrypoint (`make gates`) on a
macOS runner (goldens are renderer-dependent; iOS config-only build needs macOS) with a
synthesized `config/dev.json` (dummy secret — CI holds no real secrets).

**Archiving in Xcode (not via `make ipa`):** the `--dart-define`s are **not** read from
`config/*.json` by Xcode — `flutter` decodes them into `ios/Flutter/Generated.xcconfig`'s
`DART_DEFINES`, which the `xcode_backend.sh build` Run Script consumes. That file reflects the
**last `flutter` command**, so a raw Xcode *Archive* after `make run` would ship **dev/localhost**
(and an empty `BASE_URL` → "No host specified in URI …" if it was never generated). Run
**`make xcconfig`** (regenerates it as prod, release) immediately before *Product → Archive*; do
not run `make run` in between. Both xcconfig targets **verify after generating**: they decode the
generated `DART_DEFINES` (base64 CSV) and diff it key-by-key against `config/prod.json`
(`check_config.sh --verify-xcconfig`, secret values redacted), failing on a stale/mismatched
file and printing the `ENV`/`BASE_URL` that will actually ship. `make ipa` sidesteps this
entirely (it injects + archives in one go).

**That discipline is now enforced, not just documented.** The Runner target's **first** build
phase — *Verify Build Config*, in both `ios/` and `macos/Runner.xcodeproj` — runs
`make -s verify-xcode-config` (→ `scripts/verify_xcode_config.sh`) on **every** Xcode build,
including Archive. It fails the build when the xcconfig carries no/empty dart-defines, when a
`Release` build carries anything other than `ENV=prod`, and when the xcconfig has gone stale
against its `config/<ENV>.json`. Keep the phase first in `buildPhases` (before the Flutter
`Run Script`) so it fires before Dart is compiled; `test/governance/build_config_gate_test.dart`
asserts both projects still reference it.

**Last line of defence, at runtime:** `StartupController.start()` checks `EnvConfig.isComplete`
*before* any request and settles on `ConfigFailure(missingKeys: …)` when a build still slipped
through. It renders as "App configuration problem" with **no retry button** (`Failure.isRetryable`
is false — a retry cannot inject a compile-time define) and, in debug, prints the missing keys and
the command that fixes them. Never make `ConfigFailure` retryable, and never let a startup path
issue a request before that check.

**macOS (App Sandbox).** The macOS Runner is sandboxed, so outbound HTTP needs
`com.apple.security.network.client` — declared in **both** `macos/Runner/Release.entitlements`
(prod) and `DebugProfile.entitlements` (dev); without it every `apiDio`/`authDio` call
(`/app/init`, auth, IAP verify, wallet) fails. The Xcode-Archive caveat above applies to macOS too:
the dart-defines live in `macos/Flutter/ephemeral/Flutter-Generated.xcconfig`; run **`make macos-xcconfig`**
(prod) right before *Product → Archive*. `make ios`/`make macos` are the config-only build gates.

Lints are never relaxed to pass (`analysis_options.yaml` is shared via `include`).
No to-do or fix-me markers, `UnimplementedError`, placeholders or `// mock` in deliverables
(the repo-wide marker grep is part of the delivery audit).

## API contract notes (resolved from docs/api)

- App signature header is **`X-App-Signature`** (overview §5 + all OpenAPI specs);
  the `X-Signature` in identity.md prose is a typo.
- Signing: `HMAC_SHA256(secret, timestamp + nonce + canonicalJson(body))`, hex
  lowercase, no separators; empty body → literal `{}`; keys sorted recursively.
- Most business errors return **HTTP 200** with a non-zero `code` in the envelope.
- Order `expires_at` may be seconds or millis → defensive parse (`<1e12` = s, else ms).
- Verify retry/back-off codes: `40912 / 50000 / 50301 / 50302 / 40016` + network
  timeout; `40011` (transaction already used) → treat as complete + refresh wallet.

## Subsystems

### Network (infra_core)
Two Dio instances:
- `apiDio` (authed business calls): **Device → Auth → Signature → Clock-Sync → Retry → Envelope → Logging**.
- `authDio` (token-issuing + `/app/init` + the auth interceptor's replay channel): same chain **minus Auth**.
- Both chains start with `EndpointRoutingInterceptor`: a path claimed by an
  `EndpointRoute` (`endpointRoutesProvider`, default none) goes to that route's
  host, everything else to `BASE_URL`; retries and re-signed replays keep the
  routed host. Songlet routes `songletPlatformPaths` to `PLATFORM_BASE_URL`.

The contract's five named stages keep their relative order; request **signing** +
**clock-sync** are dedicated interceptors layered in (header order doesn't affect the
body signature).

**Clock-skew → corrected signing (DF①).** HMAC signs over `timestamp + nonce + body`,
so a skewed device clock fails every signed request — invisible offline, only erupts
in the field. `ClockOffsetService` (in-process, **never persisted**) holds the
device→server offset; `SignatureInterceptor` signs with `clockOffset.now()` (corrected),
not `DateTime.now()`. `ClockSyncInterceptor` learns the offset (RTT/2-compensated) from
the **`X-Server-Time`** response header on every response — read from the live wire only,
never from the cache-first `/app/init` body, so it can never feed a stale offset — and on
a cold-start time-window rejection (`40111`/`40112`) re-dispatches the request **once** so
it re-signs with the now-known offset (a one-shot flag prevents loops). Offset recomputes
each session; if the header is absent it stays zero (safe degrade to local time).
`AuthInterceptor` (a `QueuedInterceptor`) detects `40102`/`40106` from the envelope
`code` in **both** `onResponse` (HTTP 200 + code) and `onError` (HTTP 401 + code); on
`40102` it single-flight refreshes and replays the original request through `authDio`
(no auth interceptor → no recursion); on `40106` it force-logs-out. A per-request
"handled" flag prevents the round-tripped error from being processed twice.

### Errors (infra_core)
`ApiError` (sealed: Auth/Signature/Validation/InsufficientCredits/RateLimit/Conflict/
ContentFilter/NotFound/Permission/Server) ← `EnvelopeInterceptor`. `ErrorHandler.handle`
maps any throwable → `Failure` (sealed: Auth(requiresForceLogout)/Payment/RateLimit/
Validation/ContentFilter/Signature/Server/Network/Store/Cache). `NetworkFailure`
carries a `kind` (`NetworkFailureKind: offline / timeout / unknown`) derived from the
`DioExceptionType` — **copy selection only, never retry policy**; a
`DioExceptionType.unknown` wrapping a `SocketException` maps to `Network(offline)`,
not `Server` (Dio funnels unclassifiable transport errors there). Only backend-envelope
failures carry a user-facing `message` (already localized via `X-Language`); transport
/ diagnostic failures carry an **empty** message and the UI resolves localized copy.
Because callers keep only the returned `Failure` (bootstrap's hooks see only uncaught
errors), `handle` records an unrecognized throwable to the telemetry sink (non-fatal,
with the caller's stack when passed) **before** genericizing — the diagnostic is never
lost.

**Failure presentation (app + ui_kit).** `lib/ui/common/failure_copy.dart` is the
single source of `Failure` → localized title/message/icon (connectivity-aware via
`NetworkFailure.kind`) so every surface reads identically. Two surfaces by scenario:
a page with no content (startup failure, a screen's first-load `AsyncValue.error`)
renders `ErrorRetryView` (app adapter mapping a `Failure` to copy for ui_kit's
pure-string `StatusView` glass panel; `fullScreen` = stretched vs content-sized,
`retrying` = button spinner); an in-place operation failure (e.g. a purchase) goes
through the ui_kit **Message** banner stack (`messageControllerProvider` +
`failureMessage`, tagged loading→success/error transitions) and never covers existing
page state. The UI never auto-retries — bounded auto-retry lives only in
`RetryInterceptor` / `IapVerifier`; retry buttons re-run the page's own
`ref.invalidate(...)` / `start()`. `GlobalErrorPresenter` (SnackBar) is `@Deprecated`
— kept solely as an infra-only fallback.

### Observability (infra_core) [DF②]
Vendor-agnostic `TelemetrySink` (`logEvent / recordError / breadcrumb / setUser`)
with `NoopTelemetrySink` (default, production-safe) + `ConsoleTelemetrySink` (sample
adapter). **Always** wrapped in `RedactingTelemetrySink`, which scrubs PII (JWT /
bearer / email / 32+ hex secrets / E.164 phone, plus wholesale masking of sensitive
keys) before anything reaches the vendor — dashed `request_id`s survive for
correlation. `bootstrap()` (the `main` entry) wraps startup in `runZonedGuarded` and
installs `FlutterError.onError` (non-fatal) + `PlatformDispatcher.onError` (fatal),
funnelling every uncaught error through `ErrorHandler` → `Failure` into the sink.
`LoggingInterceptor` emits a compact masked breadcrumb (`method · path · status ·
latency_ms · request_id`) in **all** envs (verbose console only in dev/staging); the
`EnvelopeInterceptor` stashes `request_id` in `RequestOptions.extra` so it survives
unwrap. The `IapPurchaseOrchestrator` emits the funnel `paywall_view → purchase_start
→ native_cancel / deferred / verify_retry / purchase_success / purchase_fail(stage[,
diagnostic])` (+ `already_subscribed`) — `diagnostic` carries the raw plugin error /
verify status, telemetry-only (the `Failure` message stays empty for the UI). The app binds the sink once and shares it via
`telemetrySinkProvider`; swap in a real vendor adapter there for production.

### Storage migration (infra_core) [DF⑦]
`KeyValueStore` wraps SharedPreferences (corrupt JSON → null, isolated). A schema
version is stamped under `storage.schema_version`; `StorageMigrator` runs ordered
`StorageMigration` steps `[→ version]` at startup (in `StartupController`, **before**
any store reads its data) so persisted shapes (pending orders, product cache,
settings) evolve safely across upgrades. It never downgrades, stamps the version
after each step (resumable), and a failed run is caught + reported — never blocking
boot. Reads degrade defensively: corrupt/unparseable records are isolated, not fatal
(`PendingOrderStore` skips a bad record, keeps the rest). Baseline is
`kStorageSchemaVersion = 1` with no steps; append a `StorageMigration` (via
`storageMigrationsProvider`) and bump the constant when a persisted shape changes.

### Privacy manifest (iOS) [DF④]
`ios/Runner/PrivacyInfo.xcprivacy` is wired into the Runner target's Resources phase
(ships at `Payload/Runner.app/PrivacyInfo.xcprivacy`). It declares Required-Reason API
use with Apple's SDK identifiers + reason codes: UserDefaults `CA92.1`
(shared_preferences), FileTimestamp `C617.1`, DiskSpace `E174.1`, SystemBootTime
`35F9.1` (DeviceBootClock's `KERN_BOOTTIME`). `NSPrivacyTracking=false` and
`NSPrivacyCollectedDataTypes=[]` (telemetry is no-op by default — declared explicitly,
since omitting the key can itself fail review). First-party plugins ship their own
`.xcprivacy`; Apple merges them. Keep this in sync when adding native code/plugins.
**Account deletion** (App Store requires it for account systems) needs the backend
delete endpoint — see `BACKEND_COORDINATION.md` §8.

### AppConfig (app_config) — runtime governance [/app/config]
A bounded context **separate** from the `app/init` startup snapshot (the backend
forbids mixing them; zero field overlap). `GET /app/config` returns `maintenance` /
`kill_switches` / `config`; it is App-signed (no JWT) over **authDio**, a GET with no
body (signs over `{}`), and **fail-open** (always `code:0`; any failure → safe
defaults). `AppConfigController` (`Notifier<AppConfig>`) starts at
`AppConfig.safeDefault`, fetches on first read + on app **resume** (throttled to ≥60s
via DF①'s `ClockOffsetService`), and **never** throws or enters an error state — so it
can never block boot. It is **not** persisted (unlike `AppInitCache`): governance is
runtime-mutable + fail-open, so a cold start offline correctly defaults to "not in
maintenance". UI: `MaintenanceGate` (reactive, between the force-update gate and the
shell — order: **force-update > maintenance**) shows a maintenance page (server
message + `resume_at` countdown on the corrected clock); `isFeatureKilledProvider(code)`
hides/disables entries (paywall gated by `AppFeatureCodes.iapPurchase`); remote
`config` drives flags (e.g. a `promo_text` banner). Telemetry: `app_config_refreshed`
/ `maintenance_shown`.

### Uploads (media_kit) — two-stage presigned R2 direct-upload
A bounded context mirroring the backend creation BC's **generic file upload**. The
contract is two-stage (overview.md §upload + creation.md §1142+ + endpoint-inventory):
`POST /v1/uploads/sign` → client **PUT to R2** → `POST /v1/uploads/finalize`. Both
sign/finalize go over **apiDio** (JWT + App signature + clock-sync + retry + envelope
+ telemetry — the full infra_core chain); the bytes go **directly to R2** over a
**bare Dio** (`r2PutDioProvider`, **no interceptors** — the BFF's auth/signature/envelope
would break R2's presigned-URL signature, and R2 returns no envelope). `UploadService`
(stateless, concurrency-safe) orchestrates `hash → policy pre-check → sign → [dedup
short-circuit] → PUT(onSendProgress) → finalize`, reporting `UploadProgress` phases. The
client computes the **required** `file_hash` (SHA-256, 64 lowercase hex — mandatory
since 2026-06-20; the presigned channel never sees the bytes) via `Sha256FileHasher`
(`crypto`), and pre-validates MIME + 50 MiB against `UploadPolicy` (mirrors backend
`upload_policy.go`; server still authoritative — finalize HEADs R2 to confirm real size
== declared, else `40038`). On a server **dedup hit** (`dedup_hit=true`, empty `put_url`)
it skips the PUT + finalize and references the existing asset. Upload-specific codes in
`UploadErrorCodes` (40034 mime / 40035 size / 40037 hash / 40038 size-mismatch / 40420
bid / 40430 no-R2-object / 40922 already-finalized / 50100 local-mode). The **library**
stays picker-free and UI-free; the **sample app** ships the reference consumer:
`lib/ui/upload/upload_demo_page.dart` (third shell tab) drives `uploadServiceProvider`
with progress phases, cancellation, the dedup badge and standard failure surfaces. Its
picker is `image_picker` **gallery-only** (PHPicker / Photo Picker — no runtime
permission, no `NS*UsageDescription`); macOS needs the
`com.apple.security.files.user-selected.read-only` entitlement (declared in both
entitlement files).

### Auth (commerce_kit)
`AuthController` is the `Notifier<AuthPhase>` **and** the `AuthGateway`. It does all
token-lifecycle calls over `authDio` only, so `apiDio → authGateway(AuthController) →
authDio` has no cycle.

`ensureAuthenticated()` implements the identity contract's **three-lines-of-defence** —
never re-register on a mere token expiry (that mints a new guest if `device_id` drifted):
- **① local reuse** — decode the access-token JWT `exp` (`JwtUtils.isExpired`, **60 s** skew);
  valid → use it, **no network**.
- **② refresh** — expired access + a refresh token that isn't **provably** expired
  (`JwtUtils.isProvablyExpired`: opaque/non-JWT tokens fall through and are still tried) →
  single-flight `/auth/refresh` (the `_refreshing` completer guards `40106` concurrent-reuse);
  the refresh response carries `account_type`/`guest_id` so a guest stays a guest without `/me`.
- **③ idempotent register** — refresh failed/skipped → `/auth/guest-register` keyed by the
  Keychain `device_id` (idempotent: `is_new_user=false`). `device_id` lives in
  `SecureTokenStore` (survives reinstall) and is preserved by `clearTokens()`; losing it is the
  **only unrecoverable exit** → `AuthAuthenticated.isNewUser` surfaces `is_new_user=true`.

**Account deletion (guest lifecycle, App Review 5.1.1(v)).** `deleteAccount()` destroys
the tokens **and** the Keychain `device_id` (the only flow allowed to — see
`SecureTokenStore.deleteDeviceId`), resets the `DeviceInfoService` cache +
`deviceProfileProvider` (a stale cache would silently resurrect the dead id on the next
request), then immediately re-registers a fresh guest on a newly minted id. Because
guest registration is idempotent **per device id**, the old guest becomes permanently
unreachable by construction — that is the client-side deletion for a guest-only
product. The Profile entry is **guest-only**: a signed-in account keeps sign-out until
the backend delete endpoint exists (`BACKEND_COORDINATION.md` §8 — its call slots in at
the top of `deleteAccount()`), since a local wipe would masquerade as deletion while
the server account survives. The action is retryable end-to-end (wipe idempotent,
registration re-attempted); the confirm dialog states that an App Store subscription
is **not** cancelled by deletion and can be re-linked via Restore purchases.

`currentAccountProvider` (separate, `apiDio`) fetches `/me` with graceful degradation.
The app must include `commerceKitOverrides()` in its root `ProviderScope` to bind the
gateway.

### Wallet (commerce_kit)
`walletSnapshotProvider` (FutureProvider) → `walletBalanceProvider` (int),
`activeWalletFeaturesProvider` (granted + unexpired), `hasFeatureProvider(code)`.
Refresh by `ref.invalidate(walletSnapshotProvider)` (startup, IAP verify success, resume).

### IAP (commerce_kit) — two transaction sources
Subscriptions require separating the **user purchase session** from **app-level background
reconciliation** (renewal / Ask-to-Buy / revocation / re-delivery), per the StoreKit 2 spec.

- `IapPurchaseOrchestrator` (`Notifier<IapPurchaseState>`) — foreground session, 5-min native
  timeout. States: `idle → creatingOrder → orderCreated → [expiryCheck] → awaitingNative →
  verifying(1s→2s→4s) → completed`, branches `cancelled` / `deferred` (Ask-to-Buy/SCA) /
  `alreadySubscribed` (pre-gate) / `failed(stage)`, plus a `restoring → restored(count)` flow. It
  "claims" its product's next event from the reconciler rather than subscribing itself.
  - **Account binding (`appAccountToken` / `push_token`).** Each purchase carries the account
    **BID** (a UUID — `appAccountTokenProvider`, from the session's `abid` claim): attached to the
    native StoreKit 2 purchase as `appAccountToken` (the plugin maps `PurchaseParam.applicationUserName`
    → SK2 `appAccountToken`; **a non-UUID is silently dropped natively**, so guests use their UUID
    `abid`, never `guest_id`) **and** sent on `POST /iap/orders` as `push_token`. Apple echoes
    `appAccountToken` on the transaction + **every S2S notification**, so the backend maps it straight
    to the account instead of reverse-looking-up by `originalTransactionId` (reduced, not removed —
    pre-existing transactions have no token, so the reverse-lookup stays as fallback). Needs the
    backend to read `appAccountToken` from the webhook + accept `push_token` — see `BACKEND_COORDINATION.md`.
- **Restore** (`restorePurchases()`) is **user-initiated only — never auto-triggered** (no startup
  / resume / unsolicited-event path). It runs the **same create-order → verify(`transaction_id`)
  kernel** as a purchase: it opens a reconciler restore window (`beginRestore`/`endRestore`),
  calls `_store.restore()`, drains the `.restored` events that arrive just after (a short
  `restoreDrainWindowProvider`, since the native per-entitlement callbacks and the method reply are
  on separate channels), then per restored transaction — **strictly in sequence**, since
  `createOrder` has no retry/back-off and a concurrent same-account burst trips 40912/rate
  limits — resolves the catalog `productCode` by
  `storeProductId` → `createOrder` → `IapVerifier.verify` (`transaction_id` is the binding key;
  `40011` already-used-by-another-order = idempotent success) → `finish`. Outcome `IapRestored(N)`
  (0 → "nothing to restore"); a catalog-unresolved entitlement is finished as a fallback; a
  per-transaction verify failure leaves it unfinished for a later retry. Entitlement stays
  server-truth, so a final `refreshEntitlement()` surfaces the grant. Funnel: `restore_start →
  restore_success(count) / restore_fail`.
- `IapBackgroundReconciler` — app-level, started at startup, **no timeout**. Owns the single
  `purchaseStream` subscription: hands claimed events to the orchestrator and reconciles the
  rest (re-delivered order → verify by `orderNo` → finish; renewal/family → finish + refresh). An
  **unsolicited** `.restored` event (one outside an explicit restore window) is **never turned into
  an order** — it falls through to the same safe finish + refresh, so restore-via-order can only
  ever be triggered by the user's explicit call. Refreshes the server entitlement on startup and on
  **app foreground** (covers Settings-cancel + webhook-driven revocation, which emit no StoreKit
  event). Prunes stale orders.
- `IapVerifier` — the shared verify→finish kernel used by both.
- `StartupController.start()`: parallel `/app/init` + `ensureAuthenticated` → force-update gate →
  ready → prefetch `/me`+`/wallet` → activate the reconciler + prune.
- `appInitProvider` is **cache-first** and the **single source** for startup + the paywall, so
  `/app/init` is hit **at most once per boot session** (not the previous twice-per-launch).
  `AppInitCache` persists the response (products + legal + update) keyed by the device **boot
  instant** (`DeviceBootClock`, via the `infra_core/device` method channel → `KERN_BOOTTIME` on
  iOS/macOS, `now − elapsedRealtime` on Android) and the **app version**: a cache hit needs the
  same boot session (±5 s clock-jitter tolerance) and same version, so it refreshes on a **device
  reboot** or **app upgrade**. If the boot instant is undetectable (handler not registered /
  unsupported platform) the cache never hits → safe degrade to fetch-every-launch. *Trade-off:
  since `/app/init` is one endpoint, force-update is evaluated once per boot session; the authed
  endpoints' `40304/40305/40306` remain an in-session hard gate.*
- Product list pull (ported from `iap_flow_kit`, the reference impl): `storeClientProvider`
  queries `InAppPurchase.queryProductDetails`; `ProductDetailExtractor` reads the SK1/SK2/Play
  wrapper types for the **subscription period + App Store Connect offers** (introductory / free
  trial / promotional, `data/product_detail_extractor.dart`); `ProductMergeService` joins the
  backend catalog with those store details **by `storeProductId`, in catalog order**. The store is
  authoritative — a catalog product the store can't resolve goes to `unavailableProductIdsProvider`
  and is **dropped** (an unpurchasable product is never shown with a faked backend price). Products
  come from **App Store Connect via the plugin** (real device + sandbox); a bare simulator resolves
  none, so the paywall is correctly empty there. `storeCatalogQueryProvider` caches the merged list
  (`ProductCache`, 24 h TTL + currency-mismatch detection) and **serves stale cache on a query
  failure** (offline resilience); with no cache the error surfaces for retry. `storeProductsProvider`
  = the merged list; the paywall renders each product's store period + offer badges.
  `legalInfoProvider` exposes the saved privacy/terms/subscription URLs.
  `subscriptionEntitlementProvider` is the **server-authoritative** gate: grace period still
  grants access; billing-retry prompts to update payment.

IAP invariants (do not weaken):
- `PendingOrderStore` saved **before** the native purchase. **Finishing the StoreKit transaction
  and confirming the entitlement are decoupled** (Apple's model: `finish` = "I recorded this
  transaction", not "the grant is confirmed"). In the **foreground** orchestrator, verify
  failure leaves the pending order for the reconciler. In the **background reconciler**, a
  re-delivered pending order runs verify as a best-effort fast-path, then applies a
  **type-routed finish policy** (`IapBackgroundReconciler._reconcile`): on a confirmed grant →
  finish + remove. On a non-grant (verify threw / `grant_failed`), **finish anyway for
  restorable products** (subscriptions / non-consumables — `Product.isRestorable`): the
  transaction MUST be acknowledged so StoreKit stops re-delivering it (Apple review + renewal /
  family / interrupted-purchase delivery depend on it), and it can never be lost — the
  entitlement stays in StoreKit's `currentEntitlements` (user-restore re-claims it) and the
  server grants it out-of-band via the Apple S2S webhook. For **consumables / unknown kinds** —
  which have neither net (no renewal webhook, not in `currentEntitlements`) — the transaction is
  **left unfinished** so the next re-delivery re-verifies (their only recovery path), bounded by
  the 24h `pruneStalePendingOrders`. A per-product in-flight guard (`_reconciling`) prevents a
  batched/duplicate re-delivery from spawning concurrent verify+finish.
- Verify back-off on `40912/50000/50301/50302/40016/40010` + network timeout; `40011` (already
  used) → completed; order expiry → fail before native.
- SK2 user-cancel is **invisible** on the locked plugin (`in_app_purchase_storekit` 0.4.10):
  `buyNonConsumable` discards `SK2Product.purchase()`'s `.userCancelled` and returns true, and
  Apple delivers no `Transaction` — so no exception and no `purchaseStream` event ever arrive
  (verified against the pinned source; flutter/flutter#160659, #178292). The orchestrator detects
  the silence with a short window (`sk2CancelDetectorWindowProvider`, default 3 s) after `buy()`
  returns: claim unsettled within it → `cancelled`, and the pending order is **retained** — a
  misjudged slow success is then reconciled live by `IapBackgroundReconciler` (verify → finish →
  refresh), so no money is lost. An explicit **SK1/Play stream-cancel removes** the pending order;
  the `PlatformException` catch in `InAppPurchaseStoreClient` is kept as a forward-compat defensive
  fallback (unreachable on 0.4.10). Deferred (`pending`) → `deferred` (loading released, no finish,
  pending kept). The detector timer is cancelled the instant the claim settles (no dangling timer).
- Entitlement is **server-truth** (`/me` + `/wallet`), never local transactions; an already-
  entitled subscription is routed to "manage", never a duplicate order.
- App killed mid-flow → pending persists; `in_app_purchase` re-delivers on launch and the
  reconciler verifies + finishes (resume). Renewals/revocations are server-driven (Apple S2S
  webhook) + picked up by the foreground/startup entitlement refresh. Success →
  `ref.invalidate(walletSnapshotProvider)`.

### UI motion + RTL (ui_kit) [DF⑤/⑥]
`MotionPolicy.reduceMotion(context)` honours `MediaQuery.disableAnimations` (with a
`MotionPolicyOverride` escape hatch); the `RepeatingMotion` mixin drives the perpetual
Aura/skeleton controllers — repeating only while motion is allowed **and** foregrounded
(`AppLifecycleListener`), else resting on a static frame (reduce-motion + battery).
`Typewriter` reveals in full under reduce-motion. Layout is direction-safe:
`EdgeInsetsDirectional` / `AlignmentDirectional` (no hardcoded left/right — enforced by
`arch_guard`'s `no_hardcoded_directional` rule over `lib/ui/**` + `ui_kit/lib/**`);
`GradientText` passes the ambient `textDirection` to `createShader` so directional
gradients resolve + mirror. Profile + Paywall + the network-error `StatusView` ship
**ltr + rtl golden snapshots**
(`test/goldens/`, reduce-motion for determinism; the RTL variant forces
`Directionality.rtl` via `pumpApp(textDirection:)` — locale-independent, so RTL stays
covered even though the template ships only en/zh).

### App (studio_app)
- `main.dart` → `bootstrap(() => runApp(ProviderScope(retry: (_, _) => null, overrides:
  [telemetrySinkProvider.overrideWithValue(…), ...commerceKitOverrides()]) → StudioApp)))`.
  The zone-guard installs the global error handlers (see Observability). Riverpod's
  default provider **auto-retry is disabled** so error states are
  terminal (explicit error + retry screens); transient HTTP is already retried in the
  network layer. Widget tests do the same in `pumpApp()`.
- `MaterialApp(home: StartupGate(child: StudioShell()))` — no route table. `StartupGate`
  shows splash / blocking force-update / `ErrorRetryView` (retry re-runs `start()`);
  `StudioShell` is an adaptive nav over
  an `AuroraBackground` (Profile + Paywall + Upload demo).
- Profile (`lib/ui/me/`): `currentAccountProvider` + `walletSnapshotProvider` /
  `activeWalletFeaturesProvider`, three-state `AsyncValue` (skeleton / data /
  `ErrorRetryView`),
  guest sign-in sheet (`AuthController.login`). The subscription card carries a
  **persistent manage-subscription entry** (`manageSubscriptionsUrl()`) whenever the
  entitlement is active/grace **or in billing retry** (managing is the fix there) —
  gated on `subscriptionEntitlementProvider`, i.e. server truth.
- Paywall (`lib/ui/paywall/`): products from `storeProductsProvider` (dynamic; no hardcoded
  names/prices), token-shimmer skeleton, product-load failure = `ErrorRetryView`; buy →
  `IapPurchaseOrchestrator`, whose states drive **one tagged Message** through the stack
  (loading → success + wallet refresh / error / deferred / already-subscribed → manage
  link; cancel dismisses), plus restore. No new providers — reuses commerce_kit.
  **Subscription compliance (3.1.2) is structural**: an auto-renewal disclosure renders
  whenever any listed product `isSubscription`, and the legal links go through
  `effectiveLegalInfo` (server → `TERMS_URL`/`PRIVACY_URL` defines → Apple std EULA),
  so a backend that omits legal URLs can no longer produce a paywall without
  functional Terms/Privacy links.
- i18n: `lib/l10n/arb/{en,zh}` → `flutter gen-l10n` → `lib/l10n/generated/` (**build
  output: git-ignored and excluded from analysis** — `make analyze`/`make test` and CI
  regenerate it first, so a fresh clone self-heals). The template ships only the **en + zh baseline**; on copy for a new
  app, batch-translate the shipped languages from that baseline and add their ARB. RTL
  is handled structurally (DF⑤), so an RTL language needs only its ARB. Backend errors
  are already localized via `X-Language`; the app supplies copy only for store/UI-only strings.
- Widget tests use `pumpApp()` (single-frame `pump`, never `pumpAndSettle` — Aura/skeletons
  animate forever); `Override` imported from `package:riverpod/misc.dart`.

## Live validation status

- Dev backend reachable at `http://localhost:9999/v1`; a signed `/app/init` probe returns a
  structured envelope (`40304 distribution not found` for the doc example code), confirming
  the **`X-App-Signature`** header name + envelope shape live. The signing is byte-exact vs
  `openssl`, so the backend will accept it once the real distribution config is supplied.
- Pending for a full live happy-path run: real `DISTRIBUTION_CODE` / `DISTRIBUTION_SECRET` /
  `APP_CODE` / `BUNDLE_ID` / `IAP_CHANNEL` in `config/dev.json`. Live StoreKit purchases need
  a device + App Store Connect sandbox (covered here by fakes in tests).
