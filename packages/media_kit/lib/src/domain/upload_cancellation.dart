import 'dart:async';

/// Cooperative cancellation for an in-flight upload, kept HTTP-client-agnostic so
/// the domain stays pure (no Dio). The data layer bridges it to the client's
/// native cancellation, and [UploadService] also short-circuits between phases.
///
/// Single-use: once [cancel] is called it stays cancelled. Create a fresh token
/// per upload.
class UploadCancellation {
  final Completer<void> _completer = Completer<void>();

  /// Whether cancellation has been requested.
  bool get isCancelled => _completer.isCompleted;

  /// Completes the first time [cancel] is called (never, if it isn't).
  Future<void> get whenCancelled => _completer.future;

  /// Requests cancellation. Idempotent.
  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// Thrown by [UploadService] / [UploadRepository] when an upload is cancelled —
/// distinct from a transport/business failure so callers can treat a user abort
/// as a non-error.
class UploadCancelledException implements Exception {
  const UploadCancelledException();
  @override
  String toString() => 'UploadCancelledException';
}
