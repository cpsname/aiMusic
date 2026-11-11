import 'package:songlet_kit/songlet_kit.dart';

import '../../l10n/generated/app_localizations.dart';

/// Localized names of the music-video vocabulary (PRD ch.15).

String mvLevelName(AppLocalizations l10n, MvLevel level) => switch (level) {
  MvLevel.lyricVideo => l10n.mvLevelLyricVideo,
  MvLevel.chorus => l10n.mvLevelChorus,
  MvLevel.full => l10n.mvLevelFull,
};

String mvLevelHint(AppLocalizations l10n, MvLevel level) => switch (level) {
  MvLevel.lyricVideo => l10n.mvLevelLyricHint,
  MvLevel.chorus => l10n.mvLevelChorusHint,
  MvLevel.full => l10n.mvLevelFullHint,
};

String mvAspectName(AppLocalizations l10n, MvAspectRatio ratio) =>
    switch (ratio) {
      MvAspectRatio.portrait => l10n.mvAspectPortrait,
      MvAspectRatio.landscape => l10n.mvAspectLandscape,
      MvAspectRatio.square => l10n.mvAspectSquare,
    };

String mvQualityName(AppLocalizations l10n, MvQuality quality) =>
    switch (quality) {
      MvQuality.standard => l10n.mvQualityStandard,
      MvQuality.high => l10n.mvQualityHigh,
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

String mvStatusName(AppLocalizations l10n, WorkStatus status) =>
    switch (status) {
      WorkStatus.ready => l10n.mvStatusReady,
      WorkStatus.pending => l10n.mvStatusPending,
      WorkStatus.failed => l10n.mvStatusFailed,
    };

/// The paywall row subtitle of an MV pack.
String mvPackSubtitle(AppLocalizations l10n, String productId) =>
    switch (productId) {
      MusicCatalog.mvChorusPack => l10n.mvPackChorusSubtitle,
      _ => l10n.mvPackFullSubtitle,
    };
