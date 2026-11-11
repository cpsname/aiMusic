import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  group('MusicOccasion', () {
    test('wire values match the contract', () {
      expect(
        MusicOccasion.values.map((o) => o.wire),
        [
          'birthday', 'anniversary', 'confession', 'wedding',
          'memorial', 'festival', 'brand', 'soundtrack',
        'custom',
        ],
      );
    });

    test('fromWire round-trips and defaults to birthday', () {
      for (final occasion in MusicOccasion.values) {
        expect(MusicOccasion.fromWire(occasion.wire), occasion);
      }
      expect(MusicOccasion.fromWire('bogus'), MusicOccasion.birthday);
    });

    test('brand, soundtrack and a free-form prompt make the recipient optional', () {
      expect(
        MusicOccasion.values.where((o) => !o.requiresRecipient),
        [MusicOccasion.brand, MusicOccasion.soundtrack, MusicOccasion.custom],
      );
    });
  });

  group('MusicFestival.available', () {
    List<MusicFestival> available(String region, [String language = 'en']) =>
        MusicFestival.available(region: region, languageCode: language);

    test('New Year is offered everywhere', () {
      for (final preset in RegionPresets.all) {
        expect(available(preset.code), contains(MusicFestival.newYear));
        expect(available(preset.code, 'zh'), contains(MusicFestival.newYear));
      }
    });

    test('Diwali only in India', () {
      for (final preset in RegionPresets.all) {
        expect(
          available(preset.code).contains(MusicFestival.diwali),
          preset.code == 'IN',
          reason: preset.code,
        );
      }
    });

    test('Lunar New Year only on a zh UI, in any region', () {
      expect(available('US', 'zh'), contains(MusicFestival.lunarNewYear));
      expect(available('JP', 'zh'), contains(MusicFestival.lunarNewYear));
      for (final preset in RegionPresets.all) {
        expect(available(preset.code), isNot(contains(MusicFestival.lunarNewYear)));
        expect(available(preset.code, 'ja'), isNot(contains(MusicFestival.lunarNewYear)));
      }
    });

    test('country festivals follow PRD §11.3', () {
      expect(available('US'), [MusicFestival.newYear, MusicFestival.thanksgiving]);
      expect(available('CA'), [MusicFestival.newYear, MusicFestival.thanksgiving]);
      expect(available('IN'), [MusicFestival.newYear, MusicFestival.diwali]);
      expect(available('BR'), [MusicFestival.newYear, MusicFestival.carnival]);
      expect(available('ID'), [MusicFestival.newYear, MusicFestival.eid]);
      expect(available('TR'), [MusicFestival.newYear, MusicFestival.eid]);
      expect(available('DE'), [MusicFestival.newYear]);
    });

    test('fromWire round-trips; unknown / null → null', () {
      for (final festival in MusicFestival.values) {
        expect(MusicFestival.fromWire(festival.wire), festival);
      }
      expect(MusicFestival.fromWire('halloween'), isNull);
      expect(MusicFestival.fromWire(null), isNull);
    });
  });
}
