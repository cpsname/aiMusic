import 'dart:convert';

// Server-side twin of `infra_core`'s `canonical_json.dart` (the client signs
// with that one). Kept byte-for-byte equivalent so the mock recomputes the
// exact `X-App-Signature` the client produced:
//
// * object keys sorted recursively by their UTF-8 byte sequence;
// * compact output, Go's HTML-safe escaping of `<`, `>`, `&`, U+2028, U+2029;
// * a `null`/empty body encodes to the literal `{}`.

/// Canonical JSON of [value] (the body segment of the app signature).
String canonicalJson(Object? value) {
  if (value == null) return '{}';
  if (value is Map && value.isEmpty) return '{}';
  final buffer = StringBuffer();
  _write(buffer, value);
  return buffer.toString();
}

void _write(StringBuffer sb, Object? value) {
  switch (value) {
    case null:
      sb.write('null');
    case final bool b:
      sb.write(b ? 'true' : 'false');
    case final int i:
      sb.write(i.toString());
    case final double d:
      sb.write(_encodeDouble(d));
    case final String s:
      _writeString(sb, s);
    case final Map<dynamic, dynamic> map:
      _writeMap(sb, map);
    case final Iterable<dynamic> list:
      _writeList(sb, list);
    default:
      // Fall back to the value's JSON-encodable form (e.g. a custom toJson()).
      _write(sb, _toEncodable(value));
  }
}

Object? _toEncodable(Object value) {
  final dynamic dynamicValue = value;
  try {
    // ignore: avoid_dynamic_calls
    return dynamicValue.toJson() as Object?;
  } on NoSuchMethodError {
    return value.toString();
  }
}

void _writeMap(StringBuffer sb, Map<dynamic, dynamic> map) {
  final keys = map.keys.map((dynamic k) => k.toString()).toList()
    ..sort(_compareUtf8);
  sb.write('{');
  for (var i = 0; i < keys.length; i++) {
    if (i > 0) sb.write(',');
    _writeString(sb, keys[i]);
    sb.write(':');
    _write(sb, map[keys[i]]);
  }
  sb.write('}');
}

void _writeList(StringBuffer sb, Iterable<dynamic> list) {
  sb.write('[');
  var first = true;
  for (final dynamic item in list) {
    if (!first) sb.write(',');
    first = false;
    _write(sb, item as Object?);
  }
  sb.write(']');
}

String _encodeDouble(double d) {
  if (d == d.truncateToDouble() && d.isFinite) {
    return d.toInt().toString();
  }
  return d.toString();
}

/// Matches `sort.Strings` in Go: lexicographic by UTF-8 bytes.
int _compareUtf8(String a, String b) {
  final ab = utf8.encode(a);
  final bb = utf8.encode(b);
  final n = ab.length < bb.length ? ab.length : bb.length;
  for (var i = 0; i < n; i++) {
    final diff = ab[i] - bb[i];
    if (diff != 0) return diff;
  }
  return ab.length - bb.length;
}

/// String escaping that mirrors Go's `encoding/json` default encoder
/// (`escapeHTML = true`).
void _writeString(StringBuffer sb, String s) {
  sb.write('"');
  for (final rune in s.runes) {
    switch (rune) {
      case 0x22: // "
        sb.write(r'\"');
      case 0x5C: // backslash
        sb.write(r'\\');
      case 0x0A: // \n
        sb.write(r'\n');
      case 0x0D: // \r
        sb.write(r'\r');
      case 0x09: // \t
        sb.write(r'\t');
      case 0x3C: // <  (Go escapes these for HTML safety)
      case 0x3E: // >
      case 0x26: // &
      case 0x2028: // line separator
      case 0x2029: // paragraph separator
        _writeUnicodeEscape(sb, rune);
      default:
        if (rune < 0x20) {
          _writeUnicodeEscape(sb, rune);
        } else {
          sb.writeCharCode(rune);
        }
    }
  }
  sb.write('"');
}

/// Writes a `\u` followed by 4 lowercase hex digits (built at runtime to avoid
/// any literal unicode-escape sequence in source).
void _writeUnicodeEscape(StringBuffer sb, int rune) {
  sb.write(r'\u');
  sb.write(rune.toRadixString(16).padLeft(4, '0'));
}
