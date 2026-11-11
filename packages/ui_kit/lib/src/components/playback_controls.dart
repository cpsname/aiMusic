import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_elevation.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// Labels for [PlaybackControls] (localized by the app).
typedef PlaybackLabels = ({
  String play,
  String pause,
  String previous,
  String next,
  String shuffle,
  String repeat,
});

/// Transport row (docs/ui P09): shuffle · previous · play/pause · next ·
/// repeat. Null callbacks hide their control.
class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    super.key,
    required this.playing,
    required this.onPlayPause,
    required this.labels,
    this.onPrevious,
    this.onNext,
    this.onShuffle,
    this.onRepeat,
    this.shuffle = false,
    this.repeat = false,
  });

  final bool playing;
  final VoidCallback? onPlayPause;
  final PlaybackLabels labels;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onShuffle;
  final VoidCallback? onRepeat;
  final bool shuffle;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    Widget side(
      IconData icon,
      String label,
      VoidCallback? onTap, {
      bool? toggled,
    }) => IconButton(
      tooltip: label,
      onPressed: onTap,
      isSelected: toggled,
      iconSize: SongletSize.iconXl,
      color: toggled == true ? c.accent : c.ink,
      icon: Icon(icon, textDirection: TextDirection.ltr),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (onShuffle != null)
          side(
            Icons.shuffle_rounded,
            labels.shuffle,
            onShuffle,
            toggled: shuffle,
          ),
        if (onPrevious != null)
          side(Icons.skip_previous_rounded, labels.previous, onPrevious),
        PlayButton(
          playing: playing,
          onPressed: onPlayPause,
          playLabel: labels.play,
          pauseLabel: labels.pause,
        ),
        if (onNext != null) side(Icons.skip_next_rounded, labels.next, onNext),
        if (onRepeat != null)
          side(Icons.repeat_rounded, labels.repeat, onRepeat, toggled: repeat),
      ],
    );
  }
}

/// The large accent play / pause disc.
class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    required this.playing,
    required this.onPressed,
    required this.playLabel,
    required this.pauseLabel,
    this.size = SongletSize.playButton,
    this.busy = false,
  });

  final bool playing;
  final VoidCallback? onPressed;
  final String playLabel;
  final String pauseLabel;
  final double size;

  /// Audio is loading: shows a spinner in the disc.
  final bool busy;

  /// Spinner inset inside the disc (× disc size).
  static const double _spinnerInset = 0.3;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final e = SongletElevation.of(context);
    return Semantics(
      container: true,
      button: true,
      label: playing ? pauseLabel : playLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: e.level2),
        child: Material(
          color: c.accent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: busy ? null : onPressed,
            child: SizedBox.square(
              dimension: size,
              child: busy
                  ? Padding(
                      padding: EdgeInsets.all(size * _spinnerInset),
                      child: CircularProgressIndicator(
                        color: c.onAccent,
                        strokeWidth: SongletSize.focusRing,
                      ),
                    )
                  : Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: size * 0.5,
                      color: c.onAccent,
                      textDirection: TextDirection.ltr,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon over a caption, as the P07 "Loop" toggle.
class LabeledIconToggle extends StatelessWidget {
  const LabeledIconToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final color = selected ? c.accent : c.inkSecondary;
    return Semantics(
      container: true,
      button: true,
      toggled: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: SongletSize.minTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(SongletSpace.x2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: SongletSize.iconXl),
              Text(label, style: SongletType.footnote.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
