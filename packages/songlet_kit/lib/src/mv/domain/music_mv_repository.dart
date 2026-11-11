import 'music_mv.dart';

/// The music-video endpoints of the Songlet backend (contract v1.1 §3).
abstract interface class MusicMvRepository {
  /// `POST /v1/mv/estimate` — price [level] for the song of [jobId] (locks
  /// the song on the platform).
  Future<MusicMvEstimate> estimate(String jobId, MusicMvLevel level);

  /// `POST /v1/works/{job_id}/mv`.
  Future<MusicMvTicket> create(String jobId, MusicMvRequest request);

  /// `GET /v1/mv/{mv_id}`.
  Future<MusicMvSnapshot> mv(String mvId);

  /// `DELETE /v1/mv/{mv_id}`.
  Future<MusicMvCancelOutcome> cancel(String mvId);
}
