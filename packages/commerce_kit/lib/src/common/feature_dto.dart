import 'billing.dart';
import 'json.dart';

/// Parses a single `FeatureDTO`, shared by the `/me` and `/wallet` parsers.
WalletFeature featureFromJson(Map<String, dynamic> json) => WalletFeature(
      code: asString(json['feature_code']),
      name: asString(json['feature_name']),
      source: asString(json['source']),
      grantedAt: dateFromEpochSeconds(json['granted_at']),
      expiresAt: dateFromEpochSeconds(json['expires_at']),
    );
