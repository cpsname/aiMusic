# Songlet backend contract (client view) — v2 (+ music videos, v1.1)

Source of truth: PRD §6.3 (endpoints), §6.5 (error codes), §8.4 (ledger), plus
the v2 extensions the UI prototypes (docs/ui P01–P18) need — each one backed by
an ADR and listed as a change set in §7. The platform repo reviewed §7 on
2026-09-27 (items 1, 4, 5, 6 as proposed; 2, 3, 7 amended — folded in below);
§7 item 8 is the client's follow-up to that review, agreed on 2026-09-28.
Songlet is a new `songlet` bounded context inside the **existing Go monolith**
(PRD §6), so every call follows the monolith's transport conventions the
template already implements in `infra_core` — this document only pins what PRD
§6.3 leaves open. The dev mock (`mock_server/`) implements exactly this.

## 1. Transport (unchanged monolith conventions)

- Base URL: `BASE_URL` (mock: `http://localhost:8787/v1`).
- App signature on **every** request (`infra_core` `SignatureInterceptor`):
  `X-Distribution-Code`, `X-Timestamp` (Unix s), `X-Nonce` (UUID v4),
  `X-App-Signature = hex(HMAC_SHA256(secret, timestamp + nonce + canonicalJson(body)))`,
  empty body → `{}`, keys sorted recursively.
- Response header `X-Server-Time` (Unix ms) on every response (clock-skew sync).
- Envelope on every JSON response:
  `{ "code": 0, "message": "ok", "data": {...}, "details": {...}|null, "request_id": "...", "timestamp": <ms> }`.
  `code == 0` is success. Business errors carry a non-zero numeric `code` **and**
  the PRD §6.5 string in `details.error_code`. HTTP status (platform,
  2026-09-28): the 49300–49349 business codes ride on **HTTP 200**; `40140`,
  `4011x` and `40102` on **401**; the other rows of §4 keep the HTTP status listed
  there until the platform confirms them. The client reads the envelope on
  every status (`EnvelopeInterceptor` handles a 200 with a non-zero `code` and an
  error status with an envelope body alike), so no behaviour depends on it.
- Device meta headers (`X-Device-ID`, `X-Platform`, `X-App-Version`, `X-Language`,
  `X-Timezone`, …) as sent by `DeviceHeadersInterceptor`.
- Songlet headers (added by the songlet client): `X-Storefront` (StoreKit
  storefront, ISO alpha-3, may be empty) and `X-Device-Region` (ISO alpha-2 from
  the device locale).

Hosts: the Songlet endpoints are served by the product backend
(genaistudio-products.showsapp.org, `songlet` BC, the client's `BASE_URL`),
which calls the platform's shared capabilities itself. `GET /v1/app/config`
goes to the platform (genaistudio.showsapp.org, `PLATFORM_BASE_URL`), by the
product owner's decision of 2026-10-02. The
product backend's distribution gate runs first: an unknown
`DISTRIBUTION_CODE` gets envelope code `40404` on every path (signature-only
paths such as `/attest` and `/app/config` show it at once; login paths answer
"missing bearer" first and `40404` after login).

## 2. Identity (PRD §6.3 "鉴权：无账号")

- `app_account_token` = the device's persistent Keychain UUID (`X-Device-ID`).
  It is the StoreKit 2 `appAccountToken` for every purchase.
- `POST /v1/attest` (no bearer) — body:
  ```json
  { "app_account_token": "<uuid>", "challenge": "<string>",
    "key_id": "<base64>", "attestation": "<base64>"?, "assertion": "<base64>"?,
    "unsupported": true? }
  ```
  `challenge` = `<app_account_token>.<unix_ms>.<uuid>` (single-use, ±5 min).
  First call on a device sends `attestation` (DCAppAttestService.attestKey),
  later calls send `assertion`. `unsupported: true` = device without App Attest
  (simulator) — accepted only when the server runs in dev mode.
  → `data: { "device_token": "<JWT>", "expires_in": 86400 }`.
  `device_token` is an HS256 JWT `{ sub, abid, typ:"device", iat, exp }` where
  `abid == app_account_token` (the client reads `abid` for `appAccountToken`).
- All other `/v1/*` calls send `Authorization: Bearer <device_token>`.
  Expired token → `40102` (client re-attests via `assertion` and replays);
  unrecoverable → `40106`.

## 3. Endpoints (PRD §6.3)

| Method | Path | Request | `data` |
| --- | --- | --- | --- |
| POST | `/v1/generate` | `{model, occasion, inspiration?, region, prompt, lyrics?, images?[], client_ref}` (contract 02 v2.1: these eight only; others ignored) | `{job_id, eta_seconds, credits_charged}` |
| GET | `/v1/jobs/{job_id}` | — | `{job_id, status, progress, eta_seconds?, lyrics_preview?, audio_url?, wav_url?, lyrics?, structure?, error_code?, balances?}` |
| DELETE | `/v1/jobs/{job_id}` | — | `{job_id, refunded, balances}` (v2) |
| GET | `/v1/templates` | — | `{templates: [{id, sample_url, duration}], inspirations?: [Inspiration]}` (v2; `inspirations` v1.2) |
| POST | `/v1/entitlements/sync` | `{app_account_token, signed_transactions[]}` | `{tier, songs_left, clips_left, reset_at}` |
| POST | `/v1/attest` | see §2 | `{device_token}` |
| GET | `/v1/license/{job_id}` | — | raw `application/pdf` + headers `X-License-Id`, `X-License-Issued-At` (errors: JSON envelope) |
| POST | `/v1/mv/estimate` | `{job_id, level}` | `{level, credits, available_credits, affordable, gap_credits, recommended_product_id, song_locked}` (v1.1) |
| POST | `/v1/works/{job_id}/mv` | `{level, aspect_ratio?, quality?, subtitles?, photo_bids?[], chorus?{start_ms,end_ms}, client_ref}` | `{mv_id, eta_seconds, credits_charged}` (v1.1) |
| GET | `/v1/mv/{mv_id}` | — | `{mv_id, level, status, stage?, progress, segments?{done,total}, cancel_requested, eta_seconds?, video_url?, duration_ms?, ai_label?, error_code?, balances?}` (v1.1) |
| DELETE | `/v1/mv/{mv_id}` | — | `{mv_id, outcome: cancelled\|cancel_requested, refunded, balances}` (v1.1) |

Field details:

- **Contract 02 v2.1 (2026-10-04, ADR-0032)** supersedes the `template` field below:
  the scene is `inspiration: <slug>` at the top level **and** as the block's first
  line (they must match; a built-in template is sent by its id, which the server
  lists as a scene); `occasion` is the scene's; `description` carries only the
  user's own text; `vocals` and `lyric_language` are always present; each key at
  most once; `note` ≤ 600; an instrumental takes no `lyrics`. 40001
  `details.inspiration` = unknown scene / wrong occasion / block mismatch.

- `model`: `lyria-3-clip-preview` (30 s clip) | `lyria-3.5` (≈2 min full song).
- `occasion`: `birthday|anniversary|confession|wedding|memorial|festival|brand|soundtrack|custom`.
  `custom` (v2) = the free-form composer on the create home (no template).
- `template` (v2, optional): the create-home template the draft started from —
  `birthday_wish birthday_party love_story thank_a_friend party_invite wedding
  in_memory festival ringtone team_anthem sports_recap rap_battle comedy
  pet_anthem hometown business_promo`. Each maps to one `occasion` (ADR-0008);
  the server may use it to pick the §7.2 template variant. Unknown → `40001`
  validation error.
- `region`: ISO alpha-2 of the PRD §7.3 preset country (`US GB CA AU DE FR JP KR BR MX IN ID VN TR`).
- `prompt`: the user-side block; the server assembles the §7.2 template around it.
  Line-oriented `key: value`, UTF-8:
  ```
  inspiration: soundscape     (v2.1, when the draft started from an inspiration; then no `template`)
  template: birthday_wish     (v2, when the draft came from a template)
  recipient: Alex             (optional for templates that do not name anyone)
  keywords: coffee | hiking | Sunday
  description: <free-form composer text, ≤ 300 chars>   (v2, composer only)
  genre: Pop                  (omitted = "let the model choose")
  vocals: vocals              (v2: custom | vocals | instrumental)
  lyric_language: en
  festival: diwali            (festival occasion only)
  photos: 3                   (photo songs: number of attached images)
  note: <on-device polished description, may be empty>
  ```
  Genres (v2, 18, all selectable in every region — ADR-0005): `Pop`,
  `Hip-Hop & Rap`, `Rock`, `K-Pop`, `Latin`, `Electronic`, `R&B`, `Country`,
  `Afrobeats`, `Reggae`, `Jazz & Blues`, `Classical`, `Folk`, `Lo-Fi`,
  `Acoustic`, `Cinematic`, `Ambient`, `Bossa Nova`. `vocals: instrumental` means
  no sung lyrics: return `lyrics` empty and no lyric sections.
  At least one of `recipient`+`keywords`, `description`, user `lyrics` or
  `photos` is present (client preflight).
- `lyrics`: user lyrics with `[Verse]` / `[Chorus]` section tags (≤1200 chars, ≤600 CJK).
- `images`: up to 10 asset `bid`s from the monolith upload flow
  (`POST /v1/uploads/sign` → `PUT` → `POST /v1/uploads/finalize`, media_kit),
  JPEG ≤ 1024 px long side. `lyria-3-clip-preview` is text-only (PRD §5), so a
  photo clip is routed server-side to `lyria-3.5` with a "Duration 30 seconds"
  constraint (PRD §14.1); the client always sends the product-level `model`.
- `client_ref`: client UUID; the call is idempotent per `(app_account_token, client_ref)`.
- `status`: `queued | running | succeeded | failed`.
  `error_code` may be present on a non-terminal job as a hint
  (`UPSTREAM_RATE_LIMITED` = queued behind rate limit, `UPSTREAM_TIMEOUT` = retrying).
- `progress` (v2): `0.0–1.0`, monotonic; drives the P05 progress ring.
- `eta_seconds` (v2): remaining seconds while not terminal.
- `queue_position`: **never sent** (platform decision). The client shows the P06
  queue banner from `status: queued` with the ETA only, and would show a
  position again should one ever be sent.
- `lyrics_preview` (v2): up to 12 lyric lines (no section tags) once they are
  written — may appear while `running`; drives the P05 "glimpse" card.
- `balances` (v2): `{songs_left, clips_left}` on a terminal job, so the client
  mirrors the ledger without another sync call (ADR-0011).
- `audio_url`: absolute URL of the MP3. **The URL is valid 1 h; the object is kept
  24 h.** Every `GET /v1/jobs/{id}` returns a freshly signed URL. The client
  downloads the MP3 the moment the job succeeds (and a resumed job re-polls for a
  fresh URL), so it never reuses an old one.
- `wav_url` (v2): absolute URL of a 44.1 kHz WAV, full songs of a Premier
  account only — and **absent on every job until the platform's lyria-3.5 WAV
  probe passes**. Same 1 h URL / 24 h object policy; the client re-reads the job
  at save time for a fresh URL. While WAV is off the client neither shows the WAV
  row nor lists WAV as a Premier benefit — see `config.wav_export` below.
- `lyrics`: string, one line per lyric line, section tags on their own line (`[Chorus]`).
- `structure`: `[{ "section": "Intro", "start": 0.0, "end": 3.0 }, …]` seconds.
- `tier`: `free | pack | pro | premier`. `pack` = no active subscription but an
  unrefunded song pack was bought.
- `songs_left` = subscription allowance left this period + pack songs left.
- `clips_left` = subscription clip allowance left, or the lifetime free clips left.
- `reset_at`: ISO-8601 UTC of the next allowance reset, or `null`.
- `DELETE /v1/jobs/{job_id}` (v2, ADR-0012): cancels a job. Cancelled while
  `queued` → the charge is refunded (`refunded: true`); once `running` → the
  charge stays (`refunded: false`, PRD §8.4 "user cancel is not refunded").
  The job then reads `status: failed, error_code: USER_CANCELLED`. An already
  finished job → `49309` / `JOB_ALREADY_FINISHED` (§4): the client tells the user
  the song is already done and keeps polling, which opens it.
- `GET /v1/templates` (v2): the 30 s sample clip of every template for the
  create-home play buttons; `sample_url` is absolute and cacheable.
  Contract 02 v1.2 adds optional `inspirations[]` (`{id, slug, name{en,zh},
  style{en,zh}, preview_audio_url, duration_sec?, sort, linked_template_id?}`):
  the create home's Inspiration row (ADR-0029). No ETag / version: fetched once
  per session together with `templates`. `preview_audio_url` is absolute and
  played as given (on its own host, never joined to `BASE_URL`); absent field =
  no row.
- **Contract 02 v2.1, credits** (ADR-0031): everything costs credits (no free
  allowance; a free account's `reset_at` is null; the lyric video costs 57).
  `QUOTA_EXHAUSTED.details.offer` (`subscription` | `packs`) and `offer` on the
  `POST /v1/mv/estimate` response pick the paywall's lead; `recommended_product_id`
  is the preselected pack; with only an `error_code` the plans lead with the packs
  listed too. `com.songlet.pro.weekly` joins the catalog (first-week 50 % off from
  StoreKit's introductory offer).
- **Contract 02 v2.1** (product ADR-S14 / S15; ships with the server): every
  `Inspiration` carries `cover_image_url` (absolute https), `default_model`
  (`lyria-3-clip-preview` | `lyria-3.5`), `composer {hint{en,zh}, input_required}`
  and, as before, `occasion`, `default_vocals`, `suggested_genre`. The create home
  turns a picked card into a tag above the prompt field (hint = `composer.hint`,
  selectors → the defaults, `input_required: false` = sendable with no text) and
  sends `inspiration: <slug>` in the prompt block with the typed text as
  `description:` (ADR-0030). Parsed defensively; absent fields keep the v1.2
  behaviour (the older-server path), so the client works before the release.
- `POST /v1/entitlements/sync` → `credits_available` (int ≥ 0, contract 02 v1.3,
  gap G5): the account's usable credits; always sent by v1.3 servers, optional
  for older ones. The settings "Video credits" row shows only when present.
- `GET /v1/app/config` → `config.wav_export` (bool; §7 item 8): whether WAV
  export is offered. The key does not exist before the WAV probe passes and
  appears together with `wav_url` in the same release. app_config is fail-open,
  so a missing key means off.
- License headers (v2): `X-License-Id` (human-readable, e.g. `SL-20260924-A1B2C3`,
  printed on the P11 license card and in the PDF) and `X-License-Issued-At`
  (ISO-8601 UTC).

### 3.1 Music videos (v1.1, PRD ch.15, ADR-0020)

Source of truth: the platform's `docs/contracts/songlet/02-openapi.yaml` (MV
section) and `04-errors.md` §2 / §3.1. The client (`songlet_kit/src/mv`) and
the mock implement exactly those shapes.

- `level`: `lyric_video` (0 credits: a still scene with the lyrics burned in) |
  `chorus_mv` (30 s of the chorus) | `full_mv` (the whole song, priced per
  second; songs over 190 s → `MV_SONG_TOO_LONG`).
- `POST /v1/mv/estimate` prices one level for the song of `job_id`. **Estimating
  saves the song on the platform** (`song_locked: true`): the platform only
  prices a saved song, and the price of a full video depends on its measured
  length. Saving is idempotent and free. `recommended_product_id` is the MV pack
  covering the level when `affordable` is false, else `null`.
- `POST /v1/works/{job_id}/mv`: `job_id` must be a `succeeded` song of this
  account whose 24 h candidate has not expired (`MV_SONG_NOT_READY` /
  `MV_SONG_EXPIRED`). `aspect_ratio` (`9:16` default | `16:9` | `1:1`),
  `quality` (`standard` default | `high`), `subtitles` (a lyric video always has
  them), `photo_bids` (≤ 10 upload bids, 24 h old at most → `MV_PHOTOS_EXPIRED`;
  style reference only, never face-driven), `chorus` (chorus level only, 4–60 s;
  absent = the storyboard model locates it). Idempotent per
  `(account, client_ref)` like `/v1/generate`. The platform freezes
  `credits_charged` at creation; a lyric video charges 0.
- `GET /v1/mv/{mv_id}`: `status` maps like a job (`queued|running|succeeded|failed`).
  `stage` is the platform's step name passed through (`queued`, `slicing`,
  `storyboarding`, `keyframing`, `rendering`, `assembling`, `done`; a newer
  platform may add one — the client shows a generic title). `progress` is
  **real**: `0.02` queued, `0.10 + 0.85 × completed steps (the rendering step
  counting its scenes)` running, `1.0` succeeded — the client never advances it
  on a timer. `segments {done,total}` only during `rendering`.
  `cancel_requested` = the platform acknowledged a cancel and will stop at the
  next gap. `video_url` (succeeded only) is a 1 h pre-signed MP4, kept 24 h; the
  client downloads it at once. `ai_label: burned_in` = the "AI generated" badge
  is in the pixels (the platform never renders without it; the UI labels the
  video again). Terminal videos carry `balances`.
- `DELETE /v1/mv/{mv_id}`: while `queued` → `outcome: cancelled, refunded: true`
  (everything back); while `running` → `outcome: cancel_requested,
  refunded: false` — the worker stops at the next scene boundary, scenes already
  made stay charged, the rest is refunded, and the video then reads
  `failed / USER_CANCELLED` whose terminal `balances` carry the refund. A
  finished video → `49309 JOB_ALREADY_FINISHED`.
- `QUOTA_EXHAUSTED` (49303, HTTP 200) now carries `QuotaExhaustedDetails` on
  **every** endpoint: `{error_code, reason: insufficient|paywall,
  required_credits, available_credits, recommended_product_id|null}`. The client
  reads it off `Failure.details` (`QuotaGap`), opens the paywall preselected on
  the recommended pack and retries the same request (same `client_ref`) after
  the purchase.

## 4. Error codes (PRD §6.5 → envelope)

| `details.error_code` | `code` | HTTP (unconfirmed unless marked ✓) | Ledger |
| --- | --- | --- | --- |
| `SAFETY_BLOCKED` | 45101 | 451 | not charged (refunded) |
| `IMAGE_REJECTED` | 45102 | 451 | not charged (refunded) |
| `QUOTA_EXHAUSTED` | 49303 | 200 ✓ | — (client opens the paywall on `details.recommended_product_id`; v1.1 details: `reason`, `required_credits`, `available_credits`) |
| `UPSTREAM_TIMEOUT` | 50401 | 504 | refunded after 2 server retries |
| `UPSTREAM_RATE_LIMITED` | 42901 | 429 | queued ≤ 5 min |
| `REGION_UNAVAILABLE` | 45103 | 451 | not charged; the client shows the `UPSTREAM_TIMEOUT` copy (ADR-0005) |
| `USER_CANCELLED` (v2) | — | — | job-level only (`DELETE /v1/jobs`); refunded if still queued |
| `JOB_ALREADY_FINISHED` (v2) | 49309 | 200 ✓ | `DELETE /v1/jobs/{id}` on a terminal job; nothing changes. The client matches the string, not the number |
| `ATTEST_FAILED` | 40140 | 401 ✓ | generation blocked |
| `DOWNLOAD_LOCKED` | 40310 | 403 | license/download refused (refunded purchase, or free tier) |
| `NETWORK_OFFLINE` | — | — | client-side only |
| `MV_SONG_NOT_READY` (v1.1) | 49312 | 200 ✓ | the song is not `succeeded`, has no audio or cannot be saved; not charged |
| `MV_SONG_TOO_LONG` (v1.1) | 49313 | 200 ✓ | over the full-video cap (190 s); not charged — offer the chorus video |
| `MV_SONG_EXPIRED` (v1.1) | 49314 | 200 ✓ | the song's 24 h candidate expired before it was saved; not charged |
| `MV_NOT_FOUND` (v1.1) | 49315 | 200 ✓ | `GET`/`DELETE /v1/mv/{id}`: unknown, not ours, or not a music video |
| `MV_PHOTOS_EXPIRED` (v1.1) | 49316 | 200 ✓ | a reference photo's 24 h upload expired; not charged |
| `MV_RENDER_FAILED` (v1.1) | — | — | job-level (`GET /v1/mv`): a rendering step failed platform-side; finished steps settled, the rest refunded |

A failed job (or music video) reports the same string in `data.error_code` with
`status: failed`.

Region (v2, ADR-0005): the client never blocks by region — every template and
genre is open everywhere, and the region preset only shapes culture (language,
festivals, instruments). If the server still has to refuse a region it answers
`REGION_UNAVAILABLE`; the client treats it as a temporary delay.

## 5. Ledger rules (PRD §8, server-side; mirrored by the mock)

- Free: 3 lifetime clips per `app_account_token`; full songs need a paid source.
- Pro (`com.songlet.pro.monthly|yearly`): 40 songs + 100 clips / month
  (T2/T3 storefronts BRA MEX IDN VNM TUR IND: 25 + 60). Yearly resets monthly.
  Yearly free trial (intro offer, `offerType == 1`): ≤ 10 songs during the trial.
- Premier (`com.songlet.premier.monthly`): 120 songs + 200 clips / month.
- Packs (`com.songlet.pack.10|50`): +10 / +50 songs, never expire.
- Charge at job creation (subscription first, then packs); any failure except a
  user cancel refunds to the same bucket.
- Subscription expiry → allowance 0; works remain playable.
- `REFUND` (ASSN V2, or `revocationDate` in a synced JWS) freezes that
  transaction's remaining credits; works it funded stay playable but
  `/v1/license/{job_id}` answers `DOWNLOAD_LOCKED`.
- Restore: `signed_transactions` owned by another `app_account_token` link this
  token to that account (same ledger).
- Music-video credits (v1.1): a separate credit pocket — the free account's 66
  credits plus the MV packs `com.songlet.mv.chorus` (2395 credits, $14.99) and
  `com.songlet.mv.full` (12779 credits, $79.99), consumable, never expire.
  Lyric video 0 · chorus video 2169 · full video 69 × song seconds (min 4140).
  Frozen at `POST /v1/works/{id}/mv`; a platform-side failure refunds all, a
  cancel while rendering refunds the unfinished share. An MV pack purchase
  counts as `pack` tier (the buyer has paid). Premier's monthly songs are **not**
  raised for videos (platform ADR-S03: grants follow the price formula).
- Signed transactions are Apple JWS (`header.payload.signature`, base64url JSON
  payload with `transactionId, originalTransactionId, productId, purchaseDate,
  expiresDate, type, appAccountToken, storefront, offerType, revocationDate`).
  Production verifies the x5c chain against Apple's root; the dev mock decodes
  without verifying (Xcode StoreKit-testing JWS are signed by a local cert).

## 6. Dev-only mock controls (`mock_server`, never in production)

`/__admin/*` (no signature): `reset`, `config {clip_delay_ms, song_delay_ms, mv_delay_ms, wav_enabled,
remote_config, …}` (`wav_enabled` = the platform's WAV probe switch, default off;
`remote_config: {"wav_export": true}` = the matching client switch; `mv_delay_ms`
= the wall-clock length of a music-video run, default 12 s),
`inspirations_enabled` (bool, default on; off = an older server without
`inspirations`), `fail_next {error_code}` (song codes, and the MV codes `MV_SONG_NOT_READY`,
`MV_SONG_TOO_LONG`, `MV_SONG_EXPIRED`, `MV_PHOTOS_EXPIRED`, `QUOTA_EXHAUSTED`
on the next MV request; `MV_RENDER_FAILED`, `UPSTREAM_TIMEOUT`, and `IMAGE_REJECTED` /
`SAFETY_BLOCKED` at the first rendered scene of the next MV, fully refunded), `advance_clock {days}`,
`notify {notification_type: REFUND|EXPIRED|DID_RENEW, transaction_id}` (emulates
App Store Server Notifications V2), `grant {product_id}` (also the MV packs),
`state` (each account's `status.credits` = its music-video credits).

## 7. v2 change set for the platform repo

Everything below is additive and backward compatible: a v1 server keeps
working with this client (missing optional fields fall back — no progress ring
detail, no glimpse, no WAV, no samples; a cancel shows an error and the job
keeps running).

Review status (platform repo, 2026-09-27): ✅ = agreed as proposed,
✅✎ = agreed with the platform's amendment (already reflected above),
✅⁺ = raised by the client after the review, then agreed.

1. ✅ **`POST /v1/generate`** — accept optional `template` (enum above) and
   `occasion: custom`; accept the new prompt-block lines `template`,
   `description` (≤ 300 chars, screened like `note`), `vocals`, `photos`;
   `genre` may be omitted. Validate `template` → `40001`.
2. ✅✎ **`GET /v1/jobs/{id}`** — add `progress`, `eta_seconds`, `lyrics_preview`
   (≤ 12 lines, as soon as lyrics exist), `balances` (terminal jobs).
   `queue_position` is always absent; `wav_url` is always absent until the WAV
   probe passes, then present on Premier full songs.
3. ✅✎ **`DELETE /v1/jobs/{id}`** — new; refund iff still queued; terminal →
   `49309` / `JOB_ALREADY_FINISHED`; sets `error_code: USER_CANCELLED`.
4. ✅ **`GET /v1/templates`** — new; `{templates:[{id, sample_url, duration}]}`.
5. ✅ **`GET /v1/license/{job_id}`** — add `X-License-Id`, `X-License-Issued-At`
   response headers (expose them to the client).
6. ✅ **Region** — no business change required; `REGION_UNAVAILABLE` stays a
   server-side decision (the client only changes how it presents it).
7. ✅✎ **Storage** — signed URLs valid 1 h, objects kept 24 h; the per-job
   `wav` rendition for Premier is enabled once lyria-3.5 passes the WAV probe.
8. ✅⁺ **`GET /v1/app/config`** — `config.wav_export` (bool). It does not exist
   until the WAV probe passes; it appears together with `wav_url` in the same
   release, so the app starts offering WAV (row + Premier benefit) exactly when
   the files exist. Absent = off (app_config is fail-open).
   HTTP status of `49309`: 200 (answered with §1).

9. ✅ **Music videos (v1.1, 2026-09-28, PRD ch.15 / ADR-0020)** — platform-defined
   (`02-openapi.yaml` MV section, `04-errors.md` §2 rows 49312–49316 + job-level
   `MV_RENDER_FAILED`, §3.1); the client adopted it as is. `POST /v1/mv/estimate`
   (estimating saves the song), `POST /v1/works/{job_id}/mv`, `GET /v1/mv/{mv_id}`
   (real progress, stage, scenes, `cancel_requested`, `video_url`, `ai_label`),
   `DELETE /v1/mv/{mv_id}` (`cancelled` | `cancel_requested`), `QuotaExhaustedDetails`
   on every 49303 with `recommended_product_id`. `QUOTA_EXHAUSTED` is confirmed as
   49303 on HTTP 200 (§4 row updated from the provisional 40201/402).

The mock (`mock_server/`) implements all of it; `mock_server/test/contract_extensions_test.dart`
is the executable form of this list (the `v1.1 music videos` group for item 9).

### 7.1 Music-video contract gaps (client phase 2, 2026-09-29) — proposed, not yet reviewed

The client ships each of these as "optional, absent = feature off" (ADR-0026,
ADR-0028); nothing below is required for the current app to work. For the
platform repo's review:

| # | Need | Contract v1.1 today | Proposal | Client behaviour until then |
|---|---|---|---|---|
| G1 | Which render qualities the platform offers | `quality` enum only | `GET /v1/app/config` `config.mv.qualities: ["standard","high"]` | absent → standard only, no choice shown, `quality` not sent (ADR-0026) |
| G2 | Time estimate per level on the hub | not on `MvEstimateResponse` (X-57 declined) | — (declined; recorded for completeness) | the hub shows no time; the progress page uses `MvTicket.eta_seconds` |
| G3 | A cover / storyboard frame of a video | no endpoint (L2 rendered whole, X-53) | `GET /v1/mv/{id}` `cover_url` (optional) | not shown; only needed for an on-device L2 (ADR-0024) |
| G4 | Segment-level recovery: retry a scene without the rejected photo, or finish without it | no segment ops; `MvJob` does not say which scene / photo failed | `MvJob.failed_segment {index, photo_bid?}` + `POST /v1/mv/{id}/segments/{index}:retry {exclude_photo_bids}` / `:skip` | P25 offers "adjust photos and try again": a new request, new `client_ref`, charged again after the refund |
| G5 | Video credits on the settings page | ✅ resolved by contract 02 v1.3 (2026-09-30): `credits_available` on the sync response | — | shown when present (P30); the client needed no change |
| G6 | Where a request came from (library · auto_l2 · upgrade) | no `source` on `CreateMvRequest` | optional `source` enum | recorded locally (schema v4); sent once `MvRequest.sendsSource` flips |
| G7 | Share rate of automatic lyric videos | no client event endpoint | `POST /v1/events {type: mv_shared, mv_id, source}` | not measured (no client analytics SDK, by rule) |
| G8 | Tell a scene failure from an assembly failure | all `mv_*` platform codes → `MV_RENDER_FAILED` | optional `failure_stage` on terminal `MvJob` | one "couldn't finish, credits back" copy |
| G9 | Photo cap 9 (task) vs 10 (contract, X-57) | 10 | — (keep 10) | the client caps at 10 |
| G10 | Cover photo of an inspiration (create home tiles) | `inspirations[]` has no image (2026-10-03) | optional `cover_url` (absolute https) per inspiration; ~3:4, ≥ 600 px wide, on the platform's storage | a bundled `assets/inspirations/<slug>.jpg`, else a gradient with an icon (ADR-0029 amended) |
| G11 | Template sample files | ✅ resolved 2026-10-03: the 16 clips exist and are the `preview_audio_url` of the inspiration named by the template id (`templates[]` and `linked_template_id` were removed from `GET /v1/templates`; `inspirations[]` is 32 entries with optional `occasion`, `requires_recipient`, `suggested_genre`, `default_vocals`) | — | the client matches an entry to a template by slug (or `linked_template_id` on older servers) and plays its preview |
