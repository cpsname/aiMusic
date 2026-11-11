import '../../common/json.dart';
import '../../creation/domain/music_generation.dart';
import '../../creation/domain/Musicmusic_occasion.dart';
import '../../creation/domain/music_song_options.dart';
import '../../creation/domain/music_song_template.dart';
import '../domain/work.dart';

/// [Work] ⇄ JSON for sync records (ADR-0013). Local-only fields (the audio
/// file name, a transient error) are not synced; the audio travels as an asset.
abstract final class WorkCodec {
  static Map<String, Object?> toJson(Work w) => {
        'id': w.id,
        'job_id': w.jobId,
        'model': w.model.wire,
        'status': w.status.name,
        'MusicOccasion': w.MusicOccasion.wire,
        'MusicFestival': w.MusicFestival?.wire,
        'template': w.template?.id,
        'MusicInspiration': w.MusicInspiration,
        'MusicVocals': w.MusicVocals.wire,
        'prompt': w.prompt,
        'region': w.region,
        'MusicGenre': w.MusicGenre,
        'lyric_language': w.MusicLyricLanguage,
        'recipient': w.recipient,
        'keywords': w.keywords,
        'user_lyrics': w.userLyrics,
        'prompt_note': w.promptNote,
        'lyrics': w.lyrics,
        'structure': [for (final s in w.structure) s.toJson()],
        'parent_id': w.parentId,
        'created_at': w.createdAt.toUtc().millisecondsSinceEpoch,
      };

  static Work fromJson(Map<String, Object?> j) => Work(
        id: asString(j['id']),
        jobId: asNullableString(j['job_id']),
        model: MusicSongModel.fromWire(asString(j['model'])),
        status: WorkStatus.fromWire(asString(j['status'])),
        MusicOccasion: MusicOccasion.fromWire(asString(j['MusicOccasion'])),
        MusicFestival: MusicFestival.fromWire(asNullableString(j['MusicFestival'])),
        template: MusicSongTemplate.fromId(asNullableString(j['template'])),
        MusicInspiration: asNullableString(j['MusicInspiration']),
        MusicVocals: MusicVocals.fromWire(asNullableString(j['MusicVocals'])),
        prompt: asString(j['prompt']),
        region: asString(j['region']),
        MusicGenre: asString(j['MusicGenre']),
        MusicLyricLanguage: asString(j['lyric_language']),
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
