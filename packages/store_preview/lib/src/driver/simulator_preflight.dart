import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import '../config/app.dart';
import '../core/errors.dart';
import '../core/process.dart';

Version _version(Object? value) {
  final text = '$value';
  if (!RegExp(r'^\d+(?:\.\d+){0,2}$').hasMatch(text)) throw ConfigError('simulator preflight: unresolved deployment version $text');
  return Version.parse([...text.split('.'), ...List.filled(3 - text.split('.').length, '0')].join('.'));
}

/// Uses the selected SDK's limits and Xcode's resolved Debug settings; never
/// guesses from the first pbxproj declaration or changes app deployment policy.
void checkSimulatorBuild({required Map sdk, required List targets, required String bundleId}) {
  final support = (sdk['SupportedTargets'] as Map?)?['iphonesimulator'] as Map?;
  if (support == null) throw ConfigError('simulator preflight: SDKSettings.json has no iphonesimulator target');
  final minimum = _version(support['MinimumDeploymentTarget']);
  final maximum = _version(support['MaximumDeploymentTarget']);
  final apps = [
    for (final t in targets)
      if (t is Map && t['buildSettings'] is Map && (t['buildSettings'] as Map)['PRODUCT_TYPE'] == 'com.apple.product-type.application')
        t['buildSettings'] as Map,
  ];
  final matching = apps.where((b) => b['PRODUCT_BUNDLE_IDENTIFIER'] == bundleId).toList();
  if (matching.length != 1) {
    throw ConfigError(
      'simulator preflight: expected one Debug application for $bundleId; Xcode resolves ${apps.map((b) => b['PRODUCT_BUNDLE_IDENTIFIER']).join(', ')}',
    );
  }
  final deployment = _version(matching.single['IPHONEOS_DEPLOYMENT_TARGET']);
  if (deployment < minimum || deployment > maximum) {
    throw ConfigError(
      'simulator preflight: $bundleId Debug deployment target $deployment is outside the selected SDK range $minimum–$maximum. '
      'Choose a compatible Xcode SDK or review the app deployment target; no project settings were changed and no simulator was erased.',
    );
  }
}

Future<void> preflightSimulatorBuild({required ProcessRunner runner, required PreviewApp app, required String root}) async {
  final sdk = await runner.run('xcrun', ['--sdk', 'iphonesimulator', '--show-sdk-path']);
  final settings = File(p.join(sdk.stdout.trim(), 'SDKSettings.json'));
  if (!settings.existsSync()) throw ConfigError('simulator preflight: selected SDK has no SDKSettings.json');
  final helper = app.driver.helper;
  final builds = await runner.run('xcodebuild', [
    '-showBuildSettings',
    '-json',
    if (helper == null) ...['-project', 'ios/Runner.xcodeproj'] else ...['-workspace', helper.workspace],
    '-scheme',
    helper?.scheme ?? 'Runner',
    '-configuration',
    'Debug',
    '-sdk',
    'iphonesimulator',
  ], workingDirectory: root);
  checkSimulatorBuild(sdk: jsonDecode(settings.readAsStringSync()) as Map, targets: jsonDecode(builds.stdout) as List, bundleId: app.bundleId);
}
