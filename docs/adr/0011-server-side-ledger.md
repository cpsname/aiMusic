# ADR-0011 — Purchases are accounted server-side; contract handed to the platform repo
Status: Accepted
Date: 2026-09-24

## Context
The spec asks for "pre-charge and refund logic" and a "local mirror of the
allowance ledger". The product owner decided: accounting (记账) is the server's
job, and the final backend contract goes to the platform repository.

## Decision
- The server is the only ledger. It pre-charges on `POST /v1/generate`
  (`credits_charged`), refunds on failure (PRD §8.4), and returns balances from
  `/v1/entitlements/sync` and on every job terminal state.
- The client keeps a **read-only mirror** (`songletEntitlementProvider`, cached
  in preferences) for display and for pre-checks (open the paywall before
  submitting when the mirror says 0). The mirror is refreshed after every
  generate, job end, purchase, restore and app foreground. It is never
  decremented locally.
- The client never grants or refunds. It sends StoreKit JWS to
  `/v1/entitlements/sync` and renders what comes back.
- Deliverable: `docs/songlet/backend-contract.md`, the platform hand-off. It
  covers all endpoints, extensions (ADR-0010, ADR-0012), error codes and ledger
  rules. `mock_server/` implements it exactly.

## Consequences
No drift between client and server balances. Offline, the last server balance
shows with its refresh time.
