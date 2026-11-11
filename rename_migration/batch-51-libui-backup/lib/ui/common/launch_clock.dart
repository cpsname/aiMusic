import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

/// When the app process started (set in `main`), for the "open → first
/// listen" timing (PRD §12.1, target ≤ 90 s).
final launchedAtProvider = Provider<DateTime>((ref) => DateTime.now());

/// Records the first preview listen of this launch once.
final firstListenRecorderProvider = Provider<void Function()>((ref) {
  var recorded = false;
  return () {
    if (recorded) return;
    recorded = true;
    final elapsed = DateTime.now().difference(ref.read(launchedAtProvider));
    ref
        .read(telemetrySinkProvider)
        .logEvent(
          'first_listen',
          properties: {'ms_since_launch': elapsed.inMilliseconds},
        );
  };
});
