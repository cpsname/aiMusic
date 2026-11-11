// Drives a full signed happy path against a running mock, signing exactly like
// the app's infra_core SignatureInterceptor.
//
//   dart run mock_server/tool/happy_path.dart [http://localhost:8787] [--reset]
import 'dart:io';

import 'package:songlet_mock_server/songlet_mock_music_server.dart';

Future<void> main(List<String> args) async {
  final base = args.firstWhere(
    (a) => a.startsWith('http'),
    orElse: () => 'http://localhost:8787',
  );
  final c = MusicMockClient(baseUrl: base);
  void step(String label, Object? value) => stdout.writeln('✓ $label: $value');
  void check(bool ok, String what) {
    if (!ok) {
      stderr.writeln('✗ $what');
      exit(1);
    }
  }

  try {
    if (args.contains('--reset')) {
      await c.admin('reset');
      await c.admin('config', {'clip_delay_ms': 1500, 'song_delay_ms': 2500});
      step('admin reset + fast delays', 'ok');
    }

    final config = await c.call('GET', '/app/config', auth: false);
    check(config.code == 0, 'app/config $config');
    step('GET /v1/app/config', config.data);

    final attest = await c.attest();
    check(attest.code == 0, 'attest $attest');
    step('POST /v1/attest', 'device_token for ${c.appAccountToken}');

    final free = await c.sync(const []);
    check(free.data['tier'] == 'free', 'free tier $free');
    step('entitlements (free)', free.data);

    final clip = await c.generate();
    check(clip.code == 0, 'generate clip $clip');
    final clipJob = await c.waitJob(
      clip.data['job_id']! as String,
      every: _poll,
    );
    check(clipJob['status'] == 'succeeded', 'clip job $clipJob');
    step('clip ${clip.data['job_id']}', clipJob['audio_url']);
    final head = await c.raw(
      'GET',
      clipJob['audio_url']! as String,
      headers: {'Range': 'bytes=0-1023'},
    );
    check(head.status == 206 && head.bytes.length == 1024, 'range $head');
    step(
      'audio range',
      '${head.headers.value('Content-Range')} '
          '${head.headers.contentType}',
    );

    final now = DateTime.now().toUtc();
    final jws = encodeFixtureJws({
      'transactionId': '${now.millisecondsSinceEpoch}',
      'originalTransactionId': '${now.millisecondsSinceEpoch}',
      'productId': 'com.songlet.pro.monthly',
      'purchaseDate': now.millisecondsSinceEpoch,
      'expiresDate': addMonths(now, 1).millisecondsSinceEpoch,
      'type': 'Auto-Renewable Subscription',
      'appAccountToken': c.appAccountToken,
      'storefront': 'USA',
    });
    final pro = await c.call(
      'POST',
      '/entitlements/sync',
      body: {
        'app_account_token': c.appAccountToken,
        'signed_transactions': [jws],
      },
    );
    check(
      pro.data['songs_left'] == 40 && pro.data['clips_left'] == 100,
      'pro $pro',
    );
    step('entitlements (pro)', pro.data);

    final song = await c.generate(model: 'lyria-3.5');
    check(song.code == 0, 'generate song $song');
    final songJob = await c.waitJob(
      song.data['job_id']! as String,
      every: _poll,
    );
    check(songJob['status'] == 'succeeded', 'song job $songJob');
    step(
      'song ${song.data['job_id']}',
      '${(songJob['structure']! as List).length} sections',
    );

    final after = await c.sync(const []);
    check(after.data['songs_left'] == 39, 'after $after');
    step('entitlements (after song)', after.data);

    final license = await c.call('GET', '/license/${song.data['job_id']}');
    check(license.status == 200, 'license $license');
    step('license', '${license.headers.contentType} ${license.bytes.length} B');
    stdout.writeln('Happy path OK against $base');
  } finally {
    c.close();
  }
}

const Duration _poll = Duration(milliseconds: 500);
