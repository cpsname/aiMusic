# ADR-0020 — Music videos from a finished song
Status: Accepted
Date: 2026-09-28

## Context
PRD ch.15 extends Songlet from "songs" to "song → music video": a lyric video
(free), a 30 s chorus video and a full-song video, rendered server-side on the
platform's creation pipeline (platform ADR-036/037/038/043) and paid in
credits. The platform published the contract (`02-openapi.yaml` v1.1 MV
section, `04-errors.md` §2 / §3.1); the client has to adopt it without
inventing state of its own.

## Decision
- **The client keeps no server state for videos.** `mv_id` is the platform task
  id; `GET /v1/mv/{mv_id}` is the only truth while a video is being made. The
  local `music_videos` table (works database v3) stores what the library needs
  after the fact: which work, which level, the downloaded MP4, the outcome.
  Videos left `pending` are resumed by polling, like songs.
- **Estimating saves the song.** `POST /v1/mv/estimate` is the price shown on
  the hub; it locks the song on the platform (`song_locked`), because the
  platform prices only a saved song and a full video's price depends on the
  measured length. The hub says so; saving is idempotent and free.
- **Progress is never interpolated.** The page renders the platform's `progress`
  (completed steps + scenes) and `stage`; before the first snapshot it shows the
  queued anchor. No clock-driven ring (the songs' ETA-driven ring stays where the
  platform reports no progress; a video always does).
- **A credit gap buys the pack and retries.** `QUOTA_EXHAUSTED` carries
  `QuotaExhaustedDetails` (`required_credits`, `available_credits`,
  `recommended_product_id`). `infra_core` now carries the envelope `details` on
  every `ApiError` / `Failure`; `QuotaGap.of(failure)` reads them. The paywall
  opens preselected on the recommended pack (`PaywallReason.mv`, `product=` query)
  and, once `IapCompleted`, the same `MvRequest` (same `client_ref`, so it can
  never double-charge) is submitted again.
- **Cancel has two outcomes.** Queued → `cancelled` (refunded now, local record
  removed). Rendering → `cancel_requested`: the platform stops at the next scene,
  charges the finished ones and refunds the rest on the terminal poll; the page
  shows the acknowledged banner and waits for `failed / USER_CANCELLED`.
- **The AI badge is server-side and re-labelled.** The platform burns the badge
  into the pixels (`ai_label: burned_in`, not switchable); the player also shows
  the "AI generated" badge and says the badge is part of the video (PRD §9.4).
- **Playback** uses `video_player` (the first video playback in the app; the
  share card only *produces* video). Share via the system sheet, Save to Photos
  through the existing `VideoSaver` gateway, Save to Files through `FileExporter`.
- **Codes.** `SongletErrorCode` gains `MV_SONG_NOT_READY` (49312),
  `MV_SONG_TOO_LONG` (49313), `MV_SONG_EXPIRED` (49314), `MV_NOT_FOUND` (49315),
  `MV_PHOTOS_EXPIRED` (49316) and the job-level `MV_RENDER_FAILED` /
  `USER_CANCELLED`; `QUOTA_EXHAUSTED` is 49303 on HTTP 200 (the platform's
  confirmed value; the strings remain the contract).
- **Catalog.** Two consumable MV packs (`com.songlet.mv.chorus`,
  `com.songlet.mv.full`) join the paywall as pack rows; Premier's monthly songs
  are not raised (platform ADR-S03: grants follow the price formula).

## Consequences
The client stays a thin mirror: no ledger, no progress guesses, no duplicate
state. A newer platform stage name or a new pack shows up without a client
release (unknown stage → generic title; packs come from the store). The mock
(`mock_server/`, `mv_runner.dart`) reproduces the staged run, both cancel
outcomes, the credit pocket and every MV code; `contract_extensions_test.dart`
(`v1.1 music videos`) is the executable form of the contract.

## Amendments (2026-09-29)
- Progress follows the video by id and the hub session hands a submitted video
  off (ADR-0021); the page routes are `/mv/generate/:videoId` and `/mv/:videoId`.
- The credit gap opens the P22 sheet that buys the pack in place, with the
  request persisted and retried with bounded delays (ADR-0023) — no longer the
  full paywall.
