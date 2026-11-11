import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

/// Builds a `\u` + four-hex-digit escape without a literal unicode escape in source.
String _u(String hex) => '${String.fromCharCode(0x5C)}u$hex';
final String _backslash = String.fromCharCode(0x5C);

void main() {
  group('canonicalJson', () {
    test('null and empty map both encode to the literal {}', () {
      expect(canonicalJson(null), '{}');
      expect(canonicalJson(<String, dynamic>{}), '{}');
    });

    test('sorts object keys lexicographically', () {
      expect(canonicalJson({'b': 2, 'a': 1}), '{"a":1,"b":2}');
    });

    test('sorts keys recursively in nested objects', () {
      final body = {
        'app': {
          'distribution_code': 'ios_global',
          'app_code': 'studio_app',
          'channel': 'appstore',
          'bundle_id': 'com.example.studio',
        },
      };
      expect(
        canonicalJson(body),
        '{"app":{"app_code":"studio_app","bundle_id":"com.example.studio",'
        '"channel":"appstore","distribution_code":"ios_global"}}',
      );
    });

    test('HTML-escapes < > & exactly like Go json.Marshal', () {
      final out = canonicalJson({'k': 'a<b>&c'});
      expect(out.contains('<'), isFalse);
      expect(out.contains('>'), isFalse);
      expect(out.contains('&'), isFalse);
      expect(out, '{"k":"a${_u('003c')}b${_u('003e')}${_u('0026')}c"}');
      // And it must still decode back to the original value.
      expect(jsonDecode(out), {'k': 'a<b>&c'});
    });

    test('uses short escapes for newline/tab and \\u-hex escapes for other controls', () {
      expect(
        canonicalJson({'k': 'a${String.fromCharCode(10)}b'}),
        '{"k":"a${_backslash}nb"}',
      );
      expect(
        canonicalJson({'k': String.fromCharCode(1)}),
        '{"k":"${_u('0001')}"}',
      );
    });

    test('encodes lists in order', () {
      expect(canonicalJson({'xs': [3, 1, 2]}), '{"xs":[3,1,2]}');
    });

    test('encodes booleans and integral doubles', () {
      expect(canonicalJson({'a': true, 'b': false}), '{"a":true,"b":false}');
      expect(canonicalJson({'n': 2.0}), '{"n":2}');
    });
  });
}
