# Inspiration photos

Optional cover photos for the create home's inspiration tiles that are not one
of the 16 built-in templates (those use `assets/templates/`). Name a file after
the inspiration's `slug` from `GET /v1/templates`:

    soundscape.jpg  background_music.jpg  memorize_something.jpg
    text_messages.jpg  intro_music.jpg  montage.jpg  say_it_with_a_track.jpg
    brand_jingle.jpg  streaming.jpg  speech_to_track.jpg  weather_report.jpg

JPEG, roughly 3:4 (the tile is 0.86 wide ÷ high), at least 300 px wide.
Cover source order per tile: a bundled file here, else the server's
`cover_url`, else a gradient with an icon (ADR-0029, amended 2026-10-03).
