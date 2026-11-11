# Existing architecture — analysis before the P01–P18 build

Scope: everything already in the repo that the prototype build (docs/ui P01–P18)
must reuse instead of re-implementing. Read before any change; ADRs in
`docs/adr/` record where the P-series spec and this code base disagree.

## 1. Module map (dependency direction is one-way, enforced by arch_guard)

```
lib/ (app: routes, pages, l10n)
  ├─► packages/songlet_kit   business core (domain / data / application)
  │      ├─► packages/commerce_kit   auth · IAP orchestration · wallet (reused via overrides)
  │      ├─► packages/media_kit      presigned photo upload
  │      └─► packages/infra_core     network chain · errors · storage · telemetry · config
  ├─► packages/app_config    maintenance / kill switches / remote config
  └─► packages/ui_kit        design tokens + presentation primitives (no providers, no l10n)
packages/arch_guard (dev)   layering + no hardcoded left/right in UI (Gate 6)
mock_server/ (dev)          Songlet backend mock (contract in docs/songlet/backend-contract.md)
ios/Runner/Songlet/*.swift  PRD §6.4 bridge implementation + share-card encoder
```

| Layer | Owner | What exists (file) | Reuse rule |
| --- | --- | --- | --- |
| Transport | infra_core | `network/dio_factory.dart` (device → auth → signature → clock-sync → retry → envelope → logging), `interceptors/*` | All Songlet calls go through `apiDio`/`authDio`; never a second HTTP stack. |
| Errors | infra_core | `error/api_error.dart` (sealed, `errorCode`), `error/failure.dart` (sealed, `errorCode`, `NetworkFailureKind`), `error/error_handler.dart` | PRD §6.5 codes ride `Failure.errorCode`; `SongletErrorCode` (songlet_kit) is the only mapping table. |
| Storage | infra_core | `storage/key_value_store.dart`, `storage_migrator.dart`, `secure_token_store.dart` | Preferences + Keychain; schema migrations through the migrator. |
| Telemetry | infra_core | `observability/*` (`RedactingTelemetrySink`, no-op in release) | No third-party analytics (PRD §6.2). |
| Identity | commerce_kit + songlet_kit | `AuthController` + `AttestAuthRepository` (App Attest) | Device token lifecycle stays in `AuthController`. |
| Purchases | commerce_kit + songlet_kit | `IapPurchaseOrchestrator`, `IapBackgroundReconciler`, `PigeonStoreClient`, `SongletIapRepository`, `EntitlementSync` | Paywall only calls the orchestrator; entitlement is server truth (`songletEntitlementProvider`). |
| Creation | songlet_kit/creation | `CreationDraft`, `Preflight` (+ `LyricsFingerprintIndex`), `PromptBlock`, `RegionPresets`, `Occasion`/`Festival`, `GenerationController` → `JobRunner` | New composer UI edits the same `CreationDraft`; generation keeps one controller. |
| Library | songlet_kit/library | `Work`, `SqliteWorkRepository` (App Group), `FileAudioStore` (ID3 tag), `LibraryController` (resumes pending jobs) | Library pages read `libraryProvider`; schema evolves via `onUpgrade`. |
| Playback | songlet_kit/playback | `PlayerController` over `AudioEngine` (bridge `playAudio`) | One app-wide player; lock screen state arrives only via progress callback. |
| Export | songlet_kit/export | `ExportService` (MP3 + lyrics + license PDF → Files), `LicenseRepository`, `Id3Tagger` | Download page composes these; the license endpoint is the download gate. |
| Share | songlet_kit/share + app | `ShareCardService` + `VideoComposer` (AVAssetWriter channel), `ShareCardRenderer` (dart:ui frames, badge burned in) | Share-card page adds themes/layouts to the renderer, not a new pipeline. |
| Design system | ui_kit | `StudioTokens`, `SongletPalette`, `AuraTheme.warm`, `AuraStyle` extension, `GlassCard`, `ObsButton`, `PillChip`, `WaveformView`, `AiGeneratedBadge`, `StatusView`, Message stack, `MotionPolicy` | P-series tokens/components extend ui_kit; the app never defines colours/sizes. |
| App shell | lib/ui | `StartupGate`, `MaintenanceGate`, `SongletShell` (tabs), `failure_copy.dart`, `ErrorRetryView`, `messages.dart`, `external_links.dart`, `test_id.dart` | Reused as-is by the new pages. |

## 2. Business flows as implemented

1. **Startup** — `StartupGate` waits only for preferences, activates `NativeBridge` +
   `IapBackgroundReconciler`, runs `StartupController.start()` behind the shell
   (device profile → storage migration → catalog → App Attest). Offline keeps the
   library usable.
2. **Create** — draft (`CreationDraftController`) → `Preflight.check` →
   `GenerationController.generate`: auth → on-device polish → media_kit upload
   (photos) → `POST /v1/generate` → `JobRunner` polls `/v1/jobs` → audio downloaded +
   ID3-tagged → `Work` stored → wallet invalidated (ledger refresh).
3. **Purchase** — paywall → `IapPurchaseOrchestrator.purchase` → local order →
   `PigeonStoreClient.buy` (StoreKit 2) → JWS into the outbox → `SongletIapRepository.verify`
   = `EntitlementSync.sync()` → `songletEntitlementProvider` refresh.
   `Transaction.updates` → outbox → reconciler → sync.
4. **Download** — `WorkActions.download` → license (`/v1/license`, the refund/plan gate)
   → folder (MP3 + lyrics.txt + license.pdf) → `exportToFiles`.
5. **Share** — `ShareCardRenderer` frames → `ShareCardService.compose` (MP4) → share sheet.

## 3. Gaps against the P-series prototypes (what is genuinely new)

| Gap | Where it lands (reuse first) |
| --- | --- |
| Template grid (16 templates) + floating composer card with Length / Vocals / Genre selectors, Preview/Full, mic, "+" (photos) | New `creation/domain/template.dart` + `genre.dart` + `vocals` / `length` on `CreationDraft`; composer + anchored panels in ui_kit; page in `lib/ui/create/`. `PromptBlock` gains `vocals`, `note` from the free-text prompt. |
| 18 genres for every region + "Popular in {country}" | `Genre` catalogue in songlet_kit; `RegionPreset.genres` stays the recommendation list. |
| Region list as a sheet, lyrics-language row; **no availability blocking** | Reuse `RegionPresets`; delete `regionBlockedProvider` + client REGION_UNAVAILABLE copy (ADR-0005). |
| Voice input (on-device transcription) | New native channel beside the fixed Pigeon bridge (ADR-0006) + `SpeechGateway` domain port. |
| Queue position / progress / lyric glimpse / cancel on the generating page | Contract additions on `/v1/jobs` + `DELETE /v1/jobs/{id}` (docs/songlet/backend-contract.md, platform hand-off); `JobSnapshot` gains the fields. |
| Clip player with timed lyric lines; full player with section markers, prev/next section, shuffle | `LyricBlock` + `structure` already exist; waveform section markers in ui_kit. |
| Share card themes (4) × layouts (2) | `ShareCardRenderer` parameters; same compose pipeline. |
| Download page: MP3 + WAV (Premier) + license details | `ExportService` gains format; contract adds `wav_url` for Premier jobs. |
| Library filters, "See all", Preview/Full badges, more-menu; work detail with prompt/ID/regenerate/delete | Reuse `libraryByOccasionProvider`, `draftFromWork`, `LibraryController.delete`. |
| Settings (no prototype), About generation, festival landing, generic "temporarily unavailable", inline error states | Reuse `SettingsPage`, `AboutGenerationPage`, `Festival.available`, `StatusView`, `Preflight` issues. |
| Typed routes + deep links | Add go_router (no router exists today — not a duplicate); routes replace `Navigator.push` calls (ADR-0003). |

## 4. Things deliberately **not** rebuilt (would duplicate working code)

Riverpod code generation, freezed/json_serializable, drift and a `Result<T, AppError>`
type would each replace a working, tested mechanism (hand-written providers + arch_guard,
immutable models + DTO mappers, the sqflite repository behind `WorkRepository`, the
`ErrorHandler → Failure` funnel). See ADR-0002.
