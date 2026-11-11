import 'package:songlet_kit/songlet_kit.dart';

import '../../l10n/generated/app_localizations.dart';

/// Localized names of the music-video vocabulary (PRD ch.15).

String mvLevelName(AppLocalizations l10n, MusicMvLevel level) => switch (level) {
  MusicMvLevel.lyricVideo => l10n.mvLevelLyricVideo,
  MusicMvLevel.chorus => l10n.mvLevelChorus,
  MusicMvLevel.full => l10n.mvLevelFull,
};

String mvLevelHint(AppLocalizations l10n, MusicMvLevel level) => switch (level) {
  MusicMvLevel.lyricVideo => l10n.mvLevelLyricHint,
  MusicMvLevel.chorus => l10n.mvLevelChorusHint,
  MusicMvLevel.full => l10n.mvLevelFullHint,
};

String mvAspectName(AppLocalizations l10n, MusicMvAspectRatio ratio) =>
    switch (ratio) {
      MusicMvAspectRatio.portrait => l10n.mvAspectPortrait,
      MusicMvAspectRatio.landscape => l10n.mvAspectLandscape,
      MusicMvAspectRatio.square => l10n.mvAspectSquare,
    };

String mvQualityName(AppLocalizations l10n, MusicMvQuality quality) =>
    switch (quality) {
      MusicMvQuality.standard => l10n.mvQualityStandard,
      MusicMvQuality.high => l10n.mvQualityHigh,
    };

/// The platform's stage name → copy. Unknown stages (a newer platform) show
/// the generic title; nothing breaks (contract v1.1 `MvStage`).
String? mvStageName(AppLocalizations l10n, String? stage) => switch (stage) {
  'queued' => l10n.mvStageQueued,
  'slicing' => l10n.mvStageSlicing,
  'storyboarding' => l10n.mvStageStoryboarding,
  'keyframing' => l10n.mvStageKeyframing,
  'rendering' => l10n.mvStageRendering,
  'assembling' => l10n.mvStageAssembling,
  'done' => l10n.mvStageDone,
  _ => null,
};

/// Price line of an estimate: its credits (every level costs credits since
/// contract 02 v2.1, the lyric video included).
String mvPriceLabel(AppLocalizations l10n, int credits) =>
    l10n.mvPriceCredits(credits);

String mvStatusName(AppLocalizations l10n, MusicWorkStatus status) =>
    switch (status) {
      MusicWorkStatus.ready => l10n.mvStatusReady,
      MusicWorkStatus.pending => l10n.mvStatusPending,
      MusicWorkStatus.failed => l10n.mvStatusFailed,
    };

/// The paywall row subtitle of an MV pack.
String mvPackSubtitle(AppLocalizations l10n, String productId) =>
    switch (productId) {
      MusicCatalog.mvChorusPack => l10n.mvPackChorusSubtitle,
      _ => l10n.mvPackFullSubtitle,
    };
