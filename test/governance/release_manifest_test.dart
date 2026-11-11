// Governance: release-build platform manifests.
//
// Flutter's template declares android.permission.INTERNET only in the
// debug/profile manifest overlays; the main manifest ships in the release
// build. This app cannot function without the network (signed BFF calls, IAP
// verify), so a release APK/AAB missing the permission would fail every request
// in the field while working perfectly in every debug run.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the release (main) Android manifest declares INTERNET', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android.permission.INTERNET'));
  });
}
