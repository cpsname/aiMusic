import 'package:dio/dio.dart';
import 'package:media_kit/media_kit.dart';

import '../../common/json.dart';
import '../domain/music_generation.dart';
import '../domain/generation_repository.dart';

/// `/v1/generate` + `/v1/jobs/{id}` over the authed business Dio (full
/// infra_core chain: device meta, bearer device token, app signature, clock
/// sync, retry, envelope, logging).
class GenerationRepositoryImpl implements GenerationRepository {
  GenerationRepositoryImpl(this._apiDio);

  final Dio _apiDio;

  @override
  Future<MusicGenerationTicket> submit(MusicGenerationRequest request) async {
    final response = await _apiDio.post<dynamic>(
      '/generate',
      data: request.toJson(),
    );
    final json = asMap(response.data);
    return MusicGenerationTicket(
      jobId: asString(json['job_id']),
      etaSeconds: asInt(json['eta_seconds'], 30),
      creditsCharged: asInt(json['credits_charged']),
    );
  }

  @override
  Future<JobSnapshot> job(String jobId) async {
    final response = await _apiDio.get<dynamic>('/jobs/$jobId');
    return jobFromJson(asMap(response.data));
  }

  @override
  Future<CancelOutcome> cancel(String jobId) async {
    final response = await _apiDio.delete<dynamic>('/jobs/$jobId');
    return CancelOutcome(refunded: asBool(asMap(response.data)['refunded']));
  }
}

JobSnapshot jobFromJson(Map<String, Object?> json) => JobSnapshot(
      status: JobStatus.fromWire(asString(json['status'])),
      audioUrl: asNullableString(json['audio_url']),
      wavUrl: asNullableString(json['wav_url']),
      lyrics: asNullableString(json['lyrics']),
      structure: asMapList(json['structure'])
          .map(
            (s) => LyricSection(
              label: asString(s['section'], asString(s['label'])),
              start: asDouble(s['start']),
              end: asDouble(s['end']),
            ),
          )
          .toList(growable: false),
      errorCode: asNullableString(json['error_code']),
      progress: json['progress'] == null
          ? null
          : asDouble(json['progress']).clamp(0, 1).toDouble(),
      queuePosition: json['queue_position'] == null
          ? null
          : asInt(json['queue_position']),
      etaSeconds:
          json['eta_seconds'] == null ? null : asInt(json['eta_seconds']),
      lyricsPreview: asStringList(json['lyrics_preview']),
    );

/// [PhotoUploader] over media_kit's two-stage presigned upload (sign → PUT →
/// finalize) — the monolith's generic upload, reused as is.
class MediaKitPhotoUploader implements PhotoUploader {
  MediaKitPhotoUploader(this._uploads);

  final UploadService _uploads;

  @override
  Future<String> upload(List<int> jpeg, {required String filename}) async {
    final result = await _uploads.upload(
      UploadInput(
        bytes: jpeg,
        filename: filename,
        mimeType: 'image/jpeg',
        contentKind: UploadContentKind.image,
      ),
    );
    return result.bid;
  }
}
