import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';

import 'support/fixture.dart';

void main() {
  late Encoding encoding;
  late Map<String, DeviceSlot> slots;
  late FixtureRepo repo;
  late PreviewScript script;

  setUpAll(() async {
    final pkg = await packageRoot();
    encoding = loadEncoding(pkg);
    slots = loadSlots(pkg);
  });
  setUp(() {
    repo = FixtureRepo.create();
    script = loadScripts(repo.path('store_preview/demo/scripts'))['A']!;
  });
  tearDown(() => repo.delete());

  /// name 1.0–5.0 s (4 s for a 3.5 s slot), wait 5.0–6.5, player 6.5–12.5
  /// (real time, at 30 s of the song), share 12.5–15.5.
  Take take() => parseTake(
    recLog: '1000 Recording started\n',
    testLog: [
      for (final (scene, from, to, pos) in [('name', 2000, 6000, null), ('wait', 6000, 7500, null), ('player', 7500, 13500, 30.0), ('share', 13500, 16500, null)]) ...[
        '$markTag{"t":$from,"script":"A","scene":"$scene","edge":"start"${pos == null ? '' : ',"pos":$pos'}}',
        '$markTag{"t":$to,"script":"A","scene":"$scene","edge":"end"}',
      ],
    ].join('\n'),
  );

  group('native tools', () {
    test('builders running at once each write their own file; one binary per helper stays', () async {
      final pkg = await packageRoot();
      final bin = Directory.systemTemp.createTempSync('native_tools');
      addTearDown(() => bin.deleteSync(recursive: true));
      final runner = _ExclusiveSwiftc();
      final built = await Future.wait([
        for (var i = 0; i < 3; i++) NativeTools.ensure(runner, packageRoot: pkg, binDir: bin.path),
      ]);
      expect(runner.outputs.toSet(), hasLength(runner.outputs.length), reason: 'no two builds write the same file');
      expect(built.map((t) => t.cutter).toSet(), {p.join(bin.path, 'cut_scenes')});
      expect(bin.listSync().map((f) => p.basename(f.path)).toSet(), {'cut_scenes', 'cut_scenes.sha256', 'render_text', 'render_text.sha256'},
          reason: 'no build leaves its own file behind');

      runner.outputs.clear();
      await NativeTools.ensure(runner, packageRoot: pkg, binDir: bin.path);
      expect(runner.outputs, isEmpty, reason: 'the stamp matches the source: nothing to build');
    });
  });

  group('cuts', () {
    test('the clip is frame exact; cards and the bridge hold the neighbouring frames', () {
      final cuts = timelineCuts(script, take(), fps: 30);
      final frames = cuts.cuts.fold<int>(0, (n, c) => n + c.frames);
      expect(frames, 15 * 30);
      // intro: the first frame of "name", held 0.8 s.
      expect(cuts.cuts.first.from, 1.0);
      expect(cuts.cuts.first.frames, 24);
      // "name": 4 s filmed into 3.5 s.
      expect(cuts.cuts[1].from, 1.0);
      expect(cuts.cuts[1].to, 5.0);
      expect(cuts.sources['name']!.speed, closeTo(4 / 3.5, 1e-9));
      // the follow scene runs in real time from its mark.
      expect(cuts.sources['player']!.from, 6.5);
      expect(cuts.sources['player']!.to, closeTo(12.0, 1e-9));
      // outro: the last frame of "share".
      expect(cuts.cuts.last.from, closeTo(15.5 - 1 / 30, 1e-9));
      expect(cuts.cuts.last.frames, 42);
    });

    test('footage filmed too short or too long for its slot is refused', () {
      final short = parseTake(
        recLog: '1000 Recording started\n',
        testLog: '$markTag{"t":2000,"script":"A","scene":"name","edge":"start"}\n$markTag{"t":3000,"script":"A","scene":"name","edge":"end"}',
      );
      expect(() => timelineCuts(script, short, fps: 30), throwsA(isA<ConfigError>().having((e) => e.message, 'm', contains('adjust the script'))));
    });
  });

  group('soundtrack', () {
    test('one source pinned to the scene that follows it plays from 0', () {
      final cues = audioCues([(start: 5.5, file: 'song.mp3', offset: 24.5)], 15);
      expect(cues.single.from, 0);
      expect(cues.single.to, 15);
      final graph = soundtrackGraph(cues: cues, inputOf: (_) => 3, encoding: encoding, duration: 15);
      expect(graph.first, startsWith('[3:a]atrim=start=24.5000:end=39.5000'));
      expect(graph.last, contains('afade=t=out:st=14.0000:d=1.0'));
      expect(graph.last, endsWith('[aout]'));
    });

    test('a voiceover ducks the music; no music gives a silent track', () {
      final ducked = soundtrackGraph(
        cues: [const AudioCue(file: 'm', offset: 0, from: 0, to: 15)],
        inputOf: (_) => 1,
        encoding: encoding,
        duration: 15,
        voiceover: 2,
      );
      expect(ducked.join(';'), contains('[music][key]sidechaincompress=threshold=0.03:ratio=8.0'));
      expect(ducked.last, startsWith('[ducked][vo]amix=inputs=2'));
      final silent = soundtrackGraph(cues: const [], inputOf: (_) => 0, encoding: encoding, duration: 15, silent: 4);
      expect(silent.first, startsWith('[4:a]aformat=sample_rates=44100:channel_layouts=stereo,atrim=duration=15.0000'));
    });
  });

  group('graph', () {
    RenderPlan plan({List<AudioCue> audio = const []}) => RenderPlan(
      clip: 'timeline.mov',
      sourceWidth: 1320,
      sourceHeight: 2868,
      slot: slots['iphone']!,
      duration: 15,
      encoding: encoding,
      cards: const [
        CardLayer(kind: 'intro', start: 0, end: 0.8, foreground: 'intro.png', backdrop: ImageBackdrop('photo.png')),
        CardLayer(kind: 'outro', start: 13.6, end: 15, foreground: 'outro.png', backdrop: FootageBackdrop()),
      ],
      bridges: const [BridgeLayer(start: 5.25, end: 5.75, image: 'photo2.png')],
      captions: const [CaptionLayer(png: 'c0.png', from: 0.8, to: 4.3)],
      audio: audio,
      voiceover: null,
      out: 'A.mp4',
    );

    test('downscales the native footage to the slot (never enlarges)', () {
      final p = plan();
      // Cover: the width binds (886 / 1320 > 1920 / 2868); the height's
      // excess is cropped.
      expect(p.scale, closeTo(886 / 1320, 1e-9));
      expect(p.scale, lessThan(1));
      final args = ffmpegArgs(p).join(' ');
      expect(args, contains('[0:v]fps=30,scale=886:1926:flags=lanczos,crop=886:1920'));
    });

    test('cards, the bridge and motion captions are composited with dissolves and fades', () {
      final args = ffmpegArgs(plan(audio: const [AudioCue(file: 'song.mp3', offset: 24.5, from: 0, to: 15)]));
      final graph = args[args.indexOf('-filter_complex') + 1];
      expect(graph, contains('split=2[base][fb0]'));
      expect(graph, contains("zoompan=z='1+0.060*on/24'"));
      expect(graph, contains('fade=t=out:st=0.5500:d=0.25:alpha=1'));
      expect(graph, contains('[fb0]trim=start=13.6000:end=15.0000'));
      expect(graph, contains('fade=t=in:st=0:d=0.25:alpha=1'));
      expect(graph, contains('fade=t=in:st=0:d=0.2:alpha=1,fade=t=out:st=0.3000:d=0.2:alpha=1,setpts=PTS-STARTPTS+5.2500/TB[br0]'));
      expect(graph, contains("y='H-h-168+24.0*pow(max(0,1-(t-0.8000)/0.2),2)'"));
      expect(graph, contains('[vt0]trim=duration=15.0000,format=yuv420p[vout]'));
      expect(args, containsAllInOrder(['-loop', '1', '-framerate', '30', '-t', '0.8000', '-i', 'photo.png']));
      expect(args, containsAllInOrder(['-c:v', 'libx264', '-profile:v', 'high', '-level:v', '4.0']));
      expect(args, containsAllInOrder(['-b:v', '11000000', '-minrate', '11000000', '-maxrate', '11000000']));
      expect(args, containsAllInOrder(['-c:a', 'aac_at', '-aac_at_mode', 'cbr', '-b:a', '256000']));
    });

    test('no music: a silent stereo input', () {
      final args = ffmpegArgs(plan());
      expect(args, containsAllInOrder(['-f', 'lavfi', '-t', '15.0000', '-i', 'anullsrc=r=44100:cl=stereo']));
    });
  });

  group('caption plates', () {
    test('brighter footage, darker plate, inside the app\'s range', () {
      final app = PreviewApp.load(root: repo.root, id: 'demo', slots: slots);
      expect(plateOpacity(16, app.captions), closeTo(0.45, 1e-9));
      expect(plateOpacity(235, app.captions), closeTo(0.78, 1e-9));
      expect(plateOpacity(300, app.captions), closeTo(0.78, 1e-9));
    });

    test('the band maps the slot\'s caption area back onto the native footage', () {
      final band = captionBand(sourceWidth: 1320, sourceHeight: 2868, slot: slots['iphone']!);
      const scale = 886 / 1320;
      expect(band.h, (44 * 2.6 / scale).round());
      expect(band.y + band.h, closeTo((1920 - 168 + (2868 * scale - 1920) / 2) / scale, 2));
    });
  });

  group('edl', () {
    test('footage share, kinds and round trip', () {
      const edl = Edl(
        app: 'demo',
        script: 'A',
        storefront: 'en-US',
        slot: 'iphone',
        duration: 15,
        posterAt: 8,
        footageScale: 0.67,
        segments: [
          EdlSegment(kind: 'card', id: 'intro', beat: 'intro', from: 0, to: 0.8),
          EdlSegment(kind: 'footage', id: 'name', beat: 'input', from: 0.8, to: 13.6),
          EdlSegment(kind: 'card', id: 'outro', beat: 'outro', from: 13.6, to: 15),
        ],
        transitions: [EdlTransition(at: 0.8, type: 'dissolve', duration: 0.25, between: 'intro→name')],
        texts: [EdlText(source: 'claim', key: 'k', text: 't', from: 0, to: 0.8)],
        media: [EdlMedia(id: 'photo.A.en-US.1', role: 'photo', use: 'card', license: {'id': 'gen-1'})],
      );
      expect(edl.footageRatio, closeTo(12.8 / 15, 1e-9));
      final again = Edl.fromJson(edl.toJson());
      expect(again.secondsOf('card'), closeTo(2.2, 1e-9));
      expect(again.media.single.license['id'], 'gen-1');
      expect(again.transitions.single.type, 'dissolve');
    });
  });
}

/// `swiftc` as the linker behaves: it creates its output exclusively and
/// fails when the file exists (`ld: open() failed, errno=17 (File exists)`),
/// after the time a compile takes — so builders sharing an output collide.
class _ExclusiveSwiftc implements ProcessRunner {
  final List<String> outputs = [];

  @override
  Future<ProcessOutcome> run(String executable, List<String> args, {String? workingDirectory, Map<String, String>? environment, bool check = true}) async {
    final out = args[args.indexOf('-o') + 1];
    outputs.add(out);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final file = File(out);
    if (file.existsSync()) throw ToolError('ld: open() failed, errno=17 (File exists) for $out');
    file.writeAsStringSync('binary of ${args[1]}');
    return const ProcessOutcome(0, '', '');
  }

  @override
  Future<RunningProcess> start(String executable, List<String> args,
          {required String logFile, String? workingDirectory, Map<String, String>? environment, bool stampLines = false}) =>
      throw UnsupportedError('start');

  @override
  Future<void> sleep(Duration duration) async {}

  @override
  int now() => 0;
}
