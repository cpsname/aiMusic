import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  const hash =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
  const policy = UploadPolicy();

  UploadSpec spec({
    String mime = 'image/png',
    int size = 1024,
    String fileHash = hash,
  }) =>
      UploadSpec(
        mimeType: mime,
        sizeBytes: size,
        filename: 'f.png',
        fileHash: fileHash,
      );

  test('an allowed mime within size with a valid hash passes', () {
    expect(policy.check(spec()), isNull);
  });

  test('a mime outside the allow-list → unsupportedType', () {
    expect(
      policy.check(spec(mime: 'application/x-msdownload')),
      UploadPolicyViolation.unsupportedType,
    );
  });

  test('zero / negative / over-limit size → sizeExceeded', () {
    expect(policy.check(spec(size: 0)), UploadPolicyViolation.sizeExceeded);
    expect(policy.check(spec(size: -1)), UploadPolicyViolation.sizeExceeded);
    expect(
      policy.check(spec(size: UploadPolicy.defaultMaxBytes + 1)),
      UploadPolicyViolation.sizeExceeded,
    );
    expect(policy.check(spec(size: UploadPolicy.defaultMaxBytes)), isNull);
  });

  test('a non-64-lowercase-hex hash → invalidHash', () {
    expect(policy.check(spec(fileHash: '')), UploadPolicyViolation.invalidHash);
    expect(
      policy.check(spec(fileHash: hash.toUpperCase())),
      UploadPolicyViolation.invalidHash,
    );
    expect(
      policy.check(spec(fileHash: 'abc')),
      UploadPolicyViolation.invalidHash,
    );
    expect(
      policy.check(spec(fileHash: 'z' * 64)),
      UploadPolicyViolation.invalidHash,
    );
  });

  test('isSha256Hex accepts exactly 64 lowercase hex', () {
    expect(UploadPolicy.isSha256Hex(hash), isTrue);
    expect(UploadPolicy.isSha256Hex('a' * 63), isFalse);
    expect(UploadPolicy.isSha256Hex('a' * 65), isFalse);
  });
}
