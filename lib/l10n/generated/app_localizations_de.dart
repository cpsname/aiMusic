// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get commonRetry => 'Nochmal';

  @override
  String get commonCancel => 'Abbruch';

  @override
  String get startupLoading => 'Einstimmen…';

  @override
  String get commonErrorTitle => 'Etwas ist schiefgelaufen';

  @override
  String get updateRequiredTitle => 'Update erforderlich';

  @override
  String get updateRequiredMessage =>
      'Um fortzufahren, ist eine neue Version erforderlich.';

  @override
  String get updateNow => 'Jetzt updaten';

  @override
  String get maintenanceTitle => 'Geplante Wartung';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Voraussichtlich wieder verfügbar in etwa $minutesString Min.';
  }

  @override
  String get featureUnavailable =>
      'Diese Funktion ist vorübergehend nicht verfügbar.';

  @override
  String get navProfile => 'Profil';

  @override
  String get navStore => 'Store';

  @override
  String get navUpload => 'Upload';

  @override
  String get uploadTitle => 'Uploads';

  @override
  String get uploadSubtitle =>
      'Vorsignierter Direkt-Upload zu R2 mit Hashing, sofortiger Deduplizierung und Fortschrittsanzeige.';

  @override
  String get uploadPick => 'Bild auswählen & hochladen';

  @override
  String get uploadAgain => 'Weitere Datei laden';

  @override
  String get uploadPhaseHashing => 'Hashen…';

  @override
  String get uploadPhaseSigning => 'Upload-Ticket wird angefordert …';

  @override
  String uploadPhaseUploading(String percent) {
    return 'Upload: $percent';
  }

  @override
  String get uploadPhaseFinalizing => 'Abschließen…';

  @override
  String get uploadDone => 'Hochgeladen.';

  @override
  String get uploadDedup =>
      'Sofort erledigt: Diese Datei war bereits auf dem Server.';

  @override
  String get uploadOpenLink => 'Datei öffnen';

  @override
  String get uploadFailed => 'Upload gescheitert.';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Die Datei ist zu groß (max. $limitString MB).';
  }

  @override
  String get uploadUnsupportedType => 'Nicht unterstützter Dateityp.';

  @override
  String get profileGuestTitle => 'Gast';

  @override
  String get profileGuestSubtitle =>
      'Melde dich an, um deine Käufe auf allen Geräten zu behalten.';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get profileBalanceLabel => 'Guthaben';

  @override
  String get profileAccountId => 'Konto-ID';

  @override
  String get profileFeaturesLabel => 'Aktive Vorteile';

  @override
  String get profileNoFeatures => 'Noch keine aktiven Vorteile.';

  @override
  String get profileSubscriptionLabel => 'Abo';

  @override
  String get profileManageSubscription => 'Abo verwalten';

  @override
  String get subscriptionActive => 'Aktiv';

  @override
  String get subscriptionInactive => 'Keins';

  @override
  String get profileDeleteAccount => 'Konto löschen';

  @override
  String get deleteAccountTitle => 'Dieses Konto löschen?';

  @override
  String get deleteAccountMessage =>
      'Dies kann nicht rückgängig gemacht werden: Dieses Konto samt Guthaben und Vorteilen ist danach dauerhaft nicht mehr erreichbar, und ein neues Konto wird erstellt. Ein aktives App-Store-Abo wird durch das Löschen des Kontos nicht gekündigt – verwalte es in deinen App-Store-Einstellungen oder verknüpfe es später über „Käufe wiederherstellen“ erneut.';

  @override
  String get deleteAccountConfirm => 'Löschen';

  @override
  String get deleteAccountWorking => 'Konto wird gelöscht …';

  @override
  String get deleteAccountDone => 'Konto gelöscht.';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Mitglied seit $dateString';
  }

  @override
  String get loginTitle => 'Anmelden';

  @override
  String get loginUsername => 'Nutzername';

  @override
  String get loginPassword => 'Passwort';

  @override
  String get loginSubmit => 'Anmelden';

  @override
  String get paywallTitle => 'Hol dir den ganzen Song';

  @override
  String get paywallSubtitle =>
      'Mach aus deiner Vorschau einen 2-minütigen Song mit Songtext – zum Herunterladen und Verwenden.';

  @override
  String get paywallRestore => 'Käufe wiederherstellen';

  @override
  String get paywallAutoRenewNotice =>
      'Die Zahlung wird bei Bestätigung über deinen Apple-Account abgerechnet. Abos verlängern sich automatisch zum selben Preis und für denselben Zeitraum, sofern sie nicht mindestens 24 Stunden vor Ende des aktuellen Zeitraums gekündigt werden. Ein kostenloser Probezeitraum geht an seinem Ende in ein kostenpflichtiges Abo über. Du kannst dein Abo jederzeit in den Einstellungen deines App-Store-Accounts verwalten oder kündigen.';

  @override
  String get paywallContinue => 'Weiter';

  @override
  String get paywallFreeTrial => 'Gratis testen';

  @override
  String get paywallOffer => 'Angebot';

  @override
  String get paywallManage => 'Verwalten';

  @override
  String get paywallTermsOfUse => 'AGB';

  @override
  String get paywallPrivacyPolicy => 'Datenschutz';

  @override
  String get paywallSubscriptionTerms => 'Abobedingungen';

  @override
  String get commonLinkError => 'Link lässt sich nicht öffnen.';

  @override
  String get commonError => 'Etwas ist schiefgelaufen.';

  @override
  String get commonNetworkError =>
      'Netzwerkfehler – überprüfe deine Verbindung und versuche es erneut.';

  @override
  String get commonOfflineError =>
      'Du scheinst offline zu sein. Überprüfe deine Verbindung und versuche es erneut.';

  @override
  String get networkErrorTitle => 'Verbindungsproblem';

  @override
  String get configErrorTitle => 'Problem mit der App-Konfiguration';

  @override
  String get configErrorMessage =>
      'Diese Version kann unseren Dienst nicht erreichen. Aktualisiere die App über den App Store oder installiere sie neu. Wenn das Problem weiterhin besteht, wende dich an den Support.';

  @override
  String get commonAuthError =>
      'Deine Sitzung ist abgelaufen – bitte melde dich erneut an.';

  @override
  String get paywallProductsErrorTitle => 'Produkte nicht geladen';

  @override
  String get paywallNoProducts => 'Derzeit sind keine Produkte verfügbar.';

  @override
  String get paywallPurchaseSuccess => 'Kauf abgeschlossen – viel Spaß!';

  @override
  String get paywallProcessing => 'Dein Kauf wird bearbeitet …';

  @override
  String get paywallVerifying => 'Dein Kauf wird überprüft …';

  @override
  String get paywallPurchaseFailed =>
      'Der Kauf konnte nicht abgeschlossen werden.';

  @override
  String get paywallRestoreStarted => 'Käufe werden wiederhergestellt…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Käufe wiederhergestellt.',
      one: '$countString Kauf wiederhergestellt.',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => 'Keine Käufe zum Wiederherstellen.';

  @override
  String get paywallDeferred =>
      'Warte auf Genehmigung – wir schließen den Kauf ab, sobald er genehmigt ist.';

  @override
  String get paywallAlreadySubscribed => 'Du hast bereits ein Abo.';

  @override
  String get paywallBillingRetry =>
      'Aktualisiere deine Zahlungsmethode, um dein Abo zu behalten.';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString Tage kostenlos testen';
  }

  @override
  String get cycleOneTime => 'einmalig';

  @override
  String get cycleWeekly => '/ Woche';

  @override
  String get cycleMonthly => '/ Monat';

  @override
  String get cycleQuarterly => '/ Quartal';

  @override
  String get cycleSemiAnnual => '/ 6 Monate';

  @override
  String get cycleAnnual => '/ Jahr';

  @override
  String get cycleLifetime => 'lebenslang';

  @override
  String get navCreate => 'Kreieren';

  @override
  String get navLibrary => 'Mediathek';

  @override
  String get navSettings => 'Optionen';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonBack => 'Zurück';

  @override
  String get createTitle => 'Für wen ist dieser Song?';

  @override
  String get occasionBirthday => 'Geburtstag';

  @override
  String get occasionBirthdayHint => 'Ein fröhlicher Song für den großen Tag';

  @override
  String get occasionAnniversary => 'Jahrestag';

  @override
  String get occasionAnniversaryHint => 'Feiert eure gemeinsame Geschichte';

  @override
  String get occasionConfession => 'Liebeserklärung';

  @override
  String get occasionConfessionHint => 'Sag, was dein Herz fühlt';

  @override
  String get occasionWedding => 'Hochzeit';

  @override
  String get occasionWeddingHint => 'Ein Song für euer Ja-Wort';

  @override
  String get occasionMemorial => 'Zum Gedenken';

  @override
  String get occasionMemorialHint => 'Ehre einen geliebten Menschen';

  @override
  String get occasionFestival => 'Feiertag';

  @override
  String get occasionFestivalHint => 'Herzliche Wünsche zur Festzeit';

  @override
  String get occasionBrand => 'Marken-Jingle';

  @override
  String get occasionBrandHint => 'Ein Ohrwurm für deine Marke';

  @override
  String get occasionSoundtrack => 'Video-Soundtrack';

  @override
  String get occasionSoundtrackHint => 'Musik für deine Geschichte';

  @override
  String get festivalNewYear => 'Neujahr';

  @override
  String get festivalThanksgiving => 'Thanksgiving';

  @override
  String get festivalDiwali => 'Diwali';

  @override
  String get festivalCarnival => 'Karneval';

  @override
  String get festivalEid => 'Eid';

  @override
  String get festivalLunarNewYear => 'Mondneujahr';

  @override
  String get regionTitle => 'Wo soll der Song laufen?';

  @override
  String get regionSearchHint => 'Land suchen';

  @override
  String get regionLanguageSheetTitle => 'Sprache des Songtexts';

  @override
  String get countryUS => 'Vereinigte Staaten';

  @override
  String get countryGB => 'Ver. Königreich';

  @override
  String get countryCA => 'Kanada';

  @override
  String get countryAU => 'Australien';

  @override
  String get countryDE => 'Deutschl.';

  @override
  String get countryFR => 'Frankr.';

  @override
  String get countryJP => 'Japan';

  @override
  String get countryKR => 'Südkorea';

  @override
  String get countryBR => 'Bras.';

  @override
  String get countryMX => 'Mexiko';

  @override
  String get countryIN => 'Indien';

  @override
  String get countryID => 'Indonesien';

  @override
  String get countryVN => 'Vietnam';

  @override
  String get countryTR => 'Türkei';

  @override
  String get languageEn => 'Englisch';

  @override
  String get languageFr => 'Franz.';

  @override
  String get languageDe => 'Deutsch';

  @override
  String get languageJa => 'Japanisch';

  @override
  String get languageKo => 'Korean.';

  @override
  String get languagePtBR => 'Portugiesisch (Brasilien)';

  @override
  String get languageEsMX => 'Spanisch (Mexiko)';

  @override
  String get languageHi => 'Hindi';

  @override
  String get languageId => 'Indonesisch';

  @override
  String get languageVi => 'Vietnamesisch';

  @override
  String get languageTr => 'Türkisch';

  @override
  String get languageZhHans => 'Chinesisch (vereinfacht)';

  @override
  String get languageZhHant => 'Chinesisch (traditionell)';

  @override
  String get inputNameLabel => 'Name';

  @override
  String get inputNameOptionalLabel => 'Name (optional)';

  @override
  String get inputNameHint => 'z. B. Alex';

  @override
  String get inputKeywordsLabel => 'Drei Wörter über die Person';

  @override
  String get inputLyricsHint => '[Verse] …\n[Chorus] …';

  @override
  String lyricsCounter(int count, int limit) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '$countString / $limitString';
  }

  @override
  String get inputLyricsOwnership =>
      'Dieser Songtext stammt von mir oder ich darf ihn verwenden';

  @override
  String get issueRecipientMissing => 'Gib den Namen ein.';

  @override
  String get issueRecipientTooLong =>
      'Namen dürfen höchstens 24 Zeichen lang sein.';

  @override
  String get issueBriefMissing =>
      'Erzähl uns von dem Song – ein paar Worte, Songtext oder Fotos.';

  @override
  String get issueDescriptionMissing =>
      'Diese Idee braucht deine Worte – schreib einen Satz zum Song.';

  @override
  String get generatingBackToEdit => 'Bearbeiten';

  @override
  String get issueKeywordTooLong =>
      'Jedes Wort darf höchstens 20 Zeichen lang sein.';

  @override
  String get issueTooManyKeywords => 'Nutze bis zu drei Wörter.';

  @override
  String get issueArtistName =>
      'Künstlernamen sind nicht erlaubt – beschreibe stattdessen das Gefühl.';

  @override
  String get issueStyleImitation =>
      'Wir können keine Sänger oder Bands imitieren. Beschreibe stattdessen die Stimmung.';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Songtexte dürfen höchstens $limitString Zeichen lang sein.';
  }

  @override
  String get issueLyricsNotOriginal =>
      'Dieser Songtext ähnelt einem existierenden Song. Bitte schreib deinen eigenen.';

  @override
  String get issueLyricsOwnership =>
      'Bestätige, dass du den Songtext verwenden darfst.';

  @override
  String get issueTooManyPhotos => 'Wähle bis zu 10 Fotos aus.';

  @override
  String get photosTitle => 'Wähle ein paar Fotos';

  @override
  String photosCount(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '$countString / $maxString';
  }

  @override
  String get photosPrivacy =>
      'Fotos werden nur einmal zum Schreiben des Songs verwendet und innerhalb von 24 Stunden von unseren Servern gelöscht.';

  @override
  String get photosAdd => 'Fotos ergänzen';

  @override
  String get photosCreate => 'Aus Fotos erstellen';

  @override
  String get photosEmpty => 'Wähle 1–10 Fotos von dem Moment.';

  @override
  String get generatingStepPolishing =>
      'Deine Worte werden auf diesem iPhone verfeinert …';

  @override
  String get generatingStepUploading => 'Deine Fotos werden gesendet…';

  @override
  String get generatingStepSubmitting => 'Wird ans Studio gesendet …';

  @override
  String get errorSafetyBlocked =>
      'Diesen Song können wir nicht erstellen – versuch es mit anderen Wörtern und ohne Künstlernamen.';

  @override
  String get errorQuotaExhausted =>
      'Monatskontingent verbraucht. Hol ein Paket oder wechsle den Tarif.';

  @override
  String get errorUpstreamTimeout =>
      'Das dauert länger als üblich. Wir versuchen es weiter und benachrichtigen dich.';

  @override
  String get errorUpstreamRateLimited =>
      'Gerade entstehen sehr viele Songs. Deiner ist in der Warteschlange.';

  @override
  String get errorAttestFailed =>
      'Bitte aktualisiere Songlet über den App Store.';

  @override
  String get errorImageRejected =>
      'Ein Foto ist nicht nutzbar. Wähle ein anderes.';

  @override
  String get errorNetworkOffline =>
      'Du bist offline. Deine Mediathek funktioniert weiterhin.';

  @override
  String get errorDownloadLocked =>
      'Dieser Song kann nicht heruntergeladen werden – der Kauf, mit dem er erstellt wurde, wurde erstattet oder dein Abo ist abgelaufen. Du kannst ihn weiterhin abspielen.';

  @override
  String get errorJobAlreadyFinished =>
      'Schon fertig – es gibt nichts abzubrechen.';

  @override
  String get errorMvSongNotReady =>
      'Dieser Song ist noch nicht bereit für ein Video.';

  @override
  String get errorMvSongTooLong =>
      'Dieser Song ist zu lang für ein ganzes Video – probier ein Refrain-Video.';

  @override
  String get errorMvSongExpired =>
      'Dieser Song ist abgelaufen. Erstelle ihn erneut, um ein Video zu machen.';

  @override
  String get errorMvNotFound => 'Dieses Video ist nicht mehr verfügbar.';

  @override
  String get errorMvPhotosExpired =>
      'Diese Fotos sind abgelaufen – wähle sie erneut aus.';

  @override
  String get errorMvRenderFailed =>
      'Video nicht fertig. Credits sind zurück – versuch es erneut.';

  @override
  String get mvHubTitle => 'Video erstellen';

  @override
  String mvHubSubtitle(String title) {
    return 'Mach aus „$title“ ein Musikvideo.';
  }

  @override
  String get mvLevelLyricVideo => 'Lyric-Video';

  @override
  String get mvLevelLyricHint => 'Eine feste Szene mit deinem Text';

  @override
  String get mvLevelChorus => 'Refrain-Video';

  @override
  String get mvLevelChorusHint => '30 Sekunden deines Refrains, von KI gedreht';

  @override
  String get mvLevelFull => 'Video zum ganzen Song';

  @override
  String get mvLevelFullHint => 'Der ganze Song, Szene für Szene';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString Credits',
      one: '$creditsString Credit',
    );
    return '$_temp0';
  }

  @override
  String mvAvailableCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: 'Du hast $creditsString Credits',
      one: 'Du hast $creditsString Credit',
    );
    return '$_temp0';
  }

  @override
  String mvGapCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString Credits fehlen',
      one: '$creditsString Credit fehlt',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => 'Preis wird geprüft …';

  @override
  String get mvOptionsHeader => 'Optionen';

  @override
  String get mvAspectLabel => 'Format';

  @override
  String get mvAspectPortrait => 'Hochformat';

  @override
  String get mvAspectLandscape => 'Querformat';

  @override
  String get mvAspectSquare => 'Quadrat';

  @override
  String get mvQualityLabel => 'Qualität';

  @override
  String get mvQualityStandard => 'Standard';

  @override
  String get mvQualityHigh => 'Hoch';

  @override
  String get mvSubtitlesLabel => 'Text im Bild';

  @override
  String get mvPhotosLabel => 'Referenzfotos';

  @override
  String get mvPhotosHint =>
      'Für Stimmung und Farben – Gesichter werden nicht verwendet';

  @override
  String mvPhotosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Fotos',
      one: '$countString Foto',
    );
    return '$_temp0';
  }

  @override
  String get mvChorusLabel => 'Refrain';

  @override
  String get mvChorusAuto => 'Automatisch gefunden';

  @override
  String get mvChorusCustom => 'Stelle selbst wählen';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => 'Video machen';

  @override
  String get mvBuyPack => 'Paket holen und erstellen';

  @override
  String get mvSongLocked => 'Dein Song ist für das Video gesichert.';

  @override
  String get mvGeneratingTitle => 'Dein Video entsteht …';

  @override
  String get mvStageQueued => 'Wartet auf den Start';

  @override
  String get mvStageSlicing => 'Momente werden gewählt';

  @override
  String get mvStageStoryboarding => 'Storyboard wird geschrieben';

  @override
  String get mvStageKeyframing => 'Szenen werden gemalt';

  @override
  String get mvStageRendering => 'Szenen werden gedreht';

  @override
  String get mvStageAssembling => 'Wird zusammengeschnitten';

  @override
  String get mvStageDone => 'Fertig';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Szene $doneString von $totalString';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Meist etwa $minutesString Minuten';
  }

  @override
  String get mvCancelRequested => 'Wird nach der aktuellen Szene gestoppt …';

  @override
  String get mvCancelTitle => 'Dieses Video stoppen?';

  @override
  String get mvCancelQueued =>
      'Es hat noch nicht begonnen, es wird nichts verbraucht.';

  @override
  String get mvCancelStarted =>
      'Es hat schon begonnen. Fertige Szenen werden berechnet, der Rest kommt zurück.';

  @override
  String get mvCancelConfirm => 'Video stoppen';

  @override
  String get mvCancelled => 'Video gestoppt';

  @override
  String get mvCancelledRefunded => 'Video gestoppt – nichts verbraucht';

  @override
  String get mvNothing => 'Gerade wird kein Video erstellt.';

  @override
  String get mvQuotaTitle => 'Nicht genug Credits';

  @override
  String get mvAiLabelBurnedIn =>
      'KI-generiert – das Abzeichen ist Teil des Videos';

  @override
  String get mvSave => 'In Fotos sichern';

  @override
  String get mvSaveFiles => 'In Dateien sichern';

  @override
  String get mvShareText => 'Ich habe dieses Musikvideo mit Songlet gemacht 🎬';

  @override
  String get mvMissing => 'Dieses Video ist nicht mehr auf diesem Gerät.';

  @override
  String get mvDeleteTitle => 'Dieses Video löschen?';

  @override
  String get mvDeleteBody => 'Es wird von diesem Gerät entfernt.';

  @override
  String get mvDeleted => 'Video gelöscht';

  @override
  String get mvProvenance =>
      'Erstellt mit Google Lyria 3 und KI-Videomodellen · KI-generiert';

  @override
  String get detailVideos => 'Videos';

  @override
  String get detailMakeVideo => 'Video erstellen';

  @override
  String get mvStatusReady => 'Fertig';

  @override
  String get mvStatusPending => 'Entsteht…';

  @override
  String get mvStatusFailed => 'Nicht fertig';

  @override
  String get mvPackTitle => 'Musikvideo';

  @override
  String get mvPackChorusSubtitle => 'Ein Refrain-Video';

  @override
  String get mvPackFullSubtitle => 'Ein Video zum ganzen Song';

  @override
  String get paywallMvHeroTitle => 'Mach ein Video daraus';

  @override
  String get paywallMvHeroSubtitle =>
      'Credits für ein Musikvideo zu deinem Song – zum Sichern und Teilen.';

  @override
  String get playerAiGenerated => 'KI-generiert';

  @override
  String get playerLoop => 'Loop';

  @override
  String get playerPlay => 'Start';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerPreviewLabel => '30-Sekunden-Vorschau';

  @override
  String playerTitleFor(String name) {
    return 'Für $name';
  }

  @override
  String get downloadSaved => 'In Dateien gesichert.';

  @override
  String get shareComposing => 'Deine Teilen-Karte entsteht…';

  @override
  String get shareFailed => 'Teilen-Karte konnte nicht entstehen.';

  @override
  String get shareText => 'Ich habe diesen Song mit Songlet gemacht 🎵';

  @override
  String get paywallBestValue => 'Bestes Angebot';

  @override
  String get paywallStartTrial => 'Kostenlos testen';

  @override
  String get paywallClose => 'Schließen';

  @override
  String get paywallSeePlans => 'Abos ansehen';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Dein Abo ist aktiv – noch $countString ganze Songs in diesem Zeitraum.',
      one:
          'Dein Abo ist aktiv – noch $countString ganzer Song in diesem Zeitraum.',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => 'Hier findest du bald deine Songs.';

  @override
  String get libraryEmptyAction => 'Erstelle deinen ersten Song';

  @override
  String get libraryPending => 'Komponieren…';

  @override
  String get libraryPreviewBadge => 'Vorschau';

  @override
  String get librarySongBadge => 'Ganzer Song';

  @override
  String get settingsTitle => 'Optionen';

  @override
  String get settingsPlan => 'Dein Tarif';

  @override
  String get settingsPlanUnavailable =>
      'Tarif nicht geladen. Zieh später nach unten, um es neu zu versuchen.';

  @override
  String get tierFree => 'Kein Abo';

  @override
  String get tierPack => 'Song-Pakete';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $countString ganze Songs',
      one: 'Noch $countString ganzer Song',
    );
    return '$_temp0';
  }

  @override
  String settingsClipsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $countString Vorschauen',
      one: 'Noch $countString Vorschau',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Neu ab $dateString';
  }

  @override
  String get settingsUpgrade => 'Upgrade';

  @override
  String get appTagline => 'Songs für die Menschen, die du liebst';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonDone => 'OK';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonMore => 'Mehr';

  @override
  String get commonCopy => 'Kopieren';

  @override
  String get commonCopied => 'Kopiert';

  @override
  String get commonNotNow => 'Später';

  @override
  String get commonLearnMore => 'Mehr erfahren';

  @override
  String get commonSeeAll => 'Alle';

  @override
  String get commonKeepGoing => 'Weitermachen';

  @override
  String get composerHint => 'Beschreib deinen Wunschsong';

  @override
  String get composerAddPhotos => 'Fotos ergänzen';

  @override
  String get composerSourceMusicHint => 'Mit eigenen Worten beschreiben';

  @override
  String get composerDictate => 'Diktieren';

  @override
  String get composerStopDictation => 'Diktat beenden';

  @override
  String get lengthPreview => 'Vorschau';

  @override
  String get lengthFull => 'Ganzer Song';

  @override
  String get paramLength => 'Länge';

  @override
  String get paramVocals => 'Gesang';

  @override
  String get paramGenre => 'Genre';

  @override
  String templatePlaySample(String name) {
    return 'Hörprobe von $name abspielen';
  }

  @override
  String get templatePauseSample => 'Hörprobe pausieren';

  @override
  String get lengthShort => 'Kurz';

  @override
  String get lengthShortHint => '30-Sekunden-Vorschau';

  @override
  String get lengthStandard => 'Standard';

  @override
  String get lengthStandardHint => 'etwa 2 Minuten, Pro';

  @override
  String get vocalsCustom => 'Eigene';

  @override
  String get vocalsCustomHint => 'nach deiner Beschreibung';

  @override
  String get vocalsCustomDetail => 'Der Gesangsstil folgt deiner Beschreibung.';

  @override
  String get vocalsOn => 'Mit Gesang';

  @override
  String get vocalsInstrumental => 'Instrumental';

  @override
  String vocalsLyricsIn(String language) {
    return 'Songtext auf $language';
  }

  @override
  String get genreCustom => 'Eigene';

  @override
  String get genreCustomHint => 'nach deiner Beschreibung';

  @override
  String genrePopularIn(String country) {
    return 'Beliebt in $country';
  }

  @override
  String get genreAll => 'Alle Genres';

  @override
  String get regionHelper =>
      'Ändert die 3 empfohlenen Genres und die Sprache des Songtexts';

  @override
  String regionLyricsRow(String language) {
    return 'Songtext-Sprache: $language';
  }

  @override
  String get regionNoMatch => 'Kein passendes Land';

  @override
  String get keywordAdd => 'Wort ergänzen';

  @override
  String keywordRemove(String word) {
    return '$word entfernen';
  }

  @override
  String get nameClear => 'Name löschen';

  @override
  String get lyricsOptional => 'Eigenen Songtext schreiben (optional)';

  @override
  String get issueRecipientArtistName => 'Künstlernamen sind nicht erlaubt.';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Halte die Beschreibung unter $limitString Zeichen.';
  }

  @override
  String get voiceRecording => 'Aufnehmen…';

  @override
  String get voiceStarting => 'Starten…';

  @override
  String get voiceListening => 'Sag, für wen es ist und was die Person liebt…';

  @override
  String get voiceOnDevice => 'Transkription auf dem Gerät';

  @override
  String get voicePermissionDenied =>
      'Erlaube Songlet in den Einstellungen Mikrofon und Spracherkennung, um zu diktieren.';

  @override
  String get voiceUnavailable =>
      'Diktieren ist für diese Sprache auf diesem Gerät nicht verfügbar.';

  @override
  String get voiceApplied => 'Aus deiner Stimme übernommen';

  @override
  String get photoRemove => 'Foto entfernen';

  @override
  String generatingTitleFor(String name) {
    return 'Der Song für $name entsteht …';
  }

  @override
  String get generatingTitleGeneric => 'Dein Song entsteht …';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Meist etwa $secondsString Sekunden';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => 'Fortschritt';

  @override
  String get generatingGlimpse => 'Ein Blick auf deinen Song';

  @override
  String get generatingCancelTitle => 'Diesen Song stoppen?';

  @override
  String get generatingCancelQueued =>
      'Er hat noch nicht begonnen und wird nicht auf dein Kontingent angerechnet.';

  @override
  String get generatingCancelStarted =>
      'Er hat bereits begonnen und wird auf dein Kontingent angerechnet.';

  @override
  String get generatingCancelConfirm => 'Abbrechen';

  @override
  String get generatingCancelled => 'Song abgebrochen';

  @override
  String get generatingCancelledRefunded =>
      'Song abgebrochen – nichts verbraucht';

  @override
  String get queueTitle => 'Gerade entstehen sehr viele Songs.';

  @override
  String get queueSubtitle => 'Dein Song wartet.';

  @override
  String get queuePosition => 'Position';

  @override
  String get queueWait => 'Wartezeit';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '≈ $minutesString Min.';
  }

  @override
  String get generatingNothing => 'Gerade entsteht kein Song.';

  @override
  String get previewGetFull => 'Vollen 2-Minuten-Song holen';

  @override
  String get previewShare => 'Vorschau teilen';

  @override
  String get previewAnother => 'Andere Version probieren (1 Vorschau)';

  @override
  String get playerPosition => 'Wiedergabeposition';

  @override
  String get playerPrevSection => 'Vorheriger Abschnitt';

  @override
  String get playerNextSection => 'Nächster Teil';

  @override
  String get playerShuffle => 'Abschnitte zufällig';

  @override
  String get playerRepeat => 'Erneut';

  @override
  String get playerProvenance =>
      'Mit Google Lyria 3 erstellt · SynthID-Wasserzeichen · KI-generiert';

  @override
  String get playerMissing => 'Dieser Song ist nicht mehr auf diesem Gerät.';

  @override
  String get actionDownload => 'Laden';

  @override
  String get actionShare => 'Teilen';

  @override
  String get actionLicense => 'Lizenz';

  @override
  String get actionRegenerate => 'Neu erstellen';

  @override
  String get actionDetails => 'Details';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionVerse => 'Strophe';

  @override
  String get sectionPreChorus => 'Pre-Chorus';

  @override
  String get sectionChorus => 'Refrain';

  @override
  String get sectionBridge => 'Bridge';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionHook => 'Hook';

  @override
  String get shareTitle => 'Teilkarte';

  @override
  String get shareSubtitle => 'Wähle ein Thema und ein Layout.';

  @override
  String get shareTheme => 'Thema';

  @override
  String get shareLayout => 'Layout';

  @override
  String get shareLayoutScene => 'Mit Bild';

  @override
  String get shareLayoutText => 'Nur Text';

  @override
  String get paletteTerracotta => 'Terrakotta';

  @override
  String get paletteSand => 'Sand';

  @override
  String get paletteOlive => 'Oliv';

  @override
  String get paletteNavy => 'Navy';

  @override
  String get shareAction => 'Teilen';

  @override
  String get shareSaveVideo => 'Video sichern';

  @override
  String get shareCopyLyrics => 'Text kopieren';

  @override
  String get shareVideoSaved => 'In Fotos gesichert';

  @override
  String get shareLyricsCopied => 'Songtext kopiert';

  @override
  String get shareCardTagline => 'Ein Song für jemanden';

  @override
  String get shareSaveFailed =>
      'Video nicht gesichert. Erlaube Songlet in den Einstellungen den Zugriff auf Fotos.';

  @override
  String get downloadReady => 'Voller Song fertig';

  @override
  String get downloadTitle => 'Für immer deins';

  @override
  String get downloadIntro =>
      'Dein Song ist fertig. Lade unten Audio in hoher Qualität und deine kommerzielle Lizenz.';

  @override
  String get downloadAudioHeader => 'Audio laden';

  @override
  String get downloadAudioNote => 'Hohe Qualität';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbit/s';

  @override
  String get downloadMp3Subtitle => 'Ideal zum Teilen und Anhören im Alltag';

  @override
  String get downloadWavTitle => 'WAV · 44,1 kHz (Premier)';

  @override
  String get downloadWavSubtitle =>
      'Höchste Qualität für den professionellen Einsatz';

  @override
  String get downloadMp3Action => 'MP3 laden';

  @override
  String get downloadWavAction => 'WAV laden';

  @override
  String get downloadLicenseAction => 'Lizenz laden';

  @override
  String get licenseHeader => 'Kommerzielle Lizenz';

  @override
  String get licenseIncluded => 'In deinem Abo enthalten';

  @override
  String get licenseNotIncluded => 'Mit Abo oder Paket verfügbar';

  @override
  String get licensePdfTitle => 'Kommerzielle Lizenz (PDF)';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Erstellt am $dateString';
  }

  @override
  String licenseId(String id) {
    return 'Lizenz-ID: $id';
  }

  @override
  String get licenseUsesTitle => 'Du darfst diesen Song nutzen für:';

  @override
  String get usePersonal => 'Private Nutzung';

  @override
  String get usePersonalDetail => 'Geschenke, Erinnerungen, nicht kommerziell';

  @override
  String get useAds => 'Werbung & Marketing';

  @override
  String get useAdsDetail => 'Aktionen, bezahlte Kampagnen';

  @override
  String get useSocial => 'Social Media';

  @override
  String get useSocialDetail => 'TikTok, Instagram, YouTube usw.';

  @override
  String get usePodcasts => 'Podcasts & Videos';

  @override
  String get usePodcastsDetail => 'Monetarisierte Inhalte';

  @override
  String get licenseDetailsNote => 'Alle Details stehen im Lizenz-PDF.';

  @override
  String get saveEnjoyHeader => 'Sichern & genießen';

  @override
  String get saveToFiles => 'In Dateien sichern';

  @override
  String get addToMusic => 'Zu Musik';

  @override
  String get synthIdNote =>
      'Dieser Song enthält ein SynthID-Wasserzeichen, das ihn auch nach dem Laden als KI-generiert erkennbar macht.';

  @override
  String get wavNeedsPremier => 'WAV-Downloads gibt es mit Premier.';

  @override
  String get wavUnavailable =>
      'Für diesen Song gibt es keine WAV-Datei. WAV-Dateien lassen sich innerhalb von 24 Stunden nach dem Erstellen speichern.';

  @override
  String get libraryFilterAll => 'Alle';

  @override
  String get libraryJustBecause => 'Einfach so';

  @override
  String libraryPlay(String title) {
    return '$title starten';
  }

  @override
  String libraryActions(String title) {
    return 'Aktionen für $title';
  }

  @override
  String get libraryDeleteTitle => 'Diesen Song löschen?';

  @override
  String get libraryDeleteBody =>
      'Er wird von diesem Gerät entfernt. Ist der iCloud-Sync an, auch von deinen anderen Geräten.';

  @override
  String get libraryDeleted => 'Song gelöscht';

  @override
  String get libraryFailed => 'Nicht fertig';

  @override
  String get libraryNoMatch => 'Noch keine Songs für diesen Anlass.';

  @override
  String get detailFullGenerated => 'Voller Song erstellt';

  @override
  String get detailPreviewGenerated => 'Vorschau erstellt';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Erstellt am $dateString';
  }

  @override
  String get detailPromptUsed => 'Deine Angaben';

  @override
  String get detailOccasion => 'Anlass';

  @override
  String get detailCountry => 'Land';

  @override
  String get detailGenre => 'Genre';

  @override
  String get detailKeywords => 'Stichwörter';

  @override
  String get detailDescription => 'Beschreibung';

  @override
  String get detailLyrics => 'Songtext';

  @override
  String get detailGenerationId => 'Generierungs-ID';

  @override
  String get detailRegenerate => 'Gleichen Stil neu erstellen';

  @override
  String get detailCustomGenre => 'Passend zur Beschreibung';

  @override
  String get settingsSectionPlan => 'Käufe';

  @override
  String get settingsSectionLibrary => 'Mediathek';

  @override
  String get settingsSectionAbout => 'Info';

  @override
  String get settingsRestore => 'Käufe wiederherstellen';

  @override
  String get settingsManage => 'Abo verwalten';

  @override
  String get settingsICloud => 'iCloud-Sync';

  @override
  String get settingsICloudOn => 'Songs auf allen Geräten synchron';

  @override
  String get settingsICloudOff => 'Songs bleiben auf diesem Gerät';

  @override
  String get settingsICloudUnavailable =>
      'Zum Sync in den Optionen bei iCloud anmelden';

  @override
  String get settingsLyricsLanguage => 'Standardsprache für Songtexte';

  @override
  String get settingsLyricsLanguageAuto => 'Passend zum Land';

  @override
  String get settingsTerms => 'AGB';

  @override
  String get settingsPrivacy => 'Datenschutz';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutTitle => 'Über die Generierung';

  @override
  String get aboutSubtitle => 'So macht Songlet deine Songs';

  @override
  String get aboutLyriaTitle => 'Mit Google Lyria 3';

  @override
  String get aboutLyriaBody =>
      'Songs werden mit Googles Lyria 3 über die Gemini API erstellt. Lyria 3 ist ein Musikmodell, das deine Ideen in Original-Songs verwandelt.';

  @override
  String get aboutWatermarkTitle => 'Eingebautes Wasserzeichen';

  @override
  String get aboutWatermarkBody =>
      'Jeder Song enthält ein SynthID-Wasserzeichen von Google. Es kennzeichnet KI-generierte Musik und lässt sich nicht entfernen.';

  @override
  String get aboutImitationTitle => 'Keine Nachahmung echter Künstler';

  @override
  String get aboutImitationBody =>
      'Songlet ahmt niemals echte Künstler, ihre Stimmen oder bestimmte Stile nach. Songs sind original und entstehen aus deinen Ideen, Beschreibungen und Fotos.';

  @override
  String get aboutPrivacyTitle => 'Deine Privatsphäre zählt';

  @override
  String get aboutPrivacyBody =>
      'Fotos und Beschreibungen werden innerhalb von 24 Stunden von unseren Servern gelöscht. Nach der Erstellung deines Songs behalten wir weder Bilder noch Beschreibungen.';

  @override
  String get aboutBanner =>
      'Geteilte Songs sind als KI-generiert gekennzeichnet.';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · Mit Google Lyria 3 erstellt';
  }

  @override
  String get festivalKicker => 'Erzähl deine Story';

  @override
  String get festivalComing => 'kommt bald!';

  @override
  String get festivalBody => 'Feiere mit einem einzigartigen Song.';

  @override
  String festivalCta(String festival) {
    return 'Song zu $festival machen';
  }

  @override
  String get festivalPickOccasion => 'Wähle einen Anlass und leg los';

  @override
  String get festivalLanguagesTitle => 'Songs in deiner Sprache';

  @override
  String festivalLanguagesBody(String language) {
    return 'Songs auf $language und in 12 weiteren Sprachen';
  }

  @override
  String get unavailableTitle => 'Vorübergehend nicht verfügbar';

  @override
  String get unavailableMessage =>
      'Songlet kann gerade keine Songs erstellen. Deine Mediathek funktioniert weiter – versuch es gleich noch einmal.';

  @override
  String get paywallHeroTitle => 'Mach einen ganzen Song';

  @override
  String get paywallHeroSubtitle =>
      'Aus deiner Idee wird ein kompletter Song in höherer Qualität und mit allen Rechten.';

  @override
  String get paywallBenefitSongs => 'Mehr Songs';

  @override
  String get paywallBenefitQuality => 'Höhere Qualität';

  @override
  String get paywallBenefitCommercial => 'Kommerziell nutzen';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ganze Songs pro Monat',
      one: '$countString ganzer Song pro Monat',
    );
    return '$_temp0';
  }

  @override
  String planPreviews(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Vorschauen pro Monat',
      one: '$countString Vorschau pro Monat',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'MP3-Download';

  @override
  String get planMp3Wav => 'MP3- + WAV-Download';

  @override
  String get planLicense => 'Kommerzielle Lizenz';

  @override
  String get planPriority => 'Bevorzugte Erstellung';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString Tage gratis testen';
  }

  @override
  String planPerYear(String price) {
    return '$price/Jahr';
  }

  @override
  String planPerMonth(String price) {
    return '$price/Monat';
  }

  @override
  String get packTitle => 'Nur ein paar nötig?';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString-Song-Paket',
      one: '$countString-Song-Paket',
    );
    return '$_temp0';
  }

  @override
  String get packNote => 'verfällt nie';

  @override
  String get valueForever => 'Deine Songs für immer';

  @override
  String get valueDownloads => 'Downloads in hoher Qualität';

  @override
  String get valueCommercial => 'Kommerzielle Nutzung erlaubt';

  @override
  String get valuePrivate => 'Privatsphäre zuerst';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return 'Nach dem Gratistest werden automatisch $pricePerPeriod berechnet. Kündige jederzeit vor Ende des Tests.';
  }

  @override
  String get paywallSubscribe => 'Abonnieren';

  @override
  String get paywallBuyPack => 'Paket holen';

  @override
  String get templateBirthdayWish => 'Geburtstagsgruß';

  @override
  String get templateBirthdayWishHint =>
      'Ein besonderer Song für ihren besonderen Tag';

  @override
  String get templateBirthdayParty => 'Geburtstagsparty';

  @override
  String get templateBirthdayPartyHint =>
      'Heiz die Party fürs Geburtstagskind an';

  @override
  String get templateLoveStory => 'Liebesstory';

  @override
  String get templateLoveStoryHint => 'Eure Geschichte als Song';

  @override
  String get templateThankAFriend => 'Danke sagen';

  @override
  String get templateThankAFriendHint =>
      'Danke sagen, wie es Worte nicht können';

  @override
  String get templatePartyInvite => 'Partyeinladung';

  @override
  String get templatePartyInviteHint => 'Hol alle zur Party';

  @override
  String get templateWedding => 'Hochzeit';

  @override
  String get templateWeddingHint => 'Ein Song für ihren Moment für immer';

  @override
  String get templateInMemory => 'Zum Gedenken';

  @override
  String get templateInMemoryHint => 'Ehre einen geliebten Menschen';

  @override
  String get templateFestival => 'Festtag';

  @override
  String get templateFestivalHint => 'Herzliche Grüße zu einer besonderen Zeit';

  @override
  String get templateRingtone => 'Klingelton';

  @override
  String get templateRingtoneHint => 'Ein kurzer Loop nur für dich';

  @override
  String get templateTeamAnthem => 'Teamhymne';

  @override
  String get templateTeamAnthemHint => 'Bring Team und Fans in Stimmung';

  @override
  String get templateSportsRecap => 'Spielrückblick';

  @override
  String get templateSportsRecapHint => 'Das große Spiel als Song';

  @override
  String get templateRapBattle => 'Rap-Battle';

  @override
  String get templateRapBattleHint =>
      'Freundliche Bars für einen freundlichen Rivalen';

  @override
  String get templateComedy => 'Comedy';

  @override
  String get templateComedyHint => 'Insider-Witze, jetzt mit Refrain';

  @override
  String get templatePetAnthem => 'Haustier-Hymne';

  @override
  String get templatePetAnthemHint => 'Ein Titelsong für deinen besten Freund';

  @override
  String get templateHometown => 'Heimatort';

  @override
  String get templateHometownHint => 'Liebe für den Ort, den du Zuhause nennst';

  @override
  String get templateBusinessPromo => 'Geschäftswerbung';

  @override
  String get templateBusinessPromoHint =>
      'Ein Ohrwurm für deinen Laden oder deine Marke';

  @override
  String get templateCustom => 'Deine eigene Idee';

  @override
  String get mvRecommended => 'Empfohlen';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString s';
  }

  @override
  String get mvViewProgress => 'Fortschritt';

  @override
  String mvIntentWaiting(String level) {
    return '$level wartet auf Credits';
  }

  @override
  String get mvSongExpiredAction => 'Song neu erstellen';

  @override
  String mvQuotaNeed(String level, int required, int available) {
    final intl.NumberFormat requiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requiredString = requiredNumberFormat.format(required);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    String _temp0 = intl.Intl.pluralLogic(
      required,
      locale: localeName,
      other: '$requiredString Credits',
      one: '$requiredString Credit',
    );
    String _temp1 = intl.Intl.pluralLogic(
      available,
      locale: localeName,
      other: '$availableString Credits',
      one: '$availableString Credit',
    );
    return '$level braucht $_temp0. Du hast $_temp1.';
  }

  @override
  String get mvQuotaBuyAndContinue => 'Kaufen und fortfahren';

  @override
  String get mvQuotaMayNeedTwice =>
      'Wo du bist, reicht ein Paket vielleicht nicht – eventuell brauchst du zwei.';

  @override
  String get mvQuotaAutoRetry =>
      'Dein Video startet, sobald der Kauf durch ist.';

  @override
  String get mvAutoLyricMaking => 'Dein Lyric-Video entsteht';

  @override
  String get mvAutoChorusDetail => 'Aus diesem Song, mit deinen Credits';

  @override
  String mvAutoReady(String level) {
    return '$level ist fertig';
  }

  @override
  String get mvAutoView => 'Sehen';

  @override
  String get mvUpgradeChorus => 'Refrain-Video erstellen';

  @override
  String get mvAutoFailed => 'Das Video konnte nicht starten';

  @override
  String get mvLeaveHint =>
      'Du kannst diese Seite verlassen – wir sagen dir, wann es fertig sein sollte.';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: 'Deine $creditsString Credits sind zurück.',
      one: 'Dein Credit ist zurück.',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => 'Dieses Video wurde nicht fertig';

  @override
  String get mvRejectedTitle => 'Ein Foto war nicht nutzbar';

  @override
  String get mvRejectedBody =>
      'Das Videomodell hat eines deiner Referenzfotos abgelehnt. Passe die Fotos an und versuch es noch einmal.';

  @override
  String get mvAdjustPhotos => 'Fotos anpassen und neu versuchen';

  @override
  String get mvTryChorus => 'Stattdessen ein Refrain-Video';

  @override
  String get mvPreparingPhotos => 'Fotos werden hochgeladen…';

  @override
  String get mvPreparingSubmit => 'Dein Video wird gesendet …';

  @override
  String get mvNotifyTitle => 'Dein Video sollte fertig sein';

  @override
  String mvNotifyBody(String level) {
    return '$level – tippen zum Ansehen.';
  }

  @override
  String get mvRegenerate => 'Noch eins';

  @override
  String get mvEntryTitle => 'Mach ein Video daraus';

  @override
  String get mvEntrySubtitle =>
      'Lyric-, Refrain- und Song-Videos – mit Credits';

  @override
  String get mvEntryDisabled => 'Verfügbar, sobald der Song fertig ist';

  @override
  String get mvEntryChoose => 'Video auswählen';

  @override
  String get mvEntryWatch => 'Video ansehen';

  @override
  String get mvChipReady => 'Video';

  @override
  String get mvChipMaking => 'Video entsteht';

  @override
  String get lengthAutoVideo => 'Auch ein Lyric-Video erstellen';

  @override
  String get lengthAutoVideoHint =>
      'Ein paar Minuten nach dem Song fertig · mit Credits';

  @override
  String get lengthSongAndChorus => 'Song + Refrain-Video';

  @override
  String get lengthSongAndChorusHint =>
      'Der ganze Song, dann ein 30-Sekunden-Refrain-Video';

  @override
  String get paywallVideoGroup => 'Musikvideos';

  @override
  String get planVideoIncluded => 'Dein Kontingent macht auch Musikvideos';

  @override
  String get settingsVideoCredits => 'Video-Credits';

  @override
  String get createGenrePop => 'Pop';

  @override
  String get createGenreHipHopRap => 'Hip-Hop & Rap';

  @override
  String get createGenreRock => 'Rock';

  @override
  String get createGenreKPop => 'K-Pop';

  @override
  String get createGenreLatin => 'Latin';

  @override
  String get createGenreElectronic => 'Elektronik';

  @override
  String get createGenreRnb => 'R&B';

  @override
  String get createGenreCountry => 'Country';

  @override
  String get createGenreAfrobeats => 'Afrobeats';

  @override
  String get createGenreReggae => 'Reggae';

  @override
  String get createGenreJazzBlues => 'Jazz & Blues';

  @override
  String get createGenreClassical => 'Klassik';

  @override
  String get createGenreFolk => 'Folk';

  @override
  String get createGenreLofi => 'Lo-Fi';

  @override
  String get createGenreAcoustic => 'Akustik';

  @override
  String get createGenreCinematic => 'Filmmusik';

  @override
  String get createGenreAmbient => 'Ambient';

  @override
  String get createGenreBossaNova => 'Bossa Nova';

  @override
  String get createGenreIndiePop => 'Indie-Pop';

  @override
  String get createGenreContemporaryRnb => 'Modernes R&B';

  @override
  String get createGenreAlternativeCountry => 'Alternative Country';

  @override
  String get createGenreGarageRock => 'Garage-Rock';

  @override
  String get createGenreGrime => 'Grime';

  @override
  String get createGenreIndieFolk => 'Indie-Folk';

  @override
  String get createGenreSynthpop => 'Synthpop';

  @override
  String get createGenrePianoBallad => 'Pianoballade';

  @override
  String get createGenreSurfRock => 'Surf-Rock';

  @override
  String get createGenreDeepHouse => 'Deep House';

  @override
  String get createGenreMinimalTechno => 'Minimal Techno';

  @override
  String get createGenreFrenchYeyePop => 'Französischer 60er-Pop';

  @override
  String get createGenreChillout => 'Chillout';

  @override
  String get createGenreJPopIndiePop => 'J-Pop Indie-Pop';

  @override
  String get createGenreChiptune => 'Chiptune';

  @override
  String get createGenreDiscoFunk => 'Disco-Funk';

  @override
  String get createGenreReggaeton => 'Reggaeton';

  @override
  String get createGenreCumbia => 'Cumbia';

  @override
  String get createGenreLatinJazz => 'Latin Jazz';

  @override
  String get createGenreBhangra => 'Bhangra';

  @override
  String get createGenreIndianClassical => 'Indische Klassik';

  @override
  String get createGenreLofiHipHop => 'Lo-Fi Hip-Hop';

  @override
  String profileAccountIdWithValue(String id) {
    return 'Konto-ID: $id';
  }

  @override
  String profileBalanceValue(int balance) {
    final intl.NumberFormat balanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String balanceString = balanceNumberFormat.format(balance);

    return '$balanceString';
  }

  @override
  String playerExportFileName(String brand, String title, String occasion) {
    return '$brand – $title ($occasion)';
  }

  @override
  String get createVocalsCustomSummary => 'Eigene — nach deiner Beschreibung';

  @override
  String mvChipMakingWithProgress(String progress) {
    return 'Video entsteht · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return 'Das Video konnte nicht starten · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    return 'Videoguthaben: $creditsString';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => 'Inspiration';

  @override
  String inspirationPlay(String name) {
    return '$name hören';
  }

  @override
  String get inspirationStop => 'Hörprobe stoppen';

  @override
  String get inspirationNameSoundscape => 'Klangwelt';

  @override
  String get inspirationStyleSoundscape => 'Ambient-Klänge, ohne Gesang';

  @override
  String get inspirationNameBackgroundMusic => 'Hintergrundmusik';

  @override
  String get inspirationStyleBackgroundMusic =>
      'Leichte Instrumentalmusik für Videos';

  @override
  String get inspirationNameMemorizeSomething => 'Merk dir was';

  @override
  String get inspirationStyleMemorizeSomething => 'Eingängiger Merk-Pop';

  @override
  String get inspirationNameTextMessages => 'SMS als Song';

  @override
  String get inspirationStyleTextMessages => 'Verspielter Pop aus deinen SMS';

  @override
  String get inspirationNameIntroMusic => 'Intro-Musik';

  @override
  String get inspirationStyleIntroMusic => 'Mutiger, filmreifer Opener';

  @override
  String get inspirationNameMontage => 'Montage';

  @override
  String get inspirationStyleMontage =>
      'Mitreißender Aufbau für Highlight-Clips';

  @override
  String get inspirationNameSayItWithATrack => 'Sag\'s mit einem Song';

  @override
  String get inspirationStyleSayItWithATrack => 'Gefühlvolle Pop-Ballade';

  @override
  String get inspirationNameBrandJingle => 'Marken-Jingle';

  @override
  String get inspirationStyleBrandJingle => 'Kurzer, heller Ohrwurm';

  @override
  String get inspirationNameRingtone => 'Klingelton';

  @override
  String get inspirationStyleRingtone => 'Loopbarer 30-Sekunden-Hook';

  @override
  String get inspirationNameStreaming => 'Streaming';

  @override
  String get inspirationStyleStreaming =>
      'Energiegeladenes Elektro-Stream-Intro';

  @override
  String get inspirationNameSpeechToTrack => 'Sprache zu Song';

  @override
  String get inspirationStyleSpeechToTrack => 'Deine Stimme wird zum Song';

  @override
  String get inspirationNameRapBattle => 'Rap-Battle';

  @override
  String get inspirationStyleRapBattle => 'Harter Hip-Hop';

  @override
  String get inspirationNameComedy => 'Comedy';

  @override
  String get inspirationStyleComedy => 'Schräg, fröhlich, augenzwinkernd';

  @override
  String get inspirationNameTeamAnthem => 'Teamhymne';

  @override
  String get inspirationStyleTeamAnthem => 'Stadionrock zum Mitsingen';

  @override
  String get inspirationNameSportsRecap => 'Spielrückblick';

  @override
  String get inspirationStyleSportsRecap => 'Epische Orchester-Highlights';

  @override
  String get inspirationNamePartyInvite => 'Partyeinladung';

  @override
  String get inspirationStylePartyInvite => 'Dance-Pop-Einladung';

  @override
  String get inspirationNameHappyBirthday => 'Zum Geburtstag';

  @override
  String get inspirationStyleHappyBirthday => 'Warmer Akustik-Geburtstagssong';

  @override
  String get inspirationNameFriendAppreciation => 'Danke an Freunde';

  @override
  String get inspirationStyleFriendAppreciation => 'Gute-Laune-Indie-Pop';

  @override
  String get inspirationNameLoveStory => 'Liebesstory';

  @override
  String get inspirationStyleLoveStory => 'Romantische R&B-Ballade';

  @override
  String get inspirationNameBirthdayRoast => 'Geburtstags-Roast';

  @override
  String get inspirationStyleBirthdayRoast =>
      'Frecher, witziger Geburtstagssong';

  @override
  String get inspirationNameOdeToYourPet => 'Ode an dein Haustier';

  @override
  String get inspirationStyleOdeToYourPet => 'Süßer, hüpfender Pop';

  @override
  String get inspirationNameHometownTribute => 'Heimat-Hommage';

  @override
  String get inspirationStyleHometownTribute => 'Nostalgischer Folk';

  @override
  String get inspirationNameWeatherReport => 'Wetterbericht';

  @override
  String get inspirationStyleWeatherReport => 'Verspielter Lounge-Groove';

  @override
  String get inspirationNameBusinessPromo => 'Geschäftswerbung';

  @override
  String get inspirationStyleBusinessPromo => 'Selbstbewusster Business-Pop';

  @override
  String get inspirationStyleBirthdayWish =>
      'Herzliches Lied für ihren besonderen Tag';

  @override
  String get inspirationStyleBirthdayParty =>
      'Mitreißende Partyhymne für das Geburtstagskind';

  @override
  String get inspirationStyleThankAFriend => 'Warmes, dankbares Dankeslied';

  @override
  String get inspirationStyleWedding =>
      'Fröhliches, romantisches Lied für den großen Tag';

  @override
  String get inspirationStyleInMemory => 'Sanfte, hoffnungsvolle Hommage';

  @override
  String get inspirationStyleFestival => 'Strahlender, festlicher Saisongruß';

  @override
  String get inspirationStylePetAnthem =>
      'Liebevolle, beschwingte Hymne für ein Haustier';

  @override
  String get inspirationStyleHometown => 'Stolze, nostalgische Heimathymne';

  @override
  String get settingsSectionLanguage => 'Sprache';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsCredits => 'Credits';

  @override
  String get settingsAccountId => 'Konto-ID';

  @override
  String get settingsCopyAccountId => 'Konto-ID kopieren';

  @override
  String get devSectionTitle => 'Entwickler (nur DEV)';

  @override
  String get devKeychainReset => 'Keychain-Schlüssel löschen';

  @override
  String get devKeychainResetHint => 'Geräte-ID und Sitzungstoken';

  @override
  String get devKeychainResetConfirmTitle => 'Keychain-Schlüssel löschen?';

  @override
  String get devKeychainResetConfirmBody =>
      'Geräte-ID und Sitzungstoken werden aus der Keychain gelöscht. Das aktuelle Gastkonto ist nicht wiederherstellbar; die App meldet sich als neuer Gast an.';

  @override
  String get devKeychainResetDone => 'Keychain gelöscht – neuer Gast';

  @override
  String get settingsAppLanguage => 'App-Sprache';

  @override
  String get settingsLanguageSystem => 'Systemsprache';

  @override
  String settingsLanguageSystemValue(String language) {
    return 'System ($language)';
  }

  @override
  String get settingsLanguageNativeName => 'Deutsch';

  @override
  String get settingsLanguageSaveFailed =>
      'Sprache nicht gespeichert. Versuch es erneut.';

  @override
  String get settingsLyricsLanguageHint => 'Für neue Songs.';

  @override
  String composerRemoveInspiration(String name) {
    return '$name entfernen';
  }

  @override
  String get composerPromptHint =>
      'Beschreib den Song oder wähl oben eine Idee';

  @override
  String get composerPromptHintWide => 'Beschreib den Song oder wähl eine Idee';

  @override
  String get composerWordsLabel => 'Deine Worte';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Fotos hinzugefügt',
      one: '$countString Foto hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return 'Song-Optionen: $summary';
  }

  @override
  String get composerOptionsShow => 'Optionen zeigen';

  @override
  String get composerOptionsHide => 'Optionen ausblenden';

  @override
  String get composerSummaryAnyVocals => 'Gesang frei';

  @override
  String get composerSummaryAnyGenre => 'Genre frei';

  @override
  String get composerSummaryLyrics => 'Eigener Text';

  @override
  String get composerSummaryVideo => 'Lyric-Video';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Vorschau erstellen · gratis',
      'preview': 'Vorschau erstellen · 1 Vorschau',
      'other': 'Vorschau erstellen',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Vorschau für $name · gratis',
      'preview': 'Vorschau für $name · 1 Vorschau',
      'other': 'Vorschau für $name erstellen',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': 'Ganzen Song erstellen · 1 Song',
      'other': 'Ganzen Song erstellen',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => 'Text übernehmen';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level startet in $seconds s';
  }

  @override
  String planPerWeek(String price) {
    return '$price/Woche';
  }

  @override
  String get planCreditsWeekly => 'Jede Woche neue Credits';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': '1. Tag',
      'week': '1. Woche',
      'month': '1. Monat',
      'year': '1. Jahr',
      'other': '1. Zeitraum',
    });
    return '$percent % Rabatt: $_temp0';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return 'Nach dem Einführungspreis von $introPrice werden automatisch $pricePerPeriod berechnet. Kündige jederzeit vor der Verlängerung.';
  }

  @override
  String get storePreviewAHook => 'Beginne mit dem Namen';

  @override
  String get storePreviewAWords => 'Drei Wörter über die Person';

  @override
  String get storePreviewAWait => 'Dein Song entsteht';

  @override
  String get storePreviewAChorus => 'Der Name im Refrain';

  @override
  String get storePreviewAEnd => 'Ein Song mit dem Namen drin';

  @override
  String get storePreviewBHook => 'Starte mit deinen Fotos';

  @override
  String get storePreviewBVideo => 'Lyric-Video dazu';

  @override
  String get storePreviewBWait => 'Dein Song entsteht';

  @override
  String get storePreviewBLyrics => 'Lyrics synchron im Bild';

  @override
  String get storePreviewBMood => 'Fotos geben die Stimmung.';

  @override
  String get storePreviewBShare => 'Teile das Video.';

  @override
  String get storePreviewBLanguage => 'Lyrics in deiner Sprache';

  @override
  String get storePreviewAShare => 'Als Karte verschicken';

  @override
  String get storePreviewCta => 'Schreib deinen ersten Song';

  @override
  String get storePreviewDisclosure => 'Erfordert ein Abo oder Credits';

  @override
  String get storeCreativeHeader => 'Songs für die Menschen, die du liebst';

  @override
  String get storeCreativeSearch => 'Aus einem Namen wird ein Song';

  @override
  String get storeCreativeBirthday => 'Ein Geburtstagslied mit Namen';

  @override
  String get storeCreativePhoto => 'Aus deinen Fotos wird ein Song';

  @override
  String get storeCreativeWedding => 'Ein Song für euren Hochzeitstag';
}
