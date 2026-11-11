import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';
import '../config/env_config.dart';
import '../crypto/signing_service.dart';
import '../device/device_info_service.dart';
import '../observability/telemetry_sink.dart';
import '../time/clock_offset_service.dart';
import 'auth_gateway.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/clock_sync_interceptor.dart';
import 'interceptors/device_headers_interceptor.dart';
import 'interceptors/endpoint_routing_interceptor.dart';
import 'interceptors/envelope_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/signature_interceptor.dart';

/// Builds the two Dio instances that back every HTTP call.
abstract final class DioFactory {
  static BaseOptions _baseOptions(EnvConfig env, ApiConfig api) => BaseOptions(
        baseUrl: env.baseUrl,
        connectTimeout: api.connectTimeout,
        sendTimeout: api.sendTimeout,
        receiveTimeout: api.receiveTimeout,
        contentType: Headers.jsonContentType,
      );

  /// No-auth Dio: token-issuing endpoints (login/refresh/guest-register),
  /// `/app/init`, and the [AuthInterceptor]'s replay channel.
  ///
  /// Chain: device → signature → clock-sync → retry → envelope → logging. It
  /// deliberately omits the auth interceptor so refresh/replay cannot recurse.
  /// The signer reads the corrected clock from [clockOffset]; [ClockSyncInterceptor]
  /// keeps that offset fresh from the `X-Server-Time` header and re-signs once on
  /// a cold-start time-window rejection. [LoggingInterceptor] breadcrumbs every
  /// round trip to [telemetry] (all envs) and prints verbose lines in dev/staging.
  static Dio createAuthDio({
    required EnvConfig env,
    required ApiConfig apiConfig,
    required SigningService signing,
    required DeviceInfoService deviceInfoService,
    required String Function() languageTagResolver,
    required ClockOffsetService clockOffset,
    required TelemetrySink telemetry,
    String Function()? timeZoneResolver,
    Map<String, String> Function()? extraHeadersResolver,
    List<EndpointRoute> routes = const [],
    Uuid uuid = const Uuid(),
  }) {
    final dio = Dio(_baseOptions(env, apiConfig));
    dio.interceptors.addAll([
      EndpointRoutingInterceptor(routes),
      DeviceHeadersInterceptor(
        deviceInfoService: deviceInfoService,
        languageTagResolver: languageTagResolver,
        timeZoneResolver: timeZoneResolver,
        extraHeadersResolver: extraHeadersResolver,
      ),
      SignatureInterceptor(
        config: env,
        signing: signing,
        uuid: uuid,
        clock: clockOffset.now,
      ),
      ClockSyncInterceptor(clockOffset: clockOffset, dio: dio),
      RetryInterceptor(dio: dio, config: apiConfig),
      const EnvelopeInterceptor(),
      LoggingInterceptor(telemetry: telemetry, verbose: env.loggingEnabled),
    ]);
    return dio;
  }

  /// Authenticated business Dio.
  ///
  /// Chain: device → auth → signature → clock-sync → retry → envelope → logging.
  /// (The five contract stages keep their order; request-signing + clock-sync are
  /// layered in after auth — header order does not affect the body signature.)
  static Dio createApiDio({
    required EnvConfig env,
    required ApiConfig apiConfig,
    required SigningService signing,
    required DeviceInfoService deviceInfoService,
    required AuthGateway authGateway,
    required Dio authDio,
    required String Function() languageTagResolver,
    required ClockOffsetService clockOffset,
    required TelemetrySink telemetry,
    String Function()? timeZoneResolver,
    Map<String, String> Function()? extraHeadersResolver,
    List<EndpointRoute> routes = const [],
    Uuid uuid = const Uuid(),
  }) {
    final dio = Dio(_baseOptions(env, apiConfig));
    dio.interceptors.addAll([
      EndpointRoutingInterceptor(routes),
      DeviceHeadersInterceptor(
        deviceInfoService: deviceInfoService,
        languageTagResolver: languageTagResolver,
        timeZoneResolver: timeZoneResolver,
        extraHeadersResolver: extraHeadersResolver,
      ),
      AuthInterceptor(gateway: authGateway, authDio: authDio),
      SignatureInterceptor(
        config: env,
        signing: signing,
        uuid: uuid,
        clock: clockOffset.now,
      ),
      ClockSyncInterceptor(clockOffset: clockOffset, dio: dio),
      RetryInterceptor(dio: dio, config: apiConfig),
      const EnvelopeInterceptor(),
      LoggingInterceptor(telemetry: telemetry, verbose: env.loggingEnabled),
    ]);
    return dio;
  }
}
