import 'package:crypto/crypto.dart';

import '../domain/file_hasher.dart';

/// [FileHasher] backed by `package:crypto`. `sha256.convert(...).toString()`
/// yields exactly the contract's shape: 64 lowercase hex chars.
///
/// Note: hashing runs synchronously on the calling isolate. For very large files
/// on low-end devices, run the upload off the UI path (or compute the hash in an
/// isolate) to avoid a frame hitch; typical paramreference images hash in a few ms.
class Sha256FileHasher implements FileHasher {
  const Sha256FileHasher();

  @override
  String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();
}
