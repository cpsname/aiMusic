# ADR-0004 — Design tokens (light + dark) and components live in ui_kit
Status: Accepted
Date: 2026-09-24

## Context
The prototypes define a warm palette (#FFF6EE background, #C9472B accent,
#1A1A1A text, #8A8A8A secondary), a 4-pt spacing grid, 20/24/16 radii, soft
shadows and short motion. The template already has `ui_kit` (tokens, `AuraTheme`,
`AuraStyle` ThemeExtension, `GlassCard`, `ObsButton`, `StatusView`, Message stack)
and a rule: "no second theme system".

## Decision
- One token source in `ui_kit`: `SongletTokens` (colour roles, type scale,
  spacing, radii, shadows, motion durations and curves) with `light` and `dark`
  instances, exposed as a ThemeExtension and folded into `AuraTheme.warm` /
  `AuraTheme.warmDark`.
- Dark mode is derived from the same roles (the prototypes are light-only);
  contrast meets WCAG AA for text roles.
- Reusable P-series components (template tile, composer card, anchored panel,
  option row, plan card, lyric line, section waveform, share-card frame, status
  pill, etc.) are pure presentation in `ui_kit` — strings and callbacks come in as
  parameters, no providers, no l10n.
- Pages in `lib/ui/` never declare colours, sizes or durations directly.

## Consequences
Components get golden tests inside `ui_kit` in both themes and both text
directions. A second app built from the template swaps tokens without touching
components.
