import 'dart:typed_data';

/// Device capabilities behind the PRD §6.4 bridge, as the domain sees them.
/// One implementation (`MusicNativeBridge`, data layer) adapts the Pigeon API; tests
/// substitute fakes.

/// PhotosPicker (PRD F04): up to [max] images, already downscaled to a 1024 px
/// long side and JPEG q 0.8 natively. Empty when the user cancels.
abstract interface class MusicPhotoSource {
  Future<List<Uint8List>> pickPhotos(int max);
}

/// On-device prompt polishing (SystemLanguageModel). Returns [raw] unchanged
/// when the model is unavailable.
abstract interface class MusicPromptPolisher {
  Future<String> polish(String raw, String locale);
}

/// "Save to Files". Returns false when the user dismissed the picker.
abstract interface class MusicFileExporter {
  Future<bool> exportToFiles(String path, String name);
}

/// App Attest (DCAppAttestService): the decoded JSON of `appAttestAssertion`
/// (`key_id` + `attestation` | `assertion`, or `unsupported: true`).
abstract interface class MusicAttestationProvider {
  Future<Map<String, Object?>> assertion(String challenge);
}

/// AVAudioPlayer with background audio + lock-screen controls (PRD F07).
abstract interface class MusicAudioEngine {
  /// See `pigeons/songlet_api.dart`: new path → play from 0; same path + same
  /// loop → toggle; same path + other loop → set looping; '' → stop.
  Future<void> play(String path, {required bool loop});

  /// Jumps the loaded track to [seconds] (scrubbing, section jumps). Runs on
  /// the `songlet/playback` channel — the fixed PRD §6.4 bridge has no seek
  /// (ADR-0017).
  Future<void> seek(double seconds);

  /// Position in seconds while playing; [MusicAudioEngine.paused] / [MusicAudioEngine.ended].
  Stream<double> get progress;

  static const double paused = -1;
  static const double ended = -2;
}

/// A card frame of the share video: a rendered PNG shown from [start] seconds.
class MusicVideoFrame {
  const MusicVideoFrame({required this.path, required this.start});

  final String path;
  final double start;
}

/// H.264/AAC 9:16 share-card video (PRD F08).
abstract interface class MusicVideoComposer {
  Future<void> compose({
    required List<MusicVideoFrame> frames,
    required String audioPath,
    required String outputPath,
    required double duration,
    int width,
    int height,
  });
}

/// Adds a finished share video to the photo library ("Save video", docs/ui
/// P10) with add-only permission. False when the user refused access.
abstract interface class MusicVideoSaver {
  Future<bool> saveVideo(String path);
}
