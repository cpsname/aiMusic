import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

import '../data/sha256_file_hasher.dart';
import '../data/upload_repository_impl.dart';
import '../domain/file_hasher.dart';
import '../domain/upload_policy.dart';
import '../domain/upload_repository.dart';
import 'upload_service.dart';

/// Bare Dio for the R2 presigned PUT — **deliberately no interceptors**. The
/// BFF's JWT / App-signature / envelope-unwrap must never touch the direct-to-R2
/// upload: they would break R2's presigned-URL signature, and R2 returns no
/// envelope to unwrap. A generous send timeout accommodates large files on weak
/// networks; the URL is absolute so no `baseUrl` is set.
final r2PutDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      sendTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(minutes: 2),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Content hasher (SHA-256 hex). Overridable in tests.
final fileHasherProvider = Provider<FileHasher>(
  (ref) => const Sha256FileHasher(),
);

/// Client-side upload allow-list + size limit (mirrors the backend default).
/// Overridable to tighten/loosen per app.
final uploadPolicyProvider = Provider<UploadPolicy>(
  (ref) => const UploadPolicy(),
);

/// Composition root: binds the concrete repository to the domain interface,
/// wiring the BFF business Dio (sign/finalize) and the bare R2 Dio (PUT).
final uploadRepositoryProvider = Provider<UploadRepository>(
  (ref) => UploadRepositoryImpl(
    apiDio: ref.watch(apiDioProvider),
    r2Dio: ref.watch(r2PutDioProvider),
  ),
);

/// The upload use-case: `hash → sign → [dedup] → PUT → finalize`. Stateless and
/// safe to call concurrently.
final uploadServiceProvider = Provider<UploadService>(
  (ref) => UploadService(
    repository: ref.watch(uploadRepositoryProvider),
    hasher: ref.watch(fileHasherProvider),
    policy: ref.watch(uploadPolicyProvider),
  ),
);
