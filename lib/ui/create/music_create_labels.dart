import 'package:flutter/material.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import 'music_composer_model.dart';

/// Localized names + glyphs for the creation vocabulary (occasions, festivals,
/// countries, lyric languages, preflight issues).

IconData occasionIcon(MusicOccasion occasion) => switch (occasion) {
  MusicOccasion.birthday => Icons.cake_outlined,
  MusicOccasion.anniversary => Icons.favorite_border_rounded,
  MusicOccasion.confession => Icons.volunteer_activism_outlined,
  MusicOccasion.wedding => Icons.local_florist_outlined,
  MusicOccasion.memorial => Icons.local_fire_department_outlined,
  MusicOccasion.festival => Icons.celebration_outlined,
  MusicOccasion.brand => Icons.campaign_outlined,
  MusicOccasion.soundtrack => Icons.movie_creation_outlined,
  MusicOccasion.custom => Icons.auto_awesome_outlined,
};

String occasionName(AppLocalizations l10n, MusicOccasion occasion) =>
    switch (occasion) {
      MusicOccasion.birthday => l10n.occasionBirthday,
      MusicOccasion.anniversary => l10n.occasionAnniversary,
      MusicOccasion.confession => l10n.occasionConfession,
      MusicOccasion.wedding => l10n.occasionWedding,
      MusicOccasion.memorial => l10n.occasionMemorial,
      MusicOccasion.festival => l10n.occasionFestival,
      MusicOccasion.brand => l10n.occasionBrand,
      MusicOccasion.soundtrack => l10n.occasionSoundtrack,
      MusicOccasion.custom => l10n.templateCustom,
    };

String occasionHint(AppLocalizations l10n, MusicOccasion occasion) =>
    switch (occasion) {
      MusicOccasion.birthday => l10n.occasionBirthdayHint,
      MusicOccasion.anniversary => l10n.occasionAnniversaryHint,
      MusicOccasion.confession => l10n.occasionConfessionHint,
      MusicOccasion.wedding => l10n.occasionWeddingHint,
      MusicOccasion.memorial => l10n.occasionMemorialHint,
      MusicOccasion.festival => l10n.occasionFestivalHint,
      MusicOccasion.brand => l10n.occasionBrandHint,
      MusicOccasion.soundtrack => l10n.occasionSoundtrackHint,
      MusicOccasion.custom => l10n.composerSourceMusicHint,
    };

String festivalName(AppLocalizations l10n, MusicFestival festival) =>
    switch (festival) {
      MusicFestival.newYear => l10n.festivalNewYear,
      MusicFestival.thanksgiving => l10n.festivalThanksgiving,
      MusicFestival.diwali => l10n.festivalDiwali,
      MusicFestival.carnival => l10n.festivalCarnival,
      MusicFestival.eid => l10n.festivalEid,
      MusicFestival.lunarNewYear => l10n.festivalLunarNewYear,
    };

String countryName(AppLocalizations l10n, String code) => switch (code) {
  'US' => l10n.countryUS,
  'GB' => l10n.countryGB,
  'CA' => l10n.countryCA,
  'AU' => l10n.countryAU,
  'DE' => l10n.countryDE,
  'FR' => l10n.countryFR,
  'JP' => l10n.countryJP,
  'KR' => l10n.countryKR,
  'BR' => l10n.countryBR,
  'MX' => l10n.countryMX,
  'IN' => l10n.countryIN,
  'ID' => l10n.countryID,
  'VN' => l10n.countryVN,
  'TR' => l10n.countryTR,
  _ => code,
};

String languageName(AppLocalizations l10n, MusicLyricLanguage language) =>
    switch (language) {
      MusicLyricLanguage.en => l10n.languageEn,
      MusicLyricLanguage.fr => l10n.languageFr,
      MusicLyricLanguage.de => l10n.languageDe,
      MusicLyricLanguage.ja => l10n.languageJa,
      MusicLyricLanguage.ko => l10n.languageKo,
      MusicLyricLanguage.ptBR => l10n.languagePtBR,
      MusicLyricLanguage.esMX => l10n.languageEsMX,
      MusicLyricLanguage.hi => l10n.languageHi,
      MusicLyricLanguage.id => l10n.languageId,
      MusicLyricLanguage.vi => l10n.languageVi,
      MusicLyricLanguage.tr => l10n.languageTr,
      MusicLyricLanguage.zhHans => l10n.languageZhHans,
      MusicLyricLanguage.zhHant => l10n.languageZhHant,
    };

String preflightIssueText(
  AppLocalizations l10n,
  MusicPreflightIssue issue, {
  int? limit,
}) => switch (issue) {
  MusicPreflightIssue.promptTooLong => l10n.issuePromptTooLong(MusicPreflight.maxPrompt),
  MusicPreflightIssue.recipientArtistName => l10n.issueRecipientArtistName,
  MusicPreflightIssue.recipientMissing => l10n.issueRecipientMissing,
  MusicPreflightIssue.recipientTooLong => l10n.issueRecipientTooLong,
  MusicPreflightIssue.briefMissing => l10n.issueBriefMissing,
  MusicPreflightIssue.keywordTooLong => l10n.issueKeywordTooLong,
  MusicPreflightIssue.tooManyKeywords => l10n.issueTooManyKeywords,
  MusicPreflightIssue.artistName => l10n.issueArtistName,
  MusicPreflightIssue.styleImitation => l10n.issueStyleImitation,
  MusicPreflightIssue.lyricsTooLong => l10n.issueLyricsTooLong(
    limit ?? MusicLyricsFormatter.latinLimit,
  ),
  MusicPreflightIssue.lyricsNotOriginal => l10n.issueLyricsNotOriginal,
  MusicPreflightIssue.lyricsOwnershipUnconfirmed => l10n.issueLyricsOwnership,
  MusicPreflightIssue.tooManyPhotos => l10n.issueTooManyPhotos,
};

String templateName(AppLocalizations l10n, MusicSongTemplate template) =>
    switch (template) {
      MusicSongTemplate.birthdayWish => l10n.templateBirthdayWish,
      MusicSongTemplate.birthdayParty => l10n.templateBirthdayParty,
      MusicSongTemplate.loveStory => l10n.templateLoveStory,
      MusicSongTemplate.thankAFriend => l10n.templateThankAFriend,
      MusicSongTemplate.partyInvite => l10n.templatePartyInvite,
      MusicSongTemplate.wedding => l10n.templateWedding,
      MusicSongTemplate.inMemory => l10n.templateInMemory,
      MusicSongTemplate.festival => l10n.templateFestival,
      MusicSongTemplate.ringtone => l10n.templateRingtone,
      MusicSongTemplate.teamAnthem => l10n.templateTeamAnthem,
      MusicSongTemplate.sportsRecap => l10n.templateSportsRecap,
      MusicSongTemplate.rapBattle => l10n.templateRapBattle,
      MusicSongTemplate.comedy => l10n.templateComedy,
      MusicSongTemplate.petAnthem => l10n.templatePetAnthem,
      MusicSongTemplate.hometown => l10n.templateHometown,
      MusicSongTemplate.businessPromo => l10n.templateBusinessPromo,
    };

String templateHint(AppLocalizations l10n, MusicSongTemplate template) =>
    switch (template) {
      MusicSongTemplate.birthdayWish => l10n.templateBirthdayWishHint,
      MusicSongTemplate.birthdayParty => l10n.templateBirthdayPartyHint,
      MusicSongTemplate.loveStory => l10n.templateLoveStoryHint,
      MusicSongTemplate.thankAFriend => l10n.templateThankAFriendHint,
      MusicSongTemplate.partyInvite => l10n.templatePartyInviteHint,
      MusicSongTemplate.wedding => l10n.templateWeddingHint,
      MusicSongTemplate.inMemory => l10n.templateInMemoryHint,
      MusicSongTemplate.festival => l10n.templateFestivalHint,
      MusicSongTemplate.ringtone => l10n.templateRingtoneHint,
      MusicSongTemplate.teamAnthem => l10n.templateTeamAnthemHint,
      MusicSongTemplate.sportsRecap => l10n.templateSportsRecapHint,
      MusicSongTemplate.rapBattle => l10n.templateRapBattleHint,
      MusicSongTemplate.comedy => l10n.templateComedyHint,
      MusicSongTemplate.petAnthem => l10n.templatePetAnthemHint,
      MusicSongTemplate.hometown => l10n.templateHometownHint,
      MusicSongTemplate.businessPromo => l10n.templateBusinessPromoHint,
    };

/// The occasion a work or draft is filed under: its template's name, else the
/// occasion ("Just because" for a free-form prompt in the library).
String workKindName(
  AppLocalizations l10n, {
  MusicSongTemplate? template,
  required MusicOccasion occasion,
}) => template != null
    ? templateName(l10n, template)
    : occasionName(l10n, occasion);

String vocalsName(AppLocalizations l10n, MusicVocals vocals) => switch (vocals) {
  MusicVocals.custom => l10n.vocalsCustom,
  MusicVocals.vocals => l10n.vocalsOn,
  MusicVocals.instrumental => l10n.vocalsInstrumental,
};

IconData vocalsIcon(MusicVocals vocals) => switch (vocals) {
  MusicVocals.custom => Icons.auto_fix_high_outlined,
  MusicVocals.vocals => Icons.record_voice_over_outlined,
  MusicVocals.instrumental => Icons.mic_off_outlined,
};

String lengthName(AppLocalizations l10n, MusicSongModel model) =>
    model == MusicSongModel.clip ? l10n.lengthShort : l10n.lengthStandard;

/// The composer's primary action in words (ADR-0035): the verb by length and
/// name, the cost only as the ledger shows it.
String createActionLabel(AppLocalizations l10n, MusicCreateAction action) {
  final cost = action.cost.name;
  return switch (action.kind) {
    MusicCreateActionKind.preview => l10n.createPreviewLabel(cost),
    MusicCreateActionKind.previewFor => l10n.createPreviewForLabel(
      action.name ?? '',
      cost,
    ),
    MusicCreateActionKind.fullSong => l10n.createFullSongLabel(cost),
  };
}

/// One value of the composer's summary row (ADR-0033).
String summaryPartName(
  AppLocalizations l10n,
  MusicSummaryPart part,
  MusicCreationDraft draft,
) => switch (part) {
  MusicSummaryPart.preview => l10n.lengthPreview,
  MusicSummaryPart.fullSong => l10n.lengthFull,
  MusicSummaryPart.songAndChorus => l10n.lengthSongAndChorus,
  MusicSummaryPart.vocalsOn => l10n.vocalsOn,
  MusicSummaryPart.instrumental => l10n.vocalsInstrumental,
  MusicSummaryPart.anyVocals => l10n.composerSummaryAnyVocals,
  MusicSummaryPart.genre => genreName(l10n, draft.genre),
  MusicSummaryPart.anyGenre => l10n.composerSummaryAnyGenre,
  MusicSummaryPart.ownLyrics => l10n.composerSummaryLyrics,
  MusicSummaryPart.video => l10n.composerSummaryVideo,
};

/// A draft genre for display: the chosen one, or "Custom".
String genreName(AppLocalizations l10n, String? genre) => switch (genre) {
  null || '' => l10n.genreCustom,
  'Pop' => l10n.createGenrePop,
  'Hip-Hop & Rap' => l10n.createGenreHipHopRap,
  'Rock' => l10n.createGenreRock,
  'K-Pop' => l10n.createGenreKPop,
  'Latin' => l10n.createGenreLatin,
  'Electronic' => l10n.createGenreElectronic,
  'R&B' => l10n.createGenreRnb,
  'Country' => l10n.createGenreCountry,
  'Afrobeats' => l10n.createGenreAfrobeats,
  'Reggae' => l10n.createGenreReggae,
  'Jazz & Blues' => l10n.createGenreJazzBlues,
  'Classical' => l10n.createGenreClassical,
  'Folk' => l10n.createGenreFolk,
  'Lo-Fi' => l10n.createGenreLofi,
  'Acoustic' => l10n.createGenreAcoustic,
  'Cinematic' => l10n.createGenreCinematic,
  'Ambient' => l10n.createGenreAmbient,
  'Bossa Nova' => l10n.createGenreBossaNova,
  'Indie Pop' => l10n.createGenreIndiePop,
  'Contemporary R&B' => l10n.createGenreContemporaryRnb,
  'Alternative Country' => l10n.createGenreAlternativeCountry,
  'Garage Rock' => l10n.createGenreGarageRock,
  'Grime' => l10n.createGenreGrime,
  'Indie Folk' => l10n.createGenreIndieFolk,
  'Synthpop' => l10n.createGenreSynthpop,
  'Piano Ballad' => l10n.createGenrePianoBallad,
  'Surf Rock' => l10n.createGenreSurfRock,
  'Deep House' => l10n.createGenreDeepHouse,
  'Minimal Techno' => l10n.createGenreMinimalTechno,
  '1960s French Yé-yé Pop' => l10n.createGenreFrenchYeyePop,
  'Chillout' => l10n.createGenreChillout,
  'J-pop Indie Pop' => l10n.createGenreJPopIndiePop,
  'Chiptune' => l10n.createGenreChiptune,
  'Disco Funk' => l10n.createGenreDiscoFunk,
  'Reggaeton' => l10n.createGenreReggaeton,
  'Cumbia' => l10n.createGenreCumbia,
  'Latin Jazz' => l10n.createGenreLatinJazz,
  'Bhangra' => l10n.createGenreBhangra,
  'Indian Classical' => l10n.createGenreIndianClassical,
  'Lo-Fi Hip Hop' => l10n.createGenreLofiHipHop,
  _ => genre,
};

String sectionName(AppLocalizations l10n, String label) =>
    switch (label.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '')) {
      'intro' => l10n.sectionIntro,
      'verse' || 'verse1' || 'verse2' || 'verse3' => l10n.sectionVerse,
      'prechorus' => l10n.sectionPreChorus,
      'chorus' || 'refrain' => l10n.sectionChorus,
      'bridge' => l10n.sectionBridge,
      'outro' => l10n.sectionOutro,
      'hook' => l10n.sectionHook,
      _ => label,
    };

String paletteName(AppLocalizations l10n, ArtPalette palette) =>
    switch (palette) {
      ArtPalette.terracotta => l10n.paletteTerracotta,
      ArtPalette.sand => l10n.paletteSand,
      ArtPalette.olive => l10n.paletteOlive,
      ArtPalette.navy => l10n.paletteNavy,
    };
