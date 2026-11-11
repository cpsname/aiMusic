import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';

/// The package's own directory (templates/, defaults/, native/): the
/// working directory (`melos exec`, `flutter test` in the package) or
/// `packages/store_preview` under it (`flutter test packages/store_preview`
/// from the repo root). `flutter test` does not resolve package URIs to files.
Future<String> packageRoot() async {
  for (final candidate in [Directory.current.path, p.join(Directory.current.path, 'packages', 'store_preview')]) {
    if (File(p.join(candidate, 'defaults', 'devices.yaml')).existsSync()) return candidate;
  }
  throw StateError('run the tests from the repo root or packages/store_preview');
}

const String fixtureAppYaml = '''
app: demo
bundle_id: com.example.demo
brand:
  name: Demo
  icon: assets/icon.png
  palette: {primary: "#D9482B", on_primary: "#FFFFFF", scrim: "#000000"}
  cta_key: storePreviewCta
  disclosure_key: storePreviewDisclosure
requires_purchase: true
captions:
  arb_dir: l10n
  banned_words: [rivalapp]
devices: [iphone]
driver:
  type: flutter_integration_test
  target: integration_test/store_preview_test.dart
  ready: {key: home}
backend:
  start: "dart run mock/server.dart --port {port} --manifest {manifest}"
  health: "http://localhost:{port}/health"
  admin: "http://localhost:{port}/admin/"
  port: 8799
  before_take:
    - {post: reset}
    - {post: media, body: {manifest: "{manifest}"}}
prelude:
  - {do: waitFor, key: home}
on_use:
  - {do: admin, path: next, body: {script: "{use.script}", locale: "{use.locale}"}}
simulator:
  library: {role: photo}
storefronts:
  - {id: en-US, ui_locale: en, sim_language: en, sim_locale: en_US, aso_name: "Demo: Songs", aso_subtitle: "Make one", vars: {region: US}}
  - {id: ja, ui_locale: ja, sim_language: ja, sim_locale: ja_JP, aso_name: "Demo: 歌", aso_subtitle: "作ろう", vars: {region: JP}}
publish:
  shared_poster_at: 8
''';

/// A 15 s input → wait → result → share script.
const String fixtureScriptA = '''
id: A
title: A song for them
template: input_wait_result_share
rhythm: 15
poster_at: 8
requires:
  - {role: song, vars: [recipient]}
  - {role: photo, count: 2}
setup:
  - {do: use, role: song}
segments:
  - card: intro
    duration: 0.8
    text: storePreviewAIntro
    background: {image: {role: photo, index: 0}}
  - scene: name
    beat: input
    duration: 3.5
    steps:
      - {do: type, key: name, text: "{recipient}"}
  - scene: wait
    beat: wait
    duration: 1.2
    steps: [{do: pause, ms: 500}]
  - scene: player
    beat: result
    duration: 5.5
    finished: true
    follow: song
    audio: {role: song}
    steps: [{do: pause, ms: 5000}]
  - scene: share
    beat: share
    duration: 2.6
    steps: [{do: tap, key: share}]
  - card: outro
    duration: 1.4
captions:
  - {key: storePreviewAHook, from: 0.8, to: 4.3}
  - {key: storePreviewAWait, from: 4.3, to: 5.9}
  - {key: storePreviewAResult, from: 5.9, to: 11.0}
  - {key: storePreviewAShare, from: 11.0, to: 13.6}
''';

Map<String, String> fixtureTexts(String locale) => locale == 'ja'
    ? {
        'storePreviewAIntro': 'あの人の名前の歌',
        'storePreviewAHook': '名前から始めよう',
        'storePreviewAWait': '作曲中',
        'storePreviewAResult': 'サビで名前を歌う',
        'storePreviewAShare': 'カードで贈ろう',
        'storePreviewCta': '最初の一曲を作ろう',
        'storePreviewDisclosure': 'サブスクリプションまたはクレジットが必要',
      }
    : {
        'storePreviewAIntro': 'A song with their name',
        'storePreviewAHook': 'Start with their name',
        'storePreviewAWait': 'Writing it',
        'storePreviewAResult': 'Their name in the chorus',
        'storePreviewAShare': 'Send it as a card',
        'storePreviewCta': 'Write your first song',
        'storePreviewDisclosure': 'Requires a subscription or credits',
      };

/// A repo with one app (`demo`), in a temp directory.
class FixtureRepo {
  FixtureRepo._(this.root);

  static FixtureRepo create({String appYaml = fixtureAppYaml, Map<String, String> scripts = const {'A': fixtureScriptA}}) {
    final root = Directory.systemTemp.createTempSync('store_preview_fixture').path;
    final repo = FixtureRepo._(root);
    repo.write('store_preview/demo/app.yaml', appYaml);
    for (final e in scripts.entries) {
      repo.write('store_preview/demo/scripts/${e.key}.yaml', e.value);
    }
    for (final locale in ['en', 'ja']) {
      repo.write('l10n/app_$locale.arb', jsonEncode({'@@locale': locale, 'title': 'Demo', ...fixtureTexts(locale)}));
    }
    repo.write('assets/icon.png', 'png');
    repo.write('integration_test/store_preview_test.dart', '// driver entry\n');
    return repo;
  }

  final String root;

  String path(String relative) => p.join(root, relative);

  void write(String relative, String content) {
    File(path(relative))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  /// Writes a schema 2 manifest with these entries (files are created empty).
  void manifest(List<Map<String, Object?>> entries) {
    for (final e in entries) {
      write('store_preview/demo/media/${e['file']}', 'x');
    }
    write('store_preview/demo/media/manifest.json', jsonEncode({'schema': manifestSchema, 'entries': entries}));
  }

  void delete() => Directory(root).deleteSync(recursive: true);
}

Map<String, Object?> entry({
  required String id,
  required String type,
  required String role,
  required String locale,
  String script = 'A',
  String? file,
  String licenseId = 'gen-1',
  Map<String, String> vars = const {},
}) => {
  'id': id,
  'type': type,
  'role': role,
  'locale': locale,
  'script': script,
  'file': file ?? '$type/$id.${type == 'audio' ? 'mp3' : type == 'video' ? 'mp4' : 'png'}',
  'license': {'provider': 'test', 'id': licenseId, 'model': 'm1', 'generated_at': '2026-10-05T08:00:00Z'},
  'vars': vars,
};

/// Every entry the fixture's script A needs in both storefronts.
List<Map<String, Object?>> completeManifest() => [
  for (final l in ['en-US', 'ja']) ...[
    entry(id: 'song.A.$l', type: 'audio', role: 'song', locale: l, vars: {'recipient': 'Alex'}),
    entry(id: 'photo.A.$l.1', type: 'image', role: 'photo', locale: l),
    entry(id: 'photo.A.$l.2', type: 'image', role: 'photo', locale: l),
  ],
];

/// Probes by file extension: audio, video (+ audio), images 1024 px.
class FakeProber implements Prober {
  const FakeProber({this.videoWithoutAudio = false});

  final bool videoWithoutAudio;

  @override
  MediaInfo? probe(String path) {
    final ext = p.extension(path);
    const audio = AudioStream(codec: 'mp3', channels: 2, sampleRate: 44100, bitRate: 192000);
    const picture = VideoStream(codec: 'png', width: 1024, height: 1365, frameRate: 0, bitRate: 0, pixFmt: 'rgb24');
    return switch (ext) {
      '.mp3' => const MediaInfo(duration: 120, size: 1, formatName: 'mp3', audio: audio),
      '.mp4' => MediaInfo(duration: 60, size: 1, formatName: 'mov,mp4', video: picture, audio: videoWithoutAudio ? null : audio),
      '.png' || '.jpg' => const MediaInfo(duration: 0, size: 1, formatName: 'png_pipe', video: picture),
      _ => null,
    };
  }
}
