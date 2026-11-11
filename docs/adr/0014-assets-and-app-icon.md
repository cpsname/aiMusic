# ADR-0014 — Template art, cover art and app icon sources
Status: Accepted
Date: 2026-09-24

## Context
Template tiles (P01, P16) and hero cards use illustrations that exist only
inside the prototype rasters (≈2.17× scale, so a 160 pt tile has ≈350 px of
art). Three candidate app icons are at the repo root; the ChatGPT export is
1254 px square, the only one ≥ 1024 px.

## Decision
- Template and festival art is cropped from the prototypes at native resolution
  into `assets/templates/<template_id>.jpg`. Each file is listed in
  `assets/templates/manifest.json` with its source prototype and pixel size.
  Pages reference the art only through the `Template` catalogue, so replacing
  the art with design-team exports is a file swap with the same names.
- Generated-song cover art is produced in code from the work's occasion and
  genre (gradient + motif from tokens). It can't be mistaken for a photo and
  needs no network.
- App icon: `ChatGPT Image Sep 24, 2026, 10_43_17 AM.png`, resized to a
  1024×1024 single-size AppIcon (Xcode 26 generates the rest). Alpha is
  flattened onto the background token.

## Consequences
Art sharpness on 3× devices is capped by the prototype resolution; the manifest
makes the replacement explicit and mechanical.
