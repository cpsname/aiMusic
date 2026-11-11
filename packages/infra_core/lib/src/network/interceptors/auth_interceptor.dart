import 'package:dio/dio.dart';

import '../../error/api_error.dart';
import '../../error/error_codes.dart';
import '../api_headers.dart';
import '../auth_gateway.dart';

/// Injects the bearer token and transparently handles auth-expiry.
///
/// As a [QueuedInterceptor] it serializes handling so only one refresh runs at
/// a time; concurrent requests that already saw the expiry simply replay with
/// the freshly minted token. Detection works whether the backend returns the
/// expiry as HTTP 200 + envelope `code` (handled in [onResponse]) or HTTP 401 +
/// envelope `code` (handled in [onError]).
///
/// * `40102` → single-flight refresh, then replay the original request through
///   [authDio] (which has no [AuthInterceptor]) to break recursion.
/// * `40106` → force logout (clear local session); never retried.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required AuthGateway gateway,
    required Dio authDio,
    int expiredCode = ApiCodes.tokenExpired,
    Set<int> forceLogoutCodes = const {ApiCodes.refreshReused},
  })  : _gateway = gateway,
        _authDio = authDio,
        _expiredCode = expiredCode,
        _forceLogoutCodes = forceLogoutCodes;

  final AuthGateway _gateway;
  final Dio _authDio;
  final int _expiredCode;
  final Set<int> _forceLogoutCodes;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _gateway.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers[ApiHeaders.authorization] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final code = _envelopeCode(response.data);
    if (code != null && _forceLogoutCodes.contains(code)) {
      response.requestOptions.extra[_handledKey] = true;
      await _gateway.forceLogout();
      handler.next(response);
      return;
    }
    if (code == _expiredCode) {
      response.requestOptions.extra[_handledKey] = true;
      await _refreshAndReplay(
        response.requestOptions,
        onResolved: handler.resolve,
        onRejected: (e) => handler.reject(e, true),
      );
      return;
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.requestOptions.extra[_handledKey] == true) {
      handler.next(err);
      return;
    }
    final code = _envelopeCode(err.response?.data) ??
        (err.error is ApiError ? (err.error! as ApiError).code : null);
    if (code != null && _forceLogoutCodes.contains(code)) {
      await _gateway.forceLogout();
      handler.next(err);
      return;
    }
    if (code == _expiredCode) {
      await _refreshAndReplay(
        err.requestOptions,
        onResolved: handler.resolve,
        onRejected: handler.reject,
      );
      return;
    }
    handler.next(err);
  }

  Future<void> _refreshAndReplay(
    RequestOptions original, {
    required void Function(Response<dynamic>) onResolved,
    required void Function(DioException) onRejected,
  }) async {
    final usedToken = _bearerToken(original);
    final current = _gateway.accessToken;

    // A prior queued request may already have refreshed: if the live token is
    // newer than the one this request used, skip refresh and just replay.
    var refreshed =
        current != null && current.isNotEmpty && current != usedToken;
    if (!refreshed) {
      refreshed = await _gateway.refresh();
    }

    if (!refreshed) {
      await _gateway.forceLogout();
      onRejected(
        DioException(
          requestOptions: original,
          type: DioExceptionType.badResponse,
          error: const AuthApiError(
            code: ApiCodes.refreshInvalid,
            message: 'Session expired',
            requiresForceLogout: true,
          ),
        ),
      );
      return;
    }

    final newToken = _gateway.accessToken;
    final replay = original.copyWith()..extra.remove(_attemptKey);
    if (newToken != null && newToken.isNotEmpty) {
      replay.headers[ApiHeaders.authorization] = 'Bearer $newToken';
    }
    try {
      final response = await _authDio.fetch<dynamic>(replay);
      onResolved(response);
    } on DioException catch (e) {
      onRejected(e);
    }
  }

  static const String _attemptKey = 'retry_attempt';

  /// Marks a request whose auth-expiry was already handled in [onResponse], so
  /// the round-tripped error does not get handled a second time in [onError].
  static const String _handledKey = 'auth_interceptor_handled';

  int? _envelopeCode(Object? data) {
    if (data is Map && data['code'] is int) {
      final code = data['code'] as int;
      return code == 0 ? null : code;
    }
    return null;
  }

  String? _bearerToken(RequestOptions options) {
    final header = options.headers[ApiHeaders.authorization];
    if (header is String && header.startsWith('Bearer ')) {
      return header.substring('Bearer '.length);
    }
    return null;
  }
}
