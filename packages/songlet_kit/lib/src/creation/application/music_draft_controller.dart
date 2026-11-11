import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../platform/application/music_platform_providers.dart';
import '../../store/application/music_store_providers.dart';
import '../domain/music_creation_draft.dart';
import '../domain/music_genre.dart';
import '../domain/music_inspiration.dart';
import '../domain/music_occasion.dart';
import '../domain/music_preflight.dart';
import '../domain/music_region_preset.dart';
import '../domain/music_song_options.dart';
import '../domain/music_song_template.dart';
import 'music_creation_providers.dart';

/// The in-progress draft of the create flow (PRD §3.1 B → D; docs/ui P01–P04),
/// or null before the composer or a template starts one.
@immutable
class MusicCreationDraftState {
  const MusicCreationDraftState(this.draft);

  final MusicCreationDraft? draft;
}

class MusicCreationDraftController extends Notifier<MusicCreationDraftState> {
  @override
  MusicCreationDraftState build() => const MusicCreationDraftState(null);

  MusicCreationDraft? get draft => state.draft;

  /// Step B: an occasion starts a fresh draft on the default region preset —
  /// the App Store country, else the device region (PRD §11.3) — singing in
  /// the device language when the preset supports it.
  void start(MusicOccasion occasion, {required String deviceLanguage, String? deviceScript}) {
    final region = RegionPresets.defaultFor(
      storefrontAlpha3: ref.read(storefrontProvider),
      deviceRegion: ref.read(deviceRegionProvider),
    );
    state = MusicCreationDraftState(
      MusicCreationDraft(
        occasion: occasion,
        region: region,
        genre: region.genres.first,
        lyricLanguage: ref.read(lyricLanguagePreferenceProvider) ??
            defaultLyricLanguage(
              region,
              deviceLanguage: deviceLanguage,
              deviceScript: deviceScript,
            ),
      ),
    );
  }

  /// The create home (docs/ui P01): a free-form draft on the default region
  /// that the composer, panels and templates edit. Keeps an existing draft.
  void ensureStarted({required String deviceLanguage, String? deviceScript}) {
    if (draft != null) return;
    start(MusicOccasion.custom, deviceLanguage: deviceLanguage, deviceScript: deviceScript);
  }

  /// A built-in template picked on the offline grid (the server list is not
  /// loaded) or from a festival landing: its occasion and genre hint (else the
  /// region's), Length back to a preview (ADR-0036), keeping the region,
  /// vocals and text already chosen. Sent as `inspiration: <template id>` (the
  /// server lists the templates under their ids).
  void applyTemplate(
    MusicSongTemplate template, {
    required String deviceLanguage,
    String? deviceScript,
  }) {
    ensureStarted(deviceLanguage: deviceLanguage, deviceScript: deviceScript);
    update(
      (d) => d.copyWith(
        template: template,
        clearInspiration: true,
        occasion: template.occasion,
        model: MusicSongModel.clip,
        genre: template.genre?.label ?? d.genre ?? d.region.genres.first,
        clearFestival: template.occasion != MusicOccasion.festival,
        autoVideo: _autoVideo(d.autoVideo, template.videoByDefault),
      ),
    );
  }

  /// A card picked on the create home (contract 02 v2.1, ADR-0032): the card
  /// is the draft's single pick and decides the occasion; MusicVocals / MusicGenre jump
  /// to its defaults (`default_vocals`, `suggested_genre`) and "also make a
  /// video" to `default_on_video` (absent: the occasion's rule). Length starts
  /// at a preview whatever `default_model` says (ADR-0036: the first song of a
  /// session is a preview, PRD §3.1). What the card does not set stays as the
  /// user chose; the prompt keeps the user's own words (the card's hint is
  /// only a placeholder — its style is never sent as the description).
  void applyInspiration(
    MusicInspiration inspiration, {
    required String deviceLanguage,
    String? deviceScript,
  }) {
    ensureStarted(deviceLanguage: deviceLanguage, deviceScript: deviceScript);
    final template = inspiration.linkedTemplate;
    final occasion = inspiration.occasion ?? template?.occasion ?? MusicOccasion.custom;
    final genre = MusicGenre.fromLabel(inspiration.suggestedGenre)?.label;
    update(
      (d) => d.copyWith(
        inspirationSlug: inspiration.slug,
        pickRequiresRecipient: inspiration.requiresRecipient ?? template?.requiresRecipient ?? occasion.requiresRecipient,
        pickInputRequired: inspiration.composer?.inputRequired ?? false,
        template: template,
        clearTemplate: template == null,
        occasion: occasion,
        clearFestival: occasion != MusicOccasion.festival,
        model: MusicSongModel.clip,
        // Absent `default_vocals` = the client default (§1), not the last card's.
        vocals: inspiration.defaultVocals ?? MusicVocals.vocals,
        genre: genre,
        autoVideo: _autoVideo(d.autoVideo, inspiration.defaultOnVideo ?? occasion.videoByDefault),
      ),
    );
  }

  /// The card's default for the video toggle; Premier's chorus bundle is kept.
  static MusicAutoVideo _autoVideo(MusicAutoVideo current, bool on) =>
      current == MusicAutoVideo.chorus ? MusicAutoVideo.chorus : (on ? MusicAutoVideo.lyric : MusicAutoVideo.none);

  /// Unpicks the card (tapping it again, or the head's close button): back to
  /// free input. Everything typed stays in the draft — the name and three
  /// words fold away and come back with the next pick (ADR-0033).
  void clearPick() => update(
        (d) => d.copyWith(
          clearInspiration: true,
          clearTemplate: true,
          occasion: MusicOccasion.custom,
          clearFestival: true,
        ),
      );

  /// Length panel (ADR-0033: the only control of the length).
  void setModel(MusicSongModel model) => update((d) => d.copyWith(model: model));

  /// The composer's "also make a video" switch (docs/ui P28, ADR-0033): a
  /// video made once the full song is ready.
  void setAutoVideo(MusicAutoVideo autoVideo) => update((d) => d.copyWith(autoVideo: autoVideo));

  void setVocals(MusicVocals vocals) => update((d) => d.copyWith(vocals: vocals));

  /// MusicGenre panel: a preset genre or catalogue label; null = Custom.
  void setGenre(String? genre) => update(
        (d) => genre == null
            ? d.copyWith(customGenre: true)
            : d.copyWith(genre: genre),
      );

  void setGenreFrom(MusicGenre genre) => setGenre(genre.label);

  void setPrompt(String prompt) => update((d) => d.copyWith(prompt: prompt));

  /// A voice transcript applied as the description (docs/ui P03a): dictation
  /// is part of the free input (ADR-0033).
  void applyTranscript(String transcript) {
    final text = transcript.trim();
    if (text.isEmpty) return;
    update((d) => d.copyWith(prompt: String.fromCharCodes(text.runes.take(MusicPreflight.maxPrompt))));
  }

  /// Step C: switching country resets genre + lyric language to its preset.
  void selectRegion(MusicRegionPreset region, {required String deviceLanguage}) {
    final current = draft;
    if (current == null) return;
    state = MusicCreationDraftState(
      current.copyWith(
        region: region,
        // A template's own genre hint and an explicit Custom survive; a
        // region's local genre follows the region.
        genre: current.template?.genre?.label ??
            (current.genre == null ? null : region.genres.first),
        customGenre: current.template?.genre == null && current.genre == null,
        lyricLanguage: ref.read(lyricLanguagePreferenceProvider) ??
            defaultLyricLanguage(region, deviceLanguage: deviceLanguage),
        clearFestival: true,
      ),
    );
  }

  void update(MusicCreationDraft Function(MusicCreationDraft draft) change) {
    final current = draft;
    if (current != null) state = MusicCreationDraftState(change(current));
  }

  /// PhotosPicker (PRD F04): appends up to the 10-photo cap.
  Future<void> pickPhotos() async {
    final current = draft;
    if (current == null) return;
    final room = MusicPreflight.maxPhotos - current.photos.length;
    if (room <= 0) return;
    final List<Uint8List> picked = await ref.read(photoSourceProvider).pickPhotos(room);
    final latest = draft;
    if (picked.isEmpty || latest == null) return;
    state = MusicCreationDraftState(
      latest.copyWith(photos: [...latest.photos, ...picked], imageBids: const []),
    );
  }

  void removePhoto(int index) => update(
        (d) => d.copyWith(
          photos: [...d.photos]..removeAt(index),
          imageBids: const [],
        ),
      );

  void clear() => state = const MusicCreationDraftState(null);

  /// "歌词语言默认跟随设备语言，可手动切换" (PRD §11.3): the device language when
  /// the preset sings it, else the preset's first language.
  static MusicLyricLanguage defaultLyricLanguage(
    MusicRegionPreset region, {
    required String deviceLanguage,
    String? deviceScript,
  }) {
    final device = MusicLyricLanguage.forLocale(deviceLanguage, scriptCode: deviceScript);
    if (device != null && region.languages.any((l) => l.baseCode == device.baseCode)) {
      return region.languages.firstWhere((l) => l.baseCode == device.baseCode);
    }
    return region.primaryLanguage;
  }
}
