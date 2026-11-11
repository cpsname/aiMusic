# ADR-0034 — The composer's space: a budget, the keyboard, two panes
Status: Accepted
Date: 2026-10-05

## Context
The create home stacks the idea grid over the composer on phones. Unfolded, the
composer could take 62 % of the page and push the grid out of view; with the keyboard
up on an iPhone SE (≈ 387 pt left) a picked card's fields, the summary and the action
do not fit beside the brand header and a row of tiles at all.

## Decision
- **Budget (`ComposerBudget`, pure)** on phones, measured on the room under the brand
  header: the composer card, primary action included, takes at most **35 %** of the
  screen height folded (A / B) and **55 %** unfolded (C, or dictating) — and never so
  much that the grid loses its heading and one full row (`IdeaGridLayout.minExtent`,
  the same layout the grid draws and a deep link scrolls by). Past the budget the
  composer's fields scroll between its fixed head and its primary action.
- **Keyboard.** The shell's Scaffold already keeps the page above the keyboard (and hides
  its inset from the page's media query — verified in `scaffold.dart`); the page reads it
  from the view where the resize rebuilds. With the keyboard up the brand header steps
  aside; free input keeps a row of the grid; a picked card or the options fold the grid
  away and the composer gets the room — the picked card stays named in its head. The
  "≥ one row" rule is the keyboard-down rule for B and C.
- **iPad (regular width)**: the grid leading, the composer in its own pane, head and
  action fixed, nothing overlapping; the grid never folds.
- **Accessibility text sizes** keep ADR-0018's single scrolling column (composer first);
  the shares do not apply there, overflow does not happen.
- Unfolding the options (or picking a card while they are open) scrolls the summary row
  to the top of the composer's view, the selectors under it.

## Consequences
- `test/pages/composer_layout_test.dart` measures the rules on the six matrix devices in
  every state, keyboard up and down; `P01-keyboard`, `P03-keyboard`, `P01-options`,
  `P03-options` join the page goldens and the matrix review set.
- `AnchoredPanelBody` scrolls its footer with its rows (a panel anchored low at AX5).
