import 'package:meta/meta.dart';

import 'upload_models.dart';

/// Why a [UploadSpec] was rejected by the client-side pre-check.
enum UploadPolicyViolation { unsupportedType, sizeExceeded, invalidHash }

/// Thrown by [UploadService] when the local [UploadPolicy] rejects an input —
/// before any network call, so the UI can fail fast with a precise reason.
class UploadPolicyException implements Exception {
  const UploadPolicyException(this.violation);
  final UploadPolicyViolation violation;
  @override
  String toString() => 'UploadPolicyException(${violation.name})';
}

/// Client-side pre-validation mirroring the backend `upload_policy.go`
/// (`DefaultUploadPolicy`): a MIME allow-list and a max size. It only fails fast
/// for good UX — the **server remains authoritative** (it re-checks and also
/// verifies the real uploaded size at finalize).
@immutable
class UploadPolicy {
  const UploadPolicy({
    this.allowedMimeTypes = defaultAllowedMimeTypes,
    this.maxBytes = defaultMaxBytes,
  });

  /// Default ceiling: 50 MiB (matches the backend default).
  static const int defaultMaxBytes = 50 * 1024 * 1024;

  /// Default MIME allow-list (matches `DefaultUploadPolicy`).
  static const Set<String> defaultAllowedMimeTypes = {
    'image/png', 'image/jpeg', 'image/webp', 'image/gif', 'image/heic',
    'image/heif',
    'video/mp4', 'video/quicktime', 'video/webm',
    'audio/mpeg', 'audio/wav', 'audio/x-wav', 'audio/mp4',
    'application/pdf', 'text/plain', 'text/markdown',
  };

  final Set<String> allowedMimeTypes;
  final int maxBytes;

  /// Returns null when [spec] is acceptable, otherwise the violation reason.
  UploadPolicyViolation? check(UploadSpec spec) {
    if (!allowedMimeTypes.contains(spec.mimeType)) {
      return UploadPolicyViolation.unsupportedType;
    }
    if (spec.sizeBytes <= 0 || spec.sizeBytes > maxBytes) {
      return UploadPolicyViolation.sizeExceeded;
    }
    if (!isSha256Hex(spec.fileHash)) {
      return UploadPolicyViolation.invalidHash;
    }
    return null;
  }

  /// True when [value] is exactly 64 lowercase hex chars (the contract's
  /// `file_hash` shape).
  static bool isSha256Hex(String value) =>
      value.length == 64 && _hex64.hasMatch(value);

  static final RegExp _hex64 = RegExp(r'^[0-9a-f]{64}$');
}
