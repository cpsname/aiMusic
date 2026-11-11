# ADR-0010 — "Add to Music" uses the system share sheet; WAV via `wav_url`
Status: Accepted
Date: 2026-09-24

## Context
F09 promises downloads "to Files or Music" and P11 shows "Add to Music".
iOS has no public API that imports a local audio file into the user's Music
library: `MPMediaLibrary.addItem(withProductID:)` only accepts Apple Music
catalogue IDs. P11 also offers WAV for Premier, which PRD §6.3 does not expose.

## Decision
- "Add to Music" opens the system share sheet
  (`UIActivityViewController`) with the ID3-tagged MP3 and its cover. The user
  picks a music app (GarageBand, a player, AirDrop to a Mac for Music.app). The
  row subtitle says "Open in a music app" so it doesn't promise a Music library
  import.
- "Save to Files" keeps the existing folder export (MP3 + lyrics + license PDF).
- WAV: the full-song job for a Premier account returns `wav_url` next to
  `audio_url` (contract extension, `docs/songlet/backend-contract.md`). The
  client downloads it only on request. Non-Premier accounts see the WAV row
  as disabled with an upgrade action.

- P10's share targets show Messages, Instagram and TikTok logos. Posting
  straight into Instagram Stories or TikTok needs their SDKs and app IDs
  (third-party SDKs are excluded, PRD §6.2), and showing their marks needs
  brand approval. The row offers **Share** (system share sheet: Messages,
  Instagram, TikTok and every installed app appear there with their own
  icons), **Save video** (Photos, add-only permission) and **Copy lyrics**.

## Consequences
No private API use (App Review 2.5.1). If Apple adds an import API, only the
native export service changes.

## Amendment (2026-09-27) — WAV behind a switch
The platform renders WAV only after lyria-3.5 passes its WAV probe; until then
`wav_url` is absent on every job. So as not to sell or show a feature that does
not exist yet, WAV is gated by the remote-config switch `config.wav_export`
(default off, `RemoteFlags.wavExport` in `lib/ui/common/remote_flags.dart`):
while off, the download page has no WAV row and the paywall lists "MP3 download"
for Premier instead of "MP3 + WAV download". With it on, a Premier user whose song
has no WAV render (made before WAV, or past the 24 h the file is kept) sees
"There's no WAV file for this song…", never the Premier paywall. The switch is
contract v2 §7 item 8, agreed on 2026-09-28: the key does not exist until the
probe passes and ships together with `wav_url`, so no client release is needed
to turn WAV on.
