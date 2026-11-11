import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet/ui/common/external_links.dart';

EnvConfig _env({String termsUrl = '', String privacyUrl = ''}) => EnvConfig(
  env: AppEnv.dev,
  baseUrl: 'http://localhost:9999/v1',
  distributionCode: 'ios_global',
  distributionSecret: 'secret',
  appCode: 'studio_app',
  bundleId: 'com.example.studio',
  iapChannel: 'appstore',
  termsUrl: termsUrl,
  privacyUrl: privacyUrl,
);

void main() {
  group('effectiveLegalInfo', () {
    test('server-supplied links win over every fallback', () {
      final legal = effectiveLegalInfo(
        server: const LegalInfo(
          termsUrl: 'https://s.example/terms',
          privacyUrl: 'https://s.example/privacy',
          subscriptionTermsUrl: 'https://s.example/sub',
        ),
        env: _env(
          termsUrl: 'https://cfg.example/terms',
          privacyUrl: 'https://cfg.example/privacy',
        ),
        isAndroid: false,
      );
      expect(legal.termsUrl, 'https://s.example/terms');
      expect(legal.privacyUrl, 'https://s.example/privacy');
      expect(legal.subscriptionTermsUrl, 'https://s.example/sub');
    });

    test(
      'no server legal → compile-time TERMS_URL / PRIVACY_URL back it up',
      () {
        final legal = effectiveLegalInfo(
          server: null,
          env: _env(
            termsUrl: 'https://cfg.example/terms',
            privacyUrl: 'https://cfg.example/privacy',
          ),
          isAndroid: false,
        );
        expect(legal.termsUrl, 'https://cfg.example/terms');
        expect(legal.privacyUrl, 'https://cfg.example/privacy');
        // Subscription terms are server-only: no generic fallback exists.
        expect(legal.subscriptionTermsUrl, isNull);
      },
    );

    test('empty server strings count as absent, not as a supplied link', () {
      final legal = effectiveLegalInfo(
        server: const LegalInfo(termsUrl: '', privacyUrl: ''),
        env: _env(privacyUrl: 'https://cfg.example/privacy'),
        isAndroid: false,
      );
      expect(legal.termsUrl, appleStandardEulaUrl);
      expect(legal.privacyUrl, 'https://cfg.example/privacy');
    });

    test('Apple platforms fall back to the standard EULA for terms as a last '
        'resort (3.1.2: the link must never vanish)', () {
      final legal = effectiveLegalInfo(
        server: null,
        env: _env(),
        isAndroid: false,
      );
      expect(legal.termsUrl, appleStandardEulaUrl);
      expect(legal.privacyUrl, isNull);
    });

    test('Android never falls back to the Apple EULA', () {
      final legal = effectiveLegalInfo(
        server: null,
        env: _env(),
        isAndroid: true,
      );
      expect(legal.termsUrl, isNull);
    });
  });
}
