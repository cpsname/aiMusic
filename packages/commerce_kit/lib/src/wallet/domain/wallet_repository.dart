import '../../common/billing.dart';

/// Reads the current account's wallet (`GET /v1/wallet`).
abstract interface class WalletRepository {
  Future<WalletSnapshot> fetch();
}
