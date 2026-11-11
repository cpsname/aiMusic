import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/music_brand.dart';
import '../common/music_error_retry_view.dart';
import '../common/music_external_links.dart';
import '../common/music_messages.dart';

/// Gates the app on startup — Songlet variant of the template gate.
///
/// The local library must work offline (PRD §6.5 `NETWORK_OFFLINE`: "仅作品库
/// 可用"), so only the **local** prerequisites (preferences) hold the splash.
/// `StartupController.start()` (device identity, storage migration, App Attest,
/// the catalog, the entitlement prefetch) runs behind the shell; a network or
/// attestation failure there degrades to a non-blocking message and is retried
/// on the next foreground. Only a broken build (`ConfigFailure`) and a forced
/// update block the app.
class MusicStartupGate extends ConsumerStatefulWidget {
  const MusicStartupGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MusicStartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<MusicStartupGate> {
  late final AppLifecycleListener _lifecycle;
  bool _activated = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _start() => ref.read(startupControllerProvider.notifier).start();

  void _onResume() {
    final state = ref.read(startupControllerProvider);
    if (state is StartupFailed && state.failure.isRetryable) _start();
    // Videos whose polling stopped while the app was suspended are polled
    // again (ADR-0025); the runner skips those still running.
    if (_videosResumed) ref.invalidate(musicVideosProvider);
  }

  /// Once the network half is ready: resume the videos left being made and a
  /// video whose pack purchase the app was closed during (PRD §15.4).
  bool _videosResumed = false;

  void _resumeVideos() {
    if (_videosResumed) return;
    _videosResumed = true;
    ref.read(musicVideosProvider);
    unawaited(ref.read(mvControllerProvider.notifier).resumeIntent());
  }

  /// Once preferences are loaded: register the native bridge's Flutter-side
  /// handlers (StoreKit `Transaction.updates`, playback progress) and start the
  /// app-lifetime transaction reconciler — before, and independently of, the
  /// network half of startup.
  void _activateLocal() {
    if (_activated) return;
    _activated = true;
    ref
      ..read(nativeBridgeProvider)
      ..read(iapReconcilerProvider)
      // The video the length panel asked for, made once its song is ready
      // (ADR-0022); it also finishes a free lyric video left from last time.
      ..read(autoVideoCoordinatorProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen<StartupState>(startupControllerProvider, (previous, next) {
      final messages = ref.read(messageControllerProvider);
      if (next is StartupFailed && next.failure is! ConfigFailure) {
        messages.show(
          failureMessage(l10n, next.failure, onRetry: _start),
          tag: 'startup',
        );
      } else if (next is StartupReady) {
        messages.dismissTag('startup');
        _resumeVideos();
      }
    });

    final prefs = ref.watch(sharedPreferencesProvider);
    final state = ref.watch(startupControllerProvider);

    final Widget? blocking = switch (state) {
      StartupFailed(:final failure) when failure is ConfigFailure =>
        MusicErrorRetryView(failure: failure, onRetry: _start),
      StartupForceUpdate(:final update) => _ForceUpdateView(
        update: update,
        onUpdate: _start,
      ),
      _ => null,
    };
    if (blocking == null && prefs.hasValue) {
      _activateLocal();
      return widget.child;
    }
    return Scaffold(
      body: SafeArea(child: blocking ?? const Center(child: _SplashView())),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SongletMark(size: SongletSize.playButton + SongletSpace.x2),
        const SizedBox(height: SongletSpace.x4),
        Text(MusicSongletBrand.name, style: theme.textTheme.headlineMedium),
        const SizedBox(height: SongletSpace.x6),
        const SizedBox.square(
          dimension: SongletSize.iconLg,
          child: CircularProgressIndicator(strokeWidth: SongletSize.focusRing),
        ),
        const SizedBox(height: SongletSpace.x4),
        Text(l10n.startupLoading, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _ForceUpdateView extends StatelessWidget {
  const _ForceUpdateView({required this.update, required this.onUpdate});

  final UpdateInfo update;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final url = update.updateUrl;
    return StatusView(
      title: l10n.updateRequiredTitle,
      message: update.releaseNotes ?? l10n.updateRequiredMessage,
      actionLabel: l10n.updateNow,
      onAction: () {
        if (url != null && url.isNotEmpty) {
          openExternalUrl(context, url, errorMessage: l10n.commonLinkError);
        } else {
          onUpdate();
        }
      },
    );
  }
}
