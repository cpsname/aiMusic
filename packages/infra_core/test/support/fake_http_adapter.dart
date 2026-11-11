import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A configurable [HttpClientAdapter] for driving Dio in tests. It records every
/// request and delegates the response to a responder keyed by call index, so
/// tests can simulate sequences (e.g. 503 → 503 → 200) and inspect headers.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.responder);

  /// Always returns the same JSON envelope.
  factory FakeHttpAdapter.always(Object? data, {int statusCode = 200}) =>
      FakeHttpAdapter((_, _) => jsonResponse(data, statusCode: statusCode));

  final FutureOr<ResponseBody> Function(RequestOptions options, int callIndex)
      responder;

  final List<RequestOptions> requests = <RequestOptions>[];
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final index = calls;
    calls += 1;
    return responder(options, index);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object? data, {int statusCode = 200}) =>
    ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
