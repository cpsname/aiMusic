import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/library/data/sqlite_music_work_repository.dart';
import 'package:songlet_kit/src/library/data/music_work_codec.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/music_fakes.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  late MusicSqliteWorkRepository repository;

  setUp(() async {
    db = await openWorkDatabase(inMemoryDatabasePath, factory: databaseFactoryFfi);
    repository = MusicSqliteWorkRepository(() async => db);
  });

  tearDown(() => db.close());

  MusicWork fullWork() => MusicWork(
        id: 'w-full',
        jobId: 'job-42',
        model: MusicSongModel.fullSong,
        status: MusicWorkStatus.ready,
        occasion: MusicOccasion.festival,
        festival: MusicFestival.diwali,
        region: 'IN',
        genre: 'Bhangra',
        lyricLanguage: 'hi',
        recipient: 'Priya',
        keywords: const ['lights', 'sweets', 'family'],
        userLyrics: '[Verse]\nदीप जले',
        promptNote: 'A joyful Diwali song',
        imageBids: const ['bid-1', 'bid-2'],
        lyrics: '[Verse]\nदीप जले\n\n[Chorus]\nखुशियाँ',
        structure: const [
          MusicLyricSection(label: 'Intro', start: 0, end: 3),
          MusicLyricSection(label: 'Verse', start: 3, end: 45.25),
        ],
        audioFile: 'w-full.mp3',
        errorCode: 'UPSTREAM_TIMEOUT',
        parentId: 'w-clip',
        createdAt: DateTime.utc(2026, 9, 24, 10, 30, 15, 123),
      );

  void expectSameWork(MusicWork actual, MusicWork expected) {
    expect(actual.id, expected.id);
    expect(actual.jobId, expected.jobId);
    expect(actual.model, expected.model);
    expect(actual.status, expected.status);
    expect(actual.occasion, expected.occasion);
    expect(actual.festival, expected.festival);
    expect(actual.region, expected.region);
    expect(actual.genre, expected.genre);
    expect(actual.lyricLanguage, expected.lyricLanguage);
    expect(actual.recipient, expected.recipient);
    expect(actual.keywords, expected.keywords);
    expect(actual.userLyrics, expected.userLyrics);
    expect(actual.promptNote, expected.promptNote);
    expect(actual.imageBids, expected.imageBids);
    expect(actual.lyrics, expected.lyrics);
    expect(
      actual.structure.map((s) => (s.label, s.start, s.end)),
      expected.structure.map((s) => (s.label, s.start, s.end)),
    );
    expect(actual.audioFile, expected.audioFile);
    expect(actual.errorCode, expected.errorCode);
    expect(actual.parentId, expected.parentId);
    expect(actual.createdAt, expected.createdAt);
    expect(actual.createdAt.isUtc, isTrue);
  }

  test('round-trips every field', () async {
    final work = fullWork();
    await repository.upsert(work);

    expectSameWork((await repository.byId('w-full'))!, work);
    expectSameWork((await repository.all()).single, work);
  });

  test('round-trips a minimal pending work (nulls and empty lists)', () async {
    final work = sampleWork(jobId: null, keywords: const []);
    await repository.upsert(work);

    final stored = (await repository.byId(work.id))!;
    expectSameWork(stored, work);
    expect(stored.festival, isNull);
    expect(stored.userLyrics, isNull);
    expect(stored.audioFile, isNull);
    expect(stored.isReady, isFalse);
  });

  test('a local createdAt is stored as the same instant in UTC', () async {
    final local = DateTime(2026, 9, 24, 8);
    await repository.upsert(sampleWork(createdAt: local));
    final stored = (await repository.byId('w1'))!;
    expect(stored.createdAt.isAtSameMomentAs(local), isTrue);
    expect(stored.createdAt.isUtc, isTrue);
  });

  test('all() lists newest first', () async {
    await repository.upsert(sampleWork(id: 'old', createdAt: DateTime.utc(2026, 2)));
    await repository.upsert(sampleWork(id: 'new', createdAt: DateTime.utc(2026, 9)));
    await repository.upsert(sampleWork(id: 'mid', createdAt: DateTime.utc(2026, 5)));

    expect((await repository.all()).map((w) => w.id), ['new', 'mid', 'old']);
  });

  test('upsert replaces the row with the same id', () async {
    final pending = sampleWork();
    await repository.upsert(pending);
    await repository.upsert(
      pending.copyWith(status: MusicWorkStatus.ready, audioFile: 'w1.mp3', lyrics: 'la'),
    );

    final all = await repository.all();
    expect(all, hasLength(1));
    expect(all.single.status, MusicWorkStatus.ready);
    expect(all.single.audioFile, 'w1.mp3');
    expect(all.single.lyrics, 'la');
    expect(all.single.isReady, isTrue);
  });

  test('delete removes only that work', () async {
    await repository.upsert(sampleWork(id: 'a'));
    await repository.upsert(sampleWork(id: 'b'));

    await repository.delete('a');

    expect(await repository.byId('a'), isNull);
    expect((await repository.all()).map((w) => w.id), ['b']);
    await repository.delete('missing');
    expect(await repository.all(), hasLength(1));
  });

  test('byId of an unknown id is null; an empty library is empty', () async {
    expect(await repository.byId('nope'), isNull);
    expect(await repository.all(), isEmpty);
  });

  test('opens the database once', () async {
    var opens = 0;
    final counting = MusicSqliteWorkRepository(() async {
      opens++;
      return db;
    });
    await Future.wait([counting.all(), counting.all(), counting.byId('x')]);
    expect(opens, 1);
  });

  test('corrupt JSON columns degrade to empty lists', () async {
    await repository.upsert(sampleWork());
    await db.update(
      MusicSqliteWorkRepository.table,
      {'keywords': 'not json', 'image_bids': '', 'structure': '{"a":1}'},
      where: 'id = ?',
      whereArgs: ['w1'],
    );

    final stored = (await repository.byId('w1'))!;
    expect(stored.keywords, isEmpty);
    expect(stored.imageBids, isEmpty);
    expect(stored.structure, isEmpty);
  });

  test('unknown enum values degrade safely', () async {
    await repository.upsert(sampleWork());
    await db.update(
      MusicSqliteWorkRepository.table,
      {'status': 'exploded', 'occasion': 'bogus', 'festival': 'bogus', 'model': '?'},
      where: 'id = ?',
      whereArgs: ['w1'],
    );

    final stored = (await repository.byId('w1'))!;
    expect(stored.status, MusicWorkStatus.failed);
    expect(stored.occasion, MusicOccasion.birthday);
    expect(stored.festival, isNull);
    expect(stored.model, MusicSongModel.clip);
  });

  test('v2 round-trips template, vocals and prompt', () async {
    final work = fullWork();
    final composed = MusicWork(
      id: 'w-composed',
      model: MusicSongModel.clip,
      status: MusicWorkStatus.pending,
      occasion: MusicOccasion.confession,
      region: 'US',
      genre: '',
      lyricLanguage: 'en',
      template: MusicSongTemplate.petAnthem,
      vocals: MusicVocals.instrumental,
      prompt: 'a golden retriever who loves the beach',
      createdAt: work.createdAt,
    );
    await repository.upsert(composed);
    final back = (await repository.byId('w-composed'))!;
    expect(back.template, MusicSongTemplate.petAnthem);
    expect(back.vocals, MusicVocals.instrumental);
    expect(back.prompt, 'a golden retriever who loves the beach');
    expect(back.hasCustomGenre, isTrue);
    expect(back.autoVideo, MusicAutoVideo.none);

    await repository.upsert(back.copyWith(autoVideo: MusicAutoVideo.chorus));
    expect((await repository.byId('w-composed'))!.autoVideo, MusicAutoVideo.chorus);
  });

  test('the inspiration slug round-trips through the table and the sync record', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: MusicSqliteWorkRepository.version,
        singleInstance: false,
        onCreate: MusicSqliteWorkRepository.onCreate,
      ),
    );
    final repository = MusicSqliteWorkRepository(() async => db);
    final work = MusicWork(
      id: 'w-insp',
      model: MusicSongModel.clip,
      status: MusicWorkStatus.pending,
      occasion: MusicOccasion.soundtrack,
      region: 'US',
      genre: 'Ambient',
      lyricLanguage: 'en',
      createdAt: DateTime.utc(2026, 10, 3),
      inspiration: 'soundscape',
    );
    await repository.upsert(work);
    expect((await repository.byId('w-insp'))!.inspiration, 'soundscape');
    expect(MusicWorkCodec.fromJson(MusicWorkCodec.toJson(work)).inspiration, 'soundscape');
    await db.close();
  });

  test('a v1 database migrates in place and keeps its rows', () async {
    final v1 = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        singleInstance: false,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE works (
            id TEXT PRIMARY KEY, job_id TEXT, model TEXT NOT NULL,
            status TEXT NOT NULL, occasion TEXT NOT NULL, festival TEXT,
            region TEXT NOT NULL, genre TEXT NOT NULL,
            lyric_language TEXT NOT NULL, recipient TEXT NOT NULL DEFAULT '',
            keywords TEXT NOT NULL DEFAULT '[]', user_lyrics TEXT,
            prompt_note TEXT NOT NULL DEFAULT '',
            image_bids TEXT NOT NULL DEFAULT '[]',
            lyrics TEXT NOT NULL DEFAULT '', structure TEXT NOT NULL DEFAULT '[]',
            audio_file TEXT, error_code TEXT, parent_id TEXT,
            created_at INTEGER NOT NULL)
        '''),
      ),
    );
    await v1.insert('works', {
      'id': 'old',
      'model': 'lyria-3-clip-preview',
      'status': 'ready',
      'occasion': 'birthday',
      'region': 'US',
      'genre': 'Indie Pop',
      'lyric_language': 'en',
      'created_at': 0,
    });
    await MusicSqliteWorkRepository.onUpgrade(v1, 1, MusicSqliteWorkRepository.version);
    final migrated = (await MusicSqliteWorkRepository(() async => v1).byId('old'))!;
    expect(migrated.genre, 'Indie Pop');
    expect(migrated.vocals, MusicVocals.vocals);
    expect(migrated.template, isNull);
    expect(migrated.prompt, '');
    expect(migrated.inspiration, isNull, reason: 'v5 column added in place');
    await v1.close();
  });
}
