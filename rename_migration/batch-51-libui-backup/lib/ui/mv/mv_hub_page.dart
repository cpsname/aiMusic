import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/messages.dart';
import '../common/page_layout.dart';
import '../common/remote_flags.dart';
import '../common/test_id.dart';
import '../player/lyrics_model.dart';
import '../player/work_actions.dart';
import '../player/work_title.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';
import 'mv_labels.dart';
import 'mv_quota_sheet.dart';

/// P20 (compact) / P21 (regular, two panes) — the music-video hub of a
/// finished song (PRD §15.2, ADR-0027). The three levels with the platform's
/// prices (all three estimated on entry — estimating saves the song, and is
/// free), the options (format; quality as the platform offers it, ADR-0026;
/// lyrics on screen; the chorus window; up to 10 reference photos), then
/// Make video. A level already being made is not offered twice. Not enough
/// credits → the P22 sheet buys the recommended pack and the same request is
/// sent again (ADR-0023).
class MvHubPage extends ConsumerStatefulWidget {
  const MvHubPage({super.key, required this.workId, this.level, this.from});

  final String workId;

  /// Preselected level (the upgrade entry opens on the chorus video).
  final MusicMvLevel? level;

  /// An earlier video whose format, quality and chorus window prefill the
  /// options ("Make another", the retry of a failed video, the upgrade).
  final String? from;

  @override
  ConsumerState<MvHubPage> createState() => _MvHubPageState();
}

class _MvHubPageState extends ConsumerState<MvHubPage> {
  late MusicMvLevel _level = widget.level ?? MusicMvLevel.chorus;
  MusicMvAspectRatio _aspect = MusicMvAspectRatio.portrait;
  MusicMvQuality _quality = MusicMvQuality.standard;
  bool _subtitles = true;
  bool _customChorus = false;
  RangeValues? _chorus;
  final List<Uint8List> _photos = [];
  bool _picking = false;

  /// Between Make video and the platform's answer (ticket, gap or refusal).
  bool _submitting = false;
  bool _estimateRequested = false;
  bool _prefilled = false;

  /// Prices known for this song; kept while the controller moves on.
  Map<MusicMvLevel, MusicMvEstimate> _estimates = const {};

  /// The gap the sheet was shown for (once per refusal).
  MusicQuotaGap? _shownGap;

  MusicMvController get _controller => ref.read(mvControllerProvider.notifier);

  void _estimateAll(MusicWork work) {
    _estimateRequested = true;
    _controller.reset();
    unawaited(_controller.estimateAll(work, selected: _level));
  }

  void _prefill(MusicVideo? from) {
    if (_prefilled || from == null) return;
    _prefilled = true;
    _aspect = from.aspectRatio;
    _quality = from.quality;
    final chorus = from.chorus;
    if (chorus != null) {
      _customChorus = true;
      _chorus = RangeValues(chorus.startMs / 1000, chorus.endMs / 1000);
    }
  }

  void _pickLevel(MusicWork work, MusicMvLevel level) {
    if (level == _level) return;
    setState(() {
      _level = level;
      if (level != MusicMvLevel.chorus) _customChorus = false;
    });
    if (!_estimates.containsKey(level) &&
        !ref.read(mvControllerProvider).isBusy) {
      unawaited(_controller.estimate(work, level));
    }
  }

  Future<void> _pickPhotos() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await ref
          .read(photoSourceProvider)
          .pickPhotos(MusicMvRequest.maxPhotos - _photos.length);
      if (!mounted) return;
      setState(
        () => _photos.addAll(picked.take(MusicMvRequest.maxPhotos - _photos.length)),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  MusicMvSource _source() {
    final from = widget.from == null
        ? null
        : ref.read(musicVideoByIdProvider(widget.from!));
    return from != null &&
            from.level == MusicMvLevel.lyricVideo &&
            _level != MusicMvLevel.lyricVideo
        ? MusicMvSource.upgrade
        : MusicMvSource.library;
  }

  MusicMvRequest _request({required bool offersQuality}) => MusicMvRequest(
    level: _level,
    clientRef: newMvClientRef(),
    aspectRatio: _aspect,
    quality: offersQuality ? _quality : null,
    subtitles: _level == MusicMvLevel.lyricVideo ? null : _subtitles,
    chorus: _level == MusicMvLevel.chorus && _customChorus && _chorus != null
        ? MusicMvChorusWindow(
            startMs: (_chorus!.start * 1000).round(),
            endMs: (_chorus!.end * 1000).round(),
          )
        : null,
    source: _source(),
  );

  void _start(MusicWork work, {required bool offersQuality}) {
    if (_submitting) return;
    setState(() => _submitting = true);
    _controller.reset();
    unawaited(
      _controller.create(
        work,
        _request(offersQuality: offersQuality),
        photos: List.of(_photos),
      ),
    );
  }

  /// Asks the platform again at once (credits may have landed meanwhile);
  /// still short → the sheet again, with the platform's new gap.
  Future<void> _continueIntent(MusicWork work) async {
    setState(() => _submitting = true);
    await _controller.retryIntent(work, attemptDelays: const [Duration.zero]);
  }

  Future<void> _showQuota(MusicWork work, MusicMvQuotaGap gap) async {
    if (identical(_shownGap, gap.gap)) return;
    _shownGap = gap.gap;
    final bought = await showMvQuotaSheet(
      context,
      gap: gap.gap,
      level: gap.level,
    );
    if (!mounted) return;
    if (bought) {
      await _controller.retryIntent(work);
    } else {
      setState(() => _submitting = false);
    }
  }

  void _onState(MusicWork? work, MusicMvState? previous, MusicMvState next) {
    if (work == null) return;
    switch (next) {
      case MusicMvWaiting(:final workId, :final videoId)
          when workId == widget.workId && _submitting:
        _submitting = false;
        context.goTo(MvGenerateRoute(widget.workId, videoId));
      case MusicMvQuotaGap(:final workId)
          when workId == widget.workId && _submitting:
        unawaited(_showQuota(work, next));
      case MusicMvFailed(
            :final workId,
            :final request,
            :final videoId,
            :final failure,
          )
          when workId == widget.workId &&
              _submitting &&
              request != null &&
              videoId == null:
        setState(() => _submitting = false);
        _explain(work, failure);
      default:
        break;
    }
  }

  /// A refusal before the video existed: say why, and fix what can be fixed.
  void _explain(MusicWork work, Failure failure) {
    final l10n = AppLocalizations.of(context);
    final messages = ref.read(messageControllerProvider);
    switch (MusicErrorCode.of(failure)) {
      case MusicErrorCode.mvSongTooLong:
        setState(() => _level = MusicMvLevel.chorus);
        messages.show(failureMessage(l10n, failure));
      case MusicErrorCode.mvPhotosExpired:
        setState(_photos.clear);
        messages.show(failureMessage(l10n, failure));
      case MusicErrorCode.mvSongExpired:
        messages.show(
          MessageSpec(
            variant: MessageVariant.error,
            text: failureMessage(l10n, failure).text,
            actionLabel: l10n.mvSongExpiredAction,
            onAction: () => WorkActions(context, ref).anotherVersion(work),
          ),
        );
      default:
        messages.show(failureMessage(l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final work = ref.watch(workByIdProvider(widget.workId));
    ref.listen<MusicMvState>(
      mvControllerProvider,
      (previous, next) => _onState(work, previous, next),
    );
    if (work == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _prefill(
      widget.from == null
          ? null
          : ref.watch(musicVideoByIdProvider(widget.from!)),
    );
    if (!_estimateRequested) {
      _estimateRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _estimateAll(work);
      });
    }

    final state = ref.watch(mvControllerProvider);
    final estimating = state is MusicMvEstimating && state.workId == widget.workId;
    final estimateFailure =
        state is MusicMvFailed &&
            state.workId == widget.workId &&
            state.request == null
        ? state.failure
        : null;
    final preparing = state is MusicMvPreparing && state.workId == widget.workId
        ? state
        : null;
    final pending = {
      for (final v in ref.watch(musicVideosOfWorkProvider(widget.workId)))
        if (v.isPending) v.level: v,
    };
    final qualities = mvQualities(ref);
    final offersQuality = qualities.length > 1;
    if (!qualities.contains(_quality)) _quality = MusicMvQuality.standard;
    final intent = _submitting
        ? null
        : _controller.pendingIntent(widget.workId);
    // The controller's prices when it holds them, else the last ones seen.
    if (state is MusicMvEstimated && state.workId == widget.workId) {
      _estimates = state.estimates;
    }
    final estimate = _estimates[_level];
    final inFlight = pending[_level];

    final duration = workDuration(work);
    final chorusMax = duration <= 0 ? MusicMvChorusWindow.maxMs / 1000 : duration;
    final defaultChorus = RangeValues(
      (chorusMax * 0.35).clamp(0, chorusMax).toDouble(),
      (chorusMax * 0.35 + 30)
          .clamp(MusicMvChorusWindow.minMs / 1000, chorusMax)
          .toDouble(),
    );
    final chorus = _chorus ?? defaultChorus;
    final chorusSeconds = _customChorus
        ? (chorus.end - chorus.start).round()
        : MusicMvChorusWindow.defaultSeconds;

    String meta(MusicMvLevel level) => [
      switch (level) {
        MusicMvLevel.chorus => l10n.mvSeconds(chorusSeconds),
        _ => clockLabel(duration, l10n.localeName),
      },
      mvAspectName(l10n, _aspect),
    ].join(' · ');

    final Widget footer = inFlight != null
        ? TestId(
            'mv.create',
            child: ObsButton(
              label: l10n.mvViewProgress,
              icon: Icons.hourglass_top_rounded,
              onPressed: () =>
                  context.goTo(MvGenerateRoute(widget.workId, inFlight.id)),
            ),
          )
        : TestId(
            'mv.create',
            child: ObsButton(
              label: estimate != null && !estimate.affordable
                  ? l10n.mvBuyPack
                  : l10n.mvCreate,
              icon: estimate != null && !estimate.affordable
                  ? Icons.shopping_bag_outlined
                  : Icons.movie_creation_outlined,
              loading: estimating || _submitting || preparing != null,
              onPressed: estimate == null || _submitting
                  ? null
                  : () => _start(work, offersQuality: offersQuality),
            ),
          );

    final levels = <Widget>[
      Text(l10n.mvHubTitle, style: SongletType.title1.copyWith(color: c.ink)),
      const SizedBox(height: SongletSpace.x1),
      Text(
        l10n.mvHubSubtitle(workTitle(l10n, work)),
        style: SongletType.callout.copyWith(color: c.inkSecondary),
      ),
      const SizedBox(height: SongletSpace.x4),
      if (intent != null) ...[
        TestId(
          'mv.intent',
          child: NoteBanner(
            icon: Icons.add_card_outlined,
            message: l10n.mvIntentWaiting(
              mvLevelName(l10n, intent.request.level),
            ),
            linkLabel: l10n.commonContinue,
            onLink: () => _continueIntent(work),
          ),
        ),
        const SizedBox(height: SongletSpace.x4),
      ],
      if (estimateFailure != null) ...[
        TestId(
          'mv.price',
          child: InlineErrorBanner(
            message: failureMessage(l10n, estimateFailure).text,
            actionLabel: l10n.commonRetry,
            onAction: () => _estimateAll(work),
          ),
        ),
        const SizedBox(height: SongletSpace.x4),
      ],
      for (final level in MusicMvLevel.values) ...[
        const SizedBox(height: SongletSpace.x2),
        TestId(
          'mv.level.${level.wire}',
          child: MvLevelCard(
            icon: switch (level) {
              MusicMvLevel.lyricVideo => Icons.subtitles_outlined,
              MusicMvLevel.chorus => Icons.music_video_outlined,
              MusicMvLevel.full => Icons.movie_outlined,
            },
            title: mvLevelName(l10n, level),
            description: mvLevelHint(l10n, level),
            meta: meta(level),
            price: switch (_estimates[level]) {
              final MusicMvEstimate e => mvPriceLabel(l10n, e.credits),
              null => '—',
            },
            priceNote: switch (_estimates[level]) {
              final MusicMvEstimate e when e.credits == 0 => null,
              final MusicMvEstimate e when e.affordable => l10n.mvAvailableCredits(
                e.availableCredits,
              ),
              final MusicMvEstimate e => l10n.mvGapCredits(e.gapCredits),
              null => estimating ? l10n.mvEstimating : null,
            },
            badge: level == MusicMvLevel.chorus ? l10n.mvRecommended : null,
            statusLabel: pending.containsKey(level)
                ? l10n.mvStatusPending
                : null,
            selected: level == _level,
            onTap: _submitting ? null : () => _pickLevel(work, level),
          ),
        ),
        const SizedBox(height: SongletSpace.x2),
      ],
      if (estimate?.songLocked ?? false) ...[
        const SizedBox(height: SongletSpace.x2),
        Text(
          l10n.mvSongLocked,
          textAlign: TextAlign.center,
          style: SongletType.caption.copyWith(color: c.inkTertiary),
        ),
      ],
    ];

    final options = <Widget>[
      PanelSectionHeader(label: l10n.mvOptionsHeader),
      const SizedBox(height: SongletSpace.x3),
      _Labeled(
        label: l10n.mvAspectLabel,
        child: TestId(
          'mv.aspect',
          child: SegmentedToggle<MusicMvAspectRatio>(
            segments: [
              for (final r in MusicMvAspectRatio.values) (r, mvAspectName(l10n, r)),
            ],
            selected: _aspect,
            onChanged: (r) => setState(() => _aspect = r),
          ),
        ),
      ),
      if (offersQuality) ...[
        const SizedBox(height: SongletSpace.x4),
        _Labeled(
          label: l10n.mvQualityLabel,
          child: TestId(
            'mv.quality',
            child: SegmentedToggle<MusicMvQuality>(
              segments: [
                for (final q in qualities) (q, mvQualityName(l10n, q)),
              ],
              selected: _quality,
              onChanged: (q) => setState(() => _quality = q),
            ),
          ),
        ),
      ],
      if (_level != MusicMvLevel.lyricVideo) ...[
        const SizedBox(height: SongletSpace.x3),
        TestId(
          'mv.subtitles',
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.mvSubtitlesLabel,
              style: SongletType.body.copyWith(color: c.ink),
            ),
            value: _subtitles,
            onChanged: (v) => setState(() => _subtitles = v),
          ),
        ),
      ],
      if (_level == MusicMvLevel.chorus) ...[
        const SizedBox(height: SongletSpace.x3),
        _Labeled(
          label: l10n.mvChorusLabel,
          child: TestId(
            'mv.chorus',
            child: SegmentedToggle<bool>(
              segments: [
                (false, l10n.mvChorusAuto),
                (true, l10n.mvChorusCustom),
              ],
              selected: _customChorus,
              onChanged: (v) => setState(() => _customChorus = v),
            ),
          ),
        ),
        if (_customChorus) ...[
          const SizedBox(height: SongletSpace.x2),
          Text(
            l10n.mvChorusRange(
              clockLabel(chorus.start, l10n.localeName),
              clockLabel(chorus.end, l10n.localeName),
            ),
            textAlign: TextAlign.center,
            style: SongletType.footnote.copyWith(color: c.inkSecondary),
          ),
          TestId(
            'mv.chorusRange',
            child: RangeSlider(
              values: RangeValues(
                chorus.start.clamp(0, chorusMax),
                chorus.end.clamp(0, chorusMax),
              ),
              max: chorusMax,
              onChanged: (v) {
                final span = v.end - v.start;
                if (span < MusicMvChorusWindow.minMs / 1000 ||
                    span > MusicMvChorusWindow.maxMs / 1000) {
                  return;
                }
                setState(() => _chorus = v);
              },
            ),
          ),
        ],
      ],
      const SizedBox(height: SongletSpace.x4),
      _Labeled(
        label: l10n.mvPhotosLabel,
        hint: l10n.mvPhotosHint,
        child: TestId(
          'mv.photos',
          child: PhotoStrip(
            images: [for (final bytes in _photos) MemoryImage(bytes)],
            counter: l10n.mvPhotosCount(_photos.length),
            onRemove: (i) => setState(() => _photos.removeAt(i)),
            removeLabel: l10n.commonDelete,
            onAdd: _photos.length < MusicMvRequest.maxPhotos && !_picking
                ? _pickPhotos
                : null,
            addLabel: l10n.photosAdd,
          ),
        ),
      ),
    ];

    final regular =
        WindowClass.of(context) == WindowClass.regular &&
        !SongletType.isAccessibilitySize(context);
    final Widget body;
    if (regular) {
      final gutter = pageGutter(context);
      body = SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                gutter,
                SongletSpace.x2,
                gutter,
                SongletSpace.x2,
              ),
              child: const PushedHeader(),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        gutter,
                        SongletSpace.x2,
                        SongletSpace.x3,
                        SongletSpace.x6,
                      ),
                      children: levels,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        SongletSpace.x3,
                        SongletSpace.x2,
                        gutter,
                        SongletSpace.x6,
                      ),
                      children: options,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                gutter,
                SongletSpace.x2,
                gutter,
                SongletSpace.x4,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: SongletSize.anchoredPanelWidth,
                  ),
                  child: footer,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      body = PageFrame(
        header: const PushedHeader(),
        footer: footer,
        children: [
          ...levels,
          const SizedBox(height: SongletSpace.x4),
          ...options,
        ],
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // Leaving the hub gives up a video that waited for credits.
        if (didPop &&
            !_submitting &&
            _controller.pendingIntent(widget.workId) != null) {
          unawaited(_controller.discardIntent());
        }
      },
      child: Scaffold(body: TestId('mv.hub', child: body)),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child, this.hint});

  final String label;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: SongletType.subhead.copyWith(color: c.inkSecondary)),
        if (hint != null)
          Text(
            hint!,
            style: SongletType.caption.copyWith(color: c.inkTertiary),
          ),
        const SizedBox(height: SongletSpace.x2),
        child,
      ],
    );
  }
}
