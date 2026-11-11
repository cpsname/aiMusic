import 'dart:async';

import 'music_entitlement.dart';

/// `POST /v1/entitlements/sync` (PRD §6.3).
abstract interface class MusicEntitlementRemote {
  Future<MusicEntitlement> sync({
    required String appAccountToken,
    required List<String> signedTransactions,
  });
}

/// `Transaction.currentEntitlements` as JWS (the Pigeon bridge).
abstract interface class MusicSignedTransactionSource {
  Future<List<String>> currentSignedTransactions();
}

/// Durable queue of signed transactions the server has not acknowledged yet —
/// purchase results, `Transaction.updates` (renewals, refunds/revocations,
/// Ask-to-Buy approvals) and restores. StoreKit finishes transactions natively
/// (the fixed bridge has no finish call), so this queue is what guarantees a
/// consumable pack or a refund reaches the ledger even if a sync fails or the
/// app is killed.
abstract interface class MusicSignedTransactionOutbox {
  List<String> pending();

  Future<void> add(String jws);

  Future<void> removeAll(Iterable<String> jws);
}

/// Pushes the device's signed transactions to the ledger and returns the
/// server-authoritative allowance. Single-flight: concurrent callers (wallet
/// refresh, account refresh, purchase verify) share one request.
class MusicEntitlementSync {
  MusicEntitlementSync({
    required MusicEntitlementRemote remote,
    required MusicSignedTransactionSource source,
    required MusicSignedTransactionOutbox outbox,
    required Future<String> Function() appAccountToken,
  })  : _remote = remote,
        _source = source,
        _outbox = outbox,
        _appAccountToken = appAccountToken;

  final MusicEntitlementRemote _remote;
  final MusicSignedTransactionSource _source;
  final MusicSignedTransactionOutbox _outbox;
  final Future<String> Function() _appAccountToken;

  Future<MusicEntitlement>? _inFlight;
  MusicEntitlement? _latest;

  /// The most recent server answer, null before the first successful sync.
  MusicEntitlement? get latest => _latest;

  Future<MusicEntitlement> sync() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final run = _run();
    _inFlight = run;
    return run.whenComplete(() => _inFlight = null);
  }

  Future<MusicEntitlement> _run() async {
    final queued = _outbox.pending();
    List<String> current;
    try {
      current = await _source.currentSignedTransactions();
    } on Object {
      // The ledger still answers without them; the outbox covers new purchases.
      current = const <String>[];
    }
    final all = <String>{...queued, ...current}.toList(growable: false);
    final result = await _remote.sync(
      appAccountToken: await _appAccountToken(),
      signedTransactions: all,
    );
    await _outbox.removeAll(queued);
    _latest = result;
    return result;
  }
}
