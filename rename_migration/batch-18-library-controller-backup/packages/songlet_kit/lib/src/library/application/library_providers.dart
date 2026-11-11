import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../creation/application/creation_providers.dart';
import '../../creation/domain/occasion.dart';
import '../../mv/application/mv_providers.dart';
import '../data/channel_cloud_sync.dart';
import '../data/file_audio_store.dart';
import '../data/library_location.dart';
import '../data/sqlite_work_repository.dart';
import '../domain/cloud_sync.dart';
import '../domain/work.dart';
import '../domain/work_repository.dart';
import 'music_library_sync.dart';

/// Composition root of the local library (PRD F10).

final libraryLocationProvider = Provider<LibraryLocation>((ref) => LibraryLocation());

final workRepositoryProvider = Provider<WorkRepository>((ref) {
  final location = ref.watch(libraryLocationProvider);
  return SqliteWorkRepository(
    () async => openWorkDatabase(await location.databasePath()),
  );
});

/// Plain Dio for audio downloads from pre-signed object-storage links.
final audioDownloadDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final audioStoreProvider = Provider<AudioStore>(
  (ref) => FileAudioStore(
    location: ref.watch(libraryLocationProvider),
    downloadDio: ref.watch(audioDownloadDioProvider),
  ),
);

/// All works, newest first. Loading it also resumes any job that was still
/// running when the app was last closed.
final libraryProvider = AsyncNotifierProvider<LibraryController, List<Work>>(
  LibraryController.new,
);

/// Ready + pending works grouped by occasion (PRD F10 "按场合分组"), groups in
/// occasion order, works newest first.
final libraryByOccasionProvider = Provider<Map<Occasion, List<Work>>>((ref) {
  final works = ref.watch(libraryProvider).value ?? const <Work>[];
  final grouped = <Occasion, List<Work>>{};
  for (final occasion in Occasion.values) {
    final items = works
        .where((w) => w.occasion == occasion && w.status != WorkStatus.failed)
        .toList(growable: false);
    if (items.isNotEmpty) grouped[occasion] = items;
  }
  return grouped;
});

/// Marks the library stale and rebuilds it at once, in the caller's async
/// code: left stale, the first widget to watch it would rebuild it during its
/// build, and the refresh of the library's other listeners would land
/// mid-frame (a work's page opened earlier keeps such listeners). For writers
/// outside the library — not its iCloud sync, which the library's own build
/// starts and so leaves the rebuild to the next reader.
void refreshLibrary(Ref ref) {
  ref.invalidate(libraryProvider);
  ref.read(libraryProvider);
}

final workByIdProvider = Provider.family<Work?, String>((ref, id) {
  final works = ref.watch(libraryProvider).value ?? const <Work>[];
  for (final work in works) {
    if (work.id == id) return work;
  }
  return null;
});

class LibraryController extends AsyncNotifier<List<Work>> {
  @override
  Future<List<Work>> build() async {
    final works = await ref.watch(workRepositoryProvider).all();
    _resumePending(works);
    // New finished works go to iCloud when sync is on (ADR-0013).
    if (works.any((w) => w.isReady)) unawaited(ref.read(librarySyncProvider.notifier).syncNow());
    return works;
  }

  /// Deletes [work] with its audio and its music videos (a video without its
  /// song has nothing to belong to in the library).
  Future<void> delete(Work work) async {
    await ref.read(musicVideosProvider.notifier).deleteOfWork(work.id);
    await ref.read(workRepositoryProvider).delete(work.id);
    final file = work.audioFile;
    if (file != null) await ref.read(audioStoreProvider).delete(file);
    await ref.read(librarySyncProvider.notifier).onDeleted(work);
    ref.invalidateSelf();
  }

  void _resumePending(List<Work> works) {
    final runner = ref.read(jobRunnerProvider);
    for (final work in works) {
      if (work.status != WorkStatus.pending || work.jobId == null) continue;
      if (runner.isRunning(work.id)) continue;
      unawaited(
        runner.run(work).then(
              (_) {
                ref
                  ..invalidateSelf()
                  // A failed job was refunded (PRD §8.4).
                  ..invalidate(walletSnapshotProvider);
              },
              onError: (Object _, StackTrace _) {}, // stays pending; retried next load
            ),
      );
    }
  }
}

/// Absolute path of [workId]'s audio, read from the stored record (the library
/// list may still hold the pending version of a work that just finished);
/// null while the work has no audio on this device.
final workAudioPathProvider = FutureProvider.family<String?, String>((ref, workId) async {
  ref.watch(libraryProvider);
  final work = await ref.watch(workRepositoryProvider).byId(workId);
  final file = work?.audioFile;
  if (work == null || file == null) return null;
  return ref.watch(audioStoreProvider).pathOf(file);
});

final cloudSyncGatewayProvider = Provider<CloudSyncGateway>((ref) => const ChannelCloudSync());

/// Opt-in iCloud library sync (ADR-0013).
final librarySyncProvider =
    NotifierProvider<MusicLibrarySyncController, LibrarySyncState>(MusicLibrarySyncController.new);
