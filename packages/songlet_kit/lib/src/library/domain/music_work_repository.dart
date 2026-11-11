import 'music_work.dart';

/// The local work library (PRD F10), newest first.
abstract interface class MusicWorkRepository {
  Future<List<MusicWork>> all();

  Future<MusicWork?> byId(String id);

  Future<void> upsert(MusicWork work);

  Future<void> delete(String id);
}

/// Where downloaded audio lives (App Group container when available).
abstract interface class MusicAudioStore {
  /// Downloads [url] (the 24 h object-storage link, PRD §6.3 — fetched
  /// immediately) for [workId], stamps the ID3 tags, returns the file name.
  Future<String> download({
    required String url,
    required String workId,
    required String title,
  });

  /// Absolute path of a stored [fileName].
  Future<String> pathOf(String fileName);

  /// A scratch directory for exports / share cards (cleared by the OS).
  Future<String> scratchDirectory();

  /// Copies an audio file from elsewhere on the device (an iCloud asset,
  /// ADR-0013) into the library; returns the stored file name.
  Future<String> importFile({required String sourcePath, required String workId});

  /// Downloads [url] as-is (no tagging) into the scratch directory as
  /// [fileName]; returns its path. Used for WAV exports (ADR-0010).
  Future<String> fetchToScratch({required String url, required String fileName});

  Future<void> delete(String fileName);
}
