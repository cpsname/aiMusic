import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../domain/music_speech_gateway.dart';
import 'music_speech_providers.dart';

/// The composer's dictation session (docs/ui P03a).
@immutable
sealed class MusicDictationState {
  const MusicDictationState();
}

final class MusicDictationIdle extends MusicDictationState {
  const MusicDictationIdle();
}

final class MusicDictationStarting extends MusicDictationState {
  const MusicDictationStarting();
}

final class MusicDictationRecording extends MusicDictationState {
  const MusicDictationRecording({
    required this.transcript,
    required this.levels,
    required this.elapsed,
    this.finished = false,
  });

  final String transcript;

  /// Recent input levels, newest last (≤ [MusicDictationController.levelHistory]).
  final List<double> levels;
  final Duration elapsed;

  /// The recognizer delivered its final transcript.
  final bool finished;

  MusicDictationRecording copyWith({
    String? transcript,
    List<double>? levels,
    Duration? elapsed,
    bool? finished,
  }) =>
      MusicDictationRecording(
        transcript: transcript ?? this.transcript,
        levels: levels ?? this.levels,
        elapsed: elapsed ?? this.elapsed,
        finished: finished ?? this.finished,
      );
}

final class MusicDictationUnavailable extends MusicDictationState {
  const MusicDictationUnavailable(this.reason);

  final MusicSpeechAvailability reason;
}

class MusicDictationController extends Notifier<MusicDictationState> {
  /// Level samples kept for the meter.
  static const int levelHistory = 48;

  /// Hard stop, like the system dictation limit.
  static const Duration maxDuration = Duration(minutes: 1);

  /// Elapsed-time refresh rate.
  static const Duration clockInterval = Duration(milliseconds: 250);

  StreamSubscription<MusicSpeechEvent>? _events;
  Timer? _clock;
  DateTime? _startedAt;

  MusicSpeechGateway get _gateway => ref.read(speechGatewayProvider);

  @override
  MusicDictationState build() {
    ref.onDispose(_teardown);
    return const MusicDictationIdle();
  }

  Future<void> start(String locale) async {
    if (state is MusicDictationStarting || state is MusicDictationRecording) return;
    state = const MusicDictationStarting();
    final availability = await _gateway.availability(locale);
    if (availability != MusicSpeechAvailability.available) {
      state = MusicDictationUnavailable(availability);
      return;
    }
    _startedAt = DateTime.now();
    state = const MusicDictationRecording(transcript: '', levels: [], elapsed: Duration.zero);
    _clock = Timer.periodic(clockInterval, (_) => _tick());
    _events = _gateway.start(locale).listen(_onEvent, onDone: _onDone);
  }

  void _tick() {
    final current = state;
    final started = _startedAt;
    if (current is! MusicDictationRecording || started == null || current.finished) return;
    final elapsed = DateTime.now().difference(started);
    state = current.copyWith(elapsed: elapsed);
    if (elapsed >= maxDuration) stop();
  }

  void _onEvent(MusicSpeechEvent event) {
    final current = state;
    if (current is! MusicDictationRecording) return;
    state = switch (event) {
      MusicSpeechPartial(:final text) => current.copyWith(transcript: text),
      MusicSpeechLevel(:final level) => current.copyWith(levels: _append(current.levels, level)),
      MusicSpeechFinal(:final text) => current.copyWith(
          transcript: text.isEmpty ? current.transcript : text,
          finished: true,
        ),
      MusicSpeechFailure(:final reason) => MusicDictationUnavailable(reason),
    };
    if (event is MusicSpeechFinal || event is MusicSpeechFailure) _clock?.cancel();
  }

  void _onDone() {
    _clock?.cancel();
    final current = state;
    if (current is MusicDictationRecording && !current.finished) {
      state = current.copyWith(finished: true);
    }
  }

  static List<double> _append(List<double> levels, double level) {
    final next = [...levels, level];
    return next.length > levelHistory ? next.sublist(next.length - levelHistory) : next;
  }

  /// Ends recording; the final transcript arrives through the stream.
  Future<void> stop() async {
    if (state is! MusicDictationRecording) return;
    _clock?.cancel();
    await _gateway.stop();
  }

  /// Abandons the session and returns to idle.
  Future<void> cancel() async {
    final active = state is MusicDictationRecording || state is MusicDictationStarting;
    _teardown();
    state = const MusicDictationIdle();
    if (active) await _gateway.cancel();
  }

  /// Back to idle after the transcript was used.
  void reset() {
    _teardown();
    state = const MusicDictationIdle();
  }

  void _teardown() {
    _clock?.cancel();
    _clock = null;
    _events?.cancel();
    _events = null;
    _startedAt = null;
  }
}
