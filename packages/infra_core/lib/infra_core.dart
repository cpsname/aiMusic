/// infra_core — pure infrastructure layer.
///
/// Network (5-stage interceptor chain + request signing), crypto (HMAC app
/// signing), the double-layer sealed error system, environment config,
/// secure/preferences storage, and device identity. Zero business, zero UI.
///
/// Consumers import `package:infra_core/infra_core.dart`.
library;

export 'src/config/api_config.dart';
export 'src/config/env_config.dart';
export 'src/crypto/canonical_json.dart';
export 'src/crypto/signing_service.dart';
export 'src/device/device_boot_clock.dart';
export 'src/device/device_info_service.dart';
export 'src/error/api_error.dart';
export 'src/error/error_codes.dart';
export 'src/error/error_handler.dart';
export 'src/error/error_presenter.dart';
export 'src/error/failure.dart';
export 'src/network/api_envelope.dart';
export 'src/network/api_headers.dart';
export 'src/network/auth_gateway.dart';
export 'src/network/dio_factory.dart';
export 'src/network/interceptors/auth_interceptor.dart';
export 'src/network/interceptors/clock_sync_interceptor.dart';
export 'src/network/interceptors/device_headers_interceptor.dart';
export 'src/network/interceptors/endpoint_routing_interceptor.dart';
export 'src/network/interceptors/envelope_interceptor.dart';
export 'src/network/interceptors/logging_interceptor.dart';
export 'src/network/interceptors/retry_interceptor.dart';
export 'src/network/interceptors/signature_interceptor.dart';
export 'src/observability/bootstrap.dart';
export 'src/observability/pii_redactor.dart';
export 'src/observability/redacting_telemetry_sink.dart';
export 'src/observability/telemetry_sink.dart';
export 'src/providers.dart';
export 'src/storage/key_value_store.dart';
export 'src/storage/secure_token_store.dart';
export 'src/storage/storage_migrator.dart';
export 'src/time/clock_offset_service.dart';
