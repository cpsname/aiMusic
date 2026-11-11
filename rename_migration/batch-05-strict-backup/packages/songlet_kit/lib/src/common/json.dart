/// Defensive JSON coercion for the Songlet data layer: a missing or loosely
/// typed field degrades to a default instead of throwing.
library;

int asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

double asDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? fallback;
}

String asString(Object? value, [String fallback = '']) {
  if (value is String) return value;
  return value?.toString() ?? fallback;
}

String? asNullableString(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

Map<String, Object?> asMap(Object? value) => value is Map
    ? value.map((Object? k, Object? v) => MapEntry('$k', v))
    : const <String, Object?>{};

List<Map<String, Object?>> asMapList(Object? value) => value is List
    ? value.whereType<Map<Object?, Object?>>().map(asMap).toList(growable: false)
    : const <Map<String, Object?>>[];

List<String> asStringList(Object? value) => value is List
    ? value.map((Object? e) => asString(e)).toList(growable: false)
    : const <String>[];

bool asBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return switch ('$value'.toLowerCase()) {
    'true' || '1' => true,
    'false' || '0' => false,
    _ => fallback,
  };
}
