import 'package:app_config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Maintenance value equality + hashCode', () {
    const a = Maintenance(active: true, message: 'm');
    const b = Maintenance(active: true, message: 'm');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const Maintenance(active: false, message: 'm')));
    expect(a, isNot(const Maintenance(active: true, message: 'n')));
    expect(
      a,
      isNot(Maintenance(active: true, message: 'm', resumeAt: DateTime.utc(2026))),
    );
  });

  test('AppConfig value equality is deep over killSwitches + config', () {
    const a = AppConfig(
      maintenance: Maintenance.inactive,
      killSwitches: ['x'],
      config: {'k': 1, 'nested': {'a': 1}},
    );
    const b = AppConfig(
      maintenance: Maintenance.inactive,
      killSwitches: ['x'],
      config: {'k': 1, 'nested': {'a': 1}},
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);

    expect(
      a,
      isNot(const AppConfig(
        maintenance: Maintenance.inactive,
        killSwitches: ['y'],
        config: {'k': 1, 'nested': {'a': 1}},
      )),
    );
    expect(
      a,
      isNot(const AppConfig(
        maintenance: Maintenance.inactive,
        killSwitches: ['x'],
        config: {'k': 1, 'nested': {'a': 2}},
      )),
    );
    expect(a, isNot(AppConfig.safeDefault));
  });
}
