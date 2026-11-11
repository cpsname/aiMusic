import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/speech/data/channel_music_speech_gateway.dart';

class FakeSpeechGateway implements MusicSpeechGateway {
  FakeSpeechGateway({this.available = MusicSpeechAvailability.available});

  final MusicSpeechAvailability available;
  StreamController<MusicSpeechEvent>? session;
  var stopped = 0;
  var cancelled = 0;

  @override
  Future<MusicSpeechAvailability> availability(String locale) async => available;

  @override
  Stream<MusicSpeechEvent> start(String locale) {
    session = StreamController<MusicSpeechEvent>();
    return session!.stream;
  }

  @override
  Future<void> stop() async {
    stopped++;
    session?.add(const MusicSpeechFinal('coffee and hiking'));
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
      ..add(const MusicSpeechLevel(0.4))
      ..add(const MusicSpeechPartial('coffee'))
      ..add(const MusicSpeechLevel(0.9));
    await pumpEventQueue();
    final recording = container.read(dictationProvider) as MusicDictationRecording;
    expect(recording.transcript, 'coffee');
    expect(recording.levels, [0.4, 0.9]);

    await dictation.stop();
    await pumpEventQueue();
    final done = container.read(dictationProvider) as MusicDictationRecording;
    expect(done.finished, isTrue);
    expect(done.transcript, 'coffee and hiking');
    expect(gateway.stopped, 1);
  });

  test('keeps only the last 48 level samples', () async {
    container = make(FakeSpeechGateway());
    await container.read(dictationProvider.notifier).start('en-US');
    for (var i = 0; i < 60; i++) {
      gateway.session!.add(MusicSpeechLevel(i / 60));
    }
    await pumpEventQueue();
    final levels = (container.read(dictationProvider) as MusicDictationRecording).levels;
    expect(levels, hasLength(MusicDictationController.levelHistory));
    expect(levels.last, closeTo(59 / 60, 1e-9));
  });

  test('denied permission or unsupported locale never records', () async {
    for (final reason in [MusicSpeechAvailability.denied, MusicSpeechAvailability.unsupportedLocale]) {
      container = make(FakeSpeechGateway(available: reason));
      await container.read(dictationProvider.notifier).start('en-US');
      expect(container.read(dictationProvider), isA<MusicDictationUnavailable>());
      expect(gateway.session, isNull);
      container.dispose();
    }
    container = make(FakeSpeechGateway());
  });

  test('a mid-session failure ends in unavailable; cancel returns to idle', () async {
    container = make(FakeSpeechGateway());
    final dictation = container.read(dictationProvider.notifier);
    await dictation.start('en-US');
    gateway.session!.add(const MusicSpeechFailure(MusicSpeechAvailability.unavailable));
    await pumpEventQueue();
    expect(container.read(dictationProvider), isA<MusicDictationUnavailable>());
    await dictation.cancel();
    expect(container.read(dictationProvider), isA<MusicDictationIdle>());
  });

  test('decodes channel payloads', () {
    expect(decodeSpeechEvent({'type': 'partial', 'text': 'hi'}), isA<MusicSpeechPartial>());
    expect((decodeSpeechEvent({'type': 'level', 'level': 3}) as MusicSpeechLevel).level, 1);
    expect((decodeSpeechEvent({'type': 'error', 'reason': 'denied'}) as MusicSpeechFailure).reason, MusicSpeechAvailability.denied);
    expect(decodeSpeechEvent({'type': 'mystery'}), isNull);
  });
}
