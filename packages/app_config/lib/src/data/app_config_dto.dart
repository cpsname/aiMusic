import '../domain/app_config.dart';
import 'json_coerce.dart';

/// Parses the `GET /app/config` payload into the domain [AppConfig]. Fully
/// defensive: any missing or ill-typed field degrades to that field's safe
/// default (never throws), matching the contract's fail-open posture.
abstract final class AppConfigDto {
  static AppConfig fromJson(Map<String, Object?> json) => AppConfig(
        maintenance: _maintenance(json['maintenance']),
        killSwitches: _killSwitches(json['kill_switches']),
        config: asMap(json['config']),
      );

  static Maintenance _maintenance(Object? raw) {
    if (raw is! Map) return Maintenance.inactive;
    final map = asMap(raw);
    return Maintenance(
      active: asBool(map['active']),
      message: asString(map['message']),
      resumeAt: _epochMillis(map['resume_at']),
    );
  }

  static List<String> _killSwitches(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw
        .whereType<String>()
        .where((code) => code.isNotEmpty)
        .toList(growable: false);
  }

  /// `resume_at` is Unix **milliseconds** UTC; a missing/non-positive/non-int
  /// value → null.
  static DateTime? _epochMillis(Object? raw) {
    if (raw is int && raw > 0) {
      return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
    }
    return null;
  }
}
