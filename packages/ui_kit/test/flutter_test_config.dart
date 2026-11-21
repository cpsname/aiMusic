import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/testing.dart';

/// Goldens render with the device's own faces (SF Pro, New York, Apple Color
/// Emoji) read from a macOS host. On a host without them this registers that
/// host's faces under the same family names, so the non-golden tests still run;
/// only the pixel goldens need macOS (they are re-recorded there).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (systemFontsAvailable) {
    await loadGoldenFonts();
  } else {
    await _loadHostFonts();
  }
  await testMain();
}

Future<void> _loadHostFonts() async {
  if (!Directory(r'C:\Windows\Fonts').existsSync()) return;
  Future<void> register(String family, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  }

  for (final family in const [
    'Roboto',
    'CupertinoSystemText',
    'CupertinoSystemDisplay',
    '.SF Pro Text',
    '.SF Pro Display',
    '.SF UI Text',
    '.SF UI Display',
  ]) {
    await register(family, r'C:\Windows\Fonts\segoeui.ttf');
  }
  for (final family in const ['Menlo', 'SF Mono', 'Consolas']) {
    await register(family, r'C:\Windows\Fonts\consola.ttf');
  }
  await register('Georgia', r'C:\Windows\Fonts\georgia.ttf');
  await register('Apple Color Emoji', r'C:\Windows\Fonts\seguiemj.ttf');

  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    await register(
      'MaterialIcons',
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
  }
}
