import 'package:app_config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:songlet/l10n/generated/app_localizations.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

/// Pumps [child] inside a localized `MaterialApp` + `ProviderScope`.
///
/// Uses single-frame `pump`s (never `pumpAndSettle`) because the Aura
/// background and skeletons run perpetual animations that would hang a settle.
///
/// [appConfig] fixes the runtime governance config (default: safe/empty) with a
/// network-free controller, so AppConfig-consuming screens are deterministic and
/// no test ever issues a real `/app/config` request. Set it to exercise the
/// maintenance gate / kill-switches / remote config.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Locale? locale,
  bool reduceMotion = false,
  TextDirection? textDirection,
  AppConfig appConfig = AppConfig.safeDefault,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) =>
          null, // errors are terminal (explicit retry UX), as in the app
      overrides: [
        appConfigProvider.overrideWith(() => _FixedAppConfig(appConfig)),
        // Songlet allowance + storefront: deterministic, network-free defaults.
        musicEntitlementProvider.overrideWith(
          (ref) async => const MusicEntitlement(
            tier: MusicTier.free,
            songsLeft: 0,
            clipsLeft: 3,
          ),
        ),
        storefrontProvider.overrideWith(_FixedStorefront.new),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AuraTheme.warm,
        locale: locale, // drives text direction (e.g. `ar` → RTL)
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MotionPolicyOverride(
          reduceMotion:
              reduceMotion, // deterministic (static) frames for goldens
          child: textDirection == null
              ? Scaffold(body: child)
              : Directionality(
                  textDirection: textDirection,
                  child: Scaffold(body: child),
                ),
        ),
      ),
    ),
  );
  // Let overridden futures resolve (single frames, not a settle).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 10));
}

class _FixedStorefront extends MusicStorefrontController {
  @override
  String? build() => 'USA';
}

/// Network-free [AppConfigController] for tests: returns a fixed config and skips
/// the live fetch + lifecycle wiring.
class _FixedAppConfig extends AppConfigController {
  _FixedAppConfig(this._value);

  final AppConfig _value;

  @override
  AppConfig build() => _value;

  @override
  Future<void> refresh({bool force = false}) async {}
}
