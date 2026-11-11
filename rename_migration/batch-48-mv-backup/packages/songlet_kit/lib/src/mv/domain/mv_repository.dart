import 'mv.dart';

/// The music-video endpoints of the Songlet backend (contract v1.1 §3).
abstract interface class MvRepository {
  /// `POST /v1/mv/estimate` — price [level] for the song of [jobId] (locks
  /// the song on the platform).
  Future<MvEstimate> estimate(String jobId, MvLevel level);

  /// `POST /v1/works/{job_id}/mv`.
  Future<MvTicket> create(String jobId, MvRequest request);

  /// `GET /v1/mv/{mv_id}`.
  Future<MvSnapshot> mv(String mvId);

  /// `DELETE /v1/mv/{mv_id}`.
  Future<MvCancelOutcome> cancel(String mvId);
}
