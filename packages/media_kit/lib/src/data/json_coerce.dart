// Minimal defensive JSON coercion — self-contained so media_kit depends on no
// other package's internal helpers. Every coercion has a safe fallback.

Map<String, Object?> asMap(Object? value) {
  if (value is! Map) return <String, Object?>{};
  return <String, Object?>{
    for (final entry in value.entries) '${entry.key}': entry.value,
  };
}

String asString(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

bool asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) return value == 'true';
  return fallback;
}

int asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

List<String> asStringList(Object? value) {
  if (value is! List) return const <String>[];
  return <String>[for (final e in value) if (e is String) e];
}

/// Parses a Unix timestamp that may arrive as seconds or milliseconds (defensive
/// like the IAP `expires_at`): `< 1e12` is treated as seconds, else milliseconds.
/// Non-positive / non-numeric → null.
DateTime? asEpoch(Object? value) {
  final raw = value is int
      ? value
      : value is num
          ? value.toInt()
          : null;
  if (raw == null || raw <= 0) return null;
  final ms = raw < 1000000000000 ? raw * 1000 : raw;
  return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
}
