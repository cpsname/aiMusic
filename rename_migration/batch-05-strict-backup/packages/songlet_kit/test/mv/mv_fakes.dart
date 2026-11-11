import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:songlet_kit/songlet_kit.dart';

/// Answers `mv()` from a script: each entry is an [MvSnapshot] to return or an
/// object to throw; the last entry repeats forever.
class ScriptedMvRepository implements MvRepository {
  ScriptedMvRepository({this.script = const [], this.estimateResult, this.createResult, this.cancelResult});

  final List<Object> script;
  final List<String> polled = [];
  final List<(String, MvRequest)> created = [];
  final List<(String, MvLevel)> estimated = [];
  final List<String> cancelled = [];
  Completer<void>? gate;

  MvEstimate? estimateResult;

  /// Per-level answers of `estimate` (an [MvEstimate] or an error to throw);
  /// falls back to [estimateResult].
  Map<MvLevel, Object> estimateByLevel = {};
  Object? createResult;

  /// Answers of successive `create` calls, consumed first; then [createResult].
  List<Object> createQueue = [];
  Object? cancelResult;

  @override
  Future<MvEstimate> estimate(String jobId, MvLevel level) async {
    estimated.add((jobId, level));
    final byLevel = estimateByLevel[level];
    if (byLevel is MvEstimate) return byLevel;
    if (byLevel != null) throw byLevel;
    final result = estimateResult;
    if (result == null) throw StateError('no estimate scripted');
    return result;
  }

  @override
  Future<MvTicket> create(String jobId, MvRequest request) async {
    created.add((jobId, request));
    final result = createQueue.isNotEmpty ? createQueue.removeAt(0) : createResult;
    if (result is MvTicket) return result;
    throw result ?? StateError('no create scripted');
  }

  @override
  Future<MvSnapshot> mv(String mvId) async {
    final pending = gate;
    if (pending != null) await pending.future;
    final step = script[polled.length < script.length ? polled.length : script.length - 1];
    polled.add(mvId);
    if (step is MvSnapshot) return step;
    throw step;
  }

  @override
  Future<MvCancelOutcome> cancel(String mvId) async {
    cancelled.add(mvId);
    final result = cancelResult;
    if (result is MvCancelOutcome) return result;
    throw result ?? StateError('no cancel scripted');
  }
}

class FakeMusicVideoRepository implements MusicVideoRepository {
  final Map<String, MusicVideo> videos = {};
  final List<MusicVideo> upserts = [];
  final List<String> deleted = [];

  @override
  Future<List<MusicVideo>> all() async => videos.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<MusicVideo>> byWork(String workId) async => (await all()).where((v) => v.workId == workId).toList();

  @override
  Future<MusicVideo?> byId(String id) async => videos[id];

  @override
  Future<void> upsert(MusicVideo video) async {
    upserts.add(video);
    videos[video.id] = video;
  }

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    videos.remove(id);
  }
}

class FakeVideoStore implements VideoStore {
  final List<(String, String)> downloads = [];
  Object? error;

  @override
  Future<String> download({required String url, required String videoId}) async {
    downloads.add((url, videoId));
    final failure = error;
    if (failure != null) throw failure;
    return '$videoId.mp4';
  }

  @override
  Future<String> pathOf(String fileName) async => '/video/$fileName';

  @override
  Future<void> delete(String fileName) async {}
}

class MemoryMvIntentStore implements MvIntentStore {
  MvIntent? intent;
  int clears = 0;

  @override
  MvIntent? read() => intent;

  @override
  Future<void> save(MvIntent intent) async => this.intent = intent;

  @override
  Future<void> clear() async {
    clears++;
    intent = null;
  }
}

/// An [AuthController] that is always authenticated (no network).
class SignedInAuth extends AuthController {
  @override
  AuthPhase build() => const AuthIdle();

  @override
  Future<void> ensureAuthenticated() async {}
}

class FakePhotoUploader implements PhotoUploader {
  final List<String> uploaded = [];

  @override
  Future<String> upload(List<int> jpeg, {required String filename}) async {
    uploaded.add(filename);
    return 'bid-${uploaded.length}';
  }
}

MusicVideo pendingVideo({String id = 'v1', String workId = 'w1', String mvId = 'mv-1', MvLevel level = MvLevel.chorus}) =>
    MusicVideo(
      id: id,
      workId: workId,
      mvId: mvId,
      level: level,
      status: WorkStatus.pending,
      createdAt: DateTime.utc(2026, 9, 28, 10),
      creditsCharged: 2169,
    );

Work readySong({String id = 'w1', String? jobId = 'job-1'}) => Work(
      id: id,
      jobId: jobId,
      model: SongModel.fullSong,
      status: WorkStatus.ready,
      occasion: Occasion.birthday,
      region: 'US',
      genre: 'Pop',
      lyricLanguage: 'en',
      recipient: 'Alex',
      audioFile: '$id.mp3',
      createdAt: DateTime.utc(2026, 9, 28, 9),
    );
