import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../common/json.dart';
import '../../creation/domain/music_generation.dart';
import '../../creation/domain/occasion.dart';
import '../../creation/domain/song_options.dart';
import '../../creation/domain/song_template.dart';
import '../../mv/data/sqlite_music_video_repository.dart';
import '../domain/work.dart';
import '../domain/work_repository.dart';

/// The local work library in SQLite (PRD F10). One `works` table; list-typed
/// columns are JSON. Schema changes go through [onUpgrade] (bump [version]):
/// * v2 — `template`, `vocals`, `prompt` (docs/ui P01 composer, ADR-0015).
/// * v3 — the `music_videos` table (PRD ch.15, ADR-0020), owned by
///   `SqliteMusicVideoRepository` and sharing this database.
/// * v4 — `works.auto_video` (docs/ui P28) and the request columns of
///   `music_videos` (ADR-0028).
/// * v5 — `works.inspiration` (the inspiration slug, contract 02 v2.1).
class SqliteWorkRepository implements WorkRepository {
  SqliteWorkRepository(this._open);

  /// Opens the database at the app's library location (see
  /// [openWorkDatabase]); injected so tests run on sqflite_common_ffi.
  final Future<Database> Function() _open;
  Future<Database>? _db;

  static const int version = 5;
  static const String table = 'works';

  Future<Database> get _database => _db ??= _open();

  static Future<void> onCreate(Database db, int version) async {
    await _createWorks(db);
    await SqliteMusicVideoRepository.createTable(db);
  }

  static Future<void> _createWorks(Database db) => db.execute('''
    CREATE TABLE $table (
      id TEXT PRIMARY KEY,
      job_id TEXT,
      model TEXT NOT NULL,
      status TEXT NOT NULL,
      occasion TEXT NOT NULL,
      festival TEXT,
      region TEXT NOT NULL,
      genre TEXT NOT NULL,
      lyric_language TEXT NOT NULL,
      recipient TEXT NOT NULL DEFAULT '',
      keywords TEXT NOT NULL DEFAULT '[]',
      user_lyrics TEXT,
      prompt_note TEXT NOT NULL DEFAULT '',
      image_bids TEXT NOT NULL DEFAULT '[]',
      lyrics TEXT NOT NULL DEFAULT '',
      structure TEXT NOT NULL DEFAULT '[]',
      audio_file TEXT,
      error_code TEXT,
      parent_id TEXT,
      created_at INTEGER NOT NULL,
      template TEXT,
      vocals TEXT NOT NULL DEFAULT 'vocals',
      prompt TEXT NOT NULL DEFAULT '',
      auto_video TEXT NOT NULL DEFAULT 'none',
      inspiration TEXT
    )
  ''');

  /// Ordered, additive migrations; each step moves the schema one version up.
  static Future<void> onUpgrade(Database db, int from, int to) async {
    for (var v = from + 1; v <= to; v++) {
      switch (v) {
        case 2:
          await db.execute('ALTER TABLE $table ADD COLUMN template TEXT');
          await db.execute(
            "ALTER TABLE $table ADD COLUMN vocals TEXT NOT NULL DEFAULT 'vocals'",
          );
          await db.execute(
            "ALTER TABLE $table ADD COLUMN prompt TEXT NOT NULL DEFAULT ''",
          );
        case 3:
          await SqliteMusicVideoRepository.createTable(db);
        case 4:
          await db.execute(
            "ALTER TABLE $table ADD COLUMN auto_video TEXT NOT NULL DEFAULT 'none'",
          );
          await SqliteMusicVideoRepository.addV4Columns(db);
        case 5:
          await db.execute('ALTER TABLE $table ADD COLUMN inspiration TEXT');
      }
    }
  }

  @override
  Future<List<Work>> all() async {
    final rows = await (await _database).query(table, orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<Work?> byId(String id) async {
    final rows = await (await _database)
        .query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<void> upsert(Work work) async {
    await (await _database).insert(
      table,
      _toRow(work),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    await (await _database).delete(table, where: 'id = ?', whereArgs: [id]);
  }

  static Map<String, Object?> _toRow(Work w) => {
        'id': w.id,
        'job_id': w.jobId,
        'model': w.model.wire,
        'status': w.status.name,
        'occasion': w.occasion.wire,
        'festival': w.festival?.wire,
        'region': w.region,
        'genre': w.genre,
        'lyric_language': w.lyricLanguage,
        'recipient': w.recipient,
        'keywords': jsonEncode(w.keywords),
        'user_lyrics': w.userLyrics,
        'prompt_note': w.promptNote,
        'image_bids': jsonEncode(w.imageBids),
        'lyrics': w.lyrics,
        'structure': jsonEncode([for (final s in w.structure) s.toJson()]),
        'audio_file': w.audioFile,
        'error_code': w.errorCode,
        'parent_id': w.parentId,
        'template': w.template?.id,
        'inspiration': w.inspiration,
        'vocals': w.vocals.wire,
        'prompt': w.prompt,
        'auto_video': w.autoVideo.wire,
        'created_at': w.createdAt.toUtc().millisecondsSinceEpoch,
      };

  static Work _fromRow(Map<String, Object?> row) => Work(
        id: asString(row['id']),
        jobId: asNullableString(row['job_id']),
        model: SongModel.fromWire(asString(row['model'])),
        status: WorkStatus.fromWire(asString(row['status'])),
        occasion: Occasion.fromWire(asString(row['occasion'])),
        festival: Festival.fromWire(asNullableString(row['festival'])),
        region: asString(row['region']),
        genre: asString(row['genre']),
        lyricLanguage: asString(row['lyric_language']),
        recipient: asString(row['recipient']),
        keywords: asStringList(_json(row['keywords'])),
        userLyrics: asNullableString(row['user_lyrics']),
        promptNote: asString(row['prompt_note']),
        imageBids: asStringList(_json(row['image_bids'])),
        lyrics: asString(row['lyrics']),
        structure: asMapList(_json(row['structure']))
            .map(
              (s) => LyricSection(
                label: asString(s['section']),
                start: asDouble(s['start']),
                end: asDouble(s['end']),
              ),
            )
            .toList(growable: false),
        audioFile: asNullableString(row['audio_file']),
        errorCode: asNullableString(row['error_code']),
        parentId: asNullableString(row['parent_id']),
        template: SongTemplate.fromId(asNullableString(row['template'])),
        inspiration: asNullableString(row['inspiration']),
        vocals: Vocals.fromWire(asNullableString(row['vocals'])),
        prompt: asString(row['prompt']),
        autoVideo: AutoVideo.fromWire(asNullableString(row['auto_video'])),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          asInt(row['created_at']),
          isUtc: true,
        ),
      );

  static Object? _json(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }
}

/// Opens (creating / migrating) the works database at [path].
Future<Database> openWorkDatabase(String path, {DatabaseFactory? factory}) =>
    (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: SqliteWorkRepository.version,
        onCreate: SqliteWorkRepository.onCreate,
        onUpgrade: SqliteWorkRepository.onUpgrade,
      ),
    );
