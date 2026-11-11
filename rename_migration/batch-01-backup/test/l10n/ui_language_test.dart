import 'dart:async';
import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:infra_core/infra_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songlet/l10n/generated/app_localizations.dart';
import 'package:songlet/l10n/ui_locale.dart';
import 'package:songlet/ui/app.dart';
import 'package:songlet/ui/settings/settings_page.dart';
import 'package:songlet/ui/settings/ui_language_sheet.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';
import '../support/fakes.dart' show FakeStoreClient;
import '../support/songlet_harness.dart';

class _LocalStartup extends StartupController {
  @override
  Future<void> start() async {
    await ref.read(sharedPreferencesProvider.future);
    if (ref.mounted) state = const StartupReady();
  }
}

class _Prefs extends Mock implements SharedPreferences {}

Future<void> openPicker(WidgetTester tester) async {
  final entry = find.byKey(const ValueKey('settings.uiLanguage'));
  await reveal(tester, entry);
  await tester.tap(entry);
  await settleFrames(tester);
}

Future<void> choose(WidgetTester tester, String tag) async {
  final option = find.byKey(ValueKey('settings.uiLanguage.$tag'));
  await tester.scrollUntilVisible(
    option,
    150,
    scrollable: find.descendant(
      of: find.byType(UiLanguageSheet),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pump();
  await tester.tap(option);
  await settleFrames(tester);
}

void main() {
  setUp(mockNativeChannels);

  testWidgets(
    'cold start restores locale before the first business page and rebinds notifications',
    (tester) async {
      final gate = Completer<SharedPreferences>();
      final env = SongletTestEnv()..preferencesFuture = gate.future;
      final store = FakeStoreClient();
      addTearDown(store.dispose);
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          ...await env.overrides(),
          startupControllerProvider.overrideWith(_LocalStartup.new),
          storeClientProvider.overrideWithValue(store),
          languageTagProvider.overrideWith(
            (ref) => ref.watch(uiLocaleProvider).toLanguageTag(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SongletApp(initialLocation: '/settings'),
        ),
      );
      await tester.pump();
      expect(find.byType(SettingsPage), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(UiLanguagePreference.key, 'de');
      gate.complete(prefs);
      // Check every frame: no business frame can appear in the system language.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(SettingsPage).evaluate().isNotEmpty) {
          expect(
            Localizations.localeOf(tester.element(find.byType(SettingsPage))),
            const Locale('de'),
          );
        }
      }
      expect(find.byType(SettingsPage), findsOneWidget);
      final router = GoRouter.of(tester.element(find.byType(SettingsPage)));
      await container
          .read(mvNotificationsProvider)
          .scheduleFor(sampleVideo(status: WorkStatus.pending), etaSeconds: 60);
      expect(
        env.notifications.scheduled.last.title,
        lookupAppLocalizations(const Locale('de')).mvNotifyTitle,
      );
      await container
          .read(uiLanguagePreferenceProvider.notifier)
          .select(const Locale('ja'));
      await settleFrames(tester);
      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))),
        same(router),
      );
      await container
          .read(mvNotificationsProvider)
          .scheduleFor(sampleVideo(status: WorkStatus.pending), etaSeconds: 60);
      expect(
        env.notifications.scheduled.last.title,
        lookupAppLocalizations(const Locale('ja')).mvNotifyTitle,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in supportedUiLocales) {
    testWidgets(
      '${locale.toLanguageTag()} selection changes the real locale and persists',
      (tester) async {
        final container = await pumpRoute(
          tester,
          '/settings',
          dynamicLocale: true,
        );
        await openPicker(tester);
        await choose(tester, locale.toLanguageTag());
        expect(find.byType(UiLanguageSheet), findsNothing);
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
          locale,
        );
        expect(container.read(languageTagProvider), locale.toLanguageTag());
        final prefs = await container.read(sharedPreferencesProvider.future);
        expect(
          prefs.getString(UiLanguagePreference.key),
          locale.toLanguageTag(),
        );
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.settingsAppLanguage), findsOneWidget);
        await openPicker(tester);
        final option = find.byKey(
          ValueKey('settings.uiLanguage.${locale.toLanguageTag()}'),
        );
        await tester.scrollUntilVisible(
          option,
          150,
          scrollable: find.descendant(
            of: find.byType(UiLanguageSheet),
            matching: find.byType(Scrollable),
          ),
        );
        final selected = tester.widget<OptionRow>(option);
        expect(selected.selected, isTrue);
        Navigator.of(tester.element(find.byType(UiLanguageSheet))).pop();
        await settleFrames(tester);
        GoRouter.of(tester.element(find.byType(SettingsPage))).go('/create');
        await settleFrames(tester);
        expect(find.text(l10n.inspirationHeader), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('system changes only apply in follow-system mode', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final container = await pumpRoute(tester, '/settings', dynamicLocale: true);
    await openPicker(tester);
    await choose(tester, 'ja');
    tester.platformDispatcher.localesTestValue = [const Locale('de')];
    await settleFrames(tester);
    expect(container.read(uiLocaleProvider), const Locale('ja'));
    await openPicker(tester);
    await choose(tester, 'system');
    expect(container.read(uiLocaleProvider), const Locale('de'));
    expect(
      (await container.read(
        sharedPreferencesProvider.future,
      )).containsKey(UiLanguagePreference.key),
      isFalse,
    );
    tester.platformDispatcher.localesTestValue = [const Locale('zh', 'TW')];
    await settleFrames(tester);
    expect(container.read(uiLocaleProvider).scriptCode, 'Hant');
  });

  testWidgets('dismissal does not change the preference', (tester) async {
    final env = SongletTestEnv()
      ..preferences = {UiLanguagePreference.key: 'de'};
    final container = await pumpRoute(
      tester,
      '/settings',
      env: env,
      dynamicLocale: true,
    );
    await openPicker(tester);
    Navigator.of(tester.element(find.byType(UiLanguageSheet))).pop();
    await settleFrames(tester);
    expect(container.read(uiLocaleProvider), const Locale('de'));
  });

  testWidgets('save failure stays on the picker and preserves selection', (
    tester,
  ) async {
    final prefs = _Prefs();
    when(() => prefs.get(UiLanguagePreference.key)).thenReturn('en');
    when(
      () => prefs.setString(UiLanguagePreference.key, any()),
    ).thenAnswer((_) async => false);
    final env = SongletTestEnv()..preferencesInstance = prefs;
    final container = await pumpRoute(
      tester,
      '/settings',
      env: env,
      dynamicLocale: true,
    );
    await openPicker(tester);
    await choose(tester, 'de');
    expect(find.byType(UiLanguageSheet), findsOneWidget);
    expect(find.text("Couldn't save the language. Try again."), findsOneWidget);
    expect(container.read(uiLocaleProvider), const Locale('en'));
    when(
      () => prefs.setString(UiLanguagePreference.key, any()),
    ).thenAnswer((_) async => true);
    await choose(tester, 'de');
    expect(find.byType(UiLanguageSheet), findsNothing);
    expect(container.read(uiLocaleProvider), const Locale('de'));
  });

  test(
    'invalid stored values follow the system; serialized writes keep the latest choice',
    () async {
      SharedPreferences.setMockInitialValues({
        UiLanguagePreference.key: 'not-a-locale',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWith((ref) async => prefs),
        ],
      );
      addTearDown(container.dispose);
      await container.read(sharedPreferencesProvider.future);
      expect(container.read(uiLanguagePreferenceProvider), isNull);
      final controller = container.read(uiLanguagePreferenceProvider.notifier);
      await Future.wait([
        controller.select(const Locale('de')),
        controller.select(const Locale('ja')),
      ]);
      expect(container.read(uiLocaleProvider), const Locale('ja'));
      expect(prefs.getString(UiLanguagePreference.key), 'ja');
      final relaunched = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWith((ref) async => prefs),
        ],
      );
      addTearDown(relaunched.dispose);
      await relaunched.read(sharedPreferencesProvider.future);
      expect(relaunched.read(uiLocaleProvider), const Locale('ja'));
    },
  );

  testWidgets(
    'interface language does not change the draft or the default lyrics language',
    (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('en')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final container = await pumpRoute(tester, '/create', dynamicLocale: true);
      final drafts = container.read(creationDraftProvider.notifier);
      drafts.setPrompt('Keep my song idea');
      final before = drafts.draft;
      await container
          .read(uiLanguagePreferenceProvider.notifier)
          .select(const Locale('ja'));
      await settleFrames(tester);
      expect(drafts.draft, same(before));
      expect(container.read(lyricLanguagePreferenceProvider), isNull);
      expect(container.read(systemUiLocaleProvider), const Locale('en'));
      drafts.start(
        Occasion.custom,
        deviceLanguage: container.read(systemUiLocaleProvider).languageCode,
      );
      expect(drafts.draft!.lyricLanguage, LyricLanguage.en);
    },
  );
}
