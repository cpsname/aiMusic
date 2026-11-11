# Performance — method and results

Budgets from the phase-6 spec: **first frame ≤ 300 ms**, **60 fps** while scrolling
and playing, **no leak** across the main flows. What is measured where, and what is
still open, is stated per budget below.

## How it is measured

| Budget | Instrument | Where it runs |
| --- | --- | --- |
| No leak | Flutter's leak tracker (`test/perf/leak_test.dart`): every disposable created while the main flows are driven page to page — controllers, focus nodes, tickers, notifiers, pictures, images — must be disposed | `flutter test` (every CI run) |
| Frame times | `IntegrationTestWidgetsFlutterBinding.watchPerformance` over flings of the playing preview (`integration_test/first_session_test.dart`); where the engine reports no frame timings (a headless simulator may not), the flings still run and `preview_scroll` says so instead of the run waiting on them | `make integration SIM=…` (debug) · `make perf DEVICE=…` (profile) |
| Open → interactive / first listen | the same integration test: `main()` → create home tappable, and → preview playing | same |
| Layout cost at every size | the device-matrix sweep (`test/pages/device_matrix_test.dart`): 40 page states (P01–P30 and the composer's states) × 6 devices × default and AX5 text, any overflow fails; the composer's space rules measured per device × state × keyboard (`test/pages/composer_layout_test.dart`, ADR-0034) | `flutter test` |

Flutter builds only **debug** (JIT, assertions on) for the iOS simulator; profile and
release need a physical device. Simulator numbers are therefore upper bounds for
build-side work and meaningless for GPU raster, and they are labelled "debug" in the
test report.

## Results (2026-09-24)

### Leaks — ✅ none
`test/perf/leak_test.dart` drives: create home → the three panels → template form
(typing) → region sheet → voice mode → home; preview → paywall → song → download →
share card → library → work detail → settings → about → festival; generating
(waiting) → success → preview; and (2026-09-29) the music-video flow: hub →
credits sheet → progress → the video player → the song page's video entry.
**0 not-disposed objects.** Decoded art held by the
global `ImageCache` is emptied before the check (it is retained by design, not
leaked). The check was shown to catch a deliberately leaked `TextEditingController`.

### Frames — debug build, iPhone 17 Pro simulator (iOS 26.5)
Flinging the playing 30 s preview up and down three times (244 frames):

| | Build (UI thread) | Raster |
| --- | --- | --- |
| Average | 2.4 ms | 0.7 ms |
| 90th percentile | 6.9 ms | 1.0 ms |
| 99th percentile | 16.6 ms | 1.2 ms |
| Worst | 18.0 ms | — |
| Frames over the 16.7 ms budget | 4 of 244 | 0 |

Even in debug, 98 % of frames build inside the 60 fps budget; profile-mode AOT code
is typically several times faster than debug JIT, so the device run is expected to
clear it — but that is an expectation until `make perf` has been run on a device.

### Open → first listen — ✅ well inside the PRD §13.2 budget
- Integration test, debug, mock clip latency 4 s: create home interactive after
  **0.68 s**, preview playing **6.1 s** after `main()`.
- XCUITest acceptance (`docs/songlet/acceptance.md`), cold launch, mock clip latency
  8 s: **29.2 s** open → playing (includes typing the form through XCUITest).

### First frame ≤ 300 ms — ⏳ needs a device run
Not measurable on the simulator (debug JIT start-up dominates). The app keeps the
first frame cheap by construction: `main()` does no I/O before `runApp`; the
`StartupGate` splash is the first frame and only preferences are awaited behind it;
attestation, entitlement sync and the catalog load after the shell is up (CLAUDE.md
"Startup"). To measure: `make perf DEVICE=<id>` for the in-app timings, and Xcode
Instruments' *App Launch* template (or `XCTApplicationLaunchMetric`) on a release
build for the OS-level launch → first frame.

## Running the device measurement

1. Sign the Runner with a team that owns `com.songlet.ios`, the App Group, App Attest
   and the iCloud container (see `docs/RELEASE_CHECKLIST.md`).
2. Run the mock where the phone can reach it (`make mock` binds all interfaces) and
   point a config at it: `BASE_URL=http://<mac-lan-ip>:8787/v1` in `config/<env>.json`.
3. `make perf DEVICE=<device id> ENV=<env>` — `flutter drive --profile` writes the
   report to `build/integration_response_data.json` (`preview_scroll` frame stats,
   `create_home_interactive_ms`, `open_to_first_listen_ms`, `build: profile`).
