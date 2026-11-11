import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit/src/data/upload_dtos.dart';

void main() {
  const hash =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  group('signRequestJson', () {
    test('serializes the full spec incl. file_hash + access_level + content', () {
      final json = signRequestJson(
        const UploadSpec(
          mimeType: 'image/png',
          sizeBytes: 102400,
          filename: 'logo.png',
          fileHash: hash,
          contentKind: UploadContentKind.image,
          accessLevel: UploadAccessLevel.public,
        ),
      );
      expect(json, {
        'mime_type': 'image/png',
        'size': 102400,
        'filename': 'logo.png',
        'file_hash': hash,
        'access_level': 'public',
        'content_type': 'image',
      });
    });

    test('omits content_type when contentKind is null; defaults access private',
        () {
      final json = signRequestJson(
        const UploadSpec(
          mimeType: 'application/pdf',
          sizeBytes: 10,
          filename: 'a.pdf',
          fileHash: hash,
        ),
      );
      expect(json.containsKey('content_type'), isFalse);
      expect(json['access_level'], 'private');
    });
  });

  group('ticketFromJson', () {
    test('parses a normal (non-dedup) sign response', () {
      final t = ticketFromJson({
        'bid': 'b1',
        'put_url': 'https://r2/put?sig=x',
        'public_url': 'https://cdn/u.png',
        'key': 'uploads/u.png',
        'expires_at': 1714555800,
        'dedup_hit': false,
      });
      expect(t.bid, 'b1');
      expect(t.putUrl, 'https://r2/put?sig=x');
      expect(t.publicUrl, 'https://cdn/u.png');
      expect(t.dedupHit, isFalse);
      expect(t.expiresAt, DateTime.fromMillisecondsSinceEpoch(1714555800 * 1000, isUtc: true));
    });

    test('dedup hit → empty put_url, dedup_hit true', () {
      final t = ticketFromJson({
        'bid': 'existing',
        'put_url': '',
        'public_url': 'https://cdn/existing.png',
        'key': '',
        'dedup_hit': true,
      });
      expect(t.dedupHit, isTrue);
      expect(t.putUrl, isEmpty);
      expect(t.bid, 'existing');
    });

    test('missing/garbage fields degrade to safe defaults', () {
      final t = ticketFromJson({'bid': 'b'});
      expect(t.putUrl, '');
      expect(t.dedupHit, isFalse);
      expect(t.expiresAt, isNull);
    });
  });

  group('assetFromJson', () {
    test('parses the finalize Asset DTO', () {
      final a = assetFromJson({
        'bid': 'a1',
        'url': 'https://cdn/a.png',
        'file_name': 'a.png',
        'file_size': 2048,
        'mime_type': 'image/png',
        'content_type': 'image',
        'access_level': 'private',
        'tags': ['x', 1, 'y'],
        'group_name': 'g',
        'created_at': 1715760010,
        'dedup_hit': true,
      });
      expect(a.bid, 'a1');
      expect(a.fileSize, 2048);
      expect(a.tags, ['x', 'y']); // non-strings filtered
      expect(a.dedupHit, isTrue);
      expect(a.createdAt, isNotNull);
    });
  });
}
