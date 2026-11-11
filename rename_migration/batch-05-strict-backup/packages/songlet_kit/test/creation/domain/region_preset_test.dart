import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  group('RegionPresets.all', () {
    test('has exactly the 14 launch countries, wave 1 first', () {
      expect(
        RegionPresets.all.map((p) => p.code),
        ['US', 'GB', 'CA', 'AU', 'DE', 'FR', 'JP', 'KR', 'BR', 'MX', 'IN', 'ID', 'VN', 'TR'],
      );
      final waves = RegionPresets.all.map((p) => p.wave).toList();
      expect(waves, [...waves]..sort());
      expect(waves.where((w) => w == 1), hasLength(7));
    });

    test('every preset has exactly 3 distinct genres, languages and instruments', () {
      for (final preset in RegionPresets.all) {
        expect(preset.genres, hasLength(3), reason: preset.code);
        expect(preset.genres.toSet(), hasLength(3), reason: preset.code);
        expect(preset.languages, isNotEmpty, reason: preset.code);
        expect(preset.instruments, isNotEmpty, reason: preset.code);
        expect(preset.alpha3, hasLength(3), reason: preset.code);
        expect(preset.flag, isNotEmpty, reason: preset.code);
      }
    });

    test('codes are unique in both forms', () {
      expect(RegionPresets.all.map((p) => p.code).toSet(), hasLength(14));
      expect(RegionPresets.all.map((p) => p.alpha3).toSet(), hasLength(14));
    });

    test('carries the PRD §7.3 values', () {
      final us = RegionPresets.byCode('US')!;
      expect(us.genres, ['Indie Pop', 'Contemporary R&B', 'Alternative Country']);
      expect(us.instruments, 'Warm Acoustic Guitar, Rhodes Piano');

      final ca = RegionPresets.byCode('CA')!;
      expect(ca.languages, [LyricLanguage.en, LyricLanguage.fr]);

      final india = RegionPresets.byCode('IN')!;
      expect(india.languages, [LyricLanguage.hi, LyricLanguage.en]);
      expect(india.primaryLanguage, LyricLanguage.hi);
      expect(india.genres, ['Bhangra', 'Indian Classical', 'Indie Pop']);

      expect(RegionPresets.byCode('BR')!.primaryLanguage, LyricLanguage.ptBR);
      expect(RegionPresets.byCode('MX')!.primaryLanguage, LyricLanguage.esMX);
    });

    test('pricing tier follows the storefront', () {
      expect(RegionPresets.byCode('US')!.pricingTier, PricingTier.t1);
      expect(RegionPresets.byCode('KR')!.pricingTier, PricingTier.t1);
      expect(RegionPresets.byCode('BR')!.pricingTier, PricingTier.t2);
      expect(RegionPresets.byCode('TR')!.pricingTier, PricingTier.t2);
      expect(RegionPresets.byCode('IN')!.pricingTier, PricingTier.t3);
    });
  });

  group('byCode', () {
    test('looks up alpha-2 and alpha-3, case-insensitively', () {
      expect(RegionPresets.byCode('JP')!.alpha3, 'JPN');
      expect(RegionPresets.byCode('JPN')!.code, 'JP');
      expect(RegionPresets.byCode('jp')!.code, 'JP');
      expect(RegionPresets.byCode('gbr')!.code, 'GB');
      for (final preset in RegionPresets.all) {
        expect(RegionPresets.byCode(preset.code), same(preset));
        expect(RegionPresets.byCode(preset.alpha3), same(preset));
      }
    });

    test('unknown or null → null', () {
      expect(RegionPresets.byCode(null), isNull);
      expect(RegionPresets.byCode(''), isNull);
      expect(RegionPresets.byCode('ES'), isNull);
      expect(RegionPresets.byCode('CHN'), isNull);
    });
  });

  group('defaultFor', () {
    test('storefront wins over the device region', () {
      expect(
        RegionPresets.defaultFor(storefrontAlpha3: 'JPN', deviceRegion: 'DE').code,
        'JP',
      );
    });

    test('device region when the storefront is unknown or unsupported', () {
      expect(RegionPresets.defaultFor(deviceRegion: 'DE').code, 'DE');
      expect(
        RegionPresets.defaultFor(storefrontAlpha3: 'ESP', deviceRegion: 'FR').code,
        'FR',
      );
    });

    test('United States as the last resort', () {
      expect(RegionPresets.defaultFor().code, 'US');
      expect(
        RegionPresets.defaultFor(storefrontAlpha3: 'ESP', deviceRegion: 'ES').code,
        'US',
      );
    });
  });

  group('LyricLanguage', () {
    test('fromCode is case-insensitive and exact', () {
      expect(LyricLanguage.fromCode('pt-BR'), LyricLanguage.ptBR);
      expect(LyricLanguage.fromCode('ZH-HANT'), LyricLanguage.zhHant);
      expect(LyricLanguage.fromCode('pt'), isNull);
      expect(LyricLanguage.fromCode(null), isNull);
    });

    test('forLocale maps device locales to the closest sung language', () {
      expect(LyricLanguage.forLocale('pt', countryCode: 'PT'), LyricLanguage.ptBR);
      expect(LyricLanguage.forLocale('es', countryCode: 'ES'), LyricLanguage.esMX);
      expect(LyricLanguage.forLocale('zh'), LyricLanguage.zhHans);
      expect(LyricLanguage.forLocale('zh', scriptCode: 'Hant'), LyricLanguage.zhHant);
      expect(LyricLanguage.forLocale('zh', countryCode: 'tw'), LyricLanguage.zhHant);
      expect(LyricLanguage.forLocale('EN'), LyricLanguage.en);
      expect(LyricLanguage.forLocale('it'), isNull);
    });

    test('baseCode and isCjk', () {
      expect(LyricLanguage.ptBR.baseCode, 'pt');
      expect(LyricLanguage.en.baseCode, 'en');
      expect(
        LyricLanguage.values.where((l) => l.isCjk),
        [LyricLanguage.ja, LyricLanguage.ko, LyricLanguage.zhHans, LyricLanguage.zhHant],
      );
    });
  });
}
