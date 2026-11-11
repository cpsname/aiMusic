# store_preview — App Store previews and creative assets for any app on this template

`store-preview` turns an app's real simulator footage into App Store previews
that sell: an intro card with the claim, motion captions, image transitions,
one soundtrack, an end card with the call to action and the purchase
disclosure — and checks every output against Apple's specification, the
compliance rules and the narrative rules before it can be uploaded.

From the same footage it makes the **creative assets** of the product page
header (21:9) and the search results (3:2), plus the universal 16:9 image —
images and muted looping videos, per storefront — for the default product
page (the shelf), each custom product page (a counter for one audience) and
each product page optimization treatment (the shelf's A/B test). It writes
`dist/<app>/assets-manifest.json` (the warehouse: everything the Asset
Library receives) in the contract of ascpub, the tool that uploads them, and
writes each page's shelf into ascpub's listing. It makes and checks; it
never calls App Store Connect and holds no credential. The operating manual
and cross-project guide (business model, setup, configuration, CPP / PPO,
review and publishing, troubleshooting, a complete worked case):
[docs/store/asset-library-playbook.zh-CN.md](../../docs/store/asset-library-playbook.zh-CN.md).

Everything app-specific is configuration under `store_preview/<app>/`; the
next app needs no change to the tool. Songlet (the first app built on this
template) is its first consumer.

- Apple's rules, verbatim, and the tool's thresholds:
  [docs/store/apple-preview-rules.md](../../docs/store/apple-preview-rules.md)
- Creative assets — Apple's text, verbatim, and every rule with its source
  and review date:
  [docs/store/creative-assets-specs.md](../../docs/store/creative-assets-specs.md)
- Decisions: template ADR-0001 – 0015 (`docs/adr/`; creative assets 0009 – 0015)

## Commands

```sh
dart run store_preview <command> [options]          # or: make store-preview ARGS="<command> …"
```

| Command | Does |
| --- | --- |
| `render --app <app> [--scripts A,B] [--locales all\|a,b] [--devices iphone]` | checks the configuration, records every take, composes, validates, writes the upload checklist |
| `record …` / `compose …` | the recording half / the post-production half (from recorded takes) |
| `validate --app <app> [--config-only] [--only previews\|creatives]` | the configuration, then the three layers on every rendered preview and creative asset, and the assets manifest re-measured against its files |
| `creatives --app <app> [--creatives a,b] [--locales …]` | renders, validates and writes the manifest for the creative assets only, from the recorded takes |
| `manifest --app <app>` | writes `dist/<app>/assets-manifest.json` (every creative asset; ascpub's contract) |
| `review --app <app> [--asset <id> --real-ui true\|false --reviewer <name> [--note …]]` | a person records what an asset shows (the manifest's `real_ui`); without `--asset`: every asset's review status |
| `listing --app <app> [--write] [--dir]` | the shelves the definitions declare (each page's header and search results, by locale) against ascpub's listing; `--write` puts them in (those blocks and `assets.yaml` › `manifest`, nothing else); `--dir` prints the listing's directory |
| `contract --app <app>` | the assets-manifest contract the app follows: read from ascpub, its pin, ascpub's listing pages |
| `captions --app <app>` | exports the on-screen texts from the app's ARBs to `store_preview/<app>/captions/` |
| `checklist --app <app>` | `dist/<app>/upload-checklist.md` (+ `publish.checklist_doc`) |
| `export --app <app>` | copies the previews into a store-listing tree, removing retired ones |
| `new-app <name>` | scaffolds `store_preview/<name>/` from the repo (bundle id, icon, ARBs) |
| `new-creatives --app <app> [--ascpub <dir>] [--cpp a,b] [--ppo slug:Treatment,…] [--listing <dir>]` | scaffolds the creative assets: `app.yaml` › `creatives`, the shelf, a counter per custom product page, a variant per treatment, the phrases in every ARB |
| `vendor --from <template>` / `vendor --check` | copies the tool into an app repo with a drift stamp / verifies it |
| `doctor --app <app>` | checks the tools and summarizes the configuration |

Outputs: `dist/<app>/<storefront>/<script>.mp4`, `<script>.poster.png`,
`<script>.captions.srt` (every text on screen), `<script>.edl.json` (what is
footage and what is not, every transition, text and licensed item), and
`dist/<app>/upload-checklist.md`. Creative assets:
`dist/<app>/creative/<storefront|universal>/<id>.png|.mp4` (+ `.poster.png`,
`.edl.json`), contact sheets for the review in `dist/<app>/creative/sheets/`
(`<asset>.png`; a video's muted opening in `<asset>.first2s.png`), and
`dist/<app>/assets-manifest.json`. A render removes the outputs of an asset no
definition makes any more. `make asset-library APP=<app>` is the local
acceptance of the lot, ascpub's offline checks included.

Requirements: macOS with Xcode (simulators, `swiftc`, `plutil`), Flutter, and a
Homebrew ffmpeg (AudioToolbox AAC `aac_at`; libx264). Credentials never go
into the configuration: the app's `--dart-define-from-file` and the backend
read their own files and environment; validation scans the configuration and
every output for anything that looks like a key.

## How a preview is made

1. **Configuration check** — every script against its narrative template and
   the compliance thresholds, every text in every storefront, the media
   manifest (every item present, probed and licensed), the brand files, the
   driver entry. Nothing is filmed if any of it fails.
2. **Recording** — per slot and storefront, a dedicated simulator is erased and
   set to the storefront's language and region, its photo library filled with
   the app's licensed images; the backend (if any) is reset; the screen is
   recorded while the app's `integration_test` runs the compiled plan and
   marks every scene's edges; an XCUITest helper serves system UI (photo
   picker, notification prompt).
3. **Post-production** — the scenes are cut and retimed into a timeline clip
   (held frames under cards and bridges); text layers are typeset with
   CoreText; ffmpeg composites the cards, bridges and captions, mixes the
   soundtrack and encodes to Apple's targets; the poster frame, captions and
   EDL are written.
4. **Validation** — spec (ffprobe against the specification), compliance (from
   the EDL), narrative (hook, readability, poster frame, imagery).

## Configuration (`store_preview/<app>/`)

| File | Holds |
| --- | --- |
| `app.yaml` | the app (bundle id, brand, purchase disclosure, caption rules, storefronts, devices, driver, backend, prelude, `on_use`, simulator, publishing, rules) |
| `scripts/<id>.yaml` | one preview each: template, rhythm, poster frame, required media, setup, the timeline (cards, scenes, bridges), captions |
| `media/manifest.json` | the media the previews show, each with its license (schema 2) |
| `captions/<storefront>.json` | the texts, exported from the ARBs (generated) |
| `templates/<id>.yaml` | optional: the app's own narrative templates |
| `creatives/<id>.yaml` | creative assets for some targets (default product page, a custom product page, a PPO treatment) |
| `creative_review.yaml` | people's reviews of what each creative asset shows (written by `review`) |

### Creative assets

`app.yaml`:

```yaml
creatives:
  ascpub:                                   # the publisher; it owns the contract and the pages
    root: ../../Tools/ASOShip               # its checkout, repo-relative ($ASCPUB_ROOT overrides)
    schema_sha256: 7f117bc7…                # the assets-manifest.schema.json this app follows
    listing: listings/com.example.app       # its listing bundle (repo-relative): assets.yaml, cpp/<slug>.yaml, ppo/<slug>.yaml
  authorization: {song: interaction_id, lyric_video: mv_id, photo: generation_id}  # media role → license field
  layouts: {"21:9": {safe: {width: 0.66}}}  # optional: only tighter than defaults/creative.yaml
```

`creatives/cpp-birthday.yaml`:

```yaml
id: cpp-birthday
title: Custom product page "Birthday Songs"
targets: ["custom_product_page:birthday"]   # the slug = ascpub's cpp/birthday.yaml
universal_from: en-US                       # the take a universal asset shows
backdrop: {role: photo, script: B, index: 0}
text: storeCreativeBirthday                 # ARB key, prefix storeCreative
tags: ["cpp:birthday"]
shelf:                                      # what the page shows (ADR-0015): written by `listing --write`
  header: {default: cpp.birthday.header, locales: "cpp.birthday.header.{storefront}"}
slots:
  - placements: [product_page_header]
    spec: header_21x9                       # defaults/creative.yaml specs
    assets:
      - {id: cpp.birthday.header, type: image, frame: {script: A, scene: player, at: 2.0}}             # universal, no text
      - {id: "cpp.birthday.header.{storefront}", type: image, frame: {script: A, scene: player, at: 2.0}}
  - placements: [app_store_search_results]
    spec: search_3x2
    assets:
      - id: "search.{storefront}.video"
        type: video
        template: search_card               # loop template
        rhythm: 15
        poster_at: 9.0                      # inside a finished scene
        scenes:
          - {beat: input, script: A, scene: name, from: -2.6, duration: 2.6}
          - {beat: result, script: A, scene: player, duration: 7.5}
```

Pages, their deep links and keywords are ascpub's: every target must name a
page its listing declares (`ascpub assets init --cpp <slug> --ppo <slug>`
creates them), and every id a page binds must be made for that page and
slot. `shelf:` declares what the definition's pages show per slot — a
universal `default` and/or `locales` (an id with `{storefront}`, one per
localization the app ships media for — each storefront and each it `serves`
— that the page localizes: a CPP's or PPO's `locales`, every one for the
default page); `listing --write` writes it into each page, and the check fails
while the listing differs. Without `shelf:` the bindings are written by hand.
A PPO treatment is a definition of its own (`targets:
["ppo:<slug>:<treatment>"]`) whose shelf changes the experiment's one
variable; the original is the default page's shelf. A scene may declare `shows: [{role, index}]` — licensed items
on screen — so the assets cut from it license them. The manifest's
`authorization` names, per field, the primary scene's item; the EDL (its
`source.evidence`) lists every one. `real_ui` is `false` until a person reviews the rendered files and runs
`review`; the receipt binds the definition and each asset/EDL/poster hash.
Legacy definition-only receipts cannot attest to current rendered bytes.

### `app.yaml`

```yaml
app: myapp                          # = the directory name
bundle_id: com.example.myapp        # the built app's (checked)
brand:
  name: MyApp                       # as on the App Store (not localized)
  icon: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
  palette: {primary: "#1F6FEB", on_primary: "#FFFFFF", scrim: "#000000"}
  font: {family: system, weight: semibold}   # or {family: <name>, file: assets/fonts/X.ttf}
  cta_key: storePreviewCta          # ARB key, end card
  disclosure_key: storePreviewDisclosure     # ARB key, required while requires_purchase
requires_purchase: true
captions:
  arb_dir: lib/l10n/arb
  arb_file: app_{locale}.arb        # {locale} = ui_locale with "_"
  prefix: storePreview
  banned_words: [otherapp]          # added to the built-in "free"/price/date rules
  # max_chars 28, max_chars_cjk 14, max_disclosure_chars 60/30, min_seconds 1.5,
  # max_cps 17 / max_cps_cjk 9, plate_opacity {min: 0.45, max: 0.78}, radius 0.5
devices: [iphone]                   # ipad only when the app ships for iPad
slots: {iphone: {caption_size: 44, caption_bottom: 168}}   # optional overrides
driver:
  type: flutter_integration_test
  target: integration_test/store_preview_test.dart
  dart_defines_file: config/dev.json
  ready: {key: home}                # a widget that appears once the app is up
  helper: {}                        # system UI (photo picker, notification prompt)
  timeout_seconds: 1500
backend:                            # optional: a local backend the takes run against
  start: dart run mock/server.dart --port {port} --manifest {manifest}
  health: http://localhost:{port}/health
  admin: http://localhost:{port}/admin/
  port: 8787
  before_take: [{post: reset}, {post: media, body: {manifest: "{manifest}"}}]
prelude: [{do: waitFor, key: home}] # off camera, once per take
on_use: [{do: admin, path: next, body: {script: "{use.script}", locale: "{use.locale}"}}]
simulator:
  library: {role: photo, script: B} # these manifest images go into the photo library
  keyboard_tips_seen: true
  appearance: light
  time: "9:41"
storefronts:
  - {id: en-US, ui_locale: en, sim_language: en, sim_locale: en_US,
     aso_name: "MyApp: …", aso_subtitle: "…", vars: {region: US},
     serves: [en-GB, en-AU, en-CA]} # optional: localizations of the same language that show this
                                    # storefront's previews and assets (ADR-0017); nothing is recorded for them
publish:
  listings_dir: listings/com.example.myapp/locales
  device_dirs: {iphone: iphone-6.9}
  shared_poster_at: 13              # one still frame for every preview (fastlane deliver)
  upload_order: [A, B]
  checklist_doc: docs/store/preview-upload-checklist.md
rules:                              # only tighter than the defaults
  min_footage_ratio: 0.85
  max_card_seconds: 2.0
  max_cards_total: 4.0
  require_image_transition: true
```

### A script

```yaml
id: A
title: A song with their name in it
template: input_wait_result_share   # templates/ in this package, or the app's
rhythm: 25                          # 15 | 22 | 25
poster_at: 13                       # inside a finished scene
ends_on_system_ui: false            # true: filmed after the app's other scripts
soundtrack: follow                  # or none (a silent track)
requires:
  - {role: song, vars: [recipient, chorus_index]}
  - {role: photo, count: 4}
setup:
  - {do: use, role: song}           # selects media; expands to app.yaml on_use
segments:
  - card: intro
    duration: 1.0
    text: storePreviewAIntro        # the claim (not only the brand)
    background: {image: {role: photo, index: 0}}   # or {footage: true} / {color: primary}
  - scene: name
    beat: input
    duration: 3.0
    steps: [{do: type, key: composer.name, text: "{recipient}", cps: 7}]
  - bridge: toResult
    duration: 0.5
    image: {role: photo, index: 1}
  - scene: player
    beat: result
    duration: 8
    finished: true
    follow: song                    # a position reader the app registers
    audio: {role: song}
    before: [{do: tap, key: player.sections, index: "{chorus_index}"}]
    steps: [{do: pause, ms: 7500}]
  - card: outro                     # brand, cta and disclosure from app.yaml
    duration: 2.0
captions:
  - {key: storePreviewAHook, from: 1.0, to: 4.0}
```

Scenes are sped up to fit (up to `max_speed`, default ×3) unless they follow
playback, which runs in real time. `shoot_order` films a scene before an
earlier one (e.g. one that must happen before a system share sheet ends the
take). Variables `{name}` come from the selected media's `vars`, the
storefront's `vars`, then `storefront` and `script`.

### Steps

Built in (`store_preview_driver`): `pause`, `waitFor`, `waitGone`, `tap`
(`within:` a row of a lazy list), `type`, `submit`, `dismissKeyboard`,
`scrollTo`, `fling`, `pop`, `admin` (the backend's admin URL), `pickPhotos`
(`count`, `offset`), `waitSync`, `waitHelper`, `screenshot`. Finders: `key` (a
`ValueKey<String>`), `widget` (class name), `label`, `icon`, `index`.

An app registers its own in `integration_test/store_preview_test.dart`:

```dart
void main() => storePreviewTest(appMain: app.main, registry: StepRegistry()
  ..step('newDraft', (c, step) async { /* … */ })
  ..position('song', (c, at) async => /* seconds at `at` */ 0));
```

### Offline media transport

A recording can replay already-generated, licensed media through the app's real
image and video widgets without contacting the generator. For apps whose widgets
expect HTTP URLs, use the read-only loopback server:

~~~yaml
backend:
  start: 'dart run store_preview serve-media --app my_app --port {port}'
  port: 8791
  health: 'http://127.0.0.1:{port}/health'
  admin: 'http://127.0.0.1:{port}/'
~~~

GET /manifest returns schema 2 entries with an additional same-origin
media_url; GET/HEAD /media/<encoded entry id> serve that file and support
single byte ranges for native video players. The app's test entry maps the
entry's own data to its repository DTOs. No app-specific task API lives in
the tool. Empty manifests support controls-only captures; a result step must
reject a missing result.

Only files inside the manifest directory are served. Missing licenses, escaping
symlinks, unsupported media types and mismatched data.sha256 fail startup.
Files are hashed at startup and on reads; changes return 409. The server cannot
write, resize, generate media, contact ASC or mark anything real_ui.
serve-media uses normal configuration validation before it listens, and stops
on SIGINT/SIGTERM. Choose an unused local port; the recorder rejects an existing
server rather than adopting it.

### Media manifest (schema 2)

```json
{"schema": 2, "entries": [{
  "id": "song.A.en-US", "type": "audio", "role": "song", "locale": "en-US", "script": "A",
  "file": "songs/en-US_A.mp3",
  "license": {"provider": "lyria", "id": "<generation id>", "model": "lyria-3.5", "generated_at": "2026-10-05T08:00:00Z"},
  "vars": {"recipient": "Alex", "chorus_index": "2"},
  "data": {}
}]}
```

`type` is the stream the file holds (`audio`, `video`, `image`), `role` what
scripts ask for. Every entry needs a license id; entries of a script that is
not active (archive it) fail; `data` is the app's own. Media files are
git-ignored; the manifest is committed.

### Narrative templates

| Template | Beats |
| --- | --- |
| `input_wait_result_share` | intro · input · wait · bridge · result · share · proof · outro |
| `hook_problem_result_cta` | intro · hook · problem · bridge · result · proof · outro |
| `feature_triptych` | intro · feature1 · bridge1 · feature2 · bridge2 · feature3 · outro |

Each offers 15, 22 and 25 s rhythms whose beats add up to the rhythm with at
least 85 % footage; a script may stretch or squeeze a beat by ±2 s and drop
optional beats. The hook rule: the intro card states the claim and on-screen
text runs from 0 through 3 s.

Loop templates (creative videos — footage only, real time, the end dissolving
into the start, no audio):

| Template | Beats | Rhythms |
| --- | --- | --- |
| `banner_loop` | hero (finished) · detail | 8 · 12 · 16 s (header floor 10 s) |
| `search_card` | input · result (finished) · share | 8 · 12 · 15 s (search results floor 15 s) |

The muted hook: the phrase is on screen from the first frame, and the first
scene holds at least 2 s.

## Validation

| Layer | Checks |
| --- | --- |
| spec | MPEG-4, the slot's resolution, 15–30 s (= the script), ≤ 30 fps, H.264 High@4.0 yuv420p, 10–12 Mbps, AAC stereo 44.1/48 kHz 256 kbps, ≤ 500 MB, poster frame, captions, EDL |
| compliance | footage ≥ 85 %, cards ≤ 2 s each and 4 s together, cut/dissolve/fade only, footage never enlarged, no price, "free" (many languages), date or season or other app's name on screen, length limits, the purchase disclosed on the end card, every shown item licensed, no credential in the configuration or outputs |
| narrative | text from 0 to 3 s, captions ≥ 1.5 s and ≤ 17 characters/s (CJK 9), the poster frame (and the shared one) on finished footage, an image transition |

Creative assets (rule, source and review date for each:
`docs/store/creative-assets-specs.md`):

| Layer | Checks |
| --- | --- |
| spec | extension = real format; decodes completely; a fixed size pixel for pixel (3840×1646, 5244×2950), a range at its exact ratio; no alpha; ≤ 500 MB; video: 30 or 60 fps exactly, header 10–30 s / search 15–30 s and = the loop, H.264/HEVC yuv420p, one video stream, no audio stream, no rotation; poster frame |
| compliance | App Store Connect locale; a universal asset carries no text; the spec serves the placement; the panel and phrase inside the safe area, footage never enlarged; no price, "free", date, URL, ©/℗, award, Apple recognition or other platform; phrase length and lines; every shown item licensed and mapped to a license field; every source hashed |
| narrative | backdrop contrast under the phrase (WCAG); video: the phrase from 0 s through 2 s, one scene through the first 2 s, the poster frame on finished footage, the loop's seam (PSNR ≥ 40 dB) |
| manifest | ascpub's schema (from its checkout, pinned); every hash, size and measured value equal to the file; screenshot sets: `real_ui` more than half (from the review log only) |

## New app — step by step (about half a day, then ~5 min per storefront)

1. **Vendor the tool** into the app repo (once; ~1 min), from the template
   checkout: `dart run store_preview vendor --from . --root <app repo>` (the
   public packages, documentation and local acceptance script). Still in the
   template checkout, run `dart run store_preview integrate --root <app repo>`
   to inspect the plan, then add `--write` to apply it. This adds workspace
   members, development dependencies and the two Makefile targets without
   replacing existing business settings. Conflicts fail before writing.
   In the app, run `flutter pub get`, `integrate --check` and `vendor --check`.
   The root Dart SDK floor must already support pub workspace (>=3.6).
2. **Scaffold** (~1 min): `dart run store_preview new-app <name>` writes
   `store_preview/<name>/` (app.yaml from the repo's bundle id, icon, display
   name and ARBs; a 15 s feature-triptych script; an empty manifest), adds the
   caption keys to every ARB and writes
   `integration_test/store_preview_test.dart`. `validate --app <name>
   --config-only` passes as generated.
3. **Fill in the app** (~30 min): `driver.ready` (the first screen's key), the
   brand palette, each storefront's App Store name and subtitle, the copy
   (translate what new-app lists).
4. **Write the scenes** (1–3 h): each scene's steps — what a user does on that
   screen — using the built-in steps and the app's own (registered in the
   driver entry). Rehearse one storefront:
   `render --app <name> --locales en-US`; adjust pauses until every scene fits
   its slot (the error names the scene and how long it was filmed).
5. **System UI** (only if a script picks photos or meets a permission prompt;
   ~20 min): add a UI test target `RunnerUITests` to the Runner project, copy
   `native/ios/StorePreviewHelper.swift` into it, set `driver.helper: {}`.
6. **Media** (when a script shows generated media): the app's generator writes
   `media/manifest.json` with license ids; reference it from the scripts
   (`requires`, `background`, `bridge`, `audio`) and turn on
   `rules.require_image_transition`.
7. **Render everything** (~4 min recording per storefront and slot, ~30 s
   composing per preview): `render --app <name>`; then `export` into the
   store listing and upload by `dist/<name>/upload-checklist.md`.
8. **Creative assets** (~1 h, then ~1 min per asset and storefront; the
   whole flow and its rules: docs/store/asset-library-playbook.zh-CN.md):
   with a licensed image for every storefront in `media/manifest.json`,
   `new-creatives --app <name> --ascpub <ascpub checkout> [--cpp <slug>,…]
   [--ppo <slug>:<Treatment>,…]` writes `app.yaml` › `creatives`, the
   shelf, a counter per custom product page, a variant per treatment and the
   phrases. In ascpub, `ascpub assets init -b <bundle id> --cpp <slug>
   --ppo <slug>` creates the listing's pages (fill the CPP's name and
   keywords, the experiment's hypothesis and treatment names); then
   `listing --app <name> --write`, `validate --config-only`, `render` (or
   `creatives` on recorded takes; a video needs a capture script when no
   preview films a scene long enough). Look at
   `dist/<name>/creative/sheets/`, record each verdict with `review`, run
   `manifest`, then `make asset-library APP=<name>`.

## Changing the tool

Change it here (the template), run `make test`, then re-vendor every app from
the template checkout: `dart run store_preview vendor --from . --root <app
repo>`. A vendored copy edited in place fails its own test (`vendor --check`
in the app repo says so too).


### Ordered CPP screenshots

CPP screenshot sequences use the existing Asset Library manifest contract. Each
device slot declares `device` (recording source), `display_target` (Apple RefData
group), `placements: [app_screenshot]`, and a portrait screenshot spec. Built-in
specs are `screenshot_iphone_6_9` (1320×2868) and `screenshot_ipad_13` (2064×2752).
The layout `axis: vertical` puts the caption above the recording; an overflow is
an error, never an automatic font or image correction.

```yaml
shelf:
  media_sets:
    - placement: app_screenshot
      display_target: IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE
      locales: ["cpp.products.proof.{storefront}", "cpp.products.workflow.{storefront}"]
```

Every ID must be produced by that definition for the same placement/device.
One definition owns each target×placement×device group; separate device
definitions permit independent capture/render runs. `listing --write` writes
these sequences in order to the existing CPP (ascpub schema 2), retaining page
metadata and all undeclared media groups. It filters to the page's locales and
does not create pages or change schema versions. Absence is unmanaged; empty
arrays are rejected rather than interpreted as remote deletion.

The template does not upload screenshots. ASOShip ADR-0012 owns upload,
RefData limits, ordering, snapshots and read-back. Human review is still the
only authority for `real_ui`; changing the recording device or display group
invalidates that review. Configuration/renderer success alone is not release
readiness, and ascpub rejects screenshot sets without sufficient human review.

### Repeatable local delivery

Creative rendering verifies any existing manifest before starting, archives the
previous delivery under `dist/<app>/.releases/<manifest SHA-256>/`, and builds in
an isolated directory. A failed render or manifest check preserves the previous
delivery. Existing file drift blocks both regeneration and `manifest`; restoring
original bytes is required. The tool never rewrites hashes to disguise drift.
Initial partial runs can accumulate files but do not produce a valid delivery
manifest. Technically valid screenshots awaiting only human review become working
files without a delivery manifest (the command still fails); their previous
delivery stays in the archive. A person reviews the new files before `manifest`
and final acceptance. Archives are local and are not automatically deleted.

The manifest check also requires this app's bundle, complete asset IDs, locales,
placements and current human review for every `real_ui: true`. Acceptance begins
with vendor/workspace checks. Paths are resolved from the acceptance script's
repository, independently of the caller's working directory.

Recording uses a dedicated simulator per bundle, app configuration and device.
Before erasing it, the driver checks resolved Debug build settings against the
selected SDK's deployment limits. It never changes the app's deployment target.
Explicit simulator overrides remain supported and must name an exclusive,
disposable device.

See `docs/store/asset-library-reuse.zh-CN.md` for the next-app procedure and
`docs/store/asset-library-troubleshooting.zh-CN.md` for evidence and diagnosis.
