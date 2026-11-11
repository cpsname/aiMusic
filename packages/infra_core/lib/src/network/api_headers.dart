/// Canonical header names used across the request chain.
abstract final class ApiHeaders {
  // App-signature chain (overview §5).
  static const String distributionCode = 'X-Distribution-Code';
  static const String timestamp = 'X-Timestamp';
  static const String nonce = 'X-Nonce';
  static const String appSignature = 'X-App-Signature';

  // Bearer auth.
  static const String authorization = 'Authorization';

  // Request meta (overview §3.2).
  static const String deviceId = 'X-Device-ID';
  static const String platform = 'X-Platform';
  static const String appVersion = 'X-App-Version';
  static const String appBuild = 'X-App-Build';
  static const String osVersion = 'X-Os-Version';
  static const String deviceModel = 'X-Device-Model';
  static const String language = 'X-Language';
  static const String timezone = 'X-Timezone';

  // Response meta.
  /// Server's authoritative wall clock (Unix ms, UTC). Drives clock-skew
  /// correction for request signing (see `ClockOffsetService`).
  static const String serverTime = 'X-Server-Time';
}
