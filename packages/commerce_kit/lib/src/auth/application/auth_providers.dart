import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:riverpod/misc.dart' show Override;

import '../data/account_repository_impl.dart';
import '../data/auth_repository_impl.dart';
import '../domain/account_repository.dart';
import '../domain/auth_phase.dart';
import '../domain/auth_repository.dart';
import '../domain/current_account.dart';
import 'auth_controller.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authDioProvider)),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepositoryImpl(ref.watch(apiDioProvider)),
);

final authControllerProvider = NotifierProvider<AuthController, AuthPhase>(
  AuthController.new,
);

/// Authenticated account context (`/me`). Re-fetches when the session identity
/// changes (login/logout/guest upgrade).
final currentAccountProvider = FutureProvider<CurrentAccount>((ref) async {
  ref.watch(authControllerProvider);
  return ref.read(accountRepositoryProvider).currentAccount();
});

/// Riverpod overrides commerce_kit contributes to the root `ProviderScope`:
/// binds infra_core's [authGatewayProvider] to the real [AuthController].
List<Override> commerceKitOverrides() => <Override>[
      authGatewayProvider.overrideWith(
        (ref) => ref.watch(authControllerProvider.notifier),
      ),
    ];
