import 'dart:async';

import 'package:dio/dio.dart';
import 'package:infra_core/infra_core.dart';

import '../domain/iap_repository.dart';
import '../domain/order_models.dart';

/// Shared `verify` kernel used by both the purchase orchestrator and the
/// background reconciler (one verify→finish core, per spec §2).
///
/// Backs off on retryable codes + network timeouts and treats `40011`
/// (transaction already used) as an idempotent success.
class IapVerifier {
  IapVerifier({required IapRepository repository, required List<Duration> backoff})
      : _repository = repository,
        _backoff = backoff;

  /// Retryable (back off): order-not-pending / verify-in-flight / optimistic
  /// lock / server / store-unavailable / store-platform.
  static const Set<int> retryableCodes = {
    40010,
    40016,
    40912,
    50000,
    50301,
    50302,
  };

  final IapRepository _repository;
  final List<Duration> _backoff;

  Future<VerifyResult> verify({
    required String orderNo,
    required String transactionId,
    void Function(int attempt)? onAttempt,
  }) async {
    for (var attempt = 0;; attempt++) {
      onAttempt?.call(attempt);
      try {
        return await _repository.verify(
          orderNo: orderNo,
          transactionId: transactionId,
        );
      } on DioException catch (error) {
        final apiError = error.error;
        if (apiError is ApiError) {
          if (apiError.code == ApiCodes.orderAlreadyUsed) {
            return VerifyResult(
              orderNo: orderNo,
              status: 'completed',
              grantStatus: 'granted',
            );
          }
          if (retryableCodes.contains(apiError.code) &&
              attempt < _backoff.length) {
            await Future<void>.delayed(_backoff[attempt]);
            continue;
          }
          rethrow;
        }
        if (_isTransient(error.type) && attempt < _backoff.length) {
          await Future<void>.delayed(_backoff[attempt]);
          continue;
        }
        rethrow;
      }
    }
  }

  bool _isTransient(DioExceptionType type) => switch (type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError =>
          true,
        _ => false,
      };
}
