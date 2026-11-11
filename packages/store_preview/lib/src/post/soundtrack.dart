import '../config/defaults.dart';

/// What plays under the preview from [from] to [to]: [file] at preview time
/// t + [offset].
class AudioCue {
  const AudioCue({required this.file, required this.offset, required this.from, required this.to});

  final String file;
  final double offset;
  final double from;
  final double to;
}

/// One soundtrack across the preview (Apple: "a single musical score or
/// soundtrack"): each scene that follows playback pins its source to the
/// preview clock (position at its start − its start); the first source runs
/// from 0, each next one takes over at its scene, a scene continuing the
/// same source at the same offset merges.
List<AudioCue> audioCues(List<({double start, String file, double offset})> follows, double duration) {
  if (follows.isEmpty) return const [];
  final merged = <({double start, String file, double offset})>[];
  for (final f in follows) {
    final last = merged.isEmpty ? null : merged.last;
    if (last != null && last.file == f.file && (last.offset - f.offset).abs() < 0.1) continue;
    merged.add(f);
  }
  return [
    for (final (i, f) in merged.indexed)
      AudioCue(
        file: f.file,
        offset: f.offset,
        from: i == 0 ? 0 : f.start,
        to: i + 1 < merged.length ? merged[i + 1].start : duration,
      ),
  ];
}

String n4(double v) => v.toStringAsFixed(4);

/// The filter chains that produce `[aout]`.
///
/// [cues] play from their inputs ([inputOf] maps a file to its input index),
/// crossfading where one hands over to the next; a [voiceover] (input index,
/// from preview time 0) ducks the music under it by sidechain compression
/// and is mixed on top; [silent] (an `anullsrc` input) is the track when
/// there is no music. Head fade-in and tail fade-out, then trimmed to
/// [duration] at the target rate.
List<String> soundtrackGraph({
  required List<AudioCue> cues,
  required int Function(String file) inputOf,
  required Encoding encoding,
  required double duration,
  int? voiceover,
  int? silent,
}) {
  final graph = <String>[];
  final format = 'aformat=sample_rates=${encoding.sampleRate}:channel_layouts=stereo';
  final mixes = <String>[];
  for (final (i, cue) in cues.indexed) {
    final first = i == 0;
    final last = i == cues.length - 1;
    final a = cue.from - (first ? 0 : encoding.crossfade / 2);
    final b = cue.to + (last ? 0 : encoding.crossfade / 2);
    final sourceStart = a + cue.offset;
    final delay = sourceStart < 0 ? a - sourceStart : a;
    final start = sourceStart < 0 ? 0.0 : sourceStart;
    final end = b + cue.offset;
    if (end <= start) continue;
    final length = end - start;
    final chain = [
      'atrim=start=${n4(start)}:end=${n4(end)}',
      'asetpts=PTS-STARTPTS',
      format,
      if (!first) 'afade=t=in:d=${encoding.crossfade}',
      if (!last) 'afade=t=out:st=${n4(length - encoding.crossfade)}:d=${encoding.crossfade}',
      'adelay=${(delay * 1000).round()}:all=1',
    ];
    graph.add('[${inputOf(cue.file)}:a]${chain.join(',')}[m$i]');
    mixes.add('[m$i]');
  }
  final finish = 'apad,atrim=duration=${n4(duration)},'
      'afade=t=in:d=${encoding.fadeIn},afade=t=out:st=${n4(duration - encoding.fadeOut)}:d=${encoding.fadeOut},'
      'aresample=${encoding.sampleRate}';
  if (mixes.isEmpty) {
    if (silent == null) throw ArgumentError('no music cue and no silent input');
    graph.add('[$silent:a]$format,atrim=duration=${n4(duration)}[music]');
  } else {
    graph.add('${mixes.join()}amix=inputs=${mixes.length}:normalize=0:duration=longest[music]');
  }
  if (voiceover == null) {
    graph.add('[music]$finish[aout]');
    return graph;
  }
  graph
    ..add('[$voiceover:a]$format,asplit=2[vo][key]')
    ..add('[music][key]sidechaincompress=threshold=${encoding.duckThreshold}:ratio=${encoding.duckRatio}:attack=20:release=300[ducked]')
    ..add('[ducked][vo]amix=inputs=2:normalize=0:duration=first,$finish[aout]');
  return graph;
}
