import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_preview/store_preview.dart';

void main() {
  late Directory dir;
  late File media;
  late File manifest;
  late HttpClient client;
  FixtureMediaServer? server;

  Map<String, Object?> entry() => {
    'id': 'video.A.en-US',
    'type': 'video',
    'role': 'video',
    'locale': 'en-US',
    'script': 'A',
    'file': 'clip.mp4',
    'license': {
      'provider': 'test',
      'id': 'test-only-record',
      'model': 'test',
      'generated_at': '2026-01-01T00:00:00Z',
    },
    'data': {'sha256': sha256.convert(media.readAsBytesSync()).toString()},
  };
  void writeEntries(List<Map<String, Object?>> entries) =>
      manifest.writeAsStringSync(jsonEncode({'schema': 2, 'entries': entries}));
  Future<({int code, List<int> bytes, HttpHeaders headers})> request(
    String path, {
    String method = 'GET',
    Map<String, String> headers = const {},
  }) async {
    final req = await client.openUrl(method, server!.origin.resolve(path));
    headers.forEach(req.headers.set);
    final res = await req.close();
    final bytes = await res.fold<List<int>>([], (a, b) => a..addAll(b));
    return (code: res.statusCode, bytes: bytes, headers: res.headers);
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('fixture-media-test-');
    media = File('${dir.path}/clip.mp4')
      ..writeAsBytesSync(List.generate(10, (i) => i));
    manifest = File('${dir.path}/manifest.json');
    writeEntries([entry()]);
    client = HttpClient();
  });
  tearDown(() async {
    client.close(force: true);
    await server?.close();
    server = null;
    dir.deleteSync(recursive: true);
  });

  test(
    'manifest and GET/HEAD expose only the licensed file on loopback',
    () async {
      server = await FixtureMediaServer.start(Manifest.load(manifest.path));
      expect(server!.origin.host, '127.0.0.1');
      final response = await request('/manifest');
      final data = jsonDecode(utf8.decode(response.bytes)) as Map;
      final record = (data['entries'] as List).single as Map;
      expect(record['license'], entry()['license']);
      expect(record['media_url'], '/media/video.A.en-US');
      expect(utf8.decode(response.bytes), isNot(contains(dir.path)));
      final image = await request(record['media_url'] as String);
      expect(image.code, 200);
      expect(image.bytes, List.generate(10, (i) => i));
      expect(image.headers.contentType!.mimeType, 'video/mp4');
      final head = await request('/media/video.A.en-US', method: 'HEAD');
      expect(head.code, 200);
      expect(head.headers.contentLength, 10);
      expect(head.bytes, isEmpty);
      expect((await request('/health')).code, 200);
    },
  );

  test(
    'video byte ranges support bounded, open, suffix and clipped requests',
    () async {
      server = await FixtureMediaServer.start(Manifest.load(manifest.path));
      for (final (range, expected, content) in [
        ('bytes=2-5', [2, 3, 4, 5], 'bytes 2-5/10'),
        ('bytes=7-', [7, 8, 9], 'bytes 7-9/10'),
        ('bytes=-3', [7, 8, 9], 'bytes 7-9/10'),
        ('bytes=8-99', [8, 9], 'bytes 8-9/10'),
      ]) {
        final res = await request(
          '/media/video.A.en-US',
          headers: {'Range': range},
        );
        expect(res.code, 206, reason: range);
        expect(res.bytes, expected, reason: range);
        expect(res.headers.value('content-range'), content);
      }
      for (final range in [
        'bytes=99-',
        'bytes=5-2',
        'bytes=-0',
        'bytes=-',
        'bytes=0-1,3-4',
        'items=0-1',
      ]) {
        final res = await request(
          '/media/video.A.en-US',
          headers: {'Range': range},
        );
        expect(res.code, 416, reason: range);
        expect(res.headers.value('content-range'), 'bytes */10');
      }
    },
  );

  test('writes, unknown paths and foreign origins are rejected', () async {
    server = await FixtureMediaServer.start(Manifest.load(manifest.path));
    expect((await request('/manifest', method: 'POST')).code, 405);
    expect((await request('/media/clip.mp4')).code, 404);
    expect((await request('/media/../../manifest.json')).code, 404);
    expect(
      (await request(
        '/manifest',
        headers: {'Origin': 'https://example.org'},
      )).code,
      403,
    );
    // dart:io may reject a foreign Host before dispatching to our handler.
    expect(
      (await request('/manifest', headers: {'Host': 'example.org'})).code,
      anyOf(403, 404),
    );
    expect(media.readAsBytesSync(), List.generate(10, (i) => i));
  });

  test(
    'changed bytes are rejected even with the original length and timestamp',
    () async {
      server = await FixtureMediaServer.start(Manifest.load(manifest.path));
      final original = media.statSync().modified;
      media.writeAsBytesSync(List.filled(10, 9));
      media.setLastModifiedSync(original);
      expect((await request('/media/video.A.en-US')).code, 409);
    },
  );

  test(
    'missing licenses, duplicate ids and wrong hashes fail before binding',
    () async {
      for (final records in [
        [
          {...entry(), 'license': <String, Object?>{}},
        ],
        [entry(), entry()],
        [
          {
            ...entry(),
            'data': {'sha256': 'wrong'},
          },
        ],
      ]) {
        writeEntries(records);
        await expectLater(
          FixtureMediaServer.start(Manifest.load(manifest.path)),
          throwsA(isA<ConfigError>()),
        );
      }
    },
  );

  test('symlinks and paths cannot expose files outside media root', () async {
    final outside = Directory.systemTemp.createTempSync(
      'fixture-media-outside-',
    );
    addTearDown(() => outside.deleteSync(recursive: true));
    final file = File('${outside.path}/private.mp4')
      ..writeAsStringSync('not media');
    Link('${dir.path}/escape.mp4').createSync(file.path);
    for (final path in ['escape.mp4', file.path]) {
      writeEntries([
        {...entry(), 'file': path},
      ]);
      await expectLater(
        FixtureMediaServer.start(Manifest.load(manifest.path)),
        throwsA(isA<ConfigError>()),
      );
    }
  });
}
