import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

import '../../common/billing.dart';
import '../data/wallet_repository_impl.dart';
import '../domain/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepositoryImpl(ref.watch(apiDioProvider)),
);

/// The wallet snapshot. Refreshed via `ref.invalidate(walletSnapshotProvider)`
/// on: startup, IAP verify success, task terminal states, and foreground resume.
final walletSnapshotProvider = FutureProvider<WalletSnapshot>(
  (ref) => ref.watch(walletRepositoryProvider).fetch(),
);

/// Available balance (0 until the snapshot resolves).
final walletBalanceProvider = Provider<int>(
  (ref) => ref.watch(walletSnapshotProvider).value?.balance ?? 0,
);

/// Features that are granted and not expired.
final activeWalletFeaturesProvider = Provider<List<WalletFeature>>((ref) {
  final snapshot = ref.watch(walletSnapshotProvider).value;
  if (snapshot == null) return const <WalletFeature>[];
  return activeFeatures(snapshot.features, DateTime.now().toUtc());
});

/// Feature gate: true when [code] is active (granted + unexpired).
final hasFeatureProvider = Provider.family<bool, String>(
  (ref, code) =>
      ref.watch(activeWalletFeaturesProvider).any((f) => f.code == code),
);

/// Pure helper: the subset of [features] active at [now].
List<WalletFeature> activeFeatures(List<WalletFeature> features, DateTime now) =>
    features.where((feature) => feature.isActiveAt(now)).toList(growable: false);
