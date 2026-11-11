import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../domain/speech_gateway.dart';
import 'speech_providers.dart';

/// The composer's dictation session (docs/ui P03a).
@immutable
sealed class DictationState {
  const DictationState();
}

final class DictationIdle extends DictationState {
  const DictationIdle();
}

final class DictationStarting extends DictationState {
  const DictationStarting();
}

final class DictationRecording extends DictationState {
  const DictationRecording({
    required this.transcript,
    required this.levels,
    required this.elapsed,
    this.finished = false,
  });

  final String transcript;

  /// Recent input levels, newest last (≤ [DictationController.levelHistory]).
  final List<double> levels;
  final Duration elapsed;

  /// The recognizer delivered its final transcript.
  final bool finished;

  DictationRecording copyWith({
    String? transcript,
    List<double>? levels,
    Duration? elapsed,
    bool? finished,
  }) =>
      DictationRecording(
        transcript: transcript ?? this.transcript,
        levels: levels ?? this.levels,
        elapsed: elapsed ?? this.elapsed,
        finished: finished ?? this.finished,
      );
}

final class DictationUnavailable extends DictationState {
  const DictationUnavailable(this.reason);

  final SpeechAvailability reason;
}

class DictationController extends Notifier<DictationState> {
  /// Level samples kept for the meter.
  static const int levelHistory = 48;

  /// Hard stop, like the system dictation limit.
  static const Duration maxDuration = Duration(minutes: 1);

  /// Elapsed-time refresh rate.
  static const Duration clockInterval = Duration(milliseconds: 250);

  StreamSubscription<SpeechEvent>? _events;
  Timer? _clock;
  DateTime? _startedAt;

  SpeechGateway get _gateway => ref.read(speechGatewayProvider);

  @override
  DictationState build() {
    ref.onDispose(_teardown);
    return const DictationIdle();
  }

  Future<void> start(String locale) async {
    if (state is DictationStarting || state is DictationRecording) return;
    state = const DictationStarting();
    final availability = await _gateway.availability(locale);
    if (availability != SpeechAvailability.available) {
      state = DictationUnavailable(availability);
      return;
    }
    _startedAt = DateTime.now();
    state = const DictationRecording(transcript: '', levels: [], elapsed: Duration.zero);
    _clock = Timer.periodic(clockInterval, (_) => _tick());
    _events = _gateway.start(locale).listen(_onEvent, onDone: _onDone);
  }

  void _tick() {
    final current = state;
    final started = _startedAt;
    if (current is! DictationRecording || started == null || current.finished) return;
    final elapsed = DateTime.now().difference(started);
    state = current.copyWith(elapsed: elapsed);
    if (elapsed >= maxDuration) stop();
  }

  void _onEvent(SpeechEvent event) {
    final current = state;
    if (current is! DictationRecording) return;
    state = switch (event) {
      SpeechPartial(:final text) => current.copyWith(transcript: text),
      SpeechLevel(:final level) => current.copyWith(levels: _append(current.levels, level)),
      SpeechFinal(:final text) => current.copyWith(
          transcript: text.isEmpty ? current.transcript : text,
          finished: true,
        ),
      SpeechFailure(:final reason) => DictationUnavailable(reason),
    };
    if (event is SpeechFinal || event is SpeechFailure) _clock?.cancel();
  }

  void _onDone() {
    _clock?.cancel();
    final current = state;
    if (current is DictationRecording && !current.finished) {
      state = current.copyWith(finished: true);
    }
  }

  static List<double> _append(List<double> levels, double level) {
    final next = [...levels, level];
    return next.length > levelHistory ? next.sublist(next.length - levelHistory) : next;
  }

  /// Ends recording; the final transcript arrives through the stream.
  Future<void> stop() async {
    if (state is! DictationRecording) return;
    _clock?.cancel();
    await _gateway.stop();
  }

  /// Abandons the session and returns to idle.
  Future<void> cancel() async {
    final active = state is DictationRecording || state is DictationStarting;
    _teardown();
    state = const DictationIdle();
    if (active) await _gateway.cancel();
  }

  /// Back to idle after the transcript was used.
  void reset() {
    _teardown();
    state = const DictationIdle();
  }

  void _teardown() {
    _clock?.cancel();
    _clock = null;
    _events?.cancel();
    _events = null;
    _startedAt = null;
  }
}
