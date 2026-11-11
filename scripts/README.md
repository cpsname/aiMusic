# Terminal dev toolkit (`dev.sh` / `logcat.sh`)

IDE-grade **Run console** and **Logcat panel** for developing Flutter in VS Code +
terminal — no Android Studio required.

| Script | Replaces | Covers |
|---|---|---|
| `dev.sh` | IDE **Run** | Dart / Flutter-layer logs of `flutter run` (iOS + Android) |
| `logcat.sh` | Android Studio **Logcat** | Android **system**-layer logs (`adb logcat`), auto re-attach on app restart |
| `check_config.sh` | — | dart-define config validator (called by the root Makefile's guards; generic CLI) |
| `asset_library_check.sh` | — | local acceptance of an app's App Store creative assets (`make asset-library`; the template's docs/store/asset-library-playbook.zh-CN.md) |
| `lib/devkit.sh` | — | shared library (root detection, picker, prefs, colorizer, logs) |

> iOS has no logcat — for iOS **system** logs use Console.app or `idevicesyslog`.

## Install (portable)
Copy the whole `scripts/` directory (at least `dev.sh`, `logcat.sh`, `lib/`) into any
Flutter project. No configuration: the project root is found by walking up to
`pubspec.yaml`, and `logcat.sh` reads `applicationId` from `android/app/build.gradle(.kts)`.

## Usage
```bash
./scripts/dev.sh                      # pick a device → run (reuses last; single device auto-selected)
./scripts/dev.sh -d <deviceId>        # explicit device (skips picker; scriptable)
./scripts/dev.sh -p | -r              # profile / release
./scripts/dev.sh --flavor dev -t lib/main_dev.dart   # extra args pass through to flutter run
./scripts/dev.sh --dart-define=API_BASE_URL=https://...   # override config (passed through)
./scripts/dev.sh -y                   # non-interactive (CI): reuse last / defaults

./scripts/logcat.sh                   # pick device → follow just this app's process
./scripts/logcat.sh -a                # whole system
./scripts/logcat.sh -s <serial>       # explicit device
```
Interactive keys pass straight through to `flutter run`: `r` hot reload · `R` hot
restart · `q` quit.

> Config (base URL, keys, …) is your app's own compile-time config (e.g.
> `String.fromEnvironment` defaults in the codebase). To override for a run, pass
> `--dart-define=…` or `--dart-define-from-file=…` — they go straight to `flutter run`.

## Features
- **Device picker** — no device flag? pick from `flutter devices` (or `adb devices`);
  one device is auto-selected; you can boot an emulator from the menu.
- **Remembers** your last device / mode per project (in `logs/.devkit-prefs`).
- **logcat auto re-attach** — `logcat.sh` follows the app process; when it is killed
  or restarted it waits for the new pid and re-attaches automatically (Android
  Studio parity); a device disconnect exits cleanly.
- **Strict option parsing** — a missing option argument (`-d`, `-s`, `--grep`, …)
  errors out immediately (exit 2); `--long=value` forms are accepted too.
- **Colored, timestamped logs** on screen; **plain text** mirrored to
  `logs/run_*.log` / `logs/logcat_*.log` (+ `latest.log` symlinks).
- **`dev.sh` run logs are ephemeral** — a run log lives only for that run and is
  removed on any termination (normal / error / interrupt / Ctrl-C / kill); a
  crash-orphaned log is reaped on the next start. Keep one for debugging with
  `--keep-log` (or `DEV_KEEP_LOG=1`; `DEV_KEEP_LOG=on-error` keeps only on a crash).
  `logcat.sh` logs still persist (newest 20 kept).
- **Log subcommands**: `--tail`, `--open`, `--grep <pat>`, `--list`, `--clean`.

## Log management
```bash
./scripts/dev.sh --tail               # follow the latest run log
./scripts/dev.sh --open               # open latest log ($EDITOR / code / open)
./scripts/dev.sh --grep "Exception"   # search across past run logs
./scripts/logcat.sh --list            # list logcat logs
```

## Environment knobs
- `NO_COLOR=1` — disable color · `FORCE_COLOR=1` — force color (e.g. piping to `less -R`)
- `DK_YES=1` (or `-y`) — never prompt (use last/defaults)
- `ANDROID_SERIAL` — default device for `logcat.sh`

## Config guard (`check_config.sh`)
A generic dart-define config validator, wired into the root Makefile's `GUARD`s
(the project-specific key list lives in the Makefile — this script stays portable):

```bash
./scripts/check_config.sh config/prod.json \
  --require BASE_URL --require APP_CODE \
  --no-placeholder --expect-env prod --https --no-localhost
./scripts/check_config.sh config/prod.json \
  --verify-xcconfig ios/Flutter/Generated.xcconfig   # decode DART_DEFINES + diff vs config
```

`--verify-xcconfig` guards the Xcode-Archive foot-gun: it decodes the generated
`DART_DEFINES` (base64 CSV) and fails when it no longer matches the config file
(secret-like values are redacted in messages). Exit codes: 0 pass · 1 validation
failed · 2 usage/env error.

## Requirements
`bash`, `perl` (both stock on macOS/Linux; `check_config.sh` uses perl core modules
`JSON::PP`/`MIME::Base64`), `flutter`; device/emulator enumeration for the picker
uses `python3` when present, else falls back to perl `JSON::PP` (with neither,
specify `-d`/`-s`); `adb` for `logcat.sh`. Works on macOS (BSD) and Linux
(util-linux) — `dev.sh` allocates a PTY via `script` so hot reload keeps working
through the colorizer.
