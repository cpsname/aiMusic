import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/creation/data/music_generation_repository_impl.dart';

/// Answers every request with [body] on HTTP 200 — how the platform carries
/// both successes and its 49300–49349 business errors.
class _EnvelopeAdapter implements HttpClientAdapter {
  _EnvelopeAdapter(this.body);

  final Map<String, Object?> body;
  final List<String> methods = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    methods.add('${options.method} ${options.path}');
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
  group('jobFromJson', () {
    test('parses a succeeded job', () {
      final job = jobFromJson({
        'status': 'succeeded',
        'audio_url': 'https://cdn.example.com/a.mp3',
        'lyrics': '[Verse]\nhello',
        'structure': [
          {'section': 'Intro', 'start': 0, 'end': 3.5},
          {'section': 'Verse', 'start': 3.5, 'end': 20},
        ],
      });

      expect(job.status, MusicJobStatus.succeeded);
      expect(job.audioUrl, 'https://cdn.example.com/a.mp3');
      expect(job.lyrics, '[Verse]\nhello');
      expect(job.errorCode, isNull);
      expect(job.structure.map((s) => s.label), ['Intro', 'Verse']);
      expect(job.structure.first.start, 0.0);
      expect(job.structure.first.end, 3.5);
      expect(job.structure.last.end, 20.0);
    });

    test('parses a failed job with its error code', () {
      final job = jobFromJson({'status': 'failed', 'error_code': 'SAFETY_BLOCKED'});
      expect(job.status, MusicJobStatus.failed);
      expect(job.errorCode, 'SAFETY_BLOCKED');
      expect(job.audioUrl, isNull);
      expect(job.structure, isEmpty);
    });

    test('a hint on a running job', () {
      final job = jobFromJson({'status': 'queued', 'error_code': 'UPSTREAM_RATE_LIMITED'});
      expect(job.status, MusicJobStatus.queued);
      expect(job.status.isTerminal, isFalse);
      expect(job.errorCode, 'UPSTREAM_RATE_LIMITED');
    });

    test('degrades loosely typed / missing fields', () {
      final job = jobFromJson({
        'audio_url': '',
        'lyrics': '',
        'structure': [
          {'label': 'Chorus', 'start': '1.5', 'end': 'x'},
          'not a map',
        ],
      });
      expect(job.status, MusicJobStatus.queued);
      expect(job.audioUrl, isNull);
      expect(job.lyrics, isNull);
      expect(job.structure, hasLength(1));
      expect(job.structure.single.label, 'Chorus');
      expect(job.structure.single.start, 1.5);
      expect(job.structure.single.end, 0.0);
    });
  });

  group('MusicJobStatus.fromWire', () {
    test('maps synonyms, unknown → queued', () {
      expect(MusicJobStatus.fromWire('RUNNING'), MusicJobStatus.running);
      expect(MusicJobStatus.fromWire('success'), MusicJobStatus.succeeded);
      expect(MusicJobStatus.fromWire('completed'), MusicJobStatus.succeeded);
      expect(MusicJobStatus.fromWire('error'), MusicJobStatus.failed);
      expect(MusicJobStatus.fromWire('whatever'), MusicJobStatus.queued);
      expect(MusicJobStatus.succeeded.isTerminal, isTrue);
      expect(MusicJobStatus.failed.isTerminal, isTrue);
      expect(MusicJobStatus.running.isTerminal, isFalse);
    });
  });

  group('MusicSongModel', () {
    test('wire values and fromWire', () {
      expect(MusicSongModel.clip.wire, 'lyria-3-clip-preview');
      expect(MusicSongModel.fullSong.wire, 'lyria-3.5');
      expect(MusicSongModel.fromWire('lyria-3.5'), MusicSongModel.fullSong);
      expect(MusicSongModel.fromWire('lyria-3-clip-preview'), MusicSongModel.clip);
      expect(MusicSongModel.fromWire('other'), MusicSongModel.clip);
    });
  });

  group('cancel', () {
    MusicGenerationRepositoryImpl repository(_EnvelopeAdapter adapter) => MusicGenerationRepositoryImpl(
          Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
            ..httpClientAdapter = adapter
            ..interceptors.add(const EnvelopeInterceptor()),
        );

    test('a refunded cancel', () async {
      final adapter = _EnvelopeAdapter({
        'code': 0,
        'message': 'ok',
        'data': {'job_id': 'j', 'refunded': true},
      });
      final outcome = await repository(adapter).cancel('j');
      expect(outcome.refunded, isTrue);
      expect(adapter.methods, ['DELETE /jobs/j']);
    });

    test('JOB_ALREADY_FINISHED carried on HTTP 200 (platform, 2026-09-28)', () async {
      final adapter = _EnvelopeAdapter({
        'code': 49309,
        'message': 'This song is already finished.',
        'data': null,
        'details': {'error_code': 'JOB_ALREADY_FINISHED'},
      });
      try {
        await repository(adapter).cancel('j');
        fail('expected the envelope error');
      } on Object catch (error, stackTrace) {
        final failure = const ErrorHandler().handle(error, stackTrace);
        expect(MusicErrorCode.of(failure), MusicErrorCode.jobAlreadyFinished);
      }
    });
  });
}
