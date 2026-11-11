import 'package:flutter/material.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import 'composer_model.dart';

/// Localized names + glyphs for the creation vocabulary (occasions, festivals,
/// countries, lyric languages, preflight issues).

IconData occasionIcon(Occasion occasion) => switch (occasion) {
  Occasion.birthday => Icons.cake_outlined,
  Occasion.anniversary => Icons.favorite_border_rounded,
  Occasion.confession => Icons.volunteer_activism_outlined,
  Occasion.wedding => Icons.local_florist_outlined,
  Occasion.memorial => Icons.local_fire_department_outlined,
  Occasion.festival => Icons.celebration_outlined,
  Occasion.brand => Icons.campaign_outlined,
  Occasion.soundtrack => Icons.movie_creation_outlined,
  Occasion.custom => Icons.auto_awesome_outlined,
};

String occasionName(AppLocalizations l10n, Occasion occasion) =>
    switch (occasion) {
      Occasion.birthday => l10n.occasionBirthday,
      Occasion.anniversary => l10n.occasionAnniversary,
      Occasion.confession => l10n.occasionConfession,
      Occasion.wedding => l10n.occasionWedding,
      Occasion.memorial => l10n.occasionMemorial,
      Occasion.festival => l10n.occasionFestival,
      Occasion.brand => l10n.occasionBrand,
      Occasion.soundtrack => l10n.occasionSoundtrack,
      Occasion.custom => l10n.templateCustom,
    };

String occasionHint(AppLocalizations l10n, Occasion occasion) =>
    switch (occasion) {
      Occasion.birthday => l10n.occasionBirthdayHint,
      Occasion.anniversary => l10n.occasionAnniversaryHint,
      Occasion.confession => l10n.occasionConfessionHint,
      Occasion.wedding => l10n.occasionWeddingHint,
      Occasion.memorial => l10n.occasionMemorialHint,
      Occasion.festival => l10n.occasionFestivalHint,
      Occasion.brand => l10n.occasionBrandHint,
      Occasion.soundtrack => l10n.occasionSoundtrackHint,
      Occasion.custom => l10n.composerSourceMusicHint,
    };

String festivalName(AppLocalizations l10n, Festival festival) =>
    switch (festival) {
      Festival.newYear => l10n.festivalNewYear,
      Festival.thanksgiving => l10n.festivalThanksgiving,
      Festival.diwali => l10n.festivalDiwali,
      Festival.carnival => l10n.festivalCarnival,
      Festival.eid => l10n.festivalEid,
      Festival.lunarNewYear => l10n.festivalLunarNewYear,
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

String languageName(AppLocalizations l10n, LyricLanguage language) =>
    switch (language) {
      LyricLanguage.en => l10n.languageEn,
      LyricLanguage.fr => l10n.languageFr,
      LyricLanguage.de => l10n.languageDe,
      LyricLanguage.ja => l10n.languageJa,
      LyricLanguage.ko => l10n.languageKo,
      LyricLanguage.ptBR => l10n.languagePtBR,
      LyricLanguage.esMX => l10n.languageEsMX,
      LyricLanguage.hi => l10n.languageHi,
      LyricLanguage.id => l10n.languageId,
      LyricLanguage.vi => l10n.languageVi,
      LyricLanguage.tr => l10n.languageTr,
      LyricLanguage.zhHans => l10n.languageZhHans,
      LyricLanguage.zhHant => l10n.languageZhHant,
    };

String preflightIssueText(
  AppLocalizations l10n,
  PreflightIssue issue, {
  int? limit,
}) => switch (issue) {
  PreflightIssue.promptTooLong => l10n.issuePromptTooLong(Preflight.maxPrompt),
  PreflightIssue.recipientArtistName => l10n.issueRecipientArtistName,
  PreflightIssue.recipientMissing => l10n.issueRecipientMissing,
  PreflightIssue.recipientTooLong => l10n.issueRecipientTooLong,
  PreflightIssue.briefMissing => l10n.issueBriefMissing,
  PreflightIssue.keywordTooLong => l10n.issueKeywordTooLong,
  PreflightIssue.tooManyKeywords => l10n.issueTooManyKeywords,
  PreflightIssue.artistName => l10n.issueArtistName,
  PreflightIssue.styleImitation => l10n.issueStyleImitation,
  PreflightIssue.lyricsTooLong => l10n.issueLyricsTooLong(
    limit ?? LyricsFormatter.latinLimit,
  ),
  PreflightIssue.lyricsNotOriginal => l10n.issueLyricsNotOriginal,
  PreflightIssue.lyricsOwnershipUnconfirmed => l10n.issueLyricsOwnership,
  PreflightIssue.tooManyPhotos => l10n.issueTooManyPhotos,
};

String templateName(AppLocalizations l10n, SongTemplate template) =>
    switch (template) {
      SongTemplate.birthdayWish => l10n.templateBirthdayWish,
      SongTemplate.birthdayParty => l10n.templateBirthdayParty,
      SongTemplate.loveStory => l10n.templateLoveStory,
      SongTemplate.thankAFriend => l10n.templateThankAFriend,
      SongTemplate.partyInvite => l10n.templatePartyInvite,
      SongTemplate.wedding => l10n.templateWedding,
      SongTemplate.inMemory => l10n.templateInMemory,
      SongTemplate.festival => l10n.templateFestival,
      SongTemplate.ringtone => l10n.templateRingtone,
      SongTemplate.teamAnthem => l10n.templateTeamAnthem,
      SongTemplate.sportsRecap => l10n.templateSportsRecap,
      SongTemplate.rapBattle => l10n.templateRapBattle,
      SongTemplate.comedy => l10n.templateComedy,
      SongTemplate.petAnthem => l10n.templatePetAnthem,
      SongTemplate.hometown => l10n.templateHometown,
      SongTemplate.businessPromo => l10n.templateBusinessPromo,
    };

String templateHint(AppLocalizations l10n, SongTemplate template) =>
    switch (template) {
      SongTemplate.birthdayWish => l10n.templateBirthdayWishHint,
      SongTemplate.birthdayParty => l10n.templateBirthdayPartyHint,
      SongTemplate.loveStory => l10n.templateLoveStoryHint,
      SongTemplate.thankAFriend => l10n.templateThankAFriendHint,
      SongTemplate.partyInvite => l10n.templatePartyInviteHint,
      SongTemplate.wedding => l10n.templateWeddingHint,
      SongTemplate.inMemory => l10n.templateInMemoryHint,
      SongTemplate.festival => l10n.templateFestivalHint,
      SongTemplate.ringtone => l10n.templateRingtoneHint,
      SongTemplate.teamAnthem => l10n.templateTeamAnthemHint,
      SongTemplate.sportsRecap => l10n.templateSportsRecapHint,
      SongTemplate.rapBattle => l10n.templateRapBattleHint,
      SongTemplate.comedy => l10n.templateComedyHint,
      SongTemplate.petAnthem => l10n.templatePetAnthemHint,
      SongTemplate.hometown => l10n.templateHometownHint,
      SongTemplate.businessPromo => l10n.templateBusinessPromoHint,
    };

/// The occasion a work or draft is filed under: its template's name, else the
/// occasion ("Just because" for a free-form prompt in the library).
String workKindName(
  AppLocalizations l10n, {
  SongTemplate? template,
  required Occasion occasion,
}) => template != null
    ? templateName(l10n, template)
    : occasionName(l10n, occasion);

String vocalsName(AppLocalizations l10n, Vocals vocals) => switch (vocals) {
  Vocals.custom => l10n.vocalsCustom,
  Vocals.vocals => l10n.vocalsOn,
  Vocals.instrumental => l10n.vocalsInstrumental,
};

IconData vocalsIcon(Vocals vocals) => switch (vocals) {
  Vocals.custom => Icons.auto_fix_high_outlined,
  Vocals.vocals => Icons.record_voice_over_outlined,
  Vocals.instrumental => Icons.mic_off_outlined,
};

String lengthName(AppLocalizations l10n, SongModel model) =>
    model == SongModel.clip ? l10n.lengthShort : l10n.lengthStandard;

/// The composer's primary action in words (ADR-0035): the verb by length and
/// name, the cost only as the ledger shows it.
String createActionLabel(AppLocalizations l10n, CreateAction action) {
  final cost = action.cost.name;
  return switch (action.kind) {
    CreateActionKind.preview => l10n.createPreviewLabel(cost),
    CreateActionKind.previewFor => l10n.createPreviewForLabel(
      action.name ?? '',
      cost,
    ),
    CreateActionKind.fullSong => l10n.createFullSongLabel(cost),
  };
}

/// One value of the composer's summary row (ADR-0033).
String summaryPartName(
  AppLocalizations l10n,
  SummaryPart part,
  CreationDraft draft,
) => switch (part) {
  SummaryPart.preview => l10n.lengthPreview,
  SummaryPart.fullSong => l10n.lengthFull,
  SummaryPart.songAndChorus => l10n.lengthSongAndChorus,
  SummaryPart.vocalsOn => l10n.vocalsOn,
  SummaryPart.instrumental => l10n.vocalsInstrumental,
  SummaryPart.anyVocals => l10n.composerSummaryAnyVocals,
  SummaryPart.genre => genreName(l10n, draft.genre),
  SummaryPart.anyGenre => l10n.composerSummaryAnyGenre,
  SummaryPart.ownLyrics => l10n.composerSummaryLyrics,
  SummaryPart.video => l10n.composerSummaryVideo,
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
