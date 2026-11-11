import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';

import 'fixture.dart';

/// The ascpub checkout the tests read the assets-manifest contract from:
/// `$ASCPUB_ROOT`, else the workspace layout this template is developed in
/// (`<workspace>/Tools/ASOShip`, beside `<workspace>/GenAIStudio/<repo>`). The
/// contract is ascpub's and is never copied here (template ADR-0010): without
/// a checkout these tests fail and say where to point them.
String testAscpubRoot(String packageRoot) {
  final env = Platform.environment[ascpubRootVariable];
  final root = env != null && env.trim().isNotEmpty ? p.absolute(env.trim()) : p.normalize(p.join(packageRoot, '..', '..', '..', '..', 'Tools', 'ASOShip'));
  if (!File(p.join(root, contractSourceDir, contractSchemaFile)).existsSync()) {
    throw StateError('no ascpub checkout at $root: set \$$ascpubRootVariable to the ascpub repository (its $contractSourceDir holds the contract)');
  }
  return root;
}

/// The SHA-256 of the contract in the ascpub checkout at [root].
String contractSha(String root) => sha256.convert(File(p.join(root, contractSourceDir, contractSchemaFile)).readAsBytesSync()).toString();

/// The fixture app with creative assets: the ascpub checkout and its pin,
/// the authorization map, a capture script W, and a definition with a
/// universal 16:9 image, a 21:9 header image and loop video (footage from two
/// takes: A's player, W's hold), and a 3:2 search image.
String creativeAppYaml(String packageRoot, {String? listing, String? layouts}) {
  final root = testAscpubRoot(packageRoot);
  return '''
$fixtureAppYaml
creatives:
  ascpub: {root: "$root", schema_sha256: ${contractSha(root)}${listing == null ? '' : ', listing: $listing'}}
  authorization: {song: interaction_id, photo: generation_id}
${layouts ?? ''}''';
}

const String fixtureScriptW = '''
id: W
kind: capture
title: A held screen
setup:
  - {do: newDraft}
segments:
  - scene: hold
    duration: 6
    shows: [{role: photo, script: A, index: 1}]
    steps: [{do: pause, ms: 6000}]
''';

const String fixtureCreative = '''
id: page
title: The default product page
targets: [app_store_version]
universal_from: en-US
backdrop: {role: photo, script: A, index: 0}
tags: ["page:default"]
slots:
  - placements: [product_page_header, app_store_search_results]
    spec: universal_16x9
    assets:
      - {id: header.universal, type: image, frame: {script: A, scene: player, at: 1.0}}
  - placements: [product_page_header]
    spec: header_21x9
    text: storeCreativeHeader
    assets:
      - {id: "header.{storefront}", type: image, frame: {script: A, scene: player, at: 1.0}}
      - id: "header.{storefront}.video"
        type: video
        template: banner_loop
        rhythm: 12
        poster_at: 2.0
        scenes:
          - {beat: hero, script: A, scene: player, duration: 6.0}
          - {beat: detail, script: W, scene: hold, duration: 6.0}
  - placements: [app_store_search_results]
    spec: search_3x2
    text: storeCreativeSearch
    # The photo W's hold shows is also this slot's backdrop.
    backdrop: {role: photo, script: A, index: 1}
    assets:
      - {id: "search.{storefront}", type: image, frame: {script: W, scene: hold, at: -0.5}}
''';

Map<String, String> creativeTexts(String locale) =>
    locale == 'ja' ? {'storeCreativeHeader': '大切な人に贈る歌', 'storeCreativeSearch': '名前から歌をつくる'} : {'storeCreativeHeader': 'Songs for the people you love', 'storeCreativeSearch': 'Turn a name into a song'};

/// The fixture repo with [creativeAppYaml], scripts A and W, the definition
/// and the phrases in both ARBs.
FixtureRepo creativeRepo(String packageRoot, {String creative = fixtureCreative, String? listing, String? layouts}) {
  final repo = FixtureRepo.create(
    appYaml: creativeAppYaml(packageRoot, listing: listing, layouts: layouts),
    scripts: {'A': fixtureScriptA, 'W': fixtureScriptW},
  );
  for (final locale in ['en', 'ja']) {
    repo.write('l10n/app_$locale.arb', jsonEncode({'@@locale': locale, 'title': 'Demo', ...fixtureTexts(locale), ...creativeTexts(locale)}));
  }
  repo.write('store_preview/demo/creatives/page.yaml', creative);
  return repo;
}

/// [completeManifest] with a license id per item, so the manifest's
/// authorization shows which item it took.
List<Map<String, Object?>> creativeManifest() => [
  for (final l in ['en-US', 'ja']) ...[
    entry(id: 'song.A.$l', type: 'audio', role: 'song', locale: l, vars: {'recipient': 'Alex'}, licenseId: 'song-$l'),
    entry(id: 'photo.A.$l.1', type: 'image', role: 'photo', locale: l, licenseId: 'photo1-$l'),
    entry(id: 'photo.A.$l.2', type: 'image', role: 'photo', locale: l, licenseId: 'photo2-$l'),
  ],
];

/// A take run on disk: [scenes] (scene → host-clock ms window) of [script],
/// filmed from `rec` ms; [pattern] is the synthetic footage (an ffmpeg
/// lavfi source at the native iPhone size).
Future<void> synthesizeRun(TakeFiles take, {required String script, required List<(String, int, int, double?)> scenes, required String pattern, required int seconds}) async {
  Directory(take.dir).createSync(recursive: true);
  final r = await Process.run('ffmpeg', [
    '-v', 'error', '-y', '-f', 'lavfi', '-i', '$pattern=s=1320x2868:r=30:d=$seconds', //
    '-c:v', 'libx264', '-preset', 'ultrafast', '-pix_fmt', 'yuv420p', take.recording,
  ]);
  if (r.exitCode != 0) throw StateError('ffmpeg: ${r.stderr}');
  File(take.recLog).writeAsStringSync('1000 Recording started\n');
  File(take.plan).writeAsStringSync(jsonEncode({
    'runs': [
      {'script': script},
    ],
  }));
  File(take.driverLog).writeAsStringSync([
    for (final (scene, from, to, pos) in scenes) ...[
      '$markTag{"t":$from,"script":"$script","scene":"$scene","edge":"start"${pos == null ? '' : ',"pos":$pos'}}',
      '$markTag{"t":$to,"script":"$script","scene":"$scene","edge":"end"}',
    ],
    '$markTag{"t":${seconds * 1000},"edge":"done"}',
  ].join('\n'));
}

/// Two runs registered for en-US on the phone: A (its player 7.5–13.5 s) and
/// W (its hold 2–10 s), the media, and an icon.
Future<void> synthesizeCreativeTakes(FixtureRepo repo) async {
  Future<void> ff(List<String> args) async {
    final r = await Process.run('ffmpeg', ['-v', 'error', '-y', ...args]);
    if (r.exitCode != 0) throw StateError('ffmpeg ${args.join(' ')}: ${r.stderr}');
  }

  final registry = TakeRegistry(repo.path('build/store_preview/demo/raw/en-US/iphone'));
  await synthesizeRun(
    registry.run('20261008T100000Z'),
    script: 'A',
    scenes: [('name', 2000, 6000, null), ('wait', 6000, 7500, null), ('player', 7500, 13500, 30.0), ('share', 13500, 16500, null)],
    pattern: 'testsrc2',
    seconds: 17,
  );
  registry.register('20261008T100000Z', ['A']);
  await synthesizeRun(registry.run('20261008T110000Z'), script: 'W', scenes: [('hold', 2000, 10000, null)], pattern: 'smptehdbars', seconds: 11);
  registry.register('20261008T110000Z', ['W']);
  repo.manifest(creativeManifest());
  final media = repo.path('store_preview/demo/media');
  for (final l in ['en-US', 'ja']) {
    await ff(['-f', 'lavfi', '-i', 'sine=f=440:d=60', '-ac', '2', '-c:a', 'libmp3lame', '-b:a', '192k', '$media/audio/song.A.$l.mp3']);
    for (final i in [1, 2]) {
      // A fixed dark gradient (lavfi's gradients are random unless seeded):
      // the backdrop's measured contrast is the same on every run.
      await ff(['-f', 'lavfi', '-i', 'gradients=s=1024x1365:d=1:n=2:c0=0x1B2430:c1=0x3A2A40:seed=$i', '-frames:v', '1', '$media/image/photo.A.$l.$i.png']);
    }
  }
  await ff(['-f', 'lavfi', '-i', 'color=c=0xD9482B:s=1024x1024:d=1', '-frames:v', '1', repo.path('assets/icon.png')]);
  Directory(p.join(repo.root, 'store_preview/demo/captions')).createSync(recursive: true);
}
