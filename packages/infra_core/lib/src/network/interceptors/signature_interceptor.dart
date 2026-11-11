import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../config/env_config.dart';
import '../../crypto/signing_service.dart';
import '../api_headers.dart';

/// Signs every outgoing request: injects `X-Distribution-Code`, a fresh
/// `X-Timestamp` (Unix seconds) + `X-Nonce` (UUID v4), and the resulting
/// `X-App-Signature` over `timestamp + nonce + canonicalJson(body)`.
///
/// A fresh nonce/timestamp per attempt means retries and refresh-replays
/// re-sign cleanly (no `40113` nonce reuse). Bodies must be passed as Maps so
/// the canonical JSON matches the server's `json.Marshal`.
class SignatureInterceptor extends Interceptor {
  SignatureInterceptor({
    required EnvConfig config,
    required SigningService signing,
    Uuid uuid = const Uuid(),
    DateTime Function()? clock,
  })  : _config = config,
        _signing = signing,
        _uuid = uuid,
        _clock = clock ?? DateTime.now;

  final EnvConfig _config;
  final SigningService _signing;
  final Uuid _uuid;
  final DateTime Function() _clock;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final timestamp = (_clock().millisecondsSinceEpoch ~/ 1000).toString();
    final nonce = _uuid.v4();
    final signature = _signing.sign(
      secret: _config.distributionSecret,
      timestamp: timestamp,
      nonce: nonce,
      body: options.data,
    );
    options.headers[ApiHeaders.distributionCode] = _config.distributionCode;
    options.headers[ApiHeaders.timestamp] = timestamp;
    options.headers[ApiHeaders.nonce] = nonce;
    options.headers[ApiHeaders.appSignature] = signature;
    handler.next(options);
  }
}
