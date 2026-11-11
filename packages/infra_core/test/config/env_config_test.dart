import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

EnvConfig _config({
  AppEnv env = AppEnv.dev,
  String baseUrl = 'http://localhost:9999/v1',
  String distributionCode = 'ios_global',
  String distributionSecret = 'secret',
  String appCode = 'studio_app',
  String bundleId = 'com.example.studio',
}) =>
    EnvConfig(
      env: env,
      baseUrl: baseUrl,
      distributionCode: distributionCode,
      distributionSecret: distributionSecret,
      appCode: appCode,
      bundleId: bundleId,
      iapChannel: 'appstore',
    );

void main() {
  group('EnvConfig', () {
    test('isComplete is false when any signing field is empty', () {
      expect(_config().isComplete, isTrue);
      expect(_config(distributionSecret: '').isComplete, isFalse);
      expect(_config(baseUrl: '').isComplete, isFalse);
      expect(_config(distributionCode: '').isComplete, isFalse);
    });

    test('missingKeys names the empty fields in config-file spelling', () {
      // The diagnostic the startup screen and the build guards both quote —
      // a build launched without --dart-define-from-file has all of them.
      expect(_config().missingKeys, isEmpty);
      expect(
        _config(distributionSecret: '').missingKeys,
        ['DISTRIBUTION_SECRET'],
      );
      expect(
        _config(
          baseUrl: '',
          distributionCode: '',
          distributionSecret: '',
          appCode: '',
          bundleId: '',
        ).missingKeys,
        [
          'BASE_URL',
          'DISTRIBUTION_CODE',
          'DISTRIBUTION_SECRET',
          'APP_CODE',
          'BUNDLE_ID',
        ],
      );
    });

    test('legal fallback URLs default empty and never gate startup', () {
      // TERMS_URL / PRIVACY_URL are store-build-guard concerns (App Review
      // 3.1.2 fallbacks), not signing-critical keys: their absence must not
      // produce a ConfigFailure at boot.
      expect(_config().termsUrl, isEmpty);
      expect(_config().privacyUrl, isEmpty);
      expect(_config().isComplete, isTrue);
      expect(_config().missingKeys, isEmpty);
    });

    test('logging is enabled outside production only', () {
      expect(_config().loggingEnabled, isTrue);
      expect(_config(env: AppEnv.staging).loggingEnabled, isTrue);
      expect(_config(env: AppEnv.prod).loggingEnabled, isFalse);
    });

    test('environment flags', () {
      expect(_config(env: AppEnv.prod).isProd, isTrue);
      expect(_config().isDev, isTrue);
      expect(_config(env: AppEnv.staging).isStaging, isTrue);
    });

    test('toString never leaks the secret', () {
      final text = _config(distributionSecret: 'supersecret-value').toString();
      expect(text.contains('supersecret-value'), isFalse);
      expect(text.contains('***'), isTrue);
    });
  });

  group('ApiConfig.forEnv', () {
    test('prod has longer timeouts and more retries than dev', () {
      final prod = ApiConfig.forEnv(AppEnv.prod);
      final dev = ApiConfig.forEnv(AppEnv.dev);
      expect(prod.receiveTimeout, greaterThan(dev.receiveTimeout));
      expect(prod.maxRetries, greaterThan(dev.maxRetries));
    });

    test('maxRetries equals the backoff length', () {
      final config = ApiConfig.forEnv(AppEnv.dev);
      expect(config.maxRetries, config.retryBackoff.length);
    });

    test('default retryable status codes include 429 and 5xx transients', () {
      expect(
        ApiConfig.defaultRetryableStatusCodes,
        containsAll(<int>[408, 429, 500, 502, 503, 504]),
      );
    });
  });
}
