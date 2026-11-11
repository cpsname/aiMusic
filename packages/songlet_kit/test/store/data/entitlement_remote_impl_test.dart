import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/store/data/music_entitlement_remote_impl.dart';

void main() {
  group('entitlementFromJson', () {
    test('parses the sync response', () {
      final e = entitlementFromJson({
        'tier': 'pro',
        'songs_left': 38,
        'clips_left': 97,
        'reset_at': '2026-10-01T00:00:00Z',
      });

      expect(e.tier, MusicTier.pro);
      expect(e.songsLeft, 38);
      expect(e.clipsLeft, 97);
      expect(e.resetAt, DateTime.utc(2026, 10));
      expect(e.resetAt!.isUtc, isTrue);
    });

    test('an offset reset_at is normalized to UTC', () {
      final e = entitlementFromJson({
        'tier': 'premier',
        'reset_at': '2026-10-01T09:00:00+09:00',
      });
      expect(e.resetAt, DateTime.utc(2026, 10));
      expect(e.resetAt!.isUtc, isTrue);
    });

    test('null / missing / unparseable reset_at → null', () {
      expect(entitlementFromJson({'tier': 'pro', 'reset_at': null}).resetAt, isNull);
      expect(entitlementFromJson({'tier': 'pro'}).resetAt, isNull);
      expect(entitlementFromJson({'tier': 'pro', 'reset_at': 'soon'}).resetAt, isNull);
    });

    test('loosely typed counters and unknown tiers degrade', () {
      final e = entitlementFromJson({
        'tier': 'gold',
        'songs_left': '12',
        'clips_left': 3.0,
      });
      expect(e.tier, MusicTier.free);
      expect(e.songsLeft, 12);
      expect(e.clipsLeft, 3);

      final empty = entitlementFromJson(const {});
      expect(empty, MusicEntitlement.unknown);
    });

    test('credits_available is optional (contract gap G5): absent = unknown', () {
      expect(entitlementFromJson({'tier': 'premier'}).creditsAvailable, isNull);
      expect(entitlementFromJson({'tier': 'premier', 'credits_available': null}).creditsAvailable, isNull);
      expect(entitlementFromJson({'tier': 'premier', 'credits_available': 1850}).creditsAvailable, 1850);
      expect(entitlementFromJson({'tier': 'premier', 'credits_available': '66'}).creditsAvailable, 66);
    });

    test('pack tier', () {
      expect(entitlementFromJson({'tier': 'pack', 'songs_left': 10}).tier, MusicTier.pack);
    });
  });
}
