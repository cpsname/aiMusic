import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../library/domain/music_work.dart';
import '../../library/domain/music_work_repository.dart';
import '../../platform/domain/music_native_gateways.dart';

/// A rendered card frame (PNG, 1080×1920) and the second it appears at.
class MusicCardFrame {
  const MusicCardFrame({required this.png, required this.start});

  final Uint8List png;
  final double start;
}

/// Builds the 9:16 share video (PRD F08) from frames rendered by the UI — the
/// cover, lyric lines and the non-removable "AI generated" badge (PRD D8) are
/// burned into every frame — and the work's audio.
class MusicShareCardService {
  MusicShareCardService({required MusicAudioStore audio, required MusicVideoComposer composer})
      : _audio = audio,
        _composer = composer;

  final MusicAudioStore _audio;
  final MusicVideoComposer _composer;

  /// Returns the path of the composed MP4.
  Future<String> compose(
    MusicWork work, {
    required List<MusicCardFrame> frames,
    required double duration,
  }) async {
    final audioFile = work.audioFile;
    if (audioFile == null || frames.isEmpty) {
      throw StateError('work ${work.id} has no audio or no frames');
    }
    final dir = Directory(p.join(await _audio.scratchDirectory(), 'card-${work.id}'));
    if (dir.existsSync()) await dir.delete(recursive: true);
    await dir.create(recursive: true);

    final videoFrames = <MusicVideoFrame>[];
    for (var i = 0; i < frames.length; i++) {
      final path = p.join(dir.path, 'frame_$i.png');
      await File(path).writeAsBytes(frames[i].png, flush: true);
      videoFrames.add(MusicVideoFrame(path: path, start: frames[i].start));
    }
    final output = p.join(dir.path, 'songlet-${work.id.substring(0, 8)}.mp4');
    await _composer.compose(
      frames: videoFrames,
      audioPath: await _audio.pathOf(audioFile),
      outputPath: output,
      duration: duration,
    );
    return output;
  }
}
