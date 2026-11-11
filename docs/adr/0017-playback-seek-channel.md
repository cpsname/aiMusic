# ADR-0017 — Seek and section navigation on a channel beside the Pigeon bridge
Status: Accepted
Date: 2026-09-24

## Context
P07 and P09 scrub the waveform; P09 jumps between song sections (previous /
next) and shuffles sections. The fixed PRD §6.4 bridge offers only
`playAudio(path, loop)` and the progress callback: there is no way to set
the position.

## Decision
- `AudioEngine.seek(seconds)` is part of the playback port; `NativeBridge`
  implements it over a `songlet/playback` MethodChannel (`seek`), handled
  by `AudioPlaybackService` (`AVAudioPlayer.currentTime`, Now Playing
  elapsed time updated). Same pattern as ADR-0006.
- Section logic stays in Dart (`PlayerController`): section windows come
  from the job `structure`; previous restarts a section after 3 s; shuffle
  walks a shuffled section order and follows it when a section ends. The
  lock screen keeps the native previous / next track semantics.

## Consequences
The Pigeon file stays identical to PRD §6.4. Seeking is covered by
PlayerController tests against a fake engine.
