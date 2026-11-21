# The poster identity (2026-11)

The interface is set like a **two-colour poster**: bone stock, near-black ink,
and one signal coral used as a *spot*. The emotional register is carried by a
serif; the system register by a tight grotesque and a monospaced label voice.
Function, data flow, routes and copy are unchanged — only the setting changes.

## The three voices

| Voice | Face | Used for |
| --- | --- | --- |
| **Display (grotesque)** | system sans, `w800`, negative tracking (−2.2 pt at 44) | mastheads, page titles, work titles, big figures |
| **Emotional (serif)** | Georgia (→ Songti SC / Noto Serif CJK) | lyrics, quotes, standfirsts — never chrome |
| **Operator (mono)** | Menlo (→ SF Mono, Consolas, platform sans) | every label, folio, price, timestamp, stamp |

That split is the whole design argument: the app *shouts* in the grotesque,
*speaks* in the serif, and *labels itself* in mono.

## Two inks, one stock

| Role | Daylight | Night |
| --- | --- | --- |
| `canvas` (clay stock) | `#F4E6D7` | `#1A1410` |
| `surface` (cream plate) | `#FDF7EE` | `#241C16` |
| `surfaceMuted` (field) | `#EBD9C6` | `#2E241C` |
| `hairline` | `#D9C3AC` | `#3E3229` |
| `ink` (espresso) | `#241A14` | `#F6EADC` |
| `inkSecondary` | `#6F5A4A` | `#C0A895` |
| `inkTertiary` | `#A38B78` | `#8A7563` |
| `accent` (vermilion plate) | `#C93C17` | `#FF7A4D` |
| `onAccent` (cream) | `#FFF6EC` | `#1A0C06` |
| `accentSoft` (blush) | `#F9D9CB` | `#3D1F14` |
| `highlight` (honey) | `#A9762A` | `#E7B06A` |
| `success` / `warning` / `danger` | `#4E7A52` / `#A96A12` / `#A3231B` | `#9CC08A` / `#E7B06A` / `#FF7A63` |

Rules of the road:

* **The brand plate carries the action.** Primary actions, the play key and the
  filled buttons are printed on vermilion with cream lettering — the app has a
  main colour, and it is the colour of the icon.
* **Ink carries the reading.** Text, rules, the tab bar's current cell and the
  masthead rule stay espresso, so the colour never competes with the words.
* **Blush is the writing surface.** The composer is cream pulled towards the
  blush tint, the one warm plate on the page.
* **Honey is the second ink.** Offers, "Best value", counters. Used twice on a
  page at most.
* Small vermilion text is set in `accentPressed` where the plate itself is too
  bright behind it. The contrast test enforces what must pass: ink ≥ 7:1 on
  stock, the cream action label ≥ 4.5:1 on vermilion, secondary ink ≥ 3:1.

## Grid and rules

* **Corners are almost square**: plates 2, cards 4, controls 8, sheets 16,
  stamps 2. Nothing is a capsule.
* **Rules do the work**: 1 pt hairlines separate everything; a 2 pt ink rule
  closes a masthead or opens a section.
* **The staff is the signature.** Where another app draws a divider, this one
  draws five hairlines — a stave (`StaffDivider`). It closes every section head,
  opens the player (first line in the signal coral), and sits above the lyric
  sheet. A page changes subject the way a score does.
* **Numbers are printed**: `01` folios on sections and list rows, mono and
  tracked, in the signal coral.
* **The sleeve has a spine.** The player's plate carries a folded edge lettered
  bottom-to-top with the catalogue mark (`A1 · LYRIA 3.5`).
* **Prices are set as a menu**: dotted leaders from the entry name to the price
  (`PlanCard`), dashes for benefits.
* **Tickets tear**: the composer closes with a dashed perforation before its one
  action.
* **Mono stamps** carry status (`Preview`, `Full song`, `AI generated`): a label
  between two rules, not a tinted capsule.

## The generic-pattern check

What this interface deliberately does *not* do, because every App Store app does
it:

| The pattern everywhere | What this does instead |
| --- | --- |
| Circular icon + label tab bar | an index strip: `01 Create · 02 Library · 03 Settings`, the current cell printed as an ink block with a coral folio |
| large title + search field | a masthead: 48 pt tight wordmark, mono standfirst, 2 pt rule with a coral block |
| rounded card per item, thumbnail at the left, chevron at the right | a ruled index: folio, title in type, mono metadata, keys at the margin |
| three plan cards with a "best value" corner ribbon | a menu: leader dots to the price, mono stamps, a cobalt second ink, a perforated tear-off action |
| centred cover, capsule progress bar, round play button | a record sleeve: plate plus spine, waveform under a stave, segment rule, ink square transport key |
| the same thumbnail repeated on every library row | one filmstrip of plates above a pure-type index |

## Component vocabulary

`PaperBackground` · `StaffDivider` · `BrandHeader` (masthead) · `SectionHeader`
(folio + title + staff) · `SurfaceCard` (plate) · `TemplateTile` (contact-sheet
plate with a mono caption on the paper margin) · `ComposerCard` (ticket stub:
ink border, ruled summary, perforation) · `ParamChip` (spec cell) · `ObsButton`
(ink plate) · `WorkRow` (index entry, plate optional) · `LeaderRow` (dotted
leader) · `SettingsGroup` / `SettingsRow` (ruled block) · `PlanCard` /
`MvLevelCard` (menu entries) · `StatusPill` (stamp) · `SelectionMark` (struck
square) · `AiGeneratedBadge` (stamp) · `MessageView` (notice slip) ·
`PlaybackControls` (ruled transport strip with an ink key).

## Screens

* **Create home** — masthead; numbered contact sheet (photo, mono caption on
  paper); the composer as an ink-ruled ticket with a serif writing line.
* **Generating** — the state at the left, the percentage struck as a 46 pt
  grotesque figure at the right margin, the progress rule under it, the lyric
  glimpse in the serif.
* **Library** — a printed index: numbered occasions, numbered rows, mono dates,
  stamped status.
* **Player (preview / song)** — sleeve head (plate + 34 pt title + mono meta),
  waveform, ruled movement track, transport strip with an ink play key, lyrics
  in the serif between hairlines.
* **Paywall** — a title page: hero, numbered value strip, plans as menu entries
  with mono prices and struck benefits, ink Subscribe.
* **Settings / download / work detail** — numbered sections of ruled rows,
  delivery-note lines.
* **Music videos** — menu entries for the levels; the same working head for
  renders.
* **Navigation** — an index strip: three cells divided by rules, the section
  being read printed as an ink block with a coral folio.

## Verification

* `dart analyze` over the workspace: 0 errors.
* `tool/preview/design_preview_test.dart` renders 14 pages to
  `tool/preview/design-preview/` on any host (it substitutes Segoe UI, Consolas
  and Georgia for the device faces). Run:
  `flutter test tool/preview/design_preview_test.dart --update-goldens`.
* The pixel goldens under `test/goldens/` are recorded on macOS with SF Pro /
  New York / Apple Color Emoji and must be re-recorded there after this change
  (`flutter test --update-goldens`).
