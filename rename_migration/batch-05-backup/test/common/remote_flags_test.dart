import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/ui/common/remote_flags.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  group('config.mv.qualities (contract gap G1)', () {
    test('absent or unreadable = standard only', () {
      expect(RemoteFlags.mvQualitiesFrom(null), [MvQuality.standard]);
      expect(RemoteFlags.mvQualitiesFrom('high'), [MvQuality.standard]);
      expect(RemoteFlags.mvQualitiesFrom({'qualities': 'high'}), [
        MvQuality.standard,
      ]);
    });

    test('offered qualities, standard first, unknown values ignored', () {
      expect(
        RemoteFlags.mvQualitiesFrom({
          'qualities': ['high', 'standard'],
        }),
        [MvQuality.standard, MvQuality.high],
      );
      expect(
        RemoteFlags.mvQualitiesFrom({
          'qualities': ['ultra', 'high', 3],
        }),
        [MvQuality.standard, MvQuality.high],
      );
    });
  });
}
