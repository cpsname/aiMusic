# Songlet — acceptance run (PRD §13.2 + §12.4)

How the client is verified end to end on the iOS simulator against the dev mock
backend, what each check covers, and the one step that needs a StoreKit
environment.

## Run it

```sh
make mock                       # terminal 1: mock backend on :8787 (docs/songlet/backend-contract.md)
make acceptance SIM=<udid>      # terminal 2: builds with config/mock.json, runs RunnerUITests
```

`config/mock.json` is git-ignored — `cp config/mock.example.json config/mock.json`.
Debug builds honour `SONGLET_RESET_LOCAL=1` (a "new iPhone": Keychain identity,
preferences and local library wiped at launch — `DebugLaunchReset.swift`, not in
Release). The mock's `/__admin/*` endpoints drive the server side (clock, failures,
App Store Server Notifications).

## Checks

| Criterion | Test | Covers |
| --- | --- | --- |
| `xcodebuild` succeeds | every run | Runner (Swift bridge + Flutter) builds for the iOS 26.5 simulator |
| Clip generated **and playing within 90 s** of opening | `test01_firstSessionClipPlaysWithin90Seconds` | Create home (P01) → *Birthday Wish* template → form (P03): "Alex" + coffee / hiking / Sunday chips → generating (P05) → 30 s preview (P07) autoplays; measured **29.2 s** open → playing on the final 2026-09-24 run (mock clip latency 8 s; PRD budget for Lyria ≤ 45 s keeps it < 90 s). No paywall at launch; the paywall appears once the first preview finishes (PRD §8.2). |
| Pro purchase → full song → **MP3 exported** | `test02_proPurchaseFullSongExportAndLapse` | Hard paywall (P08) on "Get the full 2-minute song" → Pro → the flow re-reads the ledger on close and continues → 2-min song (P09) generated and autoplayed → *Download* → download page (P11) → *Save to Files* → system Files export sheet → folder `Songlet – For Alex (Birthday)` with the MP3 (120 s, ID3 AI-generated user-text frame), `lyrics.txt`, `license.pdf`; "Saved to Files." confirmed. |
| §12.4 case 1 — Pro 40/100 → 1 song → 39/100 → cancel → period end → 0, works playable | `test02` (continued) | Settings (P14) shows 39 songs / 100 previews; after EXPIRED + 32 days, Settings shows Free · 0 songs and the song still plays from the Library (P12). |
| §12.4 case 2 — pack of 10, failed generation refunded, no month reset | `test03_packRefundedOnFailureNeverExpires` | `UPSTREAM_TIMEOUT` → §6.5 copy on the generating page, ledger back to 10; +31 days → still 10. |
| §12.4 case 3 — refund freezes allowance, playable but not downloadable | `test04_refundLocksDownloadKeepsPlayback` | REFUND → the song opens and plays from the Library; *Download* → P11 shows the `DOWNLOAD_LOCKED` panel; frozen pack credits = 0. |
| §12.4 case 4 — new device restores tier + allowance via `currentEntitlements` | `test05_restoreOnNewDevice` — **skipped headless** | See "StoreKit" below; the server half (a second `app_account_token` syncing the buyer's JWS is linked to the same ledger) is covered by `mock_server/test/ledger_test.dart`. |
| §12.4 case 5, as amended by ADR-0005 — no client region gate; a server `REGION_UNAVAILABLE` reads as a delay, library works | `test06_regionRejectedByServerLibraryWorks` | Launched with the device region set to Russia (`-AppleLocale en_RU`): the template form opens (no client block), the mock refuses the region, the generating page shows the `UPSTREAM_TIMEOUT` copy, and the Library tab still works. |
| F08 share card + F04 photos | `test08_shareCardAndPhotoSong` | *Share preview* → share-card page (P10) → *Share* composes a 1080×1920 H.264/AAC MP4 (30 s) with the "AI generated" badge burned into every frame and opens the system share sheet; back on the create home the picked card is left (photos are free input, ADR-0033), composer **+** → photos page (P04) opens the system PhotosPicker, one photo picked (uploaded JPEG ≤ 1024 px via media_kit's presigned upload) → *Create from photos* → a new preview autoplays. |
| Music video: credit gap → pack → same request, charged once (PRD §15.4, P19 → P20 → P22 → P24 → P26) | `test09_mvQuotaPurchaseRetry` — **added 2026-09-29, not yet run** (see below) | Song page entry → hub prices the three levels (chorus shows "2103 more needed") → *Make video* on the chorus level → the credits sheet (P22) with the recommended pack → *Not now*; the pack is granted server-side → "waiting for credits · Continue" → the same request (same `client_ref`) → progress (P24) → the video (P26); `credits == 66 + 2395 − 2169`. |
| (design review) | `test07_screenshotTour` | Screenshots of the create home, genre panel, form, generating, preview, paywall, library and settings, kept in the result bundle. |

Last full run: 2026-09-24 on the final code, iPhone 17 Pro simulator (iOS 26.5):
7 passed, 1 skipped (`test05`), 0 failed, 410 s; open → first listen 29.2 s.

2026-09-29: `test09` builds (`xcodebuild build-for-testing` succeeded) but was not
run: the host's console was locked (`CGSSessionScreenIsLocked = Yes`), and a locked
console stops the simulator from rendering frames, so neither XCUITest nor
`make integration` can drive the app. Re-run `make acceptance SIM=<udid>` and
`make integration SIM=<udid>` on an unlocked session.

Headless, the paywall has no StoreKit products (see below), so it shows its
empty-catalog state; Restore, Terms, Privacy and Manage stay on the page in that
state too, and the tests assert them.

On-device prompt polishing (SystemLanguageModel) degrades by design when the model
is unavailable: on this simulator host Apple Intelligence is off
(`[PromptPolisher] SystemLanguageModel unavailable: …appleIntelligenceNotEnabled`),
so the raw brief is sent and the backend assembles the prompt as usual.

## StoreKit (the native purchase sheet)

`Songlet.storekit` (the five PRD §8.1 products, Pro yearly with a 7-day free
trial) is attached to the Runner scheme's **Run** action. On this toolchain the
simulator's `storekitd` only serves a StoreKit configuration to an app launched by
an Xcode debug session: for an app launched by XCUITest — and even for
`SKTestSession` created inside the app or a hosted unit test — it answers
"com.songlet.ios is not installed for development" and falls back to the App Store
sandbox, where these product ids do not exist yet. The headless run therefore
applies purchases on the server side (`POST /__admin/grant`, what App Store Server
Notifications V2 SUBSCRIBED / ONE_TIME_CHARGE deliver) after asserting the paywall;
every client step after the purchase is real.

Manual StoreKit checklist (Xcode → Product → Run on a simulator, `make mock` running,
`config/mock.json` in the last `flutter build`):

1. Paywall lists the 5 products with store prices; Pro Yearly shows "7-day free trial ·
   up to 10 full songs during the trial"; subscriptions show price, period, the
   auto-renewal disclosure, Restore, Manage subscription, Terms, Privacy (PRD §8.5).
2. Buy **Pro Monthly** → the full song generates → Settings shows 39 full songs / 100 previews.
3. Debug → StoreKit → Manage Transactions → *Refund* a pack purchase → the app receives
   the revoked transaction (`Transaction.updates` → `onTransactionUpdated`) → Download
   shows the `DOWNLOAD_LOCKED` copy.
5. Music video pack (PRD §15.4): a song page → *Choose a video* → chorus level →
   *Get the pack and make it* → the credits sheet (P22) → *Buy and continue* →
   the StoreKit sheet for `com.songlet.mv.chorus` → on success the sheet closes and
   the same request is sent again (progress page P24, one charge in `GET /__admin/state`);
   cancelling the StoreKit sheet returns to the hub with every option kept.
4. New device: iOS keeps the Keychain across a reinstall, so add
   `SONGLET_RESET_LOCAL=1` to the scheme's Run environment for one launch (new
   `app_account_token`, empty library) → Settings → Restore purchases → tier and
   remaining songs return (`Transaction.currentEntitlements` → `/v1/entitlements/sync`).

For App Store sandbox testing on a device, create the five products in App Store
Connect under `com.songlet.ios`. The app needs no capability (2026-10-04): App
Attest falls back to `unsupported`, which the platform accepts while the
distribution's `attest.mode` is `off` / `optional`.
