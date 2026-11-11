import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/library/data/sqlite_music_work_repository.dart';
import 'package:songlet_kit/src/mv/data/music_sqlite_music_video_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'mv_fakes.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  late MusicSqliteMusicVideoRepository repository;

  setUp(() async {
    db = await openWorkDatabase(inMemoryDatabasePath, factory: databaseFactoryFfi);
    repository = MusicSqliteMusicVideoRepository(() async => db);
  });

  tearDown(() => db.close());

  test('round-trips every column; videos list newest first per work', () async {
    final pending = pendingVideo();
    await repository.upsert(pending);
    final ready = MusicVideo(
      id: 'v2',
      workId: 'w1',
      mvId: 'mv-2',
      level: MusicMvLevel.full,
      status: MusicWorkStatus.ready,
      videoFile: 'v2.mp4',
      durationMs: 118000,
      creditsCharged: 8280,
      createdAt: DateTime.utc(2026, 9, 28, 11),
    );
    await repository.upsert(ready);
    await repository.upsert(pendingVideo(id: 'v3', workId: 'w2'));

    final stored = (await repository.byId('v2'))!;
    expect(stored.level, MusicMvLevel.full);
    expect(stored.status, MusicWorkStatus.ready);
    expect(stored.videoFile, 'v2.mp4');
    expect(stored.durationMs, 118000);
    expect(stored.creditsCharged, 8280);
    expect(stored.createdAt, DateTime.utc(2026, 9, 28, 11));
    expect(stored.isReady, isTrue);

    expect((await repository.byWork('w1')).map((v) => v.id), ['v2', 'v1']);
    expect((await repository.all()).map((v) => v.id), ['v2', 'v1', 'v3']);

    await repository.upsert(pending.copyWith(status: MusicWorkStatus.failed, errorCode: 'MV_RENDER_FAILED'));
    expect((await repository.byId('v1'))!.errorCode, 'MV_RENDER_FAILED');
    await repository.delete('v1');
    expect(await repository.byId('v1'), isNull);
  });

  test('a v2 works database gains the music_videos table on upgrade, keeping its works', () async {
    final dir = await Directory.systemTemp.createTemp('songlet-mv-upgrade');
    addTearDown(() => dir.delete(recursive: true));
    final old = await databaseFactoryFfi.openDatabase(
      '${dir.path}/songlet.db',
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          // The v2 schema as shipped (works only).
          await db.execute('''
            CREATE TABLE works (
              id TEXT PRIMARY KEY, job_id TEXT, model TEXT NOT NULL, status TEXT NOT NULL,
              occasion TEXT NOT NULL, festival TEXT, region TEXT NOT NULL, genre TEXT NOT NULL,
              lyric_language TEXT NOT NULL, recipient TEXT NOT NULL DEFAULT '',
              keywords TEXT NOT NULL DEFAULT '[]', user_lyrics TEXT, prompt_note TEXT NOT NULL DEFAULT '',
              image_bids TEXT NOT NULL DEFAULT '[]', lyrics TEXT NOT NULL DEFAULT '',
              structure TEXT NOT NULL DEFAULT '[]', audio_file TEXT, error_code TEXT, parent_id TEXT,
              created_at INTEGER NOT NULL, template TEXT, vocals TEXT NOT NULL DEFAULT 'vocals',
              prompt TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.insert('works', {
            'id': 'w1', 'model': 'lyria-3.5', 'status': 'ready', 'occasion': 'birthday', 'region': 'US',
            'genre': 'Pop', 'lyric_language': 'en', 'created_at': 1,
          });
        },
      ),
    );
    await MusicSqliteWorkRepository.onUpgrade(old, 2, MusicSqliteWorkRepository.version);
    final videos = MusicSqliteMusicVideoRepository(() async => old);
    await videos.upsert(pendingVideo());
    expect((await videos.byWork('w1')).single.mvId, 'mv-1');
    expect((await old.query('works')).single['id'], 'w1');
    await old.close();
  });

  test('v4 request columns round-trip (aspect, quality, chorus window, source, photos)', () async {
    final video = MusicVideo(
      id: 'v4',
      workId: 'w1',
      mvId: 'mv-4',
      level: MusicMvLevel.chorus,
      status: MusicWorkStatus.pending,
      createdAt: DateTime.utc(2026, 9, 29),
      aspectRatio: MusicMvAspectRatio.square,
      quality: MusicMvQuality.high,
      chorus: const MusicMvChorusWindow(startMs: 42000, endMs: 72000),
      source: MusicMvSource.upgrade,
      photoCount: 3,
    );
    await repository.upsert(video);
    final back = (await repository.byId('v4'))!;
    expect(back.aspectRatio, MusicMvAspectRatio.square);
    expect(back.quality, MusicMvQuality.high);
    expect(back.chorus, const MusicMvChorusWindow(startMs: 42000, endMs: 72000));
    expect(back.source, MusicMvSource.upgrade);
    expect(back.photoCount, 3);

    await repository.upsert(pendingVideo(id: 'v5'));
    final defaults = (await repository.byId('v5'))!;
    expect(defaults.aspectRatio, MusicMvAspectRatio.portrait);
    expect(defaults.chorus, isNull);
    expect(defaults.source, MusicMvSource.library);
  });

  test('a v3 database gains the v4 columns; old rows read the defaults', () async {
    final old = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        singleInstance: false,
        onCreate: (db, _) async {
          // The v3 schema as shipped.
          await db.execute('''
            CREATE TABLE works (
              id TEXT PRIMARY KEY, job_id TEXT, model TEXT NOT NULL, status TEXT NOT NULL,
              occasion TEXT NOT NULL, festival TEXT, region TEXT NOT NULL, genre TEXT NOT NULL,
              lyric_language TEXT NOT NULL, recipient TEXT NOT NULL DEFAULT '',
              keywords TEXT NOT NULL DEFAULT '[]', user_lyrics TEXT, prompt_note TEXT NOT NULL DEFAULT '',
              image_bids TEXT NOT NULL DEFAULT '[]', lyrics TEXT NOT NULL DEFAULT '',
              structure TEXT NOT NULL DEFAULT '[]', audio_file TEXT, error_code TEXT, parent_id TEXT,
              created_at INTEGER NOT NULL, template TEXT, vocals TEXT NOT NULL DEFAULT 'vocals',
              prompt TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE music_videos (
              id TEXT PRIMARY KEY, work_id TEXT NOT NULL, mv_id TEXT NOT NULL, level TEXT NOT NULL,
              status TEXT NOT NULL, video_file TEXT, error_code TEXT,
              duration_ms INTEGER NOT NULL DEFAULT 0, credits_charged INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.insert('works', {
            'id': 'w1', 'model': 'lyria-3.5', 'status': 'ready', 'occasion': 'birthday', 'region': 'US',
            'genre': 'Pop', 'lyric_language': 'en', 'created_at': 1,
          });
          await db.insert('music_videos', {
            'id': 'v1', 'work_id': 'w1', 'mv_id': 'mv-1', 'level': 'chorus_mv', 'status': 'ready',
            'video_file': 'v1.mp4', 'created_at': 2,
          });
        },
      ),
    );
    await MusicSqliteWorkRepository.onUpgrade(old, 3, MusicSqliteWorkRepository.version);
    // Idempotent: a second pass finds every column present.
    await MusicSqliteMusicVideoRepository.addV4Columns(old);
    final video = (await MusicSqliteMusicVideoRepository(() async => old).byId('v1'))!;
    expect(video.aspectRatio, MusicMvAspectRatio.portrait);
    expect(video.quality, MusicMvQuality.standard);
    expect(video.source, MusicMvSource.library);
    expect(video.photoCount, 0);
    expect((await MusicSqliteWorkRepository(() async => old).byId('w1'))!.autoVideo, MusicAutoVideo.none);
    await old.close();
  });
}
