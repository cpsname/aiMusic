import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'music_core.dart';

/// One parsed incoming request.
class MusicRequestContext {
  MusicRequestContext(this.request, this.body, this.json);

  final HttpRequest request;
  final Uint8List body;

  /// Decoded JSON body, or null when the body was empty.
  final Object? json;

  String get method => request.method;

  List<String> get segments => request.uri.pathSegments;

  String? header(String name) {
    final values = request.headers[name];
    return values == null || values.isEmpty ? null : values.first;
  }

  /// `scheme://host:port` as the client addressed us (the `Host` header), so
  /// absolute URLs work from the simulator (`localhost`) and devices (LAN IP).
  String get baseUrl =>
      '${request.requestedUri.scheme}://${request.requestedUri.authority}';

  /// The body as a JSON object (missing body → empty map).
  Map<String, Object?> get jsonMap => switch (json) {
    null => <String, Object?>{},
    final Map<String, Object?> m => m,
    _ => throw MusicApiException.validation('body', 'must be a JSON object'),
  };

  static Object? decodeJson(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw MusicApiException.validation('body', 'is not valid UTF-8 JSON');
    }
  }
}

/// What a handler produces; the server writes it.
sealed class MusicReply {
  const MusicReply({this.status = HttpStatus.ok, this.logNote});

  final int status;

  /// Extra token for the access log (e.g. a job's `error_code`).
  final String? logNote;
}

/// A successful envelope around [data].
class MusicJsonReply extends MusicReply {
  const MusicJsonReply(this.data, {super.logNote});

  final Object? data;
}

class MusicBytesReply extends MusicReply {
  const MusicBytesReply(
    this.bytes, {
    required this.contentType,
    this.headers = const {},
    super.status,
  });

  final List<int> bytes;
  final String contentType;
  final Map<String, String> headers;
}

class MusicEmptyReply extends MusicReply {
  const MusicEmptyReply({super.status, this.headers = const {}});

  final Map<String, String> headers;
}

// ── Body field readers (all throw 40001 on a bad shape) ─────────────────────

String requireString(Map<String, Object?> body, String key) {
  final v = body[key];
  if (v is String && v.trim().isNotEmpty) return v;
  throw MusicApiException.validation(key, 'is required');
}

String? optionalString(Map<String, Object?> body, String key) {
  final v = body[key];
  if (v == null) return null;
  if (v is String) return v;
  throw MusicApiException.validation(key, 'must be a string');
}

List<String> optionalStringList(Map<String, Object?> body, String key) {
  final v = body[key];
  if (v == null) return const [];
  if (v is List && v.every((e) => e is String)) return v.cast<String>();
  throw MusicApiException.validation(key, 'must be a list of strings');
}

num? optionalNum(Map<String, Object?> body, String key) {
  final v = body[key];
  if (v == null) return null;
  if (v is num) return v;
  throw MusicApiException.validation(key, 'must be a number');
}

/// Resolves an HTTP `Range: bytes=…` header against [total] bytes.
/// Returns null for "no range"; throws [RangeError] when unsatisfiable.
(int start, int end)? parseByteRange(String? header, int total) {
  if (header == null) return null;
  final m = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(header.trim());
  if (m == null || (m[1]!.isEmpty && m[2]!.isEmpty)) {
    throw RangeError('unsupported range "$header"');
  }
  int start;
  int end;
  if (m[1]!.isEmpty) {
    final suffix = int.parse(m[2]!);
    if (suffix == 0) throw RangeError('empty suffix range');
    start = total - suffix < 0 ? 0 : total - suffix;
    end = total - 1;
  } else {
    start = int.parse(m[1]!);
    end = m[2]!.isEmpty ? total - 1 : int.parse(m[2]!);
    if (end >= total) end = total - 1;
  }
  if (start >= total || start > end) throw RangeError('unsatisfiable range');
  return (start, end);
}
