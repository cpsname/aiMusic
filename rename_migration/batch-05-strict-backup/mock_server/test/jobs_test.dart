import 'dart:convert';

import 'package:songlet_mock_server/songlet_mock_server.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  // Slow enough that intermediate states are observable by polling.
  final h = Harness()..install(clipDelayMs: 400, songDelayMs: 500);

  Future<List<Map<String, Object?>>> trace(
    SongletMockClient c,
    String id,
  ) async {
    final seen = <Map<String, Object?>>[];
    while (true) {
      final data = (await c.job(id)).data;
      final entry = {
        'status': data['status'],
        'error_code': data['error_code'],
      };
      if (seen.isEmpty || seen.last.toString() != entry.toString()) {
        seen.add(entry);
      }
      if (data['status'] == 'succeeded' || data['status'] == 'failed') {
        return seen;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  test(
    'clip: queued → running → succeeded with audio, lyrics, structure',
    () async {
      final c = await h.device();
      final res = await c.generate(recipient: 'Mia', keywords: 'tea | rain');
      expect(res.data['eta_seconds'], 1);
      final id = res.data['job_id']! as String;
      final states = await trace(c, id);
      expect(
        states.map((s) => s['status']),
        containsAllInOrder(['queued', 'running', 'succeeded']),
      );

      final data = (await c.job(id)).data;
      expect(data['audio_url'], '${h.baseUrl}/files/$id.mp3');
      final lyrics = data['lyrics']! as String;
      expect(lyrics, contains('[Intro]'));
      expect(lyrics, contains('[Verse]'));
      expect(lyrics, contains('[Chorus]'));
      expect(lyrics, contains('Mia'));
      expect(lyrics, contains('tea'));
      expect(data['structure'], [
        {'section': 'Intro', 'start': 0.0, 'end': 3.0},
        {'section': 'Verse', 'start': 3.0, 'end': 15.0},
        {'section': 'Chorus', 'start': 15.0, 'end': 30.0},
      ]);
      expect(data.containsKey('error_code'), isFalse);
    },
  );

  test('audio: audio/mpeg with Content-Length and HTTP Range', () async {
    final c = await h.device();
    final id = (await c.generate()).data['job_id']! as String;
    final url = (await c.waitJob(id))['audio_url']! as String;
    final full = await c.raw('GET', url);
    expect(full.status, 200);
    expect(full.headers.contentType?.mimeType, 'audio/mpeg');
    expect(full.headers.contentLength, full.bytes.length);
    expect(full.headers.value('Accept-Ranges'), 'bytes');
    expect(full.bytes.length, greaterThan(300000)); // ~30 s @ 96 kbps

    final part = await c.raw('GET', url, headers: {'Range': 'bytes=100-199'});
    expect(part.status, 206);
    expect(part.bytes, full.bytes.sublist(100, 200));
    expect(
      part.headers.value('Content-Range'),
      'bytes 100-199/${full.bytes.length}',
    );
    final tail = await c.raw('GET', url, headers: {'Range': 'bytes=-10'});
    expect(tail.bytes, full.bytes.sublist(full.bytes.length - 10));
    final bad = await c.raw(
      'GET',
      url,
      headers: {'Range': 'bytes=${full.bytes.length}-'},
    );
    expect(bad.status, 416);
    final head = await c.raw('HEAD', url);
    expect(head.headers.contentLength, full.bytes.length);
  });

  test('song: 120 s structure, recipient ≥2×, full section tags', () async {
    final c = await h.device();
    await c.sync([
      txPayload(
        productId: 'com.songlet.pro.monthly',
        appAccountToken: c.appAccountToken,
      ),
    ]);
    final id =
        (await c.generate(
              model: 'lyria-3.5',
              recipient: 'Noah',
            )).data['job_id']!
            as String;
    final data = await c.waitJob(id);
    final lyrics = data['lyrics']! as String;
    expect(RegExp('Noah').allMatches(lyrics).length, greaterThanOrEqualTo(2));
    for (final tag in [
      '[Intro]', '[Verse]', '[Chorus]', '[Verse 2]', '[Bridge]', '[Outro]', //
    ]) {
      expect(lyrics, contains(tag));
    }
    final structure = (data['structure']! as List).cast<Map<String, Object?>>();
    expect(structure.map((s) => s['section']), [
      'Intro', 'Verse 1', 'Chorus', 'Verse 2', 'Chorus', 'Bridge', 'Chorus', //
      'Outro',
    ]);
    expect(structure.last['end'], 120.0);
    final audio = await c.raw('GET', data['audio_url']! as String);
    expect(audio.bytes.length, greaterThan(1200000)); // ~120 s
  });

  test('user lyrics are echoed verbatim', () async {
    final c = await h.device();
    const mine = '[Verse]\nMy own line\n[Chorus]\nSing it, Sam';
    final id = (await c.generate(lyrics: mine)).data['job_id']! as String;
    expect((await c.waitJob(id))['lyrics'], mine);
  });

  test('UPSTREAM_TIMEOUT: running + hint, then failed and refunded', () async {
    final c = await h.device();
    await c.admin('fail_next', {'error_code': 'UPSTREAM_TIMEOUT'});
    final id = (await c.generate()).data['job_id']! as String;
    expect((await c.sync(const [])).data['clips_left'], 2);
    final states = await trace(c, id);
    expect(
      states,
      containsAllInOrder([
        {'status': 'running', 'error_code': 'UPSTREAM_TIMEOUT'},
        {'status': 'failed', 'error_code': 'UPSTREAM_TIMEOUT'},
      ]),
    );
    expect((await c.sync(const [])).data['clips_left'], 3);
    final failed = (await c.job(id)).data;
    expect(failed.containsKey('audio_url'), isFalse);
  });

  test(
    'UPSTREAM_RATE_LIMITED: queued + hint, then succeeds (charged)',
    () async {
      final c = await h.device();
      await c.admin('fail_next', {'error_code': 'UPSTREAM_RATE_LIMITED'});
      final id = (await c.generate()).data['job_id']! as String;
      final states = await trace(c, id);
      expect(states.first, {
        'status': 'queued',
        'error_code': 'UPSTREAM_RATE_LIMITED',
      });
      expect(states.last, {'status': 'succeeded', 'error_code': null});
      expect((await c.sync(const [])).data['clips_left'], 2);
    },
  );

  test(
    'forced SAFETY_BLOCKED / IMAGE_REJECTED fail the job and refund',
    () async {
      final c = await h.device();
      for (final code in ['SAFETY_BLOCKED', 'IMAGE_REJECTED']) {
        await c.admin('fail_next', {'error_code': code});
        final id = (await c.generate()).data['job_id']! as String;
        final done = await c.waitJob(id);
        expect((done['status'], done['error_code']), ('failed', code));
      }
      expect((await c.sync(const [])).data['clips_left'], 3);
    },
  );

  test('license PDF: valid document with the required statements', () async {
    final c = await h.device();
    await c.sync([
      txPayload(
        productId: 'com.songlet.pack.10',
        appAccountToken: c.appAccountToken,
      ),
    ]);
    final id = (await c.generate(model: 'lyria-3.5')).data['job_id']! as String;
    await c.waitJob(id);
    final res = await c.call('GET', '/license/$id');
    expect(res.status, 200);
    expect(res.headers.contentType?.mimeType, 'application/pdf');
    final text = latin1.decode(res.bytes);
    expect(text, startsWith('%PDF-1.4'));
    expect(text.trimRight(), endsWith('%%EOF'));
    expect(text, contains('Songlet commercial license'));
    expect(text, contains(id));
    expect(text, contains(licenseScope));
    expect(
      text,
      contains(
        'Generated with Google Lyria 3 · contains SynthID '
        'watermark · AI generated',
      ),
    );
    // xref offsets point at real objects.
    final startxref = int.parse(
      RegExp(r'startxref\n(\d+)').firstMatch(text)!.group(1)!,
    );
    expect(text.substring(startxref, startxref + 4), 'xref');
    final offsets = RegExp(r'(\d{10}) 00000 n').allMatches(text).toList();
    for (var i = 0; i < offsets.length; i++) {
      final at = int.parse(offsets[i].group(1)!);
      expect(text.substring(at), startsWith('${i + 1} 0 obj'));
    }
  });

  test('jobs are private to their account', () async {
    final a = await h.device();
    final b = await h.device();
    final id = (await a.generate()).data['job_id']! as String;
    final res = await b.job(id);
    expect((res.status, res.code), (404, 40404));
  });
}
