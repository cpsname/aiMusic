import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/creation/data/remote_template_catalog.dart';

/// `/templates` answers [catalogue]; any other URL answers audio bytes.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.catalogue);

  Map<String, Object?> catalogue;
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options.uri.toString());
    if (options.path == '/templates') {
      return ResponseBody.fromString(jsonEncode(catalogue), 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }
    return ResponseBody.fromBytes(utf8.encode('mp3:${options.uri}'), 200);
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> entry(String slug, int sort, {String? linked, Object? url, Object? duration = 20}) => {
      'id': 'id-$slug',
      'slug': slug,
      'name': {'en': 'Name $slug', 'zh': '名 $slug'},
      'style': {'en': 'Style $slug', 'zh': '风格 $slug'},
      'preview_audio_url': url ?? 'https://cdn.example.com/$slug.mp3',
      'duration_sec': duration,
      'sort': sort,
      'linked_template_id': ?linked,
    };

void main() {
  late Directory cache;
  late _Adapter adapter;
  late RemoteTemplateCatalog catalog;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('songlet-catalog');
    addTearDown(() => cache.delete(recursive: true));
    adapter = _Adapter({
      'templates': [
        {'id': 'birthday_wish', 'sample_url': 'https://cdn.example.com/samples/birthday_wish.mp3', 'duration': 30},
      ],
      'inspirations': [
        entry('soundscape', 2),
        entry('happy_birthday', 1, linked: 'birthday_wish'),
        entry('future_thing', 3, linked: 'not_a_template_yet', duration: null),
      ],
    });
    final api = Dio(BaseOptions(baseUrl: 'https://api.example.com/v1'))..httpClientAdapter = adapter;
    final download = Dio()..httpClientAdapter = adapter;
    catalog = RemoteTemplateCatalog(apiDio: api, downloadDio: download, cacheDir: () async => cache.path);
  });

  test('inspirations: sorted by sort, {en, zh} copy, the linked template when known', () async {
    final list = await catalog.inspirations();
    expect(list.map((i) => i.slug), ['happy_birthday', 'soundscape', 'future_thing']);
    final birthday = list.first;
    expect(birthday.name, const LocalizedText(en: 'Name happy_birthday', zh: '名 happy_birthday'));
    expect(birthday.linkedTemplate, SongTemplate.birthdayWish);
    expect(list[1].linkedTemplate, isNull);
    expect(list[2].linkedTemplateId, 'not_a_template_yet');
    expect(list[2].linkedTemplate, isNull, reason: 'a template this client does not know opens the composer');
    expect(list[2].durationSec, isNull);
  });

  test('the 2026-10 server: no templates[], the templates listed as inspirations by their id, extra fields ignored', () async {
    adapter.catalogue = {
      'inspirations': [
        {
          'id': 'cf8ef0e2-9d9d-526e-b8a7-a88242755c54',
          'slug': 'birthday_wish',
          'name': {'en': 'Birthday Wish', 'zh': '生日祝福'},
          'style': {'en': 'Heartfelt song for their special day', 'zh': '为 TA 的特别日子写的走心歌'},
          'preview_audio_url': 'https://r2.example.com/Songlet/samples/birthday_wish.mp3',
          'duration_sec': 31,
          'sort': 1,
          'occasion': 'birthday',
          'requires_recipient': true,
        },
        {
          'id': '1f6864f7-b19f-54c6-875f-90f7edf2596d',
          'slug': 'team_anthem',
          'name': {'en': 'Team Anthem', 'zh': '队歌'},
          'style': {'en': 'Stadium rock chant', 'zh': '体育场摇滚合唱'},
          'preview_audio_url': 'https://r2.example.com/Songlet/samples/team_anthem.mp3',
          'duration_sec': 31,
          'sort': 10,
          'occasion': 'brand',
          'requires_recipient': false,
          'suggested_genre': 'Rock',
        },
        {
          'id': '26c85e2d-3dd6-5f08-a8aa-c68be85c3f0c',
          'slug': 'soundscape',
          'name': {'en': 'Soundscape', 'zh': '环境音景'},
          'style': {'en': 'Ambient textures, no vocals', 'zh': '氛围音色，纯音乐'},
          'preview_audio_url': 'https://www.example.com/soundscape.mp3',
          'duration_sec': 21,
          'sort': 17,
          'occasion': 'soundtrack',
          'requires_recipient': false,
          'suggested_genre': 'Ambient',
          'default_vocals': 'instrumental',
        },
      ],
    };
    final list = await catalog.inspirations();
    expect(list.map((i) => i.slug), ['birthday_wish', 'team_anthem', 'soundscape']);
    expect(list.map((i) => i.linkedTemplate), [SongTemplate.birthdayWish, SongTemplate.teamAnthem, null]);
    final ideas = buildIdeas(list);
    expect(ideas.map((i) => i.slug), ['birthday_wish', 'team_anthem', 'soundscape'], reason: 'the list is the grid');
    expect(ideas.every((i) => i.template == null), isTrue);
  });

  test('cover_image_url: kept when an absolute http(s) URL, otherwise none', () async {
    adapter.catalogue = {
      'inspirations': [
        {...entry('with_cover', 1), 'cover_image_url': 'https://cdn.example.com/covers/with_cover.jpg'},
        {...entry('relative_cover', 2), 'cover_image_url': '/covers/relative.jpg'},
        {...entry('blank_cover', 3), 'cover_image_url': ''},
        entry('no_cover', 4),
      ],
    };
    final list = await catalog.inspirations();
    expect(list.map((i) => i.coverImageUrl), ['https://cdn.example.com/covers/with_cover.jpg', null, null, null]);
  });

  test('contract 02 v2.1: composer, default_model, default_vocals, suggested_genre, occasion', () async {
    adapter.catalogue = {
      'inspirations': [
        {
          ...entry('soundscape', 1),
          'occasion': 'soundtrack',
          'default_model': 'lyria-3-clip-preview',
          'default_vocals': 'instrumental',
          'suggested_genre': 'Ambient',
          'cover_image_url': 'https://cdn.example.com/covers/soundscape.jpg',
          'composer': {
            'hint': {'en': 'Describe the mood', 'zh': '描述氛围'},
            'input_required': false,
          },
          'requires_recipient': false,
          'default_on_video': true,
        },
        {
          ...entry('birthday_wish', 2),
          'occasion': 'birthday',
          'default_model': 'lyria-3.5',
          'composer': {
            'hint': {'en': 'Who is it for?'},
            'input_required': true,
          },
        },
        {...entry('odd', 3), 'occasion': 'nope', 'default_model': 'gpt', 'default_vocals': 'choir', 'composer': {'hint': <String, Object?>{}}},
        entry('old_server', 4),
      ],
    };
    final list = await catalog.inspirations();
    final soundscape = list[0];
    expect(soundscape.occasion, Occasion.soundtrack);
    expect(soundscape.defaultModel, SongModel.clip);
    expect(soundscape.defaultVocals, Vocals.instrumental);
    expect(soundscape.suggestedGenre, 'Ambient');
    expect(soundscape.composer!.inputRequired, isFalse);
    expect(soundscape.composer!.hint, const LocalizedText(en: 'Describe the mood', zh: '描述氛围'));
    expect(soundscape.requiresRecipient, isFalse);
    expect(soundscape.defaultOnVideo, isTrue, reason: 'contract 02 v2.2');
    expect(list[1].defaultOnVideo, isNull, reason: 'absent = the occasion rule');

    final wish = list[1];
    expect(wish.defaultModel, SongModel.fullSong);
    expect(wish.composer!.inputRequired, isTrue);
    expect(wish.composer!.hint.zh, 'Who is it for?', reason: 'a missing zh falls back to the English hint');

    final odd = list[2];
    expect(odd.occasion, isNull, reason: 'an unknown value is left unset');
    expect(odd.defaultModel, isNull);
    expect(odd.defaultVocals, isNull);
    expect(odd.composer, isNull, reason: 'no usable hint = no composer block');

    expect(list[3].composer, isNull, reason: 'an older server: the template form / prefilled prompt');
  });

  test('one /templates fetch serves the samples and the inspirations', () async {
    await catalog.inspirations();
    await catalog.samplePath('birthday_wish');
    await catalog.inspirations();
    expect(adapter.calls.where((c) => c.endsWith('/templates')), hasLength(1));
  });

  test('an older server without the field: no inspirations', () async {
    adapter.catalogue = {'templates': const []};
    expect(await catalog.inspirations(), isEmpty);
  });

  test('entries missing required fields or with a non-absolute preview are left out', () async {
    adapter.catalogue = {
      'inspirations': [
        entry('ok', 1),
        {...entry('no_name', 2)}..remove('name'),
        entry('relative', 3, url: '/files/relative.mp3'),
        {...entry('no_sort', 4)}..remove('sort'),
      ],
    };
    expect((await catalog.inspirations()).map((i) => i.slug), ['ok']);
  });

  test('previews are fetched from their own absolute URL and cached by URL', () async {
    final first = (await catalog.inspirations()).first;
    final path = await catalog.previewPath(first);
    expect(adapter.calls.last, 'https://cdn.example.com/happy_birthday.mp3', reason: 'never joined to the API base URL');
    expect(await File(path).readAsString(), 'mp3:https://cdn.example.com/happy_birthday.mp3');
    await catalog.previewPath(first);
    expect(adapter.calls.where((c) => c.contains('happy_birthday.mp3')), hasLength(1), reason: 'cached');

    // The platform moves the previews to its own storage: the new file is fetched.
    final moved = Inspiration(
      id: first.id,
      slug: first.slug,
      name: first.name,
      style: first.style,
      previewAudioUrl: 'https://media.songlet.example/happy_birthday.mp3',
      sort: first.sort,
    );
    final movedPath = await catalog.previewPath(moved);
    expect(movedPath, isNot(path));
    expect(await File(movedPath).readAsString(), 'mp3:https://media.songlet.example/happy_birthday.mp3');
  });
}
