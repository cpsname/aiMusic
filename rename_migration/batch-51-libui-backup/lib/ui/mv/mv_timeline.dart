import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../create/create_labels.dart';
import '../player/lyrics_model.dart';

/// The part of its song a video covers, in song seconds (docs/ui P26):
/// the whole song for lyric and full videos, the chosen window for a chorus
/// video. Null when the platform located the chorus itself — the page then
/// cannot place lyrics or sections, and shows neither.
({double start, double end})? mvSongWindow(MusicWork work, MusicVideo video) {
  final duration = workDuration(work);
  return switch (video.level) {
    MusicMvLevel.chorus => switch (video.chorus) {
      final MusicMvChorusWindow w => (start: w.startMs / 1000, end: w.endMs / 1000),
      null => null,
    },
    MusicMvLevel.lyricVideo || MusicMvLevel.full => (start: 0, end: duration),
  };
}

/// The song's timed lines inside [window], on the video's clock.
List<TimedLine> mvTimedLines(MusicWork work, ({double start, double end}) window) =>
    [
      for (final line in timedLines(lyricBlocks(work.lyrics, work.structure)))
        if (line.start case final start?
            when start >= window.start && start < window.end)
          (
            text: line.text,
            start: start - window.start,
            breakBefore: line.breakBefore,
          ),
    ];

/// The song's sections inside [window], as fractions of the video.
List<TrackSection> mvSections(
  AppLocalizations l10n,
  MusicWork work,
  ({double start, double end}) window,
) {
  final span = window.end - window.start;
  if (span <= 0) return const [];
  return [
    for (final s in work.structure)
      if (s.end > window.start && s.start < window.end)
        (
          label: sectionName(l10n, s.label),
          start: ((s.start - window.start) / span).clamp(0.0, 1.0),
          end: ((s.end - window.start) / span).clamp(0.0, 1.0),
        ),
  ];
}

/// Index of the section playing at [fraction] of the video (-1 = none).
int mvSectionAt(List<TrackSection> sections, double fraction) {
  for (var i = 0; i < sections.length; i++) {
    if (fraction >= sections[i].start && fraction < sections[i].end) return i;
  }
  return -1;
}
