import 'dart:async';

import 'package:flutter/foundation.dart';

import '../error/error_handler.dart';
import 'telemetry_sink.dart';

/// Wraps app startup so **every** uncaught error reaches [telemetry]:
///
/// * synchronous + asynchronous errors → `runZonedGuarded` (fatal);
/// * framework build/layout/gesture errors → `FlutterError.onError` (non-fatal,
///   still presented in debug so the red screen survives);
/// * engine / platform-dispatcher errors → `PlatformDispatcher.onError` (fatal).
///
/// Each error is also classified through the existing [ErrorHandler] → `Failure`
/// taxonomy and tagged for triage. Call from `main`, running `runApp` inside
/// [body] (which also initialises the binding in the same zone).
void bootstrap(
  void Function() body, {
  required TelemetrySink telemetry,
  ErrorHandler errorHandler = const ErrorHandler(),
}) {
  runZonedGuarded(
    () {
      FlutterError.onError = (details) {
        recordBootstrapError(
          telemetry,
          errorHandler,
          details.exception,
          details.stack,
          fatal: false,
        );
        FlutterError.presentError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        recordBootstrapError(telemetry, errorHandler, error, stack, fatal: true);
        return true;
      };
      body();
    },
    (error, stack) => recordBootstrapError(
      telemetry,
      errorHandler,
      error,
      stack,
      fatal: true,
    ),
  );
}

/// Classifies [error] via [errorHandler] and forwards it to [telemetry] with the
/// resulting `Failure` category attached for triage.
@visibleForTesting
void recordBootstrapError(
  TelemetrySink telemetry,
  ErrorHandler errorHandler,
  Object error,
  StackTrace? stackTrace, {
  required bool fatal,
}) {
  final failure = errorHandler.handle(error);
  telemetry.recordError(
    error,
    stackTrace,
    context: {'failure': failure.runtimeType.toString()},
    fatal: fatal,
  );
}
