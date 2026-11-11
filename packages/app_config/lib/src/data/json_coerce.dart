// Minimal defensive JSON coercion — self-contained so app_config depends on no
// other package's internal helpers. Every coercion has a safe fallback.

Map<String, Object?> asMap(Object? value) {
  if (value is! Map) return <String, Object?>{};
  return <String, Object?>{
    for (final entry in value.entries) '${entry.key}': entry.value,
  };
}

bool asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) return value == 'true';
  return fallback;
}

String asString(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;
