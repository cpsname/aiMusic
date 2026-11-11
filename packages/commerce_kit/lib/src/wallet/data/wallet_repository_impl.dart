import 'package:dio/dio.dart';

import '../../common/billing.dart';
import '../../common/json.dart';
import '../domain/wallet_repository.dart';
import 'wallet_dtos.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._apiDio);

  final Dio _apiDio;

  @override
  Future<WalletSnapshot> fetch() async {
    final response = await _apiDio.get<dynamic>('/wallet');
    return WalletResponseDto.fromJson(asMap(response.data)).toDomain();
  }
}
