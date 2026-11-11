import 'package:flutter/widgets.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import 'create_labels.dart';

/// The copy of an entry in the UI language (contract 02 v2.1 §1, ADR-0032).
/// The server sends English and Simplified Chinese; every other language maps
/// the entry's **slug** to an ARB string (the 16 templates' names through their
/// own template strings), and falls back to English for a slug this build does
/// not know yet (a new server entry).

/// The name on a create-home tile: an offline template its own translated
/// name, a server entry the server's copy.
String ideaName(BuildContext context, Idea idea) {
  final template = idea.template;
  return template != null
      ? templateName(AppLocalizations.of(context), template)
      : inspirationName(context, idea.inspiration!);
}

/// The tile's style line, which assistive technology reads with the name. An
/// offline template uses its own translated hint. Never sent to the server.
String ideaStyle(BuildContext context, Idea idea) {
  final inspiration = idea.inspiration;
  return inspiration == null
      ? templateHint(AppLocalizations.of(context), idea.template!)
      : inspirationStyle(context, inspiration);
}

/// The slugs of the entries that stand on their own (the 16 templates' entries
/// are named by their template strings).
const List<String> _knownSlugs = [
  'soundscape',
  'background_music',
  'memorize_something',
  'text_messages',
  'intro_music',
  'montage',
  'say_it_with_a_track',
  'brand_jingle',
  'streaming',
  'speech_to_track',
  'happy_birthday',
  'friend_appreciation',
  'birthday_roast',
  'ode_to_your_pet',
  'hometown_tribute',
  'weather_report',
];

/// The names the create-home grid reserves room for before the server has
/// answered, in the UI language: its column count is then decided on the first
/// frame and does not change when the list arrives. Simplified Chinese shows
/// the server's own short copy, which needs no reservation.
List<String> knownInspirationNames(BuildContext context) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'zh' && locale.scriptCode != 'Hant')
    return const [];
  final l10n = AppLocalizations.of(context);
  return [for (final slug in _knownSlugs) ?_localName(l10n, slug)];
}

/// The placeholder of the prompt field once the card is picked (contract 02
/// v2.1 `composer.hint`): the server's English or Simplified Chinese copy;
/// other languages show the English hint. Never sent to the server.
String inspirationHint(BuildContext context, InspirationComposer composer) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'zh' && locale.scriptCode != 'Hant')
    return composer.hint.zh;
  return composer.hint.en;
}

/// The entry's name.
String inspirationName(BuildContext context, Inspiration inspiration) =>
    _resolve(context, inspiration.slug, inspiration.name, _localName);

/// The style it suggests.
String inspirationStyle(BuildContext context, Inspiration inspiration) =>
    _resolve(context, inspiration.slug, inspiration.style, _localStyle);

String _resolve(
  BuildContext context,
  String slug,
  LocalizedText text,
  String? Function(AppLocalizations, String slug) local,
) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'en') return text.en;
  // `zh` from the server is Simplified; Traditional has its own translation.
  if (locale.languageCode == 'zh' && locale.scriptCode != 'Hant')
    return text.zh;
  return local(AppLocalizations.of(context), slug) ?? text.en;
}

String? _localName(AppLocalizations l10n, String slug) {
  final template = SongTemplate.fromId(slug);
  if (template != null) return templateName(l10n, template);
  return switch (slug) {
    'soundscape' => l10n.inspirationNameSoundscape,
    'background_music' => l10n.inspirationNameBackgroundMusic,
    'memorize_something' => l10n.inspirationNameMemorizeSomething,
    'text_messages' => l10n.inspirationNameTextMessages,
    'intro_music' => l10n.inspirationNameIntroMusic,
    'montage' => l10n.inspirationNameMontage,
    'say_it_with_a_track' => l10n.inspirationNameSayItWithATrack,
    'brand_jingle' => l10n.inspirationNameBrandJingle,
    'streaming' => l10n.inspirationNameStreaming,
    'speech_to_track' => l10n.inspirationNameSpeechToTrack,
    'happy_birthday' => l10n.inspirationNameHappyBirthday,
    'friend_appreciation' => l10n.inspirationNameFriendAppreciation,
    'birthday_roast' => l10n.inspirationNameBirthdayRoast,
    'ode_to_your_pet' => l10n.inspirationNameOdeToYourPet,
    'hometown_tribute' => l10n.inspirationNameHometownTribute,
    'weather_report' => l10n.inspirationNameWeatherReport,
    _ => null,
  };
}

String? _localStyle(AppLocalizations l10n, String slug) => switch (slug) {
  'soundscape' => l10n.inspirationStyleSoundscape,
  'background_music' => l10n.inspirationStyleBackgroundMusic,
  'memorize_something' => l10n.inspirationStyleMemorizeSomething,
  'text_messages' => l10n.inspirationStyleTextMessages,
  'intro_music' => l10n.inspirationStyleIntroMusic,
  'montage' => l10n.inspirationStyleMontage,
  'say_it_with_a_track' => l10n.inspirationStyleSayItWithATrack,
  'brand_jingle' => l10n.inspirationStyleBrandJingle,
  'ringtone' => l10n.inspirationStyleRingtone,
  'streaming' => l10n.inspirationStyleStreaming,
  'speech_to_track' => l10n.inspirationStyleSpeechToTrack,
  'rap_battle' => l10n.inspirationStyleRapBattle,
  'comedy' => l10n.inspirationStyleComedy,
  'team_anthem' => l10n.inspirationStyleTeamAnthem,
  'sports_recap' => l10n.inspirationStyleSportsRecap,
  'party_invite' => l10n.inspirationStylePartyInvite,
  'happy_birthday' => l10n.inspirationStyleHappyBirthday,
  'friend_appreciation' => l10n.inspirationStyleFriendAppreciation,
  'love_story' => l10n.inspirationStyleLoveStory,
  'birthday_roast' => l10n.inspirationStyleBirthdayRoast,
  'ode_to_your_pet' => l10n.inspirationStyleOdeToYourPet,
  'hometown_tribute' => l10n.inspirationStyleHometownTribute,
  'weather_report' => l10n.inspirationStyleWeatherReport,
  'business_promo' => l10n.inspirationStyleBusinessPromo,
  'birthday_wish' => l10n.inspirationStyleBirthdayWish,
  'birthday_party' => l10n.inspirationStyleBirthdayParty,
  'thank_a_friend' => l10n.inspirationStyleThankAFriend,
  'wedding' => l10n.inspirationStyleWedding,
  'in_memory' => l10n.inspirationStyleInMemory,
  'festival' => l10n.inspirationStyleFestival,
  'pet_anthem' => l10n.inspirationStylePetAnthem,
  'hometown' => l10n.inspirationStyleHometown,
  _ => null,
};
