# ADR-0012 — Job progress, queue position, lyric glimpse and cancel
Status: Accepted
Date: 2026-09-24

## Context
P05/P06 show progress percent, queue position, estimated wait, a "glimpse" of
lyric lines before the audio is ready, and Cancel. PRD §6.3's
`GET /v1/jobs/{id}` returns only `status, audio_url, lyrics, structure,
error_code`.

## Decision
Additive, backward-compatible contract fields (all optional, client degrades
when absent):

| Field on `GET /v1/jobs/{id}` | Meaning |
| --- | --- |
| `progress` (0–1) | Server estimate; absent → client animates on `eta_seconds`. |
| `queue_position` (int ≥ 1) | Present only while `status == queued`. |
| `eta_seconds` (int) | Remaining time estimate. |
| `lyrics_preview` (string[]) | Up to 12 lines (P05 shows pages of 4 with page dots) as soon as lyrics are written. |
| `balances` | `{songs_left, clips_left}` after a terminal state (ADR-0011). |

`DELETE /v1/jobs/{id}` cancels a queued or running job. Per PRD §8.4 a
user-initiated cancel after the job has started is **not refunded**; a cancel
while `queued` is refunded. The response carries the updated balances.

## Consequences
The mock implements every field and both cancel outcomes. Old servers still
work: the page shows the ETA-driven progress and no queue banner.

## Amendment (2026-09-27) — platform review
The platform repo accepted the extensions with three changes, now in
`docs/songlet/backend-contract.md`:
- `queue_position` is never sent. `GenerationWaiting.isQueued` now follows the
  status alone, and the P06 `QueueBanner` leaves the position stat out when it is
  unknown (ETA only).
- A cancel on a finished job answers `49309` / `JOB_ALREADY_FINISHED`, on HTTP 200
  like every 49300–49349 business code (platform, 2026-09-28). The client
  matches the string: the generating page shows a note ("It already finished")
  instead of an error and keeps polling, which opens the song.
- Signed audio URLs live 1 h (objects 24 h). The client already downloads on
  success and re-reads the job for WAV at save time, so no URL is reused.
