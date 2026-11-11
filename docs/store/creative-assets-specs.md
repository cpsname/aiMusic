# App Store creative assets — the rules `store_preview` checks

Product page header and search results assets (images and looping videos),
announced by Apple on 2026-10-05. Fetched **2026-10-08**, re-fetched and
checked line by line on **2026-10-10** ([A] [B] [G] unchanged); quotes are
verbatim. The tool's own thresholds — where Apple states no number
— come last, marked as ours, with the reason. Re-fetch before changing a rule;
`defaults/creative.yaml` carries the numbers, the template ADRs 0009–0014 the
decisions.

- [A] [Creative assets specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications) (App Store Connect Help)
- [B] [App Store asset best practices](https://developer.apple.com/app-store/asset-best-practices/)
- [G] [App Review Guideline 2.3.3](https://developer.apple.com/help/app-review/guideline-reference/2-3-3-screenshots)
- [N] [Showcase your apps with new assets on the App Store](https://developer.apple.com/news/?id=ljpl7kyn) (Apple Developer News, 2026-10-05)
- [R] App Store Connect API RefData (`GET /v1/appAssetLibraryRefData`), as ascpub captured it on 2026-10-08 (`src/schema/asset-refdata.snapshot.json`; ascpub reports no drift from the live catalog that day)
- [M] github.com/dredfort42/dredfit/pull/306: a third party's reading of App Store Connect's device preview (not Apple's text)

## Specifications [A]

"Creative assets include product page header, search results, and in-app
event cards."

**Image specifications for product page header and search results.**
"**Note:** Images can't include alpha channels or transparencies."

| Placement | Aspect ratio | Resolution | Supported extensions |
| --- | --- | --- | --- |
| Product page header | 21:9 | 3840 x 1646 pixels | .jpeg, .jpg, or .png |
| Product page header | 16:9 | 5244 x 2950 pixels | .png |
| Search results | 3:2 | Min: 1920 x 1280 pixels Max: 3840 x 2560 pixels | .jpeg, .jpg, or .png |
| Search results | 16:9 | 5244 x 2950 pixels | .png |

**Video specifications for product page header and search results.**
"**Note:** Videos are muted by default in search results and can't currently
be unmuted. On your product page, videos are also muted by default, but
people can unmute them. Videos loop continuously in both placements."

| Placement | Aspect ratio | Resolution | Frames per second | Minimum length | Maximum length | Supported extensions |
| --- | --- | --- | --- | --- | --- | --- |
| Product page header | 21:9 | 3840 x 1646 pixels | 30 fps or 60 fps | 5 seconds | 30 seconds | .mov, .m4v, or .mp4 |
| Search results | 3:2 | Min: 1920 x 1280 pixels Max: 3840 x 2560 pixels | 30 fps or 60 fps | 5 seconds | 30 seconds | .mov, .m4v, or .mp4 |

## The API's catalog [R]

| Spec (`shortName`) | Size | Ratio | Extensions | Other |
| --- | --- | --- | --- | --- |
| `i3840x1646a0` | 3840×1646 | 21:9 | **.png only** | header; `alphaAllowed: false` |
| `i5244x2950a0` | 5244×2950 | 16:9 | .png | header and search; `universalAsset: true` |
| `i3x2w1920~3840a0` | 1920–3840 × 1280–2560 | 3:2 | .jpg, .jpeg, .png | search |
| `v3840x1646f30f60t10~30u0` | 3840×1646 | 21:9 | .mp4, .m4v, .mov | 30 or 60 fps; duration PT5S–PT30S; `audioRequired: false` |
| `v3x2w1920~3840f30f60t15~30u0` | range | 3:2 | .mp4, .m4v, .mov | 30 or 60 fps; duration PT5S–PT30S |

Every spec: `maxFileSize` 524288000. Per App Store version, custom product
page or product page optimization treatment: one header and one search
results asset (`maxCount: 1`, group `DEFAULT_PROFILE`).

## Creative guidance [B]

- Header: "Focus on a single, clear idea. Visually dense or cluttered assets
  dilute your impact." "Design with a first-time visitor in mind."
- Search results: "Your search result asset is the first thing people
  experience when they find your app or game through the Search tab, before
  they ever reach your product page." "State the obvious. Since people tend
  to look for something specific when using search, be sure your app or
  game's purpose is obvious at a glance." "Showcase the firsthand experience.
  Consider sharing the interface, content, or gameplay to make it easy for
  someone to decide whether they want to download."
- Video: "Videos autoplay and repeat, so people may see the loop multiple
  times. Ensure your video is polished and loops smoothly without visible
  jumps or breaks." "In most cases, audio is muted by default, so your
  creative must work silently first." "Start strong. Lead with your value
  proposition or most compelling feature. Be mindful with pacing your cuts to
  give people enough time to grasp what's being shared. Avoid quick cuts and
  fast-moving visuals …" "Select an impactful poster frame."
- Composition: "Design key elements with a safe area in mind to accommodate
  different devices and orientations. Be sure your focal point artwork is
  within the center of your composition to prevent any unwanted clipping."
  "Keep it legible. Ensure all key elements are readable — especially any
  text — as assets can appear differently across the App Store." "If using
  text, use a short phrase that enhances your visual rather than describes
  it. Be sure to localize for all languages your app supports."
- Where they show: "Creative assets appear across the App Store in iOS 27
  and iPadOS 27 and later including your product page, in search results,
  and when your app is featured."
- Audio: "Use audio mindfully. In most cases, audio is muted by default, so
  your creative must work silently first. When you do add sound, treat it as
  brand texture rather than information delivery." (The tool's videos carry
  no audio stream at all.)
- Content: "Don't include specific pricing, discounts, website URLs,
  copyright symbols." "Avoid claims that can't be verified, such as awards or
  recognition that your app or game hasn't actually received." "Don't
  include logos or references to other platforms or marketplaces." "Please
  don't include any Apple-designated recognitions — such as Editor's Choice,
  App of the Day, Game of the Day, or Apple Design Award winner …"

## Screenshots [G]

"App Review takes the set of screenshots submitted for each supported device
into account, and will approve only those submissions where more than half
of screenshots show the app in use." Example: "if an app has three
screenshots for each supported device, two of the screenshots for each device
must show the app in use on that device."

## Where the sources differ, and what they leave open

| Point | [A] | [R] | The tool |
| --- | --- | --- | --- |
| Header 21:9 image extensions | .jpeg, .jpg, .png | .png | PNG (the API's check is the binding one) |
| Header video minimum length | 5 s | spec name `t10~30`, duration PT5S | ≥ 10 s |
| Search video minimum length | 5 s | spec name `t15~30`, duration PT5S | ≥ 15 s |
| Range sizes' ratio tolerance | not stated | not stated | none: w·b = h·a in integers (ascpub V-11 asks the same) |
| Video codec, bitrate, audio | not stated | `audioRequired: false` | H.264 High, no audio stream |
| Safe area in pixels | not stated ("within the center") | — | central 72 % width of 21:9 from [M] (x 330–3530 shown on iPhone, content inside 520–3320); 84 % / 74 % elsewhere |
| OS versions that show the assets | not stated | — | iOS 27 and iPadOS 27 and later, as [B] states (below); the tool renders the same files for every version |

## What `store_preview` checks

| Rule | How | Source | Reviewed |
| --- | --- | --- | --- |
| An exact size is matched pixel for pixel | `SizeRule.fits`: 3840×1646, 5244×2950 never tested by ratio (3840/1646 ≠ 21/9) | [A] [R] | 2026-10-10 |
| A range size holds its ratio exactly | in range, and w·b = h·a in integers | [A] [R]; ours (no tolerance stated) | 2026-10-10 |
| No alpha | the image's pixel format has no alpha channel (palettes count as alpha) | [A] [R] | 2026-10-10 |
| Extension = real format | `.png` ↔ PNG, `.jpg/.jpeg` ↔ JPEG, `.mp4/.m4v` ↔ ISO media (not `qt`), `.mov` ↔ QuickTime | [R] lists extensions and MIME types | 2026-10-10 |
| Decodes completely | `ffmpeg -xerror` over every frame, no error output | ours (ascpub does the same) | 2026-10-10 |
| Frame rate exactly 30 or 60 | average and base frame rate both | [A] [R] | 2026-10-10 |
| Length | header 10–30 s, search 15–30 s, = the loop's own length (rhythms: header 8 / 12 / 16, search 8 / 12 / 15; the floor rules out the shorter ones) | [A] [R], strictest (ADR-0013) | 2026-10-10 |
| Codec, rotation, streams | H.264 or HEVC, no rotation metadata, one video stream, `yuv420p` | ours (Apple states no codec; rotation handling is unpublished) | 2026-10-10 |
| Muted | no audio stream at all | [A] (muted, search can't unmute) | 2026-10-10 |
| ≤ 500 MB | file size | [R] | 2026-10-10 |
| Locale and placement | per-storefront assets carry a storefront id that is an App Store Connect locale (`defaults/creative.yaml` `asc_locales`); universal assets (`locale: null`) carry no text; a spec serves only its placements; one id per asset; a custom product page target and its default ids exist in ascpub's page configuration | [R]; contract; ascpub `cpp/<slug>.yaml` | 2026-10-10 |
| Safe area | panel and text block inside the layout's safe area, as the renderer measured them | [B]; [M] for 21:9 | 2026-10-10 |
| Footage never enlarged | panel scale ≤ 1 | ours (as for previews) | 2026-10-10 |
| Text | no "free", price, date, URL, ©/℗, award or Apple recognition, other platform; ≤ 40 characters (CJK 20); ≤ the layout's line limit as set | [B]; ours (lengths) | 2026-10-10 |
| Licensed media | every shown generated item (a scene's audio, what it `shows`, the backdrop) has its license id in the EDL; the manifest's `authorization` names, per field, the item of the asset's primary scene first (ADR-0014) | ours; contract `authorization` | 2026-10-10 |
| Muted hook | a video's phrase on screen from 0 s through 2 s (all of it, in fact); its first scene runs at least 2 s (no cut inside the first 2 s); a sheet of the frames at 0 / 0.5 / 1 / 1.5 / 2 s per video for the person reviewing | [B] "work silently first", "Avoid quick cuts"; ours (2 s) | 2026-10-10 |
| Poster frame | inside a finished-product scene | [B] "impactful poster frame" | 2026-10-10 |
| Loop seam | PSNR(last frame, first frame) ≥ 40 dB, measured on the file | [B] "loops smoothly"; ours (40 dB) | 2026-10-10 |
| Legibility | the backdrop under the text block: WCAG contrast with the text colour ≥ 4.5 (mean) and ≥ 3.0 (90th percentile) | [B] "Keep it legible"; ours (WCAG 2) | 2026-10-10 |
| Screenshot majority | per locale × display target: `real_ui` > half; `real_ui` only from the human review log | [G]; contract | 2026-10-10 |
| The manifest | valid against ascpub's own `assets-manifest.schema.json`, read from the ascpub checkout and pinned by SHA-256 (no copy, ADR-0010); every hash, size and measured value equal to the file's | contract | 2026-10-10 |

Never fixed by the tool: a failing asset is reported, not edited. A
re-render writes a new file with a new hash; the manifest records each
asset's sources (recording, backdrop, icon) by hash in its EDL and
`derived_from`.
