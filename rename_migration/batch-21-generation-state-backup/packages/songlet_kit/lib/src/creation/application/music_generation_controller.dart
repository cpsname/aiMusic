import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:uuid/uuid.dart';

import '../../library/application/library_providers.dart';
import '../../library/domain/work.dart';
import '../../platform/application/platform_providers.dart';
import '../domain/music_creation_draft.dart';
import '../domain/music_generation.dart';
import '../domain/preflight.dart';
import '../domain/prompt_block.dart';
import '../domain/music_error_code.dart';
import 'creation_providers.dart';
import 'generation_state.dart';
import 'job_runner.dart';

/// One generation, end to end (PRD §3.1 / §7.1): local preflight → device
/// attestation → on-device prompt polish (SystemLanguageModel)
/// → photo upload → `POST /v1/generate` → poll → download → library.
///
/// Charging and refunds are server-side (PRD §8.4); after every terminal
/// outcome the entitlement is refreshed so the counters follow the ledger.
class MusicGenerationController extends Notifier<GenerationState> {
  static const Duration polishTimeout = Duration(seconds: 8);

  bool _disposed = false;

  /// Set by [cancel]; stops the poller of the current run.
  bool _cancelled = false;

  @override
  GenerationState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const GenerationIdle();
  }

  bool get _stopped => _disposed || _cancelled;

  /// The server charged or refunded: re-read the ledger now, from this run —
  /// left stale, the first widget to watch it (the create home's primary
  /// action) would rebuild it during its build, and the refresh of the
  /// ledger's other readers would land mid-frame.
  void _refreshLedger() {
    ref.invalidate(walletSnapshotProvider);
    ref.read(walletSnapshotProvider);
  }

  Preflight get _preflight => ref.read(preflightProvider);
  JobRunner get _runner => ref.read(jobRunnerProvider);
  ErrorHandler get _errors => ref.read(errorHandlerProvider);

  void reset() {
    if (!state.isBusy) state = const GenerationIdle();
  }

  /// Generates [draft] — a clip or a full song per its length, or [model]
  /// when given (the full song of a clip). [parentId] links a full song (or
  /// another version) to the clip it came from.
  Future<void> generate(
    MusicCreationDraft draft, {
    SongModel? model,
    String? parentId,
  }) async {
    if (state.isBusy) return;
    _cancelled = false;
    final songModel = model ?? draft.model;
    draft = draft.copyWith(model: songModel).forSubmit();
    state = GenerationPreparing(songModel, PreparingStep.checking);

    final checked = _preflight.check(draft);
    if (!checked.isOk) {
      state = GenerationRejected(checked.issues);
      return;
    }
    var ready = checked.draft!;

    String? workId;
    try {
      await ref.read(authControllerProvider.notifier).ensureAuthenticated();

      state = GenerationPreparing(songModel, PreparingStep.polishing);
      final note = await _polish(ready);

      if (ready.photos.isNotEmpty && ready.imageBids.isEmpty) {
        state = GenerationPreparing(songModel, PreparingStep.uploadingPhotos);
        final uploader = ref.read(photoUploaderProvider);
        final bids = <String>[];
        for (var i = 0; i < ready.photos.length; i++) {
          bids.add(await uploader.upload(ready.photos[i], filename: 'photo_${i + 1}.jpg'));
        }
        // The bytes are dropped from the draft once uploaded (never persisted).
        ready = ready.copyWith(imageBids: bids, photos: const []);
      }

      state = GenerationPreparing(songModel, PreparingStep.submitting);
      final id = const Uuid().v4();
      final ticket = await ref.read(generationRepositoryProvider).submit(
            MusicGenerationRequest.fromDraft(ready, clientRef: id, note: note),
          );
      workId = id;

      var work = Work(
        id: id,
        jobId: ticket.jobId,
        model: songModel,
        status: WorkStatus.pending,
        occasion: ready.occasion,
        festival: ready.festival,
        region: ready.region.code,
        genre: ready.genre ?? '',
        template: ready.template,
        inspiration: ready.inspirationSlug,
        vocals: ready.vocals,
        prompt: ready.prompt,
        lyricLanguage: ready.lyricLanguage.code,
        recipient: ready.recipient,
        keywords: ready.keywords,
        userLyrics: ready.userLyrics,
        promptNote: note,
        imageBids: ready.imageBids,
        parentId: parentId,
        autoVideo: ready.autoVideo,
        createdAt: DateTime.now().toUtc(),
      );
      await ref.read(workRepositoryProvider).upsert(work);

      var waiting = GenerationWaiting(
        model: songModel,
        workId: id,
        jobId: ticket.jobId,
        etaSeconds: ticket.etaSeconds,
        startedAt: DateTime.now(),
      );
      state = waiting;

      // Claim the job in the runner before the library reloads, so its resume
      // of pending works does not start a second poller for this one.
      final running = _runner.run(
        work,
        isCancelled: () => _stopped,
        onSnapshot: (snapshot) {
          if (_stopped) return;
          final current = state;
          waiting = (current is GenerationWaiting ? current : waiting)
              .withSnapshot(snapshot);
          state = waiting;
        },
      );
      refreshLibrary(ref);
      // The server pre-charged the allowance (PRD §8.4).
      _refreshLedger();
      work = await running;
      if (_stopped) return;
      refreshLibrary(ref);
      _refreshLedger();

      if (work.status == WorkStatus.ready) {
        state = GenerationSucceeded(work);
      } else {
        _fail(
          MusicErrorCode.fromWire(work.errorCode) ?? MusicErrorCode.upstreamTimeout,
          model: songModel,
          draft: ready,
        );
      }
    } on MusicJobTimeoutException {
      if (_stopped) return;
      _fail(MusicErrorCode.upstreamTimeout, model: songModel, draft: ready, workId: workId);
    } on Object catch (error, stackTrace) {
      if (_stopped) return;
      final failure = _errors.handle(error, stackTrace);
      // The scene is not (or no longer) in the list, or belongs to another
      // occasion (contract 02 v2.1 §2.7): fetch the list again.
      if (failure.details.containsKey('inspiration')) ref.invalidate(inspirationsProvider);
      state = GenerationFailed(
        failure,
        model: songModel,
        draft: ready,
        workId: workId,
      );
      if (workId != null) refreshLibrary(ref);
    }
  }

  /// Cancels the running job (docs/ui P05 "Cancel", ADR-0012): the server
  /// refunds a job still queued and keeps the charge for one already started
  /// (PRD §8.4). The pending work is removed from the library either way.
  /// Returns whether the allowance was refunded; null when nothing was
  /// running. A failed cancel request leaves the job running.
  Future<bool?> cancel() async {
    final current = state;
    if (current is! GenerationWaiting || current.cancelling) return null;
    state = current.copyWith(cancelling: true);
    try {
      final outcome =
          await ref.read(generationRepositoryProvider).cancel(current.jobId);
      _cancelled = true;
      await ref.read(workRepositoryProvider).delete(current.workId);
      refreshLibrary(ref);
      _refreshLedger();
      state = const GenerationIdle();
      return outcome.refunded;
    } on Object catch (error, stackTrace) {
      _errors.handle(error, stackTrace);
      final latest = state;
      if (latest is GenerationWaiting) {
        state = latest.copyWith(cancelling: false);
      }
      rethrow;
    }
  }

  Future<String> _polish(MusicCreationDraft draft) async {
    try {
      final brief = PromptBlock.brief(draft);
      final polished = await ref
          .read(promptPolisherProvider)
          .polish(brief, draft.lyricLanguage.code)
          .timeout(polishTimeout);
      return polished == brief ? '' : polished;
    } on Object {
      return ''; // polishing is best effort (PRD §6.2)
    }
  }

  void _fail(
    MusicErrorCode code, {
    required SongModel model,
    MusicCreationDraft? draft,
    String? workId,
  }) {
    state = GenerationFailed(
      _errors.handle(code.toApiError()),
      model: model,
      draft: draft,
      workId: workId,
    );
  }
}
