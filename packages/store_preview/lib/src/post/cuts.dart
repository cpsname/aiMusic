import '../config/script.dart';
import '../core/errors.dart';
import '../driver/take.dart';

/// A stretch of the recording placed in the timeline clip: `from`–`to`
/// (recording seconds) played to [frames] output frames. A hold (one frame
/// held under a card or bridge) is a one-frame span stretched.
class Cut {
  const Cut({required this.from, required this.to, required this.frames, required this.fps});

  final double from;
  final double to;
  final int frames;
  final int fps;

  /// The cutter's `factor`: output time per source time.
  double get factor => frames / ((to - from) * fps);

  Map<String, Object?> toJson() => {'from': from, 'to': to, 'factor': factor};
}

/// The timeline clip of a script: every segment's cuts, back to back, frame
/// exact (frame counts from cumulative rounding, so the clip holds exactly
/// `duration × fps` frames), and where each scene came from.
class TimelineCuts {
  const TimelineCuts(this.cuts, this.sources);

  final List<Cut> cuts;

  /// scene id → recording span and speed.
  final Map<String, ({double from, double to, double speed})> sources;
}

TimelineCuts timelineCuts(PreviewScript script, Take take, {required int fps}) {
  int frame(double t) => (t * fps).round();
  final frameLength = 1 / fps;
  final cuts = <Cut>[];
  final sources = <String, ({double from, double to, double speed})>{};

  SceneWindow windowOf(SceneSegment s) => take.window(script.id, s.id);
  Cut hold(double at, double start, double end) =>
      Cut(from: at, to: at + frameLength, frames: frame(end) - frame(start), fps: fps);

  final segments = script.segments;
  for (final (i, seg) in segments.indexed) {
    switch (seg) {
      case SceneSegment():
        final w = windowOf(seg);
        final from = take.at(w.startMs);
        final filmed = (w.endMs - w.startMs) / 1000;
        final double to;
        if (!seg.retime) {
          if (filmed < seg.duration - 0.05) {
            throw ConfigError('${script.id}/${seg.id} runs in real time for ${seg.duration}s but was filmed for ${filmed.toStringAsFixed(2)}s');
          }
          to = from + seg.duration;
        } else {
          if (filmed < seg.duration * 0.97 || filmed > seg.duration * seg.maxSpeed) {
            throw ConfigError('${script.id}/${seg.id} was filmed for ${filmed.toStringAsFixed(2)}s, its slot is ${seg.duration}s '
                '(allowed ×1–×${seg.maxSpeed}) — adjust the script\'s pauses');
          }
          to = take.at(w.endMs);
        }
        cuts.add(Cut(from: from, to: to, frames: frame(seg.end) - frame(seg.start), fps: fps));
        sources[seg.id] = (from: from, to: to, speed: (to - from) / seg.duration);
      case CardSegment():
        // Under the card: the first frame of the scene after it (intro) or
        // the last of the scene before it (outro) — the card dissolves
        // into / out of that frame.
        final at = seg.kind == 'intro' ? _firstFrame(segments, i, script, take) : _lastFrame(segments, i, script, take, frameLength);
        cuts.add(hold(at, seg.start, seg.end));
      case BridgeSegment():
        final mid = seg.start + seg.duration / 2;
        cuts
          ..add(hold(_lastFrame(segments, i, script, take, frameLength), seg.start, mid))
          ..add(hold(_firstFrame(segments, i, script, take), mid, seg.end));
    }
  }
  return TimelineCuts(cuts, sources);
}

/// The recording time of the first frame of the next scene after [i].
double _firstFrame(List<Segment> segments, int i, PreviewScript script, Take take) {
  final next = segments.skip(i + 1).whereType<SceneSegment>().firstOrNull ?? (throw ConfigError('${script.id}: no scene after ${segments[i].id}'));
  return take.at(take.window(script.id, next.id).startMs);
}

/// The recording time of the last frame of the scene before [i].
double _lastFrame(List<Segment> segments, int i, PreviewScript script, Take take, double frameLength) {
  final previous = segments.take(i).whereType<SceneSegment>().lastOrNull ?? (throw ConfigError('${script.id}: no scene before ${segments[i].id}'));
  final w = take.window(script.id, previous.id);
  final start = take.at(w.startMs);
  final end = previous.retime ? take.at(w.endMs) : start + previous.duration;
  return end - frameLength;
}
