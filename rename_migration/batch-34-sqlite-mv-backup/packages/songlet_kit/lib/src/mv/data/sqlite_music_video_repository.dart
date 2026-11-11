import 'package:sqflite/sqflite.dart';

import '../../common/json.dart';
import '../../library/domain/work.dart';
import '../domain/music_video.dart';
import '../domain/mv.dart';

/// Music videos in the library database (`music_videos`, schema v3 of
/// `SqliteWorkRepository`, extended in v4). One row per video; a work may
/// have several (one per level, or retries).
class SqliteMusicVideoRepository implements MusicVideoRepository {
  SqliteMusicVideoRepository(this._open);

  /// Opens the shared library database (see `openWorkDatabase`).
  final Future<Database> Function() _open;
  Future<Database>? _db;

  static const String table = 'music_videos';

  Future<Database> get _database => _db ??= _open();

  /// Columns added in schema v4 (ADR-0028): what was asked for and where
  /// the request came from.
  static const Map<String, String> v4Columns = {
    'aspect_ratio': "TEXT NOT NULL DEFAULT '9:16'",
    'quality': "TEXT NOT NULL DEFAULT 'standard'",
    'chorus_start_ms': 'INTEGER',
    'chorus_end_ms': 'INTEGER',
    'source': "TEXT NOT NULL DEFAULT 'library'",
    'photo_count': 'INTEGER NOT NULL DEFAULT 0',
  };

  /// The table, created on a fresh install (`onCreate`) and by the v3
  /// migration (`onUpgrade`) of the works database — always at the current
  /// shape, so [addV4Columns] adds only what an older table lacks.
  static Future<void> createTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS $table (
      id TEXT PRIMARY KEY,
      work_id TEXT NOT NULL,
      mv_id TEXT NOT NULL,
      level TEXT NOT NULL,
      status TEXT NOT NULL,
      video_file TEXT,
      error_code TEXT,
      duration_ms INTEGER NOT NULL DEFAULT 0,
      credits_charged INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      ${[for (final e in v4Columns.entries) '${e.key} ${e.value}'].join(',\n      ')}
    )
  ''');

  /// The v4 migration: adds the [v4Columns] a v3 table lacks. Idempotent — a
  /// table created by a v2 → v4 upgrade already has them.
  static Future<void> addV4Columns(Database db) async {
    final existing = {
      for (final row in await db.rawQuery('PRAGMA table_info($table)')) asString(row['name']),
    };
    for (final column in v4Columns.entries) {
      if (existing.contains(column.key)) continue;
      await db.execute('ALTER TABLE $table ADD COLUMN ${column.key} ${column.value}');
    }
  }

  @override
  Future<List<MusicVideo>> all() async {
    final rows = await (await _database).query(table, orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<MusicVideo>> byWork(String workId) async {
    final rows = await (await _database)
        .query(table, where: 'work_id = ?', whereArgs: [workId], orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<MusicVideo?> byId(String id) async {
    final rows = await (await _database).query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<void> upsert(MusicVideo video) async {
    await (await _database).insert(table, _toRow(video), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> delete(String id) async {
    await (await _database).delete(table, where: 'id = ?', whereArgs: [id]);
  }

  static Map<String, Object?> _toRow(MusicVideo v) => {
        'id': v.id,
        'work_id': v.workId,
        'mv_id': v.mvId,
        'level': v.level.wire,
        'status': v.status.name,
        'video_file': v.videoFile,
        'error_code': v.errorCode,
        'duration_ms': v.durationMs,
        'credits_charged': v.creditsCharged,
        'aspect_ratio': v.aspectRatio.wire,
        'quality': v.quality.wire,
        'chorus_start_ms': v.chorus?.startMs,
        'chorus_end_ms': v.chorus?.endMs,
        'source': v.source.wire,
        'photo_count': v.photoCount,
        'created_at': v.createdAt.toUtc().millisecondsSinceEpoch,
      };

  static MusicVideo _fromRow(Map<String, Object?> row) => MusicVideo(
        id: asString(row['id']),
        workId: asString(row['work_id']),
        mvId: asString(row['mv_id']),
        level: MvLevel.fromWire(asString(row['level'])) ?? MvLevel.lyricVideo,
        status: WorkStatus.fromWire(asString(row['status'])),
        videoFile: asNullableString(row['video_file']),
        errorCode: asNullableString(row['error_code']),
        durationMs: asInt(row['duration_ms']),
        creditsCharged: asInt(row['credits_charged']),
        aspectRatio: MvAspectRatio.fromWire(asNullableString(row['aspect_ratio'])) ?? MvAspectRatio.portrait,
        quality: MvQuality.fromWire(asNullableString(row['quality'])) ?? MvQuality.standard,
        chorus: _chorus(row['chorus_start_ms'], row['chorus_end_ms']),
        source: MvSource.fromWire(asNullableString(row['source'])),
        photoCount: asInt(row['photo_count']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(asInt(row['created_at']), isUtc: true),
      );

  static MvChorusWindow? _chorus(Object? start, Object? end) =>
      start == null || end == null ? null : MvChorusWindow(startMs: asInt(start), endMs: asInt(end));
}
