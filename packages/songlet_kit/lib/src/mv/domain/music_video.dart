import 'package:meta/meta.dart';

import '../../library/domain/music_work.dart';
import 'music_mv.dart';

/// A music video made from a work, stored locally next to it (PRD ch.15).
/// The backend keeps no record of its own: [mvId] is the platform task id and
/// the platform is the source of truth while the video is being made; once
/// downloaded the file lives in the library like the audio does.
@immutable
class MusicVideo {
  const MusicVideo({
    required this.id,
    required this.workId,
    required this.mvId,
    required this.level,
    required this.status,
    required this.createdAt,
    this.videoFile,
    this.errorCode,
    this.durationMs = 0,
    this.creditsCharged = 0,
    this.aspectRatio = MusicMvAspectRatio.portrait,
    this.quality = MusicMvQuality.standard,
    this.chorus,
    this.source = MusicMvSource.library,
    this.photoCount = 0,
  });

  /// Local id — also the `client_ref` of the create call.
  final String id;

  /// The work (song) the video was made from.
  final String workId;

  /// Platform MV task id (`mv_id`).
  final String mvId;
  final MusicMvLevel level;
  final MusicWorkStatus status;
  final DateTime createdAt;

  /// File name inside the library's video directory.
  final String? videoFile;
  final String? errorCode;
  final int durationMs;
  final int creditsCharged;

  /// What was asked for (the platform defaults when the request left it
  /// out), kept so the player lays the video out and "Regenerate" (docs/ui
  /// P27) can repeat it.
  final MusicMvAspectRatio aspectRatio;
  final MusicMvQuality quality;

  /// The chorus window a chorus video covers; null = located by the platform.
  final MusicMvChorusWindow? chorus;
  final MusicMvSource source;

  /// Reference photos sent (their bids expire after 24 h, so only the count
  /// is kept).
  final int photoCount;

  bool get isPending => status == MusicWorkStatus.pending;

  bool get isReady => status == MusicWorkStatus.ready && videoFile != null;

  MusicVideo copyWith({
    MusicWorkStatus? status,
    String? videoFile,
    String? errorCode,
    int? durationMs,
  }) =>
      MusicVideo(
        id: id,
        workId: workId,
        mvId: mvId,
        level: level,
        status: status ?? this.status,
        createdAt: createdAt,
        videoFile: videoFile ?? this.videoFile,
        errorCode: errorCode ?? this.errorCode,
        durationMs: durationMs ?? this.durationMs,
        creditsCharged: creditsCharged,
        aspectRatio: aspectRatio,
        quality: quality,
        chorus: chorus,
        source: source,
        photoCount: photoCount,
      );
}

/// Local persistence of music videos (same SQLite database as the works).
abstract interface class MusicVideoRepository {
  Future<List<MusicVideo>> all();

  Future<List<MusicVideo>> byWork(String workId);

  Future<MusicVideo?> byId(String id);

  Future<void> upsert(MusicVideo video);

  Future<void> delete(String id);
}

/// Video files in the library's container.
abstract interface class MusicVideoStore {
  /// Downloads [url] and returns the stored file name.
  Future<String> download({required String url, required String videoId});

  Future<String> pathOf(String fileName);

  Future<void> delete(String fileName);
}
