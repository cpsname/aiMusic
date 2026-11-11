import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/ui/common/music_remote_flags.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  group('config.mv.qualities (contract gap G1)', () {
    test('absent or unreadable = standard only', () {
      expect(MusicRemoteFlags.mvQualitiesFrom(null), [MusicMvQuality.standard]);
      expect(MusicRemoteFlags.mvQualitiesFrom('high'), [MusicMvQuality.standard]);
      expect(MusicRemoteFlags.mvQualitiesFrom({'qualities': 'high'}), [
        MusicMvQuality.standard,
      ]);
    });

    test('offered qualities, standard first, unknown values ignored', () {
      expect(
        MusicRemoteFlags.mvQualitiesFrom({
          'qualities': ['high', 'standard'],
        }),
        [MusicMvQuality.standard, MusicMvQuality.high],
      );
      expect(
        MusicRemoteFlags.mvQualitiesFrom({
          'qualities': ['ultra', 'high', 3],
        }),
        [MusicMvQuality.standard, MusicMvQuality.high],
      );
    });
  });
}
