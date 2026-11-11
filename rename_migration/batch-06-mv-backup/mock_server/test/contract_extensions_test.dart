import 'dart:io';

import 'package:songlet_mock_server/songlet_mock_server.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Contract extensions handed to the platform repo (ADR-0008, -0010, -0012):
/// templates, template/custom generate, job progress, cancel, WAV, license
/// headers — and the v1.1 music-video change set (ADR-0020).
void main() {
  final h = Harness()..install(clipDelayMs: 400, songDelayMs: 400);

  Future<int> clipsLeft(SongletMockClient c) async => (await c.sync(const [])).data['clips_left']! as int;

  test('GET /v1/templates lists a playable sample per template', () async {
    final c = await h.device();
    final res = await c.templates();
    final list = (res.data['templates']! as List).cast<Map<String, Object?>>();
    expect(list, hasLength(16));
    expect(list.first['id'], 'birthday_wish');
    final sample = await HttpClient().getUrl(Uri.parse(list.first['sample_url']! as String));
    final response = await sample.close();
    expect(response.statusCode, 200);
    expect(response.headers.contentType?.mimeType, 'audio/mpeg');
    await response.drain<void>();
  });

  test('v2.1 inspirations: one list of 32 in sort order, {en, zh} copy, stable ids; absent on an older server', () async {
    final c = await h.device();
    final res = await c.templates();
    final list = (res.data['inspirations']! as List).cast<Map<String, Object?>>();
    expect(list, hasLength(32));
    expect(list.map((e) => e['sort']), List.generate(32, (i) => i + 1));
    expect(list.take(16).map((e) => e['slug']), Catalog.templates, reason: 'the 16 templates are entries of the list');
    final wish = list.first;
    expect(wish['name'], {'en': 'Birthday Wish', 'zh': '生日祝福'});
    expect(wish.containsKey('linked_template_id'), isFalse);
    expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(wish['id']! as String), isTrue);
    expect((await c.templates()).data['inspirations'], res.data['inspirations'], reason: 'same content every time');
    for (final e in list) {
      final url = Uri.parse(e['preview_audio_url']! as String);
      expect(url.scheme, 'https');
      expect(url.host, isNot('localhost'), reason: '${e['slug']}: never rebased onto the mock host');
      expect((e['composer']! as Map)['hint'], isA<Map<String, Object?>>());
    }

    await h.client().admin('config', {'inspirations_enabled': false});
    expect((await c.templates()).data.containsKey('inspirations'), isFalse);
  });

  test('v2.1 generate: the scene by slug, top level and first line alike; unknown fields ignored', () async {
    final c = await h.device();
    expect((await c.generate(inspiration: 'birthday_wish')).code, 0);
    expect((await c.generate(inspiration: 'pet_anthem', occasion: 'confession')).code, 0);
    expect((await c.generate(occasion: 'custom')).code, 0, reason: 'free input with keywords');

    final unknown = await c.generate(inspiration: 'not_a_scene');
    expect(unknown.details?['inspiration'], 'unknown inspiration');
    final mismatch = await c.generate(inspiration: 'birthday_wish', occasion: 'wedding');
    expect(mismatch.details?['inspiration'], 'inspiration does not belong to the occasion');

    final other = await h.device();
    final differs = await other.call('POST', '/generate', body: {
      'model': 'lyria-3-clip-preview',
      'occasion': 'birthday',
      'inspiration': 'birthday_wish',
      'region': 'US',
      'prompt': 'inspiration: birthday_party\nvocals: vocals\nlyric_language: en',
      'client_ref': uuidV4(),
    });
    expect(differs.details?['inspiration'], 'inspiration differs from the prompt block');

    // An id or other fields outside the eight are dropped, not rejected.
    final extra = await other.call('POST', '/generate', body: {
      'model': 'lyria-3-clip-preview',
      'occasion': 'birthday',
      'inspiration': 'birthday_wish',
      'inspiration_id': 'cf8ef0e2-9d9d-526e-b8a7-a88242755c54',
      'vocals': 'vocals',
      'region': 'US',
      'prompt': 'inspiration: birthday_wish\nvocals: vocals\nlyric_language: en',
      'client_ref': uuidV4(),
    });
    expect(extra.code, 0);
  });

  test('v2.1 prompt rules: vocals / lyric_language required, no duplicate key, no lyrics on an instrumental, input_required needs words', () async {
    final c = await h.device();
    Future<MockResponse> raw(String prompt, {String? inspiration, String occasion = 'birthday', String? lyrics}) =>
        c.call('POST', '/generate', body: {
          'model': 'lyria-3-clip-preview',
          'occasion': occasion,
          'inspiration': ?inspiration,
          'region': 'US',
          'prompt': prompt,
          'lyrics': ?lyrics,
          'client_ref': uuidV4(),
        });
    expect((await raw('keywords: tea\nlyric_language: en')).details?.containsKey('prompt.vocals'), isTrue);
    expect((await raw('keywords: tea\nvocals: vocals')).details?.containsKey('prompt.lyric_language'), isTrue);
    expect((await raw('keywords: tea\nkeywords: cake\nvocals: vocals\nlyric_language: en')).details?.containsKey('prompt.keywords'), isTrue);
    expect((await raw('keywords: tea\nvocals: instrumental\nlyric_language: en', lyrics: '[Verse]\nla')).details?.containsKey('lyrics'), isTrue);
    final words = await raw('inspiration: text_messages\nvocals: vocals\nlyric_language: en', inspiration: 'text_messages', occasion: 'confession');
    expect(words.details?.containsKey('prompt.description'), isTrue, reason: 'input_required');
    expect((await raw('inspiration: soundscape\nvocals: instrumental\nlyric_language: en', inspiration: 'soundscape', occasion: 'soundtrack')).code, 0,
        reason: 'input_required false: the card alone');
    expect((await raw('recipient: Ana\nvocals: vocals\nlyric_language: en', occasion: 'custom')).details?.containsKey('prompt.description'), isTrue,
        reason: 'a name alone does not make a song');
  });

  test('a queued job reports progress and ETA (never a position); a running one a lyric preview', () async {
    final admin = h.client();
    await admin.admin('config', {'clip_delay_ms': 1200});
    final c = await h.device();
    final id = (await c.generate()).data['job_id']! as String;
    final queued = (await c.job(id)).data;
    expect(queued['status'], 'queued');
    expect(queued.containsKey('queue_position'), isFalse, reason: 'the platform never sends it');
    expect(queued['eta_seconds'], greaterThan(0));
    expect(queued['progress'], lessThan(0.1));
    final running = await c.waitJob(id, until: {'running'});
    expect(running['progress'], inInclusiveRange(0.1, 0.95));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final later = (await c.job(id)).data;
    expect((later['lyrics_preview']! as List), isNotEmpty);
    final done = await c.waitJob(id);
    expect(done['progress'], 1.0);
    expect(done['balances'], {'songs_left': 0, 'clips_left': 2});
  });

  test('cancel while queued refunds; once running it does not (§8.4)', () async {
    final admin = h.client();
    await admin.admin('config', {'clip_delay_ms': 4000});
    final c = await h.device();
    final queued = (await c.generate()).data['job_id']! as String;
    final cancelled = await c.cancelJob(queued);
    expect(cancelled.data['refunded'], isTrue);
    expect(await clipsLeft(c), 3);
    expect((await c.job(queued)).data['error_code'], 'USER_CANCELLED');

    final running = (await c.generate()).data['job_id']! as String;
    await c.waitJob(running, until: {'running'});
    final kept = await c.cancelJob(running);
    expect(kept.data['refunded'], isFalse);
    expect(await clipsLeft(c), 2);
    final tooLate = await c.cancelJob(running);
    expect(tooLate.status, 200, reason: '49300–49349 ride on HTTP 200');
    expect(tooLate.code, 49309);
    expect(tooLate.errorCode, 'JOB_ALREADY_FINISHED');
  });

  test('no WAV link until the WAV switch is on, even for Premier', () async {
    final c = await h.device();
    await h.client().admin('grant', {'product_id': 'com.songlet.premier.monthly', 'app_account_token': c.appAccountToken});
    final id = (await c.generate(model: 'lyria-3.5')).data['job_id']! as String;
    final done = await c.waitJob(id);
    expect(done.containsKey('wav_url'), isFalse);
  });

  test('with the WAV switch on: WAV for Premier full songs; license carries id + issue date', () async {
    await h.client().admin('config', {'wav_enabled': true});
    final c = await h.device();
    await h.client().admin('grant', {'product_id': 'com.songlet.premier.monthly', 'app_account_token': c.appAccountToken});
    final id = (await c.generate(model: 'lyria-3.5')).data['job_id']! as String;
    final done = await c.waitJob(id);
    expect(done['wav_url'], endsWith('.wav'));

    final license = await c.call('GET', '/license/$id');
    expect(license.status, 200);
    expect(license.headers.value('x-license-id'), matches(RegExp(r'^SL-\d{8}-[0-9A-F]{6}$')));
    expect(DateTime.tryParse(license.headers.value('x-license-issued-at') ?? ''), isNotNull);
  });

  test('a Pro full song has no WAV link, switch on or not', () async {
    await h.client().admin('config', {'wav_enabled': true});
    final c = await h.device();
    await h.client().admin('grant', {'product_id': 'com.songlet.pro.monthly', 'app_account_token': c.appAccountToken});
    final id = (await c.generate(model: 'lyria-3.5')).data['job_id']! as String;
    final done = await c.waitJob(id);
    expect(done.containsKey('wav_url'), isFalse);
  });

  group('v1.1 music videos', musicVideoChangeSet);
}

/// Contract v1.1 — music videos (§7 item 9, ADR-0020): estimate, create → real
/// progress → succeed, both cancel outcomes, the credit gap, every MV error
/// code, the served MP4.
void musicVideoChangeSet() {
  final h = Harness()..install();

  Future<String> song(SongletMockClient c) async {
    await h.client().admin('grant', {'product_id': 'com.songlet.pro.monthly', 'app_account_token': c.appAccountToken});
    final id = (await c.generate(model: 'lyria-3.5')).data['job_id']! as String;
    await c.waitJob(id);
    return id;
  }

  Future<int> credits(SongletMockClient c) async {
    final state = (await h.client().admin('state')).data;
    final accounts = (state['accounts']! as List).cast<Map<String, Object?>>();
    final me = accounts.firstWhere((a) => a['id'] == c.appAccountToken);
    return (me['status']! as Map)['credits']! as int;
  }

  test('estimate prices each level for the song; a free guest can afford only the lyric video', () async {
    final c = await h.device();
    final id = await song(c);
    final lyric = (await c.mvEstimate(id, 'lyric_video')).data;
    expect(lyric['credits'], 0);
    expect(lyric['affordable'], isTrue);
    expect(lyric['recommended_product_id'], isNull);
    expect(lyric['song_locked'], isTrue);
    final chorus = (await c.mvEstimate(id, 'chorus_mv')).data;
    expect(chorus['credits'], 2169);
    expect(chorus['available_credits'], 66);
    expect(chorus['affordable'], isFalse);
    expect(chorus['gap_credits'], 2103);
    expect(chorus['recommended_product_id'], 'com.songlet.mv.chorus');
    final full = (await c.mvEstimate(id, 'full_mv')).data;
    expect(full['credits'], 69 * 120);
    expect(full['recommended_product_id'], 'com.songlet.mv.full');
  });

  test('create → queued → stages with real progress and scene counts → succeeded with the video', () async {
    await h.client().admin('config', {'mv_delay_ms': 1500});
    final c = await h.device();
    final id = await song(c);
    await h.client().admin('grant', {'product_id': 'com.songlet.mv.chorus', 'app_account_token': c.appAccountToken});
    expect(await credits(c), 66 + 2395);

    final ticket = await c.mvCreate(id, options: {'aspect_ratio': '16:9', 'subtitles': true, 'chorus': {'start_ms': 44000, 'end_ms': 74000}});
    expect(ticket.code, 0, reason: '$ticket');
    final mvId = ticket.data['mv_id']! as String;
    expect(ticket.data['credits_charged'], 2169);
    expect(ticket.data['eta_seconds'], 2);
    expect(await credits(c), 66 + 2395 - 2169);

    final queued = (await c.mv(mvId)).data;
    expect(queued['status'], 'queued');
    expect(queued['stage'], 'queued');
    expect(queued['progress'], 0.02);
    expect(queued['cancel_requested'], isFalse);

    final rendering = await c.waitMv(mvId, until: {'rendering'});
    expect(rendering['status'], 'running');
    expect(rendering['progress'], inInclusiveRange(0.1, 0.95));
    final segments = rendering['segments']! as Map;
    expect(segments['total'], 3);
    expect(segments['done'], inInclusiveRange(0, 2));
    expect(rendering.containsKey('video_url'), isFalse);

    final done = await c.waitMv(mvId);
    expect(done['status'], 'succeeded');
    expect(done['stage'], 'done');
    expect(done['progress'], 1.0);
    expect(done['ai_label'], 'burned_in');
    expect(done['duration_ms'], 30000);
    expect(done['balances'], isA<Map>());
    final video = await HttpClient().getUrl(Uri.parse(done['video_url']! as String));
    final response = await video.close();
    expect(response.statusCode, 200);
    expect(response.headers.contentType?.mimeType, 'video/mp4');
    await response.drain<void>();
  });

  test('the same client_ref replays the same video (no double charge); a full video charges per second', () async {
    await h.client().admin('config', {'mv_delay_ms': 400});
    final c = await h.device();
    final id = await song(c);
    await h.client().admin('grant', {'product_id': 'com.songlet.mv.full', 'app_account_token': c.appAccountToken});
    final first = (await c.mvCreate(id, level: 'full_mv', clientRef: 'same-ref')).data;
    final again = (await c.mvCreate(id, level: 'full_mv', clientRef: 'same-ref')).data;
    expect(again['mv_id'], first['mv_id']);
    expect(first['credits_charged'], 8280);
    expect(await credits(c), 66 + 12779 - 8280);
    final done = await c.waitMv(first['mv_id']! as String);
    expect(done['duration_ms'], 120000);
  });

  test('QUOTA_EXHAUSTED carries the gap and the pack to buy; nothing is charged', () async {
    final c = await h.device();
    final id = await song(c);
    final res = await c.mvCreate(id);
    expect(res.status, 200, reason: '49303 rides on HTTP 200');
    expect(res.code, 49303);
    expect(res.errorCode, 'QUOTA_EXHAUSTED');
    expect(res.details!['reason'], 'insufficient');
    expect(res.details!['required_credits'], 2169);
    expect(res.details!['available_credits'], 66);
    expect(res.details!['recommended_product_id'], 'com.songlet.mv.chorus');
    expect(await credits(c), 66);
    // The free level never hits the gate.
    expect((await c.mvCreate(id, level: 'lyric_video')).code, 0);
  });

  test('cancel while queued refunds everything; while rendering it is honoured at the next scene, partially refunded', () async {
    await h.client().admin('config', {'mv_delay_ms': 2000});
    final c = await h.device();
    final id = await song(c);
    await h.client().admin('grant', {'product_id': 'com.songlet.mv.full', 'app_account_token': c.appAccountToken});

    final queued = (await c.mvCreate(id)).data['mv_id']! as String;
    final cancelled = (await c.cancelMv(queued)).data;
    expect(cancelled['outcome'], 'cancelled');
    expect(cancelled['refunded'], isTrue);
    expect(await credits(c), 66 + 12779);
    expect((await c.mv(queued)).data['error_code'], 'USER_CANCELLED');

    final running = (await c.mvCreate(id)).data['mv_id']! as String;
    await c.waitMv(running, until: {'rendering'});
    final requested = (await c.cancelMv(running)).data;
    expect(requested['outcome'], 'cancel_requested');
    expect(requested['refunded'], isFalse);
    expect((await c.mv(running)).data['cancel_requested'], isTrue);
    final done = await c.waitMv(running);
    expect(done['status'], 'failed');
    expect(done['error_code'], 'USER_CANCELLED');
    final left = await credits(c);
    expect(left, greaterThan(66 + 12779 - 2169), reason: 'unfinished scenes refunded');
    expect(left, lessThan(66 + 12779), reason: 'finished steps stay charged');
    final tooLate = await c.cancelMv(running);
    expect((tooLate.status, tooLate.code, tooLate.errorCode), (200, 49309, 'JOB_ALREADY_FINISHED'));
  });

  test('MV error codes: not ready, expired, not found, too-long / photos / render via fail_next', () async {
    await h.client().admin('config', {'mv_delay_ms': 300, 'song_delay_ms': 3000});
    final c = await h.device();
    await h.client().admin('grant', {'product_id': 'com.songlet.pro.monthly', 'app_account_token': c.appAccountToken});
    final pending = (await c.generate(model: 'lyria-3.5')).data['job_id']! as String;
    final notReady = await c.mvCreate(pending, level: 'lyric_video');
    expect((notReady.status, notReady.code, notReady.errorCode), (200, 49312, 'MV_SONG_NOT_READY'));
    expect((await c.mvEstimate('job_unknown', 'lyric_video')).errorCode, 'MV_SONG_NOT_READY');

    final missing = await c.mv('mv_unknown');
    expect((missing.status, missing.code, missing.errorCode), (200, 49315, 'MV_NOT_FOUND'));
    expect((await c.cancelMv('mv_unknown')).errorCode, 'MV_NOT_FOUND');

    final id = await song(c);
    for (final (code, numeric) in [
      ('MV_SONG_TOO_LONG', 49313),
      ('MV_PHOTOS_EXPIRED', 49316),
      ('MV_SONG_EXPIRED', 49314),
    ]) {
      await h.client().admin('fail_next', {'error_code': code});
      final res = await c.mvCreate(id, level: 'lyric_video');
      expect((res.status, res.code, res.errorCode), (200, numeric, code), reason: code);
    }
    await h.client().admin('fail_next', {'error_code': 'MV_RENDER_FAILED'});
    final failing = (await c.mvCreate(id, level: 'lyric_video')).data['mv_id']! as String;
    final failed = await c.waitMv(failing);
    expect(failed['status'], 'failed');
    expect(failed['error_code'], 'MV_RENDER_FAILED');

    // Past the 24 h candidate retention the song can no longer be locked
    // (the device token expired too: re-attest at the new clock).
    await h.client().admin('advance_clock', {'days': 2});
    c.clockOffset = const Duration(days: 2);
    expect((await c.attest()).code, 0);
    expect((await c.mvEstimate(id, 'lyric_video')).errorCode, 'MV_SONG_EXPIRED');
  });

  test('validation: level, chorus window (chorus only, 4–60 s), photo bids', () async {
    final c = await h.device();
    final id = await song(c);
    expect((await c.mvCreate(id, level: 'imax')).status, 400);
    expect((await c.mvCreate(id, level: 'full_mv', options: {'chorus': {'start_ms': 0, 'end_ms': 30000}})).status, 400);
    expect((await c.mvCreate(id, options: {'chorus': {'start_ms': 0, 'end_ms': 3000}})).status, 400);
    expect((await c.mvCreate(id, options: {'quality': 'ultra'})).status, 400);
    expect((await c.mvCreate(id, level: 'lyric_video', options: {'photo_bids': ['nope']})).status, 400);
  });

  test('short of credits → the pack is bought → the same client_ref is accepted, charged once', () async {
    final c = await h.device();
    final id = await song(c);
    const ref = 'retry-after-purchase';
    final refused = await c.mvCreate(id, clientRef: ref);
    expect(refused.errorCode, 'QUOTA_EXHAUSTED');
    await h.client().admin('grant', {'product_id': 'com.songlet.mv.chorus', 'app_account_token': c.appAccountToken});
    final accepted = await c.mvCreate(id, clientRef: ref);
    expect(accepted.code, 0);
    expect(accepted.data['credits_charged'], 2169);
    final replay = await c.mvCreate(id, clientRef: ref);
    expect(replay.data['mv_id'], accepted.data['mv_id'], reason: 'idempotent per client_ref');
    expect(await credits(c), 66 + 2395 - 2169, reason: 'charged once');
  });

  test('a reference photo rejected mid-render fails the video at its first scene, fully refunded', () async {
    await h.client().admin('config', {'mv_delay_ms': 400});
    final c = await h.device();
    final id = await song(c);
    await h.client().admin('grant', {'product_id': 'com.songlet.mv.chorus', 'app_account_token': c.appAccountToken});
    await h.client().admin('fail_next', {'error_code': 'IMAGE_REJECTED'});
    final mvId = (await c.mvCreate(id)).data['mv_id']! as String;
    final done = await c.waitMv(mvId);
    expect(done['status'], 'failed');
    expect(done['error_code'], 'IMAGE_REJECTED');
    expect(await credits(c), 66 + 2395, reason: 'nothing kept');
  });

  test('an MV pack purchase makes the account a pack tier', () async {
    final c = await h.device();
    await h.client().admin('grant', {'product_id': 'com.songlet.mv.chorus', 'app_account_token': c.appAccountToken});
    expect((await c.sync(const [])).data['tier'], 'pack');
  });
}
