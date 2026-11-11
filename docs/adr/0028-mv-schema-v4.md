# ADR-0028 — Works database v4: what a video was asked for, and where from
Status: Accepted
Date: 2026-09-29

## Context
The player lays out a video by its shape and places lyrics by the chorus
window; "Make another" and the retry of a failed video repeat the options; the
task wants each request's source recorded (library · auto_l2 · upgrade).

## Decision
Schema v4 (`SqliteWorkRepository.version = 4`):
- `music_videos` gains `aspect_ratio` ('9:16'), `quality` ('standard'),
  `chorus_start_ms`, `chorus_end_ms`, `source` ('library'), `photo_count` (0).
  The migration adds only the columns a table lacks (a v2 → v4 upgrade creates
  the table at the current shape in its v3 step).
- `works` gains `auto_video` ('none'), ADR-0022.
`source` is sent on the wire only once the contract has the field
(`MvRequest.sendsSource`, gap G6); until then it is local.

The plan listed a `credits_refunded` column; it was dropped: the terminal
`balances` carry songs and clips, not credits, so the refund cannot be derived
without the client doing arithmetic on the ledger. P25 states what the platform
refunded — the charged credits of a video that failed with a refunded code.

## Consequences
Deleting a work deletes its videos' rows and files (ADR-0021).
