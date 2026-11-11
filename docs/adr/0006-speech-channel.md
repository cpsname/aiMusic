# ADR-0006 — On-device speech on a channel beside the Pigeon bridge
Status: Accepted
Date: 2026-09-24

## Context
P03a adds voice input with live transcript and level meter, labelled "On-device
transcription". The PRD §6.4 Pigeon interface is fixed verbatim and has no speech
methods. Streaming partial results and audio levels also fit an event stream
better than request/response.

## Decision
- A separate `songlet/speech` MethodChannel (`start(locale)`, `stop()`,
  `cancel()`, `availability(locale)`) and `songlet/speech/events` EventChannel
  (`{partial, level, final, error}`), implemented in
  `ios/Runner/Songlet/SpeechService.swift` with `SFSpeechRecognizer`,
  `requiresOnDeviceRecognition = true`, and `AVAudioEngine`.
- The share-card encoder already uses the same pattern (`songlet/share_card`).
- Dart side: `SpeechGateway` domain port in songlet_kit, `ChannelSpeechGateway` in
  data, bound in the providers file; tests use a fake gateway.
- Unsupported locale or no on-device model → the mic shows an error message, and
  audio never leaves the device (no server fallback).
- Info.plist gains `NSMicrophoneUsageDescription` and
  `NSSpeechRecognitionUsageDescription` in all 13 localisations.

## Consequences
The Pigeon file stays identical to PRD §6.4. A later PRD revision can move speech
into Pigeon without changing `SpeechGateway` callers.
