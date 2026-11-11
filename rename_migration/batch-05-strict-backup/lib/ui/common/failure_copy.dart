import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../../l10n/generated/app_localizations.dart';

/// The single source of truth for turning a sealed [Failure] into user-facing
/// copy, shared by every error surface: the full/page [ErrorRetryView] card
/// (via `describeFailure`), the snackbar stack (`failureMessage`), and inline
/// text (the sign-in sheet). Centralizing title/message/icon selection here
/// stops the surfaces from drifting — e.g. one showing the offline copy while
/// another shows a generic network error for the same fault.
///
/// [Failure.message] is surfaced only when the backend supplied it (already
/// localized via `X-Language`); transport/diagnostic failures carry an empty
/// message (see `ErrorHandler`) and resolve to the localized generics below.

/// PRD §6.5 copy for a Songlet error code — the table's English lines,
/// localized through the ARBs. Checked before the generic mapping so every
/// surface shows the contract copy for the same code.
String songletErrorText(AppLocalizations l10n, MusicErrorCode code) =>
    switch (code.presentedAs) {
      MusicErrorCode.safetyBlocked => l10n.errorSafetyBlocked,
      MusicErrorCode.quotaExhausted => l10n.errorQuotaExhausted,
      MusicErrorCode.upstreamRateLimited => l10n.errorUpstreamRateLimited,
      MusicErrorCode.upstreamTimeout ||
      MusicErrorCode.regionUnavailable => l10n.errorUpstreamTimeout,
      MusicErrorCode.attestFailed => l10n.errorAttestFailed,
      MusicErrorCode.imageRejected => l10n.errorImageRejected,
      MusicErrorCode.networkOffline => l10n.errorNetworkOffline,
      MusicErrorCode.downloadLocked => l10n.errorDownloadLocked,
      MusicErrorCode.jobAlreadyFinished => l10n.errorJobAlreadyFinished,
      // Music videos (contract v1.1 §4 / platform 04 §2).
      MusicErrorCode.mvSongNotReady => l10n.errorMvSongNotReady,
      MusicErrorCode.mvSongTooLong => l10n.errorMvSongTooLong,
      MusicErrorCode.mvSongExpired => l10n.errorMvSongExpired,
      MusicErrorCode.mvNotFound => l10n.errorMvNotFound,
      MusicErrorCode.mvPhotosExpired => l10n.errorMvPhotosExpired,
      MusicErrorCode.mvRenderFailed => l10n.errorMvRenderFailed,
      // A user cancel is reported by the flow that asked for it, never as an
      // error card; the stopped-video copy stands in if it ever surfaces.
      MusicErrorCode.userCancelled => l10n.mvCancelled,
    };

/// Leading glyph for a failure on card/status surfaces.
IconData failureIcon(Failure failure) =>
    switch (MusicErrorCode.of(failure)?.presentedAs) {
      MusicErrorCode.quotaExhausted => Icons.music_off_rounded,
      MusicErrorCode.upstreamTimeout ||
      MusicErrorCode.upstreamRateLimited => Icons.hourglass_top_rounded,
      MusicErrorCode.safetyBlocked ||
      MusicErrorCode.imageRejected => Icons.edit_note_rounded,
      MusicErrorCode.downloadLocked => Icons.lock_outline_rounded,
      MusicErrorCode.mvRenderFailed ||
      MusicErrorCode.mvSongNotReady ||
      MusicErrorCode.mvSongTooLong => Icons.movie_creation_outlined,
      MusicErrorCode.mvSongExpired ||
      MusicErrorCode.mvNotFound => Icons.history_toggle_off_rounded,
      MusicErrorCode.mvPhotosExpired => Icons.photo_library_outlined,
      _ => _genericIcon(failure),
    };

IconData _genericIcon(Failure failure) => switch (failure) {
  NetworkFailure(:final kind) =>
    kind == NetworkFailureKind.offline
        ? Icons.wifi_off_rounded
        : Icons.cloud_off_rounded,
  ConfigFailure() => Icons.settings_suggest_rounded,
  _ => Icons.error_outline_rounded,
};

/// Headline for a failure on card/status surfaces. [genericTitle] overrides the
/// default generic headline (e.g. a screen-specific "Couldn't load products")
/// but never the connectivity-aware network title.
String failureTitle(
  AppLocalizations l10n,
  Failure failure, {
  String? genericTitle,
}) => switch (failure) {
  NetworkFailure() => l10n.networkErrorTitle,
  // Never overridden by a screen-specific headline: the app is not up, so
  // "Couldn't load products" would name the wrong problem.
  ConfigFailure() => l10n.configErrorTitle,
  _ => genericTitle ?? l10n.commonErrorTitle,
};

/// User-facing body message. Network failures use connectivity-aware copy keyed
/// off [NetworkFailureKind]; other failures prefer the (localized) backend
/// message, else the caller's [genericFallback], else the generic sentence.
String failureMessageText(
  AppLocalizations l10n,
  Failure failure, {
  String? genericFallback,
}) {
  final code = MusicErrorCode.of(failure);
  if (code != null) return songletErrorText(l10n, code);
  return _genericMessage(l10n, failure, genericFallback);
}

String _genericMessage(
  AppLocalizations l10n,
  Failure failure,
  String? genericFallback,
) => switch (failure) {
  NetworkFailure(:final kind) =>
    kind == NetworkFailureKind.offline
        ? l10n.commonOfflineError
        : l10n.commonNetworkError,
  AuthFailure() =>
    failure.message.isNotEmpty ? failure.message : l10n.commonAuthError,
  // Users get the plain sentence; developers get the actual missing keys
  // and the command that injects them — this only ever fires on a build
  // that was made wrong, so the fix belongs on screen in debug.
  ConfigFailure(:final missingKeys) =>
    kDebugMode
        ? '${l10n.configErrorMessage}\n\nmissing: ${missingKeys.join(', ')}'
              '\nrun `make run` (or `make xcconfig` before an Xcode Archive)'
        : l10n.configErrorMessage,
  _ =>
    failure.message.isNotEmpty
        ? failure.message
        : (genericFallback ?? l10n.commonError),
};
