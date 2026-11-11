import '../domain/file_hasher.dart';
import '../domain/upload_cancellation.dart';
import '../domain/upload_models.dart';
import '../domain/upload_policy.dart';
import '../domain/upload_repository.dart';

/// Orchestrates the two-stage presigned upload as one call:
///
/// `hash → policy pre-check → sign → [dedup short-circuit] → PUT to R2 →
/// finalize`.
///
/// Stateless and reusable — each [upload] is independent, so callers may run
/// several concurrently and bind their own UI state. Progress is reported via the
/// optional [UploadProgress] callback.
///
/// Pass an [UploadCancellation] to abort in flight: the service short-circuits
/// between phases and cancels the active request, surfacing
/// [UploadCancelledException].
///
/// Failure modes:
/// * [UploadPolicyException] — local pre-check rejected the input (no network).
/// * [UploadCancelledException] — cancelled via [UploadCancellation].
/// * [R2UploadException] — the direct-to-R2 PUT was rejected (e.g. 403).
/// * `DioException` (with an `ApiError` from infra_core's envelope interceptor) —
///   a `sign` / `finalize` business error (see `UploadErrorCodes`) or transport
///   failure. Callers map these to UI via infra_core's `ErrorHandler`.
class UploadService {
  UploadService({
    required UploadRepository repository,
    required FileHasher hasher,
    required UploadPolicy policy,
  })  : _repository = repository,
        _hasher = hasher,
        _policy = policy;

  final UploadRepository _repository;
  final FileHasher _hasher;
  final UploadPolicy _policy;

  Future<UploadResult> upload(
    UploadInput input, {
    void Function(UploadProgress progress)? onProgress,
    UploadCancellation? cancellation,
  }) async {
    final total = input.bytes.length;
    _throwIfCancelled(cancellation);

    onProgress?.call(const UploadProgress(phase: UploadPhase.hashing));
    final spec = UploadSpec(
      mimeType: input.mimeType,
      sizeBytes: total,
      filename: input.filename,
      fileHash: _hasher.sha256Hex(input.bytes),
      contentKind: input.contentKind,
      accessLevel: input.accessLevel,
    );

    final violation = _policy.check(spec);
    if (violation != null) throw UploadPolicyException(violation);

    _throwIfCancelled(cancellation);
    onProgress?.call(const UploadProgress(phase: UploadPhase.signing));
    final ticket = await _repository.sign(spec, cancellation: cancellation);

    // Dedup short-circuit: the file already exists server-side — skip the PUT and
    // finalize, reference the existing asset directly.
    if (ticket.dedupHit) {
      onProgress?.call(
        UploadProgress(
          phase: UploadPhase.done,
          sentBytes: total,
          totalBytes: total,
        ),
      );
      return UploadResult(
        bid: ticket.bid,
        url: ticket.publicUrl,
        dedupHit: true,
      );
    }

    _throwIfCancelled(cancellation);
    await _repository.putToR2(
      putUrl: ticket.putUrl,
      bytes: input.bytes,
      mimeType: input.mimeType,
      cancellation: cancellation,
      onProgress: (sent, t) => onProgress?.call(
        UploadProgress(
          phase: UploadPhase.uploading,
          sentBytes: sent,
          totalBytes: t > 0 ? t : total,
        ),
      ),
    );

    _throwIfCancelled(cancellation);
    onProgress?.call(
      UploadProgress(
        phase: UploadPhase.finalizing,
        sentBytes: total,
        totalBytes: total,
      ),
    );
    final asset = await _repository.finalize(ticket.bid, cancellation: cancellation);

    onProgress?.call(
      UploadProgress(
        phase: UploadPhase.done,
        sentBytes: total,
        totalBytes: total,
      ),
    );
    return UploadResult(
      bid: asset.bid,
      url: asset.url,
      dedupHit: asset.dedupHit,
      asset: asset,
    );
  }

  void _throwIfCancelled(UploadCancellation? cancellation) {
    if (cancellation != null && cancellation.isCancelled) {
      throw const UploadCancelledException();
    }
  }
}
