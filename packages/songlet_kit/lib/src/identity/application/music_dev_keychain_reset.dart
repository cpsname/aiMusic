import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether this binary carries the DEV-only Keychain reset at all: a debug
/// build **and** the `ENV` define spelled exactly `dev`.
///
/// Both operands are compile-time constants, so in a profile or release build,
/// and for `ENV=mock` / `staging` / `prod` / no define, this is `false` and
/// every branch behind it is removed by the compiler — the capability is not
/// hidden there, it does not exist. (`EnvConfig.isDev` is deliberately not
/// used: it also reads `mock` and an absent define as dev.)
const bool devKeychainResetAvailable =
    kDebugMode && String.fromEnvironment('ENV') == 'dev';

/// The DEV-only Keychain reset, or null whenever [devKeychainResetAvailable]
/// is false — the only way to reach [MusicDevKeychainReset], whose constructor is
/// private.
final devKeychainResetProvider = Provider<MusicDevKeychainReset?>(
  (ref) => devKeychainResetAvailable ? MusicDevKeychainReset._(ref) : null,
);

/// Deletes this app's iOS Keychain keys — the persistent device id
/// (`device.id`, the guest's identity anchor and `app_account_token`) and the
/// session tokens — then signs in as a brand-new guest
/// (`AuthController.deleteAccount`). The previous guest cannot be recovered.
final class MusicDevKeychainReset {
  MusicDevKeychainReset._(this._ref);

  final Ref _ref;

  Future<void> run() async {
    // Second line of defence: refuse even if an instance was reached some
    // other way in a build without the capability.
    if (!devKeychainResetAvailable) {
      throw StateError('The Keychain reset is a DEV-only tool.');
    }
    await _ref.read(authControllerProvider.notifier).deleteAccount();
    // The new guest has its own balance.
    _ref.invalidate(walletSnapshotProvider);
  }
}
