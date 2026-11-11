import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  group('Occasion', () {
    test('wire values match the contract', () {
      expect(
        Occasion.values.map((o) => o.wire),
        [
          'birthday', 'anniversary', 'confession', 'wedding',
          'memorial', 'festival', 'brand', 'soundtrack',
        'custom',
        ],
      );
    });

    test('fromWire round-trips and defaults to birthday', () {
      for (final occasion in Occasion.values) {
        expect(Occasion.fromWire(occasion.wire), occasion);
      }
      expect(Occasion.fromWire('bogus'), Occasion.birthday);
    });

    test('brand, soundtrack and a free-form prompt make the recipient optional', () {
      expect(
        Occasion.values.where((o) => !o.requiresRecipient),
        [Occasion.brand, Occasion.soundtrack, Occasion.custom],
      );
    });
  });

  group('Festival.available', () {
    List<Festival> available(String region, [String language = 'en']) =>
        Festival.available(region: region, languageCode: language);

    test('New Year is offered everywhere', () {
      for (final preset in RegionPresets.all) {
        expect(available(preset.code), contains(Festival.newYear));
        expect(available(preset.code, 'zh'), contains(Festival.newYear));
      }
    });

    test('Diwali only in India', () {
      for (final preset in RegionPresets.all) {
        expect(
          available(preset.code).contains(Festival.diwali),
          preset.code == 'IN',
          reason: preset.code,
        );
      }
    });

    test('Lunar New Year only on a zh UI, in any region', () {
      expect(available('US', 'zh'), contains(Festival.lunarNewYear));
      expect(available('JP', 'zh'), contains(Festival.lunarNewYear));
      for (final preset in RegionPresets.all) {
        expect(available(preset.code), isNot(contains(Festival.lunarNewYear)));
        expect(available(preset.code, 'ja'), isNot(contains(Festival.lunarNewYear)));
      }
    });

    test('country festivals follow PRD §11.3', () {
      expect(available('US'), [Festival.newYear, Festival.thanksgiving]);
      expect(available('CA'), [Festival.newYear, Festival.thanksgiving]);
      expect(available('IN'), [Festival.newYear, Festival.diwali]);
      expect(available('BR'), [Festival.newYear, Festival.carnival]);
      expect(available('ID'), [Festival.newYear, Festival.eid]);
      expect(available('TR'), [Festival.newYear, Festival.eid]);
      expect(available('DE'), [Festival.newYear]);
    });

    test('fromWire round-trips; unknown / null → null', () {
      for (final festival in Festival.values) {
        expect(Festival.fromWire(festival.wire), festival);
      }
      expect(Festival.fromWire('halloween'), isNull);
      expect(Festival.fromWire(null), isNull);
    });
  });
}
