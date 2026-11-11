import 'package:meta/meta.dart';

import 'work.dart';

/// The user's iCloud account as CloudKit sees it (ADR-0013).
enum CloudAccount {
  available,
  noAccount,
  restricted,

  /// Temporarily unavailable, or CloudKit not reachable.
  unavailable;

  static CloudAccount fromWire(String? value) =>
      values.firstWhere((v) => v.name == value, orElse: () => unavailable);
}

/// One change pulled from the private database.
@immutable
class CloudWorkChange {
  const CloudWorkChange.upsert(Work this.work, {this.audioPath}) : workId = null;

  const CloudWorkChange.deleted(String this.workId)
      : work = null,
        audioPath = null;

  /// The work (null for a deletion).
  final Work? work;

  /// Temporary local copy of the work's audio asset, when it has one.
  final String? audioPath;

  /// Id of a deleted work.
  final String? workId;

  String get id => work?.id ?? workId!;
  bool get isDeletion => work == null;
}

/// Opt-in library sync through the CloudKit **private** database (PRD F10:
/// "iCloud 同步默认关，可开"; ADR-0013). Works never reach the Songlet backend.
abstract interface class CloudSyncGateway {
  Future<CloudAccount> account();

  /// Saves [work] (metadata + its audio at [audioPath]) — last writer wins.
  Future<void> push(Work work, {String? audioPath});

  /// Tombstones [workId] so other devices remove it too.
  Future<void> remove(String workId);

  /// Changes since [since] (everything when null).
  Future<List<CloudWorkChange>> pull({DateTime? since});
}
