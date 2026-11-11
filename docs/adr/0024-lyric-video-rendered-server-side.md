# ADR-0024 — The lyric video (L2) stays rendered server-side
Status: Accepted
Date: 2026-09-29

## Context
The task asked for on-device L2 rendering (Pigeon + AVAssetWriter + Core
Animation, cover from the backend). PRD §15.10 D-3, platform X-47/X-53 and
contract v1.1 (`level: lyric_video`, 0 credits) render it on the server. On-device
rendering would also lack two inputs: a cover/storyboard endpoint (gap G3) and a
word-level timeline (the client only splits section windows evenly; the
platform's ASR timeline stays in the platform).

## Decision
Keep the server-side lyric video (decision D-1 of the confirmed plan). It is the
same task model as the other levels (ADR-0021) and is made automatically by
path 2 (ADR-0022).

## Consequences
No new native renderer. If the platform ever exposes a cover and a timeline, an
on-device renderer would be a new side channel beside the frozen Pigeon bridge.
