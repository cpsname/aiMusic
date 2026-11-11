import 'package:meta/meta.dart';

/// Whether on-device dictation can run for a locale (ADR-0006).
enum SpeechAvailability {
  available,

  /// Microphone or speech-recognition permission refused.
  denied,

  /// No on-device model for the locale — audio never goes to a server, so
  /// dictation is simply not offered.
  unsupportedLocale,

  /// Recognizer busy / restricted / no microphone.
  unavailable;

  static SpeechAvailability fromWire(String? value) =>
      values.firstWhere((v) => v.name == value, orElse: () => unavailable);
}

/// One update from a dictation session.
@immutable
sealed class SpeechEvent {
  const SpeechEvent();
}

/// The best transcript so far (replaces the previous one).
final class SpeechPartial extends SpeechEvent {
  const SpeechPartial(this.text);

  final String text;
}

/// Input level 0..1 for the meter.
final class SpeechLevel extends SpeechEvent {
  const SpeechLevel(this.level);

  final double level;
}

/// The final transcript; the session is over.
final class SpeechFinal extends SpeechEvent {
  const SpeechFinal(this.text);

  final String text;
}

/// The session failed.
final class SpeechFailure extends SpeechEvent {
  const SpeechFailure(this.reason);

  final SpeechAvailability reason;
}

/// On-device speech recognition (SFSpeechRecognizer, `requiresOnDeviceRecognition`)
/// — the P03a voice input. Implemented on a channel beside the fixed PRD §6.4
/// Pigeon bridge (ADR-0006).
abstract interface class SpeechGateway {
  Future<SpeechAvailability> availability(String locale);

  /// Starts a session; the stream ends after [SpeechFinal] or [SpeechFailure].
  Stream<SpeechEvent> start(String locale);

  /// Ends the session and delivers the final transcript.
  Future<void> stop();

  /// Abandons the session without a transcript.
  Future<void> cancel();
}
