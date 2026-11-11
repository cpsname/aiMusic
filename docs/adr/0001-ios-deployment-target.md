# ADR-0001 — iOS 26.0 deployment target, iOS 26.5 SDK
Status: Accepted
Date: 2026-09-24

## Context
The first brief named iOS 27.0; the toolchain on hand is Xcode 26.6 with the
iOS 26.5 SDK and simulator. The product owner decided "iOS 26.5 SDK + iOS 26.5
就可以" and later confirmed keeping the 26.0 minimum. Features that set the floor:
FoundationModels `SystemLanguageModel` (26.0), SwiftUI `PhotosPicker`, StoreKit 2,
App Attest, SFSpeechRecognizer on-device mode.

## Decision
`IPHONEOS_DEPLOYMENT_TARGET = 26.0`, built against the iOS 26.5 SDK. Every API used
is available at 26.0; no `#available` branches exist for features the PRD requires.
Apple Intelligence remains optional at runtime (the prompt polisher degrades to the
raw text).

## Consequences
Devices that cannot run iOS 26 are out of scope. Raising the floor later is a
one-line project change; lowering it would need availability checks around
FoundationModels.
