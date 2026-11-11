import 'auth_session.dart';

/// Token-lifecycle operations. All run over the no-auth Dio (`authDio`); none
/// requires the auth interceptor, which keeps the controller free of a cycle
/// with `apiDio`.
abstract interface class AuthRepository {
  Future<TokenBundle> guestRegister(AppDescriptor app);

  Future<TokenBundle> login({required String username, required String password});

  Future<TokenBundle> refresh(String refreshToken);

  Future<void> logout(String accessToken);

  Future<void> logoutAll(String accessToken);
}
