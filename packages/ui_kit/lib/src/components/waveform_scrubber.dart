import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import '../waveform.dart';

/// How the playhead is drawn.
enum PlayheadStyle {
  /// A filled disc on the midline (docs/ui P07).
  dot,

  /// A thin vertical line topped with a dot (docs/ui P09).
  line,
}

/// Seekable waveform with a playhead and elapsed / total labels (docs/ui P07,
/// P09). Tap or drag to seek; [onSeek] receives 0..1 when the drag ends.
class WaveformScrubber extends StatefulWidget {
  const WaveformScrubber({
    super.key,
    required this.bars,
    required this.progress,
    required this.elapsedLabel,
    required this.totalLabel,
    required this.semanticsLabel,
    this.onSeek,
    this.labelFor,
    this.playhead = PlayheadStyle.dot,
    this.height = SongletSize.waveformHeight,
  });

  final List<double> bars;
  final double progress;
  final String elapsedLabel;
  final String totalLabel;
  final String semanticsLabel;
  final ValueChanged<double>? onSeek;

  /// Formats a position (0..1) for VoiceOver's adjustable steps; without it
  /// the scrubber is announced but not adjustable.
  final String Function(double fraction)? labelFor;
  final PlayheadStyle playhead;
  final double height;

  @override
  State<WaveformScrubber> createState() => _WaveformScrubberState();
}

class _WaveformScrubberState extends State<WaveformScrubber> {
  /// VoiceOver adjust step (a tenth of the song).
  static const double _step = 0.1;

  double? _drag;

  double _fraction(Offset local, double width, bool rtl) {
    final x = (local.dx / width).clamp(0.0, 1.0);
    return rtl ? 1 - x : x;
  }

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final shown = (_drag ?? widget.progress).clamp(0.0, 1.0);
    final adjustable = widget.onSeek != null && widget.labelFor != null;
    final up = (shown + _step).clamp(0.0, 1.0);
    final down = (shown - _step).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          slider: true,
          label: widget.semanticsLabel,
          value: widget.elapsedLabel,
          increasedValue: adjustable ? widget.labelFor!(up) : null,
          decreasedValue: adjustable ? widget.labelFor!(down) : null,
          onIncrease: adjustable ? () => widget.onSeek!(up) : null,
          onDecrease: adjustable ? () => widget.onSeek!(down) : null,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              void update(Offset local) =>
                  setState(() => _drag = _fraction(local, width, rtl));
              void commit() {
                final value = _drag;
                setState(() => _drag = null);
                if (value != null) widget.onSeek?.call(value);
              }

              // Playhead offset in reading direction (mirrors in RTL).
              final x = shown * width;
              final knob = widget.playhead == PlayheadStyle.dot
                  ? SongletSize.iconXl
                  : SongletSize.iconSm;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: widget.onSeek == null
                    ? null
                    : (d) => update(d.localPosition),
                onTapUp: widget.onSeek == null ? null : (_) => commit(),
                onHorizontalDragStart: widget.onSeek == null
                    ? null
                    : (d) => update(d.localPosition),
                onHorizontalDragUpdate: widget.onSeek == null
                    ? null
                    : (d) => update(d.localPosition),
                onHorizontalDragEnd: widget.onSeek == null
                    ? null
                    : (_) => commit(),
                child: SizedBox(
                  height: widget.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: WaveformView(
                          bars: widget.bars,
                          progress: shown,
                          activeColor: c.accent,
                          inactiveColor: c.waveformIdle,
                          height: widget.height,
                        ),
                      ),
                      if (widget.playhead == PlayheadStyle.line)
                        PositionedDirectional(
                          start: x - SongletSize.hairline,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: SongletSize.focusRing,
                            color: c.accent,
                          ),
                        ),
                      PositionedDirectional(
                        // Centred on the playhead, kept inside the track.
                        start: (x - knob / 2)
                            .clamp(0.0, math.max(0.0, width - knob))
                            .toDouble(),
                        top: widget.playhead == PlayheadStyle.dot
                            ? widget.height / 2 - knob / 2
                            : -knob / 2,
                        child: Container(
                          width: knob,
                          height: knob,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                            border: widget.playhead == PlayheadStyle.dot
                                ? Border.all(
                                    color: c.surface,
                                    width: SongletSize.focusRing * 2,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: SongletSpace.x2),
        ExcludeSemantics(
          child: Row(
            children: [
              Text(widget.elapsedLabel, style: _time(c)),
              const Spacer(),
              Text(widget.totalLabel, style: _time(c)),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _time(SongletColors c) => SongletType.footnote.copyWith(
    color: c.inkSecondary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// One labelled song section on the [SectionTrack].
typedef TrackSection = ({String label, double start, double end});

/// The song's sections under the waveform (docs/ui P09: Intro · Verse ·
/// Chorus · Bridge · Outro); tap jumps to a section.
class SectionTrack extends StatelessWidget {
  const SectionTrack({
    super.key,
    required this.sections,
    required this.current,
    this.onSelect,
  });

  /// Fractions 0..1 of the song.
  final List<TrackSection> sections;
  final int current;
  final ValueChanged<int>? onSelect;

  /// Flex units per whole song (section fractions → integer flex weights);
  /// also the cap of one section's weight.
  static const int _flexResolution = 1000;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    if (sections.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          height: SongletSize.iconMd,
          decoration: BoxDecoration(
            color: c.accentSoft,
            borderRadius: SongletRadius.pillAll,
          ),
          child: Row(
            children: [
              for (var i = 0; i < sections.length; i++)
                Expanded(
                  flex:
                      ((sections[i].end - sections[i].start) * _flexResolution)
                          .round()
                          .clamp(1, _flexResolution),
                  child: Container(
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : BorderDirectional(
                              start: BorderSide(color: c.surface),
                            ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: SongletSpace.x2,
                      height: SongletSpace.x2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == current ? c.accent : c.inkTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: SongletSpace.x1),
        Row(
          children: [
            for (var i = 0; i < sections.length; i++)
              Expanded(
                flex: ((sections[i].end - sections[i].start) * _flexResolution)
                    .round()
                    .clamp(1, _flexResolution),
                child: Semantics(
                  button: onSelect != null,
                  selected: i == current,
                  child: InkWell(
                    onTap: onSelect == null ? null : () => onSelect!(i),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        vertical: SongletSpace.x1,
                      ),
                      child: Text(
                        sections[i].label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SongletType.caption.copyWith(
                          color: i == current ? c.ink : c.inkSecondary,
                          fontWeight: i == current
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
