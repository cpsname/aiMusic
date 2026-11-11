import 'package:meta/meta.dart';

import '../../creation/domain/generation.dart';
import '../../creation/domain/occasion.dart';
import '../../creation/domain/song_options.dart';
import '../../creation/domain/song_template.dart';

/// Lifecycle of a work in the local library.
enum WorkStatus {
  /// Submitted; the job is still running (resumed after an app restart).
  pending,

  /// Audio downloaded; playable offline.
  ready,

  /// The job failed (the ledger refunded it); kept so the user sees why.
  failed;

  static WorkStatus fromWire(String value) =>
      WorkStatus.values.firstWhere((s) => s.name == value, orElse: () => failed);
}

/// A generated clip or song, stored locally (PRD F10: no account; SQLite).
/// Keeps the inputs and the `interaction.id` (= job id) so the same style can be
/// regenerated (PRD §5.1).
@immutable
class Work {
  const Work({
    required this.id,
    required this.model,
    required this.status,
    required this.occasion,
    required this.region,
    required this.genre,
    required this.lyricLanguage,
    required this.createdAt,
    this.jobId,
    this.template,
    this.inspiration,
    this.vocals = Vocals.vocals,
    this.prompt = '',
    this.festival,
    this.recipient = '',
    this.keywords = const <String>[],
    this.userLyrics,
    this.promptNote = '',
    this.imageBids = const <String>[],
    this.lyrics = '',
    this.structure = const <LyricSection>[],
    this.audioFile,
    this.errorCode,
    this.parentId,
    this.autoVideo = AutoVideo.none,
  });

  /// Local id — also the `client_ref` of the generate call.
  final String id;
  final SongModel model;
  final WorkStatus status;
  final Occasion occasion;
  final String region;

  /// Region preset genre or `Genre.label`; empty = custom (prompt decides).
  final String genre;
  final String lyricLanguage;
  final DateTime createdAt;

  /// Backend job id = the Lyria `interaction.id` (PRD §5.1 / §9.1).
  final String? jobId;
  final SongTemplate? template;

  /// The inspiration the song was started from (its slug; contract 02 v2.1),
  /// so "another version" sends it again.
  final String? inspiration;
  final Vocals vocals;

  /// The composer's free-text description.
  final String prompt;
  final Festival? festival;
  final String recipient;
  final List<String> keywords;
  final String? userLyrics;
  final String promptNote;
  final List<String> imageBids;
  final String lyrics;
  final List<LyricSection> structure;

  /// Audio file name inside the library's audio directory.
  final String? audioFile;
  final String? errorCode;

  /// The clip a full song was made from.
  final String? parentId;

  /// The music video to make once the song is ready (docs/ui P28). Local to
  /// this device: not synced; set back to [AutoVideo.none] once the video
  /// was started or declined.
  final AutoVideo autoVideo;

  bool get isClip => model == SongModel.clip;
  bool get isInstrumental => vocals == Vocals.instrumental;
  bool get hasCustomGenre => genre.isEmpty;
  bool get isReady => status == WorkStatus.ready && audioFile != null;

  Work copyWith({
    WorkStatus? status,
    String? jobId,
    String? lyrics,
    List<LyricSection>? structure,
    String? audioFile,
    String? errorCode,
    AutoVideo? autoVideo,
  }) =>
      Work(
        id: id,
        model: model,
        status: status ?? this.status,
        occasion: occasion,
        region: region,
        genre: genre,
        lyricLanguage: lyricLanguage,
        createdAt: createdAt,
        jobId: jobId ?? this.jobId,
        template: template,
        inspiration: inspiration,
        vocals: vocals,
        prompt: prompt,
        festival: festival,
        recipient: recipient,
        keywords: keywords,
        userLyrics: userLyrics,
        promptNote: promptNote,
        imageBids: imageBids,
        lyrics: lyrics ?? this.lyrics,
        structure: structure ?? this.structure,
        audioFile: audioFile ?? this.audioFile,
        errorCode: errorCode ?? this.errorCode,
        parentId: parentId,
        autoVideo: autoVideo ?? this.autoVideo,
      );

  /// A display title: "Alex · Birthday" style pieces for the UI / ID3.
  String get titleSeed => recipient.isNotEmpty ? recipient : keywords.join(', ');
}
