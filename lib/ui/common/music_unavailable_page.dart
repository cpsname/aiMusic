import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../routing/music_navigation.dart';
import '../routing/music_routes.dart';
import 'music_test_id.dart';

/// P17 — "Temporarily unavailable" (ADR-0009): shown for app-wide kill
/// switches and repeated upstream failures; the library keeps working.
class MusicUnavailablePage extends StatelessWidget {
  const MusicUnavailablePage({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        // Centred when it fits; scrolls at large Dynamic Type sizes.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: MusicTestId(
                  'unavailable',
                  child: MusicUnavailableView(
                    onRetry: onRetry ?? () => context.goTo(const MusicCreateRoute()),
                    onLibrary: () => context.goTo(const MusicLibraryRoute()),
                    title: l10n.unavailableTitle,
                    message: l10n.unavailableMessage,
                    retryLabel: l10n.commonRetry,
                    libraryLabel: l10n.navLibrary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The P17 state, reusable in place inside a page.
class MusicUnavailableView extends StatelessWidget {
  const MusicUnavailableView({
    super.key,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.libraryLabel,
    this.onLibrary,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String? libraryLabel;
  final VoidCallback? onLibrary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyState(
          icon: Icons.cloud_off_rounded,
          title: title,
          message: message,
          actionLabel: retryLabel,
          onAction: onRetry,
        ),
        if (libraryLabel != null && onLibrary != null)
          TextButton(onPressed: onLibrary, child: Text(libraryLabel!)),
      ],
    );
  }
}
