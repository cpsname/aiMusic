import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/music_ui_locale.dart';
import '../common/music_page_layout.dart';
import '../common/music_test_id.dart';
import 'music_create_flow.dart';
import 'music_create_labels.dart';

/// P04 — image-to-song (PRD F04 / §2.2): 1–10 photos from the system
/// PhotosPicker, downscaled natively (1024 px, JPEG 0.8), held in memory only.
class MusicPhotosPage extends ConsumerStatefulWidget {
  const MusicPhotosPage({super.key});

  @override
  ConsumerState<MusicPhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends ConsumerState<MusicPhotosPage> {
  bool _picking = false;
  bool _submitting = false;
  List<MusicPreflightIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locale = ref.read(systemUiLocaleProvider);
      final notifier = ref.read(creationDraftProvider.notifier)
        ..ensureStarted(
          deviceLanguage: locale.languageCode,
          deviceScript: locale.scriptCode,
        );
      if (notifier.draft?.photos.isEmpty ?? true) _pick();
    });
  }

  Future<void> _pick() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      await ref.read(creationDraftProvider.notifier).pickPhotos();
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _create() async {
    // Photos are free input (ADR-0033): a song made from them leaves a
    // picked card behind (its fields stay in the draft for the next pick).
    final drafts = ref.read(creationDraftProvider.notifier);
    if (drafts.draft?.hasPick ?? false) drafts.clearPick();
    final flow = MusicCreateFlow(context, ref);
    final issues = flow.issues();
    setState(() => _issues = issues);
    if (issues.isNotEmpty) return;
    setState(() => _submitting = true);
    await flow.submit();
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final photos =
        ref.watch(creationDraftProvider).draft?.photos ?? const <List<int>>[];
    final images = [
      for (final bytes in photos)
        MemoryImage(bytes is Uint8List ? bytes : Uint8List.fromList(bytes)),
    ];

    return Scaffold(
      body: MusicPageFrame(
        header: const MusicPushedHeader(showBrand: false),
        footer: MusicTestId(
          'photos.create',
          child: ObsButton(
            label: l10n.photosCreate,
            loading: _submitting,
            onPressed: photos.isEmpty ? null : _create,
          ),
        ),
        children: [
          MusicPageTitle(title: l10n.photosTitle),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (photos.isEmpty)
                  EmptyState(
                    icon: Icons.photo_library_outlined,
                    title: l10n.photosAdd,
                    message: l10n.photosEmpty,
                    actionLabel: _picking ? null : l10n.photosAdd,
                    onAction: _pick,
                  )
                else
                  MusicTestId(
                    'photos.strip',
                    child: PhotoStrip(
                      images: images,
                      counter: l10n.photosCount(
                        photos.length,
                        MusicPreflight.maxPhotos,
                      ),
                      removeLabel: l10n.photoRemove,
                      onRemove: ref
                          .read(creationDraftProvider.notifier)
                          .removePhoto,
                      addLabel: l10n.photosAdd,
                      onAdd: photos.length < MusicPreflight.maxPhotos && !_picking
                          ? _pick
                          : null,
                    ),
                  ),
                const SizedBox(height: SongletSpace.x4),
                Text(
                  l10n.photosPrivacy,
                  style: SongletType.subhead.copyWith(color: c.inkSecondary),
                ),
              ],
            ),
          ),
          if (_issues.isNotEmpty) ...[
            const SizedBox(height: SongletSpace.x4),
            InlineErrorBanner(message: preflightIssueText(l10n, _issues.first)),
          ],
        ],
      ),
    );
  }
}
