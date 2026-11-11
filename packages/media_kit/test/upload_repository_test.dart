import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit/src/data/upload_repository_impl.dart';

import 'support/fake_http_adapter.dart';

void main() {
  const hash =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  Dio apiDioWith(FakeHttpAdapter adapter) =>
      Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
        ..httpClientAdapter = adapter;

  test('sign POSTs /uploads/sign with the spec body and parses the ticket',
      () async {
    final api = FakeHttpAdapter(
      (options, _) => jsonResponse({
        'bid': 'b1',
        'put_url': 'https://r2/p?sig=x',
        'public_url': 'https://cdn/u.png',
        'key': 'uploads/u.png',
        'dedup_hit': false,
        'expires_at': 1714555800,
      }),
    );
    final repo = UploadRepositoryImpl(apiDio: apiDioWith(api), r2Dio: Dio());

    final ticket = await repo.sign(
      const UploadSpec(
        mimeType: 'image/png',
        sizeBytes: 10,
        filename: 'f.png',
        fileHash: hash,
        contentKind: UploadContentKind.image,
      ),
    );

    final req = api.requests.single;
    expect(req.method, 'POST');
    expect(req.path, '/uploads/sign');
    expect((req.data! as Map)['file_hash'], hash);
    expect((req.data! as Map)['content_type'], 'image');
    expect(ticket.bid, 'b1');
    expect(ticket.putUrl, 'https://r2/p?sig=x');
    expect(ticket.dedupHit, isFalse);
  });

  test('finalize POSTs /uploads/finalize with {bid} and parses the asset',
      () async {
    final api = FakeHttpAdapter(
      (options, _) => jsonResponse({
        'bid': 'a1',
        'url': 'https://cdn/a.png',
        'file_name': 'a.png',
        'file_size': 5,
        'mime_type': 'image/png',
        'content_type': 'image',
        'access_level': 'private',
        'tags': <String>[],
        'group_name': '',
        'dedup_hit': false,
      }),
    );
    final repo = UploadRepositoryImpl(apiDio: apiDioWith(api), r2Dio: Dio());

    final asset = await repo.finalize('b1');

    final req = api.requests.single;
    expect(req.method, 'POST');
    expect(req.path, '/uploads/finalize');
    expect(req.data, {'bid': 'b1'});
    expect(asset.bid, 'a1');
  });

  test('putToR2 issues a raw PUT to the absolute presigned URL with the mime',
      () async {
    final r2 = FakeHttpAdapter((options, _) => emptyResponse());
    final repo = UploadRepositoryImpl(
      apiDio: Dio(),
      r2Dio: Dio()..httpClientAdapter = r2,
    );
    const url = 'https://r2.example.com/uploads/abc.png?sig=test';

    await repo.putToR2(
      putUrl: url,
      bytes: const [1, 2, 3],
      mimeType: 'image/png',
    );

    final req = r2.requests.single;
    expect(req.method, 'PUT');
    expect(req.uri.toString(), url);
    expect(req.contentType, 'image/png');
  });

  test('a non-cancel R2 PUT failure surfaces as R2UploadException', () async {
    final r2 = FakeHttpAdapter((options, _) => emptyResponse(statusCode: 403));
    final repo = UploadRepositoryImpl(
      apiDio: Dio(),
      r2Dio: Dio()..httpClientAdapter = r2,
    );

    await expectLater(
      repo.putToR2(
        putUrl: 'https://r2.example.com/x?sig=bad',
        bytes: const [1, 2, 3],
        mimeType: 'image/png',
      ),
      throwsA(
        isA<R2UploadException>().having((e) => e.statusCode, 'statusCode', 403),
      ),
    );
  });

  test('a cancelled PUT surfaces as UploadCancelledException (not R2)',
      () async {
    final r2 = FakeHttpAdapter((options, _) => emptyResponse());
    final repo = UploadRepositoryImpl(
      apiDio: Dio(),
      r2Dio: Dio()..httpClientAdapter = r2,
    );
    final cancellation = UploadCancellation()..cancel();

    await expectLater(
      repo.putToR2(
        putUrl: 'https://r2.example.com/x?sig=t',
        bytes: const [1, 2, 3],
        mimeType: 'image/png',
        cancellation: cancellation,
      ),
      throwsA(isA<UploadCancelledException>()),
    );
  });
}
