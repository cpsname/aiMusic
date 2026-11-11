/// Computes the content hash the upload contract requires: SHA-256 as 64
/// lowercase hex. Implemented in the data layer (`Sha256FileHasher`) and bound in
/// the composition root, so the application layer stays pure and testable.
abstract interface class FileHasher {
  String sha256Hex(List<int> bytes);
}
