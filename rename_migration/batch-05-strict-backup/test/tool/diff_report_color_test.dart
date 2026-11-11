import 'package:flutter_test/flutter_test.dart';

import '../../tool/diff_report/color.dart';

/// `tool/diff_report` scores colours with CIEDE2000; checked against the
/// reference pairs of Sharma, Wu & Dalal (2005), Table 1.
void main() {
  test('CIEDE2000 matches the published reference pairs', () {
    const pairs = [
      ((50.0, 2.6772, -79.7751), (50.0, 0.0, -82.7485), 2.0425),
      ((50.0, 3.1571, -77.2803), (50.0, 0.0, -82.7485), 2.8615),
      ((50.0, 0.0, 0.0), (50.0, -1.0, 2.0), 2.3669),
      ((50.0, 2.5, 0.0), (73.0, 25.0, -18.0), 27.1492),
      ((50.0, 2.5, 0.0), (50.0, 3.2592, 0.3350), 1.0000),
      ((60.2574, -34.0099, 36.2677), (60.4626, -34.1751, 39.4387), 1.2644),
      ((2.0776, 0.0795, -1.1350), (0.9033, -0.0636, -0.5514), 0.9082),
    ];
    for (final (p, q, expected) in pairs) {
      final e = deltaE2000(
        (l: p.$1, a: p.$2, b: p.$3),
        (l: q.$1, a: q.$2, b: q.$3),
      );
      expect(e, closeTo(expected, 1e-4), reason: '$p vs $q');
    }
  });

  test('sRGB → Lab: white and a token', () {
    final white = labOfHex('#ffffff');
    expect(white.l, closeTo(100, 1e-3));
    expect(deltaE2000(labOfHex('#c9472b'), labOfHex('#c9472b')), 0);
  });
}
