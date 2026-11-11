import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

class _CapturingSink implements TelemetrySink {
  Object? lastError;
  StackTrace? lastStack;
  Map<String, Object?>? lastContext;
  bool? lastFatal;

  @override
  void logEvent(String name, {Map<String, Object?>? properties}) {}

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, Object?>? context,
    bool fatal = false,
  }) {
    lastError = error;
    lastStack = stackTrace;
    lastContext = context;
    lastFatal = fatal;
  }

  @override
  void breadcrumb(String message, {Map<String, Object?>? data}) {}

  @override
  void setUser(String? anonymousId) {}
}

void main() {
  test('recordBootstrapError tags the Failure category and forwards fatal', () {
    final sink = _CapturingSink();
    recordBootstrapError(
      sink,
      const ErrorHandler(),
      StateError('boom'),
      StackTrace.current,
      fatal: true,
    );
    expect(sink.lastError, isA<StateError>());
    expect(sink.lastFatal, isTrue);
    // ErrorHandler maps an arbitrary error to a Failure subtype; the category is
    // attached for triage.
    expect(sink.lastContext!['failure'], endsWith('Failure'));
  });

  test('a thrown error in the guarded zone is recorded as fatal', () {
    final sink = _CapturingSink();
    final originalFlutter = FlutterError.onError;
    final originalPlatform = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = originalFlutter;
      PlatformDispatcher.instance.onError = originalPlatform;
    });

    bootstrap(() => throw StateError('zone boom'), telemetry: sink);

    expect(sink.lastError, isA<StateError>());
    expect(sink.lastFatal, isTrue);
  });

  test('FlutterError.onError routes framework errors as non-fatal', () {
    final sink = _CapturingSink();
    final originalFlutter = FlutterError.onError;
    final originalPlatform = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = originalFlutter;
      PlatformDispatcher.instance.onError = originalPlatform;
    });

    bootstrap(
      () => FlutterError.reportError(
        FlutterErrorDetails(exception: StateError('frame boom')),
      ),
      telemetry: sink,
    );

    expect(sink.lastError, isA<StateError>());
    expect(sink.lastFatal, isFalse);
  });
}
