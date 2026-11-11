import '../../common/json.dart';
import '../../creation/domain/music_generation.dart';
import '../../creation/domain/music_occasion.dart';
import '../../creation/domain/music_song_options.dart';
import '../../creation/domain/music_song_template.dart';
import '../domain/music_work.dart';

/// [MusicWork] ⇄ JSON for sync records (ADR-0013). Local-only fields (the audio
/// file name, a transient error) are not synced; the audio travels as an asset.
abstract final class MusicWorkCodec {
  static Map<String, Object?> toJson(MusicWork w) => {
        'id': w.id,
        'job_id': w.jobId,
        'model': w.model.wire,
        'status': w.status.name,
        'occasion': w.occasion.wire,
        'festival': w.festival?.wire,
        'template': w.template?.id,
        'inspiration': w.inspiration,
        'vocals': w.vocals.wire,
        'prompt': w.prompt,
        'region': w.region,
        'genre': w.genre,
        'lyric_language': w.lyricLanguage,
        'recipient': w.recipient,
        'keywords': w.keywords,
        'user_lyrics': w.userLyrics,
        'prompt_note': w.promptNote,
        'lyrics': w.lyrics,
        'structure': [for (final s in w.structure) s.toJson()],
        'parent_id': w.parentId,
        'created_at': w.createdAt.toUtc().millisecondsSinceEpoch,
      };

  static MusicWork fromJson(Map<String, Object?> j) => MusicWork(
        id: asString(j['id']),
        jobId: asNullableString(j['job_id']),
        model: MusicSongModel.fromWire(asString(j['model'])),
        status: MusicWorkStatus.fromWire(asString(j['status'])),
        occasion: MusicOccasion.fromWire(asString(j['occasion'])),
        festival: MusicFestival.fromWire(asNullableString(j['festival'])),
        template: MusicSongTemplate.fromId(asNullableString(j['template'])),
        inspiration: asNullableString(j['inspiration']),
        vocals: MusicVocals.fromWire(asNullableString(j['vocals'])),
        prompt: asString(j['prompt']),
        region: asString(j['region']),
        genre: asString(j['genre']),
        lyricLanguage: asString(j['lyric_language']),
        recipient: asString(j['recipient']),
        keywords: asStringList(j['keywords']),
        userLyrics: asNullableString(j['user_lyrics']),
        promptNote: asString(j['prompt_note']),
        lyrics: asString(j['lyrics']),
        structure: asMapList(j['structure'])
            .map((s) => MusicLyricSection(label: asString(s['section']), start: asDouble(s['start']), end: asDouble(s['end'])))
            .toList(growable: false),
        parentId: asNullableString(j['parent_id']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(asInt(j['created_at']), isUtc: true),
      );
}
