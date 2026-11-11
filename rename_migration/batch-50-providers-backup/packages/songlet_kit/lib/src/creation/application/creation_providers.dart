import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:media_kit/media_kit.dart';

import '../../library/application/music_library_providers.dart';
import '../data/music_generation_repository_impl.dart';
import '../data/music_remote_template_catalog.dart';
import '../domain/music_generation_repository.dart';
import '../domain/music_idea.dart';
import '../domain/music_inspiration.dart';
import '../domain/music_preflight.dart';
import '../domain/music_region_preset.dart';
import '../domain/music_template_samples.dart';
import 'music_draft_controller.dart';
import 'music_generation_controller.dart';
import 'music_generation_state.dart';
import 'music_job_runner.dart';
import 'music_lyric_language_preference.dart';
import 'music_template_sample_player.dart';

/// Composition root of the creation context.

final generationRepositoryProvider = Provider<MusicGenerationRepository>(
  (ref) => MusicGenerationRepositoryImpl(ref.watch(apiDioProvider)),
);

final photoUploaderProvider = Provider<MusicPhotoUploader>(
  (ref) => MusicMediaKitPhotoUploader(ref.watch(uploadServiceProvider)),
);

final preflightProvider = Provider<MusicPreflight>((ref) => MusicPreflight());

final jobRunnerProvider = Provider<MusicJobRunner>(
  (ref) => MusicJobRunner(
    jobs: ref.watch(generationRepositoryProvider),
    audio: ref.watch(audioStoreProvider),
    works: ref.watch(workRepositoryProvider),
  ),
);

/// The draft being built across occasion → region → input.
final creationDraftProvider =
    NotifierProvider<MusicCreationDraftController, MusicCreationDraftState>(
  MusicCreationDraftController.new,
);

final generationControllerProvider =
    NotifierProvider<MusicGenerationController, MusicGenerationState>(
  MusicGenerationController.new,
);

/// `GET /v1/templates`, fetched once per session for the template samples
/// and the inspirations alike (ADR-0029).
final _templateCatalogProvider = Provider<MusicRemoteTemplateCatalog>(
  (ref) => MusicRemoteTemplateCatalog(
    apiDio: ref.watch(apiDioProvider),
    downloadDio: ref.watch(audioDownloadDioProvider),
    cacheDir: () => ref.read(audioStoreProvider).scratchDirectory(),
  ),
);

final templateSampleSourceProvider = Provider<MusicTemplateSampleSource>((ref) => ref.watch(_templateCatalogProvider));

final inspirationSourceProvider = Provider<MusicInspirationSource>((ref) => ref.watch(_templateCatalogProvider));

/// The create home's MusicInspiration row (ADR-0029), sorted. An older server (no
/// field) or a failed fetch yields none: the row is simply not shown.
///
/// `GET /v1/templates` is bearer-authed and the shell shows before startup's
/// network half finishes, so it waits for the device to be attested: a fetch
/// sent earlier fails terminally and the empty answer would stick all session.
final inspirationsProvider = FutureProvider<List<MusicInspiration>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (auth is AuthError) return const <MusicInspiration>[];
  if (auth is! AuthAuthenticated) return Completer<List<MusicInspiration>>().future;
  try {
    return await ref.watch(inspirationSourceProvider).inspirations();
  } on Object {
    return const <MusicInspiration>[];
  }
});

/// The create home's tiles (ADR-0029, amended): the built-in templates
/// straight away, the server's inspirations merged in as they arrive.
final ideasProvider = Provider<List<MusicIdea>>(
  (ref) => buildIdeas(ref.watch(inspirationsProvider).value ?? const <MusicInspiration>[]),
);

/// The template sample playing on the create home, if any.
final templateSampleProvider =
    NotifierProvider<MusicTemplateSamplePlayer, String?>(MusicTemplateSamplePlayer.new);

/// Default lyrics language chosen in Settings (null = automatic).
final lyricLanguagePreferenceProvider =
    NotifierProvider<MusicLyricLanguagePreference, MusicLyricLanguage?>(MusicLyricLanguagePreference.new);
