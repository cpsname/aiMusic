#!/usr/bin/env bash
#
# asset_library_check.sh — local acceptance of an app's App Store creative assets
# (the Asset Library flow: docs/store/asset-library-playbook.zh-CN.md). Offline: no
# App Store Connect call, no credential.
#
#   1. store-preview: the configuration, with the shelves (header and search results of
#      the default page, each custom product page, each PPO treatment) against ascpub's
#      listing; then every rendered creative asset (spec · compliance · narrative) and
#      the assets manifest re-measured against its files.
#   2. ascpub (offline): the listing — bindings, counters, treatments — against the
#      manifest, the files re-probed and Apple's spec catalogue (its bundled snapshot).
#
# Usage: scripts/asset_library_check.sh <app>        (make asset-library APP=<app>)
#   ASCPUB=<command>  the ascpub command (default: ascpub; from its checkout:
#                     `npm run build && npm link`)
#
# Exit: 0 every check passes · 1 a check fails · 2 usage or a missing tool
#
set -euo pipefail

# Resolve from this script, so a caller's current directory cannot select
# another app's workspace or listing.
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

app="${1:-}"
if [[ -z "$app" ]]; then
  echo "usage: scripts/asset_library_check.sh <app>   (make asset-library APP=<app>)" >&2
  exit 2
fi
ascpub="${ASCPUB:-ascpub}"
if ! command -v "$ascpub" >/dev/null 2>&1; then
  echo "✗ $ascpub not found: in the ascpub checkout run \`npm run build && npm link\`, or set ASCPUB" >&2
  exit 2
fi

echo "▶ store-preview: vendor integrity and app integration"
dart run store_preview vendor --check
dart run store_preview integrate --check

echo "▶ store-preview: the shelves in ascpub's listing"
dart run store_preview listing --app "$app"
echo "▶ store-preview: the configuration, every creative asset, the assets manifest"
dart run store_preview validate --app "$app" --only creatives

listing="$(dart run store_preview listing --app "$app" --dir)"
root="$(dirname "$listing")"
bundle="$(basename "$listing")"
echo "▶ ascpub (offline): $listing"
"$ascpub" assets validate -l "$root" -b "$bundle"
"$ascpub" cpp validate -l "$root" -b "$bundle"
"$ascpub" ppo validate -l "$root" -b "$bundle"
echo "✓ $app: the creative assets, the shelves and ascpub's listing agree — ready for \`ascpub assets push --dry-run\`"
