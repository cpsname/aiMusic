import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../../support/songlet_fakes.dart';

void main() {
  group('tryParse', () {
    test('decodes the payload fields; dates are epoch milliseconds (UTC)', () {
      final jws = makeJws({
        'transactionId': '2000000123',
        'originalTransactionId': '2000000001',
        'productId': 'com.songlet.pro.monthly',
        'appAccountToken': '0f8fad5b-d9cb-469f-a165-70867728950e',
        'purchaseDate': 1767225600000,
        'expiresDate': 1769904000000,
        'storefront': 'USA',
        'type': 'Auto-Renewable Subscription',
        'offerType': 1,
      });

      final t = SignedTransaction.tryParse(jws)!;

      expect(t.jws, jws);
      expect(t.transactionId, '2000000123');
      expect(t.originalTransactionId, '2000000001');
      expect(t.productId, 'com.songlet.pro.monthly');
      expect(t.appAccountToken, '0f8fad5b-d9cb-469f-a165-70867728950e');
      expect(t.purchaseDate, DateTime.utc(2026));
      expect(t.purchaseDate!.isUtc, isTrue);
      expect(t.expiresDate, DateTime.utc(2026, 2));
      expect(t.revocationDate, isNull);
      expect(t.isRevoked, isFalse);
      expect(t.storefront, 'USA');
      expect(t.type, 'Auto-Renewable Subscription');
    });

    test('revocationDate marks the transaction revoked', () {
      final t = SignedTransaction.tryParse(
        makeJws({
          'transactionId': '1',
          'productId': 'com.songlet.pack.10',
          'revocationDate': 1767225600000,
        }),
      )!;
      expect(t.isRevoked, isTrue);
      expect(t.revocationDate, DateTime.utc(2026));
    });

    test('originalTransactionId defaults to transactionId; optional fields null', () {
      final t = SignedTransaction.tryParse(
        makeJws({'transactionId': '42', 'productId': 'com.songlet.pack.50'}),
      )!;
      expect(t.originalTransactionId, '42');
      expect(t.appAccountToken, isNull);
      expect(t.purchaseDate, isNull);
      expect(t.expiresDate, isNull);
      expect(t.storefront, isNull);
      expect(t.type, isNull);
    });

    test('accepts numeric ids and padded base64url', () {
      final payload = base64Url.encode(
        utf8.encode(jsonEncode({'transactionId': 7, 'productId': 'p'})),
      );
      final t = SignedTransaction.tryParse('e30.$payload.sig')!;
      expect(t.transactionId, '7');
    });

    test('zero / negative / non-numeric dates are treated as absent', () {
      final t = SignedTransaction.tryParse(
        makeJws({
          'transactionId': '1',
          'productId': 'p',
          'purchaseDate': 0,
          'expiresDate': 'soon',
          'revocationDate': -5,
        }),
      )!;
      expect(t.purchaseDate, isNull);
      expect(t.expiresDate, isNull);
      expect(t.isRevoked, isFalse);
    });

    group('malformed input → null', () {
      String b64(String raw) => base64Url.encode(utf8.encode(raw)).replaceAll('=', '');

      final cases = <String, String>{
        'empty': '',
        'one part': 'abc',
        'two parts': 'a.b',
        'four parts': 'a.b.c.d',
        'payload not base64': 'e30.%%%%.sig',
        'payload not UTF-8': 'e30.${base64Url.encode([0xff, 0xfe, 0xfd])}.sig',
        'payload not JSON': 'e30.${b64('not json')}.sig',
        'payload a JSON array': 'e30.${b64('[1,2]')}.sig',
        'payload a JSON string': 'e30.${b64('"x"')}.sig',
        'missing transactionId': makeJws({'productId': 'p'}),
        'missing productId': makeJws({'transactionId': '1'}),
        'empty ids': makeJws({'transactionId': '', 'productId': ''}),
        'null ids': makeJws({'transactionId': null, 'productId': 'p'}),
      };

      cases.forEach((name, input) {
        test(name, () => expect(SignedTransaction.tryParse(input), isNull));
      });
    });
  });
}
