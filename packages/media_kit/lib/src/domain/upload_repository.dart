import 'upload_cancellation.dart';
import 'upload_models.dart';

/// A direct-to-R2 PUT failure (the bytes channel). R2 returns no envelope, so
/// this is surfaced distinctly from a BFF `DioException`/`ApiError` (`sign` /
/// `finalize`) — callers can tell a presigned-PUT rejection (e.g. 403 on a
/// signature / Content-Type mismatch) from a business error.
class R2UploadException implements Exception {
  const R2UploadException({this.statusCode, this.message});

  /// R2's HTTP status, when the failure carried a response.
  final int? statusCode;
  final String? message;

  @override
  String toString() =>
      'R2UploadException(statusCode: $statusCode, message: $message)';
}

/// Domain contract for the two-stage presigned upload. The concrete impl (data
/// layer, `UploadRepositoryImpl`) is bound in the composition root
/// (`upload_providers.dart`). Every call accepts an optional [UploadCancellation]
/// and throws [UploadCancelledException] if it is cancelled in flight.
abstract interface class UploadRepository {
  /// `POST /v1/uploads/sign` — pre-creates a pending asset and returns the
  /// presigned PUT ticket (or a dedup short-circuit). Authed (JWT + App
  /// signature), over the BFF Dio.
  Future<UploadTicket> sign(UploadSpec spec, {UploadCancellation? cancellation});

  /// Raw `PUT` of [bytes] to the presigned R2 [putUrl]. [mimeType] MUST equal the
  /// `sign` request's mime (R2 rejects a mismatched Content-Type as a signature
  /// failure). [onProgress] reports (sent, total) bytes. **Bypasses the BFF
  /// interceptor chain.** Throws [R2UploadException] on a non-cancel failure.
  Future<void> putToR2({
    required String putUrl,
    required List<int> bytes,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
    UploadCancellation? cancellation,
  });

  /// `POST /v1/uploads/finalize` — advances the pending asset for [bid] to
  /// `uploaded` and returns the finalized asset. Authed, over the BFF Dio.
  Future<UploadedAsset> finalize(String bid, {UploadCancellation? cancellation});
}
