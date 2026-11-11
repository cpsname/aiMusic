import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:commerce_kit/src/iap/data/iap_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal adapter that captures the request and returns a fixed create-order
/// envelope-unwrapped body (the EnvelopeInterceptor isn't in this bare Dio).
class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      jsonEncode({
        'order_no': 'ORD-1',
        'product_code': 'pro_monthly',
        'store_product_id': 'com.example.pro_monthly',
        'amount_cents': 998,
        'currency': 'USD',
        'expires_at': 1893456000,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const uuid = '0193b9a0-7c8d-7e3f-9a01-abcdef012345';

  IapRepositoryImpl repoWith(_CaptureAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
      ..httpClientAdapter = adapter;
    return IapRepositoryImpl(
      authDio: dio,
      apiDio: dio,
      distributionCode: 'ios_global',
    );
  }

  test('createOrder includes push_token when provided', () async {
    final adapter = _CaptureAdapter();
    await repoWith(adapter).createOrder(
      distributionCode: 'ios_global',
      productCode: 'pro_monthly',
      pushToken: uuid,
    );

    final body = adapter.captured!.data! as Map;
    expect(body['distribution_code'], 'ios_global');
    expect(body['product_code'], 'pro_monthly');
    expect(body['push_token'], uuid);
  });

  test('createOrder omits push_token when null or empty', () async {
    final adapter = _CaptureAdapter();
    await repoWith(adapter).createOrder(
      distributionCode: 'ios_global',
      productCode: 'pro_monthly',
    );
    expect((adapter.captured!.data! as Map).containsKey('push_token'), isFalse);

    final adapter2 = _CaptureAdapter();
    await repoWith(adapter2).createOrder(
      distributionCode: 'ios_global',
      productCode: 'pro_monthly',
      pushToken: '',
    );
    expect((adapter2.captured!.data! as Map).containsKey('push_token'), isFalse);
  });
}
