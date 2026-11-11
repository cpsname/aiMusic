/// media_kit — file upload via the two-stage presigned R2 direct-upload
/// (`POST /v1/uploads/sign` → client `PUT` to R2 → `POST /v1/uploads/finalize`).
///
/// A bounded context mirroring the backend creation BC's upload capability:
/// `sign`/`finalize` go over infra_core's authed business Dio; the bytes go
/// **directly to R2** over a bare Dio (no BFF interceptors). The client computes
/// the required content hash (SHA-256), pre-validates against a MIME/size policy,
/// and short-circuits on a server dedup hit. Consumers import
/// `package:media_kit/media_kit.dart` and call [UploadService] via
/// `uploadServiceProvider`.
library;

export 'src/application/upload_providers.dart';
export 'src/application/upload_service.dart';
export 'src/domain/file_hasher.dart';
export 'src/domain/upload_cancellation.dart';
export 'src/domain/upload_error_codes.dart';
export 'src/domain/upload_models.dart';
export 'src/domain/upload_policy.dart';
export 'src/domain/upload_repository.dart';
