import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songlet/l10n/generated/app_localizations.dart';
import 'package:songlet/l10n/ui_locale.dart';
import 'icu_message.dart';

const targetTags = {
  'en',
  'zh-Hans',
  'zh-Hant',
  'ja',
  'ko',
  'de',
  'fr',
  'es',
  'pt-BR',
  'hi',
  'id',
  'vi',
  'tr',
};
Map<String, dynamic> readArb(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
Set<String> messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  setUpAll(initializeDateFormatting);
  final files = Directory(
    'lib/l10n/arb',
  ).listSync().whereType<File>().where((f) => f.path.endsWith('.arb')).toList();
  final source = readArb(File('lib/l10n/arb/app_en.arb'));
  final keys = messageKeys(source);
  test('all 13 target locales have complete resources', () {
    final tags = files
        .map((f) => (readArb(f)['@@locale'] as String).replaceAll('_', '-'))
        .toSet();
    expect(tags.containsAll(targetTags), isTrue);
    expect(files, hasLength(13));
    expect(
      supportedUiLocales.map((l) => l.toLanguageTag()).toSet(),
      targetTags,
    );
  });
  for (final file in files) {
    final arb = readArb(file);
    test(
      '${file.uri.pathSegments.last}: keys, ICU, types, and descriptions',
      () {
        expect(messageKeys(arb), keys);
        for (final key in keys) {
          final text = arb[key];
          expect(text, isA<String>(), reason: key);
          expect((text as String).trim(), isNotEmpty, reason: key);
          final parsed = IcuMessage(text);
          final original = IcuMessage(source[key] as String);
          expect(parsed.placeholders, original.placeholders, reason: key);
          final meta = arb['@$key'] as Map<String, dynamic>;
          expect(meta['description'], isNotEmpty, reason: key);
          final placeholders =
              (meta['placeholders'] as Map<String, dynamic>?) ?? {};
          final expected =
              ((source['@$key'] as Map<String, dynamic>)['placeholders']
                  as Map<String, dynamic>?) ??
              {};
          expect(placeholders.keys.toSet(), parsed.placeholders, reason: key);
          for (final name in parsed.placeholders) {
            final ph = placeholders[name] as Map<String, dynamic>;
            expect(ph['type'], expected[name]['type'], reason: '$key.$name');
            for (final attribute in ['format', 'optionalParameters']) {
              expect(
                ph[attribute],
                expected[name][attribute],
                reason: '$key.$name.$attribute',
              );
            }
            expect(
              {'int', 'String', 'DateTime'},
              contains(ph['type']),
              reason: '$key.$name',
            );
            expect(ph['description'], isNotEmpty, reason: '$key.$name');
            if (parsed.selectors[name] == 'plural') {
              expect(ph['type'], 'int', reason: '$key.$name');
            }
            if (parsed.selectors[name] == 'select') {
              expect(ph['type'], 'String', reason: '$key.$name');
            }
          }
        }
      },
    );
  }
  test('German resources stay within the approved length budget', () {
    final de = readArb(File('lib/l10n/arb/app_de.arb'));
    for (final key in keys) {
      expect(
        (de[key] as String).runes.length,
        lessThanOrEqualTo((source[key] as String).runes.length * 1.4),
        reason: key,
      );
    }
  });
  for (final tag in targetTags) {
    test(
      '$tag loads and formats counts, dates, prices, and notifications',
      () async {
        final subtags = tag.split('-');
        final locale = Locale.fromSubtags(
          languageCode: subtags.first,
          scriptCode: subtags.last.length == 4 ? subtags.last : null,
          countryCode: subtags.length > 1 && subtags.last.length == 2
              ? subtags.last
              : null,
        );
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(l10n.localeName.replaceAll('_', '-'), tag);
        final date = DateTime(2026, 9, 30);
        for (final count in [0, 1, 2, 21, 1000]) {
          for (final text in [
            l10n.paywallRestoreSuccess(count),
            l10n.paywallCurrentPlan(count),
            l10n.settingsSongsLeft(count),
            l10n.settingsClipsLeft(count),
            l10n.planSongs(count),
            l10n.planPreviews(count),
            l10n.packSubtitle(count),
            l10n.mvPhotosCount(count),
            l10n.mvPriceCredits(count),
            l10n.mvAvailableCredits(count),
            l10n.mvGapCredits(count),
            l10n.mvCreditsBack(count),
            l10n.settingsVideoCreditsSummary(count),
            l10n.mvQuotaNeed(l10n.mvLevelChorus, count, count),
            l10n.profileBalanceValue(count),
            l10n.photosCount(count, 10),
            l10n.lyricsCounter(count, 1200),
          ]) {
            expect(text, isNotEmpty);
            expect(text, isNot(contains('{')));
          }
        }
        for (final text in [
          l10n.profileMemberSince(date),
          l10n.detailGeneratedOn(date),
          l10n.licenseGenerated(date),
          l10n.settingsResets(date),
        ]) {
          expect(text, isNotEmpty);
          expect(text, contains('2026'));
        }
        const storePrice = 'StoreKit-price';
        expect(l10n.planPerYear(storePrice), contains(storePrice));
        expect(l10n.planPerMonth(storePrice), contains(storePrice));
        for (final pricePerPeriod in [
          l10n.planPerMonth(storePrice),
          l10n.planPerYear(storePrice),
        ]) {
          expect(
            l10n.paywallTrialDisclosure(pricePerPeriod),
            contains(pricePerPeriod),
          );
        }
        expect(
          l10n.mvNotifyBody(l10n.mvLevelChorus),
          contains(l10n.mvLevelChorus),
        );
      },
    );
  }
  test(
    'unsupported language falls back to English; Chinese and Portuguese resolve',
    () {
      expect(resolveUiLocale([const Locale('it')]), const Locale('en'));
      expect(
        resolveUiLocale([
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ]).scriptCode,
        'Hans',
      );
      expect(
        resolveUiLocale([
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ]).scriptCode,
        'Hant',
      );
      expect(
        resolveUiLocale([const Locale('pt', 'BR')]),
        const Locale('pt', 'BR'),
      );
    },
  );
  testWidgets('system language changes update the resolved UI locale', (
    tester,
  ) async {
    final dispatcher = tester.platformDispatcher;
    dispatcher.localesTestValue = [const Locale('de')];
    addTearDown(dispatcher.clearLocalesTestValue);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWith((ref) async => prefs)],
    );
    expect(container.read(uiLocaleProvider), const Locale('de'));
    dispatcher.localesTestValue = [const Locale('zh', 'TW')];
    await tester.pump();
    expect(container.read(uiLocaleProvider).scriptCode, 'Hant');
    dispatcher.localesTestValue = [const Locale('it')];
    await tester.pump();
    expect(container.read(uiLocaleProvider), const Locale('en'));
    container.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  });
  test('ICU handles Unicode branch bodies, nesting, and invalid syntax', () {
    expect(
      IcuMessage(
        '{count, plural, =0{免费试听已用完} other{还剩 {count} 次}}',
      ).placeholders,
      {'count'},
    );
    expect(
      IcuMessage(
        '{gender, select, other{{count, plural, one{1 photo} other{{count} photos}}}}',
      ).placeholders,
      {'gender', 'count'},
    );
    for (final invalid in [
      '{count, plural, one{One}}',
      '{count, plural, =other{Bad} other{OK}}',
      '{name',
      '{count, plural, many{A} many{B} other{C}}',
    ]) {
      expect(() => IcuMessage(invalid), throwsFormatException);
    }
  });
}
