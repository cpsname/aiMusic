import 'package:dio/dio.dart';

import '../../common/json.dart';
import '../../creation/domain/generation.dart';
import '../../store/domain/quota_offer.dart';
import '../domain/mv.dart';
import '../domain/mv_repository.dart';

/// The MV endpoints over the authed business Dio (the full infra_core chain:
/// device meta, bearer device token, app signature, clock sync, retry,
/// envelope, logging).
class MvRepositoryImpl implements MvRepository {
  MvRepositoryImpl(this._apiDio);

  final Dio _apiDio;

  @override
  Future<MvEstimate> estimate(String jobId, MvLevel level) async {
    final response = await _apiDio.post<dynamic>(
      '/mv/estimate',
      data: <String, Object?>{'job_id': jobId, 'level': level.wire},
    );
    return mvEstimateFromJson(asMap(response.data));
  }

  @override
  Future<MvTicket> create(String jobId, MvRequest request) async {
    final response = await _apiDio.post<dynamic>('/works/$jobId/mv', data: request.toJson());
    final json = asMap(response.data);
    return MvTicket(
      mvId: asString(json['mv_id']),
      etaSeconds: asInt(json['eta_seconds'], 60),
      creditsCharged: asInt(json['credits_charged']),
    );
  }

  @override
  Future<MvSnapshot> mv(String mvId) async {
    final response = await _apiDio.get<dynamic>('/mv/$mvId');
    return mvFromJson(asMap(response.data));
  }

  @override
  Future<MvCancelOutcome> cancel(String mvId) async {
    final response = await _apiDio.delete<dynamic>('/mv/$mvId');
    final json = asMap(response.data);
    return MvCancelOutcome(
      mvId: asString(json['mv_id'], mvId),
      result: MvCancelResult.fromWire(asString(json['outcome'])),
      refunded: asBool(json['refunded']),
      balances: balancesFromJson(json['balances']),
    );
  }
}

MvBalances? balancesFromJson(Object? raw) {
  if (raw is! Map) return null;
  final json = asMap(raw);
  return MvBalances(songsLeft: asInt(json['songs_left']), clipsLeft: asInt(json['clips_left']));
}

MvSnapshot mvFromJson(Map<String, Object?> json) {
  final segments = json['segments'];
  final segmentsJson = segments is Map ? asMap(segments) : null;
  return MvSnapshot(
    status: JobStatus.fromWire(asString(json['status'])),
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

MvEstimate mvEstimateFromJson(Map<String, Object?> json) => MvEstimate(
      level: MvLevel.fromWire(asNullableString(json['level'])) ?? MvLevel.lyricVideo,
      credits: asInt(json['credits']),
      availableCredits: asInt(json['available_credits']),
      affordable: asBool(json['affordable']),
      gapCredits: asInt(json['gap_credits']),
      recommendedProductId: asNullableString(json['recommended_product_id']),
      songLocked: asBool(json['song_locked']),
      offer: QuotaOffer.fromWire(asNullableString(json['offer'])),
    );
