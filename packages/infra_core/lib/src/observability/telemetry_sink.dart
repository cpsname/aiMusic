import 'package:flutter/foundation.dart';

/// Vendor-agnostic telemetry boundary. Production builds bind a real adapter
/// (Crashlytics / Sentry / a custom ingest endpoint) behind this interface;
/// nothing in the codebase depends on a specific vendor. Always wrap the bound
/// adapter in a `RedactingTelemetrySink` so PII never reaches the vendor.
abstract interface class TelemetrySink {
  /// Records a structured analytics event (e.g. the IAP funnel steps).
  void logEvent(String name, {Map<String, Object?>? properties});

  /// Records an error. [fatal] marks crashes (uncaught zone / platform errors)
  /// versus handled faults. [context] carries structured tags for triage.
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, Object?>? context,
    required bool fatal,
  });

  /// Adds a breadcrumb to the session trail (e.g. each HTTP round trip).
  void breadcrumb(String message, {Map<String, Object?>? data});

  /// Associates subsequent telemetry with an anonymous user id (null clears it).
  void setUser(String? anonymousId);
}

/// The default sink: discards everything. Used until the app binds a real
/// adapter, and in tests by default. Safe and free in production.
class NoopTelemetrySink implements TelemetrySink {
  const NoopTelemetrySink();

  @override
  void logEvent(String name, {Map<String, Object?>? properties}) {}

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, Object?>? context,
    bool fatal = false,
  }) {}

  @override
  void breadcrumb(String message, {Map<String, Object?>? data}) {}

  @override
  void setUser(String? anonymousId) {}
}

/// A sample adapter that writes structured lines to the console. Demonstrates
/// the [TelemetrySink] contract (a real vendor adapter has the same shape) and
/// is handy in dev/staging. Bind it via `telemetrySinkProvider`, wrapped in a
/// `RedactingTelemetrySink`.
class ConsoleTelemetrySink implements TelemetrySink {
  const ConsoleTelemetrySink({void Function(String message)? out})
      : _out = out ?? _defaultOut;

  final void Function(String message) _out;

  static void _defaultOut(String message) => debugPrint('[telemetry] $message');

  @override
  void logEvent(String name, {Map<String, Object?>? properties}) =>
      _out('event · $name ${properties ?? const {}}');

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, Object?>? context,
    bool fatal = false,
  }) =>
      _out('${fatal ? 'fatal' : 'error'} · $error ${context ?? const {}}');

  @override
  void breadcrumb(String message, {Map<String, Object?>? data}) =>
      _out('· $message ${data ?? const {}}');

  @override
  void setUser(String? anonymousId) => _out('user · ${anonymousId ?? '<none>'}');
}
