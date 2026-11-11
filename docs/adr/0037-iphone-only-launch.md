# ADR-0037 — Launch iPhone-only; decide on iPad after the first wave's data
Status: Accepted
Date: 2026-10-05
Amends ADR-0018 and the phase-5 adaptive layout (`WindowClass.regular`): the iPad
two-column layouts stay in the code but are switched off.

## Context
The Runner target ships for iPhone only: `TARGETED_DEVICE_FAMILY = 1` in Debug,
Release and Profile, so the built app's `UIDeviceFamily` is `[1]`. On an iPad,
iPadOS runs it in a phone-sized compatibility window. The code nevertheless
carried an iPad side: two-column layouts behind `WindowClass.regular` (the
navigation rail, the create home's side-by-side grid and composer, the
festival grid's four columns, the video hub and the landscape video player
beside its panel, the wider gutter), iPad devices in the golden and layout
matrix, and the iPad-only goldens P21 and P27. It was tested, but no user can
see it.

The App Store previews made the gap concrete. An iPad preview filmed on the
iPad Pro 13" simulator shows the phone window floating over the home-screen
wallpaper, which is not an iPad app experience (App Review 2.3.4).

## Decision
- **Launch iPhone-only.** `TARGETED_DEVICE_FAMILY` stays `1`. Whether to ship
  for iPad is decided after the first wave's data (PRD §11.1: storefronts, iPad
  share of installs from App Store analytics, reviews asking for it).
- **One switch for everything iPad.** `ipadEnabled` (`lib/ui/common/device_family.dart`,
  a compile-time constant, `false`) gates:
  - `WindowClass.of`: regular only when the switch is on. Every two-column branch
    goes through it, so on iPhone (portrait only, ≤ 440 pt) nothing changes.
  - The iPad devices of `TestDevice.matrix` (device matrix and review goldens).
  - The iPad-only tests: page goldens defined by an iPad layout (P21, P27, via
    `TestDevice.skipped`) and the regular-width / landscape video tests in
    `test/pages/mv_test.dart`.
  - The iPad App Store previews: the preview tool (now `packages/store_preview`,
    ADR-0038) records the iPhone 6.9"
    slot by default, and refuses `--devices ipad` while the built app's
    `UIDeviceFamily` lacks 2.
- **Kept, not deleted.** The layouts, the iPad goldens under `test/goldens/` and the
  pipeline's 1200 × 1600 slot stay in the repo, dormant.
- **They change together.** `test/governance/device_family_test.dart` reads the
  Runner configurations from `project.pbxproj` and fails unless `ipadEnabled` is
  `true` exactly when `TARGETED_DEVICE_FAMILY` contains 2.

## Turning iPad on
1. Set `TARGETED_DEVICE_FAMILY = "1,2"` on the Runner's Debug, Release and Profile.
2. Set `ipadEnabled = true`.
3. Run `make test`. The iPad goldens and tests run again; review and update them
   (the layouts have not been reviewed since this decision).
4. Produce the iPad previews with `make store-preview ARGS="render --app songlet --devices iphone,ipad"` (add `ipad` to `store_preview/songlet/app.yaml` devices).

## Consequences
- `make test` skips 4 tests and the iPad review goldens, and checks the switch
  against the project file.
- App Store Connect asks for no iPad screenshots or previews.
- The 36 preview files are iPhone 6.9" only. The 72 of the original plan need step 4.
