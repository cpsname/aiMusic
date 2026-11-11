import 'pii_redactor.dart';
import 'telemetry_sink.dart';

/// Decorates any [TelemetrySink], scrubbing PII from event properties, error
/// context, breadcrumb messages and breadcrumb data before they reach the inner
/// (vendor) sink. Bind the real adapter as `RedactingTelemetrySink(adapter)` so
/// masking is structurally guaranteed — no call site can forget it.
class RedactingTelemetrySink implements TelemetrySink {
  const RedactingTelemetrySink(
    this._inner, {
    PiiRedactor redactor = const PiiRedactor(),
  }) : _redactor = redactor;

  final TelemetrySink _inner;
  final PiiRedactor _redactor;

  @override
  void logEvent(String name, {Map<String, Object?>? properties}) =>
      _inner.logEvent(
        name,
        properties:
            properties == null ? null : _redactor.redactMap(properties),
      );

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, Object?>? context,
    bool fatal = false,
  }) =>
      _inner.recordError(
        error,
        stackTrace,
        context: context == null ? null : _redactor.redactMap(context),
        fatal: fatal,
      );

  @override
  void breadcrumb(String message, {Map<String, Object?>? data}) =>
      _inner.breadcrumb(
        _redactor.redactString(message),
        data: data == null ? null : _redactor.redactMap(data),
      );

  @override
  void setUser(String? anonymousId) => _inner.setUser(anonymousId);
}
