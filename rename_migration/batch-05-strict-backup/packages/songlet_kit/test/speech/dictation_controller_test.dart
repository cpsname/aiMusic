import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/speech/data/channel_speech_gateway.dart';

class FakeSpeechGateway implements SpeechGateway {
  FakeSpeechGateway({this.available = SpeechAvailability.available});

  final SpeechAvailability available;
  StreamController<SpeechEvent>? session;
  var stopped = 0;
  var cancelled = 0;

  @override
  Future<SpeechAvailability> availability(String locale) async => available;

  @override
  Stream<SpeechEvent> start(String locale) {
    session = StreamController<SpeechEvent>();
    return session!.stream;
  }

  @override
  Future<void> stop() async {
    stopped++;
    session?.add(const SpeechFinal('coffee and hiking'));
    await session?.close();
  }

  @override
  Future<void> cancel() async => cancelled++;
}

void main() {
  late FakeSpeechGateway gateway;
  late ProviderContainer container;

  ProviderContainer make(FakeSpeechGateway g) {
    gateway = g;
    return ProviderContainer(overrides: [speechGatewayProvider.overrideWithValue(g)]);
  }

  tearDown(() => container.dispose());

  test('records partials and levels, then delivers the final transcript', () async {
    container = make(FakeSpeechGateway());
    final dictation = container.read(dictationProvider.notifier);
    await dictation.start('en-US');
    gateway.session!
      ..add(const SpeechLevel(0.4))
      ..add(const SpeechPartial('coffee'))
      ..add(const SpeechLevel(0.9));
    await pumpEventQueue();
    final recording = container.read(dictationProvider) as DictationRecording;
    expect(recording.transcript, 'coffee');
    expect(recording.levels, [0.4, 0.9]);

    await dictation.stop();
    await pumpEventQueue();
    final done = container.read(dictationProvider) as DictationRecording;
    expect(done.finished, isTrue);
    expect(done.transcript, 'coffee and hiking');
    expect(gateway.stopped, 1);
  });

  test('keeps only the last 48 level samples', () async {
    container = make(FakeSpeechGateway());
    await container.read(dictationProvider.notifier).start('en-US');
    for (var i = 0; i < 60; i++) {
      gateway.session!.add(SpeechLevel(i / 60));
    }
    await pumpEventQueue();
    final levels = (container.read(dictationProvider) as DictationRecording).levels;
    expect(levels, hasLength(DictationController.levelHistory));
    expect(levels.last, closeTo(59 / 60, 1e-9));
  });

  test('denied permission or unsupported locale never records', () async {
    for (final reason in [SpeechAvailability.denied, SpeechAvailability.unsupportedLocale]) {
      container = make(FakeSpeechGateway(available: reason));
      await container.read(dictationProvider.notifier).start('en-US');
      expect(container.read(dictationProvider), isA<DictationUnavailable>());
      expect(gateway.session, isNull);
      container.dispose();
    }
    container = make(FakeSpeechGateway());
  });

  test('a mid-session failure ends in unavailable; cancel returns to idle', () async {
    container = make(FakeSpeechGateway());
    final dictation = container.read(dictationProvider.notifier);
    await dictation.start('en-US');
    gateway.session!.add(const SpeechFailure(SpeechAvailability.unavailable));
    await pumpEventQueue();
    expect(container.read(dictationProvider), isA<DictationUnavailable>());
    await dictation.cancel();
    expect(container.read(dictationProvider), isA<DictationIdle>());
  });

  test('decodes channel payloads', () {
    expect(decodeSpeechEvent({'type': 'partial', 'text': 'hi'}), isA<SpeechPartial>());
    expect((decodeSpeechEvent({'type': 'level', 'level': 3}) as SpeechLevel).level, 1);
    expect((decodeSpeechEvent({'type': 'error', 'reason': 'denied'}) as SpeechFailure).reason, SpeechAvailability.denied);
    expect(decodeSpeechEvent({'type': 'mystery'}), isNull);
  });
}
