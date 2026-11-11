import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'core.dart';

/// The `demo` profile: the App Store preview recordings
/// (store_preview/songlet, packages/store_preview).
///
/// It serves the storefront's own Lyria songs and platform lyric videos from
/// the preview manifest instead of the synthetic fixtures — a recording may
/// only show and play what the product really makes. The recording selects
/// what the next job is (`POST /__admin/demo {script, locale}`); a song job
/// then:
///
/// * runs straight to `running` (no queue banner) and succeeds after
///   `demo_delay_ms` (`/__admin/config`, default 4 s) — the wait compressed for the preview — while
///   the generate reply keeps the real ETA ([etaSeconds], "Usually about 45
///   seconds");
/// * carries the manifest's lyrics and section timing, so the glimpse and the
///   synced lyrics are the song's own;
/// * serves the manifest's audio (and its WAV render for the download page).
///
/// A lyric video of a demo song serves the manifest video of that storefront.
/// The manifest is validated by `store-preview` before any recording;
/// this loader re-checks only what it serves.
class DemoProfile {
  DemoProfile._(this.manifestPath, this._songs, this._videos);

  /// Loads `manifest.json` (schema 2, store_preview/songlet/media); files resolve
  /// against its directory.
  factory DemoProfile.load(String manifestPath) {
    final file = File(manifestPath);
    if (!file.existsSync()) {
      throw ApiException.validation('manifest', 'no such file $manifestPath');
    }
    final Object? raw;
    try {
      raw = jsonDecode(file.readAsStringSync());
    } on FormatException catch (e) {
      throw ApiException.validation('manifest', 'not JSON: ${e.message}');
    }
    if (raw is! Map || raw['schema'] != 2) {
      throw ApiException.validation('manifest', 'is not schema 2 (packages/store_preview ADR-0008)');
    }
    final entries = raw['entries'];
    if (entries is! List) {
      throw ApiException.validation('manifest', 'has no entries list');
    }
    final dir = p.dirname(p.absolute(manifestPath));
    final songs = <String, DemoSong>{};
    final videos = <String, DemoVideo>{};
    for (final e in entries) {
      if (e is! Map) continue;
      final role = e['role'];
      final locale = e['locale'];
      final script = e['script'];
      final rel = e['file'];
      if (locale is! String || script is! String || rel is! String) continue;
      final path = p.normalize(p.join(dir, rel));
      final data = e['data'] is Map ? e['data'] as Map : const <String, Object?>{};
      if (role == 'song') {
        final structure = data['structure'];
        songs[_key(script, locale)] = DemoSong(
          audioPath: _existing(path),
          lyrics: (data['lyrics'] as String?) ?? '',
          structure: [
            if (structure is List)
              for (final s in structure)
                if (s is Map)
                  {
                    'section': '${s['section']}',
                    'start': (s['start'] as num).toDouble(),
                    'end': (s['end'] as num).toDouble(),
                  },
          ],
        );
      } else if (role == 'lyric_video') {
        videos[_key(script, locale)] = DemoVideo(videoPath: _existing(path));
      }
    }
    return DemoProfile._(p.absolute(manifestPath), songs, videos);
  }

  /// The real ETA a song job announces (PRD §5: about 45 s on Lyria).
  static const int etaSeconds = 45;

  final String manifestPath;
  final Map<String, DemoSong> _songs;
  final Map<String, DemoVideo> _videos;

  String? _script;
  String? _locale;

  static String _key(String script, String locale) => '$script|$locale';

  static String _existing(String path) {
    if (!File(path).existsSync()) {
      throw ApiException.validation('manifest', 'missing file $path');
    }
    return path;
  }

  /// The song the next job makes: [script]'s song of [locale].
  void select(String script, String locale) {
    if (!_songs.containsKey(_key(script, locale))) {
      throw ApiException.validation('script', 'no $script song for $locale in $manifestPath');
    }
    _script = script;
    _locale = locale;
  }

  DemoSong? get selectedSong => _script == null ? null : _songs[_key(_script!, _locale!)];

  /// The lyric video of the selected storefront's song, when it has one.
  DemoVideo? get selectedVideo => _script == null ? null : _videos[_key(_script!, _locale!)];

  Map<String, Object?> toJson() => {
    'manifest': manifestPath,
    'songs': _songs.length,
    'videos': _videos.length,
    'script': _script,
    'locale': _locale,
  };
}

class DemoSong {
  const DemoSong({required this.audioPath, required this.lyrics, required this.structure});

  final String audioPath;
  final String lyrics;
  final List<Map<String, Object>> structure;

  /// The song's length: the end of its last section.
  int get seconds => structure.isEmpty ? 0 : (structure.last['end']! as double).ceil();
}

class DemoVideo {
  const DemoVideo({required this.videoPath});

  final String videoPath;

  /// The video's length from ffprobe (`null` when it cannot be read).
  int? probeDurationMs() {
    try {
      final result = Process.runSync('ffprobe', [
        '-v', 'error', '-show_entries', 'format=duration', //
        '-of', 'default=noprint_wrappers=1:nokey=1', videoPath,
      ]);
      final seconds = double.tryParse('${result.stdout}'.trim());
      return seconds == null ? null : (seconds * 1000).round();
    } on ProcessException {
      return null;
    }
  }
}

/// The WAV render of a demo song's audio for the download page, made once
/// with ffmpeg next to the system temp dir.
File demoWav(String audioPath) {
  final out = File(p.join(
    Directory.systemTemp.path,
    'songlet_demo_wav',
    '${p.basenameWithoutExtension(audioPath)}-${File(audioPath).lengthSync()}.wav',
  ));
  if (out.existsSync()) return out;
  out.parent.createSync(recursive: true);
  final result = Process.runSync('ffmpeg', ['-v', 'error', '-y', '-i', audioPath, '-ar', '44100', '-ac', '2', out.path]);
  if (result.exitCode != 0) {
    throw ApiException(ApiCodes.serverError, 'ffmpeg could not render WAV: ${result.stderr}');
  }
  return out;
}
