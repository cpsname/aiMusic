import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:media_kit/media_kit.dart';

import '../../library/application/library_providers.dart';
import '../data/generation_repository_impl.dart';
import '../data/remote_template_catalog.dart';
import '../domain/generation_repository.dart';
import '../domain/idea.dart';
import '../domain/inspiration.dart';
import '../domain/preflight.dart';
import '../domain/region_preset.dart';
import '../domain/template_samples.dart';
import 'draft_controller.dart';
import 'music_generation_controller.dart';
import 'generation_state.dart';
import 'job_runner.dart';
import 'music_lyric_language_preference.dart';
import 'music_template_sample_player.dart';

/// Composition root of the creation context.

final generationRepositoryProvider = Provider<GenerationRepository>(
  (ref) => GenerationRepositoryImpl(ref.watch(apiDioProvider)),
);

final photoUploaderProvider = Provider<PhotoUploader>(
  (ref) => MediaKitPhotoUploader(ref.watch(uploadServiceProvider)),
);

final preflightProvider = Provider<Preflight>((ref) => Preflight());

final jobRunnerProvider = Provider<JobRunner>(
  (ref) => JobRunner(
    jobs: ref.watch(generationRepositoryProvider),
    audio: ref.watch(audioStoreProvider),
    works: ref.watch(workRepositoryProvider),
  ),
);

/// The draft being built across occasion → region → input.
final creationDraftProvider =
    NotifierProvider<CreationDraftController, CreationDraftState>(
  CreationDraftController.new,
);

final generationControllerProvider =
    NotifierProvider<MusicGenerationController, GenerationState>(
  MusicGenerationController.new,
);

/// `GET /v1/templates`, fetched once per session for the template samples
/// and the inspirations alike (ADR-0029).
final _templateCatalogProvider = Provider<RemoteTemplateCatalog>(
  (ref) => RemoteTemplateCatalog(
    apiDio: ref.watch(apiDioProvider),
    downloadDio: ref.watch(audioDownloadDioProvider),
    cacheDir: () => ref.read(audioStoreProvider).scratchDirectory(),
  ),
);

final templateSampleSourceProvider = Provider<TemplateSampleSource>((ref) => ref.watch(_templateCatalogProvider));

final inspirationSourceProvider = Provider<InspirationSource>((ref) => ref.watch(_templateCatalogProvider));

/// The create home's Inspiration row (ADR-0029), sorted. An older server (no
/// field) or a failed fetch yields none: the row is simply not shown.
///
/// `GET /v1/templates` is bearer-authed and the shell shows before startup's
/// network half finishes, so it waits for the device to be attested: a fetch
/// sent earlier fails terminally and the empty answer would stick all session.
final inspirationsProvider = FutureProvider<List<Inspiration>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (auth is AuthError) return const <Inspiration>[];
  if (auth is! AuthAuthenticated) return Completer<List<Inspiration>>().future;
  try {
    return await ref.watch(inspirationSourceProvider).inspirations();
  } on Object {
    return const <Inspiration>[];
  }
});

/// The create home's tiles (ADR-0029, amended): the built-in templates
/// straight away, the server's inspirations merged in as they arrive.
final ideasProvider = Provider<List<Idea>>(
  (ref) => buildIdeas(ref.watch(inspirationsProvider).value ?? const <Inspiration>[]),
);

/// The template sample playing on the create home, if any.
final templateSampleProvider =
    NotifierProvider<MusicTemplateSamplePlayer, String?>(
      MusicTemplateSamplePlayer.new,
    );

/// Default lyrics language chosen in Settings (null = automatic).
final lyricLanguagePreferenceProvider =
    NotifierProvider<MusicLyricLanguagePreference, LyricLanguage?>(MusicLyricLanguagePreference.new);
