# ADR-0031 — Everything costs credits: the paywall by offer, Weekly Pro
Status: Accepted
Date: 2026-10-03

## Context
Contract 02 v2.1 (product ADR-S14 / S15) removes the free allowance: every song,
clip and video costs credits, a free account has `reset_at: null`, and the lyric
video costs 57. `QUOTA_EXHAUSTED.details.offer` — and `offer` on the music-video
estimate — says whether to offer a plan (`subscription`) or credit packs
(`packs`); `recommended_product_id` is the pack to preselect. A new subscription,
`com.songlet.pro.weekly`, leads, with the App Store's first-week 50 % off.

## Decision
- **No client-side gate.** `CreateFlow.ensureAllowance` is gone: nothing is
  counted down on the device (a fresh account reports `songs_left 0,
  clips_left 0` and must still be able to try). The server answers
  `QUOTA_EXHAUSTED`; the generating page opens the paywall with `offer` and
  `recommended_product_id` (`QuotaOffer.of(failure)`, `QuotaGap.of(failure)`). The
  "create-home allowance pill" is removed; Full / Preview switch freely.
- **One paywall, two leads.** `PaywallRoute(offer:)` (query `offer=`):
  - `subscription` or no offer (only an error code): the plans lead, **Weekly Pro
    preselected** (`SongletCatalog.recommendedSubscription`), the packs listed below
    — a recommended pack is ignored in favour of Weekly Pro.
  - `packs`: the credit packs lead (the music-video packs when opened for a video),
    `recommended_product_id` preselected, the plans behind a "See subscriptions"
    link at the bottom (tapping it shows them and preselects Weekly Pro).
  - The music-video quota sheet (P22) forwards its gap's `offer` to "See plans".
- **Weekly Pro** is in the fixed catalog (`proWeekly`, `billingCycle: weekly`, sort
  order first) and in `ios/Runner/Songlet.storekit` (4.99, intro offer pay-as-you-go
  2.49 for one week — local testing only; App Store Connect is the truth). Its
  benefits say "Fresh credits every week", never a number it does not know and never
  "unlimited". The price shows `/week` (`planPerWeek`, from the store's period; the
  old formatting called everything but yearly "/mo").
- **First-week discount is read, not typed.** The bridge's introductory offer
  (`payAsYouGo` / `payUpFront`, one period, still redeemable) gives the plan card its
  caption (`paywallIntroOffer`: percent from the offer's price against the regular
  price, period unit from the offer) and the selected plan a disclosure
  (`paywallIntroDisclosure`: intro price, then the recurring price, cancel before it
  renews — App Review 3.1.2). An offer over several periods, or one with no real
  discount, shows no caption.
- **Free copy is gone** (13 languages): "30-second preview", the lyric video's hint
  and price line, the automatic-video hint and the music-video entry subtitle no
  longer say free; the "No subscription" plan label replaces "Free plan"; Settings
  counts songs / previews only for a paid plan. The Pro Yearly 7-day trial is the
  App Store's and stays.
- **Every video costs credits, so none starts unseen.** The automatic lyric video
  gets the same cancellable 10 s countdown as the chorus video (nothing charged
  before it ends) and, like it, is never started after a restart
  (`AutoVideoCoordinator`; `mvAutoCountdown`). `MvLevel.isFree` is removed; the hub
  prices the lyric level (57) like the others.

## Consequences
The packs the paywall lists are the existing ones (`com.songlet.pack.10 / .50`, the
two music-video packs); a recommended id outside the fixed catalog is not
purchasable until it is added. `QuotaOffer` lives in `store/domain`.
