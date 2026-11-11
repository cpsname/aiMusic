import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../library/domain/work.dart';
import '../../library/domain/work_repository.dart';
import '../../platform/domain/native_gateways.dart';

/// A rendered card frame (PNG, 1080×1920) and the second it appears at.
class CardFrame {
  const CardFrame({required this.png, required this.start});

  final Uint8List png;
  final double start;
}

/// Builds the 9:16 share video (PRD F08) from frames rendered by the UI — the
/// cover, lyric lines and the non-removable "AI generated" badge (PRD D8) are
/// burned into every frame — and the work's audio.
class ShareCardService {
  ShareCardService({required AudioStore audio, required VideoComposer composer})
      : _audio = audio,
        _composer = composer;

  final AudioStore _audio;
  final VideoComposer _composer;

  /// Returns the path of the composed MP4.
  Future<String> compose(
    Work work, {
    required List<CardFrame> frames,
    required double duration,
  }) async {
    final audioFile = work.audioFile;
    if (audioFile == null || frames.isEmpty) {
      throw StateError('work ${work.id} has no audio or no frames');
    }
    final dir = Directory(p.join(await _audio.scratchDirectory(), 'card-${work.id}'));
    if (dir.existsSync()) await dir.delete(recursive: true);
    await dir.create(recursive: true);

    final videoFrames = <VideoFrame>[];
    for (var i = 0; i < frames.length; i++) {
      final path = p.join(dir.path, 'frame_$i.png');
      await File(path).writeAsBytes(frames[i].png, flush: true);
      videoFrames.add(VideoFrame(path: path, start: frames[i].start));
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
