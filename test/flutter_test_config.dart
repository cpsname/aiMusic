import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/testing.dart';

/// Golden tests render with the device's own faces (ADR-0007): SF Pro, New York
/// and Apple Color Emoji, read from a macOS host.
///
/// On a host without them (Windows, Linux) this falls back to that host's
/// system faces under the same family names, so layout, state and theme tests
/// still run; only the pixel goldens need macOS (they record the wrong faces
/// elsewhere, which is why they are re-recorded on a Mac).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (systemFontsAvailable) {
    await loadGoldenFonts();
  } else {
    await _loadHostFonts();
  }
  await testMain();
}

Future<void> _loadHostFonts() async {
  final windowsFonts = Directory(r'C:\Windows\Fonts');
  if (!windowsFonts.existsSync()) return;
  const families = [
    'Roboto',
    'CupertinoSystemText',
    'CupertinoSystemDisplay',
    '.SF Pro Text',
    '.SF Pro Display',
    '.SF UI Text',
    '.SF UI Display',
  ];
  Future<void> register(String family, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  }

  for (final family in families) {
    await register(family, r'C:\Windows\Fonts\segoeui.ttf');
  }
  // The mono voice (Menlo on iOS): Consolas stands in on this host.
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
