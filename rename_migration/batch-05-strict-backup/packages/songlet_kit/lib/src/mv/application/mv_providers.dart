import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

import '../../library/application/library_providers.dart';
import '../../library/data/sqlite_work_repository.dart';
import '../../library/domain/work.dart';
import '../../platform/application/platform_providers.dart';
import '../data/file_video_store.dart';
import '../data/kv_mv_intent_store.dart';
import '../data/mv_repository_impl.dart';
import '../data/sqlite_music_video_repository.dart';
import '../domain/music_video.dart';
import '../domain/mv.dart';
import '../domain/mv_intent.dart';
import '../domain/mv_repository.dart';
import 'mv_controller.dart';
import 'mv_launcher.dart';
import 'mv_notifications.dart';
import 'mv_runner.dart';
import 'mv_state.dart';

/// Composition root of the music-video context (PRD ch.15).

final mvRepositoryProvider = Provider<MvRepository>(
  (ref) => MvRepositoryImpl(ref.watch(apiDioProvider)),
);

/// Music videos share the works database (schema v3).
final musicVideoRepositoryProvider = Provider<MusicVideoRepository>((ref) {
  final location = ref.watch(libraryLocationProvider);
  return SqliteMusicVideoRepository(
    () async => openWorkDatabase(await location.databasePath()),
  );
});

final videoStoreProvider = Provider<VideoStore>(
  (ref) => FileVideoStore(
    location: ref.watch(libraryLocationProvider),
    downloadDio: ref.watch(audioDownloadDioProvider),
  ),
);

/// ETA notifications of music videos (ADR-0025); the app binds the copy.
final mvNotificationsProvider = Provider<MvNotifications>(
  (ref) => MvNotifications(ref.watch(localNotificationsProvider)),
);

final mvRunnerProvider = Provider<MvRunner>((ref) {
  final notifications = ref.watch(mvNotificationsProvider);
  final runner = MvRunner(
    mvs: ref.watch(mvRepositoryProvider),
    videos: ref.watch(videoStoreProvider),
    library: ref.watch(musicVideoRepositoryProvider),
    onSettled: (videoId) => unawaited(notifications.cancelFor(videoId)),
  );
  ref.onDispose(runner.dispose);
  return runner;
});

/// The video refused for credits, kept across the purchase (ADR-0023).
final mvIntentStoreProvider = Provider<MvIntentStore>(
  (ref) => KvMvIntentStore(ref.watch(keyValueStoreProvider)),
);

final mvLauncherProvider = Provider<MvLauncher>(
  (ref) => MvLauncher(
    mvs: ref.watch(mvRepositoryProvider),
    library: ref.watch(musicVideoRepositoryProvider),
    intents: ref.watch(mvIntentStoreProvider),
    notifications: ref.watch(mvNotificationsProvider),
  ),
);

/// Attempts of `MvController.retryIntent` after a purchase (tests shorten
/// them).
final mvRetryDelaysProvider = Provider<List<Duration>>((ref) => MvController.purchaseRetryDelays);

/// Live progress of one video (docs/ui P24/P25): the runner's latest
/// snapshot, then every new one — whichever path runs it (the live flow or
/// the resume after a restart). Emits nothing while no run polls it; the
/// page then reads the stored video ([musicVideoByIdProvider]).
final mvProgressProvider = StreamProvider.family<MvSnapshot, String>((ref, videoId) async* {
  final runner = ref.watch(mvRunnerProvider);
  final latest = runner.latest(videoId);
  if (latest != null) yield latest;
  yield* runner.snapshots(videoId);
});

final mvControllerProvider = NotifierProvider<MvController, MvState>(MvController.new);

/// All music videos, newest first. Loading it also resumes any video that was
/// still being made when the app was last closed.
final musicVideosProvider = AsyncNotifierProvider<MusicVideosController, List<MusicVideo>>(
  MusicVideosController.new,
);

/// The videos of one work, newest first.
final musicVideosOfWorkProvider = Provider.family<List<MusicVideo>, String>((ref, workId) {
  final videos = ref.watch(musicVideosProvider).value ?? const <MusicVideo>[];
  return videos.where((v) => v.workId == workId).toList(growable: false);
});

/// A work's video state for badges and entry cards (docs/ui P13 / P19):
/// making while any is pending, else ready when any is on this device.
enum WorkVideoStatus { none, making, ready }

final mvStatusOfWorkProvider = Provider.family<WorkVideoStatus, String>((ref, workId) {
  final videos = ref.watch(musicVideosOfWorkProvider(workId));
  if (videos.any((v) => v.isPending)) return WorkVideoStatus.making;
  if (videos.any((v) => v.isReady)) return WorkVideoStatus.ready;
  return WorkVideoStatus.none;
});

final musicVideoByIdProvider = Provider.family<MusicVideo?, String>((ref, id) {
  final videos = ref.watch(musicVideosProvider).value ?? const <MusicVideo>[];
  for (final video in videos) {
    if (video.id == id) return video;
  }
  return null;
});

/// Absolute path of [videoId]'s MP4 on this device, read from the stored
/// record; null while there is none.
final musicVideoPathProvider = FutureProvider.family<String?, String>((ref, videoId) async {
  ref.watch(musicVideosProvider);
  final video = await ref.watch(musicVideoRepositoryProvider).byId(videoId);
  final file = video?.videoFile;
  if (video == null || file == null) return null;
  return ref.watch(videoStoreProvider).pathOf(file);
});

class MusicVideosController extends AsyncNotifier<List<MusicVideo>> {
  @override
  Future<List<MusicVideo>> build() async {
    final videos = await ref.watch(musicVideoRepositoryProvider).all();
    _resumePending(videos);
    return videos;
  }

  Future<void> delete(MusicVideo video) async {
    await _remove(video);
    ref.invalidateSelf();
  }

  /// Every video of [workId] — its song is being deleted. A video still being
  /// made is abandoned locally (its run never writes it back).
  Future<void> deleteOfWork(String workId) async {
    final videos = await ref.read(musicVideoRepositoryProvider).byWork(workId);
    for (final video in videos) {
      ref.read(mvRunnerProvider).abandon(video.id);
      await _remove(video);
    }
    if (videos.isNotEmpty) ref.invalidateSelf();
  }

  Future<void> _remove(MusicVideo video) async {
    await ref.read(musicVideoRepositoryProvider).delete(video.id);
    final file = video.videoFile;
    if (file != null) await ref.read(videoStoreProvider).delete(file);
  }

  /// Videos left `pending` are polled again with the largest budget: their
  /// ETA is unknown after a restart.
  void _resumePending(List<MusicVideo> videos) {
    final runner = ref.read(mvRunnerProvider);
    for (final video in videos) {
      if (video.status != WorkStatus.pending || runner.isRunning(video.id)) continue;
      unawaited(
        runner.run(video, etaSeconds: MvRunner.maxTimeout.inSeconds ~/ MvRunner.etaMultiplier).then(
              (_) {
                ref
                  ..invalidateSelf()
                  ..invalidate(walletSnapshotProvider);
              },
              onError: (Object _, StackTrace _) {}, // stays pending; retried next load
            ),
      );
    }
  }
}
