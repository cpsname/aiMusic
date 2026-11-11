import 'app_config.dart';

/// Domain contract for fetching the runtime app-governance config. The concrete
/// implementation (data layer) is bound in the composition root
/// (`app_config_providers.dart`).
abstract interface class AppConfigRepository {
  /// Fetches the current [AppConfig]. Throws on transport failure — the
  /// application layer applies the fail-open policy (retain last good / safe
  /// default), never the caller.
  Future<AppConfig> fetch();
}
