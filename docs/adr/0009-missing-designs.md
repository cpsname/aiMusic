# ADR-0009 — Settings (P14) and "temporarily unavailable" (P17) come from the design system
Status: Accepted
Date: 2026-09-24

## Context
`P14.png` is byte-identical to `P13.png` (work detail), so there is no Settings
design. `P17.png` was not delivered; the spec turns P17 into a generic
"temporarily unavailable" state.

## Decision
- **P14 Settings** is composed only from existing tokens and components: plan
  card (tier, songs and previews left, reset date), Upgrade, Restore purchases,
  Manage subscription, iCloud sync toggle (ADR-0013), default lyrics language,
  About generation (P15), Terms, Privacy, version. Grouped cards follow P13's
  card rhythm.
- **P17** is `StatusView` with the unavailable copy and Retry. It is used in
  place (inside the affected page) for upstream failures and at
  `/unavailable` for app-wide kill switches.
- Both are marked "design-system composed" in `docs/ui/diff-report.md` and
  have goldens but no prototype comparison.

## Consequences
When the design team delivers P14/P17 art, only the page files change;
components and routes stay.
