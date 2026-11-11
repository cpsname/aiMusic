# ADR-0018 — Dynamic Type: chrome caps, content reflows
Status: Accepted
Date: 2026-09-24

## Context
Phase 5 requires every page to work at the largest Dynamic Type size on the
whole device matrix (iPhone SE → iPad Pro 13 landscape). A sweep of the 22
prototype pages × 6 devices at AX5 (53 pt body, ×3.12) found 88 layout failures;
every one was at AX5, the default size was clean everywhere. Two kinds of
cause: chrome that grows without bound (page headers, the tab bar / rail, the
allowance pill) and content arranged side by side that cannot fit when text is
three times larger (composer actions, stat rows, pinned footers).

Options: clamp the whole app's text scale (simple, but denies the sizes
low-vision users chose), or keep content fully scalable and give layouts an
accessibility arrangement.

## Decision
- **Chrome is capped** at `SongletType.chromeMaxTextScale` (xxxLarge, 23/17),
  the point where UIKit bars stop growing: `BrandHeader`, `NavigationBar`,
  `NavigationRail` (`MediaQuery.withClampedTextScaling`).
- **Artwork does not scale**: the 9:16 share card is a fixed design rendered
  into the video (`MediaQuery.withNoTextScaling`).
- **Content scales fully**. From `SongletType.accessibilityTextScale` (AX1,
  28/17), read through `SongletType.isAccessibilitySize(context)`, layouts switch
  to an accessibility arrangement:
  - `PageFrame` scrolls its footer in after the content instead of pinning it;
  - the create home becomes one scrolling column (header, composer, templates)
    on every width, template tiles grow with the text (one per row on a phone,
    `SongletSize.tileAspectWide`);
  - `BrandHeader` moves its trailing slot under the name;
  - `ComposerCard` wraps its leading controls, puts the length toggle full
    width and stacks the parameter chips; `QueueBanner` stacks its stats;
  - the region sheet scrolls as one list.
- Rows of peers (share targets, paywall benefits) use equal `Expanded` columns
  so labels wrap; text that sits next to an icon is `Flexible`.
- Sizes derived from text (glimpse card page height) are measured with a
  `TextPainter` at the current scaler, never computed from the unscaled style.

## Consequences
`test/pages/device_matrix_test.dart` runs every page on every device at ×1 and
AX5 (264 layout cases; any overflow fails) and keeps 36 review goldens at 1×
under `test/goldens/matrix/`. A new page or component must pass the sweep; the
"how to add a page" checklist points to it.
