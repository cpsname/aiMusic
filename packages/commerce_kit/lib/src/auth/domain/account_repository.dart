import 'current_account.dart';

/// Authenticated account read (`GET /v1/auth/me`) over the business Dio
/// (`apiDio`), so it benefits from the auth interceptor's refresh-and-replay.
abstract interface class AccountRepository {
  Future<CurrentAccount> currentAccount();
}
