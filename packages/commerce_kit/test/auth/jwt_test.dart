import 'package:commerce_kit/src/auth/domain/jwt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auth_fakes.dart';

void main() {
  group('JwtUtils', () {
    test('decodes abid and exp', () {
      final exp = DateTime.utc(2030);
      final claims = JwtUtils.decode(makeJwt(exp: exp, subject: 'acc-9'));
      expect(claims.subject, 'acc-9');
      expect(claims.expiresAt, exp);
    });

    test('isExpired honours the skew window', () {
      final now = DateTime.utc(2026, 1, 1, 12);
      final soon = makeJwt(exp: now.add(const Duration(seconds: 30)));
      final later = makeJwt(exp: now.add(const Duration(minutes: 30)));
      expect(JwtUtils.isExpired(soon, now: now), isTrue); // within 60s skew
      expect(JwtUtils.isExpired(later, now: now), isFalse);
    });

    test('a malformed token is treated as expired', () {
      expect(JwtUtils.isExpired('not-a-jwt'), isTrue);
      expect(JwtUtils.decode('not-a-jwt').subject, isNull);
    });

    test('isProvablyExpired: true only for a decodable, past-exp JWT', () {
      final now = DateTime.utc(2026, 1, 1, 12);
      expect(
        JwtUtils.isProvablyExpired(makeJwt(exp: DateTime.utc(2000)), now: now),
        isTrue, // decodable + past → provably expired
      );
      expect(
        JwtUtils.isProvablyExpired(makeJwt(exp: DateTime.utc(2030)), now: now),
        isFalse, // decodable + future → not expired
      );
      // Opaque / non-JWT refresh tokens can't be proven expired → false, so the
      // caller still attempts the refresh.
      expect(JwtUtils.isProvablyExpired('opaque-refresh-token'), isFalse);
    });
  });
}
