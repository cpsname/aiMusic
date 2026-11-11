# ADR-0007 — How screens are compared with the prototypes
Status: Accepted
Date: 2026-09-24

## Context
The spec gates components and pages on "difference ≤ 2 px or ΔE ≤ 2" against the
prototypes. The prototypes are AI-generated rasters: two capture sizes (852×1847
= 393 pt wide at ≈2.17×, and 794×1981 tall scroll captures), compression noise,
invented glyph shapes, photographic art, and some numbers that contradict the PRD
(ADR-0008). A whole-image pixel diff against a real renderer (real fonts, live
data, localized text) cannot pass that threshold and would not measure fidelity
either: it would flag anti-aliasing and art, not layout mistakes.

## Decision
Fidelity is measured on three axes, each automated and each with its own
threshold, by `tool/diff_report` (writes `docs/ui/diff-report.md`):

1. **Colour tokens — ΔE2000 ≤ 2.** For every token, sample points in the
   prototypes (flat fills: background, accent button, text, secondary text,
   card surface, chip, divider) are listed in `tool/diff_report/samples.json`.
   The tool averages a 5×5 patch at each point and compares it with the token.
2. **Geometry — ≤ 2 pt.** Per page, landmark boxes (card frames, tile grid
   pitch, button heights, radii, spacing between sections) are measured in
   prototype points (pixels ÷ scale) and recorded in
   `tool/diff_report/landmarks.json`. The page golden test records the
   matching widget rects (found by `Key`s) at 393×852 into a JSON sidecar;
   the tool compares them.
3. **Visual review.** The tool writes a side-by-side and a 50 % overlay image
   per page into `docs/ui/diff/` and links them from the report, for the human
   review a metric cannot do.

Regression goldens (`matchesGoldenFile`) remain the gate against change: every
component in light and dark and LTR and RTL, every page on the device matrix
(ADR-0018). Page goldens load real fonts at test time — SF Pro, New York and
Apple Color Emoji from the macOS system font directory, never shipped in the
repository or the app. There is no second golden set: `loadGoldenFonts` fails
with the missing path on a host without them, and CI runs on macOS.

## Consequences
The report fails when a token or landmark exceeds its threshold. Art, copy and
data differences are visible in the overlay but not scored.

## Amendment (2026-09-24) — as implemented
Building the tool against the 21 prototype rasters changed three details:
- **Colour roles are matched by palette, not hand-placed points.** Per page, the
  prominent colours (≥ 0.2 % of the screen, 5-bit buckets) are extracted and each
  token is compared with its nearest one within ΔE 10; the token is scored on the
  median over the pages that show it. Hand-placed points drifted between
  captures of different scales; the palette is reproducible. Where roles sit too
  close to tell apart by colour, the result says so (see `accentSoft` in the
  report) instead of being tuned away.
- **System chrome is excluded.** The prototypes draw the status bar, Dynamic
  Island and home indicator (pure black); the top 54 pt and bottom 34 pt are
  left out of every measurement, on both images.
- **Everything that is not scored is written down.** `tool/diff_report/config.json`
  lists the sampled roles, the stroke-only roles that cannot be sampled, the
  tokens whose value the phase-1 spec fixes (reported as 📌, never changed to
  chase a raster), and each geometry waiver with its reason and ADR. The report
  lists every open deviation by name.
- **Geometry landmarks are detected from pixels on both images** (the widest
  accent pill, and the first non-canvas column over the middle third) rather
  than from widget rects, so the same detector measures both sides.
The app side is rendered at the prototypes' 393×852 pt canvas by
`test/pages/design_capture_test.dart`; `make diff-report` runs both steps.
