import 'package:infra_core/infra_core.dart';
import 'package:meta/meta.dart';

/// Observable authentication state machine:
/// `Idle → Registering → Authenticated | Error`.
@immutable
sealed class AuthPhase {
  const AuthPhase();
}

/// No session yet (and none being established).
final class AuthIdle extends AuthPhase {
  const AuthIdle();
}

/// A session is being established (guest-register, login, or refresh).
final class AuthRegistering extends AuthPhase {
  const AuthRegistering();
}

/// Authenticated. The raw tokens are held privately by the controller; only the
/// identity is exposed here.
final class AuthAuthenticated extends AuthPhase {
  const AuthAuthenticated({
    required this.userId,
    required this.isGuest,
    this.isNewUser = false,
  });

  final String userId;
  final bool isGuest;

  /// True only right after a guest-register that minted a **new** account
  /// (`is_new_user`). Per the identity contract this means any prior guest is
  /// unrecoverable (the `device_id` idempotency anchor changed). Restore /
  /// refresh / login always report false.
  final bool isNewUser;
}

/// Authentication failed; carries the typed failure for presentation.
final class AuthError extends AuthPhase {
  const AuthError(this.failure);

  final Failure failure;
}
