import 'package:meta/meta.dart';

/// What the player is doing (PRD F07). Driven only by the native progress
/// callback, so lock-screen / Control Center commands are reflected too.
@immutable
class PlaybackState {
  const PlaybackState({
    this.path,
    this.position = 0,
    this.isPlaying = false,
    this.loop = false,
    this.completedCount = 0,
    this.shuffle = false,
  });

  static const PlaybackState idle = PlaybackState();

  /// The loaded file, null when stopped.
  final String? path;
  final double position;
  final bool isPlaying;
  final bool loop;

  /// Increments each time playback reaches the end (drives "first listen
  /// finished → paywall", PRD §8.2).
  final int completedCount;

  /// Sections play in a shuffled order (docs/ui P09).
  final bool shuffle;

  bool isCurrent(String candidate) => path == candidate;

  PlaybackState copyWith({
    String? path,
    bool clearPath = false,
    double? position,
    bool? isPlaying,
    bool? loop,
    int? completedCount,
    bool? shuffle,
  }) =>
      PlaybackState(
        path: clearPath ? null : (path ?? this.path),
        position: position ?? this.position,
        isPlaying: isPlaying ?? this.isPlaying,
        loop: loop ?? this.loop,
        completedCount: completedCount ?? this.completedCount,
        shuffle: shuffle ?? this.shuffle,
      );
}
