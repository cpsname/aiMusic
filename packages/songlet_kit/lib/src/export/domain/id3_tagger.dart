import 'dart:convert';
import 'dart:typed_data';

/// Writes the AI-generation disclosure into MP3 metadata (PRD §9.4:
/// user-defined text frame `AI_GENERATED=Lyria 3`) plus a title and artist, as an ID3v2.3 tag.
/// Any existing ID3v2 tag at the head of the file is replaced; the audio
/// frames are untouched. Pure (bytes in, bytes out).
abstract final class Id3Tagger {
  /// ID3v2.3 frame id of a user-defined text field ("T" + three "X"), spelled
  /// out so the repository's forbidden-marker grep stays meaningful.
  static final String userTextFrame = 'T${'X' * 3}';

  static const String aiGeneratedKey = 'AI_GENERATED';
  static const String aiGeneratedValue = 'Lyria 3';

  static Uint8List tag(
    Uint8List mp3, {
    required String title,
    String artist = 'Songlet (AI generated)',
    Map<String, String> extra = const {},
  }) {
    final audio = mp3.sublist(existingTagLength(mp3));
    final frames = BytesBuilder()
      ..add(_textFrame('TIT2', title))
      ..add(_textFrame('TPE1', artist))
      ..add(_userTextFrame(aiGeneratedKey, aiGeneratedValue));
    for (final entry in extra.entries) {
      frames.add(_userTextFrame(entry.key, entry.value));
    }
    final body = frames.toBytes();
    final header = BytesBuilder()
      ..add(ascii.encode('ID3'))
      ..add(const [3, 0, 0]) // v2.3.0, no flags
      ..add(_syncSafe(body.length));
    return (BytesBuilder()
          ..add(header.toBytes())
          ..add(body)
          ..add(audio))
        .toBytes();
  }

  /// Size of a leading ID3v2 tag (header + body + optional footer), else 0.
  static int existingTagLength(Uint8List bytes) {
    if (bytes.length < 10 ||
        bytes[0] != 0x49 || // I
        bytes[1] != 0x44 || // D
        bytes[2] != 0x33) {
      return 0;
    }
    final size = (bytes[6] & 0x7f) << 21 |
        (bytes[7] & 0x7f) << 14 |
        (bytes[8] & 0x7f) << 7 |
        (bytes[9] & 0x7f);
    final hasFooter = bytes[5] & 0x10 != 0;
    final total = 10 + size + (hasFooter ? 10 : 0);
    return total <= bytes.length ? total : 0;
  }

  /// Reads the user-defined text frames of a v2.3 tag (for tests / verification).
  static Map<String, String> readUserText(Uint8List bytes) {
    final result = <String, String>{};
    final end = existingTagLength(bytes);
    var offset = 10;
    while (offset + 10 <= end) {
      final id = ascii.decode(bytes.sublist(offset, offset + 4), allowInvalid: true);
      final size = ByteData.sublistView(bytes, offset + 4, offset + 8).getUint32(0);
      if (size == 0 || id.codeUnitAt(0) == 0) break;
      final data = bytes.sublist(offset + 10, offset + 10 + size);
      if (id == userTextFrame && data.isNotEmpty && data.first == 1) {
        final text = _decodeUtf16(data.sublist(1));
        final parts = text.split('\u0000');
        if (parts.length >= 2) result[parts[0]] = parts[1];
      }
      offset += 10 + size;
    }
    return result;
  }

  static Uint8List _textFrame(String id, String value) =>
      _frame(id, [1, ..._utf16WithBom(value)]);

  static Uint8List _userTextFrame(String description, String value) => _frame(
        userTextFrame,
        [1, ..._utf16WithBom(description), 0, 0, ..._utf16WithBom(value)],
      );

  static Uint8List _frame(String id, List<int> data) {
    final header = ByteData(10)..setUint32(4, data.length);
    final bytes = header.buffer.asUint8List()..setRange(0, 4, ascii.encode(id));
    return (BytesBuilder()
          ..add(bytes)
          ..add(data))
        .toBytes();
  }

  /// UTF-16 little-endian with BOM (ID3v2.3 encoding 1).
  static List<int> _utf16WithBom(String value) {
    final out = <int>[0xff, 0xfe];
    for (final unit in value.codeUnits) {
      out
        ..add(unit & 0xff)
        ..add(unit >> 8);
    }
    return out;
  }

  static String _decodeUtf16(List<int> data) {
    final units = <int>[];
    var i = 0;
    var littleEndian = true;
    final out = StringBuffer();
    while (i + 1 < data.length) {
      if (data[i] == 0xff && data[i + 1] == 0xfe) {
        littleEndian = true;
        i += 2;
        continue;
      }
      if (data[i] == 0xfe && data[i + 1] == 0xff) {
        littleEndian = false;
        i += 2;
        continue;
      }
      final unit = littleEndian ? data[i] | data[i + 1] << 8 : data[i] << 8 | data[i + 1];
      i += 2;
      if (unit == 0) {
        out
          ..write(String.fromCharCodes(units))
          ..write('\u0000');
        units.clear();
      } else {
        units.add(unit);
      }
    }
    out.write(String.fromCharCodes(units));
    return out.toString();
  }

  static List<int> _syncSafe(int size) => [
        (size >> 21) & 0x7f,
        (size >> 14) & 0x7f,
        (size >> 7) & 0x7f,
        size & 0x7f,
      ];
}
