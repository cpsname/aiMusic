import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../creation/application/creation_providers.dart';
import '../../creation/application/music_generation_state.dart';
import '../../creation/domain/song_options.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/work.dart';
import '../domain/mv.dart';
import 'mv_providers.dart';

/// The automatic video of one song (docs/ui P23, ADR-0022).
@immutable
class AutoVideoTask {
  const AutoVideoTask({
    required this.workId,
    required this.level,
    this.secondsLeft,
    this.videoId,
    this.failure,
  });

  final String workId;
  final MvLevel level;

  /// Counting down before the chorus video is submitted (nothing charged
  /// yet); null once submitted or for the lyric video.
  final int? secondsLeft;

  /// The submitted video (follow it with `mvProgressProvider`).
  final String? videoId;

  /// Submitting failed; the song page's video entry still works.
  final Failure? failure;

  bool get isCountingDown => secondsLeft != null && videoId == null && failure == null;

  AutoVideoTask copyWith({int? secondsLeft, String? videoId, Failure? failure}) => AutoVideoTask(
        workId: workId,
        level: level,
        secondsLeft: videoId != null || failure != null ? null : (secondsLeft ?? this.secondsLeft),
        videoId: videoId ?? this.videoId,
        failure: failure ?? this.failure,
      );
}

/// Path 2 of the music video (ADR-0022): the video the length panel asked
/// for, made once the song is ready, without the hub.
///
/// * `AutoVideo.lyric` — the lyric video, then a 10 s local countdown the user
///   can cancel (it costs credits since contract 02 v2.1: nothing is free).
/// * `AutoVideo.chorus` (Premier "song + chorus video") — the same countdown,
///   then the chorus video. Nothing is charged before the countdown ends.
///
/// The intent lives on the work (`Work.autoVideo`). A video is never started
/// after a restart — it costs credits and the user would not see the
/// countdown — the intent is dropped and the song page's entry remains. The
/// `client_ref` is derived from the work and level, so starting twice is
/// answered by the platform's idempotency, never charged twice.
class AutoVideoCoordinator extends Notifier<Map<String, AutoVideoTask>> {
  static const int countdownSeconds = 10;

  /// Namespace of the derived `client_ref`s (UUID v5).
  static const String _refNamespace = '6f1c2a57-6c1e-4a53-9a0e-8f0a3c4b7d21';

  final Map<String, Timer> _timers = {};
  final Set<String> _handled = {};

  @override
  Map<String, AutoVideoTask> build() {
    ref
      ..onDispose(() {
        for (final timer in _timers.values) {
          timer.cancel();
        }
        _timers.clear();
      })
      // Listeners can fire while a widget builds: the work (which changes
      // this notifier's state) starts on the next microtask.
      ..listen<MusicGenerationState>(generationControllerProvider, (_, next) {
        if (next is GenerationSucceeded && next.work.autoVideo.isOn) {
          scheduleMicrotask(() => unawaited(_songReady(next.work, live: true)));
        }
      })
      ..listen<AsyncValue<List<Work>>>(libraryProvider, (_, next) {
        for (final work in next.value ?? const <Work>[]) {
          if (work.isReady && work.autoVideo.isOn) scheduleMicrotask(() => unawaited(_songReady(work, live: false)));
        }
      }, fireImmediately: true);
    return const {};
  }

  /// The derived `client_ref` of [workId]'s automatic [level] video.
  static String clientRefFor(String workId, MvLevel level) =>
      const Uuid().v5(_refNamespace, 'auto:$workId:${level.wire}');

  /// Stops a countdown; the song keeps no automatic video.
  Future<void> cancelCountdown(String workId) async {
    final task = state[workId];
    if (task == null || !task.isCountingDown) return;
    _timers.remove(workId)?.cancel();
    _put(workId, null);
    await _clearIntent(workId);
  }

  /// The banner was closed.
  void dismiss(String workId) {
    if (state[workId]?.isCountingDown ?? false) return;
    _put(workId, null);
  }

  Future<void> _songReady(Work work, {required bool live}) async {
    if (!_handled.add(work.id)) return;
    final (level, source) = switch (work.autoVideo) {
      AutoVideo.none => (null, null),
      AutoVideo.lyric => (MvLevel.lyricVideo, MvSource.autoLyric),
      AutoVideo.chorus => (MvLevel.chorus, MvSource.library),
    };
    if (level == null || source == null) return;
    if (!live) {
      await _clearIntent(work.id);
      return;
    }
    _put(work.id, AutoVideoTask(workId: work.id, level: level, secondsLeft: countdownSeconds));
    _timers[work.id] = Timer.periodic(ref.read(autoVideoTickProvider), (timer) {
      final task = state[work.id];
      if (task == null || !task.isCountingDown) {
        timer.cancel();
        return;
      }
      final left = task.secondsLeft! - 1;
      if (left > 0) {
        _put(work.id, task.copyWith(secondsLeft: left));
        return;
      }
      timer.cancel();
      _timers.remove(work.id);
      unawaited(_submit(work.id, level, source));
    });
  }

  Future<void> _submit(String workId, MvLevel level, MvSource source) async {
    final current = state[workId];
    _put(workId, AutoVideoTask(workId: workId, level: level, secondsLeft: current?.secondsLeft));
    // The latest record: the work may have changed since it finished.
    final work = await ref.read(workRepositoryProvider).byId(workId);
    if (work == null || !work.isReady || work.jobId == null) {
      _put(workId, null);
      return;
    }
    final request = MvRequest(level: level, clientRef: clientRefFor(workId, level), source: source);
    try {
      await ref.read(authControllerProvider.notifier).ensureAuthenticated();
      final (video, ticket) = await ref.read(mvLauncherProvider).submit(work, request);
      await _clearIntent(workId);
      _put(workId, (state[workId] ?? AutoVideoTask(workId: workId, level: level)).copyWith(videoId: video.id));
      ref
        ..invalidate(musicVideosProvider)
        ..invalidate(walletSnapshotProvider);
      final runner = ref.read(mvRunnerProvider);
      if (runner.isRunning(video.id)) return;
      unawaited(
        runner.run(video, etaSeconds: ticket.etaSeconds).then(
              (_) => ref
                ..invalidate(musicVideosProvider)
                ..invalidate(walletSnapshotProvider),
              onError: (Object _, StackTrace _) {}, // stays pending; the library resumes it
            ),
      );
    } on Object catch (error, stackTrace) {
      final failure = ref.read(errorHandlerProvider).handle(error, stackTrace);
      // The intent ends either way: a video that costs credits is never started
      // on a later launch.
      await _clearIntent(workId);
      _put(workId, (state[workId] ?? AutoVideoTask(workId: workId, level: level)).copyWith(failure: failure));
    }
  }

  Future<void> _clearIntent(String workId) async {
    final repository = ref.read(workRepositoryProvider);
    final work = await repository.byId(workId);
    if (work == null || !work.autoVideo.isOn) return;
    await repository.upsert(work.copyWith(autoVideo: AutoVideo.none));
  }

  void _put(String workId, AutoVideoTask? task) {
    final next = {...state};
    task == null ? next.remove(workId) : next[workId] = task;
    state = next;
  }
}

/// One step of the countdown (tests shorten it).
final autoVideoTickProvider = Provider<Duration>((ref) => const Duration(seconds: 1));

/// A running coordinator: read once at startup (ADR-0022).
final autoVideoCoordinatorProvider =
    NotifierProvider<AutoVideoCoordinator, Map<String, AutoVideoTask>>(AutoVideoCoordinator.new);

/// The automatic video of [workId], if any (docs/ui P23 banner).
final autoVideoOfWorkProvider = Provider.family<AutoVideoTask?, String>(
  (ref, workId) => ref.watch(autoVideoCoordinatorProvider)[workId],
);
