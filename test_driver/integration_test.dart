import 'package:integration_test/integration_test_driver.dart';

/// `flutter drive` host side of integration_test/: writes the test's
/// `reportData` (timings, frame statistics) to build/integration_response_data.json.
Future<void> main() => integrationDriver();
