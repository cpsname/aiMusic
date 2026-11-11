import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import 'failure_copy.dart';

/// App-wide message stack. [StudioApp] mounts a [MessageHost] over the whole app
/// (via MaterialApp.builder) bound to this controller; any screen drives it via
/// `ref.read(messageControllerProvider)`. ui_kit owns the visual + the
/// controller; this provider is the app's single binding point.
final messageControllerProvider = Provider<MessageController>((ref) {
  final controller = MessageController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Maps a sealed [Failure] to a localized error [MessageSpec]. Delegates copy
/// selection to the shared [failureMessageText] (backend message preferred,
/// connectivity-aware network copy, generic fallback) so the snackbar reads
/// identically to the [ErrorRetryView] card for the same failure; [fallback] is
/// the caller-specific generic (e.g. a purchase-specific line).
MessageSpec failureMessage(
  AppLocalizations l10n,
  Failure failure, {
  VoidCallback? onRetry,
  String? fallback,
}) {
  return MessageSpec(
    variant: MessageVariant.error,
    text: failureMessageText(l10n, failure, genericFallback: fallback),
    actionLabel: onRetry == null ? null : l10n.commonRetry,
    onAction: onRetry,
  );
}
