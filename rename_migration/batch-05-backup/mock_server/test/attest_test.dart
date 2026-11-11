import 'dart:convert';

import 'package:songlet_mock_server/songlet_mock_server.dart';
import 'package:test/test.dart';

import 'support.dart';

Map<String, Object?> _claims(String jwt) =>
    (jsonDecode(
              utf8.decode(
                base64Url.decode(base64Url.normalize(jwt.split('.')[1])),
              ),
            )
            as Map)
        .cast<String, Object?>();

void main() {
  final h = Harness()..install();

  test(
    'simulator attest issues a device JWT that JwtUtils can decode',
    () async {
      final c = h.client();
      final res = await c.attest();
      expect(res.code, 0);
      expect(res.data['expires_in'], 86400);
      final claims = _claims(c.deviceToken!);
      expect(claims['abid'], c.appAccountToken);
      expect(claims['sub'], c.appAccountToken);
      expect(claims['typ'], 'device');
      final iat = claims['iat']! as int;
      expect(claims['exp'], iat + 86400);
      // Seconds, not millis.
      expect(iat, closeTo(DateTime.now().millisecondsSinceEpoch ~/ 1000, 60));
      expect(c.deviceToken!.split('.'), hasLength(3));
    },
  );

  test('assertion / attestation path needs key_id + proof', () async {
    final c = h.client();
    expect((await c.attest(unsupported: false)).code, 0);
    final noProof = await c.call(
      'POST',
      '/attest',
      auth: false,
      body: {
        'app_account_token': c.appAccountToken,
        'challenge': c.newChallenge(),
        'key_id': 'k',
      },
    );
    expect((noProof.status, noProof.code), (401, 40140));
    expect(noProof.errorCode, 'ATTEST_FAILED');
  });

  test(
    'challenge reuse, skew >5 min and foreign token → ATTEST_FAILED',
    () async {
      final c = h.client();
      final challenge = c.newChallenge();
      expect((await c.attest(challenge: challenge)).code, 0);
      expect((await c.attest(challenge: challenge)).errorCode, 'ATTEST_FAILED');

      final old =
          '${c.appAccountToken}.'
          '${DateTime.now().millisecondsSinceEpoch - 6 * 60 * 1000}.${uuidV4()}';
      expect((await c.attest(challenge: old)).errorCode, 'ATTEST_FAILED');

      final foreign =
          '${uuidV4()}.${DateTime.now().millisecondsSinceEpoch}.${uuidV4()}';
      expect((await c.attest(challenge: foreign)).errorCode, 'ATTEST_FAILED');
    },
  );

  test('admin attest_fail forces ATTEST_FAILED', () async {
    final c = h.client();
    await c.admin('config', {'attest_fail': true});
    final res = await c.attest();
    expect(
      (res.status, res.code, res.errorCode),
      (401, 40140, 'ATTEST_FAILED'),
    );
  });

  test('missing / forged / expired bearer → 40102 HTTP 401', () async {
    final c = await h.device();
    expect((await c.job('job_x')).code, 40404); // valid token reaches handler

    final saved = c.deviceToken;
    c.deviceToken = null;
    final missing = await c.job('job_x');
    expect((missing.status, missing.code), (401, 40102));

    c.deviceToken = '${saved!.substring(0, saved.lastIndexOf('.'))}.forged';
    expect((await c.job('job_x')).code, 40102);

    c.deviceToken = saved;
    await c.admin('advance_clock', {'days': 2});
    c.clockOffset = const Duration(days: 2); // client learned X-Server-Time
    final expired = await c.job('job_x');
    expect((expired.status, expired.code), (401, 40102));

    // Re-attest recovers.
    expect((await c.attest()).code, 0);
    expect((await c.job('job_x')).code, 40404);
  });
}
