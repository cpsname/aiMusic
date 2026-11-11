import 'package:crypto/crypto.dart';
import 'package:songlet_mock_server/songlet_mock_music_server.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final h = MusicHarness()..install();

  Future<int> clipsLeft(MusicMockClient c) async =>
      (await c.sync(const [])).data['clips_left']! as int;

  group('region', () {
    test(
      'unsupported device region → REGION_UNAVAILABLE (451), not charged',
      () async {
        for (final region in [
          'CN',
          'HK',
          'MO',
          'RU',
          'BY',
          'IR',
          'KP',
          'SY',
          'CU',
        ]) {
          final c = await h.device(deviceRegion: region);
          final res = await c.generate();
          expect(
            (res.status, res.code, res.errorCode),
            (451, 45103, 'REGION_UNAVAILABLE'),
            reason: region,
          );
          expect(await clipsLeft(c), 3);
        }
      },
    );

    test(
      'unsupported storefront (header, alpha-3) → REGION_UNAVAILABLE',
      () async {
        final c = await h.device(storefront: 'CHN');
        expect((await c.generate()).errorCode, 'REGION_UNAVAILABLE');
        c.storefront = 'RUS';
        expect((await c.generate()).errorCode, 'REGION_UNAVAILABLE');
        c.storefront = 'USA';
        expect((await c.generate()).code, 0);
      },
    );

    test('storefront falls back to the latest synced JWS', () async {
      final c = await h.device(storefront: '');
      await c.sync([
        txPayload(
          productId: 'com.songlet.pack.10',
          appAccountToken: c.appAccountToken,
          storefront: 'HKG',
        ),
      ]);
      expect((await c.generate()).errorCode, 'REGION_UNAVAILABLE');
    });

    test('region field must be one of the 14 presets', () async {
      final c = await h.device();
      expect((await c.generate(region: 'CN')).errorCode, 'REGION_UNAVAILABLE');
      expect((await c.generate(region: 'IT')).errorCode, 'REGION_UNAVAILABLE');
      for (final ok in ['JP', 'br', 'IN']) {
        expect((await c.generate(region: ok)).code, 0, reason: ok);
      }
    });

    test(
      'works stay readable when the region later becomes unsupported',
      () async {
        final c = await h.device();
        final id = (await c.generate()).data['job_id']! as String;
        await c.waitJob(id);
        c.deviceRegion = 'RU';
        expect((await c.generate()).errorCode, 'REGION_UNAVAILABLE');
        expect((await c.job(id)).data['status'], 'succeeded');
      },
    );
  });

  group('safety pre-check', () {
    for (final bad in [
      'make it in the style of someone famous',
      'should sound like a big star',
      'with the voice of my idol',
      'something Taylor Swift would sing',
      'like drake but happier',
      'BTS vibes',
      'an Ed Sheeran ballad',
    ]) {
      test('blocks "$bad" without charging', () async {
        final c = await h.device();
        final res = await c.generate(keywords: bad);
        expect(
          (res.status, res.code, res.errorCode),
          (451, 45101, 'SAFETY_BLOCKED'),
        );
        expect(await clipsLeft(c), 3);
      });
    }

    test('lyrics are checked too; sensitive-but-fine words pass', () async {
      final c = await h.device();
      final blocked = await c.generate(
        lyrics: '[Verse]\nSing in the style of Adele',
      );
      expect(blocked.errorCode, 'SAFETY_BLOCKED');
      for (final ok in [
        'funeral | goodbye',
        'breakup | healing',
        'mandrake | badele',
      ]) {
        expect((await c.generate(keywords: ok)).code, 0, reason: ok);
      }
    });
  });

  test('idempotent per (app_account_token, client_ref)', () async {
    final c = await h.device();
    final ref = uuidV4();
    final first = await c.generate(clientRef: ref);
    final second = await c.generate(clientRef: ref);
    expect(second.data, first.data);
    expect(await clipsLeft(c), 2); // charged once

    final other = await h
        .device(); // same client_ref on another token → new job
    final third = await other.generate(clientRef: ref);
    expect(third.data['job_id'], isNot(first.data['job_id']));
  });

  test('validation → 40001 with field details', () async {
    final c = await h.device();
    final badModel = await c.generate(model: 'lyria-9');
    expect((badModel.status, badModel.code), (400, 40001));
    expect(badModel.json['details'], containsPair('model', isA<String>()));
    expect((await c.generate(occasion: 'party')).code, 40001);
    expect((await c.generate(lyrics: 'x' * 1201)).code, 40001);
    expect((await c.generate(lyrics: '歌' * 601)).code, 40001);
    expect((await c.generate(images: ['nope'])).code, 40001);
    expect(await clipsLeft(c), 3);
  });

  test('fail_next request-level codes reject the next generate', () async {
    final c = await h.device();
    await c.admin('fail_next', {'error_code': 'QUOTA_EXHAUSTED'});
    expect((await c.generate()).errorCode, 'QUOTA_EXHAUSTED');
    expect((await c.generate()).code, 0);
    final bad = await c.admin('fail_next', {'error_code': 'NOPE'});
    expect(bad.code, 40001);
  });

  test('upload sign → PUT → finalize, then photo generation', () async {
    final c = await h.device();
    final bytes = List<int>.generate(2048, (i) => i % 251);
    final hash = sha256.convert(bytes).toString();
    final sign = await c.call(
      'POST',
      '/uploads/sign',
      body: {
        'mime_type': 'image/jpeg',
        'size': bytes.length,
        'filename': 'photo.jpg',
        'file_hash': hash,
        'access_level': 'private',
        'content_type': 'image',
      },
    );
    expect(sign.code, 0, reason: '$sign');
    final ticket = sign.data;
    final bid = ticket['bid']! as String;
    expect(ticket['put_url'], '${h.baseUrl}/r2/$bid');
    expect(ticket['dedup_hit'], false);
    expect(ticket['expires_at'], isA<int>());

    // Finalize before PUT → no object.
    expect(
      (await c.call('POST', '/uploads/finalize', body: {'bid': bid})).code,
      40430,
    );
    final wrongType = await c.raw(
      'PUT',
      ticket['put_url']! as String,
      bytes: bytes,
      headers: {'Content-Type': 'image/png'},
    );
    expect(wrongType.status, 403);
    final put = await c.raw(
      'PUT',
      ticket['put_url']! as String,
      bytes: bytes,
      headers: {'Content-Type': 'image/jpeg'},
    );
    expect(put.status, 200);
    expect(put.bytes, isEmpty);

    final fin = await c.call('POST', '/uploads/finalize', body: {'bid': bid});
    expect(fin.code, 0);
    expect(fin.data['bid'], bid);
    expect(fin.data['file_size'], bytes.length);
    expect(fin.data['mime_type'], 'image/jpeg');
    expect(
      (await c.call('POST', '/uploads/finalize', body: {'bid': bid})).code,
      40922,
    );
    expect((await c.raw('GET', fin.data['url']! as String)).bytes, bytes);

    final gen = await c.generate(images: [bid]);
    expect(gen.code, 0, reason: '$gen');
    expect(
      (await c.waitJob(gen.data['job_id']! as String))['status'],
      'succeeded',
    );

    final badMime = await c.call(
      'POST',
      '/uploads/sign',
      body: {'mime_type': 'application/zip', 'size': 1, 'file_hash': hash},
    );
    expect(badMime.code, 40034);
  });

  test(
    'GET /v1/app/config reflects admin maintenance + kill switches',
    () async {
      final c = h.client();
      await c.admin('config', {
        'maintenance': {'active': true, 'message': 'Back soon', 'resume_at': 1},
        'kill_switches': ['iap_purchase'],
        'remote_config': {'promo_text': 'hi'},
      });
      final res = await c.call('GET', '/app/config', auth: false);
      expect(res.data['maintenance'], {
        'active': true,
        'message': 'Back soon',
        'resume_at': 1,
      });
      expect(res.data['kill_switches'], ['iap_purchase']);
      expect(res.data['config'], {'promo_text': 'hi'});
    },
  );
}
