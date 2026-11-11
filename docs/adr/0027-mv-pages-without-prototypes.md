# ADR-0027 — P19–P30 built without prototypes
Status: Accepted
Date: 2026-09-29

## Context
The task numbers the music-video screens P19–P30; `docs/ui/` holds prototypes
for P01–P18 only. ADR-0009 is the precedent for a screen without a prototype.

## Decision
Derive the pages from PRD ch.15 and the component library (plan decision D-3):
P19 entries (song-page card, work-detail rows, library chip) · P20/P21 hub
(compact / two panes) · P22 credits sheet · P23 automatic-video banner · P24/P25
progress / failure · P26/P27 video (portrait / landscape, dark, full screen above
the tab bar) · P28 length panel · P29 paywall video group · P30 settings video
credits. Two components were added to ui_kit (`MvLevelCard`,
`InlineProgressBanner`, goldens light/dark/RTL); everything else is existing
components and tokens. Each page has a golden (`test/goldens/pages/P19–P30`)
and runs in the device matrix (6 devices × default and AX5 text). The previous
MV goldens P19/P20/P21 are now P20/P24/P26.

`make diff-report` lists these pages under "Pages without a prototype" and
copies their captures to `docs/ui/diff/`; they are scored once
`docs/ui/P19–P30.png` exist.
