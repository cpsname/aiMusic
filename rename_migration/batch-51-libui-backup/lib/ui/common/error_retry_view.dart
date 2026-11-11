import 'package:flutter/material.dart';
import 'package:infra_core/infra_core.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import 'failure_copy.dart';

/// Localized title/message/icon for a [Failure], used by [ErrorRetryView].
/// Thin adapter over the shared resolvers in `failure_copy.dart` so the card,
/// the snackbar, and inline text all present a failure identically.
///
/// [genericTitle] overrides the generic headline for non-network failures only
/// (a network failure always keeps its connectivity-aware title).
({String title, String message, IconData icon}) describeFailure(
  AppLocalizations l10n,
  Failure failure, {
  String? genericTitle,
}) => (
  title: failureTitle(l10n, failure, genericTitle: genericTitle),
  message: failureMessageText(l10n, failure),
  icon: failureIcon(failure),
);

/// The single reusable "error + retry" surface. Maps a sealed [Failure] to
/// localized copy and renders it through [StatusView]. Used by the startup gate
/// and by every business screen's `AsyncValue` error branch — replacing the
/// previously duplicated bespoke error cards.
///
/// [fullScreen] true (the default) stretches the card/button for a screen-filling
/// state (startup, first-load failures); false renders a compact, content-sized
/// card for page-level errors. Pass [title] to override the generic headline
/// with a screen-specific one (e.g. "Couldn't load products") — it applies to
/// non-network failures only; a network failure keeps its "Connection problem"
/// headline so the title, icon, and body always agree. Set [retrying] while a
/// retry is in flight to disable the button and show a spinner.
///
/// A failure whose [Failure.isRetryable] is false (a `ConfigFailure`: the build
/// itself is missing its `--dart-define` config) renders with **no action at
/// all** — offering a retry that provably cannot succeed is worse than
/// offering nothing.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.title,
    this.fullScreen = true,
    this.retrying = false,
  });

  final Failure failure;
  final VoidCallback onRetry;
  final String? title;
  final bool fullScreen;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final described = describeFailure(l10n, failure, genericTitle: title);
    final canRetry = failure.isRetryable;
    return StatusView(
      title: described.title,
      message: described.message,
      icon: described.icon,
      // StatusView renders no button when the label is null.
      actionLabel: canRetry ? l10n.commonRetry : null,
      onAction: canRetry && !retrying ? onRetry : null,
      loading: retrying,
      expand: fullScreen,
    );
  }
}
