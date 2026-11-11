import 'package:dio/dio.dart';

import '../../common/json.dart';
import '../domain/account_repository.dart';
import '../domain/current_account.dart';
import 'account_dtos.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._apiDio);

  final Dio _apiDio;

  @override
  Future<CurrentAccount> currentAccount() async {
    final response = await _apiDio.get<dynamic>('/auth/me');
    return CurrentAccountDto.fromJson(asMap(response.data)).toDomain();
  }
}
