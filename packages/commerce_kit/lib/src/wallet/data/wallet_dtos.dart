import '../../common/billing.dart';
import '../../common/feature_dto.dart';
import '../../common/json.dart';

/// Parses `WalletResponse` from `GET /v1/wallet`. A new guest's wallet returns
/// zeros (not an error), which falls out of the defensive `asInt` defaults.
class WalletResponseDto {
  const WalletResponseDto(this._json);

  factory WalletResponseDto.fromJson(Map<String, dynamic> json) =>
      WalletResponseDto(json);

  final Map<String, dynamic> _json;

  WalletSnapshot toDomain() => WalletSnapshot(
        balance: asInt(_json['balance']),
        frozen: asInt(_json['frozen']),
        totalCredited: asInt(_json['total_credited']),
        totalDebited: asInt(_json['total_debited']),
        features: asMapList(_json['features'])
            .map(featureFromJson)
            .toList(growable: false),
      );
}
