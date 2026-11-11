import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

import 'generated/app_localizations.dart';

/// Only these locales are offered by Songlet; generator fallback bundles are internal.
const supportedUiLocales = [
  Locale('en'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  Locale('ja'),
  Locale('ko'),
  Locale('de'),
  Locale('fr'),
  Locale('es'),
  Locale('pt', 'BR'),
  Locale('hi'),
  Locale('id'),
  Locale('vi'),
  Locale('tr'),
];

/// One resolved locale for Flutter, intl, and the backend's X-Language header.
final uiLocaleProvider = Provider<Locale>(
  (ref) =>
      ref.watch(uiLanguagePreferenceProvider) ??
      ref.watch(systemUiLocaleProvider),
);

final systemUiLocaleProvider =
    NotifierProvider<SystemUiLocaleController, Locale>(
      SystemUiLocaleController.new,
    );

final uiLanguagePreferenceProvider =
    NotifierProvider<UiLanguagePreference, Locale?>(UiLanguagePreference.new);

/// Autonyms come from each language's resource, independent of the current UI.
String uiLanguageName(Locale locale) =>
    lookupAppLocalizations(locale).settingsLanguageNativeName;

class UiLanguagePreference extends Notifier<Locale?> {
  static const key = 'songlet.ui_locale';
  Future<void> _writes = Future<void>.value();

  @override
  Locale? build() {
    // MaterialApp reads this before StartupGate has loaded preferences. Watching
    // the async source restores the selection before business pages are shown.
    final stored = ref.watch(sharedPreferencesProvider).value?.get(key);
    return supportedUiLocales
        .where((l) => l.toLanguageTag() == stored)
        .firstOrNull;
  }

  Future<void> select(Locale? locale) {
    if (locale != null && !supportedUiLocales.contains(locale)) {
      return Future<void>.error(ArgumentError.value(locale, 'locale'));
    }
    final operation = _writes.then((_) => _save(locale));
    _writes = operation.catchError((Object _, StackTrace _) {});
    return operation;
  }

  Future<void> _save(Locale? locale) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final previous = state?.toLanguageTag();
    try {
      final saved = locale == null
          ? await prefs.remove(key)
          : await prefs.setString(key, locale.toLanguageTag());
      if (!saved) throw StateError('Unable to persist UI locale');
    } on Object {
      // SharedPreferences updates its memory cache before the platform write.
      // Restore that cache as well, so a failed write cannot change the locale
      // on a later provider rebuild. Keep the original failure for the picker.
      try {
        if (previous == null) {
          await prefs.remove(key);
        } else {
          await prefs.setString(key, previous);
        }
      } on Object catch (_) {
        // The picker reports the original persistence failure.
      }
      rethrow;
    }
    if (ref.mounted) state = locale;
  }
}

Locale resolveUiLocale(List<Locale>? preferred) => basicLocaleListResolution(
  preferred?.map((locale) {
    if (locale.languageCode != 'zh' || locale.scriptCode != null) return locale;
    return Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: const {'TW', 'HK', 'MO'}.contains(locale.countryCode)
          ? 'Hant'
          : 'Hans',
      countryCode: locale.countryCode,
    );
  }).toList(),
  supportedUiLocales,
);

class SystemUiLocaleController extends Notifier<Locale>
    with WidgetsBindingObserver {
  @override
  Locale build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return resolveUiLocale(WidgetsBinding.instance.platformDispatcher.locales);
  }

  @override
  void didChangeLocales(List<Locale>? locales) =>
      state = resolveUiLocale(locales);
}
