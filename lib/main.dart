import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';

import 'l10n/music_ui_locale.dart';
import 'ui/common/music_launch_clock.dart';
import 'ui/music_app.dart';

void main() {
  // "Open → first listen" is timed from here (PRD §12.1).
  final launchedAt = DateTime.now();

  // Telemetry: a console sample adapter in dev/staging, a no-op in release.
  // Songlet ships no third-party analytics or ads SDK (PRD §6.2 / §9.3); the
  // `RedactingTelemetrySink` wrapper keeps PII out of any sink.
  final TelemetrySink telemetry = RedactingTelemetrySink(
    kReleaseMode ? const NoopTelemetrySink() : const ConsoleTelemetrySink(),
  );

  bootstrap(() {
    runApp(
      ProviderScope(
        // Errors are terminal so the explicit error+retry screens show reliably;
        // transient HTTP faults are already retried in the network layer.
        retry: (_, _) => null,
        overrides: [
          languageTagProvider.overrideWith(
            (ref) => ref.watch(uiLocaleProvider).toLanguageTag(),
          ),
          telemetrySinkProvider.overrideWithValue(telemetry),
          launchedAtProvider.overrideWithValue(launchedAt),
          // Binds commerce_kit (auth / IAP / wallet) to Songlet's StoreKit 2
          // bridge, App Attest identity and entitlement ledger.
          ...songletKitOverrides(),
        ],
        child: const MusicApp(),
      ),
    );
  }, telemetry: telemetry);
}
