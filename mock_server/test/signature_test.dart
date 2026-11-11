import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:songlet_mock_server/songlet_mock_music_server.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('canonical JSON + HMAC (byte-compatible with infra_core)', () {
    test('keys sorted recursively, compact, empty body is {}', () {
      // Go-style HTML-safe escapes (backslash-u003c), built at runtime.
      final bs = String.fromCharCode(0x5c);
      expect(canonicalJson(null), '{}');
      expect(canonicalJson(<String, Object?>{}), '{}');
      expect(
        canonicalJson({
          'b': 1,
          'a': {'z': true, 'y': null},
          'c': [2.0, 'x<y&z'],
        }),
        '{"a":{"y":null,"z":true},"b":1,"c":[2,"x${bs}u003cy${bs}u0026z"]}',
      );
    });

    test('signature = hex(HMAC_SHA256(secret, ts + nonce + canonical))', () {
      final expected = Hmac(
        sha256,
        utf8.encode('s3cret'),
      ).convert(utf8.encode('1700000000n-1{"a":1,"b":"x"}')).toString();
      expect(
        computeAppSignature(
          secret: 's3cret',
          timestamp: '1700000000',
          nonce: 'n-1',
          body: {'b': 'x', 'a': 1},
        ),
        expected,
      );
    });
  });

  group('server verification', () {
    final h = MusicHarness()..install();

    test('a correctly signed GET (body {}) passes', () async {
      final res = await h.client().call('GET', '/app/config', auth: false);
      expect(res.status, 200);
      expect(res.code, 0);
      expect(res.data['maintenance'], {'active': false});
      expect(res.data['kill_switches'], isEmpty);
      expect(
        int.parse(res.headers.value('X-Server-Time')!),
        closeTo(DateTime.now().millisecondsSinceEpoch, 5000),
      );
    });

    test('wrong secret → 40114, HTTP 401, no details.error_code', () async {
      final res = await h.client().call(
        'POST',
        '/attest',
        auth: false,
        body: {'app_account_token': 'x', 'challenge': 'y'},
        secretOverride: 'wrong',
      );
      expect(res.status, 401);
      expect(res.code, 40114);
      expect(res.json['details'], isNull);
      expect(res.headers.value('X-Server-Time'), isNotNull);
    });

    test(
      'unsigned → 40110; stale timestamp → 40112; replayed nonce → 40113',
      () async {
        final c = h.client();
        final unsigned = await c.call('GET', '/app/config', sign: false);
        expect((unsigned.status, unsigned.code), (401, 40110));

        c.clockOffset = const Duration(minutes: -10);
        final stale = await c.call('GET', '/app/config');
        expect((stale.status, stale.code), (401, 40112));
        c.clockOffset = Duration.zero;

        final ts = '${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
        final sig = computeAppSignature(
          secret: MusicMockServer.defaultSecret,
          timestamp: ts,
          nonce: 'fixed',
        );
        final headers = {
          'X-Distribution-Code': 'songlet_ios',
          'X-Timestamp': ts,
          'X-Nonce': 'fixed',
          'X-App-Signature': sig,
        };
        final first = await c.raw('GET', '/v1/app/config', headers: headers);
        final replay = await c.raw('GET', '/v1/app/config', headers: headers);
        expect(first.code, 0);
        expect((replay.status, replay.code), (401, 40113));
      },
    );

    test('the signature covers the body (tampered body → 40114)', () async {
      final c = h.client();
      final ts = '${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
      final sig = computeAppSignature(
        secret: MusicMockServer.defaultSecret,
        timestamp: ts,
        nonce: 'n1',
        body: {'app_account_token': 'a', 'challenge': 'b'},
      );
      final res = await c.raw(
        'POST',
        '/v1/attest',
        json: {'app_account_token': 'EVIL', 'challenge': 'b'},
        headers: {
          'X-Distribution-Code': 'songlet_ios',
          'X-Timestamp': ts,
          'X-Nonce': 'n1',
          'X-App-Signature': sig,
        },
      );
      expect(res.code, 40114);
    });

    test('admin, files and r2 skip the signature', () async {
      final c = h.client();
      expect((await c.admin('state')).code, 0);
      final files = await c.raw('GET', '/files/job_nope.mp3');
      expect(files.status, 404); // reached the handler, not a 401
      final r2 = await c.raw('PUT', '/r2/nope', bytes: [1, 2, 3]);
      expect(r2.status, 404);
    });
  });
}
