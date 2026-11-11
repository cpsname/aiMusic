import 'package:app_config/src/data/app_config_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a full payload', () {
    final config = AppConfigDto.fromJson({
      'maintenance': {
        'active': true,
        'message': 'down',
        'resume_at': 1781755280613,
      },
      'kill_switches': ['a', 'b'],
      'config': {'k': 1, 'flag': true, 'promo_text': 'hi'},
    });

    expect(config.maintenance.active, isTrue);
    expect(config.maintenance.message, 'down');
    expect(
      config.maintenance.resumeAt,
      DateTime.fromMillisecondsSinceEpoch(1781755280613, isUtc: true),
    );
    expect(config.killSwitches, ['a', 'b']);
    expect(config.isKilled('a'), isTrue);
    expect(config.isKilled('z'), isFalse);
    expect(config.configValue<int>('k', 0), 1);
    expect(config.configValue<bool>('flag', false), isTrue);
    expect(config.configValue<String>('promo_text', ''), 'hi');
    expect(config.configValue<String>('missing', 'x'), 'x');
  });

  test('an empty/absent payload degrades to safe defaults', () {
    final config = AppConfigDto.fromJson({});
    expect(config.maintenance.active, isFalse);
    expect(config.maintenance.message, '');
    expect(config.maintenance.resumeAt, isNull);
    expect(config.killSwitches, isEmpty);
    expect(config.config, isEmpty);
  });

  test('resume_at: null / non-int / non-positive → null', () {
    DateTime? parse(Object? v) => AppConfigDto.fromJson({
          'maintenance': {'active': true, 'resume_at': v},
        }).maintenance.resumeAt;
    expect(parse(null), isNull);
    expect(parse('soon'), isNull);
    expect(parse(0), isNull);
    expect(parse(-5), isNull);
  });

  test('kill_switches filters non-strings/empties; non-list → []', () {
    expect(
      AppConfigDto.fromJson({
        'kill_switches': ['a', 1, '', 'b', null],
      }).killSwitches,
      ['a', 'b'],
    );
    expect(AppConfigDto.fromJson({'kill_switches': 'nope'}).killSwitches,
        isEmpty);
  });

  test('ill-typed maintenance / config degrade to safe defaults', () {
    final config = AppConfigDto.fromJson({'maintenance': 'x', 'config': 'y'});
    expect(config.maintenance.active, isFalse);
    expect(config.config, isEmpty);
  });

  test('active maintenance with string-coerced "true" flag', () {
    final config = AppConfigDto.fromJson({
      'maintenance': {'active': 'true', 'message': 'm'},
    });
    expect(config.maintenance.active, isTrue);
  });
}
