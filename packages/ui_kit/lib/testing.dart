/// Test support for goldens that should look like the device (ADR-0007).
/// Not exported from `ui_kit.dart`; import `package:ui_kit/testing.dart` from
/// `flutter_test_config.dart` only.
library;

import 'dart:io';

import 'package:flutter/services.dart';

import 'src/tokens/songlet_type.dart';

/// System font files used on iOS, read from the macOS host at test time (they
/// are never bundled into the repository or the app).
const Map<String, String> _systemFonts = {
  'SF': '/System/Library/Fonts/SFNS.ttf',
  'serif': '/System/Library/Fonts/NewYork.ttf',
  'devanagari': '/System/Library/Fonts/Kohinoor.ttc',
};

/// Colour emoji (country flags), registered under [SongletType.emojiFamily].
const String _emojiFont = '/System/Library/Fonts/Apple Color Emoji.ttc';

/// Family names Flutter resolves by default on each platform; the SF file is
/// registered under all of them so un-styled text renders in SF.
const List<String> _defaultFamilies = [
  'Roboto',
  'CupertinoSystemText',
  'CupertinoSystemDisplay',
  '.SF Pro Text',
  '.SF Pro Display',
  '.SF UI Text',
  '.SF UI Display',
];

/// Whether the host has the iOS system font (every macOS machine does).
bool get systemFontsAvailable =>
    _systemFonts.values.every((path) => File(path).existsSync());

/// Registers SF under the default families plus the Material icon font from
/// the Flutter SDK cache. Call once before golden tests; throws
/// [StateError] with the missing path on a host without the fonts.
Future<void> loadGoldenFonts() async {
  final devanagari = File(_systemFonts['devanagari']!);
  if (devanagari.existsSync()) {
    final loader = FontLoader('Kohinoor Devanagari')
      ..addFont(
        Future.value(ByteData.sublistView(devanagari.readAsBytesSync())),
      );
    await loader.load();
  }
  final sf = File(_systemFonts['SF']!);
  if (!sf.existsSync()) {
    throw StateError(
      'Golden tests need ${sf.path} (macOS). Run them on a macOS host.',
    );
  }
  final bytes = sf.readAsBytesSync();
  for (final family in _defaultFamilies) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
  final serif = File(_systemFonts['serif']!);
  if (serif.existsSync()) {
    final loader = FontLoader(SongletType.serifFamily)
      ..addFont(Future.value(ByteData.sublistView(serif.readAsBytesSync())));
    await loader.load();
  }
  final emoji = File(_emojiFont);
  if (emoji.existsSync()) {
    final loader = FontLoader(SongletType.emojiFamily)
      ..addFont(Future.value(ByteData.sublistView(emoji.readAsBytesSync())));
    await loader.load();
  }
  final icons = _materialIconsFile();
  if (icons != null) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

/// `MaterialIcons-Regular.otf` from the Flutter SDK cache, located from the
/// `FLUTTER_ROOT` the test runner exports.
File? _materialIconsFile() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return null;
  final file = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  return file.existsSync() ? file : null;
}
