import 'generation.dart';

/// The Lyria proxy of the Songlet backend (PRD §6.3).
abstract interface class GenerationRepository {
  /// `POST /v1/generate`.
  Future<GenerationTicket> submit(GenerationRequest request);

  /// `GET /v1/jobs/{job_id}`.
  Future<JobSnapshot> job(String jobId);

  /// `DELETE /v1/jobs/{job_id}` (ADR-0012).
  Future<CancelOutcome> cancel(String jobId);
}

/// Uploads a picked photo (JPEG bytes) and returns its upload bid — the monolith's
/// generic two-stage upload (media_kit). The bytes never touch the disk.
abstract interface class PhotoUploader {
  Future<String> upload(List<int> jpeg, {required String filename});
}
