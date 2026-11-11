# UI inventory — prototypes → routes → components → states

Source: `docs/ui/*.png` (P01–P18, P02a–P02c, P03a) and `docs/design/songlet-prd.md`.
Routes are go_router locations (ADR-0003); every route is deep-linkable as
`songlet://app<location>`. States use the fixed vocabulary
**default · loading · empty · error · disabled · success**; "—" = not applicable.

## Prototype set audit

| File | Content | Notes |
| --- | --- | --- |
| P01 | Create home: Inspiration grid (16 template tiles + the server's inspirations, one tile kind) + floating composer | Canonical home (ADR-0008). The composer is built in three states with one primary action (ADR-0033); the prototype's mode chip, Preview/Full control and send arrow are not built. |
| P02 | Region sheet "Where will it be heard?" | Lists IE / NZ / ES / IT too; rows come from the 14 PRD §7.3 presets (ADR-0008). |
| P02a / P02b / P02c | Length / Vocals / Genre panels anchored to the composer | P02c = 18 genres + "Popular in {country}". |
| P03 | Template-filled create form | Built as the create home with the tile picked: composer state B (ADR-0032/0033). |
| P03a | Voice input mode inside the composer | Needs on-device transcription (ADR-0006). |
| P04 | Photo selection | System PhotosPicker sheet shown below the selection card. |
| P05 / P06 | Generating / queued | P06 adds the queue banner (position, wait). |
| P07 | Preview (30 s) player | |
| P08 | Paywall | Pro Monthly shows 10/50 — PRD §8.1 (40/100) wins (ADR-0008). |
| P09 | Full-song player | |
| P10 | Share card editor | |
| P11 | Download & license | |
| P12 | Library | |
| P13 | Work detail | |
| **P14** | **identical file to P13** (same md5) | No Settings prototype delivered — Settings is built from the design system (ADR-0009). |
| P15 | About generation | |
| P16 | Festival landing (pt-BR, Carnaval) | Different tab labels/icons than P01 — P01's shell wins (ADR-0008). |
| **P17** | **not delivered** | Spec: generic "temporarily unavailable" state (ADR-0009). |
| P18 | Validation + error banner (artist name) | Inline under the offending composer field (ADR-0033). |
| sub-week.png | Weekly "Unlimited" paywall | Not in the page list; contradicts PRD §8.1/D6 (no weekly product, capped allowances) — out of scope (ADR-0008). |

## Pages

### P01 · Create home — `/create` (shell tab 1) — F01, F02, F03, F05, F06
- **Components**: brand header (mark + name + tagline); template tile grid (photo, title, play-sample button); the composer card in three states (ADR-0033); shell tab bar (Create / Library / Settings). Nothing is counted down (ADR-0031).
- **Composer** (one mental model: who it is for → what to say → how it sounds → start):
  - **A · free input** (nothing picked): one prompt field — "+" (photos, P04) at its start, the mic (P03a) at its end, placeholder "Describe the song, or pick an idea above" ("…or pick an idea" beside the grid on iPad); the summary row "Preview · Vocals on · Indie Pop ›" (the region preset's and the card's defaults; own lyrics / lyric video appended while folded when they will be sent); the one primary action "Create preview · free" pinned under it.
  - **B · a picked tile**: the card's head (photo, name, ✕) at the composer's top; its fields in place of the prompt — "Their name" ("Name (optional)" by `requires_recipient`), "Three words about them" as chips (the third closes the keyboard), "Your words" (the card's hint as placeholder) only for an `input_required` card; the summary row with the card's defaults; the action "Create Alex's preview · free" ("Create preview · free" without a name; "Create full song · 1 song" under Standard).
  - **C · options** (tap the summary row; `/create?options=1`, over A or B): Length / Vocals / Genre selectors with their values (P02a–c panels: Short / Standard (+ Premier's song + chorus video); Vocals on / Instrumental / Custom; Popular in {country} ×3, All genres ×18, Custom); "Write your own lyrics (optional)" folded row (0 / 1,200; CJK 600; hidden for an instrumental); "Also make a lyric video" under Standard only (the card's `default_on_video`, else the occasion rule).
  - The action's cost follows the ledger (ADR-0035): "· free" (a free allowance), "· 1 preview", "· 1 song", or nothing. Removed: the "Music" chip, the Preview/Full control, the send arrow, the standing artist-name note.
- **Space** (ADR-0034): phones — the composer ≤ 35 % of the screen folded, ≤ 55 % unfolded, the grid keeps its heading and a full row; keyboard up — the header steps aside, a pick or the options fold the grid (the head stays); iPad — grid leading, composer in its own pane; AX sizes — one scrolling column, composer first. State switches animate over 200 ms (`SongletMotion.state`).
- **States**: default · loading · empty — · error (sample preview can't play → message banner; preflight → under the field, P18) · disabled (the action until there is something to make a song from, or while a card needs the user's words) · success → P05.
- **Interactions**: tap tile → picks it (accent outline, inward scale; tap again or the head's ✕ unpicks; what was typed stays in the draft both ways); tap tile play → sample preview toggle; "+" → P04; mic → P03a; summary row → options; selectors → P02a/b/c; action → preflight → P05 (a `QUOTA_EXHAUSTED` refusal → the paywall by its `offer`).
- **Inspiration grid** (ADR-0032, contract 02 v2.1): one heading, one grid — the server's list by `sort` (the 16 templates are entries of it), or the 16 built-in templates while it is not loaded. Tile = photo (`cover_image_url` → template photo → bundled photo → occasion picture), title, play dot (plays `preview_audio_url` only, never changes the pick); the style line is the accessibility label's second half. Goldens `P01`, `P01-inspirations`, `P01-picked`, `P01-options`, `P01-keyboard`; geometry `composer_layout_test`.

### P02a · Length panel — `/create?panel=length` (opens the options under it) — F05, F06
- **Components**: anchored popover (title, radio rows with icon + title + hint: Short, Standard, Premier's Song + chorus video), backdrop dim.
- **States**: default · disabled (the Premier row off Premier → the plans) · success (selection check).
- **Interactions**: select Short/Standard; tap outside/escape dismisses back to `/create?options=1`; the composer's summary row and the action follow. The lyric-video switch lives in the options under Standard (ADR-0033).

### P02b · Vocals panel — `/create?panel=vocals` — F03
- **Components**: anchored popover; rows Custom (based on prompt) / Vocals on / Instrumental with icons + radio; footnote "Lyrics are written in {language}".
- **States**: default · success.
- **Interactions**: select option; footnote tap → P02 (language row).

### P02c · Genre panel — `/create?panel=genre` — F02
- **Components**: side sheet (grab handle, title, close); "Custom — based on your prompt"; section "Popular in {country}" (3 region genres, primary with equalizer icon); section "All genres" (18); scroll.
- **States**: default · success (check) · empty — .
- **Interactions**: pick genre; "Popular in {country}" header → P02; close.

### P02 · Region sheet — `/create/region` — F02, F13
- **Components**: modal sheet (handle, large title, search field, country list rows flag + name + check/chevron, lyrics-language row, helper text, primary Done).
- **States**: default · empty (search no match → "No countries match") · success (checked row).
- **Interactions**: search filter; select country (updates 3 recommended genres + lyric language); lyrics language picker sheet; Done dismisses. **No availability blocking** (ADR-0005).

### P03 · Tile picked (deep link) — `/create/template/:id` → `/create?template=:id` — F01, F03
- **Components** (ADR-0032/0033; no separate page): the create home in state B — the tile picked (accent outline, inward scale) and scrolled into view; the composer with the card's head (photo, name, ✕), "Their name" with clear (label by `requires_recipient`), keyword chips with remove + add, "Your words" for an `input_required` card, the summary row, the primary action naming the person ("Create Alex's preview · free"). `?options=1` keeps the options open (golden `P03-options`); with the keyboard up the grid folds and the head stays (`P03-keyboard`).
- **States**: default · error (P18 under the fields; photo issues as a message) · disabled (the action while a card needs the user's own words) · success → P05.
- **Interactions**: edit fields (limits: name ≤ 24, 3 × ≤ 20, lyrics ≤ 1,200 / 600 CJK in the options); tap the tile again or ✕ → free input (fields fold, content kept and sent only with a pick); summary row → options; action → preflight → P05.

### P03a · Voice input mode — `/create?mode=voice` (free input only) — F03
- **Components**: the composer's body as the recording panel (recording dot + label, elapsed timer, live level waveform, live transcript, "On-device transcription" badge, "Use this text", the stop button at the status row's end); the summary row and the action stay.
- **States**: default (recording) · loading (starting / finalising) · error (permission denied, recogniser unavailable → message) · success (transcript applied to the prompt).
- **Interactions**: stop; "Use this text" → the prompt; with a tile picked the voice route is dropped (dictation is free input, ADR-0033).

### P04 · Photos — `/create/photos` — F04
- **Components**: back; large title; selection card (count "n / 10", thumbnails with remove, privacy note); primary "Create from photos"; system PhotosPicker.
- **States**: default · empty (no photos: helper text, button disabled) · loading (picker / compressing) · error (IMAGE_REJECTED banner) · disabled · success → P05.
- **Interactions**: pick (≤ 10), remove, create.

### P05 / P06 · Generating & queued — `/generate/:workId` — F05, F06, F12
- **Components**: brand header; pulsing mark; title "Writing {name}'s song…", subtitle ETA; progress bar + percent; meta line (genre · language · occasion); Cancel; "A glimpse of your song" carousel (lyric lines, page dots); P06 queue banner (clock icon, message, Position n, ≈ wait).
- **States**: loading (preparing / uploading) · default (running) · queued (P06) · error (§6.5 copy, retry / paywall / back) · success → P07/P09.
- **Interactions**: cancel (confirm; PRD §8.4: user cancel is not refunded); auto-advance on success.

### P07 · Preview player — `/works/:workId/preview` — F07, F08, F14
- **Components**: top bar (back, mark, share, more); cover with AI-generated badge; title; meta (occasion · genre · 0:30); waveform scrubber; loop; play/pause; timed lyric list (current line highlighted); primary "Get the full 2-minute song"; secondary "Share preview"; link "Try another version (uses 1 preview)".
- **States**: loading (audio preparing) · default · error (file missing → regenerate) · disabled (another version when no previews → paywall) · success.
- **Interactions**: play/pause/seek/loop; full song → P08 (no songs) or P05; share → P10; another version → P05; more → delete / details (P13).

### P08 · Paywall — `/paywall` (modal) — F11, §8
- **Components**: close; "Not now"; hero (title, subtitle, art); benefit icons; plan cards (Pro Yearly highlighted "Best value" + trial pill, Pro Monthly, Premier Monthly) with bullet lists; pack row ("Just need a few? 10-song pack", price, "never expires"); value strip; auto-renewal disclosure; links Restore / Terms / Privacy / Manage subscription; primary CTA (Start free trial / Subscribe / Buy).
- **States**: loading (products skeleton) · empty (no products) · error (ErrorRetryView) · disabled (purchase in progress) · success (dismiss + continue flow).
- **Interactions**: select plan; purchase; restore; manage; legal links; dismiss.
- **Credits** (contract 02 v2.1, ADR-0031): nothing is free. The page opens by `QUOTA_EXHAUSTED.offer`: `subscription` (or no offer) → plans lead, **Pro Weekly** preselected (price `/week`, caption "50% off your first week" and the intro-price disclosure read from StoreKit, benefit "Fresh credits every week"), packs below; `packs` → credit packs lead with `recommended_product_id` preselected and a "See subscriptions" link at the bottom. No "free previews", no "unlimited".

### P09 · Full-song player — `/works/:workId/play` — F07, F09
- **Components**: top bar; cover + badge; title; meta (duration · genre · language); waveform with section track (Intro / Verse / Chorus / Bridge / Outro); controls shuffle · previous section · play/pause · next section · repeat; scrolling synced lyrics; action tiles Download / Share / License / Regenerate; provenance footer.
- **States**: loading · default · error · disabled (download locked → copy) · success.
- **Interactions**: seek, section jumps, loop, shuffle (section order), actions → P11 / P10 / license PDF / P05.

### P10 · Share card — `/works/:workId/share` — F08
- **Components**: header; title/subtitle; 9:16 card canvas (brand, title, lyric lines, waveform, art, AI badge with lock); theme swatches (4); layout options (2); share targets (Messages, Instagram, TikTok, Save Video).
- **States**: default · loading (composing video) · error (compose failed) · success (sheet shown).
- **Interactions**: pick theme / layout (live preview); share target → system share sheet with the MP4 (ADR-0010).

### P11 · Download & license — `/works/:workId/download` — F09, §9.1
- **Components**: back; cover; "Full song ready" pill; title; meta; description; "Download audio" rows (MP3; WAV for Premier behind the `wav_export` switch, ADR-0010); "Commercial license" card (PDF row with date + ID, usage grid, info row); "Save and enjoy" (Save to Files, Add to Music); SynthID note + Learn more; Done.
- **States**: loading (preparing) · error (DOWNLOAD_LOCKED) · disabled (WAV for non-Premier → paywall; Premier song without a WAV render → note) · success (saved).
- **Interactions**: download MP3/WAV (Files), license PDF, Save to Files (folder), Add to Music (ADR-0010), Learn more → P15, Done.

### P12 · Library — `/library` (shell tab 2) — F10
- **Components**: header with iCloud sync status; filter chips (All + occasions + More); grouped sections with "See all"; work rows (cover, title, recipient, duration · date, Preview/Full badge, play, more).
- **States**: loading · empty ("Your songs will live here") · error · default · success.
- **Interactions**: filter; see all → `/library/occasion/:occasion`; play inline; open → P13/P07/P09; more → share / download / delete; sync status → Settings.

### P13 · Work detail — `/works/:workId` — F10, §5.1
- **Components**: top bar; summary card (cover, title, meta, generated date · model, status pill); "Prompt used" (occasion, country, genre, keywords); lyrics; Generation ID with copy; "Regenerate same style"; "Delete".
- **States**: default · loading · error · success (copied / deleted).
- **Interactions**: copy ID; regenerate → P05; delete (confirm) → back.

### P14 · Settings — `/settings` (shell tab 3) — F11, F13, §9.4
- **Components** (no prototype; ADR-0009): plan card (tier, songs/previews left, reset); Upgrade; Restore purchases; Manage subscription; iCloud sync toggle; lyrics language default; About generation; Terms; Privacy; version.
- **States**: loading · error · default · success.

### P15 · About generation — `/settings/about` — §9.4, §10.1
- **Components**: back; title/subtitle; 4 info cards (Lyria 3, SynthID, no imitations, privacy); highlight banner "Every song you share is labeled AI generated."; version footer.
- **States**: default.

### P16 · Festival — `/festival/:festivalId` — §11.3
- **Components**: festival hero banner (kicker, title, body, CTA), heading "Who is this song for?", occasion cards grid (image, title, hint, chevron), "Songs in your language" row.
- **States**: default · empty (no festival for region → New Year).
- **Interactions**: CTA → P03 with the festival template; occasion card → P03; language row → P02.

### P17 · Temporarily unavailable — `/unavailable` + in-place — F12
- **Components** (no prototype; ADR-0009): StatusView (icon, title "Temporarily unavailable", message, Retry).
- **States**: default · loading (retrying).
- **Triggers**: kill switch, maintenance without message, `REGION_UNAVAILABLE` from the server mapped per ADR-0005, repeated upstream failures.

### P18 · Validation & error states — inline in the composer and on P04 — §7.4, §6.5
- **Components**: the offending field's error outline + helper under it ("Artist names can’t be used." under the name; "Artist names can't be used — describe the feeling instead." under the prompt, the three words or the lyrics — `Preflight.screen` finds which); error banner (icon, §6.5 copy) for what no field shows (photos, the material rule).
- **States**: error · default.
- **Interactions**: editing clears the issue; a lyrics issue opens the options to the lyrics.

### Music videos (PRD ch.15) — no prototypes, ADR-0027

### P19 · Video entries — P09 card, P13 rows, P12 chip
- **Components**: `MvEntryCard` (SurfaceCard: title, subtitle, status pill with the real percent, See progress / Watch video, Choose a video); work-detail video rows (level, status, credits, date); library row `MvStatusChip` (Making video · Video).
- **States**: default (no video) · making (percent when reported) · ready · failed (row) · disabled (song not finished).
- **Interactions**: Choose a video → P20; See progress → P24; Watch → P26; a row opens where the video stands (P24/P25/P26).

### P20 · Video hub (compact) — `/library/works/:id/mv?level=&from=` — §15.2
- **Components**: three `MvLevelCard`s (price from `POST /v1/mv/estimate`, credits you have / more needed, "Recommended" on the chorus video, "Making…" on a level in flight), waiting-for-credits banner, options (format, quality when offered, lyrics on screen, chorus window, up to 10 reference photos), "saved for the video" note, primary action.
- **States**: default · loading (pricing) · error (pricing failed, retry) · level in flight (disabled, See progress) · submitting · credit gap (→ P22) · refusal (message: too long → chorus; photos expired → cleared; song expired → make the song again).
- **Interactions**: `level` preselects, `from` prefills the options (Make another, retry, upgrade).

### P21 · Video hub (regular) — same route, iPad / landscape
- **Components**: P20's levels on the start pane, options on the end pane, the action at the end corner.

### P22 · Not enough credits — bottom sheet over P20 — §15.4
- **Components**: title, need vs have, gap pill, recommended pack row (store price), "may need two" note (T2/T3), auto-retry note, Buy and continue, See plans, Not now.
- **States**: default · purchasing · failed (inline) · deferred · no pack (plans only) · kill-switched.
- **Interactions**: purchase completed → the same request again → P24; cancelled / Not now → back to P20 with every choice.

### P23 · Automatic video banner — on P07 / P09 — ADR-0022
- **Components**: `InlineProgressBanner` (countdown with Cancel — for the lyric and the chorus video alike, since both cost credits (ADR-0031); lyric video being made with stage and percent, View); ready card (Watch video, Make a chorus video); inline error with Close.

### P24 · Making the video — `/library/works/:id/mv/generate/:videoId` — §15.5
- **Components**: header, pulsing mark, title, stage, `ProgressMeter` (platform progress only), scenes x of y, meta (level · song · time left), leave hint, Cancel; cancel-requested banner.
- **States**: preparing (upload / submit) · queued anchor · running · cancel requested · unknown video (back to the hub).
- **Interactions**: Cancel → queued: refunded, back to P20; rendering: stops after the scene.

### P25 · The video didn't finish — same route
- **Components**: StatusView (title, contract copy, icon), credits-back pill, photo count, one action.
- **States**: photo rejected / safety (Adjust photos and try again) · render failed / timeout (Retry) · too long (Make a chorus video instead) · song expired / not ready (Make the song again) · photos expired (Adjust photos) · stopped by the user.

### P26 · The video (portrait) — `/library/works/:id/mv/:videoId` — §15.2
- **Components**: dark, above the tab bar: back, delete, the video with the AI badge and play/pause, title, meta, scrubber, `SectionTrack` of the covered span, `SyncedLyricsView` on the video's clock (chorus offset by its window; none for a lyric video or a chorus the platform located), AI disclosure, Share · Save to Photos · Save to Files · Make another, provenance.
- **States**: loading · playing / paused · file missing · action busy.

### P27 · The video (landscape / iPad, 16:9 and 1:1) — same route
- **Components**: the video on the start side, P26's panel as a side column.

### P28 · Standard with the lyric video — the composer's options — ADR-0022, ADR-0033
- **Components**: the options under Standard: Length "Standard" (Premier's "Song + chorus video" in the P02a panel, Premier pill off Premier), "Also make a lyric video" switch (template default; never sent with a preview), the action "Create full song · 1 song".

### P29 · Paywall video packs — P08 — §15.4
- **Components**: "Music videos" group (first when opened for a video, preselected pack), Premier benefit "Your allowance also makes music videos".

### P30 · Settings video credits — P14 — gap G5
- **Components**: "Video credits · N credits" in the plan card, only when `credits_available` is reported.

## Coverage

18 page IDs (P01–P18) + 4 panels/modes (P02a, P02b, P02c, P03a) + 12 music-video pages (P19–P30, ADR-0027) registered = 34 entries.
