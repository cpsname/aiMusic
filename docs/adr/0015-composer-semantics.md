# ADR-0015 — Composer card semantics
Status: Superseded by ADR-0033 (2026-10-05)
Date: 2026-09-24

## Context
P01's floating composer shows a free-text prompt, "+", a "Music" chip, a
Preview/Full segmented control, a mic, and Length / Vocals / Genre chips. The
Preview/Full control and the Length panel (P02a: Short 30 s / Standard ≈2 min)
express the same choice, and "Music" has no defined alternative.

## Decision
- **Preview/Full and Length are one state** (`CreationDraft.length`: `clip` |
  `full`). Either control changes it; both always show the same value. `full`
  without an allowance opens the paywall (PRD §8.2) instead of switching.
- **"Music" is the source chip.** It shows what the song is built from: *Music*
  (text prompt), *Photos* (after "+" adds photos, P04), or *Voice* (after P03a
  applies a transcript). Tapping it opens the same "+" menu. This maps the three
  PRD inputs (F03 text, F04 photos, voice as a text source) to one control.
- **Free-text prompt** is the `description` line of the prompt block
  (≤ 300 characters, P18's note counter). It runs
  through the same preflight as keywords (artist names, "in the style of"). The
  occasion skeleton still comes from the chosen template, or "Custom" when none
  is chosen.
- **Vocals** (`custom` | `vocals` | `instrumental`) is a new `PromptBlock` field;
  `instrumental` drops the lyrics section from the prompt and the lyric UI from
  the players.
- **Genre**: `custom` (let the prompt decide) or one of the 18 genres.

## Consequences
One draft model drives the composer, the template form (P03) and the photo
flow. No control has hidden or duplicate state.
