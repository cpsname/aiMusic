import 'dart:async';

import 'package:ui_kit/testing.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadGoldenFonts();
  await testMain();
}
