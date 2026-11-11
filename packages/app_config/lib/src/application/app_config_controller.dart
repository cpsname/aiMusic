import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

import '../domain/app_config.dart';
import 'app_config_providers.dart';

/// Holds the current [AppConfig] and keeps it fresh: an initial fetch on first
/// read, a throttled refresh on app foreground (`resumed`), and an on-demand
/// [refresh].
///
/// **Fail-open**: a failed fetch never throws and never moves the state into an
/// error — the last good value (or [AppConfig.safeDefault]) is retained, so the
/// maintenance gate can never block the app on a config outage. Refreshes are
/// throttled to [appConfigPollIntervalProvider] (the contract recommends ≥60s).
class AppConfigController extends Notifier<AppConfig> {
  DateTime? _lastFetchedAt;
  AppLifecycleListener? _lifecycle;
  bool _inFlight = false;
  bool _languageRefreshPending = false;
  int _languageRevision = 0;
  final Map<String, AppConfig> _localized = {};

  @override
  AppConfig build() {
    ref.listen(languageTagProvider, (previous, next) {
      if (previous == next) return;
      _languageRevision++;
      _lastFetchedAt = null;
      // Keep governance flags authoritative while old-language copy is hidden.
      final translated = _localized[next];
      state = AppConfig(
        maintenance: Maintenance(
          active: state.maintenance.active,
          message: translated?.maintenance.message ?? '',
          resumeAt: state.maintenance.resumeAt,
        ),
        killSwitches: state.killSwitches,
        config: {
          ...state.config,
          'promo_text': translated?.configValue<String>('promo_text', '') ?? '',
        },
      );
      if (_inFlight) {
        _languageRefreshPending = true;
      } else {
        unawaited(refresh(force: true));
      }
    });
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    ref.onDispose(() => _lifecycle?.dispose());
    // Fire-and-forget initial fetch; the maintenance gate reacts when it lands.
    unawaited(refresh());
    return AppConfig.safeDefault;
  }

  void _onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  /// Refreshes the config — fail-open and throttled. [force] bypasses the
  /// throttle (e.g. before a critical operation).
  Future<void> refresh({bool force = false}) async {
    if (_inFlight) return;
    final revision = _languageRevision;
    final language = ref.read(languageTagProvider);
    try {
      // Throttle on the RAW device clock (monotonic elapsed time) — never the
      // server-corrected clock, whose offset is relearned mid-session (from the
      // `X-Server-Time` header on this very response) and would distort the
      // window. The corrected clock is only for the `resume_at` countdown.
      final now = ref.read(clockOffsetServiceProvider).deviceNow();
      final last = _lastFetchedAt;
      final interval = ref.read(appConfigPollIntervalProvider);
      if (!force && last != null && now.difference(last) < interval) return;

      _inFlight = true;
      final config = await ref.read(appConfigRepositoryProvider).fetch();
      if (!ref.mounted || revision != _languageRevision) return;
      _localized[language] = config;
      state = config;
      _lastFetchedAt =
          now; // stamp on success only → fast retry after a failure
      ref
          .read(telemetrySinkProvider)
          .logEvent(
            'app_config_refreshed',
            properties: {
              'maintenance': config.maintenance.active,
              'kill_switches': config.killSwitches.length,
            },
          );
    } on Object catch (error, stackTrace) {
      if (!ref.mounted) return;
      // Fail-open: keep the last good value; never surface an error state.
      ref
          .read(telemetrySinkProvider)
          .recordError(error, stackTrace, fatal: false);
    } finally {
      _inFlight = false;
      if (ref.mounted && _languageRefreshPending) {
        _languageRefreshPending = false;
        unawaited(refresh(force: true));
      }
    }
  }
}
