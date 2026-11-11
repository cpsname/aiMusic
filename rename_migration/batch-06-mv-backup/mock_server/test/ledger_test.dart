import 'package:songlet_mock_server/songlet_mock_server.dart';
import 'package:test/test.dart';

import 'support.dart';

const _pro = 'com.songlet.pro.monthly';
const _yearly = 'com.songlet.pro.yearly';
const _premier = 'com.songlet.premier.monthly';
const _pack10 = 'com.songlet.pack.10';

void main() {
  final h = Harness()..install();

  Future<Map<String, Object?>> status(SongletMockClient c) async {
    final res = await c.sync(const []);
    expect(res.code, 0, reason: '$res');
    return res.data;
  }

  /// Advances the mock clock and lets [c] catch up (clock-sync + re-attest,
  /// as the app does after `X-Server-Time` moves and its token expires).
  Future<void> advance(SongletMockClient c, int days) async {
    await c.admin('advance_clock', {'days': days});
    c.clockOffset += Duration(days: days);
    expect((await c.attest()).code, 0);
  }

  Future<String> makeSong(SongletMockClient c) async {
    final res = await c.generate(model: 'lyria-3.5');
    expect(res.code, 0, reason: '$res');
    final id = res.data['job_id']! as String;
    expect((await c.waitJob(id))['status'], 'succeeded');
    return id;
  }

  test(
    'free: 3 lifetime clips, then QUOTA_EXHAUSTED; songs need payment',
    () async {
      final c = await h.device();
      expect(await status(c), {
        'tier': 'free',
        'songs_left': 0,
        'clips_left': 3,
        'reset_at': null,
      });
      for (var i = 0; i < 3; i++) {
        expect((await c.generate()).code, 0);
      }
      final fourth = await c.generate();
      expect(
        (fourth.status, fourth.code, fourth.errorCode),
        (200, 49303, 'QUOTA_EXHAUSTED'),
      );
      final song = await c.generate(model: 'lyria-3.5');
      expect(song.errorCode, 'QUOTA_EXHAUSTED');
      expect((await status(c))['clips_left'], 0);
    },
  );

  test('Pro monthly: 40/100 → one song → 39/100; reset_at = renewal', () async {
    final c = await h.device();
    final tx = txPayload(productId: _pro, appAccountToken: c.appAccountToken);
    final synced = (await c.sync([tx])).data;
    expect(synced['tier'], 'pro');
    expect((synced['songs_left'], synced['clips_left']), (40, 100));
    expect(
      DateTime.parse(synced['reset_at']! as String).millisecondsSinceEpoch,
      tx['expiresDate'],
    );
    await makeSong(c);
    final after = await status(c);
    expect((after['songs_left'], after['clips_left']), (39, 100));
  });

  test('T2/T3 storefronts get 25/60; Premier 120/200', () async {
    final br = await h.device(storefront: 'BRA', deviceRegion: 'BR');
    final t2 = (await br.sync([
      txPayload(
        productId: _pro,
        appAccountToken: br.appAccountToken,
        storefront: 'BRA',
      ),
    ])).data;
    expect((t2['songs_left'], t2['clips_left']), (25, 60));

    final us = await h.device();
    final premier = (await us.sync([
      txPayload(productId: _premier, appAccountToken: us.appAccountToken),
    ])).data;
    expect(
      (premier['tier'], premier['songs_left'], premier['clips_left']),
      ('premier', 120, 200),
    );
  });

  test('yearly trial (offerType 1) is capped at 10 songs', () async {
    final c = await h.device();
    final now = DateTime.now().toUtc();
    final trial = (await c.sync([
      txPayload(
        productId: _yearly,
        appAccountToken: c.appAccountToken,
        offerType: 1,
        purchaseDate: now,
        expiresDate: now.add(const Duration(days: 7)),
      ),
    ])).data;
    expect(
      (trial['tier'], trial['songs_left'], trial['clips_left']),
      ('pro', 10, 100),
    );
  });

  test('yearly resets monthly (no rollover)', () async {
    final c = await h.device();
    await c.sync([
      txPayload(productId: _yearly, appAccountToken: c.appAccountToken),
    ]);
    await makeSong(c);
    await makeSong(c);
    expect((await status(c))['songs_left'], 38);
    await advance(c, 31);
    final next = await status(c);
    expect((next['tier'], next['songs_left']), ('pro', 40));
  });

  test('pack 10 → forced failure refunds → 10; packs never expire; '
      'expired subscription → 0', () async {
    final c = await h.device();
    await c.sync([
      txPayload(productId: _pro, appAccountToken: c.appAccountToken),
      txPayload(productId: _pack10, appAccountToken: c.appAccountToken),
    ]);
    expect((await status(c))['songs_left'], 50);
    // Burn the subscription so the pack is next in line.
    await c.admin('notify', {
      'notification_type': 'EXPIRED',
      'original_transaction_id':
          ((await c.admin('state')).data['transactions']! as List)
              .cast<Map<String, Object?>>()
              .firstWhere((t) => t['product_id'] == _pro)['transaction_id'],
    });
    var s = await status(c);
    expect((s['tier'], s['songs_left'], s['clips_left']), ('pack', 10, 3));

    await c.admin('fail_next', {'error_code': 'UPSTREAM_TIMEOUT'});
    final res = await c.generate(model: 'lyria-3.5');
    expect(res.data['credits_charged'], 1);
    expect((await status(c))['songs_left'], 9); // pre-charged
    final failed = await c.waitJob(res.data['job_id']! as String);
    expect(
      (failed['status'], failed['error_code']),
      ('failed', 'UPSTREAM_TIMEOUT'),
    );
    expect((await status(c))['songs_left'], 10); // refunded to the pack

    await advance(c, 31);
    s = await status(c);
    expect((s['tier'], s['songs_left']), ('pack', 10));
  });

  test(
    'subscription lapses after the period: allowance 0, works playable',
    () async {
      final c = await h.device();
      await c.sync([
        txPayload(productId: _pro, appAccountToken: c.appAccountToken),
      ]);
      final job = await makeSong(c);
      expect((await status(c))['songs_left'], 39);
      await advance(c, 31);
      final s = await status(c);
      expect((s['tier'], s['songs_left'], s['reset_at']), ('free', 0, null));
      final data = (await c.job(job)).data;
      expect(data['status'], 'succeeded');
      final audio = await c.raw('GET', data['audio_url']! as String);
      expect(audio.status, 200);
    },
  );

  test('DID_RENEW after lapse restores a fresh period', () async {
    final c = await h.device();
    final tx = txPayload(productId: _pro, appAccountToken: c.appAccountToken);
    await c.sync([tx]);
    await makeSong(c);
    await advance(c, 31);
    expect((await status(c))['tier'], 'free');
    final renew = await c.admin('notify', {
      'notification_type': 'DID_RENEW',
      'original_transaction_id': tx['originalTransactionId'],
    });
    expect(renew.code, 0);
    final s = await status(c);
    expect((s['tier'], s['songs_left'], s['clips_left']), ('pro', 40, 100));
  });

  test('re-syncing the same JWS never double-credits', () async {
    final c = await h.device();
    final pack = txPayload(
      productId: _pack10,
      appAccountToken: c.appAccountToken,
    );
    await c.sync([pack]);
    await c.sync([pack]);
    await c.sync([pack, pack]);
    expect((await status(c))['songs_left'], 10);
  });

  test('REFUND freezes the funding purchase: license DOWNLOAD_LOCKED, '
      'job + audio stay available', () async {
    final c = await h.device();
    final packA = txPayload(
      productId: _pack10,
      appAccountToken: c.appAccountToken,
    );
    await c.sync([packA]);
    final jobA = await makeSong(c);
    final ok = await c.call('GET', '/license/$jobA');
    expect(ok.status, 200);
    expect(ok.headers.contentType?.mimeType, 'application/pdf');

    final packB = txPayload(
      productId: _pack10,
      appAccountToken: c.appAccountToken,
    );
    await c.sync([packB]);
    final refund = await c.admin('notify', {
      'notification_type': 'REFUND',
      'transaction_id': packA['transactionId'],
    });
    expect(refund.code, 0);

    // Pack A's remaining 9 credits are frozen; pack B is intact.
    final s = await status(c);
    expect((s['tier'], s['songs_left']), ('pack', 10));

    final locked = await c.call('GET', '/license/$jobA');
    expect(
      (locked.status, locked.code, locked.errorCode),
      (403, 40310, 'DOWNLOAD_LOCKED'),
    );
    final job = (await c.job(jobA)).data;
    expect(job['status'], 'succeeded');
    expect((await c.raw('GET', job['audio_url']! as String)).status, 200);

    final jobB = await makeSong(c); // funded by pack B → still licensable
    expect((await c.call('GET', '/license/$jobB')).status, 200);
  });

  test(
    'revocationDate in a synced JWS also freezes; free tier cannot license',
    () async {
      final c = await h.device();
      final clip = await c.generate();
      final clipId = clip.data['job_id']! as String;
      await c.waitJob(clipId);
      expect(
        (await c.call('GET', '/license/$clipId')).errorCode,
        'DOWNLOAD_LOCKED',
      );

      final pro = txPayload(
        productId: _pro,
        appAccountToken: c.appAccountToken,
      );
      await c.sync([pro]);
      final song = await makeSong(c);
      expect((await c.call('GET', '/license/$song')).status, 200);
      await c.sync([
        {...pro, 'revocationDate': DateTime.now().millisecondsSinceEpoch},
      ]);
      final s = await status(c);
      expect(s['tier'], 'free');
      expect(
        (await c.call('GET', '/license/$song')).errorCode,
        'DOWNLOAD_LOCKED',
      );
    },
  );

  test('restore on a new device links to the purchasing account', () async {
    final a = await h.device();
    final pro = txPayload(productId: _pro, appAccountToken: a.appAccountToken);
    await a.sync([pro]);
    final job = await makeSong(a);
    expect((await status(a))['songs_left'], 39);

    final b = await h.device(); // new device, new app_account_token
    await b.generate(); // spends one of B's own free clips first
    expect((await status(b))['tier'], 'free');
    final restored = (await b.sync([pro])).data;
    expect(
      (restored['tier'], restored['songs_left'], restored['clips_left']),
      ('pro', 39, 100),
    );
    // Same ledger: spending on B shows on A.
    await makeSong(b);
    expect((await status(a))['songs_left'], 38);
    // B can read (and license) A's works.
    expect((await b.job(job)).data['status'], 'succeeded');
    expect((await b.call('GET', '/license/$job')).status, 200);

    final dump = (await a.admin('state')).data;
    final accounts = (dump['accounts']! as List).cast<Map<String, Object?>>();
    final owner = accounts.firstWhere((x) => x['id'] == a.appAccountToken);
    expect(owner['linked_tokens'], contains(b.appAccountToken));
  });

  test('admin grant = a server-side purchase (ASSN V2) for the latest account', () async {
    final c = await h.device();
    final granted = (await c.admin('grant', {'product_id': 'com.songlet.pack.10'})).data;
    expect(granted['app_account_token'], c.appAccountToken.toLowerCase());
    final synced = (await c.sync(const [])).data;
    expect((synced['tier'], synced['songs_left']), ('pack', 10));

    final pro = (await c.admin('grant', {
      'product_id': 'com.songlet.pro.monthly',
      'app_account_token': c.appAccountToken,
    })).data;
    expect(pro['transaction_id'], startsWith('grant-'));
    final after = (await c.sync(const [])).data;
    expect((after['tier'], after['songs_left'], after['clips_left']), ('pro', 50, 100));
  });
}
