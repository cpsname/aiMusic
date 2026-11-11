import 'package:dio/dio.dart';
import 'package:infra_core/infra_core.dart';

import '../../common/json.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import 'auth_dtos.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._authDio);

  final Dio _authDio;

  @override
  Future<TokenBundle> guestRegister(AppDescriptor app) async {
    final response = await _authDio.post<dynamic>(
      '/auth/guest-register',
      data: {'app': app.toJson()},
    );
    return GuestRegisterResponseDto.fromJson(asMap(response.data)).toDomain();
  }

  @override
  Future<TokenBundle> login({
    required String username,
    required String password,
  }) async {
    final response = await _authDio.post<dynamic>(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return TokenResponseDto.fromJson(asMap(response.data)).toDomain();
  }

  @override
  Future<TokenBundle> refresh(String refreshToken) async {
    final response = await _authDio.post<dynamic>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return TokenResponseDto.fromJson(asMap(response.data)).toDomain();
  }

  @override
  Future<void> logout(String accessToken) => _authDio.post<dynamic>(
        '/auth/logout',
        options: _bearer(accessToken),
      );

  @override
  Future<void> logoutAll(String accessToken) => _authDio.post<dynamic>(
        '/auth/logout/all',
        options: _bearer(accessToken),
      );

  Options _bearer(String token) =>
      Options(headers: {ApiHeaders.authorization: 'Bearer $token'});
}
