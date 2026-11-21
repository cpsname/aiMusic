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
| `canvas` (stock) | `#F2EFE9` | `#0E0D0C` |
| `surface` (plate) | `#FCFBF8` | `#171513` |
| `surfaceMuted` (field) | `#E7E2D8` | `#211E1B` |
| `hairline` | `#CFC8BA` | `#332E29` |
| `ink` | `#111010` | `#F5F0E8` |
| `inkSecondary` | `#6A6357` | `#ADA396` |
| `inkTertiary` | `#9C9487` | `#776F64` |
| `accent` (signal) | `#F2401C` | `#FF5A34` |
| `onAccent` | `#160A06` | `#160A06` |
| `accentSoft` | `#FBD9CF` | `#3A1C13` |
| `highlight` (second ink) | `#1B33F0` | `#5B72FF` |
| `success` / `warning` / `danger` | `#3E6B4F` / `#A96A12` / `#A3201B` | `#8FB49A` / `#E0A45A` / `#FF6B5A` |

Rules of the road:

* **The action is ink, not coral.** A poster's call to action is the darkest
  thing on the page (`ObsButton`, filled buttons, the play key, the active tab).
* **Coral is a spot.** Selection marks, progress, the numbered folio, the
  composer's perforation mark, the AI stamp. It never fills a large field.
* **The second ink is cobalt.** Reserved for offers and counters ("Best value",
  "Recommended"). Used twice on a page at most.
* **Coral text is set in `accentPressed`** when it is small (`#C93012`), because
  the signal itself only reaches ~3.4:1 on bone. The contrast test enforces what
  must pass: ink ≥ 7:1 on stock, action label ≥ 4.5:1 on ink, secondary ≥ 3:1.

## Grid and rules

* **Corners are almost square**: plates 2, cards 4, controls 8, sheets 16,
  stamps 2. Nothing is a capsule.
* **Rules do the work**: 1 pt hairlines separate everything; a 2 pt ink rule
  closes a masthead or opens a section.
* **Numbers are printed**: `01` folios on sections and list rows, mono and
  tracked, in the signal coral.
* **Tickets tear**: the composer closes with a dashed perforation before its one
  action.
* **Mono stamps** carry status (`Preview`, `Full song`, `AI generated`): a label
  between two rules, not a tinted capsule.

## Component vocabulary

`PaperBackground` · `BrandHeader` (masthead: mark + tight wordmark + mono
standfirst + 2 pt rule) · `SectionHeader` (folio + coral block + title + rule) ·
`SurfaceCard` (plate) · `TemplateTile` (contact-sheet plate with a mono caption
on the paper margin) · `ComposerCard` (ticket stub: ink border, ruled summary,
perforation) · `ParamChip` (spec cell) · `ObsButton` (ink plate) · `WorkRow`
(index entry) · `LeaderRow` (dotted leader) · `SettingsGroup` / `SettingsRow`
(ruled block) · `PlanCard` / `MvLevelCard` (menu entries) · `StatusPill` (stamp) ·
`SelectionMark` (struck square) · `AiGeneratedBadge` (stamp) · `MessageView`
(notice slip) · `PlaybackControls` (ruled transport strip with an ink key).

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
