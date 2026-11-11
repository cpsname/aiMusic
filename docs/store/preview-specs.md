# Songlet's App Store previews

What Songlet's previews are and why. Apple's specification, creative guidance
and Review Guideline 2.3 are quoted verbatim, with the tool's own thresholds,
in [apple-preview-rules.md](apple-preview-rules.md) (vendored with the tool,
`packages/store_preview`). Decisions: ADR-0037 (iPhone only), ADR-0038 (two
previews, the reusable tool).

## Slot and count

The app launches iPhone-only (ADR-0037): the **iPhone 6.9"** slot, 886 × 1920,
**two previews per localization**, 12 localizations — 24 files. App Store
Connect scales them to the smaller iPhones. The iPad 13" slot (1200 × 1600)
stays available in the tool and is refused while the Runner target lacks
device family 2.

## The two previews (25 s each, `input_wait_result_share`)

| Time | A — "A song with their name in it" | B — "Your photos set the mood" |
| --- | --- | --- |
| 0–1 s | intro card: icon + the claim, over the storefront's photo | intro card: icon + the claim, over the storefront's photo |
| 1–4 s | the Birthday Wish tile, the name typed | four photos picked from the library |
| 4–7.5 / 4–8 s | three words about them | "also make a lyric video" switched on, create |
| 7.5–10 / 8–10 s | the wait (sped up; the page says "about 45 seconds") | the wait |
| 10–10.5 s | dissolve through a photo | dissolve through a photo |
| 10.5–18.5 / 10.5–17 s | the player on the chorus that sings the name (real time, with the song) | the platform's lyric video (real time, with its soundtrack) |
| 18.5–23 / 17–19.5 s | the 9:16 share card | the share sheet |
| 19.5–23 s | — | the country and lyric language picked (the many-languages claim, from the archived script C) |
| 23–25 s | end card: icon, Songlet, call to action, "Requires a subscription or credits" | the same |

Poster frame at **13 s** in both: the player (A) and the lyric video (B). The
same 13 s works as the single still frame fastlane deliver sets
(`listings/com.songlet.ios/base.yaml` `preview_frame_time_code`).

## How they meet the rules

| Rule | Songlet |
| --- | --- |
| Screen captures of the app (2.3.4) | Simulator footage at native resolution, downscaled only; 21.5 of 25 s (86 %) is footage. The cards (3 s) and the bridge (0.5 s) are measured in each output's EDL against the tool's 85 % / 4 s limits. |
| Transitions | Cuts between scenes; dissolves into and out of the cards and through the bridge. |
| Muted autoplay | The intro card states the claim; the first caption runs from 1 s to 4 s. |
| Captions readable | ≥ 1.5 s each, ≤ 17 characters/s (≤ 9 for Japanese, Korean, Chinese), on plates whose opacity follows the footage under them. |
| No price, "free", dates, other apps | Checked on every text in every storefront (Suno, Udio, Boomy, Mubert, Soundraw, AIVA, Soundful, Riffusion added to the tool's list). |
| Purchase disclosure | The end card's small print, localized (`storePreviewDisclosure`). |
| Authorized content | Songs from Lyria, lyric videos and photos from the platform, each with its license id in `store_preview/songlet/media/manifest.json`; no other audio, video or picture. Photos show no faces, brands or lettering. |
| Encoding | x264 High Profile Level 4.0, 30 fps, 11 Mbps CBR with HRD filler; AudioToolbox AAC 256 kbps stereo 44.1 kHz. |
| Undelivered features | WAV export stays hidden (production keeps `config.wav_export` off). |

## Making them

```sh
make store-preview                                    # render --app songlet --scripts A,B --locales all
make store-preview ARGS="validate --app songlet"      # the three layers on dist/songlet
make store-preview ARGS="export --app songlet"        # into listings/com.songlet.ios (removes retired previews)
```

Recording erases a dedicated simulator ("Store Preview (iPhone 17 Pro Max)",
or `STORE_PREVIEW_SIM_IPHONE=<udid>`), takes about 4 minutes per storefront;
composing all 24 about 10 minutes. The media come from the products repo
(`store_preview/songlet/media/README.md`).
