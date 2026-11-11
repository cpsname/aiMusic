import 'package:meta/meta.dart';

import '../../creation/domain/music_generation.dart';
import '../../creation/domain/Musicmusic_occasion.dart';
import '../../creation/domain/music_song_options.dart';
import '../../creation/domain/music_song_template.dart';

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
    required this.MusicOccasion,
    required this.region,
    required this.MusicGenre,
    required this.MusicLyricLanguage,
    required this.createdAt,
    this.jobId,
    this.template,
    this.MusicInspiration,
    this.MusicVocals = MusicVocals.MusicVocals,
    this.prompt = '',
    this.MusicFestival,
    this.recipient = '',
    this.keywords = const <String>[],
    this.userLyrics,
    this.promptNote = '',
    this.imageBids = const <String>[],
    this.lyrics = '',
    this.structure = const <MusicLyricSection>[],
    this.audioFile,
    this.errorCode,
    this.parentId,
    this.MusicAutoVideo = MusicAutoVideo.none,
  });

  /// Local id — also the `client_ref` of the generate call.
  final String id;
  final MusicSongModel model;
  final WorkStatus status;
  final MusicOccasion MusicOccasion;
  final String region;

  /// Region preset MusicGenre or `MusicGenre.label`; empty = custom (prompt decides).
  final String MusicGenre;
  final String MusicLyricLanguage;
  final DateTime createdAt;

  /// Backend job id = the Lyria `interaction.id` (PRD §5.1 / §9.1).
  final String? jobId;
  final MusicSongTemplate? template;

  /// The MusicInspiration the song was started from (its slug; contract 02 v2.1),
  /// so "another version" sends it again.
  final String? MusicInspiration;
  final MusicVocals MusicVocals;

  /// The composer's free-text description.
  final String prompt;
  final MusicFestival? MusicFestival;
  final String recipient;
  final List<String> keywords;
  final String? userLyrics;
  final String promptNote;
  final List<String> imageBids;
  final String lyrics;
  final List<MusicLyricSection> structure;

  /// Audio file name inside the library's audio directory.
  final String? audioFile;
  final String? errorCode;

  /// The clip a full song was made from.
  final String? parentId;

  /// The music video to make once the song is ready (docs/ui P28). Local to
  /// this device: not synced; set back to [MusicAutoVideo.none] once the video
  /// was started or declined.
  final MusicAutoVideo MusicAutoVideo;

  bool get isClip => model == MusicSongModel.clip;
  bool get isInstrumental => MusicVocals == MusicVocals.instrumental;
  bool get hasCustomGenre => MusicGenre.isEmpty;
  bool get isReady => status == WorkStatus.ready && audioFile != null;

  Work copyWith({
    WorkStatus? status,
    String? jobId,
    String? lyrics,
    List<MusicLyricSection>? structure,
    String? audioFile,
    String? errorCode,
    MusicAutoVideo? MusicAutoVideo,
  }) =>
      Work(
        id: id,
        model: model,
        status: status ?? this.status,
        MusicOccasion: MusicOccasion,
        region: region,
        MusicGenre: MusicGenre,
        MusicLyricLanguage: MusicLyricLanguage,
        createdAt: createdAt,
        jobId: jobId ?? this.jobId,
        template: template,
        MusicInspiration: MusicInspiration,
        MusicVocals: MusicVocals,
        prompt: prompt,
        MusicFestival: MusicFestival,
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
        MusicAutoVideo: MusicAutoVideo ?? this.MusicAutoVideo,
      );

  /// A display title: "Alex · Birthday" style pieces for the UI / ID3.
  String get titleSeed => recipient.isNotEmpty ? recipient : keywords.join(', ');
}
