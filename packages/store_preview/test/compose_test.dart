import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';

import 'support/fixture.dart';

/// The real composer — native tools, ffmpeg — on synthetic footage: the
/// output meets Apple's spec and carries the cards, bridge, captions and
/// soundtrack the script asks for. Needs macOS with Xcode and ffmpeg
/// (AudioToolbox AAC); skipped elsewhere.
void main() {
  final tools = Process.runSync('which', ['ffmpeg', 'swiftc']).stdout.toString().trim().split('\n').length == 2 &&
      Process.runSync('ffmpeg', ['-hide_banner', '-encoders']).stdout.toString().contains('aac_at');

  late String pkg;
  late FixtureRepo repo;

  setUpAll(() async => pkg = await packageRoot());
  setUp(() => repo = FixtureRepo.create());
  tearDown(() => repo.delete());

  Future<void> ff(List<String> args) async {
    final r = await Process.run('ffmpeg', ['-v', 'error', '-y', ...args]);
    if (r.exitCode != 0) fail('ffmpeg ${args.join(' ')}: ${r.stderr}');
  }

  /// A 17 s recording at the iPhone 17 Pro Max's native size, a 60 s song,
  /// two photos and an icon; scene marks as the driver prints them.
  Future<TakeFiles> synthesize() async {
    final take = TakeFiles(repo.path('build/take'));
    Directory(take.dir).createSync(recursive: true);
    await ff(['-f', 'lavfi', '-i', 'testsrc2=s=1320x2868:r=30:d=17', '-c:v', 'libx264', '-preset', 'ultrafast', '-pix_fmt', 'yuv420p', take.recording]);
    File(take.recLog).writeAsStringSync('1000 Recording started\n');
    File(take.driverLog).writeAsStringSync([
      for (final (scene, from, to, pos) in [('name', 2000, 6000, null), ('wait', 6000, 7500, null), ('player', 7500, 13500, 30.0), ('share', 13500, 16500, null)]) ...[
        '$markTag{"t":$from,"script":"A","scene":"$scene","edge":"start"${pos == null ? '' : ',"pos":$pos'}}',
        '$markTag{"t":$to,"script":"A","scene":"$scene","edge":"end"}',
      ],
      '$markTag{"t":17000,"edge":"done"}',
    ].join('\n'));
    repo.manifest(completeManifest());
    final media = repo.path('store_preview/demo/media');
    for (final l in ['en-US', 'ja']) {
      await ff(['-f', 'lavfi', '-i', 'sine=f=440:d=60', '-ac', '2', '-c:a', 'libmp3lame', '-b:a', '192k', '$media/audio/song.A.$l.mp3']);
      for (final i in [1, 2]) {
        await ff(['-f', 'lavfi', '-i', 'testsrc=s=1024x1365:d=1', '-frames:v', '1', '$media/image/photo.A.$l.$i.png']);
      }
    }
    await ff(['-f', 'lavfi', '-i', 'color=c=0xD9482B:s=1024x1024:d=1', '-frames:v', '1', repo.path('assets/icon.png')]);
    return take;
  }

  test('a composed preview meets the spec and records what it shows', () async {
    final slots = loadSlots(pkg);
    final app = PreviewApp.load(root: repo.root, id: 'demo', slots: slots);
    final encoding = loadEncoding(pkg);
    final take = await synthesize();
    final runner = const SystemProcessRunner();
    final native = await NativeTools.ensure(runner, packageRoot: pkg, binDir: p.join(pkg, '.dart_tool', 'store_preview_test_bin'));
    final script = loadScripts(app.scriptsDir)['A']!;
    final composer = Composer(runner: runner, app: app, manifest: Manifest.load(app.manifestPath), encoding: encoding, tools: native, root: repo.root);
    final out = await composer.compose(
      script: script,
      storefront: app.storefront('en-US'),
      slot: slots['iphone']!,
      take: take,
      texts: captionsFromArb(repo.root, app, app.storefront('en-US')),
      distDir: repo.path('dist/demo'),
    );

    final info = const FfprobeProber().probe(out.video)!;
    expect(info.video!.width, 886);
    expect(info.video!.height, 1920);
    expect(info.duration, closeTo(15, 0.1));
    expect(info.video!.codec, 'h264');
    expect(info.video!.profile, 'High');
    expect(info.video!.level, 40);
    expect(info.video!.frameRate, closeTo(30, 0.01));
    expect(info.video!.bitRate, inInclusiveRange(10000000, 12000000));
    expect(info.audio!.codec, 'aac');
    expect(info.audio!.channels, 2);
    expect((info.audio!.bitRate - 256000).abs(), lessThan(256000 * 0.05));
    expect(const FfprobeProber().probe(out.poster)!.video!.width, 886);

    final edl = Edl.load(out.edl);
    expect(edl.footageRatio, closeTo(12.8 / 15, 1e-6));
    expect(edl.segments.map((s) => s.kind), ['card', 'footage', 'footage', 'footage', 'footage', 'card']);
    expect(edl.transitions.map((t) => t.type).toSet(), {'dissolve', 'cut'});
    expect(edl.texts.map((t) => t.source), containsAll(['claim', 'caption', 'brand', 'cta', 'disclosure']));
    expect(edl.media.map((m) => '${m.id}:${m.use}'), ['photo.A.en-US.1:card', 'song.A.en-US:soundtrack']);
    expect(edl.footageScale, lessThan(1));
    final srtText = File(out.captions).readAsStringSync();
    expect(srtText, contains('A song with their name'));
    expect(srtText, contains('Requires a subscription or credits'));
    _keep(out, 'compose-A');
  }, skip: tools ? false : 'needs macOS with Xcode and ffmpeg (aac_at)', timeout: const Timeout(Duration(minutes: 5)));

  test('a bridge through a licensed image, a footage-backed outro and a silent track', () async {
    repo.write(
      'store_preview/demo/scripts/A.yaml',
      fixtureScriptA
          .replaceFirst('title: A song for them', 'title: A song for them\nsoundtrack: none')
          .replaceFirst('    duration: 1.2\n', '    duration: 0.7\n')
          .replaceFirst('  - scene: player', '  - bridge: toResult\n    duration: 0.5\n    image: {role: photo, index: 1}\n  - scene: player')
          .replaceFirst('    audio: {role: song}\n', '')
          .replaceFirst('    duration: 1.4\n', '    duration: 1.4\n    background: {footage: true}\n'),
    );
    final slots = loadSlots(pkg);
    final app = PreviewApp.load(root: repo.root, id: 'demo', slots: slots);
    final take = await synthesize();
    final runner = const SystemProcessRunner();
    final native = await NativeTools.ensure(runner, packageRoot: pkg, binDir: p.join(pkg, '.dart_tool', 'store_preview_test_bin'));
    final script = loadScripts(app.scriptsDir)['A']!;
    expect(script.bridges.single.start, closeTo(5.0, 1e-9));
    final composer = Composer(runner: runner, app: app, manifest: Manifest.load(app.manifestPath), encoding: loadEncoding(pkg), tools: native, root: repo.root);
    final out = await composer.compose(
      script: script,
      storefront: app.storefront('ja'),
      slot: slots['iphone']!,
      take: take,
      texts: captionsFromArb(repo.root, app, app.storefront('ja')),
      distDir: repo.path('dist/demo'),
    );
    final info = const FfprobeProber().probe(out.video)!;
    expect(info.duration, closeTo(15, 0.1));
    expect((info.audio!.bitRate - 256000).abs(), lessThan(256000 * 0.05));
    final edl = Edl.load(out.edl);
    expect(edl.segments.map((s) => s.kind), ['card', 'footage', 'footage', 'bridge', 'footage', 'footage', 'card']);
    expect(edl.segments.last.detail['background'], 'footage');
    expect(edl.media.map((m) => '${m.id}:${m.use}'), ['photo.A.ja.1:card', 'photo.A.ja.2:bridge']);
    expect(edl.transitions.where((t) => t.between.contains('toResult')).map((t) => t.type), ['dissolve', 'dissolve']);
    _keep(out, 'compose-B');
  }, skip: tools ? false : 'needs macOS with Xcode and ffmpeg (aac_at)', timeout: const Timeout(Duration(minutes: 5)));
}

/// Keeps a rendered preview for a look (`STORE_PREVIEW_KEEP=<dir>`).
void _keep(PreviewFiles out, String name) {
  final dir = Platform.environment['STORE_PREVIEW_KEEP'];
  if (dir == null) return;
  Directory(dir).createSync(recursive: true);
  File(out.video).copySync(p.join(dir, '$name.mp4'));
}
