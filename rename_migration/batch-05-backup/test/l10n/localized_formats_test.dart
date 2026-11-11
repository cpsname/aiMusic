import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:songlet/ui/common/localized_formats.dart';

void main() {
  test('percent uses locale spacing, sign order, and fractional input', () {
    for (final locale in ['en', 'de', 'hi', 'vi', 'tr', 'pt_BR', 'zh_Hans']) {
      expect(
        progressPercent(.66, locale),
        NumberFormat.percentPattern(locale).format(.66),
      );
      expect(
        progressPercent(2, locale),
        NumberFormat.percentPattern(locale).format(1),
      );
      expect(
        progressPercent(double.nan, locale),
        NumberFormat.percentPattern(locale).format(0),
      );
    }
    expect(progressPercent(.66, 'tr'), startsWith('%'));
  });
  test(
    'media durations do not wrap, use locale digits, and handle invalid input',
    () {
      expect(mediaDuration(3661, 'en'), '61:01');
      expect(mediaDuration(9.9, 'de'), '0:09');
      expect(mediaDuration(double.infinity, 'hi'), '0:00');
      expect(mediaDuration(-1, 'vi'), '0:00');
      expect(
        mediaDuration(123, 'hi'),
        '${NumberFormat('0', 'hi').format(2)}:${NumberFormat('00', 'hi').format(3)}',
      );
    },
  );
}
