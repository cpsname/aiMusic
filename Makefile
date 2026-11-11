# Project task runner. The portable scripts/ toolkit stays config-agnostic; this
# Makefile injects the right config/<env>.json (--dart-define-from-file) for both
# `flutter run` and store builds, so you never run/ship with an empty BASE_URL.
# Every config-consuming target first validates the file's CONTENT via
# scripts/check_config.sh (all keys non-empty, no REPLACE placeholders, ENV field
# matches the target env); store builds additionally require an https,
# non-localhost BASE_URL, and the xcconfig targets verify the generated
# DART_DEFINES byte-for-byte against the config after generation.
#
#   make mock                Songlet dev mock backend on :8787 (mock_server/)
#   make run ENV=mock        debug run against the mock   (config/mock.json)
#   make acceptance          simulator acceptance run (XCUITest) vs the mock
#   make pigeon              regenerate the PRD §6.4 bridge (pigeons/songlet_api.dart)
#   make run                 debug run, picks a device     (config/dev.json)
#   make run DEVICE=<id>      ... on a specific device
#   make run ENV=staging     ... with config/staging.json
#   make logcat              Android system-layer logs     (scripts/logcat.sh)
#   make ipa                 App Store archive (.ipa)      (config/prod.json)
#   make aab                 Play Store app bundle         (config/prod.json)
#   make apk                 release APK                   (config/prod.json)
#   make ios                 iOS config-only build (gate)  (config/dev.json)
#   make macos               macOS config-only build (gate)(config/dev.json)
#   make macos-app           macOS release .app            (config/prod.json)
#   make macos-xcconfig      prep macOS Flutter-Generated.xcconfig as prod (Xcode Archive)
#   make verify-xcode-config 校验 Xcode 构建会烤进包里的 dart-define(XCCONFIG=<path>)
#   make shellcheck          lint the scripts/ toolkit (auto-skips if not installed)
#   make analyze | test | l10n | get | clean
#
# config/<env>.json is gitignored — copy config/dev.example.json and fill it.

ENV    ?= dev
DEVICE ?=
ARGS   ?=

CONFIG  = config/$(ENV).json
DEFINE  = --dart-define-from-file=$(CONFIG)
DEVFLAG = $(if $(DEVICE),-d $(DEVICE),)

# Config guards: existence + content. The project-specific key list lives HERE
# (scripts/check_config.sh itself stays copy-anywhere generic). GUARD_SHIP adds
# the store-build-only rules: https + non-localhost BASE_URL, plus SHIP_KEYS —
# the compile-time legal-link fallbacks (App Review 3.1.2): optional in dev,
# but a store package can never be built without functional Terms/Privacy URLs.
REQUIRED_KEYS = ENV BASE_URL DISTRIBUTION_CODE DISTRIBUTION_SECRET APP_CODE BUNDLE_ID IAP_CHANNEL
SHIP_KEYS = TERMS_URL PRIVACY_URL
# Production identity/address restrictions. Development and staging may use
# another app identity or backend for debugging; required keys still apply.
# Store-build targets enforce these rules even if ENV is overridden.
PLATFORM_HOSTS = genaistudio.showsapp.org localhost:9999 127.0.0.1:9999
SONGLET_RULES  = --expect APP_CODE=songlet \
                 --match 'DISTRIBUTION_CODE=^[a-z0-9]+(\.[a-z0-9-]+)+$$' \
                 $(foreach h,$(PLATFORM_HOSTS),--forbid-host $(h))
CHECKCFG   = bash scripts/check_config.sh $(CONFIG) $(foreach k,$(REQUIRED_KEYS),--require $(k)) --no-placeholder --expect-env $(ENV) $(if $(filter prod,$(ENV)),$(SONGLET_RULES),)
GUARD      = test -f $(CONFIG) || { echo "✗ missing $(CONFIG) — copy config/dev.example.json → config/$(ENV).json and fill it"; exit 1; }; $(CHECKCFG)
GUARD_SHIP = $(GUARD) $(if $(filter prod,$(ENV)),,$(SONGLET_RULES)) --https --no-localhost $(foreach k,$(SHIP_KEYS),--require $(k))

# Xcode 侧闸门。GUARD/GUARD_SHIP 只在走 make 时生效,Xcode 的 Run / Archive 按钮
# 绕开它们 —— 所以同一份 key 清单也挂在 Runner target 的「Verify Build Config」
# build phase 上(它回头调用下面这个 target)。
XCCONFIG_IOS   = ios/Flutter/Generated.xcconfig
XCCONFIG_MACOS = macos/Flutter/ephemeral/Flutter-Generated.xcconfig
XCCONFIG      ?= $(XCCONFIG_IOS)
VERIFY_XC      = bash scripts/verify_xcode_config.sh $(XCCONFIG) $(foreach k,$(REQUIRED_KEYS),--require $(k)) $(SONGLET_RULES)

.DEFAULT_GOAL := help
.PHONY: help mock store-preview asset-library acceptance integration perf diff-report pigeon run logcat ipa aab apk ios xcconfig verify-xcode-config macos macos-app macos-xcconfig analyze test arch gates shellcheck l10n get clean

help: ## show this help
	@grep -hE '^[a-z][a-zA-Z-]*:.*##' $(MAKEFILE_LIST) | sed -E 's/:.*## /\t— /' | sort

# Songlet dev loop. The mock implements docs/songlet/backend-contract.md; the
# acceptance run drives the app on a simulator against it (see
# docs/songlet/acceptance.md). SIM=<simulator udid> picks the device.
SIM ?= $(shell xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -1)

mock: ## Songlet mock backend on :8787 (Ctrl-C to stop)
	dart run mock_server/bin/server.dart --port 8787

# The default run: previews A and B, the footage-only script W, and every
# creative asset (header, search results, custom product pages) with the
# assets manifest. The defaults are target-specific so the recipes stay the
# template's (`store_preview integrate --check`) and ARGS keeps no default
# for `run` / `logcat`. Kept in a variable: a comma inside $(or …) would
# split it.
STORE_PREVIEW_DEFAULT := render --app songlet --scripts A,B,W --locales all

store-preview: ## App Store previews + creative assets (packages/store_preview/README.md): 12 storefronts, iPhone 6.9" → dist/songlet (+ assets-manifest.json); ARGS="validate --app songlet" etc.
	dart run store_preview $(ARGS)
store-preview: ARGS := $(or $(ARGS),$(STORE_PREVIEW_DEFAULT))

asset-library: ## creative assets' local acceptance, offline (template docs/store/asset-library-playbook.zh-CN.md): APP=songlet — assets, manifest, ascpub's listing checks
	bash scripts/asset_library_check.sh $(APP)
asset-library: APP ?= songlet

acceptance: ENV = mock
acceptance: l10n ## simulator acceptance (XCUITest) against a running `make mock` (SIM=<udid>)
	@$(GUARD)
	@test -n "$(SIM)" || { echo "✗ no booted simulator — boot one or pass SIM=<udid>"; exit 1; }
	@curl -fsS -o /dev/null http://localhost:8787/__admin/state || { echo "✗ mock not running — start it with 'make mock'"; exit 1; }
	flutter build ios --simulator --debug $(DEFINE)
	cd ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner \
		-parallel-testing-enabled NO -destination 'platform=iOS Simulator,id=$(SIM)' \
		-only-testing:RunnerUITests

integration: ENV = mock
integration: l10n ## first-session integration_test on a simulator against a running `make mock` (SIM=<udid>)
	@$(GUARD)
	@test -n "$(SIM)" || { echo "✗ no booted simulator — boot one or pass SIM=<udid>"; exit 1; }
	@curl -fsS -o /dev/null http://localhost:8787/__admin/state || { echo "✗ mock not running — start it with 'make mock'"; exit 1; }
	flutter test integration_test/first_session_test.dart -d $(SIM) $(DEFINE)

perf: l10n ## first session in profile mode on a device (DEVICE=<id>, ENV=<env> whose BASE_URL the device reaches) → build/integration_response_data.json
	@$(GUARD)
	@test -n "$(DEVICE)" || { echo "✗ pass DEVICE=<device id> (profile mode needs a physical device)"; exit 1; }
	flutter drive --profile --driver=test_driver/integration_test.dart --target=integration_test/first_session_test.dart -d $(DEVICE) $(DEFINE)

diff-report: l10n ## prototype fidelity report → docs/ui/diff-report.md + docs/ui/diff/ (ADR-0007)
	flutter test test/pages/design_capture_test.dart
	dart run tool/diff_report/diff_report.dart

pigeon: ## regenerate the Pigeon bridge (Swift + Dart) from pigeons/songlet_api.dart
	dart run pigeon --input pigeons/songlet_api.dart

run: l10n ## debug run on a device (DEVICE=<id> ARGS=... ENV=dev)
	@$(GUARD)
	bash scripts/dev.sh $(DEVFLAG) $(ARGS) $(DEFINE)

logcat: ## Android system-layer logs (ARGS=... passes through to scripts/logcat.sh)
	bash scripts/logcat.sh $(ARGS)

ipa: ENV = prod
ipa: l10n ## App Store archive → build/ios/ipa/*.ipa (config/prod.json)
	@$(GUARD_SHIP)
	flutter build ipa --release $(DEFINE)

aab: ENV = prod
aab: l10n ## Play Store app bundle (config/prod.json)
	@$(GUARD_SHIP)
	flutter build appbundle --release $(DEFINE)

apk: ENV = prod
apk: l10n ## release APK (config/prod.json)
	@$(GUARD_SHIP)
	flutter build apk --release $(DEFINE)

ios: l10n ## iOS config-only build, no signing — Gate 3 (config/$(ENV).json)
	@$(GUARD)
	flutter build ios --config-only --no-codesign $(DEFINE)

xcconfig: ENV = prod
xcconfig: l10n ## prep ios/Flutter/Generated.xcconfig for an Xcode Archive (ENV=prod)
	@$(GUARD_SHIP)
	flutter build ios --config-only --release --no-codesign $(DEFINE)
	@bash scripts/check_config.sh $(CONFIG) --verify-xcconfig ios/Flutter/Generated.xcconfig
	@echo "✓ Generated.xcconfig now holds ENV=$(ENV) ($(CONFIG)) — Archive in Xcode now."
	@echo "  ⚠ a later 'make run' reverts it to dev; re-run 'make xcconfig' before re-archiving."

verify-xcode-config: ## 校验 Xcode 构建会烤进包里的 dart-define(XCCONFIG=<path>,CONFIGURATION=Release 时要求 prod)
	@$(VERIFY_XC)

macos: l10n ## macOS config-only build, gate (config/$(ENV).json)
	@$(GUARD)
	flutter build macos --config-only $(DEFINE)

macos-app: ENV = prod
macos-app: l10n ## macOS release .app → build/macos/Build/Products/Release (config/prod.json)
	@$(GUARD_SHIP)
	flutter build macos --release $(DEFINE)

macos-xcconfig: ENV = prod
macos-xcconfig: l10n ## prep macos/Flutter/ephemeral/Flutter-Generated.xcconfig for an Xcode Archive (ENV=prod)
	@$(GUARD_SHIP)
	flutter build macos --config-only --release $(DEFINE)
	@bash scripts/check_config.sh $(CONFIG) --verify-xcconfig macos/Flutter/ephemeral/Flutter-Generated.xcconfig
	@echo "✓ macOS Flutter-Generated.xcconfig now holds ENV=$(ENV) ($(CONFIG)) — Archive in Xcode now."
	@echo "  ⚠ a later 'make run' reverts it to dev; re-run 'make macos-xcconfig' before re-archiving."

# analyze/test regenerate l10n first: lib/l10n/generated/ is git-ignored build
# output, so a fresh clone (and CI) would otherwise fail on missing files.
analyze: l10n ## static analysis: app + all packages
	flutter analyze

arch: ## Gate 6 — architecture-boundary check (no reverse/cross-layer imports)
	dart run arch_guard

test: l10n ## app + package tests (+ the mock backend's own tests)
	flutter test
	@# The DEV-only Keychain reset is a compile-time gate: run its test as a DEV build too.
	flutter test test/pages/dev_keychain_reset_test.dart --dart-define=ENV=dev
	dart run melos exec --ignore=songlet_mock_server -- flutter test
	cd mock_server && dart test

shellcheck: ## lint the scripts/ toolkit (auto-skips when shellcheck is not installed)
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -x -P SCRIPTDIR scripts/dev.sh scripts/logcat.sh scripts/check_config.sh scripts/verify_xcode_config.sh scripts/asset_library_check.sh scripts/lib/devkit.sh && echo "✓ shellcheck clean"; \
	else \
		echo "⚠ shellcheck not installed — skipped (brew install shellcheck)"; \
	fi

gates: ## all quality gates: analyze → arch → app+package tests → iOS config-only → shellcheck
	@$(MAKE) analyze
	@$(MAKE) arch
	@$(MAKE) test
	@$(MAKE) ios
	@$(MAKE) verify-xcode-config
	@$(MAKE) shellcheck
	@echo "✓ all gates green — analyze · arch · tests (app+packages) · ios config-only · xcode config · shellcheck"

l10n: ## stage the 13 locale resources and regenerate localizations
	dart tool/l10n/prepare.dart
	flutter gen-l10n

get: ## resolve the whole workspace
	dart tool/l10n/prepare.dart
	flutter pub get

clean: ## flutter clean
	flutter clean
