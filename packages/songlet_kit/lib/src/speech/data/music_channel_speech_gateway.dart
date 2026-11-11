import 'dart:async';

import 'package:flutter/services.dart';

import '../../common/json.dart';
import '../domain/music_speech_gateway.dart';

/// [MusicSpeechGateway] over `songlet/speech` (methods) and `songlet/speech/events`
/// (partial / level / final / error maps) — SpeechService.swift.
class MusicChannelSpeechGateway implements MusicSpeechGateway {
  const MusicChannelSpeechGateway({
    MethodChannel methods = const MethodChannel('songlet/speech'),
    EventChannel events = const EventChannel('songlet/speech/events'),
  })  : _methods = methods,
        _events = events;

  final MethodChannel _methods;
  final EventChannel _events;

  @override
  Future<MusicSpeechAvailability> availability(String locale) async {
    try {
      final result = await _methods.invokeMethod<String>('availability', {'locale': locale});
      return MusicSpeechAvailability.fromWire(result);
    } on PlatformException {
      return MusicSpeechAvailability.unavailable;
    } on MissingPluginException {
      return MusicSpeechAvailability.unavailable;
    }
  }

  @override
  Stream<MusicSpeechEvent> start(String locale) {
    late final StreamController<MusicSpeechEvent> controller;
    StreamSubscription<Object?>? subscription;
    controller = StreamController<MusicSpeechEvent>(
      onListen: () {
        subscription = _events.receiveBroadcastStream({'locale': locale}).listen(
          (raw) {
            final event = decodeSpeechEvent(asMap(raw));
            if (event == null) return;
            controller.add(event);
            if (event is MusicSpeechFinal || event is MusicSpeechFailure) {
              subscription?.cancel();
              controller.close();
            }
          },
          onError: (Object error) {
            controller
              ..add(MusicSpeechFailure(
                error is PlatformException
                    ? MusicSpeechAvailability.fromWire(error.code)
                    : MusicSpeechAvailability.unavailable,
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
MusicSpeechEvent? decodeSpeechEvent(Map<String, Object?> json) => switch (asString(json['type'])) {
      'partial' => MusicSpeechPartial(asString(json['text'])),
      'level' => MusicSpeechLevel(asDouble(json['level']).clamp(0, 1).toDouble()),
      'final' => MusicSpeechFinal(asString(json['text'])),
      'error' => MusicSpeechFailure(MusicSpeechAvailability.fromWire(asNullableString(json['reason']))),
      _ => null,
    };
