import 'package:dio/dio.dart';

import '../../common/json.dart';
import '../domain/entitlement_sync.dart';
import '../domain/music_entitlement.dart';

/// `POST /v1/entitlements/sync` over the authed business Dio.
class EntitlementRemoteImpl implements EntitlementRemote {
  EntitlementRemoteImpl(this._apiDio);

  final Dio _apiDio;

  @override
  Future<MusicEntitlement> sync({
    required String appAccountToken,
    required List<String> signedTransactions,
  }) async {
    final response = await _apiDio.post<dynamic>(
      '/entitlements/sync',
      data: <String, Object?>{
        'app_account_token': appAccountToken,
        'signed_transactions': signedTransactions,
      },
    );
    return entitlementFromJson(asMap(response.data));
  }
}

MusicEntitlement entitlementFromJson(Map<String, Object?> json) {
  final resetAt = asNullableString(json['reset_at']);
  return MusicEntitlement(
    tier: MusicTier.fromWire(asString(json['tier'])),
    songsLeft: asInt(json['songs_left']),
    clipsLeft: asInt(json['clips_left']),
    resetAt: resetAt == null ? null : DateTime.tryParse(resetAt)?.toUtc(),
    creditsAvailable: json['credits_available'] == null ? null : asInt(json['credits_available']),
  );
}
