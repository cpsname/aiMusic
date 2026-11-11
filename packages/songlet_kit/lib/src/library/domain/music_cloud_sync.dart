import 'package:meta/meta.dart';

import 'music_work.dart';

/// The user's iCloud account as CloudKit sees it (ADR-0013).
enum MusicCloudAccount {
  available,
  noAccount,
  restricted,

  /// Temporarily unavailable, or CloudKit not reachable.
  unavailable;

  static MusicCloudAccount fromWire(String? value) =>
      values.firstWhere((v) => v.name == value, orElse: () => unavailable);
}

/// One change pulled from the private database.
@immutable
class MusicCloudWorkChange {
  const MusicCloudWorkChange.upsert(MusicWork this.work, {this.audioPath}) : workId = null;

  const MusicCloudWorkChange.deleted(String this.workId)
      : work = null,
        audioPath = null;

  /// The work (null for a deletion).
  final MusicWork? work;

  /// Temporary local copy of the work's audio asset, when it has one.
  final String? audioPath;

  /// Id of a deleted work.
  final String? workId;

  String get id => work?.id ?? workId!;
  bool get isDeletion => work == null;
}

/// Opt-in library sync through the CloudKit **private** database (PRD F10:
/// "iCloud 同步默认关，可开"; ADR-0013). Works never reach the Songlet backend.
abstract interface class MusicCloudSyncGateway {
  Future<MusicCloudAccount> account();

  /// Saves [work] (metadata + its audio at [audioPath]) — last writer wins.
  Future<void> push(MusicWork work, {String? audioPath});

  /// Tombstones [workId] so other devices remove it too.
  Future<void> remove(String workId);

  /// Changes since [since] (everything when null).
  Future<List<MusicCloudWorkChange>> pull({DateTime? since});
}
