import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

/// Records `play` calls; progress is pushed by the test like the native
/// `onPlaybackProgress` callback.
class FakeAudioEngine implements AudioEngine {
  final StreamController<double> _progress = StreamController<double>.broadcast();
  final List<(String, bool)> plays = [];

  void emit(double value) => _progress.add(value);

  Future<void> close() => _progress.close();

  @override
  Future<void> play(String path, {required bool loop}) async => plays.add((path, loop));

  final List<double> seeks = [];

  @override
  Future<void> seek(double seconds) async => seeks.add(seconds);

  @override
  Stream<double> get progress => _progress.stream;
}

void main() {
  late FakeAudioEngine engine;
  late ProviderContainer container;

  setUp(() {
    engine = FakeAudioEngine();
    container = ProviderContainer(
      overrides: [audioEngineProvider.overrideWithValue(engine)],
    );
    container.listen(playerControllerProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await engine.close();
  });

  PlaybackState state() => container.read(playerControllerProvider);
  PlayerController controller() => container.read(playerControllerProvider.notifier);

  Future<void> emit(double value) async {
    engine.emit(value);
    await pumpEventQueue();
  }

  test('starts idle', () {
    expect(state().path, isNull);
    expect(state().isPlaying, isFalse);
    expect(state().position, 0);
    expect(state().completedCount, 0);
  });

  test('toggle on a new track plays it from 0 and is optimistically playing', () async {
    await controller().toggle('/a.mp3');

    expect(engine.plays, [('/a.mp3', false)]);
    expect(state().path, '/a.mp3');
    expect(state().isCurrent('/a.mp3'), isTrue);
    expect(state().isPlaying, isTrue);
    expect(state().position, 0);
  });

  test('toggle on the loaded track forwards to the engine (native toggles)', () async {
    await controller().toggle('/a.mp3');
    await emit(4.5);

    await controller().toggle('/a.mp3');

    expect(engine.plays, [('/a.mp3', false), ('/a.mp3', false)]);
    expect(state().position, 4.5, reason: 'no restart on the loaded track');
  });

  test('switching tracks resets the position', () async {
    await controller().toggle('/a.mp3');
    await emit(12);

    await controller().toggle('/b.mp3');

    expect(state().path, '/b.mp3');
    expect(state().position, 0);
    expect(state().isPlaying, isTrue);
    expect(engine.plays.last, ('/b.mp3', false));
  });

  test('progress events update the position and mark playing', () async {
    await controller().toggle('/a.mp3');
    await emit(-1);
    expect(state().isPlaying, isFalse);

    await emit(1.25);
    expect(state().position, 1.25);
    expect(state().isPlaying, isTrue);

    await emit(2.5);
    expect(state().position, 2.5);
  });

  test('-1 pauses and keeps the position', () async {
    await controller().toggle('/a.mp3');
    await emit(7);

    await emit(AudioEngine.paused);

    expect(state().isPlaying, isFalse);
    expect(state().position, 7);
    expect(state().path, '/a.mp3');
  });

  test('-2 (ended) increments completedCount and resets the position', () async {
    await controller().toggle('/a.mp3');
    await emit(29.9);

    await emit(AudioEngine.ended);

    expect(state().completedCount, 1);
    expect(state().position, 0);
    expect(state().isPlaying, isFalse);
    expect(state().path, '/a.mp3', reason: 'the track stays loaded');

    await controller().toggle('/a.mp3');
    await emit(AudioEngine.ended);
    expect(state().completedCount, 2);
  });

  test('an ended event with nothing loaded does not count', () async {
    await emit(AudioEngine.ended);
    expect(state().completedCount, 0);
  });

  test('lock-screen play (progress with no tap) is reflected', () async {
    await controller().toggle('/a.mp3');
    await emit(AudioEngine.paused);
    await emit(3);
    expect(state().isPlaying, isTrue);
  });

  test('setLoop forwards to the engine without restarting', () async {
    await controller().toggle('/a.mp3');
    await emit(8);

    await controller().setLoop(loop: true);

    expect(engine.plays.last, ('/a.mp3', true));
    expect(state().loop, isTrue);
    expect(state().position, 8);
    expect(state().isPlaying, isTrue);
    expect(state().path, '/a.mp3');

    await controller().toggle('/a.mp3');
    expect(engine.plays.last, ('/a.mp3', true), reason: 'toggle keeps the loop flag');
  });

  test(
    'setLoop with the unchanged value sends nothing to the engine',
    () async {
      await controller().toggle('/a.mp3');
      await emit(8);

      // Native contract (AudioPlaybackService.play): the loaded path with the
      // SAME loop flag toggles pause/resume. A no-op setLoop must not send it.
      await controller().setLoop(loop: false);

      expect(engine.plays, [('/a.mp3', false)]);
    },
  );

  test('setLoop with nothing loaded only remembers the flag', () async {
    await controller().setLoop(loop: true);

    expect(engine.plays, isEmpty);
    expect(state().loop, isTrue);

    await controller().toggle('/a.mp3');
    expect(engine.plays.single, ('/a.mp3', true));
  });

  test('stop clears the track and stops the engine', () async {
    await controller().toggle('/a.mp3');
    await emit(5);

    await controller().stop();

    expect(engine.plays.last, ('', false));
    expect(state().path, isNull);
    expect(state().isPlaying, isFalse);
    expect(state().position, 0);
  });

  test('stop with nothing loaded does nothing', () async {
    await controller().stop();
    expect(engine.plays, isEmpty);
  });

  test('disposing the container stops listening to progress', () async {
    await controller().toggle('/a.mp3');
    container.dispose();
    engine.emit(3);
    await pumpEventQueue();
    // A fresh container starts idle and is unaffected by the old stream.
    container = ProviderContainer(
      overrides: [audioEngineProvider.overrideWithValue(engine)],
    );
    expect(container.read(playerControllerProvider).path, isNull);
  });

  group('sections', () {
    const sections = [
      (start: 0.0, end: 10.0),
      (start: 10.0, end: 40.0),
      (start: 40.0, end: 70.0),
      (start: 70.0, end: 90.0),
    ];

    test('seek moves the loaded track and the state', () async {
      await controller().toggle('/a.mp3');
      await controller().seek(33);
      expect(engine.seeks, [33]);
      expect(state().position, 33);
    });

    test('next / previous section follow the structure; previous restarts past 3 s', () async {
      await controller().toggle('/a.mp3');
      controller().setSections(sections);
      await emit(12);
      expect(controller().currentSection, 1);
      await controller().jumpSection(1);
      expect(engine.seeks.last, 40);
      await emit(45);
      await controller().jumpSection(-1);
      expect(engine.seeks.last, 40, reason: '5 s in → restart the section');
      await emit(41);
      await controller().jumpSection(-1);
      expect(engine.seeks.last, 10);
    });

    test('shuffle plays every section once, in a shuffled order', () async {
      await controller().toggle('/a.mp3');
      controller()
        ..setSections(sections)
        ..setShuffle(shuffle: true, seed: 7);
      expect(state().shuffle, isTrue);
      final visited = <double>{};
      for (var i = 0; i < sections.length; i++) {
        await controller().jumpSection(1);
        visited.add(engine.seeks.last);
      }
      expect(visited, {0, 10, 40, 70});
    });

    test('in shuffle mode the end of a section jumps along the order', () async {
      await controller().toggle('/a.mp3');
      controller()
        ..setSections(sections)
        ..setShuffle(shuffle: true, seed: 3);
      await emit(5);
      final before = engine.seeks.length;
      await emit(10.2);
      expect(engine.seeks.length, before + 1);
      expect(sections.map((s) => s.start), contains(engine.seeks.last));
    });

    test('a new track clears sections and shuffle', () async {
      await controller().toggle('/a.mp3');
      controller()
        ..setSections(sections)
        ..setShuffle(shuffle: true);
      await controller().toggle('/b.mp3');
      expect(state().shuffle, isFalse);
      expect(controller().currentSection, -1);
    });
  });
}
