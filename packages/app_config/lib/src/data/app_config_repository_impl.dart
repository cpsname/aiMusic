import 'package:dio/dio.dart';

import '../domain/app_config.dart';
import '../domain/app_config_repository.dart';
import 'app_config_dto.dart';
import 'json_coerce.dart';

/// Fetches `GET /app/config` over the app-signed, no-JWT Dio. Signature,
/// `X-Distribution-Code` injection, clock-sync and envelope unwrapping are all
/// applied by the infra_core interceptor chain, so this just issues the GET and
/// parses the unwrapped body. A GET has no body → the signature is computed over
/// the literal `{}`.
class AppConfigRepositoryImpl implements AppConfigRepository {
  AppConfigRepositoryImpl(this._authDio);

  final Dio _authDio;

  @override
  Future<AppConfig> fetch() async {
    final response = await _authDio.get<dynamic>('/app/config');
    return AppConfigDto.fromJson(asMap(response.data));
  }
}
