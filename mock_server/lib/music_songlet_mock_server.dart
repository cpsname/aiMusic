/// Dev-only mock of the Songlet backend (docs/songlet/backend-contract.md).
/// Never shipped: the app never depends on this package.
library;

export 'src/music_canonical_json.dart' show canonicalJson;
export 'src/music_catalog.dart';
export 'src/music_client.dart';
export 'src/music_core.dart';
export 'src/music_jws.dart';
export 'src/music_jwt.dart';
export 'src/music_ledger.dart';
export 'src/music_license_pdf.dart';
export 'src/music_lyrics.dart';
export 'src/music_safety.dart';
export 'src/music_server.dart';
export 'src/music_signature.dart';
export 'src/music_state.dart';
