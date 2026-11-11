import 'dart:io';

import 'package:infra_core/infra_core.dart';
import 'package:path/path.dart' as p;

import '../../creation/domain/generation_repository.dart';
import '../../creation/domain/music_error_code.dart';
import '../../library/domain/work.dart';
import '../../library/domain/work_repository.dart';
import '../../platform/domain/native_gateways.dart';
import '../domain/license_repository.dart';

/// Outcome of a download (PRD F09).
enum ExportOutcome { saved, cancelled }

/// Single-file downloads of the P11 page.
enum ExportFile { mp3, wav, license }

/// Downloads (PRD F09; docs/ui P11): the MP3 (ID3-tagged "AI generated", PRD
/// §9.4), the Premier WAV (ADR-0010), the commercial-license PDF, or all of
/// them with the lyrics as one folder — saved through the system document
/// picker.
///
/// The gate is the server's license endpoint: it refuses free accounts and
/// works funded by a refunded purchase or a lapsed plan (`DOWNLOAD_LOCKED`,
/// PRD §8.4 — such works stay playable).
class ExportService {
  ExportService({
    required AudioStore audio,
    required LicenseRepository licenses,
    required FileExporter exporter,
    required GenerationRepository jobs,
  })  : _audio = audio,
        _licenses = licenses,
        _exporter = exporter,
        _jobs = jobs;

  final AudioStore _audio;
  final LicenseRepository _licenses;
  final FileExporter _exporter;
  final GenerationRepository _jobs;

  /// The license of [work] — also the download gate. Throws the server's
  /// `DOWNLOAD_LOCKED` error for a locked work.
  Future<LicenseDocument> license(Work work) {
    final jobId = work.jobId;
    if (!work.isReady || jobId == null) throw const CacheFailure(message: '');
    return _licenses.license(jobId);
  }

  /// "Save to Files": folder with MP3 + lyrics + license PDF.
  Future<ExportOutcome> export(Work work, {required String folderName}) async {
    final audioFile = work.audioFile;
    final document = await license(work);
    if (audioFile == null) throw const CacheFailure(message: '');

    final scratch = Directory(p.join(await _audio.scratchDirectory(), 'export-${work.id}'));
    if (scratch.existsSync()) await scratch.delete(recursive: true);
    final folder = Directory(p.join(scratch.path, _safe(folderName)));
    await folder.create(recursive: true);
    final base = _safe(folderName);
    await File(await _audio.pathOf(audioFile)).copy(p.join(folder.path, '$base.mp3'));
    await File(p.join(folder.path, 'lyrics.txt')).writeAsString(_lyricsText(work), flush: true);
    await File(p.join(folder.path, 'license.pdf')).writeAsBytes(document.pdf, flush: true);

    try {
      final saved = await _exporter.exportToFiles(folder.path, p.basename(folder.path));
      return saved ? ExportOutcome.saved : ExportOutcome.cancelled;
    } finally {
      if (scratch.existsSync()) await scratch.delete(recursive: true);
    }
  }

  /// One file to Files. The WAV is rendered for Premier full songs only; its
  /// short-lived link is fetched from the job on request (ADR-0010).
  Future<ExportOutcome> saveFile(Work work, ExportFile file, {required String name}) async {
    final base = _safe(name);
    final document = await license(work);
    final scratch = Directory(p.join(await _audio.scratchDirectory(), 'file-${work.id}'));
    if (scratch.existsSync()) await scratch.delete(recursive: true);
    await scratch.create(recursive: true);
    try {
      final String path;
      switch (file) {
        case ExportFile.mp3:
          final audioFile = work.audioFile;
          if (audioFile == null) throw const CacheFailure(message: '');
          path = p.join(scratch.path, '$base.mp3');
          await File(await _audio.pathOf(audioFile)).copy(path);
        case ExportFile.license:
          path = p.join(scratch.path, '$base – license.pdf');
          await File(path).writeAsBytes(document.pdf, flush: true);
        case ExportFile.wav:
          final snapshot = await _jobs.job(work.jobId!);
          final url = snapshot.wavUrl;
          // No link = not rendered for this plan: the same refusal as a
          // locked download.
          if (url == null) throw MusicErrorCode.downloadLocked.toApiError();
          final fetched = await _audio.fetchToScratch(url: url, fileName: 'file-${work.id}.wav');
          path = p.join(scratch.path, '$base.wav');
          await File(fetched).rename(path);
      }
      final saved = await _exporter.exportToFiles(path, p.basename(path));
      return saved ? ExportOutcome.saved : ExportOutcome.cancelled;
    } finally {
      if (scratch.existsSync()) await scratch.delete(recursive: true);
    }
  }

  /// The tagged MP3's path, for the system share sheet ("Add to Music",
  /// ADR-0010). Gated like every download.
  Future<String> shareableAudio(Work work) async {
    await license(work);
    final audioFile = work.audioFile;
    if (audioFile == null) throw const CacheFailure(message: '');
    return _audio.pathOf(audioFile);
  }

  static String _lyricsText(Work work) => [
        work.lyrics.trim(),
        '',
        '— AI generated with Google Lyria 3 · contains a SynthID watermark.',
        if (work.jobId != null) 'Interaction ID: ${work.jobId}',
      ].join('\n');

  static String _safe(String name) {
    final cleaned = name.replaceAll(RegExp(r'[/\\:*?"<>|\n\r]+'), ' ').trim();
    return cleaned.isEmpty ? 'Songlet' : cleaned;
  }
}
