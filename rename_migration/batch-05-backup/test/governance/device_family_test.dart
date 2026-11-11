// Governance: the iPad switch follows the shipped device family (ADR-0037).
//
// `ipadEnabled` turns the iPad layouts, goldens and tests on. It must say
// exactly what the Runner target ships: an iPad layout switched on in an
// iPhone-only app is dead code nobody sees, and an app shipped for iPad with
// the switch off would stretch the phone layout over a 13" screen.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/ui/common/device_family.dart';

/// `TARGETED_DEVICE_FAMILY` of every build configuration of the Runner
/// target (the configurations that use Runner/Info.plist).
List<String> runnerDeviceFamilies(String pbxproj) {
  final families = <String>[];
  final config = RegExp(r'buildSettings = \{(.*?)\n\t\t\t\};', dotAll: true);
  for (final m in config.allMatches(pbxproj)) {
    final settings = m.group(1)!;
    if (!settings.contains('INFOPLIST_FILE = Runner/Info.plist;')) continue;
    final family = RegExp(
      r'TARGETED_DEVICE_FAMILY = "?([0-9,]+)"?;',
    ).firstMatch(settings);
    families.add(family?.group(1) ?? '1');
  }
  return families;
}

void main() {
  test('ipadEnabled is true exactly when the Runner target ships for iPad', () {
    final families = runnerDeviceFamilies(
      File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(),
    );
    expect(families, isNotEmpty, reason: 'no Runner build configuration found');
    expect(
      families.toSet(),
      hasLength(1),
      reason:
          'Debug / Release / Profile ship different device families: $families',
    );
    final shipsIpad = families.first.split(',').contains('2');
    expect(
      ipadEnabled,
      shipsIpad,
      reason: shipsIpad
          ? 'Runner ships for iPad (TARGETED_DEVICE_FAMILY = ${families.first}): turn ipadEnabled on in '
                'lib/ui/common/device_family.dart (ADR-0037)'
          : 'Runner is iPhone-only (TARGETED_DEVICE_FAMILY = ${families.first}): ipadEnabled must stay off, '
                'or change both together (ADR-0037)',
    );
  });

  test('the parser reads a universal Runner configuration', () {
    const pbxproj = '''
\t\t1 /* Release */ = {
\t\t\tbuildSettings = {
\t\t\t\tINFOPLIST_FILE = Runner/Info.plist;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t};
\t\t2 /* Release */ = {
\t\t\tbuildSettings = {
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t};
''';
    expect(runnerDeviceFamilies(pbxproj), ['1,2']);
  });
}
