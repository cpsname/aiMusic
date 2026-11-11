import 'package:flutter_test/flutter_test.dart';
import 'package:store_preview/src/driver/simulator_preflight.dart';
import 'package:store_preview/store_preview.dart';

void main() {
  Map sdk(String minimum, String maximum) => {
    'SupportedTargets': {
      'iphonesimulator': {'MinimumDeploymentTarget': minimum, 'MaximumDeploymentTarget': maximum},
    },
  };
  List builds(String deployment, {String bundle = 'org.example.notes'}) => [
    {
      'buildSettings': {'PRODUCT_TYPE': 'com.apple.product-type.application', 'PRODUCT_BUNDLE_IDENTIFIER': bundle, 'IPHONEOS_DEPLOYMENT_TARGET': deployment},
    },
    {
      'buildSettings': {
        'PRODUCT_TYPE': 'com.apple.product-type.bundle.unit-test',
        'PRODUCT_BUNDLE_IDENTIFIER': '$bundle.Tests',
        'IPHONEOS_DEPLOYMENT_TARGET': '13.0',
      },
    },
  ];

  test('accepts resolved app settings within the installed SDK, independent of test targets', () {
    checkSimulatorBuild(sdk: sdk('15.0', '27.0.99'), targets: builds('15.0'), bundleId: 'org.example.notes');
    checkSimulatorBuild(sdk: sdk('18', '29.0.99'), targets: builds('28.1'), bundleId: 'org.example.notes');
  });
  test('reports a Flutter-created deployment target below the selected SDK before recording', () {
    expect(
      () => checkSimulatorBuild(sdk: sdk('15.0', '27.0.99'), targets: builds('13.0'), bundleId: 'org.example.notes'),
      throwsA(isA<ConfigError>().having((e) => e.message, 'diagnosis', contains('no simulator was erased'))),
    );
    expect(() => checkSimulatorBuild(sdk: sdk('15.0', '27.0.99'), targets: builds('28.0'), bundleId: 'org.example.notes'), throwsA(isA<ConfigError>()));
  });
  test('does not film another bundle or accept unresolved Xcode macros', () {
    expect(
      () => checkSimulatorBuild(
        sdk: sdk('15.0', '27.0.99'),
        targets: builds('15.0', bundle: 'org.example.other'),
        bundleId: 'org.example.notes',
      ),
      throwsA(isA<ConfigError>()),
    );
    expect(
      () => checkSimulatorBuild(sdk: sdk('15.0', '27.0.99'), targets: builds(r'$(DEPLOYMENT_TARGET)'), bundleId: 'org.example.notes'),
      throwsA(isA<ConfigError>()),
    );
    expect(() => checkSimulatorBuild(sdk: {}, targets: builds('15.0'), bundleId: 'org.example.notes'), throwsA(isA<ConfigError>()));
  });
}
