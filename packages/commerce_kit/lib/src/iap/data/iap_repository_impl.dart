import 'package:dio/dio.dart';

import '../../common/json.dart';
import '../domain/iap_models.dart';
import '../domain/iap_repository.dart';
import '../domain/order_models.dart';
import 'iap_dtos.dart';

class IapRepositoryImpl implements IapRepository {
  IapRepositoryImpl({
    required Dio authDio,
    required Dio apiDio,
    required String distributionCode,
  })  : _authDio = authDio,
        _apiDio = apiDio,
        _distributionCode = distributionCode;

  final Dio _authDio;
  final Dio _apiDio;
  final String _distributionCode;

  @override
  Future<AppInitData> appInit({String? clientVersion}) async {
    final response = await _authDio.post<dynamic>(
      '/app/init',
      data: {
        'distribution_code': _distributionCode,
        'client_version': ?clientVersion,
      },
    );
    return AppInitResponseDto.fromJson(asMap(response.data)).toDomain();
  }

  @override
  Future<CreateOrderResult> createOrder({
    required String distributionCode,
    required String productCode,
    String? pushToken,
  }) async {
    final response = await _apiDio.post<dynamic>(
      '/iap/orders',
      data: {
        'distribution_code': distributionCode,
        'product_code': productCode,
        if (pushToken != null && pushToken.isNotEmpty) 'push_token': pushToken,
      },
    );
    return CreateOrderResponseDto.fromJson(asMap(response.data)).toDomain();
  }

  @override
  Future<VerifyResult> verify({
    required String orderNo,
    required String transactionId,
  }) async {
    final response = await _apiDio.post<dynamic>(
      '/iap/orders/$orderNo/verify',
      data: {'transaction_id': transactionId},
    );
    return VerifyReceiptResponseDto.fromJson(asMap(response.data)).toDomain();
  }
}
