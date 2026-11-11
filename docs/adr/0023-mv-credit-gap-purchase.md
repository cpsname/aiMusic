# ADR-0023 — A credit gap buys the pack in place and sends the same request
Status: Accepted (amends ADR-0020's paywall step)
Date: 2026-09-29

## Context
PRD §15.4: on `QUOTA_EXHAUSTED` the client buys the recommended product with
StoreKit 2 and retries the same `client_ref`; "待执行动作本地持久化，购买中途 App
被杀仍能续做". ADR-0020 opened the full paywall and kept the request in memory.

## Decision
- A refusal with its gap is a state of its own, `MvQuotaGap` (not a failure).
  The request — photos already uploaded, their bids — is saved as the pending
  `MvIntent` (`KeyValueStore` `mv.pending_intent`, one per device).
- The hub opens the P22 sheet (a bottom sheet, not a route: it acts on the
  request the hub holds). It buys the recommended pack through commerce_kit's
  `IapPurchaseOrchestrator` exactly as the paywall does; "See plans" opens the
  paywall preselected. `IapCompleted` → `retryIntent`; `IapCancelled` → the
  sheet closes, every choice on the hub stays, the hub shows "waiting for
  credits · Continue". Leaving the hub gives the intent up.
- `retryIntent` sends the same `client_ref` while the intent is fresh
  (≤ 60 min, inside the platform's 70-min idempotency window); past that a new
  one — the refused attempt was never accepted, so nothing can be charged
  twice. After a purchase it retries a `QUOTA_EXHAUSTED` at 0 / 2 / 5 s (the
  ledger may credit a verified purchase a moment later), then shows the sheet
  again with the platform's new gap (a T2/T3 pack may not cover a video — the
  sheet says so, from the catalog's per-tier credits).
- "Continue" asks the platform once; still short → the sheet again.
- At launch a fresh intent is sent again (the app was closed during the
  purchase); a stale one is dropped.
- A business refusal ends the intent; a transport failure keeps it.

## Consequences
The client never decides from local transactions whether it can retry; it asks
the platform, whose ledger is the truth (ADR-0011).
