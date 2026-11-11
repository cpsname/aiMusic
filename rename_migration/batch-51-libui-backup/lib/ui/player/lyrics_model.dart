import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../common/localized_formats.dart';

/// A lyric section as displayed: its tag label, lines, and (when the job
/// returned a `structure`) its time window for sync (PRD F07 "歌词同步滚动").
class LyricBlock {
  const LyricBlock({
    required this.label,
    required this.lines,
    this.start,
    this.end,
  });

  final String label;
  final List<String> lines;
  final double? start;
  final double? end;

  bool contains(double position) =>
      start != null && end != null && position >= start! && position < end!;
}

final RegExp _tag = RegExp(r'^\s*\[([^\]]+)\]\s*$');

/// Splits `[Section]`-tagged lyrics into blocks and pairs them, in order, with
/// the returned structure's time windows.
List<LyricBlock> lyricBlocks(String lyrics, List<MusicLyricSection> structure) {
  final blocks = <({String label, List<String> lines})>[];
  for (final raw in lyrics.split('\n')) {
    final line = raw.trimRight();
    final tag = _tag.firstMatch(line);
    if (tag != null) {
      blocks.add((label: tag.group(1)!.trim(), lines: <String>[]));
    } else if (line.trim().isNotEmpty) {
      if (blocks.isEmpty) blocks.add((label: '', lines: <String>[]));
      blocks.last.lines.add(line.trim());
    }
  }
  return [
    for (final (i, block) in blocks.indexed)
      LyricBlock(
        label: block.label,
        lines: block.lines,
        start: i < structure.length ? structure[i].start : null,
        end: i < structure.length ? structure[i].end : null,
      ),
  ];
}

/// A timed lyric line for the synced view: each block's window is shared
/// evenly across its lines.
typedef TimedLine = ({String text, double? start, bool breakBefore});

List<TimedLine> timedLines(List<LyricBlock> blocks) => [
  for (final block in blocks)
    for (final (i, line) in block.lines.indexed)
      (
        text: line,
        start: block.start == null || block.end == null
            ? null
            : block.start! +
                  (block.end! - block.start!) * i / block.lines.length,
        breakBefore: i == 0,
      ),
];

/// Index of the line being sung at [position] (-1 before the first).
int activeLine(List<TimedLine> lines, double position) {
  var active = -1;
  for (var i = 0; i < lines.length; i++) {
    final start = lines[i].start;
    if (start != null && position >= start) active = i;
  }
  return active;
}

/// The lines for [SyncedLyricsView], with "0:12" stamps when [withTimes].
List<LyricLineView> lyricLineViews(
  List<TimedLine> lines, {
  required bool withTimes,
  required String locale,
}) => [
  for (final line in lines)
    (
      text: line.text,
      time: withTimes && line.start != null
          ? clockLabel(line.start!, locale)
          : null,
      breakBefore: line.breakBefore,
    ),
];

/// "m:ss".
String clockLabel(double seconds, String locale) =>
    mediaDuration(seconds, locale);

/// Nominal length of a preview clip in seconds (Lyria clip model).
const double clipSeconds = 30;

/// Nominal length of a full song in seconds (≈ 2 min, Lyria pro model).
const double songSeconds = 120;

/// Length of a work's audio in seconds, from its structure (fallback: the
/// model's nominal length — [clipSeconds] / [songSeconds]).
double workDuration(MusicWork work) {
  if (work.structure.isNotEmpty) return work.structure.last.end;
  return work.isClip ? clipSeconds : songSeconds;
}

/// Initial hash state of [waveformBars]' seed fold.
const int _barsHashSeed = 0x2545F491;

/// Multiplier of the string hash over the seed's code units.
const int _hashMultiplier = 31;

/// Keeps hash / generator state in 31 bits (also the generator's maximum).
const int _mask31 = 0x7fffffff;

/// Linear congruential generator constants (the classic C `rand()` pair).
const int _lcgMultiplier = 1103515245;
const int _lcgIncrement = 12345;

/// Bar-height envelope: [_envelopeBase] at the edges plus up to
/// [_envelopeRange] toward the middle, falling off by [_envelopeFalloff].
const double _envelopeBase = 0.55;
const double _envelopeRange = 0.45;
const double _envelopeFalloff = 1.4;

/// Smoothing: share of the previous bar kept vs. the fresh random draw.
const double _carryWeight = 0.45;
const double _freshWeight = 0.55;

/// Shortest bar, as a share of full height.
const double _minBar = 0.12;

/// Deterministic decorative waveform bars for a work (seeded by its id, so the
/// same song always looks the same).
List<double> waveformBars(String seed, {int count = SongletSize.waveformBars}) {
  var state = seed.codeUnits.fold<int>(
    _barsHashSeed,
    (h, c) => (h * _hashMultiplier + c) & _mask31,
  );
  final bars = <double>[];
  var previous = 0.5;
  for (var i = 0; i < count; i++) {
    state = (state * _lcgMultiplier + _lcgIncrement) & _mask31;
    final random = state / _mask31;
    final envelope =
        _envelopeBase +
        _envelopeRange * (1 - ((i / count) - 0.5).abs() * _envelopeFalloff);
    previous = (previous * _carryWeight) + (random * _freshWeight);
    bars.add((previous * envelope).clamp(_minBar, 1.0));
  }
  return bars;
}
