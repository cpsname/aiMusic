import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/mv/data/mv_repository_impl.dart';

/// Answers every request with [body] on HTTP 200 and records the requests.
class _EnvelopeAdapter implements HttpClientAdapter {
  _EnvelopeAdapter(this.body);

  final Map<String, Object?> body;
  final List<String> calls = [];
  final List<Object?> bodies = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add('${options.method} ${options.path}');
    bodies.add(options.data);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('mvFromJson (contract MvJob)', () {
    test('parses a rendering snapshot with real progress and scene counts', () {
      final mv = mvFromJson({
        'mv_id': '0192c…',
        'level': 'chorus_mv',
        'status': 'running',
        'stage': 'rendering',
        'progress': 0.661,
        'segments': {'done': 1, 'total': 3},
        'cancel_requested': false,
        'eta_seconds': 420,
      });
      expect(mv.status, JobStatus.running);
      expect(mv.stage, 'rendering');
      expect(mv.progress, 0.661);
      expect(mv.segmentsDone, 1);
      expect(mv.segmentsTotal, 3);
      expect(mv.cancelRequested, isFalse);
      expect(mv.etaSeconds, 420);
      expect(mv.videoUrl, isNull);
      expect(mv.balances, isNull);
    });

    test('parses a succeeded snapshot with the video, the burned-in label and balances', () {
      final mv = mvFromJson({
        'status': 'succeeded',
        'stage': 'done',
        'progress': 1.0,
        'cancel_requested': false,
        'video_url': 'https://r2.example/mv.mp4?X-Amz-Expires=3600',
        'duration_ms': 30000,
        'ai_label': 'burned_in',
        'balances': {'songs_left': 0, 'clips_left': 2},
      });
      expect(mv.status, JobStatus.succeeded);
      expect(mv.videoUrl, 'https://r2.example/mv.mp4?X-Amz-Expires=3600');
      expect(mv.durationMs, 30000);
      expect(mv.badgeBurnedIn, isTrue);
      expect(mv.balances?.clipsLeft, 2);
    });

    test('a failed snapshot keeps the job-level error code; a cancel request is a flag', () {
      final failed = mvFromJson({'status': 'failed', 'error_code': 'MV_RENDER_FAILED', 'progress': 0.44});
      expect(failed.status, JobStatus.failed);
      expect(failed.errorCode, 'MV_RENDER_FAILED');
      final pending = mvFromJson({'status': 'running', 'cancel_requested': true});
      expect(pending.cancelRequested, isTrue);
      expect(pending.progress, isNull, reason: 'no snapshot value → no guess');
    });

    test('an unknown stage from a newer platform is passed through', () {
      expect(mvFromJson({'status': 'running', 'stage': 'grading'}).stage, 'grading');
    });
  });

  test('mvEstimateFromJson reads the gap and the recommended pack (null when affordable)', () {
    final gap = mvEstimateFromJson({
      'level': 'full_mv',
      'credits': 8280,
      'available_credits': 66,
      'affordable': false,
      'gap_credits': 8214,
      'recommended_product_id': 'com.songlet.mv.full',
      'song_locked': true,
    });
    expect(gap.level, MvLevel.full);
    expect(gap.credits, 8280);
    expect(gap.gapCredits, 8214);
    expect(gap.recommendedProductId, 'com.songlet.mv.full');
    expect(gap.songLocked, isTrue);
    final ok = mvEstimateFromJson({'level': 'chorus_mv', 'credits': 2169, 'available_credits': 3000, 'affordable': true, 'gap_credits': 0, 'recommended_product_id': null, 'song_locked': true});
    expect(ok.affordable, isTrue);
    expect(ok.recommendedProductId, isNull);
  });

  test('mvEstimateFromJson reads the offer of contract 02 v2.1 (absent on an older server)', () {
    final json = {'level': 'lyric_video', 'credits': 57, 'available_credits': 0, 'affordable': false, 'gap_credits': 57, 'song_locked': true};
    expect(mvEstimateFromJson({...json, 'offer': 'subscription'}).offer, QuotaOffer.subscription);
    expect(mvEstimateFromJson({...json, 'offer': 'packs'}).offer, QuotaOffer.packs);
    expect(mvEstimateFromJson(json).offer, isNull);
    expect(mvEstimateFromJson({...json, 'offer': 'x'}).offer, isNull);
  });

  test('MvRequest serialises only what was chosen (the platform fills the defaults)', () {
    const minimal = MvRequest(level: MvLevel.lyricVideo, clientRef: 'ref-1');
    expect(minimal.toJson(), {'level': 'lyric_video', 'client_ref': 'ref-1'});
    const full = MvRequest(
      level: MvLevel.chorus,
      clientRef: 'ref-2',
      aspectRatio: MvAspectRatio.landscape,
      quality: MvQuality.high,
      subtitles: true,
      photoBids: ['bid-1'],
      chorus: MvChorusWindow(startMs: 44000, endMs: 74000),
    );
    expect(full.toJson(), {
      'level': 'chorus_mv',
      'aspect_ratio': '16:9',
      'quality': 'high',
      'subtitles': true,
      'photo_bids': ['bid-1'],
      'chorus': {'start_ms': 44000, 'end_ms': 74000},
      'client_ref': 'ref-2',
    });
    expect(const MvChorusWindow(startMs: 0, endMs: 3000).isValid, isFalse);
    expect(const MvChorusWindow(startMs: 0, endMs: 61000).isValid, isFalse);
    expect(const MvChorusWindow(startMs: 10000, endMs: 40000).isValid, isTrue);
  });

  group('MvRepositoryImpl', () {
    test('create posts to /works/{job_id}/mv and reads the ticket', () async {
      final adapter = _EnvelopeAdapter({'mv_id': 'mv-9', 'eta_seconds': 600, 'credits_charged': 2169});
      final repo = MvRepositoryImpl(Dio()..httpClientAdapter = adapter);
      final ticket = await repo.create('job-1', const MvRequest(level: MvLevel.chorus, clientRef: 'ref'));
      expect(adapter.calls, ['POST /works/job-1/mv']);
      expect((adapter.bodies.single as Map)['level'], 'chorus_mv');
      expect(ticket.mvId, 'mv-9');
      expect(ticket.etaSeconds, 600);
      expect(ticket.creditsCharged, 2169);
    });

    test('estimate posts job_id + level; cancel reads the outcome', () async {
      final adapter = _EnvelopeAdapter({'level': 'chorus_mv', 'credits': 2169, 'available_credits': 66, 'affordable': false, 'gap_credits': 2103, 'recommended_product_id': 'com.songlet.mv.chorus', 'song_locked': true});
      final repo = MvRepositoryImpl(Dio()..httpClientAdapter = adapter);
      final estimate = await repo.estimate('job-1', MvLevel.chorus);
      expect(adapter.calls, ['POST /mv/estimate']);
      expect(adapter.bodies.single, {'job_id': 'job-1', 'level': 'chorus_mv'});
      expect(estimate.gapCredits, 2103);

      final cancelAdapter = _EnvelopeAdapter({'mv_id': 'mv-9', 'outcome': 'cancel_requested', 'refunded': false, 'balances': {'songs_left': 0, 'clips_left': 3}});
      final outcome = await MvRepositoryImpl(Dio()..httpClientAdapter = cancelAdapter).cancel('mv-9');
      expect(cancelAdapter.calls, ['DELETE /mv/mv-9']);
      expect(outcome.result, MvCancelResult.cancelRequested);
      expect(outcome.refunded, isFalse);
      expect(outcome.balances?.clipsLeft, 3);
    });
  });
}
