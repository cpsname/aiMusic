# ADR-0019 — iOS text sizes over the prototypes' drawing scale
Status: Accepted
Date: 2026-09-24

## Context
The prototype diff report (docs/ui/diff-report.md) shows the prototypes draw
every type-driven size at about 0.72× of the iOS text styles they depict:
page titles ≈ 24 pt where iOS Large Title is 34, body copy ≈ 12 pt where Body
is 17, primary buttons ≈ 40 pt tall where the app's are 54. Layout proportions,
colours, order and component set match; the drawing scale does not. Matching it
literally would set body text at 12 pt at the default Dynamic Type size, make
primary buttons shorter than Apple's 44 pt minimum tap target, and leave no
headroom for Dynamic Type (ADR-0018).

## Decision
- Text follows the iOS text styles (`SongletType`, 17 pt body at the default
  size) and scales with Dynamic Type; controls keep ≥ 44 pt targets, primary
  actions 54 pt (`SongletSize.primaryAction`).
- Layout measurements that do not depend on type follow the prototypes, as
  measured by the report: compact page gutter 16 pt (`SongletSpace.gutter`,
  also UIKit's compact margin), 12 pt on the create home
  (`SongletSpace.gutterDense`), 20 pt sheet inset (`SongletSpace.sheetInset`),
  sheets on the canvas colour.
- Because text is larger, pages that fit on one prototype screen scroll in the
  app. Forms keep their primary action pinned in the footer (P03 draws it at
  the end of the card) so it stays reachable; at accessibility sizes it scrolls
  in after the content (ADR-0018).
- The diff report waives CTA height on every page and P03's CTA width / inset
  for this reason (`tool/diff_report/config.json`); nothing else is waived.

## Consequences
Screens look larger than the prototypes at the same device size, never denser.
A future brand refresh that wants the denser look changes `SongletType` in one
place; the diff report will show the effect.
