# ADR-0022 — The automatic video after a song (path 2)
Status: Accepted
Date: 2026-09-29

## Context
Task item 1c/2d: the create page can ask for a video along with the song — the
free lyric video (L2), and on Premier a "song + chorus video" bundle — without
going through the hub, then offer to upgrade the lyric video to a chorus video.

## Options
a) Chain the video inside `GenerationController` after the song succeeds.
b) A separate `AutoVideoCoordinator` that listens for finished songs.

## Decision
b. The song flow is untouched. The intent is stored on the work
(`Work.autoVideo`: none · lyric · chorus, works schema v4, ADR-0028; not synced
to iCloud — it is this device's intent, not part of the song). The coordinator
is started with the app (`StartupGate`) and:
- on a finished song with `lyric`, submits the free lyric video at once
  (source `auto_l2`);
- on `chorus` (Premier only; the panel shows it Premier-gated), runs a 10 s
  local countdown the user can cancel from the player banner (P23); nothing is
  charged before it ends; then submits the chorus video;
- on launch, starts a lyric video the app was closed before starting; a
  **chorus** intent found after a restart is dropped, never started — it costs
  credits and the user would not see the countdown.
The `client_ref` is derived from the work and level (UUID v5), so a second
start is answered by the platform's idempotency. After a submit the intent is
cleared; a refusal clears it; a transport failure keeps a lyric intent for the
next launch. Template default (P28): the lyric video starts on for templates
whose songs are made to be posted (soundtrack, brand, festival occasions).

The automatic chorus video is recorded with source `library` (the task lists
three sources: library · auto_l2 · upgrade; an explicit create-page choice is
closest to `library`). The upgrade entry on a finished lyric video opens the
hub on the chorus level with `from=<lyric video>` and records `upgrade`.

## Consequences
- Coordinator work that changes its state is deferred to a microtask: provider
  listeners can fire while a page builds.
- The countdown step is injectable (`autoVideoTickProvider`) for tests.
