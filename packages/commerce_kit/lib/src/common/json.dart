/// Defensive JSON coercion helpers shared by the data layer. The backend is
/// well-typed, but graceful degradation means never throwing on a missing or
/// loosely-typed field.
library;

int asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

String asString(Object? value, [String fallback = '']) {
  if (value is String) return value;
  return value?.toString() ?? fallback;
}

bool asBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) return value == 'true';
  return fallback;
}

Map<String, dynamic> asMap(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

List<Map<String, dynamic>> asMapList(Object? value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList(growable: false)
    : const <Map<String, dynamic>>[];

List<String> asStringList(Object? value) => value is List
    ? value.map(asString).toList(growable: false)
    : const <String>[];

/// Converts a Unix-seconds timestamp to UTC; null on absence.
DateTime? dateFromEpochSeconds(Object? value) =>
    value is int && value > 0
        ? DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
        : null;
