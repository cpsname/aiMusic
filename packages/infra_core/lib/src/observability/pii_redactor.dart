/// Masks personally-identifiable / secret material before it reaches a telemetry
/// vendor. Two layers: **key-based** (values under sensitive keys are always
/// masked, regardless of content) and **pattern-based** (free-form occurrences in
/// strings — JWTs, bearer tokens, emails, long hex secrets/signatures, E.164
/// phone numbers). Conservative by design: it never masks dashed UUIDs (so
/// `request_id` stays correlatable) or short digit runs (order numbers).
class PiiRedactor {
  const PiiRedactor();

  static const String _mask = '«redacted»';

  /// Values under these keys are masked wholesale (case-insensitive).
  static const Set<String> _sensitiveKeys = {
    'authorization',
    'token',
    'access_token',
    'accesstoken',
    'refresh_token',
    'refreshtoken',
    'id_token',
    'secret',
    'distribution_secret',
    'distributionsecret',
    'password',
    'pwd',
    'signature',
    'x-app-signature',
    'nonce',
    'api_key',
    'apikey',
    'email',
    'phone',
    'phone_number',
    'mobile',
  };

  static final RegExp _jwt =
      RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+');
  static final RegExp _bearer =
      RegExp(r'[Bb]earer\s+[A-Za-z0-9._~+/=-]+');
  static final RegExp _email =
      RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
  // 32+ contiguous hex chars: HMAC signatures, SHA digests, raw secrets. Dashed
  // UUIDs (request_id) are not contiguous hex, so they survive.
  static final RegExp _longHex = RegExp(r'[0-9a-fA-F]{32,}');
  // E.164-ish: a leading + and 8–15 digits. Avoids masking plain digit runs.
  static final RegExp _phone = RegExp(r'\+\d{8,15}');

  /// Masks PII patterns inside a free-form string.
  String redactString(String input) {
    return input
        .replaceAll(_jwt, _mask)
        .replaceAll(_bearer, 'Bearer $_mask')
        .replaceAll(_email, _mask)
        .replaceAll(_longHex, _mask)
        .replaceAll(_phone, _mask);
  }

  /// Recursively redacts a value. When [key] names a sensitive field the whole
  /// value is masked; otherwise strings are pattern-scrubbed and maps/lists are
  /// walked.
  Object? redactValue(Object? value, {String? key}) {
    if (key != null && _sensitiveKeys.contains(key.toLowerCase())) return _mask;
    if (value is String) return redactString(value);
    if (value is Map) {
      return value.map(
        (dynamic k, dynamic v) => MapEntry('$k', redactValue(v, key: '$k')),
      );
    }
    if (value is Iterable) {
      return value.map<Object?>((dynamic v) => redactValue(v)).toList();
    }
    return value;
  }

  /// Redacts every entry of a properties/context map.
  Map<String, Object?> redactMap(Map<String, Object?> input) {
    final result = <String, Object?>{};
    input.forEach((key, value) => result[key] = redactValue(value, key: key));
    return result;
  }
}
