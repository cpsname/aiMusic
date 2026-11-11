import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/application/music_platform_providers.dart';
import '../../platform/domain/music_native_gateways.dart';
import '../domain/music_playback_state.dart';

/// The single app-wide player (PRD F07) over AVAudioPlayer. State follows the
/// native progress callback only, so lock-screen and Control Center commands
/// (and audio interruptions) are reflected exactly like in-app taps.
class MusicPlayerController extends Notifier<MusicPlaybackState> {
  StreamSubscription<double>? _progress;

  /// Section windows (seconds) of the loaded track, for section jumps and
  /// shuffle; empty when the track has no structure.
  List<({double start, double end})> _sections = const [];

  /// Shuffled section order while [MusicPlaybackState.shuffle] is on.
  List<int> _order = const [];
  int _orderIndex = 0;
  bool _jumping = false;

  /// Seeded so tests are deterministic; a new order per shuffle toggle.
  math.Random _random = math.Random();

  @override
  MusicPlaybackState build() {
    final engine = ref.watch(audioEngineProvider);
    _progress = engine.progress.listen(_onProgress);
    ref.onDispose(() => _progress?.cancel());
    return MusicPlaybackState.idle;
  }

  MusicAudioEngine get _engine => ref.read(audioEngineProvider);

  /// Plays [path] from the start, or toggles pause / resume when it is the
  /// loaded track.
  Future<void> toggle(String path) async {
    final loaded = state.isCurrent(path);
    if (!loaded) {
      _sections = const [];
      state = state.copyWith(path: path, position: 0, isPlaying: true, shuffle: false);
    }
    await _engine.play(path, loop: state.loop);
  }

  /// Loop on / off for the loaded track (PRD F07 "循环") without restarting.
  Future<void> setLoop({required bool loop}) async {
    // The bridge reads "loaded path + same loop" as a pause/resume toggle, so an
    // unchanged value must not reach it.
    if (loop == state.loop) return;
    final path = state.path;
    state = state.copyWith(loop: loop);
    if (path != null) await _engine.play(path, loop: loop);
  }

  Future<void> stop() async {
    if (state.path == null) return;
    await _engine.play('', loop: false);
    _sections = const [];
    state = state.copyWith(clearPath: true, position: 0, isPlaying: false, shuffle: false);
  }

  /// Jumps the loaded track to [seconds].
  Future<void> seek(double seconds) async {
    if (state.path == null) return;
    final target = math.max(0.0, seconds);
    state = state.copyWith(position: target);
    await _engine.seek(target);
  }

  /// Declares the loaded track's sections (from the job `structure`).
  void setSections(List<({double start, double end})> sections) {
    _sections = List.unmodifiable(sections);
    if (state.shuffle) _reshuffle();
  }

  /// Index of the section containing the current position, -1 if none.
  int get currentSection => sectionAt(state.position);

  int sectionAt(double position) {
    for (var i = 0; i < _sections.length; i++) {
      if (position >= _sections[i].start && position < _sections[i].end) return i;
    }
    return -1;
  }

  /// Jumps to the next (+1) or previous (-1) section; in shuffle mode, along
  /// the shuffled order. "Previous" restarts the current section when more
  /// than [restartThreshold] seconds into it, like a music player.
  Future<void> jumpSection(int direction) async {
    if (_sections.isEmpty) return;
    final current = math.max(0, currentSection);
    int target;
    if (state.shuffle && _order.isNotEmpty) {
      _orderIndex = (_orderIndex + direction) % _order.length;
      if (_orderIndex < 0) _orderIndex += _order.length;
      target = _order[_orderIndex];
    } else if (direction < 0 && state.position - _sections[current].start > restartThreshold) {
      target = current;
    } else {
      target = (current + direction).clamp(0, _sections.length - 1);
    }
    await seek(_sections[target].start);
  }

  /// Seconds into a section after which "previous" restarts it.
  static const double restartThreshold = 3;

  /// Shuffle sections on / off (docs/ui P09).
  void setShuffle({required bool shuffle, int? seed}) {
    if (seed != null) _random = math.Random(seed);
    state = state.copyWith(shuffle: shuffle);
    if (shuffle) _reshuffle();
  }

  void _reshuffle() {
    _order = List<int>.generate(_sections.length, (i) => i)..shuffle(_random);
    _orderIndex = math.max(0, _order.indexOf(math.max(0, currentSection)));
  }

  /// In shuffle mode, crossing the end of a section continues with the next
  /// section of the shuffled order instead of the following one.
  void _followShuffle(double position) {
    if (!state.shuffle || _jumping || _order.isEmpty) return;
    final playing = _order[_orderIndex];
    if (position < _sections[playing].end) return;
    _orderIndex = (_orderIndex + 1) % _order.length;
    _jumping = true;
    unawaited(seek(_sections[_order[_orderIndex]].start).whenComplete(() => _jumping = false));
  }

  void _onProgress(double value) {
    if (value == MusicAudioEngine.paused) {
      state = state.copyWith(isPlaying: false);
    } else if (value == MusicAudioEngine.ended) {
      state = state.copyWith(
        isPlaying: false,
        position: 0,
        completedCount: state.completedCount + (state.path == null ? 0 : 1),
      );
    } else if (value >= 0) {
      state = state.copyWith(position: value, isPlaying: true);
      _followShuffle(value);
    }
  }
}

final playerControllerProvider =
    NotifierProvider<MusicPlayerController, MusicPlaybackState>(MusicPlayerController.new);
