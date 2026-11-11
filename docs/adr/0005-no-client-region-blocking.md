# ADR-0005 — No client-side region blocking
Status: Accepted
Date: 2026-09-24

## Context
Phase 1 blocked generation on the client when the storefront was outside the
launch regions (`regionBlockedProvider`, OccasionPage check, `REGION_UNAVAILABLE`
copy, acceptance test06). The delivery spec removes that: availability is the
server's decision, and the region layer only shapes culture — §7.3 presets,
§11.3 festivals and "Popular in {country}". All 18 genres are offered in every
region.

## Decision
- Remove `regionBlockedProvider` and every client check that uses it.
- The server may still answer `REGION_UNAVAILABLE`; the client shows the
  `UPSTREAM_TIMEOUT` copy for it (a retryable "temporarily unavailable"), so users
  are never told their country is excluded.
- Region selection (sheet P02) changes only lyric language, the 3 recommended
  genres and festival content.
- Acceptance test06 changes to "server REGION_UNAVAILABLE shows the
  temporarily-unavailable copy and the library still works".

## Consequences
Storefront and device region are still sent (`X-Storefront`, `X-Device-Region`)
so the server can decide. The mock keeps a `region_unavailable` switch for tests.
