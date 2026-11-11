import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

void main() {
  const signing = SigningService();

  group('SigningService.sign (ground-truth vectors from openssl)', () {
    test('sorted nested body matches HMAC-SHA256', () {
      final sig = signing.sign(
        secret: 'shhh',
        timestamp: '1700000000',
        nonce: 'nonce-123',
        body: {'b': 2, 'a': 1},
      );
      expect(
        sig,
        'bf93a836d51dc7afd2f91327ae0dd658b731e06a41a6a4989c69c4a51359bd21',
      );
    });

    test('null and empty body both sign over {} and match', () {
      final withNull = signing.sign(
        secret: 'shhh',
        timestamp: '1700000000',
        nonce: 'nonce-123',
      );
      final withEmpty = signing.sign(
        secret: 'shhh',
        timestamp: '1700000000',
        nonce: 'nonce-123',
        body: <String, dynamic>{},
      );
      expect(
        withNull,
        '14b2ddeaf2f1d0090d7fbb5cceea140e3e79bb624ffd514a3d26d37142021d3a',
      );
      expect(withEmpty, withNull);
    });

    test('guest-register-shaped body matches (recursive key sort)', () {
      final sig = signing.sign(
        secret: 'topsecret',
        timestamp: '1700000000',
        nonce: 'abc',
        body: {
          'app': {
            'distribution_code': 'ios_global',
            'app_code': 'studio_app',
            'channel': 'appstore',
            'bundle_id': 'com.example.studio',
          },
        },
      );
      expect(
        sig,
        'e6d3f1136b922b03addf0162cf5e011896b8d9850953c9a9ca2c617bb4743679',
      );
    });

    test('output is exactly 64 lowercase hex characters', () {
      final sig = signing.sign(
        secret: 'k',
        timestamp: '1',
        nonce: 'n',
        body: {'x': 1},
      );
      expect(sig, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('signRequest bundles the supplied timestamp/nonce', () {
      final payload = signing.signRequest(
        secret: 'shhh',
        timestamp: '1700000000',
        nonce: 'nonce-123',
        body: {'a': 1, 'b': 2},
      );
      expect(payload.timestamp, '1700000000');
      expect(payload.nonce, 'nonce-123');
      expect(
        payload.signature,
        'bf93a836d51dc7afd2f91327ae0dd658b731e06a41a6a4989c69c4a51359bd21',
      );
    });
  });
}
