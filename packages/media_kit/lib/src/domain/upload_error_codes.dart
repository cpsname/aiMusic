/// Backend envelope `code` values specific to the upload flow that a client may
/// branch on. The authoritative list lives in `docs/api/creation.md`
/// (§/v1/uploads/sign · /finalize) + `docs/api/error-codes.md`. These surface as
/// `ApiError.code` on the `DioException` thrown by [UploadRepository] /
/// [UploadService]; map them to UI via `infra_core`'s `ErrorHandler` as usual.
abstract final class UploadErrorCodes {
  /// MIME not in the allow-list (sign).
  static const int unsupportedMimeType = 40034;

  /// Declared size exceeds the server limit (sign).
  static const int fileSizeExceeded = 40035;

  /// `file_hash` is not 64 lowercase hex — domain-layer re-check (sign).
  static const int invalidFileHash = 40037;

  /// finalize HEAD found the real R2 object size ≠ the declared `size` — re-PUT
  /// the correct file, then finalize again (state stays `pending`).
  static const int uploadSizeMismatch = 40038;

  /// finalize could not find the pending asset for the given `bid` (or it is not
  /// owned by the caller).
  static const int assetNotFound = 40420;

  /// finalize found no R2 object — the client did not actually PUT. Re-PUT, then
  /// finalize again.
  static const int r2ObjectNotFound = 40430;

  /// Duplicate / out-of-state finalize (already `uploaded`, or a non-dedup
  /// concurrent race).
  static const int uploadNotPending = 40922;

  /// The server's storage backend does not support direct upload
  /// (`storage.provider=local`, dev mode).
  static const int directUploadUnsupported = 50100;
}
