import 'package:meta/meta.dart';

/// Visibility requested for an uploaded asset (mirrors `gen_assets.access_level`).
enum UploadAccessLevel { private, unlisted, public }

/// Coarse content-type hint sent to `sign` so the finalized asset can be
/// type-filtered by `GET /v1/assets`.
enum UploadContentKind { image, video, audio, document }

/// Phases the orchestrated upload moves through (for progress reporting).
enum UploadPhase { hashing, signing, uploading, finalizing, done }

/// What a caller hands the [UploadService]: the raw bytes plus their metadata.
/// The content hash is computed by the service (not the caller).
@immutable
class UploadInput {
  const UploadInput({
    required this.bytes,
    required this.filename,
    required this.mimeType,
    this.contentKind,
    this.accessLevel = UploadAccessLevel.private,
  });

  final List<int> bytes;
  final String filename;
  final String mimeType;
  final UploadContentKind? contentKind;
  final UploadAccessLevel accessLevel;
}

/// Progress tick emitted during [UploadService.upload].
@immutable
class UploadProgress {
  const UploadProgress({
    required this.phase,
    this.sentBytes = 0,
    this.totalBytes = 0,
  });

  final UploadPhase phase;
  final int sentBytes;
  final int totalBytes;

  /// 0.0–1.0 sent fraction during [UploadPhase.uploading]; 0 when total unknown.
  double get fraction =>
      totalBytes <= 0 ? 0 : (sentBytes / totalBytes).clamp(0.0, 1.0);
}

/// Fully specified upload request for `POST /v1/uploads/sign`. [fileHash] is the
/// content SHA-256 as 64 lowercase hex — required by the backend since
/// 2026-06-20 (the presigned channel never sees the bytes, so the client must
/// supply the dedup hash).
@immutable
class UploadSpec {
  const UploadSpec({
    required this.mimeType,
    required this.sizeBytes,
    required this.filename,
    required this.fileHash,
    this.contentKind,
    this.accessLevel = UploadAccessLevel.private,
  });

  final String mimeType;
  final int sizeBytes;
  final String filename;
  final String fileHash;
  final UploadContentKind? contentKind;
  final UploadAccessLevel accessLevel;
}

/// Result of `POST /v1/uploads/sign`. On a dedup hit ([dedupHit] true) the file
/// already exists server-side: [putUrl] is empty and the client must **skip** the
/// PUT and finalize, using [bid]/[publicUrl] directly.
@immutable
class UploadTicket {
  const UploadTicket({
    required this.bid,
    required this.putUrl,
    required this.publicUrl,
    required this.key,
    required this.dedupHit,
    this.expiresAt,
  });

  final String bid;
  final String putUrl;
  final String publicUrl;
  final String key;
  final bool dedupHit;
  final DateTime? expiresAt;
}

/// Result of `POST /v1/uploads/finalize` — the finalized asset (`uploaded`).
@immutable
class UploadedAsset {
  const UploadedAsset({
    required this.bid,
    required this.url,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.contentType,
    required this.accessLevel,
    required this.tags,
    required this.groupName,
    required this.dedupHit,
    this.expiresAt,
    this.createdAt,
  });

  final String bid;
  final String url;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String contentType;
  final String accessLevel;
  final List<String> tags;
  final String groupName;
  final bool dedupHit;
  final DateTime? expiresAt;
  final DateTime? createdAt;
}

/// The settled outcome callers reference: the asset [bid] (to attach to a task)
/// and its [url]. [asset] is the full finalize DTO on the normal path, and null
/// on the dedup short-circuit (no finalize was issued).
@immutable
class UploadResult {
  const UploadResult({
    required this.bid,
    required this.url,
    required this.dedupHit,
    this.asset,
  });

  final String bid;
  final String url;
  final bool dedupHit;
  final UploadedAsset? asset;
}
