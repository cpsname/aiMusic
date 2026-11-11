import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../routing/navigation.dart';
import '../routing/routes.dart';

/// Outcome of trying to start a song.
enum SubmitOutcome {
  /// Generation started; the generating page is open.
  started,

  /// The draft has preflight issues; the composer shows them (P18).
  rejected,

  /// Nothing to submit.
  noDraft,
}

/// The one way every create surface (the composer, photos) starts a song:
/// local preflight → [MusicGenerationController.generate] → the generating page
/// (P05). There is no client-side allowance gate (contract 02 v2.1:
/// everything costs credits): the server answers `QUOTA_EXHAUSTED` and the
/// generating page opens the paywall it asks for.
class CreateFlow {
  CreateFlow(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  MusicCreationDraft? get _draft => ref.read(creationDraftProvider).draft;

  /// MusicPreflight issues of what would be sent (empty = ready): with nothing
  /// picked, the folded name / three words / lyrics are not part of it.
  List<MusicPreflightIssue> issues() {
    final draft = _draft;
    if (draft == null) return const [];
    return ref.read(preflightProvider).check(draft.forSubmit()).issues;
  }

  /// Starts the draft, unless preflight rejects it (the caller shows
  /// [issues]).
  Future<SubmitOutcome> submit() async {
    final draft = _draft;
    if (draft == null) return SubmitOutcome.noDraft;
    if (issues().isNotEmpty) return SubmitOutcome.rejected;
    if (!context.mounted) return SubmitOutcome.noDraft;
    unawaited(ref.read(generationControllerProvider.notifier).generate(draft));
    // `go`, not push: the Create tab's location then records the progress
    // page, so once the song has opened in Library the tab's restore passes
    // the route's idle redirect and lands on the create home (the draft is
    // kept for another go).
    context.goTo(const GenerateRoute());
    return SubmitOutcome.started;
  }
}
