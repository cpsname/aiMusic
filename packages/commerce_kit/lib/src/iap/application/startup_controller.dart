import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:meta/meta.dart';

import '../../auth/application/auth_providers.dart';
import '../../wallet/application/wallet_providers.dart';
import '../domain/iap_models.dart';
import 'iap_providers.dart';

@immutable
sealed class StartupState {
  const StartupState();
}

final class StartupInProgress extends StartupState {
  const StartupInProgress();
}

final class StartupForceUpdate extends StartupState {
  const StartupForceUpdate(this.update);
  final UpdateInfo update;
}

final class StartupReady extends StartupState {
  const StartupReady();
}

final class StartupFailed extends StartupState {
  const StartupFailed(this.failure);
  final Failure failure;
}

/// Cold-start sequence: in parallel run `/app/init` (no-auth) and
/// `ensureAuthenticated` (guest-register) → force-update gate → ready →
/// fire-and-forget prefetch of `/me` + `/wallet` and recovery of pending orders.
class StartupController extends Notifier<StartupState> {
  @override
  StartupState build() => const StartupInProgress();

  Future<void> start() async {
    state = const StartupInProgress();

    // Gate 0 — this binary's own config, checked before a single request.
    // A build launched without `--dart-define-from-file=config/<env>.json`
    // (a bare `flutter run`, or an Xcode Archive taken before `make xcconfig`)
    // has no signing secret and no distribution code, so the guest-register
    // below — and every later call — comes back rejected by the app-signature
    // middleware. Failing here names the missing keys instead of surfacing it
    // as a connection problem, and `ConfigFailure` is non-retryable so the
    // screen does not offer an action that cannot work.
    final env = ref.read(envConfigProvider);
    if (!env.isComplete) {
      state = StartupFailed(
        ConfigFailure(message: '', missingKeys: env.missingKeys),
      );
      return;
    }

    try {
      // Load device identity + preferences first, so request headers,
      // clientVersion, and the (synchronous) KeyValueStore are all ready before
      // anything reads them.
      await ref.read(deviceProfileProvider.future);
      await ref.read(sharedPreferencesProvider.future);

      // Migrate persisted storage to the current schema BEFORE any store reads
      // it. A migration must never block boot — degrade and report on failure.
      try {
        await ref
            .read(storageMigratorProvider)
            .run(ref.read(keyValueStoreProvider));
      } on Object catch (error, stack) {
        ref.read(telemetrySinkProvider).recordError(error, stack, fatal: false);
      }

      // `appInitProvider` is cache-first and the single source shared with the
      // paywall, so `/app/init` is hit at most once per boot session.
      AppInitData? appInit;
      await Future.wait<void>([
        ref.read(appInitProvider.future).then((data) => appInit = data),
        ref.read(authControllerProvider.notifier).ensureAuthenticated(),
      ]);

      final update = appInit?.update;
      if (update != null && update.forceUpdate) {
        state = StartupForceUpdate(update);
        return;
      }

      state = const StartupReady();

      // Warm caches without blocking; activate the long-lived reconciler so
      // re-delivered/renewal transactions are handled, and prune stale orders.
      _prefetch(ref.read(currentAccountProvider.future));
      _prefetch(ref.read(walletSnapshotProvider.future));
      final reconciler = ref.read(iapReconcilerProvider);
      unawaited(reconciler.pruneStalePendingOrders());
    } on Object catch (error, stackTrace) {
      state = StartupFailed(
        ref.read(errorHandlerProvider).handle(error, stackTrace),
      );
    }
  }

  void _prefetch(Future<Object?> future) {
    future.then((_) {}, onError: (Object _, StackTrace _) {});
  }
}
