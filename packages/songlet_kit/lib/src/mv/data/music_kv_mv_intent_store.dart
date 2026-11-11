import 'package:infra_core/infra_core.dart';

import '../../common/json.dart';
import '../domain/music_mv.dart';
import '../domain/music_mv_intent.dart';

/// [MusicMvIntentStore] in [KeyValueStore] under `mv.pending_intent`. A record
/// that no longer parses reads as absent (never fatal).
class MusicKvMvIntentStore implements MusicMvIntentStore {
  MusicKvMvIntentStore(this._store);

  static const String key = 'mv.pending_intent';

  final KeyValueStore _store;

  @override
  MusicMvIntent? read() {
    final json = _store.getJson(key);
    if (json == null) return null;
    final level = MusicMvLevel.fromWire(asNullableString(json['level']));
    final workId = asNullableString(json['work_id']);
    final clientRef = asNullableString(json['client_ref']);
    final createdAt = json['created_at'];
    if (level == null || workId == null || clientRef == null || createdAt is! int) return null;
    final chorus = asMap(json['chorus']);
    return MusicMvIntent(
      workId: workId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
      request: MusicMvRequest(
        level: level,
        clientRef: clientRef,
        aspectRatio: MusicMvAspectRatio.fromWire(asNullableString(json['aspect_ratio'])),
        quality: MusicMvQuality.fromWire(asNullableString(json['quality'])),
        subtitles: json['subtitles'] is bool ? json['subtitles']! as bool : null,
        photoBids: asStringList(json['photo_bids']),
        chorus: chorus.isEmpty
            ? null
            : MusicMvChorusWindow(startMs: asInt(chorus['start_ms']), endMs: asInt(chorus['end_ms'])),
        source: MusicMvSource.fromWire(asNullableString(json['source'])),
      ),
    );
  }

  @override
  Future<void> save(MusicMvIntent intent) => _store.setJson(key, {
        ...intent.request.toJson(),
        // Always kept locally, whether or not it travels (contract gap G6).
        'source': intent.request.source.wire,
        'work_id': intent.workId,
        'created_at': intent.createdAt.toUtc().millisecondsSinceEpoch,
      });

  @override
  Future<void> clear() => _store.remove(key);
}
