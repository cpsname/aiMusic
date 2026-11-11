import 'music_generation.dart';

/// The Lyria proxy of the Songlet backend (PRD §6.3).
abstract interface class MusicGenerationRepository {
  /// `POST /v1/generate`.
  Future<MusicGenerationTicket> submit(MusicGenerationRequest request);

  /// `GET /v1/jobs/{job_id}`.
  Future<MusicJobSnapshot> job(String jobId);

  /// `DELETE /v1/jobs/{job_id}` (ADR-0012).
  Future<MusicCancelOutcome> cancel(String jobId);
}

/// Uploads a picked photo (JPEG bytes) and returns its upload bid — the monolith's
/// generic two-stage upload (media_kit). The bytes never touch the disk.
abstract interface class MusicPhotoUploader {
  Future<String> upload(List<int> jpeg, {required String filename});
}
