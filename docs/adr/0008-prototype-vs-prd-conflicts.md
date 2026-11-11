# ADR-0008 — Where prototypes and the PRD disagree, the PRD wins
Status: Accepted
Date: 2026-09-24

## Context
The prototypes are visual targets; the PRD is the product and commercial
contract. Several screens contradict it or each other.

## Decision
| Conflict | Resolution |
| --- | --- |
| P08 Pro Monthly shows "10 songs / 50 previews" | PRD §8.1: 40 full songs / 100 clips. Plan copy is generated from the catalogue, never from art. |
| P02 lists Ireland, New Zealand, Spain, Italy beyond the 14 launch presets | Rows come from `RegionPresets` (PRD §7.3, 14 countries). Adding a country is the README "add a country preset" checklist. |
| P16 shows a different tab bar (labels and icons) and a pt-BR festival | P01's shell (Create / Library / Settings) is used everywhere; the festival page is data-driven for any region (§11.3). |
| `sub-week.png`: weekly "Unlimited" plan | Not a listed page; PRD §8.1 and D6 exclude weekly and unlimited plans. Not built. |
| P01 shows 16 template tiles; F01 names 8 occasions | Each template (`SongTemplate`) maps to exactly one PRD occasion skeleton and ledger category: Birthday Wish / Birthday Party → birthday; Love Story → anniversary; Thank a Friend / Rap Battle / Pet Anthem → confession; Wedding → wedding; In Memory → memorial; Festival / Party Invite → festival; Team Anthem / Hometown / Business Promo → brand; Ringtone / Sports Recap / Comedy → soundtrack. The template id travels as the optional `template` field of `/v1/generate` so the server may specialise the skeleton. The festival page (P16) shows the 8 occasions themselves. A composer prompt without a template uses occasion `custom` (contract extension; library section "Just because"). |
| P07 (preview player) has no tab bar, P09 (full player) has one | All work pages live under the Library branch (`/library/works/:id/…`) and keep the tab bar, as P09, P12 and P13 do. |
| P18 name field rejects "Taylor Swift style"; the preflight never screened the recipient (a friend may be called Adele) | The recipient is screened for imitation phrases and multi-word artist names only; single-word names stay allowed. |
| P18 shows an "Add a note (optional) 0/300" field | The composer's description (P01) is that note: ≤ 300 characters. |
| P09 action tile "License" and P11 license card | One license document per work (`GET /v1/license/{job_id}`), shown in both places. |

## Consequences
Numbers on screen always match what the server bills. Visual structure follows
the prototypes.
