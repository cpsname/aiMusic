/// app_config — runtime app governance (maintenance gate / feature
/// kill-switches / remote parameters) sourced from `GET /app/config`.
///
/// A bounded context **separate** from the startup `app/init` snapshot: this
/// contract is runtime-mutable and fail-open. Consumers import
/// `package:app_config/app_config.dart`.
library;

export 'src/application/app_config_controller.dart';
export 'src/application/app_config_providers.dart';
export 'src/domain/app_config.dart';
export 'src/domain/app_config_repository.dart';
