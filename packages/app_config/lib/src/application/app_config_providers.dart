import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

import '../data/app_config_repository_impl.dart';
import '../domain/app_config.dart';
import '../domain/app_config_repository.dart';
import 'app_config_controller.dart';

/// Known feature codes the app checks against `kill_switches`. Integrators extend
/// this; unknown codes from the server are ignored (forward-compatible).
abstract final class AppFeatureCodes {
  /// Disables the in-app purchase / paywall entry when present.
  static const String iapPurchase = 'iap_purchase';
}

/// Minimum interval between throttled config refreshes. The server caches for
/// 30s and the contract recommends client polling ≥60s. Overridable in tests.
final appConfigPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 60),
);

/// Composition root: binds the concrete repository to the domain interface,
/// reading the app-signed Dio from infra_core.
final appConfigRepositoryProvider = Provider<AppConfigRepository>(
  (ref) => AppConfigRepositoryImpl(ref.watch(authDioProvider)),
);

/// The live runtime governance config (fail-open; never errors). First read
/// triggers an initial fetch; foreground resume refreshes it (throttled).
final appConfigProvider = NotifierProvider<AppConfigController, AppConfig>(
  AppConfigController.new,
);

/// The current maintenance status.
final maintenanceProvider = Provider<Maintenance>(
  (ref) => ref.watch(appConfigProvider).maintenance,
);

/// Whether [code] is currently kill-switched.
final isFeatureKilledProvider = Provider.family<bool, String>(
  (ref, code) => ref.watch(appConfigProvider).isKilled(code),
);
