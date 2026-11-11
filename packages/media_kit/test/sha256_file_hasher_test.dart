import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/src/data/sha256_file_hasher.dart';

void main() {
  const hasher = Sha256FileHasher();

  test('empty input → the canonical SHA-256 of "" (64 lowercase hex)', () {
    expect(
      hasher.sha256Hex(const <int>[]),
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
  });

  test('"abc" → the canonical SHA-256 vector', () {
    expect(
      hasher.sha256Hex(utf8.encode('abc')),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('output is always 64 lowercase hex chars', () {
    final hex = hasher.sha256Hex(utf8.encode('the quick brown fox'));
    expect(hex.length, 64);
    expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hex), isTrue);
  });
}
