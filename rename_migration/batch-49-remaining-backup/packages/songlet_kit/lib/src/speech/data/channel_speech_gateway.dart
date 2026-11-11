import 'dart:async';

import 'package:flutter/services.dart';

import '../../common/json.dart';
import '../domain/speech_gateway.dart';

/// [SpeechGateway] over `songlet/speech` (methods) and `songlet/speech/events`
/// (partial / level / final / error maps) — SpeechService.swift.
class ChannelSpeechGateway implements SpeechGateway {
  const ChannelSpeechGateway({
    MethodChannel methods = const MethodChannel('songlet/speech'),
    EventChannel events = const EventChannel('songlet/speech/events'),
  })  : _methods = methods,
        _events = events;

  final MethodChannel _methods;
  final EventChannel _events;

  @override
  Future<SpeechAvailability> availability(String locale) async {
    try {
      final result = await _methods.invokeMethod<String>('availability', {'locale': locale});
      return SpeechAvailability.fromWire(result);
    } on PlatformException {
      return SpeechAvailability.unavailable;
    } on MissingPluginException {
      return SpeechAvailability.unavailable;
    }
  }

  @override
  Stream<SpeechEvent> start(String locale) {
    late final StreamController<SpeechEvent> controller;
    StreamSubscription<Object?>? subscription;
    controller = StreamController<SpeechEvent>(
      onListen: () {
        subscription = _events.receiveBroadcastStream({'locale': locale}).listen(
          (raw) {
            final event = decodeSpeechEvent(asMap(raw));
            if (event == null) return;
            controller.add(event);
            if (event is SpeechFinal || event is SpeechFailure) {
              subscription?.cancel();
              controller.close();
            }
          },
          onError: (Object error) {
            controller
              ..add(SpeechFailure(
                error is PlatformException
                    ? SpeechAvailability.fromWire(error.code)
                    : SpeechAvailability.unavailable,
              ))
              ..close();
          },
          onDone: () {
            if (!controller.isClosed) controller.close();
          },
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> stop() => _methods.invokeMethod<void>('stop');

  @override
  Future<void> cancel() => _methods.invokeMethod<void>('cancel');
}

/// Maps one event-channel payload; unknown kinds are ignored.
SpeechEvent? decodeSpeechEvent(Map<String, Object?> json) => switch (asString(json['type'])) {
      'partial' => SpeechPartial(asString(json['text'])),
      'level' => SpeechLevel(asDouble(json['level']).clamp(0, 1).toDouble()),
      'final' => SpeechFinal(asString(json['text'])),
      'error' => SpeechFailure(SpeechAvailability.fromWire(asNullableString(json['reason']))),
      _ => null,
    };
