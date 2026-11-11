import 'dart:async';
import 'dart:math' as math;

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infra_core/infra_core.dart';
import 'package:intl/intl.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/brand.dart';
import '../common/error_retry_view.dart';
import '../common/localized_formats.dart';
import '../common/messages.dart';
import '../common/page_layout.dart';
import '../common/test_id.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';
import 'create_labels.dart';

/// P05 / P06 — waiting for Lyria (PRD §3.1: a clip in ≤ 45 s): progress,
/// queue position, a lyric glimpse and Cancel (ADR-0012). Follows the app's
/// one [GenerationController]; failures map to the §6.5 copy and
/// `QUOTA_EXHAUSTED` opens the paywall.
class GeneratingPage extends ConsumerStatefulWidget {
  const GeneratingPage({super.key});

  @override
  ConsumerState<GeneratingPage> createState() => _GeneratingPageState();
}

class _GeneratingPageState extends ConsumerState<GeneratingPage> {
  /// Redraws the ETA-driven progress between polls.
  static const Duration tick = Duration(seconds: 1);

  /// Progress never shows complete before the audio is actually ready.
  static const double estimateCeiling = 0.95;

  Timer? _ticker;
  bool _paywallShown = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(tick, (_) {
      if (mounted) setState(() {});
    });
    // The server may refuse before this page is up (a fast QUOTA_EXHAUSTED):
    // the paywall it asks for opens all the same.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _offerPaywall(ref.read(generationControllerProvider));
    });
  }

  /// Opens the paywall once for a run the server refused for credits.
  void _offerPaywall(MusicGenerationState state) {
    if (state is GenerationFailed &&
        MusicErrorCode.of(state.failure) == MusicErrorCode.quotaExhausted &&
        !_paywallShown) {
      _paywallShown = true;
      _openPaywall(state);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _retry(GenerationFailed failed) async {
    final draft = failed.draft;
    if (draft == null) return;
    unawaited(
      ref
          .read(generationControllerProvider.notifier)
          .generate(draft, model: failed.model),
    );
  }

  /// Leaves a failed or refused run for the create home, the draft kept so
  /// it can be fixed (the page is reached with `go`: there is no back stack).
  void _backToEdit() {
    ref.read(generationControllerProvider.notifier).reset();
    context.goTo(const CreateRoute());
  }

  Future<void> _openPaywall(GenerationFailed failed) async {
    // The page the server asked for: plans or credit packs, with the pack it
    // recommends preselected (contract 02 v2.1; no detail = the plans).
    final gap = QuotaGap.of(failed.failure);
    final bought = await context.openPaywall(
      PaywallReason.quota,
      productId: gap?.recommendedProductId,
      offer: QuotaOffer.of(failed.failure),
    );
    if (!mounted) return;
    // Re-read the ledger whatever the sheet returned: a purchase can land
    // outside it (approved later, granted by the server, a renewal). Once the
    // ledger covers what was refused, the song is made all the same.
    ref
      ..invalidate(walletSnapshotProvider)
      ..invalidate(musicEntitlementProvider);
    final covered = bought || await _ledgerCovers(failed);
    if (covered && mounted) await _retry(failed);
  }

  /// Whether the re-read ledger now has what [failed] was refused for.
  Future<bool> _ledgerCovers(GenerationFailed failed) async {
    try {
      final ledger = await ref.read(musicEntitlementProvider.future);
      final model = failed.model ?? failed.draft?.model;
      return model == SongModel.fullSong
          ? ledger.canMakeSong
          : ledger.canMakeClip;
    } on Object {
      // The ledger cannot be read now: the failure view keeps its way to
      // the paywall and to retry.
      return false;
    }
  }

  Future<void> _cancel(GenerationWaiting waiting) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.generatingCancelTitle),
        content: Text(
          waiting.status == JobStatus.queued
              ? l10n.generatingCancelQueued
              : l10n.generatingCancelStarted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonKeepGoing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.generatingCancelConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messages = ref.read(messageControllerProvider);
    try {
      final refunded = await ref
          .read(generationControllerProvider.notifier)
          .cancel();
      if (!mounted || refunded == null) return;
      messages.info(
        refunded ? l10n.generatingCancelledRefunded : l10n.generatingCancelled,
      );
      context.goTo(const CreateRoute());
    } on Object catch (error, stackTrace) {
      final failure = ref.read(errorHandlerProvider).handle(error, stackTrace);
      // Lost the race to completion: not an error — the song is on its way
      // and polling opens it.
      if (MusicErrorCode.of(failure) == MusicErrorCode.jobAlreadyFinished) {
        messages.info(l10n.errorJobAlreadyFinished);
      } else {
        messages.show(failureMessage(l10n, failure));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(generationControllerProvider);
    ref.listen<MusicGenerationState>(generationControllerProvider, (previous, next) {
      if (next is GenerationSucceeded) {
        ref.read(generationControllerProvider.notifier).reset();
        ref
            .read(creationDraftProvider.notifier)
            .update((d) => d.copyWith(photos: const [], imageBids: const []));
        context.goTo(playerRouteFor(next.work));
      } else if (next is GenerationFailed) {
        _offerPaywall(next);
      } else if (next is GenerationRejected && context.canPop()) {
        context.pop();
      }
    });

    final Widget body = switch (state) {
      GenerationIdle() || GenerationSucceeded() => _Nothing(
        onCreate: () => context.goTo(const CreateRoute()),
      ),
      GenerationFailed() => _FailureView(
        failed: state,
        onRetry: () => _retry(state),
        onPaywall: () => _openPaywall(state),
        onBack: _backToEdit,
      ),
      GenerationRejected(:final issues) => TestId(
        'generating.rejected',
        child: StatusView(
          title: preflightIssueText(l10n, issues.first),
          message: issues.length > 1
              ? issues
                    .skip(1)
                    .map((i) => preflightIssueText(l10n, i))
                    .join('\n')
              : null,
          icon: Icons.edit_note_rounded,
          actionLabel: l10n.generatingBackToEdit,
          onAction: _backToEdit,
          expand: false,
        ),
      ),
      GenerationPreparing() || GenerationWaiting() => _Progress(
        state: state,
        progress: _progress(state),
        onCancel: state is GenerationWaiting && !state.cancelling
            ? () => _cancel(state)
            : null,
      ),
    };

    return PopScope(
      canPop: !state.isBusy,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: SongletSize.contentMaxWidth,
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }

  /// Server progress when reported, else elapsed ÷ ETA, capped below 100 %.
  double _progress(MusicGenerationState state) => switch (state) {
    GenerationWaiting(:final progress, :final startedAt, :final etaSeconds) =>
      progress ??
          math.min(
            estimateCeiling,
            DateTime.now().difference(startedAt).inMilliseconds /
                math.max(1, etaSeconds * Duration.millisecondsPerSecond),
          ),
    _ => 0,
  };
}

class _Progress extends ConsumerWidget {
  const _Progress({
    required this.state,
    required this.progress,
    required this.onCancel,
  });

  final MusicGenerationState state;
  final double progress;
  final VoidCallback? onCancel;

  /// Upper bound of the queue wait caption, in minutes (keeps it two digits).
  static const int _maxWaitMinutes = 99;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final waiting = state is GenerationWaiting
        ? state as GenerationWaiting
        : null;
    final work = waiting == null
        ? null
        : ref.watch(workByIdProvider(waiting.workId));
    final draft = ref.watch(creationDraftProvider).draft;
    final recipient = work?.recipient ?? draft?.recipient ?? '';
    final meta = [
      if ((work?.genre ?? draft?.genre ?? '').isNotEmpty)
        genreName(l10n, work?.genre ?? draft!.genre!),
      if (draft != null) languageName(l10n, draft.lyricLanguage),
      if (work != null || draft != null)
        workKindName(
          l10n,
          template: work?.template ?? draft?.template,
          occasion: work?.occasion ?? draft!.occasion,
        ),
    ];
    final hint = MusicErrorCode.fromWire(waiting?.hint);
    final subtitle = switch (state) {
      GenerationPreparing(:final step) => switch (step) {
        PreparingStep.checking ||
        PreparingStep.polishing => l10n.generatingStepPolishing,
        PreparingStep.uploadingPhotos => l10n.generatingStepUploading,
        PreparingStep.submitting => l10n.generatingStepSubmitting,
      },
      _ when hint == MusicErrorCode.upstreamTimeout =>
        l10n.errorUpstreamTimeout,
      _ => l10n.generatingUsually(waiting?.etaSeconds ?? 0),
    };
    final percent = progressPercent(progress, l10n.localeName);
    final gutter = pageGutter(context);
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        gutter,
        SongletSpace.x3,
        gutter,
        SongletSpace.x8,
      ),
      children: [
        BrandHeader(title: SongletBrand.name, tagline: l10n.appTagline),
        const SizedBox(height: SongletSpace.x4),
        if (waiting != null &&
            (waiting.isQueued || hint == MusicErrorCode.upstreamRateLimited))
          TestId(
            'generating.queue',
            child: QueueBanner(
              title: l10n.queueTitle,
              subtitle: l10n.queueSubtitle,
              positionLabel: l10n.queuePosition,
              position: waiting.queuePosition == null
                  ? null
                  : NumberFormat.decimalPattern(
                      l10n.localeName,
                    ).format(waiting.queuePosition),
              waitLabel: l10n.queueWait,
              waitValue: l10n.queueWaitMinutes(
                ((waiting.remainingSeconds ?? waiting.etaSeconds) /
                        Duration.secondsPerMinute)
                    .ceil()
                    .clamp(1, _maxWaitMinutes),
              ),
            ),
          ),
        Center(
          child: PulsingMark(
            label: recipient.isEmpty
                ? l10n.generatingTitleGeneric
                : l10n.generatingTitleFor(recipient),
          ),
        ),
        TestId(
          'generating.progress',
          child: Text(
            recipient.isEmpty
                ? l10n.generatingTitleGeneric
                : l10n.generatingTitleFor(recipient),
            textAlign: TextAlign.center,
            style: SongletType.title1.copyWith(color: c.ink),
          ),
        ),
        const SizedBox(height: SongletSpace.x2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: SongletType.body.copyWith(color: c.inkSecondary),
        ),
        const SizedBox(height: SongletSpace.x5),
        ProgressMeter(
          value: progress,
          percentLabel: waiting == null
              ? null
              : l10n.generatingPercent(percent),
          semanticsLabel: l10n.generatingProgress,
        ),
        const SizedBox(height: SongletSpace.x4),
        MetaLine(parts: meta),
        const SizedBox(height: SongletSpace.x2),
        if (onCancel != null || waiting?.cancelling == true)
          Center(
            child: TestId(
              'generating.cancel',
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: c.accent),
                child: Text(l10n.commonCancel),
              ),
            ),
          ),
        const SizedBox(height: SongletSpace.x4),
        if (!(work?.isInstrumental ?? draft?.vocals == Vocals.instrumental))
          GlimpseCard(
            title: l10n.generatingGlimpse,
            lines: waiting?.lyricsPreview ?? const [],
          ),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({
    required this.failed,
    required this.onRetry,
    required this.onPaywall,
    required this.onBack,
  });

  final GenerationFailed failed;
  final VoidCallback onRetry;
  final VoidCallback onPaywall;

  /// Back to the create home with the draft kept.
  final VoidCallback onBack;

  /// The server refused what was written (contract 02 v2.1 §2.7: 40001 with
  /// `details.prompt` / `details.prompt.description`): the fix is in the
  /// draft, so its copy, and no retry.
  static String? _promptIssue(AppLocalizations l10n, Failure failure) {
    if (failure is! ValidationFailure) return null;
    final details = failure.details;
    if (details.containsKey('prompt.description'))
      return l10n.issueDescriptionMissing;
    if (details.containsKey('prompt')) return l10n.issueBriefMissing;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = failed.failure;
    final code = MusicErrorCode.of(failure);
    final back = TestId(
      'generating.back',
      child: TextButton(
        onPressed: onBack,
        child: Text(l10n.generatingBackToEdit),
      ),
    );
    if (code == MusicErrorCode.quotaExhausted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TestId(
            'generating.quota',
            child: StatusView(
              title: l10n.paywallTitle,
              message: l10n.errorQuotaExhausted,
              icon: Icons.music_note_rounded,
              accentColor: SongletColors.of(context).accent,
              actionLabel: l10n.paywallSeePlans,
              onAction: onPaywall,
              expand: false,
            ),
          ),
          back,
        ],
      );
    }
    final promptIssue = _promptIssue(l10n, failure);
    if (promptIssue != null) {
      return TestId(
        'generating.failure',
        child: StatusView(
          title: promptIssue,
          icon: Icons.edit_note_rounded,
          actionLabel: l10n.generatingBackToEdit,
          onAction: onBack,
          expand: false,
        ),
      );
    }
    // Blocked (attestation) and still-running jobs (they finish in the
    // library) offer no retry — the action could not change the outcome.
    final retryable =
        !(code?.blocksGeneration ?? false) &&
        failed.workId == null &&
        failed.draft != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TestId(
          'generating.failure',
          child: retryable
              ? ErrorRetryView(
                  failure: failure,
                  onRetry: onRetry,
                  fullScreen: false,
                )
              : _Described(failure: failure),
        ),
        back,
      ],
    );
  }
}

class _Described extends StatelessWidget {
  const _Described({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final described = describeFailure(AppLocalizations.of(context), failure);
    return StatusView(
      title: described.title,
      message: described.message,
      icon: described.icon,
      expand: false,
    );
  }
}

class _Nothing extends StatelessWidget {
  const _Nothing({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: EmptyState(
        icon: Icons.music_note_outlined,
        title: l10n.generatingNothing,
        message: l10n.composerHint,
        actionLabel: l10n.navCreate,
        onAction: onCreate,
      ),
    );
  }
}
