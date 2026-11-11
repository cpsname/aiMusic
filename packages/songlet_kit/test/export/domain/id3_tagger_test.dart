import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

/// Fake MPEG audio: a frame-sync header followed by a deterministic payload.
Uint8List audioBytes([int length = 2048]) => Uint8List.fromList([
      0xff, 0xfb, 0x90, 0x64,
      for (var i = 4; i < length; i++) (i * 31 + 7) & 0xff,
    ]);

/// A hand-built ID3v2.[version] header + [bodyLength] bytes of body.
Uint8List foreignTag({int version = 4, int bodyLength = 300, bool footer = false}) {
  final size = [
    (bodyLength >> 21) & 0x7f,
    (bodyLength >> 14) & 0x7f,
    (bodyLength >> 7) & 0x7f,
    bodyLength & 0x7f,
  ];
  return Uint8List.fromList([
    ...ascii.encode('ID3'),
    version,
    0,
    footer ? 0x10 : 0,
    ...size,
    for (var i = 0; i < bodyLength; i++) 0x41 + i % 26,
    if (footer) ...[...ascii.encode('3DI'), version, 0, 0x10, ...size],
  ]);
}

void main() {
  group('tag', () {
    test('writes an ID3v2.3 header in front of the audio', () {
      final audio = audioBytes();
      final tagged = Id3Tagger.tag(audio, title: 'Songlet song for Alex');

      expect(ascii.decode(tagged.sublist(0, 3)), 'ID3');
      expect(tagged.sublist(3, 5), [3, 0]);
      expect(tagged[5], 0, reason: 'no flags');
      final tagLength = Id3Tagger.existingTagLength(tagged);
      expect(tagLength, greaterThan(10));
      expect(tagged.sublist(tagLength), audio);
    });

    test('readUserText round-trips AI_GENERATED=Lyria 3', () {
      final tagged = Id3Tagger.tag(audioBytes(), title: 'x');
      expect(Id3Tagger.readUserText(tagged), {'AI_GENERATED': 'Lyria 3'});
      expect(Id3Tagger.aiGeneratedKey, 'AI_GENERATED');
      expect(Id3Tagger.aiGeneratedValue, 'Lyria 3');
    });

    test('extra user-text frames round-trip, non-ASCII included', () {
      final tagged = Id3Tagger.tag(
        audioBytes(),
        title: '生日快乐 🎂',
        extra: {'SONGLET_WORK': 'w-1', 'OCCASION': 'anniversaire été 🎉'},
      );
      expect(Id3Tagger.readUserText(tagged), {
        'AI_GENERATED': 'Lyria 3',
        'SONGLET_WORK': 'w-1',
        'OCCASION': 'anniversaire été 🎉',
      });
    });

    test('writes TIT2 (title) and TPE1 (artist) frames', () {
      final tagged = Id3Tagger.tag(audioBytes(), title: 'Hi', artist: 'Me');
      final frames = _frameIds(tagged);
      expect(frames, ['TIT2', 'TPE1', Id3Tagger.userTextFrame]);
      // TIT2 = encoding 1 + BOM + "Hi" in UTF-16LE.
      expect(tagged.sublist(20, 27), [1, 0xff, 0xfe, 0x48, 0, 0x69, 0]);
    });

    test('the header size is syncsafe and matches the frames', () {
      final tagged = Id3Tagger.tag(audioBytes(), title: 'a' * 200);
      for (final byte in tagged.sublist(6, 10)) {
        expect(byte & 0x80, 0, reason: 'syncsafe bytes never set the high bit');
      }
      final bodyLength = Id3Tagger.existingTagLength(tagged) - 10;
      var offset = 10;
      while (offset < 10 + bodyLength) {
        final size = ByteData.sublistView(tagged, offset + 4, offset + 8).getUint32(0);
        offset += 10 + size;
      }
      expect(offset, 10 + bodyLength, reason: 'frames exactly fill the tag');
    });

    test('an existing ID3v2 tag is replaced; the audio is preserved byte for byte', () {
      final audio = audioBytes(4096);
      final original = Uint8List.fromList([...foreignTag(), ...audio]);
      expect(Id3Tagger.existingTagLength(original), 310);

      final retagged = Id3Tagger.tag(original, title: 'new');

      expect(Id3Tagger.readUserText(retagged), {'AI_GENERATED': 'Lyria 3'});
      expect(retagged.sublist(Id3Tagger.existingTagLength(retagged)), audio);
      expect(ascii.decode(retagged.sublist(0, 3)), 'ID3');
      expect(
        retagged.length,
        Id3Tagger.existingTagLength(retagged) + audio.length,
        reason: 'no byte of the old tag survives',
      );
      expect(retagged, Id3Tagger.tag(audio, title: 'new'));
    });

    test('a tag with a footer is fully replaced', () {
      final audio = audioBytes(512);
      final original = Uint8List.fromList([...foreignTag(footer: true), ...audio]);
      expect(Id3Tagger.existingTagLength(original), 10 + 300 + 10);

      final retagged = Id3Tagger.tag(original, title: 't');
      expect(retagged.sublist(Id3Tagger.existingTagLength(retagged)), audio);
    });

    test('re-tagging is idempotent on the audio', () {
      final audio = audioBytes();
      final once = Id3Tagger.tag(audio, title: 'one');
      final twice = Id3Tagger.tag(once, title: 'one');
      expect(twice, once);
    });

    test('tags empty audio', () {
      final tagged = Id3Tagger.tag(Uint8List(0), title: 'x');
      expect(Id3Tagger.existingTagLength(tagged), tagged.length);
      expect(Id3Tagger.readUserText(tagged), {'AI_GENERATED': 'Lyria 3'});
    });
  });

  group('existingTagLength', () {
    test('is 0 for non-ID3 input', () {
      expect(Id3Tagger.existingTagLength(audioBytes()), 0);
      expect(Id3Tagger.existingTagLength(Uint8List(0)), 0);
      expect(Id3Tagger.existingTagLength(Uint8List.fromList(ascii.encode('ID3'))), 0);
      expect(
        Id3Tagger.existingTagLength(Uint8List.fromList(ascii.encode('RIFF....WAVEfmt '))),
        0,
      );
    });

    test('is 0 for a truncated tag (declared size past the end)', () {
      final truncated = foreignTag().sublist(0, 100);
      expect(Id3Tagger.existingTagLength(truncated), 0);
    });

    test('readUserText on untagged audio is empty', () {
      expect(Id3Tagger.readUserText(audioBytes()), isEmpty);
    });
  });
}

List<String> _frameIds(Uint8List tagged) {
  final end = Id3Tagger.existingTagLength(tagged);
  final ids = <String>[];
  var offset = 10;
  while (offset + 10 <= end) {
    ids.add(ascii.decode(tagged.sublist(offset, offset + 4)));
    final size = ByteData.sublistView(tagged, offset + 4, offset + 8).getUint32(0);
    offset += 10 + size;
  }
  return ids;
}
