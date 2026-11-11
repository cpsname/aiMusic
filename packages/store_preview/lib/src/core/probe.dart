import 'dart:convert';
import 'dart:io';

import 'errors.dart';

class VideoStream {
  const VideoStream({
    required this.codec,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.bitRate,
    required this.pixFmt,
    this.profile = '',
    this.level = 0,
    this.realFrameRate = 0,
    this.rotation = 0,
  });

  final String codec;
  final int width;
  final int height;

  /// Average frames per second (`avg_frame_rate`).
  final double frameRate;

  /// Bits per second, 0 when unknown.
  final int bitRate;
  final String pixFmt;

  /// H.264 profile (`High`) and level × 10 (`40` = 4.0).
  final String profile;
  final int level;

  /// The stream's base frame rate (`r_frame_rate`): constant-rate footage
  /// has it equal to [frameRate].
  final double realFrameRate;

  /// Display rotation in degrees from the stream's display matrix (or its
  /// `rotate` tag); 0 when it has none.
  final int rotation;

  /// The pixel format carries an alpha channel (`rgba`, `ya8`, …) or may (a
  /// palette, whose entries can be transparent).
  bool get mayHaveAlpha => alphaPixelFormats.contains(pixFmt) || pixFmt.startsWith('pal');
}

/// Pixel formats with an alpha channel.
const Set<String> alphaPixelFormats = {
  'rgba', 'bgra', 'argb', 'abgr', 'ya8', 'ya16be', 'ya16le', 'rgba64be', 'rgba64le', 'bgra64be', 'bgra64le', //
  'yuva420p', 'yuva422p', 'yuva444p', 'gbrap', 'gbrap10le', 'gbrap12le', 'gbrap16le', 'gbrapf32le',
};

class AudioStream {
  const AudioStream({
    required this.codec,
    required this.channels,
    required this.sampleRate,
    required this.bitRate,
  });

  final String codec;
  final int channels;
  final int sampleRate;
  final int bitRate;
}

class MediaInfo {
  const MediaInfo({
    required this.duration,
    required this.size,
    required this.formatName,
    this.video,
    this.audio,
    this.majorBrand = '',
    this.videoStreams = 0,
    this.audioStreams = 0,
  });

  final double duration;
  final int size;
  final String formatName;
  final VideoStream? video;
  final AudioStream? audio;

  /// The ISO base media file's major brand (`isom`, `qt`, `M4V`); empty for
  /// other files.
  final String majorBrand;
  final int videoStreams;
  final int audioStreams;

  /// The container as App Store tooling names it: `mp4` or `quicktime` for an
  /// ISO base media file (by its major brand), else ffprobe's format name.
  String get container {
    if (formatName.contains('mov') || formatName.contains('mp4')) {
      return majorBrand.toLowerCase().startsWith('qt') ? 'quicktime' : 'mp4';
    }
    return formatName;
  }
}

/// Reads a media file's streams.
abstract interface class Prober {
  MediaInfo? probe(String path);
}

/// ffprobe (Homebrew ffmpeg).
class FfprobeProber implements Prober {
  const FfprobeProber();

  @override
  MediaInfo? probe(String path) {
    final ProcessResult result;
    try {
      result = Process.runSync('ffprobe', [
        '-v', 'error', '-print_format', 'json', '-show_format', '-show_streams', path, //
      ]);
    } on ProcessException {
      throw ToolError('ffprobe not found — brew install ffmpeg');
    }
    if (result.exitCode != 0) return null;
    return parseFfprobe(jsonDecode(result.stdout as String) as Map<String, Object?>);
  }
}

double _rate(Object? v) {
  final parts = '$v'.split('/');
  if (parts.length != 2) return double.tryParse('$v') ?? 0;
  final d = double.tryParse(parts[1]) ?? 0;
  return d == 0 ? 0 : (double.tryParse(parts[0]) ?? 0) / d;
}

int _int(Object? v) => int.tryParse('$v') ?? 0;

int _rotation(Map<String, Object?> stream) {
  for (final raw in (stream['side_data_list'] as List? ?? const [])) {
    final rotation = (raw as Map)['rotation'];
    if (rotation is num) return rotation.round();
  }
  final tag = ((stream['tags'] as Map?)?['rotate']);
  return tag == null ? 0 : _int(tag);
}

MediaInfo parseFfprobe(Map<String, Object?> json) {
  final format = (json['format'] as Map?)?.cast<String, Object?>() ?? const {};
  VideoStream? video;
  AudioStream? audio;
  var videoStreams = 0;
  var audioStreams = 0;
  for (final raw in (json['streams'] as List? ?? const [])) {
    final s = (raw as Map).cast<String, Object?>();
    final disposition = (s['disposition'] as Map?)?.cast<String, Object?>() ?? const {};
    if (s['codec_type'] == 'video' && disposition['attached_pic'] != 1) videoStreams++;
    if (s['codec_type'] == 'audio') audioStreams++;
    if (s['codec_type'] == 'video' && disposition['attached_pic'] != 1 && video == null) {
      video = VideoStream(
        codec: '${s['codec_name']}',
        width: _int(s['width']),
        height: _int(s['height']),
        frameRate: _rate(s['avg_frame_rate']),
        bitRate: _int(s['bit_rate']),
        pixFmt: '${s['pix_fmt']}',
        profile: '${s['profile'] ?? ''}',
        level: _int(s['level']),
        realFrameRate: _rate(s['r_frame_rate']),
        rotation: _rotation(s),
      );
    } else if (s['codec_type'] == 'audio' && audio == null) {
      audio = AudioStream(
        codec: '${s['codec_name']}',
        channels: _int(s['channels']),
        sampleRate: _int(s['sample_rate']),
        bitRate: _int(s['bit_rate']),
      );
    }
  }
  return MediaInfo(
    duration: double.tryParse('${format['duration']}') ?? 0,
    size: _int(format['size']),
    formatName: '${format['format_name']}',
    video: video,
    audio: audio,
    majorBrand: '${(format['tags'] as Map?)?['major_brand'] ?? ''}'.trim(),
    videoStreams: videoStreams,
    audioStreams: audioStreams,
  );
}
