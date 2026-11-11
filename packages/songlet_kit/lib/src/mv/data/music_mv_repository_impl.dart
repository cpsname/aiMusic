import 'package:dio/dio.dart';

import '../../common/json.dart';
import '../../creation/domain/music_generation.dart';
import '../../store/domain/music_quota_offer.dart';
import '../domain/music_mv.dart';
import '../domain/music_mv_repository.dart';

/// The MV endpoints over the authed business Dio (the full infra_core chain:
/// device meta, bearer device token, app signature, clock sync, retry,
/// envelope, logging).
class MusicMvRepositoryImpl implements MusicMvRepository {
  MusicMvRepositoryImpl(this._apiDio);

  final Dio _apiDio;

  @override
  Future<MusicMvEstimate> estimate(String jobId, MusicMvLevel level) async {
    final response = await _apiDio.post<dynamic>(
      '/mv/estimate',
      data: <String, Object?>{'job_id': jobId, 'level': level.wire},
    );
    return mvEstimateFromJson(asMap(response.data));
  }

  @override
  Future<MusicMvTicket> create(String jobId, MusicMvRequest request) async {
    final response = await _apiDio.post<dynamic>('/works/$jobId/mv', data: request.toJson());
    final json = asMap(response.data);
    return MusicMvTicket(
      mvId: asString(json['mv_id']),
      etaSeconds: asInt(json['eta_seconds'], 60),
      creditsCharged: asInt(json['credits_charged']),
    );
  }

  @override
  Future<MusicMvSnapshot> mv(String mvId) async {
    final response = await _apiDio.get<dynamic>('/mv/$mvId');
    return mvFromJson(asMap(response.data));
  }

  @override
  Future<MusicMvCancelOutcome> cancel(String mvId) async {
    final response = await _apiDio.delete<dynamic>('/mv/$mvId');
    final json = asMap(response.data);
    return MusicMvCancelOutcome(
      mvId: asString(json['mv_id'], mvId),
      result: MusicMvCancelResult.fromWire(asString(json['outcome'])),
      refunded: asBool(json['refunded']),
      balances: balancesFromJson(json['balances']),
    );
  }
}

MusicMvBalances? balancesFromJson(Object? raw) {
  if (raw is! Map) return null;
  final json = asMap(raw);
  return MusicMvBalances(songsLeft: asInt(json['songs_left']), clipsLeft: asInt(json['clips_left']));
}

MusicMvSnapshot mvFromJson(Map<String, Object?> json) {
  final segments = json['segments'];
  final segmentsJson = segments is Map ? asMap(segments) : null;
  return MusicMvSnapshot(
    status: MusicJobStatus.fromWire(asString(json['status'])),
    stage: asNullableString(json['stage']),
    progress: json['progress'] == null ? null : asDouble(json['progress']).clamp(0, 1).toDouble(),
    segmentsDone: segmentsJson == null ? null : asInt(segmentsJson['done']),
    segmentsTotal: segmentsJson == null ? null : asInt(segmentsJson['total']),
    cancelRequested: asBool(json['cancel_requested']),
    etaSeconds: json['eta_seconds'] == null ? null : asInt(json['eta_seconds']),
    videoUrl: asNullableString(json['video_url']),
    durationMs: json['duration_ms'] == null ? null : asInt(json['duration_ms']),
    aiLabel: asNullableString(json['ai_label']),
    errorCode: asNullableString(json['error_code']),
    balances: balancesFromJson(json['balances']),
  );
}

MusicMvEstimate mvEstimateFromJson(Map<String, Object?> json) => MusicMvEstimate(
      level: MusicMvLevel.fromWire(asNullableString(json['level'])) ?? MusicMvLevel.lyricVideo,
      credits: asInt(json['credits']),
      availableCredits: asInt(json['available_credits']),
      affordable: asBool(json['affordable']),
      gapCredits: asInt(json['gap_credits']),
      recommendedProductId: asNullableString(json['recommended_product_id']),
      songLocked: asBool(json['song_locked']),
      offer: MusicQuotaOffer.fromWire(asNullableString(json['offer'])),
    );
