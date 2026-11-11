# Apple App Preview rules (source of every creative rule in `store_preview`)

Fetched 2026-10-06 from the three pages below. Quotes are verbatim; the tool's
own thresholds — where Apple states no number — are listed last, marked as
ours, with the reason. Re-fetch these pages before changing a rule.

- [App preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications)
- [App previews](https://developer.apple.com/app-store/app-previews/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) § 2.3

## Specifications

| Context | Requirement |
| --- | --- |
| Maximum file size | 500MB |
| Minimum length | 15 Seconds |
| Maximum length | 30 Seconds |
| Default poster frame setting | 5 Seconds |
| Orientation | Portrait or Landscape |

**H.264**: "Target bit rate: 10-12 Mbps"; "Progressive, up to High Profile
Level 4.0"; "Max frame rate: 30 frames per second"; ".mov, .m4v, .mp4".
**ProRes 422 (HQ only)**: "VBR ~220 Mbps", ".mov".

**Audio** (stereo): "256kbps AAC" (H.264) | "PCM or 256kbps AAC" (ProRes);
"Sample Rate: 44.1kHz or 48kHz"; "All tracks should be enabled"; "1 track
with 2-channel stereo (1st channel L and 2nd channel R)".

**Resolutions** (portrait): iPhone 6.9", 6.5", 6.3", 6.1" Display — 886 x 1920
px; iPad 13", 11" Display — 1200 x 1600 px. "You can deliver up to 3 app
previews with the supported resolutions listed above."

## Creative guidance (App previews page)

- "App previews demonstrate the features, functionality, and user interface
  of your app using footage captured on device."
- "Stay within the app. App previews must show only content within the app
  itself. Don't film people interacting with a device, such as an
  over-the-shoulder angle or fingers tapping the screen."
- "You can have up to three app previews for each language your app
  supports, and each preview can be up to 30 seconds long."
- "Use graphics and transitions. If you need to demonstrate how interaction
  or navigation works within your app, you may add graphic elements, such as
  touch hotspots. We recommend capturing the native UI resolution rather than
  zooming in on the view. Ensure that any transitions between scenes don't
  imply functionality that your app doesn't include. Aim to use
  straightforward transitions, like dissolves and fades."
- "Add additional context with copy. By default, app previews play with the
  sound muted, so consider using copy to add additional context to your
  footage. Ensure text is legible, is easy to understand, and remains on the
  screen long enough for people to read. Avoid any seasonal or timely
  references that will age your video, such as 'new for spring' or dates.
  Don't include specific prices, as pricing and currencies vary across
  regions."
- "Note if a purchase is required. If you display features that are only
  available through in-app purchase, or if your app uses a subscription
  model or requires login, you must disclose this. Disclaimer copy can be
  included within the footage or in the end frame."
- "Consider your audio. To establish continuity across scenes, consider using
  a single musical score or soundtrack throughout your entire app preview. To
  reinforce functionality in your app, you can include sound effects from
  your UI or gameplay in your footage. If you decide to use any voiceover to
  enhance your app preview, use high-quality audio equipment and record in
  locations without background noise to deliver the best user experience."
- "Include only authorized content. Show only material you have the legal
  right to display. If your app displays any protected content such as music,
  film, trademarked characters, brands, or other intellectual property
  assets, ensure you have the appropriate licensing rights for your marketing
  use in all territories."
- "If someone has turned off video autoplay in their App Store settings, a
  poster frame will display. Select a visually compelling poster frame from
  your footage that conveys the essence of your app."

The page states **no numeric share** of in-app footage.

## App Review Guidelines § 2.3 (excerpts)

- **2.3** "…make sure all your app metadata, including privacy information,
  your app description, screenshots, and previews accurately reflect the
  app's core experience…"
- **2.3.1(a)** "…marketing your app in a misleading way, such as by promoting
  content or services that it does not actually offer … is grounds for
  removal…"
- **2.3.2** "If your app includes in-app purchases, make sure your app
  description, screenshots, and previews clearly indicate whether any
  featured items, levels, subscriptions, etc. require additional purchases."
- **2.3.4** "Previews are a great way for customers to see what your app looks
  like and what it does. To ensure people understand what they'll be getting
  with your app, previews may only use video screen captures of the app
  itself. Stickers and iMessage extensions may show the user experience in
  the Messages app. You can add narration and video or textual overlays to
  help explain anything that isn't clear from the video alone."
- **2.3.7** "Metadata such as app names, subtitles, screenshots, and previews
  should not include prices, terms, or descriptions that are not specific to
  the metadata type."
- **2.3.8** "…make sure your app and in-app purchase icons, screenshots, and
  previews adhere to a 4+ age rating even if your app is rated higher."
- **2.3.9** "You are responsible for securing the rights to use all materials
  in your app icons, screenshots, and previews, and you should display
  fictional account information instead of data from a real person."
- **2.3.10** "…don't include names, icons, or imagery of other mobile
  platforms or alternative app marketplaces in your app or metadata…"

## How the tool applies them

| Rule | Check (layer) | Value | Source |
| --- | --- | --- | --- |
| Length, size, resolution, codec, profile/level, bitrate, frame rate, audio | spec | as quoted above | Specifications |
| Full-frame app footage share of the timeline | compliance | **≥ 85 %** | **ours** — 2.3.4 allows only screen captures plus overlays; cards and image bridges are full-frame non-footage, so their total is capped. Apple gives no number. |
| Brand cards | compliance | **≤ 2.0 s each, ≤ 4.0 s together** | **ours** (task brief) |
| Transitions | compliance | dissolve / fade only | "straightforward transitions, like dissolves and fades" |
| Footage scale | compliance | never enlarged (scale ≤ 1) | "capturing the native UI resolution rather than zooming" |
| Prices, "free", dates, seasons | compliance | none on screen | Creative guidance, 2.3.7 |
| Other apps' names | compliance | none (app list) | 2.3.7, 2.3.10 |
| Purchase disclosure | compliance | on the end card while the app sells in-app purchases | "you must disclose this … in the end frame", 2.3.2 |
| Licensed media | compliance | every manifest item carries a license id | "Include only authorized content", 2.3.9 |
| Muted hook | narrative | on-screen text from 0 through 3 s | "app previews play with the sound muted" |
| Caption reading | narrative | **≥ 1.5 s on screen; ≤ 17 characters/s (CJK ≤ 9)** | **ours** — "remains on the screen long enough for people to read" |
| Poster frame | narrative | inside a finished-product scene | "a poster frame … that conveys the essence of your app" |
| Single soundtrack | post-production | one source across the timeline, crossfaded | "a single musical score or soundtrack" |
