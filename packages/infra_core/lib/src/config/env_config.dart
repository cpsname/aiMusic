import 'package:meta/meta.dart';

/// Runtime environment selected at build time.
enum AppEnv { dev, staging, prod }

/// Immutable, environment-scoped application configuration.
///
/// Every field is sourced exclusively from compile-time defines via
/// [String.fromEnvironment] — there are **zero hardcoded secrets in source**
/// (the value is still baked into the built binary). Inject the values with
/// `--dart-define-from-file=config/<env>.json` (or `make run` / `make ipa`).
@immutable
class EnvConfig {
  const EnvConfig({
    required this.env,
    required this.baseUrl,
    required this.distributionCode,
    required this.distributionSecret,
    required this.appCode,
    required this.bundleId,
    required this.iapChannel,
    this.platformBaseUrl = '',
    this.termsUrl = '',
    this.privacyUrl = '',
  });

  /// Builds the config purely from compile-time defines. Const-invoked so the
  /// values are baked from the `--dart-define`/`--dart-define-from-file` inputs.
  factory EnvConfig.fromEnvironment() {
    return EnvConfig(
      env: _parseEnv(const String.fromEnvironment('ENV', defaultValue: 'dev')),
      baseUrl: const String.fromEnvironment('BASE_URL'),
      distributionCode: const String.fromEnvironment('DISTRIBUTION_CODE'),
      distributionSecret: const String.fromEnvironment('DISTRIBUTION_SECRET'),
      appCode: const String.fromEnvironment('APP_CODE'),
      bundleId: const String.fromEnvironment('BUNDLE_ID'),
      iapChannel:
          const String.fromEnvironment('IAP_CHANNEL', defaultValue: 'appstore'),
      // ignore: avoid_redundant_argument_values
      platformBaseUrl: const String.fromEnvironment('PLATFORM_BASE_URL'),
      // The analyzer const-evaluates fromEnvironment to '' (no defines at
      // analysis time) and flags it as matching the parameter default — but at
      // build time the injected value differs, so the argument is load-bearing.
      // ignore: avoid_redundant_argument_values
      termsUrl: const String.fromEnvironment('TERMS_URL'),
      // ignore: avoid_redundant_argument_values
      privacyUrl: const String.fromEnvironment('PRIVACY_URL'),
    );
  }

  final AppEnv env;

  /// The default API host (`BASE_URL`): every request no `EndpointRoute`
  /// claims.
  final String baseUrl;

  /// `PLATFORM_BASE_URL`: the platform's host, for the paths an app routes
  /// there. Optional; empty means [baseUrl]. Read it through
  /// [effectivePlatformBaseUrl].
  final String platformBaseUrl;

  String get effectivePlatformBaseUrl => platformBaseUrl.isEmpty ? baseUrl : platformBaseUrl;
  final String distributionCode;

  /// HMAC secret for app-signature. Never logged, never persisted.
  final String distributionSecret;
  final String appCode;
  final String bundleId;
  final String iapChannel;

  /// Compile-time fallback legal links (App Review 3.1.2): used by the paywall
  /// when `/app/init` supplies no legal URLs, so the Terms/Privacy links can
  /// never silently vanish on a backend misconfiguration. Deliberately **not**
  /// part of [missingKeys]/[isComplete] — the app boots and signs fine without
  /// them (they are required by the store-build guard, not the runtime gate).
  final String termsUrl;
  final String privacyUrl;

  bool get isDev => env == AppEnv.dev;
  bool get isStaging => env == AppEnv.staging;
  bool get isProd => env == AppEnv.prod;

  /// Verbose request/response logging is enabled outside production only.
  bool get loggingEnabled => env != AppEnv.prod;

  /// Config keys carrying no value in this binary, spelled as in
  /// `config/<env>.json`, in a stable order so the diagnostic always reads the
  /// same way. Empty ⇔ [isComplete].
  List<String> get missingKeys => [
        if (baseUrl.isEmpty) 'BASE_URL',
        if (distributionCode.isEmpty) 'DISTRIBUTION_CODE',
        if (distributionSecret.isEmpty) 'DISTRIBUTION_SECRET',
        if (appCode.isEmpty) 'APP_CODE',
        if (bundleId.isEmpty) 'BUNDLE_ID',
      ];

  /// True only when every signing-critical field is present.
  ///
  /// Enforced at startup by `StartupController` — a build launched without
  /// `--dart-define-from-file=config/<env>.json` cannot sign or route a single
  /// `/v1/*` request (the app-signature middleware answers `40110` / `40114` /
  /// `40304`), and no amount of retrying can put a define into a built binary.
  bool get isComplete => missingKeys.isEmpty;

  static AppEnv _parseEnv(String name) => switch (name.toLowerCase()) {
        'prod' || 'production' => AppEnv.prod,
        'staging' || 'stage' => AppEnv.staging,
        // `mock` = dev against the local mock backend (config/mock.json): a
        // separate config file (so Xcode's build-config gate verifies against
        // it), same dev behaviour.
        'dev' || 'mock' => AppEnv.dev,
        _ => AppEnv.dev,
      };

  /// Redacted form safe for logs (never exposes the secret).
  @override
  String toString() =>
      'EnvConfig(env: ${env.name}, baseUrl: $baseUrl, '
      'platformBaseUrl: $effectivePlatformBaseUrl, '
      'distributionCode: $distributionCode, appCode: $appCode, '
      'bundleId: $bundleId, iapChannel: $iapChannel, secret: ***)';
}
