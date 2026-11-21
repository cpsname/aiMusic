import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Windows stand-in for `package:ui_kit/testing.dart`'s macOS font loader.
///
/// The real loader reads SF Pro / New York off a macOS host. This preview run
/// happens on Windows, so it registers Segoe UI under the platform family
/// names, Georgia as the serif, and the emoji face — enough to judge layout,
/// colour and typography while keeping the SDK's icon font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await _loadFonts();
  await testMain();
}

Future<void> _loadFonts() async {
  const windows = r'C:\Windows\Fonts';
  final sans = File('$windows\\segoeui.ttf');
  final serif = File('$windows\\georgia.ttf');
  final emoji = File('$windows\\seguiemj.ttf');

  if (sans.existsSync()) {
    final bytes = sans.readAsBytesSync();
    for (final family in const [
      'Roboto',
      'CupertinoSystemText',
      'CupertinoSystemDisplay',
      '.SF Pro Text',
      '.SF Pro Display',
      '.SF UI Text',
      '.SF UI Display',
      // The mono voice: Windows' Consolas stands in for Menlo.
      'Menlo',
    ]) {
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    }
  }
  final mono = File('$windows\\consola.ttf');
  if (mono.existsSync()) {
    final bytes = mono.readAsBytesSync();
    for (final family in const ['Menlo', 'SF Mono', 'Consolas']) {
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    }
  }
  if (serif.existsSync()) {
    final loader = FontLoader('Georgia')
      ..addFont(
        Future.value(ByteData.sublistView(serif.readAsBytesSync())),
      );
    await loader.load();
  }
  if (emoji.existsSync()) {
    final loader = FontLoader('Apple Color Emoji')
      ..addFont(
        Future.value(ByteData.sublistView(emoji.readAsBytesSync())),
      );
    await loader.load();
  }
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(ByteData.sublistView(icons.readAsBytesSync())),
        );
      await loader.load();
    }
  }
}
