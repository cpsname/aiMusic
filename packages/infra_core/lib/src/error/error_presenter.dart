import 'package:flutter/material.dart';

import 'failure.dart';

/// Surfaces a [Failure] to the user as a SnackBar.
///
/// Infra-level: it deliberately does **not** import the app's localizations.
/// The backend already returns localized messages (it honours `X-Language`), so
/// [Failure.message] is shown by default; callers may inject a
/// [localizedMessage]/[retryLabel] for app-specific copy.
///
/// Prefer the unified ui_kit Message component (drive `messageControllerProvider`,
/// map failures via `failureMessage`): it renders above any screen via an
/// app-root host, supports loading→error transitions, and never silently drops a
/// message when no `ScaffoldMessenger` is in scope. This SnackBar presenter is
/// kept as a fallback for non-ui_kit / infra-only contexts.
@Deprecated('Use the ui_kit Message component (messageControllerProvider + failureMessage).')
abstract final class GlobalErrorPresenter {
  static void show(
    BuildContext context,
    Failure failure, {
    String? localizedMessage,
    String? fallbackMessage,
    String retryLabel = 'Retry',
    VoidCallback? onRetry,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final resolved = localizedMessage ??
        (failure.message.isNotEmpty
            ? failure.message
            : (fallbackMessage ?? 'Something went wrong'));

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(resolved),
          behavior: SnackBarBehavior.floating,
          action: onRetry != null
              ? SnackBarAction(label: retryLabel, onPressed: onRetry)
              : null,
        ),
      );
  }
}
