import 'package:dio/dio.dart';

import '../../error/api_error.dart';
import '../api_envelope.dart';

/// Unwraps the response envelope. On `code == 0` it replaces `response.data`
/// with the inner `data`; on any non-zero code it rejects with a typed
/// [ApiError] attached to a `DioException` (propagated to following error
/// interceptors so the logger can record it).
class EnvelopeInterceptor extends Interceptor {
  const EnvelopeInterceptor();

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final data = response.data;
    if (!ApiEnvelope.looksLikeEnvelope(data)) {
      handler.next(response);
      return;
    }
    final envelope = ApiEnvelope.fromMap(data! as Map);
    response.requestOptions.extra[ApiEnvelope.requestIdExtraKey] =
        envelope.requestId;
    if (envelope.isSuccess) {
      response.data = envelope.data;
      handler.next(response);
      return;
    }
    handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: envelope.toApiError(),
      ),
      true,
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiError) {
      handler.next(err);
      return;
    }
    final data = err.response?.data;
    if (ApiEnvelope.looksLikeEnvelope(data)) {
      final envelope = ApiEnvelope.fromMap(data! as Map);
      if (!envelope.isSuccess) {
        err.requestOptions.extra[ApiEnvelope.requestIdExtraKey] =
            envelope.requestId;
        handler.next(
          err.copyWith(error: envelope.toApiError()),
        );
        return;
      }
    }
    handler.next(err);
  }
}
