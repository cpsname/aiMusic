# songlet_mock_server

Dev-only mock of the Songlet backend, implementing
[`docs/songlet/backend-contract.md`](../docs/songlet/backend-contract.md) so the
app can be driven end to end on the simulator without the Go monolith or
Lyria. Pure Dart (`dart:io`), in-memory state with optional JSON persistence.
**Never shipped**: no app package depends on it.

## Run

From the repo root (after `flutter pub get`):

```sh
dart run songlet_mock_server:server                 # :8787
dart run mock_server/bin/server.dart --port 8787 --state-file /tmp/songlet-mock.json
PORT=9000 SONGLET_MOCK_SECRET=xyz dart run songlet_mock_server:server
```

| Setting | Default | Notes |
| --- | --- | --- |
| `--port` / `PORT` | `8787` | binds `0.0.0.0` (simulator + LAN devices) |
| `--state-file` | none | persists accounts, ledger, jobs, uploads, clock offset, config |
| `SONGLET_MOCK_SECRET` | `songlet-mock-secret` | HMAC app-signature secret **and** JWT key |
| `SONGLET_MOCK_DISTRIBUTION_CODE` | `songlet_ios` | expected `X-Distribution-Code` |

App config (`config/dev.json`): `BASE_URL=http://localhost:8787/v1`,
`DISTRIBUTION_CODE=songlet_ios`, `DISTRIBUTION_SECRET=songlet-mock-secret`.

Every request is logged as one line: `METHOD path status ms [error_code]`.

Smoke test against a running server (signs exactly like `infra_core`):

```sh
dart run mock_server/tool/happy_path.dart --reset    # attest → clip → Pro sync → song → license
```

Tests: `cd mock_server && dart test` · lint: `dart analyze mock_server`.

## What it serves

| Route | Signed | Bearer | Notes |
| --- | --- | --- | --- |
| `GET /v1/app/config` | ✓ | – | `{maintenance, kill_switches, config}` (admin-controlled) |
| `POST /v1/attest` | ✓ | – | `unsupported:true` accepted (dev); challenge `<token>.<unix_ms>.<uuid>`, single use, ±5 min → HS256 `{sub, abid, typ:"device", iat, exp}` |
| `POST /v1/generate` | ✓ | ✓ | validation → idempotency → region → images → safety → charge → job |
| `GET /v1/jobs/{id}` | ✓ | ✓ | `{job_id, status, progress, eta_seconds?, lyrics_preview?, audio_url?, wav_url? (Premier songs, only with `wav_enabled`), lyrics?, structure?, error_code?, balances? (terminal)}` — never `queue_position`, like the platform |
| `DELETE /v1/jobs/{id}` | ✓ | ✓ | v2 cancel: queued → refunded; running → charge kept; job → `failed` + `USER_CANCELLED`; finished → `49309` `JOB_ALREADY_FINISHED` |
| `GET /v1/templates` | ✓ | ✓ | v2: `{templates:[{id, sample_url, duration:30}]}` for the 16 create-home templates |
| `POST /v1/entitlements/sync` | ✓ | ✓ | decodes JWS payloads (no x5c check) → `{tier, songs_left, clips_left, reset_at}` |
| `GET /v1/license/{id}` | ✓ | ✓ | `application/pdf` + `X-License-Id` / `X-License-Issued-At`, or `DOWNLOAD_LOCKED` (free tier / refunded funding purchase) |
| `POST /v1/uploads/sign` · `/finalize` | ✓ | ✓ | media_kit two-stage presigned upload; `put_url = http://<host>/r2/<bid>` |
| `POST /v1/mv/estimate` | ✓ | ✓ | v1.1: price of a level for a `succeeded` song (lyric 0 · chorus 2169 · full 69/s), `available_credits`, gap, `recommended_product_id`, `song_locked` |
| `POST /v1/works/{job}/mv` | ✓ | ✓ | v1.1: validation → idempotency → song (24 h) → photos → credit charge (`QUOTA_EXHAUSTED` + `QuotaExhaustedDetails`) → staged run |
| `GET /v1/mv/{id}` | ✓ | ✓ | v1.1: `{mv_id, level, status, stage, progress (real: completed steps / scenes), segments? (rendering), cancel_requested, eta_seconds?, video_url?, duration_ms?, ai_label: burned_in, error_code?, balances? (terminal)}` |
| `DELETE /v1/mv/{id}` | ✓ | ✓ | v1.1: queued → `cancelled` + full refund; running → `cancel_requested`, honoured at the next scene (finished steps charged, rest refunded, then `failed` + `USER_CANCELLED`) |
| `GET/HEAD /files/{mv}.mp4` | – | – | the 15 s badge-burned fixture (`video/mp4`, Range) of a `succeeded` video |
| `PUT /r2/{bid}` | – | – | raw bytes; `Content-Type` must equal the signed MIME (else 403); 200 empty |
| `GET/HEAD /files/{job}.mp3` | – | – | fixture MP3 (`audio/mpeg`, `Content-Length`, HTTP `Range`); songs also `.wav` |
| `GET /files/samples/{template}.mp3` | – | – | template sample (the 30 s clip fixture) |
| `GET /files/uploads/{bid}` | – | – | uploaded bytes |

Transport details: envelope `{code, message, data, details, request_id, timestamp}`
on every JSON response; HTTP status = `code ~/ 100`; Songlet errors carry the PRD
§6.5 string in `details.error_code`; `X-Server-Time` (Unix ms, **mock clock**) on
every response. Signature failures: `40110` missing headers, `40111` bad
timestamp, `40112` outside ±5 min, `40113` nonce replay, `40114` bad
HMAC/distribution (HTTP 401, `details: null`). Any bearer problem → `40102`.

Music-video timing (real time, `mv_delay_ms`, default 12 s): `queued` →
`slicing` → `storyboarding` → `keyframing` → `rendering` (one step per scene:
3 for a chorus, one per 15 s slice up to 12 for a full song; none for a lyric
video) → `assembling` → `succeeded`. `progress` moves only when a step finishes.

Job timing (real time): `queued` → `running` (after ¼ delay, max 1 s) →
`succeeded` after `clip_delay_ms` (8000) / `song_delay_ms` (15000). Lyrics are
templated in `lyric_language` (en ja pt es de fr ko hi id vi tr zh, fallback en)
from the `prompt` block, or echo the request's `lyrics`. The draft lyrics are written at
generate time, so `lyrics_preview` (first 12 lines) appears once a running job
is 30 % through. `progress` is a monotonic 0–1 estimate from elapsed real time.
`/v1/generate` validates the optional `template` against the 16 ids (→ `40001`).
The full v2 contract (and the change set for the platform repo) is in
`docs/songlet/backend-contract.md` §7.

Audio fixtures (`assets/`) are synthesized by `tool/make_fixtures.sh` (ffmpeg,
no samples): `clip_30s.mp3` (30 s), `song_120s.mp3` + `song_120s.wav` (120 s),
44.1 kHz stereo, 96 kbps.

## Admin API (no signature, JSON envelope)

```sh
A=http://localhost:8787/__admin
curl -XPOST $A/reset
curl -XPOST $A/config -d '{"clip_delay_ms":2000,"song_delay_ms":4000}'
curl -XPOST $A/config -d '{"wav_enabled":true,"remote_config":{"wav_export":true}}'   # WAV on: server renders + app offers it
curl -XPOST $A/config -d '{"attest_fail":true}'
curl -XPOST $A/config -d '{"maintenance":{"active":true,"message":"Back soon","resume_at":1790000000000},"kill_switches":["iap_purchase"],"remote_config":{"promo_text":"hi"}}'
curl -XPOST $A/config -d '{"token_ttl_seconds":60}'          # force 40102 → re-attest quickly
curl -XPOST $A/fail_next -d '{"error_code":"UPSTREAM_TIMEOUT"}'
curl -XPOST $A/advance_clock -d '{"days":31}'                  # also hours / minutes
curl -XPOST $A/notify -d '{"notification_type":"REFUND","transaction_id":"2000000123"}'
curl $A/state                                                  # accounts (+computed status), transactions, jobs, uploads
```

`config {"inspirations_enabled": false}` drops `inspirations` from `GET /v1/templates`
(an older server); on by default, with the product repo's 24 seed entries
(`lib/src/inspirations.dart`) and previews served by the mock.

`fail_next` codes:

| Code | Effect on the next `/v1/generate` |
| --- | --- |
| `UPSTREAM_TIMEOUT` | job `running` + `error_code: UPSTREAM_TIMEOUT` after 1× delay, then `failed` after 2× delay; refunded |
| `UPSTREAM_RATE_LIMITED` | job `queued` + `error_code: UPSTREAM_RATE_LIMITED` for 1× delay, then runs and succeeds (charged) |
| `SAFETY_BLOCKED` / `IMAGE_REJECTED` | job fails after 1× delay; refunded |
| `QUOTA_EXHAUSTED` / `REGION_UNAVAILABLE` / `ATTEST_FAILED` | the generate call itself is rejected (nothing charged) |

On the next music video (`POST /v1/works/{id}/mv`) instead: `QUOTA_EXHAUSTED`,
`MV_SONG_NOT_READY`, `MV_SONG_TOO_LONG`, `MV_SONG_EXPIRED`, `MV_PHOTOS_EXPIRED`
reject the request (nothing charged); `MV_RENDER_FAILED`, `UPSTREAM_TIMEOUT`,
`IMAGE_REJECTED`, `SAFETY_BLOCKED` fail the video at its first rendered scene
(or at assembling for a lyric video), fully refunded — `IMAGE_REJECTED` is the
segment-level photo rejection of docs/ui P25. A code applies to whichever of
the two calls comes first.

`notify` (App Store Server Notifications V2 emulation) takes `transaction_id`
and/or `original_transaction_id` (ids are listed by `GET /__admin/state`):
`REFUND` revokes that transaction (or the whole chain when
`original_transaction_id` is given); `EXPIRED` ends the subscription chain now;
`DID_RENEW` appends a renewal transaction `<original>.r<n>` for the next period.

## `demo` profile (App Store previews)

```sh
dart run mock_server/bin/server.dart --profile demo --demo-manifest store_preview/songlet/media/manifest.json
curl -XPOST $A/demo -d '{"script":"A","locale":"ja"}'      # the song the next job makes
curl -XPOST $A/demo -d '{"manifest":"/abs/manifest.json"}'  # switch on at runtime ({"manifest":null} = off)
curl $A/demo
```

For the preview recordings (`store_preview/songlet`, `lib/src/demo.dart`; the manifest is
schema 2, packages/store_preview ADR-0008). While
a song is selected, a generate job:

- runs straight to `running` (no queue banner);
- succeeds after `demo_delay_ms` (default 4000; `POST /__admin/config`) while
  its reply announces the real `eta_seconds: 45` ("Usually about 45 seconds");
- carries the manifest song's lyrics (also the glimpse) and section timing;
- serves its MP3, with WAV rendered from it by ffmpeg when offered.

A lyric video made from such a song serves that storefront's platform-rendered
video from the manifest. The fixtures are never served for a demo job. `reset`
keeps the profile (a server setting), so a recording can reset between takes.

`advance_clock` moves the mock clock (JWT expiry, subscription periods, yearly
monthly windows, `X-Server-Time`). The app then sees one `40112` (its
`ClockSyncInterceptor` re-signs with the learned offset) and a `40102` once its
device token has expired (re-attest).

## PRD §12.4 commercial test cases

| Case | Steps |
| --- | --- |
| Pro monthly 40/100 → 39/100 → lapse | buy `com.songlet.pro.monthly` (Xcode StoreKit config) → app syncs → `pro 40/100`; generate a song → `39/100`; cancel renewal, then `advance_clock {"days":31}` (or `notify {"notification_type":"EXPIRED","original_transaction_id":"<id>"}`) → re-sync → `free`, `songs_left 0`; `/v1/jobs/{id}` + audio still work |
| Pack refund on failure, no expiry | buy `com.songlet.pack.10` → `fail_next {"error_code":"UPSTREAM_TIMEOUT"}` (or `SAFETY_BLOCKED`) → generate a song → `9` while running, back to `10` after the job fails; `advance_clock {"days":31}` → still `10` |
| Refund | `notify {"notification_type":"REFUND","transaction_id":"<id>"}` → the purchase's remaining credits freeze; `/v1/license/{job}` → 403 `DOWNLOAD_LOCKED`; `/v1/jobs/{job}` and `/files/{job}.mp3` still serve |
| Restore on a new device | second simulator / reinstall (new `app_account_token`) → attest → sync the `currentEntitlements` JWS (whose `appAccountToken` is the buyer's) → the new token is linked to the buyer's account: same tier + remaining; `GET /__admin/state` lists it under `linked_tokens` |
| Region | set the simulator region to e.g. Russia (`X-Device-Region: RU`) or use a CHN/RUS/HKG storefront → `/v1/generate` → 451 `REGION_UNAVAILABLE`; the library (`/v1/jobs`, `/files`) keeps working |

## Ledger rules implemented

Free: 3 lifetime clips. Pro 40 songs + 100 clips per period (T2/T3 storefronts
BRA MEX IDN VNM TUR IND: 25 + 60); Premier 120 + 200; yearly resets monthly
from `originalPurchaseDate` without rollover; yearly trial (`offerType == 1`)
capped at 10 songs. Packs +10/+50, never expire, consumed after the
subscription, keyed by `transactionId` (re-syncs never re-credit). Charge at job
creation, any job failure refunds the same bucket. `revocationDate` / `REFUND`
freezes the transaction; works stay playable, their license is locked. A synced
transaction owned by another account links the caller's token to that account
(its prior usage is merged).
