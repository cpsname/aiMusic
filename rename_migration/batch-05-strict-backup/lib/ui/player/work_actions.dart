import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/messages.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';

/// What a finished work offers (PRD §3.1 G–I): the full song (paywalled),
/// another version, regenerate, delete. Shared by the players, the library and
/// the work detail page so all behave identically.
class WorkActions {
  WorkActions(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  /// "Get the full song" — straight to generation; when the account has no
  /// credits for it the server answers `QUOTA_EXHAUSTED` and the generating
  /// page opens the paywall (PRD §8.2, contract 02 v2.1).
  Future<void> makeFullSong(Work clip) => _generate(clip, SongModel.fullSong);

  /// "Try another version" (PRD F14) / "Regenerate same style" (P13): the same
  /// inputs and length, a new take.
  Future<void> anotherVersion(Work work) => _generate(work, work.model);

  Future<void> _generate(Work source, SongModel model) async {
    final draft = draftFromWork(source);
    if (draft == null) return;
    ref
        .read(creationDraftProvider.notifier)
        .update((_) => draft.copyWith(model: model));
    unawaited(
      ref
          .read(generationControllerProvider.notifier)
          .generate(draft, model: model, parentId: source.id),
    );
    context.goTo(const GenerateRoute());
  }

  /// Delete after confirmation; leaves the work's pages. Everything tied to
  /// the page's context is captured first — the page rebuilds without the
  /// work while the deletion completes.
  Future<void> delete(Work work) async {
    final l10n = _l10n;
    final messages = ref.read(messageControllerProvider);
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.libraryDeleteTitle),
        content: Text(l10n.libraryDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final path = await ref.read(workAudioPathProvider(work.id).future);
    if (path != null && ref.read(playerControllerProvider).isCurrent(path)) {
      await ref.read(playerControllerProvider.notifier).stop();
    }
    await ref.read(libraryProvider.notifier).delete(work);
    messages.success(l10n.libraryDeleted);
    router.go(const LibraryRoute().location);
  }
}
