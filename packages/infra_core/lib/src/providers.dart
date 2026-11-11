import 'dart:ui' show PlatformDispatcher;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/api_config.dart';
import 'config/env_config.dart';
import 'crypto/signing_service.dart';
import 'device/device_boot_clock.dart';
import 'device/device_info_service.dart';
import 'error/error_handler.dart';
import 'network/auth_gateway.dart';
import 'network/dio_factory.dart';
import 'network/interceptors/device_headers_interceptor.dart';
import 'network/interceptors/endpoint_routing_interceptor.dart';
import 'observability/telemetry_sink.dart';
import 'storage/key_value_store.dart';
import 'storage/secure_token_store.dart';
import 'storage/storage_migrator.dart';
import 'time/clock_offset_service.dart';

/// Active environment configuration (compile-time defines). Override in tests.
final envConfigProvider = Provider<EnvConfig>(
  (ref) => EnvConfig.fromEnvironment(),
);

final apiConfigProvider = Provider<ApiConfig>(
  (ref) => ApiConfig.forEnv(ref.watch(envConfigProvider).env),
);

final signingServiceProvider = Provider<SigningService>(
  (ref) => const SigningService(),
);

/// In-process clock-skew correction shared by both Dios. The offset is learned
/// from the `X-Server-Time` response header and is **never persisted** (see
/// [ClockOffsetService]). A single instance backs authDio + apiDio so an offset
/// learned during guest-register is applied to every later business call.
final clockOffsetServiceProvider = Provider<ClockOffsetService>(
  (ref) => ClockOffsetService(),
);

/// Maps any throwable to a typed [Failure]. Wired to the telemetry sink so an
/// unrecognized (non-Dio, non-envelope) caught error is recorded before it is
/// genericized — callers keep only the returned Failure, so without this the
/// original diagnostic would be lost (bootstrap records UNCAUGHT errors only).
final errorHandlerProvider = Provider<ErrorHandler>(
  (ref) => ErrorHandler(telemetry: ref.watch(telemetrySinkProvider)),
);

/// Telemetry boundary. Defaults to a no-op (production-safe, free); the app
/// overrides it with a vendor adapter wrapped in `RedactingTelemetrySink` so PII
/// never leaves the device. See [TelemetrySink].
final telemetrySinkProvider = Provider<TelemetrySink>(
  (ref) => const NoopTelemetrySink(),
);

final secureTokenStoreProvider = Provider<SecureTokenStore>(
  (ref) => SecureTokenStore.withDefaults(),
);

/// Loaded once; override with [AsyncValue.data] in tests / preload in `main`.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// Synchronous key-value access; valid after [sharedPreferencesProvider] has
/// resolved (the startup gate guarantees this before any consumer runs).
final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => KeyValueStore(ref.watch(sharedPreferencesProvider).requireValue),
);

/// The persisted-storage schema version this build expects. Bump it — and append
/// a matching [StorageMigration] to [storageMigrationsProvider] — whenever a
/// persisted shape (pending orders, product cache, settings) changes.
const int kStorageSchemaVersion = 1;

/// Ordered storage migrations. Empty at the baseline (v1); the app/commerce layer
/// overrides this with real steps as the schema evolves.
final storageMigrationsProvider = Provider<List<StorageMigration>>(
  (ref) => const [],
);

/// Migrates persisted storage to [kStorageSchemaVersion] at startup (run by
/// `StartupController` before any store reads its data).
final storageMigratorProvider = Provider<StorageMigrator>(
  (ref) => StorageMigrator(
    currentVersion: kStorageSchemaVersion,
    migrations: ref.watch(storageMigrationsProvider),
  ),
);

final deviceInfoServiceProvider = Provider<DeviceInfoService>(
  (ref) => DeviceInfoService(tokenStore: ref.watch(secureTokenStoreProvider)),
);

final deviceProfileProvider = FutureProvider<DeviceProfile>(
  (ref) => ref.watch(deviceInfoServiceProvider).load(),
);

/// Reads the device boot instant for reboot detection (see [DeviceBootClock]).
final deviceBootClockProvider = Provider<DeviceBootClock>(
  (ref) => const DeviceBootClock(),
);

/// Current UI language tag sent as `X-Language`. The app overrides this with
/// its selected locale; the default reflects the platform locale.
final languageTagProvider = Provider<String>(
  (ref) => PlatformDispatcher.instance.locale.toLanguageTag(),
);

/// Device time zone sent as `X-Timezone`. Defaults to the ISO-8601 UTC offset
/// (e.g. `+08:00`); override with an IANA name (e.g. `Asia/Shanghai`) if the app
/// integrates a platform time-zone plugin.
final timeZoneProvider = Provider<String>(
  (ref) => DeviceHeadersInterceptor.systemTimeZoneTag(),
);

/// App-specific request meta headers added to every request by the device
/// headers interceptor (both Dios). Empty by default; an app overrides it (e.g.
/// Songlet sends its StoreKit storefront + device region for the backend's
/// region-availability check).
final requestMetaHeadersProvider = Provider<Map<String, String>>(
  (ref) => const <String, String>{},
);

/// Auth gateway used by the [apiDioProvider]'s auth interceptor. Defaults to an
/// unauthenticated no-op; commerce_kit overrides this with the real gateway.
final authGatewayProvider = Provider<AuthGateway>(
  (ref) => const UnauthenticatedAuthGateway(),
);

/// No-auth Dio (token-issuing + replay channel).
/// Paths served by another host than `BASE_URL` (one route per prefix); the
/// app binds them. Default: none — every request goes to `BASE_URL`.
final endpointRoutesProvider = Provider<List<EndpointRoute>>((ref) => const []);

final authDioProvider = Provider<Dio>((ref) {
  final dio = DioFactory.createAuthDio(
    env: ref.watch(envConfigProvider),
    apiConfig: ref.watch(apiConfigProvider),
    signing: ref.watch(signingServiceProvider),
    deviceInfoService: ref.watch(deviceInfoServiceProvider),
    languageTagResolver: () => ref.read(languageTagProvider),
    clockOffset: ref.watch(clockOffsetServiceProvider),
    telemetry: ref.watch(telemetrySinkProvider),
    timeZoneResolver: () => ref.read(timeZoneProvider),
    extraHeadersResolver: () => ref.read(requestMetaHeadersProvider),
    routes: ref.watch(endpointRoutesProvider),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Authenticated business Dio.
final apiDioProvider = Provider<Dio>((ref) {
  final dio = DioFactory.createApiDio(
    env: ref.watch(envConfigProvider),
    apiConfig: ref.watch(apiConfigProvider),
    signing: ref.watch(signingServiceProvider),
    deviceInfoService: ref.watch(deviceInfoServiceProvider),
    authGateway: ref.watch(authGatewayProvider),
    authDio: ref.watch(authDioProvider),
    languageTagResolver: () => ref.read(languageTagProvider),
    clockOffset: ref.watch(clockOffsetServiceProvider),
    telemetry: ref.watch(telemetrySinkProvider),
    timeZoneResolver: () => ref.read(timeZoneProvider),
    extraHeadersResolver: () => ref.read(requestMetaHeadersProvider),
    routes: ref.watch(endpointRoutesProvider),
  );
  ref.onDispose(dio.close);
  return dio;
});
