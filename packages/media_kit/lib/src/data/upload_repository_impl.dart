import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../domain/upload_cancellation.dart';
import '../domain/upload_models.dart';
import '../domain/upload_repository.dart';
import 'json_coerce.dart';
import 'upload_dtos.dart';

/// Two-stage presigned upload over two Dio instances:
/// * [_apiDio] — the BFF business Dio (JWT + App signature + clock-sync + retry +
///   envelope unwrap, all from infra_core) for `sign` and `finalize`.
/// * [_r2Dio] — a **bare** Dio (no interceptors) for the direct-to-R2 PUT, so the
///   BFF's auth/signature/envelope never touch (and break) the presigned URL.
///
/// Each call bridges the domain [UploadCancellation] to a Dio [CancelToken];
/// a cancelled request surfaces as [UploadCancelledException], and a non-cancel
/// R2 PUT failure as [R2UploadException].
class UploadRepositoryImpl implements UploadRepository {
  UploadRepositoryImpl({required Dio apiDio, required Dio r2Dio})
      : _apiDio = apiDio,
        _r2Dio = r2Dio;

  final Dio _apiDio;
  final Dio _r2Dio;

  @override
  Future<UploadTicket> sign(
    UploadSpec spec, {
    UploadCancellation? cancellation,
  }) async {
    final response = await _guardCancel(
      () => _apiDio.post<dynamic>(
        '/uploads/sign',
        data: signRequestJson(spec),
        cancelToken: _bridge(cancellation),
      ),
    );
    return ticketFromJson(asMap(response.data));
  }

  @override
  Future<void> putToR2({
    required String putUrl,
    required List<int> bytes,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
    UploadCancellation? cancellation,
  }) async {
    final body = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    try {
      await _guardCancel(
        () => _r2Dio.put<void>(
          putUrl,
          // A single-chunk stream sends the bytes raw (no JSON encoding); the
          // explicit Content-Length lets R2 accept it (not chunked) and drives
          // onSendProgress.
          data: Stream<List<int>>.fromIterable(<List<int>>[body]),
          options: Options(
            contentType: mimeType, // MUST match the sign mime, or R2 rejects.
            headers: <String, Object?>{Headers.contentLengthHeader: body.length},
          ),
          onSendProgress: onProgress,
          cancelToken: _bridge(cancellation),
        ),
      );
    } on DioException catch (error) {
      // Not a cancel (that already became UploadCancelledException in
      // _guardCancel) — surface a distinct R2 rejection.
      throw R2UploadException(
        statusCode: error.response?.statusCode,
        message: error.message,
      );
    }
  }

  @override
  Future<UploadedAsset> finalize(
    String bid, {
    UploadCancellation? cancellation,
  }) async {
    final response = await _guardCancel(
      () => _apiDio.post<dynamic>(
        '/uploads/finalize',
        data: finalizeRequestJson(bid),
        cancelToken: _bridge(cancellation),
      ),
    );
    return assetFromJson(asMap(response.data));
  }

  /// Bridges the domain cancellation to a Dio [CancelToken]: cancelling the
  /// former cancels the in-flight request.
  CancelToken? _bridge(UploadCancellation? cancellation) {
    if (cancellation == null) return null;
    final token = CancelToken();
    if (cancellation.isCancelled) {
      token.cancel();
    } else {
      cancellation.whenCancelled.then((_) => token.cancel());
    }
    return token;
  }

  /// Runs [op], converting a Dio cancellation into [UploadCancelledException]
  /// (any other error propagates unchanged).
  Future<T> _guardCancel<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) throw const UploadCancelledException();
      rethrow;
    }
  }
}
