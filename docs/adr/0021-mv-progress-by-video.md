# ADR-0021 — Music-video progress follows the video, not the hub session
Status: Accepted
Date: 2026-09-29

## Context
ADR-0020 ran a video inside the single `MvController` session: the progress page
read the controller, and while a video rendered the controller was "busy". That
cannot express a video resumed after a restart, the automatic video of a song
(ADR-0022), or two videos at once (the plan's high-risk item ③: a lyric video
still being made while the user orders a chorus video). It also locked the hub:
while a 10-minute chorus video rendered, no other level could be priced or made.

## Options
a) One controller per video (`NotifierProvider.family`).
b) Keep one hub session; publish every poll of every run on the shared runner,
   and let pages follow a video by id.

## Decision
b. `MvRunner` publishes each snapshot on a per-video bus (`snapshots(videoId)`)
and keeps `latest(videoId)` while the run lasts; `mvProgressProvider(videoId)`
yields the latest then every new one, whichever path runs the video (the hub,
the automatic video, the library's resume). The progress page (P24/P25) is
`MvGenerateRoute(workId, videoId)`; it reads the stored video and the bus, never
the session. The id is the request's `client_ref`, known before the platform
answers, so the page can show the upload / submit steps too.

`MvController` is the hub session only: pricing, submitting, the credit gap
(ADR-0023). A submitted video is not "busy": the session writes a run's
snapshots and outcome only while it still follows that video; once the hub
prices again or makes another video, the earlier run goes on without writing
the session. Cancellation is per video (`cancelVideo(videoId)`) and works for a
video this session did not start. Submitting is shared with the automatic path
through `MvLauncher` (idempotency, retries, the stored record, the ETA
notification in one place).

## Consequences
- Several videos can be made at once; the runner's `_running` set already
  prevented a second poller for the same video.
- Deleting a work abandons its videos' runs (`MvRunner.abandon`): the run stops
  at its next poll and never writes the video back; the local record and file
  are removed. The platform job is not cancelled by a delete (a delete is not a
  cancel request); what it charged stays charged.
