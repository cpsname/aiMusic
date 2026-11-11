/// songlet_kit — Songlet business core (PRD §4 F01–F14).
///
/// * creation — occasions, the 14 region presets, preflight, the Lyria job
///   pipeline (`/v1/generate` → `/v1/jobs`), on-device prompt polish;
/// * library — local SQLite works + audio in the App Group container;
/// * store — StoreKit 2 over the PRD §6.4 Pigeon bridge, bound into
///   commerce_kit (orchestrator / reconciler / auth / wallet) through
///   [songletKitOverrides], with the `/v1/entitlements/sync` ledger;
/// * mv — music videos from a finished song (`/v1/mv/*`, PRD ch.15): estimate,
///   create, real-progress polling, the local video library;
/// * playback, export (Files + license PDF + ID3 AI tag), share (9:16 video).
///
/// Layered domain / data / application, hand-written Riverpod providers.
library;

export 'src/creation/application/music_creation_providers.dart';
export 'src/creation/application/music_draft_controller.dart';
export 'src/creation/application/music_generation_controller.dart';
export 'src/creation/application/music_generation_state.dart';
export 'src/creation/application/music_job_runner.dart' show MusicJobTimeoutException;
export 'src/creation/application/music_lyric_language_preference.dart';
export 'src/creation/application/music_template_sample_player.dart';
export 'src/creation/domain/music_creation_draft.dart';
export 'src/creation/domain/music_draft_codec.dart';
export 'src/creation/domain/music_generation.dart';
export 'src/creation/domain/music_generation_repository.dart';
export 'src/creation/domain/music_genre.dart';
export 'src/creation/domain/music_idea.dart';
export 'src/creation/domain/music_inspiration.dart';
export 'src/creation/domain/music_lyrics_formatter.dart';
export 'src/creation/domain/music_occasion.dart';
export 'src/creation/domain/music_preflight.dart';
export 'src/creation/domain/music_prompt_block.dart';
export 'src/creation/domain/music_region_preset.dart';
export 'src/creation/domain/music_song_options.dart';
export 'src/creation/domain/music_song_template.dart';
export 'src/creation/domain/music_error_code.dart';
export 'src/creation/domain/music_template_samples.dart';
export 'src/export/application/music_export_providers.dart';
export 'src/export/application/music_export_service.dart';
export 'src/export/domain/id3_tagger.dart';
export 'src/export/domain/music_license_repository.dart' show MusicLicenseDocument;
export 'src/identity/application/music_dev_keychain_reset.dart';
export 'src/library/application/music_library_providers.dart';
export 'src/library/application/music_library_sync.dart';
export 'src/library/domain/music_cloud_sync.dart';
export 'src/library/domain/music_work.dart';
export 'src/library/domain/music_work_repository.dart';
export 'src/mv/application/music_auto_video_coordinator.dart';
export 'src/mv/application/music_mv_controller.dart';
export 'src/mv/application/music_mv_launcher.dart';
export 'src/mv/application/music_mv_notifications.dart';
export 'src/mv/application/music_mv_providers.dart';
export 'src/mv/application/music_mv_runner.dart';
export 'src/mv/application/music_mv_state.dart';
export 'src/mv/domain/music_video.dart';
export 'src/mv/domain/music_mv.dart';
export 'src/mv/domain/music_mv_intent.dart';
export 'src/mv/domain/music_mv_repository.dart';
export 'src/platform/application/music_platform_providers.dart';
export 'src/platform/domain/music_local_notifications.dart';
export 'src/platform/domain/music_native_gateways.dart';
export 'src/playback/application/music_player_controller.dart';
export 'src/playback/domain/music_playback_state.dart';
export 'src/share/application/music_share_card_service.dart';
export 'src/share/application/music_share_providers.dart';
export 'src/speech/application/music_dictation_controller.dart';
export 'src/speech/application/music_speech_providers.dart';
export 'src/speech/domain/music_speech_gateway.dart';
export 'src/store/application/music_store_providers.dart';
export 'src/store/application/music_storefront_controller.dart';
export 'src/store/domain/music_quota_offer.dart';
export 'src/store/domain/music_signed_transaction.dart';
export 'src/store/domain/music_catalog.dart';
export 'src/store/domain/music_entitlement.dart';
