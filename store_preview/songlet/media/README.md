# Preview media

The only media the App Store previews use besides the app itself. Everything
here comes from the products repo's `cmd/songlet-samples`, through the real
BFF and the platform (Lyria for songs, the lyric-video renderer, the image
model). It writes the files and `manifest.json` (schema 2,
packages/store_preview ADR-0008) with each item's license record. Nothing
here is edited or made by hand.

Commit `manifest.json`; the media files are git-ignored (fetch them with the
manifest from wherever songlet-samples published them).

## Making it

What is asked for each storefront is in `../generation.yaml` (the scripts,
model, recipient, keywords, photo framings, style and each storefront's photo
imagery); the storefronts' regions and lyric languages are the `vars` of
`../app.yaml`. Against a platform (server + worker, with an ffmpeg that has
libass for the lyric-video subtitles) and the products BFF, with a funded
guest on a distribution whose attest mode is not `required`:

```sh
cd ../genaistudio-products     # the products repo
SONGLET_SAMPLES_DIST_SECRET=… go run ./cmd/songlet-samples \
  -base http://localhost:9910/v1 -dist e2e.songlet.ios -device <funded guest UUID> \
  -store-preview <this repo>/store_preview/songlet \
  -platform-dsn postgres://…/genaistudio -nb-command ../genaistudio/scripts/nb-image-gen.sh
```

The credentials come from the environment (`SONGLET_SAMPLES_DIST_SECRET`, the
DSN) and never land in this directory.

It resumes: an item already in the manifest with its file is never made (or
paid for) again. A song is retaken (up to three takes) when the BFF gives it
no section timing, since the player's synced lyrics need it, or when script A's
chorus never sings the name.

Where the license ids come from:

- songs (`provider: lyria`): the Lyria interaction id, which the platform's
  music step records in its candidate metadata
  (`gen_post_process_executions.output_snapshot`);
- lyric videos (`provider: platform`): the platform's lyric-video task;
- photos (`provider: platform`): the platform image tool's provider call
  (`prov_provider_call_logs.id`).

`store-preview validate --app songlet` (and `render` before recording)
checks the manifest. A missing item, an empty license id or an entry of an
inactive script fails it, and nothing is recorded or rendered. There is no
fallback to other audio, video or pictures.

## What it holds (84 entries)

| role | count | which |
| --- | --- | --- |
| `song` | 24 | script A and script B × 12 storefronts |
| `lyric_video` | 12 | the platform's lyric video of each storefront's B song (a still made with that storefront's photos as style reference, Ken Burns, synced lyrics, AI label) |
| `photo` | 48 | 4 per storefront: picked in script B's hook, the style reference of that storefront's B song and lyric video, and the backdrops of both scripts' cards and bridges |

Script C's three songs are archived in `../archive/C/` (ADR-0038). Photos show
no faces, brands or text.

## Variables

What the scripts type and tap comes from each song's `vars`:
`recipient`, `keyword1`–`keyword3` (A), `lyric_language`, `chorus_index` (the
section chip of the first chorus) and `sung_name` (how A's chorus spells the
recipient). `data` holds the app's own fields — `prompt`, `lyrics`,
`structure` (the BFF's section timing, one window per `[Section]` tag), `job_id`
— which the dev mock's demo profile serves.
