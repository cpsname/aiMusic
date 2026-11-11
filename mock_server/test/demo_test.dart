import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:songlet_mock_server/songlet_mock_music_server.dart';
import 'package:test/test.dart';

import 'support.dart';

/// The `demo` profile (store_preview/songlet): a storefront's own song, lyrics,
/// timing and lyric video instead of the fixtures, the wait compressed while
/// the reply keeps the real ETA.
void main() {
  final h = MusicHarness()..install();
  late Directory media;
  late String manifest;

  setUpAll(() {
    media = Directory.systemTemp.createTempSync('songlet_demo_');
    final assets = p.join(p.current, 'assets');
    File(p.join(assets, 'clip_30s.mp3')).copySync(p.join(media.path, 'ja_A.mp3'));
    File(p.join(assets, 'mv_15s.mp4')).copySync(p.join(media.path, 'ja_B.mp4'));
    File(p.join(assets, 'song_120s.mp3')).copySync(p.join(media.path, 'ja_B.mp3'));
    manifest = p.join(media.path, 'manifest.json');
    File(manifest).writeAsStringSync(jsonEncode({
      'schema': 2,
      'entries': [
        {
          'id': 'song.A.ja', 'type': 'audio', 'role': 'song', 'locale': 'ja', 'script': 'A', 'file': 'ja_A.mp3', //
          'data': {
            'lyrics': '[Verse]\nアレックスの朝\n[Chorus]\nハッピーバースデー、アレックス',
            'structure': [
              {'section': 'Verse', 'start': 0, 'end': 12.5},
              {'section': 'Chorus', 'start': 12.5, 'end': 30},
            ],
          },
        },
        {
          'id': 'song.B.ja', 'type': 'audio', 'role': 'song', 'locale': 'ja', 'script': 'B', 'file': 'ja_B.mp3', //
          'data': {
            'lyrics': '[Chorus]\n写真の夏',
            'structure': [
              {'section': 'Chorus', 'start': 0, 'end': 120},
            ],
          },
        },
        {'id': 'lyric_video.B.ja', 'type': 'video', 'role': 'lyric_video', 'locale': 'ja', 'script': 'B', 'file': 'ja_B.mp4'},
      ],
    }));
  });
  tearDownAll(() => media.deleteSync(recursive: true));

  Future<MusicMockClient> pro() async {
    final c = await h.device();
    await h.client().admin('grant', {'product_id': 'com.songlet.premier.monthly', 'app_account_token': c.appAccountToken});
    return c;
  }

  test('a selected song: no queue, the real ETA, the manifest lyrics, timing and audio', () async {
    final admin = h.client();
    expect((await admin.admin('demo', {'manifest': manifest, 'script': 'A', 'locale': 'ja'})).status, 200);
    await admin.admin('config', {'demo_delay_ms': 300, 'wav_enabled': true});
    final c = await pro();
    final res = await c.generate(model: 'lyria-3.5', lyricLanguage: 'ja');
    expect(res.data['eta_seconds'], 45, reason: '"Usually about 45 seconds"');
    final id = res.data['job_id']! as String;
    expect((await c.job(id)).data['status'], 'running', reason: 'no queue banner in a preview');

    final done = await c.waitJob(id);
    expect(done['lyrics'], contains('ハッピーバースデー、アレックス'));
    expect(done['structure'], [
      {'section': 'Verse', 'start': 0.0, 'end': 12.5},
      {'section': 'Chorus', 'start': 12.5, 'end': 30.0},
    ]);
    final audio = await c.raw('GET', done['audio_url']! as String);
    expect(audio.bytes, File(p.join(media.path, 'ja_A.mp3')).readAsBytesSync());
    final wav = await c.raw('GET', done['wav_url']! as String);
    expect(wav.headers.contentType?.mimeType, 'audio/wav');
    expect(ascii.decode(wav.bytes.sublist(0, 4)), 'RIFF');
  });

  test("a demo song's lyric video is the storefront's platform video", () async {
    final admin = h.client();
    await admin.admin('demo', {'manifest': manifest, 'script': 'B', 'locale': 'ja'});
    await admin.admin('config', {'demo_delay_ms': 100, 'mv_delay_ms': 200});
    final c = await pro();
    final id = (await c.generate(model: 'lyria-3.5', lyricLanguage: 'ja')).data['job_id']! as String;
    await c.waitJob(id);
    final mvId = (await c.mvCreate(id, level: 'lyric_video')).data['mv_id']! as String;
    final mv = await c.waitMv(mvId);
    expect(mv['status'], 'succeeded');
    expect(mv['duration_ms'], closeTo(15000, 200));
    final video = await c.raw('GET', mv['video_url']! as String);
    expect(video.bytes, File(p.join(media.path, 'ja_B.mp4')).readAsBytesSync());
  });

  test('selection is checked against the manifest; off → fixtures again', () async {
    final admin = h.client();
    await admin.admin('demo', {'manifest': manifest});
    expect((await admin.admin('demo', {'script': 'C', 'locale': 'ja'})).code, 40001);
    expect((await admin.admin('demo', {'manifest': p.join(media.path, 'nope.json')})).code, 40001);
    final schema1 = File(p.join(media.path, 'schema1.json'))..writeAsStringSync(jsonEncode({'entries': <Object>[]}));
    expect((await admin.admin('demo', {'manifest': schema1.path})).code, 40001);
    await admin.admin('demo', {'manifest': null});
    final c = await pro();
    final res = await c.generate(model: 'lyria-3.5');
    expect(res.data['eta_seconds'], isNot(45));
    expect((await c.waitJob(res.data['job_id']! as String))['lyrics'], contains('Alex'));
  });
}
