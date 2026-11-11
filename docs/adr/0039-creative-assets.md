# ADR-0039 — Creative assets: the default page and three custom product pages, from the previews' footage
Status: Accepted
Date: 2026-10-10
Builds on ADR-0038 (the template's `store_preview` tool; its ADRs 0009–0014).

## Context
Apple added the product page header and search results creative assets on
2026-10-05 (iOS 27 and later). ascpub publishes Songlet's listing and holds
three custom product pages — `cpp/birthday.yaml`
(`songlet://app/create?template=birthday_wish`), `cpp/photo.yaml`
(`songlet://app/create/photos`), `cpp/wedding.yaml`
(`songlet://app/create?template=wedding`) — whose default assets it binds by
id (`cpp.<slug>.header`, `cpp.<slug>.search`); its `assets.yaml` binds
`header.universal.tool` to the default page's header and search results.

## Decision
- `store_preview/songlet/creatives/`: `store-page.yaml` (the universal 16:9
  `header.universal.tool`; per storefront the 21:9 header image + 12 s video
  and the 3:2 search results image + 15 s video) and `cpp-birthday.yaml`,
  `cpp-photo.yaml`, `cpp-wedding.yaml` (each a universal header and search
  image for the page's default, and one per storefront with its phrase).
  127 assets over 12 storefronts.
- Footage: A's player and name / words / share scenes, B's photo picker and
  lyric video; the Wedding card has no preview scene, so the capture script W
  films it (picked, the couple's names typed) in each storefront's take.
- Texts: `storeCreativeHeader`, `storeCreativeSearch`, `storeCreativeBirthday`,
  `storeCreativePhoto`, `storeCreativeWedding` in the 13 ARBs (12 storefronts
  use them); no price, "free", competitor or award.
- The page slugs and the ids they bind are ascpub's: `app.yaml`
  `creatives.ascpub.listing` names the listing bundle
  (`../songlet/listings/com.songlet.ios`, the checkout ascpub publishes from)
  and the tool fails a target or a bound id that disagrees with it. No deep
  link is written here.
- `make store-preview` records A, B and W and renders the previews, the
  creative assets and `dist/songlet/assets-manifest.json` in one run.

## Consequences
- Every take now films W too (~6 s per storefront).
- `real_ui` stays `false` until a person reviews each asset
  (`make store-preview ARGS="review --app songlet …"`).
