import 'package:meta/meta.dart';

import 'env_config.dart';

/// Per-environment HTTP timeouts and retry policy. These are operational
/// parameters (not secrets), so presets are defined in code.
@immutable
class ApiConfig {
  const ApiConfig({
    required this.connectTimeout,
    required this.sendTimeout,
    required this.receiveTimeout,
    required this.retryBackoff,
    this.retryableStatusCodes = defaultRetryableStatusCodes,
  });

  /// Transient HTTP status codes worth retrying (idempotent transport faults).
  static const Set<int> defaultRetryableStatusCodes = {408, 429, 500, 502, 503, 504};

  factory ApiConfig.forEnv(AppEnv env) => switch (env) {
        AppEnv.prod => const ApiConfig(
            connectTimeout: Duration(seconds: 15),
            sendTimeout: Duration(seconds: 20),
            receiveTimeout: Duration(seconds: 30),
            retryBackoff: [
              Duration(milliseconds: 400),
              Duration(milliseconds: 900),
              Duration(seconds: 2),
            ],
          ),
        AppEnv.staging || AppEnv.dev => const ApiConfig(
            connectTimeout: Duration(seconds: 10),
            sendTimeout: Duration(seconds: 15),
            receiveTimeout: Duration(seconds: 20),
            retryBackoff: [
              Duration(milliseconds: 300),
              Duration(milliseconds: 800),
            ],
          ),
      };

  final Duration connectTimeout;
  final Duration sendTimeout;
  final Duration receiveTimeout;

  /// Per-attempt delays; its length is the maximum number of retries.
  final List<Duration> retryBackoff;
  final Set<int> retryableStatusCodes;

  int get maxRetries => retryBackoff.length;
}
