import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';

const _hash =
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

class _FakeRepo implements UploadRepository {
  _FakeRepo({this.signResult, this.asset});

  UploadTicket? signResult;
  Object? signThrows;
  UploadedAsset? asset;
  Object? finalizeThrows;
  Object? putThrows;

  int signCalls = 0;
  int putCalls = 0;
  int finalizeCalls = 0;
  String? putMimeSeen;
  bool sawCancellation = false;

  /// Optional hook invoked at the start of sign() — lets a test cancel mid-flow.
  void Function()? onSign;

  @override
  Future<UploadTicket> sign(UploadSpec spec, {UploadCancellation? cancellation}) async {
    signCalls += 1;
    sawCancellation = sawCancellation || cancellation != null;
    onSign?.call();
    if (signThrows != null) throw signThrows!;
    return signResult!;
  }

  @override
  Future<void> putToR2({
    required String putUrl,
    required List<int> bytes,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
    UploadCancellation? cancellation,
  }) async {
    putCalls += 1;
    putMimeSeen = mimeType;
    if (putThrows != null) throw putThrows!;
    onProgress?.call(bytes.length, bytes.length);
  }

  @override
  Future<UploadedAsset> finalize(String bid, {UploadCancellation? cancellation}) async {
    finalizeCalls += 1;
    if (finalizeThrows != null) throw finalizeThrows!;
    return asset!;
  }
}

class _FakeHasher implements FileHasher {
  const _FakeHasher(this.value);
  final String value;
  @override
  String sha256Hex(List<int> bytes) => value;
}

UploadTicket _ticket({
  bool dedupHit = false,
  String bid = 'b1',
  String putUrl = 'https://r2/p',
  String publicUrl = 'https://cdn/u.png',
}) =>
    UploadTicket(
      bid: bid,
      putUrl: putUrl,
      publicUrl: publicUrl,
      key: 'k',
      dedupHit: dedupHit,
    );

UploadedAsset _asset({bool dedupHit = false}) => UploadedAsset(
      bid: 'a1',
      url: 'https://cdn/a.png',
      fileName: 'a.png',
      fileSize: 3,
      mimeType: 'image/png',
      contentType: 'image',
      accessLevel: 'private',
      tags: const [],
      groupName: '',
      dedupHit: dedupHit,
    );

UploadInput _input({String mime = 'image/png'}) => UploadInput(
      bytes: const [1, 2, 3],
      filename: 'f.png',
      mimeType: mime,
    );

UploadService _service(
  _FakeRepo repo, {
  String hash = _hash,
  UploadPolicy policy = const UploadPolicy(),
}) =>
    UploadService(repository: repo, hasher: _FakeHasher(hash), policy: policy);

void main() {
  test('happy path: hash → sign → PUT → finalize → UploadResult(asset)',
      () async {
    final repo = _FakeRepo(signResult: _ticket(), asset: _asset());
    final phases = <UploadPhase>[];

    final result = await _service(repo).upload(
      _input(),
      onProgress: (p) => phases.add(p.phase),
    );

    expect(repo.signCalls, 1);
    expect(repo.putCalls, 1);
    expect(repo.finalizeCalls, 1);
    expect(repo.putMimeSeen, 'image/png');
    expect(result.bid, 'a1');
    expect(result.url, 'https://cdn/a.png');
    expect(result.dedupHit, isFalse);
    expect(result.asset, isNotNull);
    expect(
      phases,
      containsAllInOrder([
        UploadPhase.hashing,
        UploadPhase.signing,
        UploadPhase.uploading,
        UploadPhase.finalizing,
        UploadPhase.done,
      ]),
    );
  });

  test('dedup hit → skip PUT + finalize, reference existing asset', () async {
    final repo = _FakeRepo(
      signResult: _ticket(
        dedupHit: true,
        bid: 'existing',
        putUrl: '',
        publicUrl: 'https://cdn/existing.png',
      ),
    );

    final result = await _service(repo).upload(_input());

    expect(repo.signCalls, 1);
    expect(repo.putCalls, 0); // short-circuited
    expect(repo.finalizeCalls, 0);
    expect(result.bid, 'existing');
    expect(result.url, 'https://cdn/existing.png');
    expect(result.dedupHit, isTrue);
    expect(result.asset, isNull);
  });

  test('unsupported mime → UploadPolicyException before any network call',
      () async {
    final repo = _FakeRepo();

    await expectLater(
      _service(repo).upload(_input(mime: 'application/zip')),
      throwsA(
        isA<UploadPolicyException>().having(
          (e) => e.violation,
          'violation',
          UploadPolicyViolation.unsupportedType,
        ),
      ),
    );
    expect(repo.signCalls, 0);
  });

  test('invalid content hash → UploadPolicyException(invalidHash), no sign',
      () async {
    final repo = _FakeRepo();

    await expectLater(
      _service(repo, hash: 'not-a-real-hash').upload(_input()),
      throwsA(
        isA<UploadPolicyException>().having(
          (e) => e.violation,
          'violation',
          UploadPolicyViolation.invalidHash,
        ),
      ),
    );
    expect(repo.signCalls, 0);
  });

  test('a finalize failure propagates (after the bytes were PUT)', () async {
    final repo = _FakeRepo(signResult: _ticket())
      ..finalizeThrows = StateError('40038');

    await expectLater(
      _service(repo).upload(_input()),
      throwsA(isA<StateError>()),
    );
    expect(repo.putCalls, 1);
    expect(repo.finalizeCalls, 1);
  });

  group('cancellation', () {
    test('a pre-cancelled token → UploadCancelledException before sign',
        () async {
      final repo = _FakeRepo(signResult: _ticket(), asset: _asset());
      final cancellation = UploadCancellation()..cancel();

      await expectLater(
        _service(repo).upload(_input(), cancellation: cancellation),
        throwsA(isA<UploadCancelledException>()),
      );
      expect(repo.signCalls, 0);
    });

    test('cancel during sign → no PUT, no finalize', () async {
      final repo = _FakeRepo(signResult: _ticket(), asset: _asset());
      final cancellation = UploadCancellation();
      repo.onSign = cancellation.cancel; // user aborts while signing

      await expectLater(
        _service(repo).upload(_input(), cancellation: cancellation),
        throwsA(isA<UploadCancelledException>()),
      );
      expect(repo.signCalls, 1);
      expect(repo.putCalls, 0);
      expect(repo.finalizeCalls, 0);
    });

    test('the cancellation token is threaded to the repository', () async {
      final repo = _FakeRepo(signResult: _ticket(), asset: _asset());

      await _service(repo).upload(_input(), cancellation: UploadCancellation());

      expect(repo.sawCancellation, isTrue);
    });
  });
}
