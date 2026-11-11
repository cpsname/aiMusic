# ADR-0036 — A picked card starts at a preview
Status: Accepted
Date: 2026-10-05
Amends: ADR-0032 (Length took the card's `default_model`).

## Context
Most cards of the product's list send `default_model: lyria-3.5` (the full song). With
Length following it, picking "Birthday Wish", typing a name and pressing the action asked
for a full song first — which a new account is refused for — while PRD §3.1 / §8.2 make
the 30-second preview the first song of a session and the paywall come after it.

## Decision
Picking a card (server entry or offline template) sets Length to **Short** (the
preview). Vocals, Genre and the video switch still take the card's defaults
(`default_vocals`, `suggested_genre`, `default_on_video` / the occasion rule).
`default_model` is still parsed and kept on `Inspiration` as data. Standard is one tap
away in the options; "Get the full song" on the preview carries the same inputs.

## Consequences
The first session's three decisions (tile, name, action) make a preview; the integration
test asserts `model: lyria-3-clip-preview` on the request the mock stored.
