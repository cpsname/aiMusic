// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get startupLoading => 'On accorde les instruments…';

  @override
  String get commonErrorTitle => 'Un problème est survenu';

  @override
  String get updateRequiredTitle => 'Mise à jour requise';

  @override
  String get updateRequiredMessage =>
      'Une nouvelle version est requise pour continuer.';

  @override
  String get updateNow => 'Mettre à jour';

  @override
  String get maintenanceTitle => 'Maintenance programmée';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Reprise estimée dans environ $minutesString min';
  }

  @override
  String get featureUnavailable =>
      'Cette fonctionnalité est temporairement indisponible.';

  @override
  String get navProfile => 'Profil';

  @override
  String get navStore => 'Boutique';

  @override
  String get navUpload => 'Importer';

  @override
  String get uploadTitle => 'Importations';

  @override
  String get uploadSubtitle =>
      'Importation directe vers R2 par URL présignée, avec hachage, déduplication instantanée et suivi de la progression.';

  @override
  String get uploadPick => 'Choisir une image et importer';

  @override
  String get uploadAgain => 'Importer un autre fichier';

  @override
  String get uploadPhaseHashing => 'Calcul du hachage…';

  @override
  String get uploadPhaseSigning => 'Demande du ticket d’importation…';

  @override
  String uploadPhaseUploading(String percent) {
    return 'Importation : $percent';
  }

  @override
  String get uploadPhaseFinalizing => 'Finalisation…';

  @override
  String get uploadDone => 'Importé.';

  @override
  String get uploadDedup =>
      'Instantané : ce fichier existait déjà sur le serveur.';

  @override
  String get uploadOpenLink => 'Voir le fichier';

  @override
  String get uploadFailed => 'Échec de l’importation.';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Fichier trop volumineux ($limitString Mo max.).';
  }

  @override
  String get uploadUnsupportedType => 'Type de fichier non pris en charge.';

  @override
  String get profileGuestTitle => 'Invité';

  @override
  String get profileGuestSubtitle =>
      'Connecte-toi pour retrouver tes achats sur tous tes appareils.';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get profileBalanceLabel => 'Crédits';

  @override
  String get profileAccountId => 'Identifiant du compte';

  @override
  String get profileFeaturesLabel => 'Avantages actifs';

  @override
  String get profileNoFeatures => 'Aucun avantage actif pour l’instant.';

  @override
  String get profileSubscriptionLabel => 'Abonnement';

  @override
  String get profileManageSubscription => 'Gérer l’abonnement';

  @override
  String get subscriptionActive => 'Actif';

  @override
  String get subscriptionInactive => 'Aucun';

  @override
  String get profileDeleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountTitle => 'Supprimer ce compte ?';

  @override
  String get deleteAccountMessage =>
      'Cette action est irréversible : ce compte, ses crédits et ses avantages deviendront définitivement inaccessibles, et un nouveau compte sera créé. La suppression du compte ne résilie pas un abonnement App Store actif : gère-le dans les réglages de ton compte App Store, ou associe-le à nouveau plus tard avec « Restaurer les achats ».';

  @override
  String get deleteAccountConfirm => 'Supprimer';

  @override
  String get deleteAccountWorking => 'Suppression du compte…';

  @override
  String get deleteAccountDone => 'Compte supprimé.';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Membre depuis $dateString';
  }

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginUsername => 'Nom d’utilisateur';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginSubmit => 'Se connecter';

  @override
  String get paywallTitle => 'Obtiens la chanson complète';

  @override
  String get paywallSubtitle =>
      'Transforme ton aperçu en une chanson de 2 minutes avec paroles, à toi de la télécharger et de l’utiliser.';

  @override
  String get paywallRestore => 'Restaurer les achats';

  @override
  String get paywallAutoRenewNotice =>
      'Le paiement est débité de ton compte Apple lors de la confirmation. Les abonnements se renouvellent automatiquement au même prix et pour la même durée, sauf s’ils sont annulés au moins 24 heures avant la fin de la période en cours. Un essai gratuit se convertit en abonnement payant à son terme. Gère ou annule ton abonnement à tout moment dans les réglages de ton compte App Store.';

  @override
  String get paywallContinue => 'Continuer';

  @override
  String get paywallFreeTrial => 'Essai gratuit';

  @override
  String get paywallOffer => 'Offre';

  @override
  String get paywallManage => 'Gérer';

  @override
  String get paywallTermsOfUse => 'Conditions d’utilisation';

  @override
  String get paywallPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get paywallSubscriptionTerms => 'Conditions d’abonnement';

  @override
  String get commonLinkError => 'Impossible d’ouvrir le lien.';

  @override
  String get commonError => 'Un problème est survenu.';

  @override
  String get commonNetworkError =>
      'Erreur réseau : vérifie ta connexion et réessaie.';

  @override
  String get commonOfflineError =>
      'Tu sembles être hors ligne. Vérifie ta connexion et réessaie.';

  @override
  String get networkErrorTitle => 'Problème de connexion';

  @override
  String get configErrorTitle => 'Problème de configuration de l’app';

  @override
  String get configErrorMessage =>
      'Cette version ne peut pas accéder à notre service. Mets à jour l’app depuis l’App Store ou réinstalle-la. Si le problème persiste, contacte l’assistance.';

  @override
  String get commonAuthError => 'Ta session a expiré. Reconnecte-toi.';

  @override
  String get paywallProductsErrorTitle => 'Impossible de charger les produits';

  @override
  String get paywallNoProducts => 'Aucun produit disponible pour le moment.';

  @override
  String get paywallPurchaseSuccess => 'Achat effectué. Profites-en !';

  @override
  String get paywallProcessing => 'Traitement de ton achat…';

  @override
  String get paywallVerifying => 'Vérification de ton achat…';

  @override
  String get paywallPurchaseFailed => 'L’achat n’a pas pu être effectué.';

  @override
  String get paywallRestoreStarted => 'Restauration de tes achats…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString achats restaurés.',
      one: '$countString achat restauré.',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => 'Aucun achat à restaurer.';

  @override
  String get paywallDeferred =>
      'En attente d’approbation. Nous finaliserons l’achat dès qu’il sera approuvé.';

  @override
  String get paywallAlreadySubscribed => 'Ton abonnement est déjà actif.';

  @override
  String get paywallBillingRetry =>
      'Mets à jour ton moyen de paiement pour conserver ton abonnement.';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Essai gratuit de $daysString jours';
  }

  @override
  String get cycleOneTime => 'achat unique';

  @override
  String get cycleWeekly => '/ semaine';

  @override
  String get cycleMonthly => '/ mois';

  @override
  String get cycleQuarterly => '/ trimestre';

  @override
  String get cycleSemiAnnual => '/ 6 mois';

  @override
  String get cycleAnnual => '/ an';

  @override
  String get cycleLifetime => 'à vie';

  @override
  String get navCreate => 'Créer';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navSettings => 'Réglages';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonBack => 'Retour';

  @override
  String get createTitle => 'Pour qui est cette chanson ?';

  @override
  String get occasionBirthday => 'Anniversaire';

  @override
  String get occasionBirthdayHint => 'Une chanson joyeuse pour son grand jour';

  @override
  String get occasionAnniversary => 'Anniversaire de couple';

  @override
  String get occasionAnniversaryHint => 'Célébrez votre histoire à deux';

  @override
  String get occasionConfession => 'Déclaration d’amour';

  @override
  String get occasionConfessionHint => 'Dis ce que ton cœur ressent';

  @override
  String get occasionWedding => 'Mariage';

  @override
  String get occasionWeddingHint =>
      'Une chanson pour le plus beau jour de votre vie';

  @override
  String get occasionMemorial => 'En mémoire';

  @override
  String get occasionMemorialHint => 'Rends hommage à un être cher';

  @override
  String get occasionFestival => 'Fête';

  @override
  String get occasionFestivalHint =>
      'Des vœux chaleureux pour une période spéciale';

  @override
  String get occasionBrand => 'Jingle de marque';

  @override
  String get occasionBrandHint => 'Un air accrocheur pour ta marque';

  @override
  String get occasionSoundtrack => 'Musique de vidéo';

  @override
  String get occasionSoundtrackHint => 'Une musique qui colle à ton histoire';

  @override
  String get festivalNewYear => 'Nouvel An';

  @override
  String get festivalThanksgiving => 'Thanksgiving';

  @override
  String get festivalDiwali => 'Diwali';

  @override
  String get festivalCarnival => 'Carnaval';

  @override
  String get festivalEid => 'Aïd';

  @override
  String get festivalLunarNewYear => 'Nouvel An lunaire';

  @override
  String get regionTitle => 'Où sera-t-elle écoutée ?';

  @override
  String get regionSearchHint => 'Rechercher un pays';

  @override
  String get regionLanguageSheetTitle => 'Langue des paroles';

  @override
  String get countryUS => 'États-Unis';

  @override
  String get countryGB => 'Royaume-Uni';

  @override
  String get countryCA => 'Canada';

  @override
  String get countryAU => 'Australie';

  @override
  String get countryDE => 'Allemagne';

  @override
  String get countryFR => 'France';

  @override
  String get countryJP => 'Japon';

  @override
  String get countryKR => 'Corée du Sud';

  @override
  String get countryBR => 'Brésil';

  @override
  String get countryMX => 'Mexique';

  @override
  String get countryIN => 'Inde';

  @override
  String get countryID => 'Indonésie';

  @override
  String get countryVN => 'Viêt Nam';

  @override
  String get countryTR => 'Turquie';

  @override
  String get languageEn => 'Anglais';

  @override
  String get languageFr => 'Français';

  @override
  String get languageDe => 'Allemand';

  @override
  String get languageJa => 'Japonais';

  @override
  String get languageKo => 'Coréen';

  @override
  String get languagePtBR => 'Portugais (Brésil)';

  @override
  String get languageEsMX => 'Espagnol (Mexique)';

  @override
  String get languageHi => 'Hindi';

  @override
  String get languageId => 'Indonésien';

  @override
  String get languageVi => 'Vietnamien';

  @override
  String get languageTr => 'Turc';

  @override
  String get languageZhHans => 'Chinois (simplifié)';

  @override
  String get languageZhHant => 'Chinois (traditionnel)';

  @override
  String get inputNameLabel => 'Son prénom';

  @override
  String get inputNameOptionalLabel => 'Prénom (facultatif)';

  @override
  String get inputNameHint => 'ex. : Alex';

  @override
  String get inputKeywordsLabel => 'Trois mots pour la décrire';

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
      'Ces paroles sont de moi ou j’ai le droit de les utiliser';

  @override
  String get issueRecipientMissing => 'Ajoute son prénom.';

  @override
  String get issueRecipientTooLong =>
      'Les prénoms peuvent contenir jusqu’à 24 caractères.';

  @override
  String get issueBriefMissing =>
      'Parle-nous de la chanson : quelques mots, des paroles ou des photos.';

  @override
  String get issueDescriptionMissing =>
      'Cette idée a besoin de tes mots : écris une phrase sur la chanson.';

  @override
  String get generatingBackToEdit => 'Retour à la modification';

  @override
  String get issueKeywordTooLong =>
      'Chaque mot peut contenir jusqu’à 20 caractères.';

  @override
  String get issueTooManyKeywords => 'Utilise trois mots maximum.';

  @override
  String get issueArtistName =>
      'Les noms d’artistes ne sont pas autorisés : décris plutôt l’émotion.';

  @override
  String get issueStyleImitation =>
      'Nous ne pouvons pas imiter un chanteur ou un groupe. Décris plutôt l’ambiance.';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Les paroles peuvent contenir jusqu’à $limitString caractères.';
  }

  @override
  String get issueLyricsNotOriginal =>
      'Ces paroles ressemblent à une chanson existante. Écris les tiennes.';

  @override
  String get issueLyricsOwnership =>
      'Confirme que tu as le droit d’utiliser ces paroles.';

  @override
  String get issueTooManyPhotos => 'Choisis jusqu’à 10 photos.';

  @override
  String get photosTitle => 'Choisis quelques photos';

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
      'Les photos servent une seule fois à écrire la chanson et sont supprimées de nos serveurs sous 24 heures.';

  @override
  String get photosAdd => 'Ajouter des photos';

  @override
  String get photosCreate => 'Créer à partir des photos';

  @override
  String get photosEmpty => 'Choisis 1 à 10 photos du moment.';

  @override
  String get generatingStepPolishing =>
      'Peaufinage de tes mots sur cet iPhone…';

  @override
  String get generatingStepUploading => 'Envoi de tes photos…';

  @override
  String get generatingStepSubmitting => 'Envoi au studio…';

  @override
  String get errorSafetyBlocked =>
      'Impossible de créer celle-ci : essaie d’autres mots et évite les noms d’artistes.';

  @override
  String get errorQuotaExhausted =>
      'Tu as utilisé les chansons de ce mois-ci. Ajoute un pack ou passe à une formule supérieure.';

  @override
  String get errorUpstreamTimeout =>
      'Cela prend plus de temps que d’habitude. Nous continuons d’essayer et te préviendrons.';

  @override
  String get errorUpstreamRateLimited =>
      'Beaucoup de chansons sont en cours de création. La tienne est en file d’attente.';

  @override
  String get errorAttestFailed => 'Mets à jour Songlet depuis l’App Store.';

  @override
  String get errorImageRejected =>
      'L’une de ces photos ne peut pas être utilisée. Essaies-en une autre.';

  @override
  String get errorNetworkOffline =>
      'Tu es hors ligne. Ta bibliothèque fonctionne toujours.';

  @override
  String get errorDownloadLocked =>
      'Cette chanson ne peut pas être téléchargée : l’achat qui l’a créée a été remboursé ou ton abonnement a pris fin. Tu peux toujours l’écouter.';

  @override
  String get errorJobAlreadyFinished => 'C\'est déjà terminé — rien à annuler.';

  @override
  String get errorMvSongNotReady =>
      'Cette chanson n\'est pas encore prête pour une vidéo.';

  @override
  String get errorMvSongTooLong =>
      'Cette chanson est trop longue pour une vidéo complète — essayez une vidéo du refrain.';

  @override
  String get errorMvSongExpired =>
      'Cette chanson a expiré. Régénère-la pour en faire une vidéo.';

  @override
  String get errorMvNotFound => 'Cette vidéo n\'est plus disponible.';

  @override
  String get errorMvPhotosExpired =>
      'Ces photos ont expiré — choisis-les à nouveau.';

  @override
  String get errorMvRenderFailed =>
      'Nous n\'avons pas pu terminer cette vidéo. Tes crédits sont de retour — réessaie.';

  @override
  String get mvHubTitle => 'Créer une vidéo';

  @override
  String mvHubSubtitle(String title) {
    return 'Transforme « $title » en clip vidéo.';
  }

  @override
  String get mvLevelLyricVideo => 'Vidéo lyrics';

  @override
  String get mvLevelLyricHint => 'Une scène fixe avec tes paroles';

  @override
  String get mvLevelChorus => 'Vidéo du refrain';

  @override
  String get mvLevelChorusHint =>
      '30 secondes de ton refrain, filmées par l\'IA';

  @override
  String get mvLevelFull => 'Vidéo de la chanson entière';

  @override
  String get mvLevelFullHint => 'Toute la chanson, scène par scène';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString crédits',
      one: '$creditsString crédit',
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
      other: 'Tu as $creditsString crédits',
      one: 'Tu as $creditsString crédit',
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
      other: 'Il manque $creditsString crédits',
      one: 'Il manque $creditsString crédit',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => 'Vérification du prix…';

  @override
  String get mvOptionsHeader => 'Options';

  @override
  String get mvAspectLabel => 'Format';

  @override
  String get mvAspectPortrait => 'Portrait';

  @override
  String get mvAspectLandscape => 'Paysage';

  @override
  String get mvAspectSquare => 'Carré';

  @override
  String get mvQualityLabel => 'Qualité';

  @override
  String get mvQualityStandard => 'Standard';

  @override
  String get mvQualityHigh => 'Haute';

  @override
  String get mvSubtitlesLabel => 'Paroles à l\'écran';

  @override
  String get mvPhotosLabel => 'Photos de référence';

  @override
  String get mvPhotosHint =>
      'Pour l\'ambiance et les couleurs — les visages ne sont pas utilisés';

  @override
  String mvPhotosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString photos',
      one: '$countString photo',
    );
    return '$_temp0';
  }

  @override
  String get mvChorusLabel => 'Refrain';

  @override
  String get mvChorusAuto => 'Détecté automatiquement';

  @override
  String get mvChorusCustom => 'Choisir le passage';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => 'Créer la vidéo';

  @override
  String get mvBuyPack => 'Prendre le pack et créer';

  @override
  String get mvSongLocked => 'Ta chanson est sauvegardée pour la vidéo.';

  @override
  String get mvGeneratingTitle => 'Création de ta vidéo…';

  @override
  String get mvStageQueued => 'En attente';

  @override
  String get mvStageSlicing => 'Choix des moments';

  @override
  String get mvStageStoryboarding => 'Écriture du storyboard';

  @override
  String get mvStageKeyframing => 'Peinture des scènes';

  @override
  String get mvStageRendering => 'Tournage des scènes';

  @override
  String get mvStageAssembling => 'Montage';

  @override
  String get mvStageDone => 'Terminé';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Scène $doneString sur $totalString';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Environ $minutesString minutes en général';
  }

  @override
  String get mvCancelRequested => 'Arrêt après la scène en cours…';

  @override
  String get mvCancelTitle => 'Arrêter cette vidéo ?';

  @override
  String get mvCancelQueued =>
      'Elle n\'a pas encore commencé, rien ne sera utilisé.';

  @override
  String get mvCancelStarted =>
      'Elle a déjà commencé. Les scènes déjà faites sont facturées, le reste est rendu.';

  @override
  String get mvCancelConfirm => 'Arrêter la vidéo';

  @override
  String get mvCancelled => 'Vidéo arrêtée';

  @override
  String get mvCancelledRefunded => 'Vidéo arrêtée — rien n\'a été utilisé';

  @override
  String get mvNothing => 'Aucune vidéo en cours.';

  @override
  String get mvQuotaTitle => 'Pas assez de crédits';

  @override
  String get mvAiLabelBurnedIn =>
      'Généré par IA — le badge fait partie de la vidéo';

  @override
  String get mvSave => 'Enregistrer dans Photos';

  @override
  String get mvSaveFiles => 'Enregistrer dans Fichiers';

  @override
  String get mvShareText => 'J\'ai fait ce clip avec Songlet 🎬';

  @override
  String get mvMissing => 'Cette vidéo n\'est plus sur cet appareil.';

  @override
  String get mvDeleteTitle => 'Supprimer cette vidéo ?';

  @override
  String get mvDeleteBody => 'Elle est retirée de cet appareil.';

  @override
  String get mvDeleted => 'Vidéo supprimée';

  @override
  String get mvProvenance =>
      'Créé avec Google Lyria 3 et des modèles vidéo IA · Généré par IA';

  @override
  String get detailVideos => 'Vidéos';

  @override
  String get detailMakeVideo => 'Créer une vidéo';

  @override
  String get mvStatusReady => 'Prête';

  @override
  String get mvStatusPending => 'En cours…';

  @override
  String get mvStatusFailed => 'Non terminée';

  @override
  String get mvPackTitle => 'Clip vidéo';

  @override
  String get mvPackChorusSubtitle => 'Une vidéo du refrain';

  @override
  String get mvPackFullSubtitle => 'Une vidéo de la chanson entière';

  @override
  String get paywallMvHeroTitle => 'Passe en vidéo';

  @override
  String get paywallMvHeroSubtitle =>
      'Des crédits pour un clip de ta chanson — à garder et partager.';

  @override
  String get playerAiGenerated => 'Généré par IA';

  @override
  String get playerLoop => 'En boucle';

  @override
  String get playerPlay => 'Lire';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerPreviewLabel => 'Aperçu de 30 secondes';

  @override
  String playerTitleFor(String name) {
    return 'Pour $name';
  }

  @override
  String get downloadSaved => 'Enregistré dans Fichiers.';

  @override
  String get shareComposing => 'Création de ta carte de partage…';

  @override
  String get shareFailed => 'Impossible de créer la carte de partage.';

  @override
  String get shareText => 'J’ai créé cette chanson avec Songlet 🎵';

  @override
  String get paywallBestValue => 'Meilleure offre';

  @override
  String get paywallStartTrial => 'Commencer l’essai gratuit';

  @override
  String get paywallClose => 'Fermer';

  @override
  String get paywallSeePlans => 'Voir les abonnements';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ta formule est active : il te reste $countString chansons complètes pour cette période.',
      one:
          'Ta formule est active : il te reste $countString chanson complète pour cette période.',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => 'Tes chansons apparaîtront ici.';

  @override
  String get libraryEmptyAction => 'Crée ta première chanson';

  @override
  String get libraryPending => 'Composition…';

  @override
  String get libraryPreviewBadge => 'Aperçu';

  @override
  String get librarySongBadge => 'Chanson complète';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsPlan => 'Ta formule';

  @override
  String get settingsPlanUnavailable =>
      'Impossible de charger ta formule. Tire vers le bas pour réessayer plus tard.';

  @override
  String get tierFree => 'Sans abonnement';

  @override
  String get tierPack => 'Packs de chansons';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString chansons complètes restantes',
      one: '$countString chanson complète restante',
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
      other: '$countString aperçus restants',
      one: '$countString aperçu restant',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Réinitialisation le $dateString';
  }

  @override
  String get settingsUpgrade => 'Mettre à niveau';

  @override
  String get appTagline => 'Des chansons pour ceux que tu aimes';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonMore => 'Plus';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonCopied => 'Copié';

  @override
  String get commonNotNow => 'Plus tard';

  @override
  String get commonLearnMore => 'En savoir plus';

  @override
  String get commonSeeAll => 'Tout voir';

  @override
  String get commonKeepGoing => 'Continuer';

  @override
  String get composerHint => 'Décris la chanson que tu veux';

  @override
  String get composerAddPhotos => 'Ajouter des photos';

  @override
  String get composerSourceMusicHint => 'La décrire avec tes mots';

  @override
  String get composerDictate => 'Dicter';

  @override
  String get composerStopDictation => 'Arrêter la dictée';

  @override
  String get lengthPreview => 'Aperçu';

  @override
  String get lengthFull => 'Chanson complète';

  @override
  String get paramLength => 'Durée';

  @override
  String get paramVocals => 'Voix';

  @override
  String get paramGenre => 'Genre';

  @override
  String templatePlaySample(String name) {
    return 'Écouter un extrait de $name';
  }

  @override
  String get templatePauseSample => 'Mettre l’extrait en pause';

  @override
  String get lengthShort => 'Courte';

  @override
  String get lengthShortHint => 'Aperçu de 30 secondes';

  @override
  String get lengthStandard => 'Standard';

  @override
  String get lengthStandardHint => 'environ 2 minutes, Pro';

  @override
  String get vocalsCustom => 'Auto';

  @override
  String get vocalsCustomHint => 'selon ta description';

  @override
  String get vocalsCustomDetail => 'Le style vocal suit ta description.';

  @override
  String get vocalsOn => 'Avec voix';

  @override
  String get vocalsInstrumental => 'Instrumental';

  @override
  String vocalsLyricsIn(String language) {
    return 'Paroles en $language';
  }

  @override
  String get genreCustom => 'Auto';

  @override
  String get genreCustomHint => 'selon ta description';

  @override
  String genrePopularIn(String country) {
    return 'Populaire : $country';
  }

  @override
  String get genreAll => 'Tous les genres';

  @override
  String get regionHelper =>
      'Change les 3 genres recommandés et la langue des paroles';

  @override
  String regionLyricsRow(String language) {
    return 'Langue des paroles : $language';
  }

  @override
  String get regionNoMatch => 'Aucun pays ne correspond';

  @override
  String get keywordAdd => 'Ajouter un mot';

  @override
  String keywordRemove(String word) {
    return 'Retirer $word';
  }

  @override
  String get nameClear => 'Effacer le prénom';

  @override
  String get lyricsOptional => 'Écrire tes propres paroles (facultatif)';

  @override
  String get issueRecipientArtistName =>
      'Les noms d’artistes ne sont pas autorisés.';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'La description doit faire moins de $limitString caractères.';
  }

  @override
  String get voiceRecording => 'Enregistrement…';

  @override
  String get voiceStarting => 'Démarrage…';

  @override
  String get voiceListening =>
      'Dis pour qui c’est et ce que cette personne aime…';

  @override
  String get voiceOnDevice => 'Transcription sur l’appareil';

  @override
  String get voicePermissionDenied =>
      'Autorise le micro et la reconnaissance vocale pour Songlet dans Réglages pour dicter.';

  @override
  String get voiceUnavailable =>
      'La dictée n’est pas disponible pour cette langue sur cet appareil.';

  @override
  String get voiceApplied => 'Ajouté depuis ta voix';

  @override
  String get photoRemove => 'Retirer la photo';

  @override
  String generatingTitleFor(String name) {
    return 'La chanson de $name s’écrit…';
  }

  @override
  String get generatingTitleGeneric => 'Ta chanson s’écrit…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Environ $secondsString secondes en général';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => 'Progression';

  @override
  String get generatingGlimpse => 'Un aperçu de ta chanson';

  @override
  String get generatingCancelTitle => 'Arrêter cette chanson ?';

  @override
  String get generatingCancelQueued =>
      'Elle n’a pas encore commencé : elle ne sera pas décomptée.';

  @override
  String get generatingCancelStarted =>
      'Elle a déjà commencé : elle reste décomptée.';

  @override
  String get generatingCancelConfirm => 'Arrêter';

  @override
  String get generatingCancelled => 'Chanson arrêtée';

  @override
  String get generatingCancelledRefunded =>
      'Chanson arrêtée — rien n’a été décompté';

  @override
  String get queueTitle => 'Beaucoup de chansons sont en cours de création.';

  @override
  String get queueSubtitle => 'La tienne est dans la file.';

  @override
  String get queuePosition => 'Position';

  @override
  String get queueWait => 'attente estimée';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '≈ $minutesString min';
  }

  @override
  String get generatingNothing => 'Aucune chanson n’est en cours de création.';

  @override
  String get previewGetFull => 'Obtenir la chanson complète de 2 minutes';

  @override
  String get previewShare => 'Partager l’aperçu';

  @override
  String get previewAnother => 'Essayer une autre version (1 aperçu)';

  @override
  String get playerPosition => 'Position de lecture';

  @override
  String get playerPrevSection => 'Section précédente';

  @override
  String get playerNextSection => 'Section suivante';

  @override
  String get playerShuffle => 'Sections aléatoires';

  @override
  String get playerRepeat => 'Répéter';

  @override
  String get playerProvenance =>
      'Créée avec Google Lyria 3 · filigrane SynthID · générée par IA';

  @override
  String get playerMissing => 'Cette chanson n’est plus sur cet appareil.';

  @override
  String get actionDownload => 'Télécharger';

  @override
  String get actionShare => 'Partager';

  @override
  String get actionLicense => 'Licence';

  @override
  String get actionRegenerate => 'Recréer';

  @override
  String get actionDetails => 'Détails';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionVerse => 'Couplet';

  @override
  String get sectionPreChorus => 'Pré-refrain';

  @override
  String get sectionChorus => 'Refrain';

  @override
  String get sectionBridge => 'Pont';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionHook => 'Accroche';

  @override
  String get shareTitle => 'Carte de partage';

  @override
  String get shareSubtitle => 'Choisis un thème et une mise en page.';

  @override
  String get shareTheme => 'Thème';

  @override
  String get shareLayout => 'Mise en page';

  @override
  String get shareLayoutScene => 'Avec illustration';

  @override
  String get shareLayoutText => 'Texte seul';

  @override
  String get paletteTerracotta => 'Terracotta';

  @override
  String get paletteSand => 'Sable';

  @override
  String get paletteOlive => 'Olive';

  @override
  String get paletteNavy => 'Marine';

  @override
  String get shareAction => 'Partager';

  @override
  String get shareSaveVideo => 'Enregistrer la vidéo';

  @override
  String get shareCopyLyrics => 'Copier les paroles';

  @override
  String get shareVideoSaved => 'Enregistrée dans Photos';

  @override
  String get shareLyricsCopied => 'Paroles copiées';

  @override
  String get shareCardTagline => 'Une chanson pour quelqu’un';

  @override
  String get shareSaveFailed =>
      'Impossible d’enregistrer la vidéo. Autorise Songlet à ajouter à Photos dans Réglages.';

  @override
  String get downloadReady => 'Chanson complète prête';

  @override
  String get downloadTitle => 'À toi pour toujours';

  @override
  String get downloadIntro =>
      'Ta chanson est prête. Télécharge l’audio haute qualité et ta licence commerciale ci-dessous.';

  @override
  String get downloadAudioHeader => 'Télécharger l’audio';

  @override
  String get downloadAudioNote => 'Haute qualité';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbit/s';

  @override
  String get downloadMp3Subtitle =>
      'Idéal pour partager et écouter au quotidien';

  @override
  String get downloadWavTitle => 'WAV · 44,1 kHz (Premier)';

  @override
  String get downloadWavSubtitle =>
      'Qualité maximale pour un usage professionnel';

  @override
  String get downloadMp3Action => 'Télécharger le MP3';

  @override
  String get downloadWavAction => 'Télécharger le WAV';

  @override
  String get downloadLicenseAction => 'Télécharger la licence';

  @override
  String get licenseHeader => 'Licence commerciale';

  @override
  String get licenseIncluded => 'Incluse dans ton offre';

  @override
  String get licenseNotIncluded => 'Disponible avec une offre ou un pack';

  @override
  String get licensePdfTitle => 'Licence commerciale (PDF)';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Générée le $dateString';
  }

  @override
  String licenseId(String id) {
    return 'ID de licence : $id';
  }

  @override
  String get licenseUsesTitle => 'Tu peux utiliser cette chanson pour :';

  @override
  String get usePersonal => 'Usage personnel';

  @override
  String get usePersonalDetail => 'Cadeaux, souvenirs, non commercial';

  @override
  String get useAds => 'Publicité et marketing';

  @override
  String get useAdsDetail => 'Promotions, campagnes payantes';

  @override
  String get useSocial => 'Réseaux sociaux';

  @override
  String get useSocialDetail => 'TikTok, Instagram, YouTube, etc.';

  @override
  String get usePodcasts => 'Podcasts et vidéos';

  @override
  String get usePodcastsDetail => 'Contenus monétisés';

  @override
  String get licenseDetailsNote =>
      'Tous les détails figurent dans le PDF de licence.';

  @override
  String get saveEnjoyHeader => 'Enregistrer et profiter';

  @override
  String get saveToFiles => 'Enregistrer dans Fichiers';

  @override
  String get addToMusic => 'Ajouter à Musique';

  @override
  String get synthIdNote =>
      'Cette chanson contient un filigrane SynthID qui l’identifie comme contenu généré par IA, même après téléchargement.';

  @override
  String get wavNeedsPremier =>
      'Les téléchargements WAV sont inclus avec Premier.';

  @override
  String get wavUnavailable =>
      'Il n\'y a pas de fichier WAV pour cette chanson. Les fichiers WAV peuvent être enregistrés dans les 24 heures suivant sa création.';

  @override
  String get libraryFilterAll => 'Toutes';

  @override
  String get libraryJustBecause => 'Juste comme ça';

  @override
  String libraryPlay(String title) {
    return 'Écouter $title';
  }

  @override
  String libraryActions(String title) {
    return 'Actions pour $title';
  }

  @override
  String get libraryDeleteTitle => 'Supprimer cette chanson ?';

  @override
  String get libraryDeleteBody =>
      'Elle sera supprimée de cet appareil. Si la synchronisation iCloud est activée, elle le sera aussi de tes autres appareils.';

  @override
  String get libraryDeleted => 'Chanson supprimée';

  @override
  String get libraryFailed => 'Inachevée';

  @override
  String get libraryNoMatch =>
      'Aucune chanson pour cette occasion pour l’instant.';

  @override
  String get detailFullGenerated => 'Chanson complète générée';

  @override
  String get detailPreviewGenerated => 'Aperçu généré';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Générée le $dateString';
  }

  @override
  String get detailPromptUsed => 'Informations utilisées';

  @override
  String get detailOccasion => 'Occasion';

  @override
  String get detailCountry => 'Pays';

  @override
  String get detailGenre => 'Genre';

  @override
  String get detailKeywords => 'Mots-clés';

  @override
  String get detailDescription => 'Description';

  @override
  String get detailLyrics => 'Paroles';

  @override
  String get detailGenerationId => 'ID de génération';

  @override
  String get detailRegenerate => 'Recréer dans le même style';

  @override
  String get detailCustomGenre => 'Selon la description';

  @override
  String get settingsSectionPlan => 'Achats';

  @override
  String get settingsSectionLibrary => 'Bibliothèque';

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsRestore => 'Restaurer les achats';

  @override
  String get settingsManage => 'Gérer l’abonnement';

  @override
  String get settingsICloud => 'Synchronisation iCloud';

  @override
  String get settingsICloudOn =>
      'Les chansons se synchronisent sur tes appareils';

  @override
  String get settingsICloudOff => 'Les chansons restent sur cet appareil';

  @override
  String get settingsICloudUnavailable =>
      'Connecte-toi à iCloud dans Réglages pour synchroniser';

  @override
  String get settingsLyricsLanguage => 'Langue des paroles par défaut';

  @override
  String get settingsLyricsLanguageAuto => 'Selon le pays';

  @override
  String get settingsTerms => 'Conditions d’utilisation';

  @override
  String get settingsPrivacy => 'Politique de confidentialité';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutTitle => 'À propos de la génération';

  @override
  String get aboutSubtitle => 'Comment Songlet crée tes chansons';

  @override
  String get aboutLyriaTitle => 'Propulsé par Lyria 3 de Google';

  @override
  String get aboutLyriaBody =>
      'Les chansons sont générées par Lyria 3 de Google via l’API Gemini. Lyria 3 est un modèle de génération musicale qui transforme tes idées en chansons originales.';

  @override
  String get aboutWatermarkTitle => 'Filigrane intégré';

  @override
  String get aboutWatermarkBody =>
      'Chaque chanson contient un filigrane SynthID de Google. Il permet d’identifier la musique générée par IA et ne peut pas être retiré.';

  @override
  String get aboutImitationTitle => 'Aucune imitation d’artistes réels';

  @override
  String get aboutImitationBody =>
      'Songlet n’imite jamais d’artistes réels, leur voix ou un style précis. Les chansons sont originales et créées à partir de tes idées, descriptions et photos.';

  @override
  String get aboutPrivacyTitle => 'Ta vie privée compte';

  @override
  String get aboutPrivacyBody =>
      'Les photos et descriptions sont supprimées de nos serveurs sous 24 heures. Nous ne conservons ni tes images ni tes descriptions après la création de ta chanson.';

  @override
  String get aboutBanner =>
      'Chaque chanson partagée est signalée comme générée par IA.';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · Créé avec Google Lyria 3';
  }

  @override
  String get festivalKicker => 'Vis ton histoire';

  @override
  String get festivalComing => 'approche !';

  @override
  String get festivalBody => 'Crée une chanson unique pour célébrer.';

  @override
  String festivalCta(String festival) {
    return 'Créer une chanson pour $festival';
  }

  @override
  String get festivalPickOccasion => 'Choisis une occasion et commence à créer';

  @override
  String get festivalLanguagesTitle => 'Des chansons dans ta langue';

  @override
  String festivalLanguagesBody(String language) {
    return 'Des chansons en $language et 12 autres langues';
  }

  @override
  String get unavailableTitle => 'Temporairement indisponible';

  @override
  String get unavailableMessage =>
      'Songlet ne peut pas créer de chansons pour le moment. Ta bibliothèque fonctionne toujours — réessaie dans un instant.';

  @override
  String get paywallHeroTitle => 'Passe à la chanson complète';

  @override
  String get paywallHeroSubtitle =>
      'Transforme ton idée en une chanson complète, de meilleure qualité et avec tous les droits.';

  @override
  String get paywallBenefitSongs => 'Plus de chansons';

  @override
  String get paywallBenefitQuality => 'Meilleure qualité';

  @override
  String get paywallBenefitCommercial => 'Usage commercial';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString chansons complètes par mois',
      one: '$countString chanson complète par mois',
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
      other: '$countString extraits par mois',
      one: '$countString extrait par mois',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'Téléchargement MP3';

  @override
  String get planMp3Wav => 'Téléchargement MP3 + WAV';

  @override
  String get planLicense => 'Licence commerciale';

  @override
  String get planPriority => 'Génération prioritaire';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Essai gratuit de $daysString jours';
  }

  @override
  String planPerYear(String price) {
    return '$price/an';
  }

  @override
  String planPerMonth(String price) {
    return '$price/mois';
  }

  @override
  String get packTitle => 'Besoin de quelques-unes seulement ?';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pack de $countString chansons',
      one: 'Pack de $countString chanson',
    );
    return '$_temp0';
  }

  @override
  String get packNote => 'sans date d’expiration';

  @override
  String get valueForever => 'Tes chansons, pour toujours';

  @override
  String get valueDownloads => 'Téléchargements haute qualité';

  @override
  String get valueCommercial => 'Usage commercial autorisé';

  @override
  String get valuePrivate => 'Confidentialité avant tout';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return 'Après l’essai gratuit, $pricePerPeriod seront facturés automatiquement. Annule à tout moment avant la fin de l’essai.';
  }

  @override
  String get paywallSubscribe => 'S’abonner';

  @override
  String get paywallBuyPack => 'Acheter le pack';

  @override
  String get templateBirthdayWish => 'Vœux d’anniversaire';

  @override
  String get templateBirthdayWishHint =>
      'Une chanson spéciale pour un jour spécial';

  @override
  String get templateBirthdayParty => 'Fête d’anniversaire';

  @override
  String get templateBirthdayPartyHint =>
      'Mets l’ambiance pour la star du jour';

  @override
  String get templateLoveStory => 'Histoire d’amour';

  @override
  String get templateLoveStoryHint => 'Votre histoire mise en musique';

  @override
  String get templateThankAFriend => 'Merci l’ami';

  @override
  String get templateThankAFriendHint =>
      'Dire merci comme les mots ne le peuvent pas';

  @override
  String get templatePartyInvite => 'Invitation à la fête';

  @override
  String get templatePartyInviteHint => 'Réunis tout le monde';

  @override
  String get templateWedding => 'Mariage';

  @override
  String get templateWeddingHint => 'Une chanson pour leur moment éternel';

  @override
  String get templateInMemory => 'En mémoire';

  @override
  String get templateInMemoryHint => 'Rends hommage à quelqu’un qui compte';

  @override
  String get templateFestival => 'Fêtes';

  @override
  String get templateFestivalHint =>
      'Des vœux chaleureux pour une saison spéciale';

  @override
  String get templateRingtone => 'Sonnerie';

  @override
  String get templateRingtoneHint => 'Une courte boucle rien qu’à toi';

  @override
  String get templateTeamAnthem => 'Hymne d’équipe';

  @override
  String get templateTeamAnthemHint => 'Enflamme l’équipe et les supporters';

  @override
  String get templateSportsRecap => 'Résumé du match';

  @override
  String get templateSportsRecapHint => 'Le grand match en chanson';

  @override
  String get templateRapBattle => 'Battle de rap';

  @override
  String get templateRapBattleHint => 'Des rimes amicales pour un rival amical';

  @override
  String get templateComedy => 'Humour';

  @override
  String get templateComedyHint => 'Les blagues entre vous, avec un refrain';

  @override
  String get templatePetAnthem => 'Hymne pour animal';

  @override
  String get templatePetAnthemHint =>
      'Un générique pour ton meilleur compagnon';

  @override
  String get templateHometown => 'Ville natale';

  @override
  String get templateHometownHint =>
      'De l’amour pour l’endroit que tu appelles chez toi';

  @override
  String get templateBusinessPromo => 'Pub pour ton commerce';

  @override
  String get templateBusinessPromoHint =>
      'Un air entraînant pour ta boutique ou ta marque';

  @override
  String get templateCustom => 'Ta propre idée';

  @override
  String get mvRecommended => 'Recommandé';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString s';
  }

  @override
  String get mvViewProgress => 'Voir la progression';

  @override
  String mvIntentWaiting(String level) {
    return '$level attend des crédits';
  }

  @override
  String get mvSongExpiredAction => 'Refaire la chanson';

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
      other: '$requiredString crédits',
      one: '$requiredString crédit',
    );
    return '$level demande $_temp0. Tu en as $availableString.';
  }

  @override
  String get mvQuotaBuyAndContinue => 'Acheter et continuer';

  @override
  String get mvQuotaMayNeedTwice =>
      'Là où tu es, un pack peut ne pas suffire : il en faudra peut-être deux.';

  @override
  String get mvQuotaAutoRetry => 'Ta vidéo démarre dès que l’achat est validé.';

  @override
  String get mvAutoLyricMaking => 'Ta vidéo lyrics est en cours';

  @override
  String get mvAutoChorusDetail =>
      'Faite à partir de cette chanson, avec tes crédits';

  @override
  String mvAutoReady(String level) {
    return '$level est prête';
  }

  @override
  String get mvAutoView => 'Voir';

  @override
  String get mvUpgradeChorus => 'Créer une vidéo du refrain';

  @override
  String get mvAutoFailed => 'La vidéo n’a pas pu démarrer';

  @override
  String get mvLeaveHint =>
      'Tu peux quitter cet écran : on te prévient quand elle devrait être prête.';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: 'Tes $creditsString crédits sont remboursés.',
      one: 'Ton crédit est remboursé.',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => 'Cette vidéo n’a pas abouti';

  @override
  String get mvRejectedTitle => 'Une photo n’a pas pu être utilisée';

  @override
  String get mvRejectedBody =>
      'Le modèle vidéo a refusé l’une de tes photos de référence. Modifie les photos et réessaie.';

  @override
  String get mvAdjustPhotos => 'Modifier les photos et réessayer';

  @override
  String get mvTryChorus => 'Plutôt une vidéo du refrain';

  @override
  String get mvPreparingPhotos => 'Envoi de tes photos…';

  @override
  String get mvPreparingSubmit => 'Envoi de ta vidéo…';

  @override
  String get mvNotifyTitle => 'Ta vidéo devrait être prête';

  @override
  String mvNotifyBody(String level) {
    return '$level — touche pour la regarder.';
  }

  @override
  String get mvRegenerate => 'En faire une autre';

  @override
  String get mvEntryTitle => 'En faire une vidéo';

  @override
  String get mvEntrySubtitle =>
      'Vidéos lyrics, du refrain et complètes, avec des crédits';

  @override
  String get mvEntryDisabled => 'Disponible une fois la chanson terminée';

  @override
  String get mvEntryChoose => 'Choisir une vidéo';

  @override
  String get mvEntryWatch => 'Regarder la vidéo';

  @override
  String get mvChipReady => 'Vidéo';

  @override
  String get mvChipMaking => 'Vidéo en cours';

  @override
  String get lengthAutoVideo => 'Créer aussi une vidéo lyrics';

  @override
  String get lengthAutoVideoHint =>
      'Prête quelques minutes après la chanson · avec des crédits';

  @override
  String get lengthSongAndChorus => 'Chanson + vidéo du refrain';

  @override
  String get lengthSongAndChorusHint =>
      'La chanson entière, puis une vidéo du refrain de 30 secondes';

  @override
  String get paywallVideoGroup => 'Clips vidéo';

  @override
  String get planVideoIncluded => 'Ton quota sert aussi aux clips vidéo';

  @override
  String get settingsVideoCredits => 'Crédits vidéo';

  @override
  String get createGenrePop => 'Pop';

  @override
  String get createGenreHipHopRap => 'Hip-hop et rap';

  @override
  String get createGenreRock => 'Rock';

  @override
  String get createGenreKPop => 'K-pop';

  @override
  String get createGenreLatin => 'Latino';

  @override
  String get createGenreElectronic => 'Électro';

  @override
  String get createGenreRnb => 'R&B';

  @override
  String get createGenreCountry => 'Country';

  @override
  String get createGenreAfrobeats => 'Afrobeats';

  @override
  String get createGenreReggae => 'Reggae';

  @override
  String get createGenreJazzBlues => 'Jazz et blues';

  @override
  String get createGenreClassical => 'Classique';

  @override
  String get createGenreFolk => 'Folk';

  @override
  String get createGenreLofi => 'Lo-fi';

  @override
  String get createGenreAcoustic => 'Acoustique';

  @override
  String get createGenreCinematic => 'Musique de film';

  @override
  String get createGenreAmbient => 'Ambient';

  @override
  String get createGenreBossaNova => 'Bossa nova';

  @override
  String get createGenreIndiePop => 'Pop indé';

  @override
  String get createGenreContemporaryRnb => 'R&B contemporain';

  @override
  String get createGenreAlternativeCountry => 'Country alternative';

  @override
  String get createGenreGarageRock => 'Garage rock';

  @override
  String get createGenreGrime => 'Grime';

  @override
  String get createGenreIndieFolk => 'Folk indé';

  @override
  String get createGenreSynthpop => 'Synthpop';

  @override
  String get createGenrePianoBallad => 'Ballade au piano';

  @override
  String get createGenreSurfRock => 'Surf rock';

  @override
  String get createGenreDeepHouse => 'Deep house';

  @override
  String get createGenreMinimalTechno => 'Techno minimale';

  @override
  String get createGenreFrenchYeyePop => 'Yé-yé des années 60';

  @override
  String get createGenreChillout => 'Chill-out';

  @override
  String get createGenreJPopIndiePop => 'J-pop indé';

  @override
  String get createGenreChiptune => 'Chiptune';

  @override
  String get createGenreDiscoFunk => 'Disco-funk';

  @override
  String get createGenreReggaeton => 'Reggaeton';

  @override
  String get createGenreCumbia => 'Cumbia';

  @override
  String get createGenreLatinJazz => 'Jazz latino';

  @override
  String get createGenreBhangra => 'Bhangra';

  @override
  String get createGenreIndianClassical => 'Classique indien';

  @override
  String get createGenreLofiHipHop => 'Hip-hop lo-fi';

  @override
  String profileAccountIdWithValue(String id) {
    return 'Identifiant du compte: $id';
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
  String get createVocalsCustomSummary => 'Auto — selon ta description';

  @override
  String mvChipMakingWithProgress(String progress) {
    return 'Vidéo en cours · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return 'La vidéo n’a pas pu démarrer · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    return 'Crédits vidéo : $creditsString';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => 'Inspiration';

  @override
  String inspirationPlay(String name) {
    return 'Écouter $name';
  }

  @override
  String get inspirationStop => 'Arrêter l’extrait';

  @override
  String get inspirationNameSoundscape => 'Paysage sonore';

  @override
  String get inspirationStyleSoundscape => 'Textures ambiantes, sans voix';

  @override
  String get inspirationNameBackgroundMusic => 'Musique de fond';

  @override
  String get inspirationStyleBackgroundMusic =>
      'Instrumental léger pour vidéos';

  @override
  String get inspirationNameMemorizeSomething => 'Pour mémoriser';

  @override
  String get inspirationStyleMemorizeSomething =>
      'Pop entraînante pour mémoriser';

  @override
  String get inspirationNameTextMessages => 'Tes messages en chanson';

  @override
  String get inspirationStyleTextMessages =>
      'Pop malicieuse tirée de tes messages';

  @override
  String get inspirationNameIntroMusic => 'Musique d’intro';

  @override
  String get inspirationStyleIntroMusic =>
      'Ouverture cinématographique audacieuse';

  @override
  String get inspirationNameMontage => 'Montage';

  @override
  String get inspirationStyleMontage =>
      'Montée enthousiaste pour tes temps forts';

  @override
  String get inspirationNameSayItWithATrack => 'Dis-le en chanson';

  @override
  String get inspirationStyleSayItWithATrack => 'Ballade pop sincère';

  @override
  String get inspirationNameBrandJingle => 'Jingle de marque';

  @override
  String get inspirationStyleBrandJingle =>
      'Accroche courte, lumineuse et mémorable';

  @override
  String get inspirationNameRingtone => 'Sonnerie';

  @override
  String get inspirationStyleRingtone => 'Accroche de 30 secondes en boucle';

  @override
  String get inspirationNameStreaming => 'Streaming';

  @override
  String get inspirationStyleStreaming =>
      'Intro électro énergique pour un live';

  @override
  String get inspirationNameSpeechToTrack => 'De la voix à la chanson';

  @override
  String get inspirationStyleSpeechToTrack => 'Ta voix transformée en chanson';

  @override
  String get inspirationNameRapBattle => 'Battle de rap';

  @override
  String get inspirationStyleRapBattle => 'Hip-hop percutant';

  @override
  String get inspirationNameComedy => 'Humour';

  @override
  String get inspirationStyleComedy => 'Décalé, joyeux, plein d’humour';

  @override
  String get inspirationNameTeamAnthem => 'Hymne d’équipe';

  @override
  String get inspirationStyleTeamAnthem => 'Chant de stade rock';

  @override
  String get inspirationNameSportsRecap => 'Résumé du match';

  @override
  String get inspirationStyleSportsRecap => 'Temps forts orchestraux épiques';

  @override
  String get inspirationNamePartyInvite => 'Invitation à la fête';

  @override
  String get inspirationStylePartyInvite => 'Invitation dance-pop';

  @override
  String get inspirationNameHappyBirthday => 'Joyeux anniversaire';

  @override
  String get inspirationStyleHappyBirthday =>
      'Chanson d’anniversaire acoustique et chaleureuse';

  @override
  String get inspirationNameFriendAppreciation => 'Merci les amis';

  @override
  String get inspirationStyleFriendAppreciation => 'Indie pop qui fait du bien';

  @override
  String get inspirationNameLoveStory => 'Histoire d’amour';

  @override
  String get inspirationStyleLoveStory => 'Ballade R&B romantique';

  @override
  String get inspirationNameBirthdayRoast => 'Anniversaire taquin';

  @override
  String get inspirationStyleBirthdayRoast => 'Chanson d’anniversaire espiègle';

  @override
  String get inspirationNameOdeToYourPet => 'Ode à ton animal';

  @override
  String get inspirationStyleOdeToYourPet => 'Pop mignonne et sautillante';

  @override
  String get inspirationNameHometownTribute => 'Hommage à ta ville';

  @override
  String get inspirationStyleHometownTribute => 'Folk nostalgique';

  @override
  String get inspirationNameWeatherReport => 'Bulletin météo';

  @override
  String get inspirationStyleWeatherReport => 'Groove lounge enjoué';

  @override
  String get inspirationNameBusinessPromo => 'Pub pour ton commerce';

  @override
  String get inspirationStyleBusinessPromo => 'Pop d’entreprise assurée';

  @override
  String get inspirationStyleBirthdayWish =>
      'Chanson sincère pour leur jour spécial';

  @override
  String get inspirationStyleBirthdayParty =>
      'Hymne festif et entraînant pour la star de l\'anniversaire';

  @override
  String get inspirationStyleThankAFriend =>
      'Chanson de remerciement chaleureuse et reconnaissante';

  @override
  String get inspirationStyleWedding =>
      'Chanson joyeuse et romantique pour le grand jour';

  @override
  String get inspirationStyleInMemory => 'Hommage doux et plein d\'espoir';

  @override
  String get inspirationStyleFestival => 'Vœux de saison lumineux et festifs';

  @override
  String get inspirationStylePetAnthem =>
      'Thème tendre et sautillant pour un animal';

  @override
  String get inspirationStyleHometown =>
      'Hymne fier et nostalgique à sa ville natale';

  @override
  String get settingsSectionLanguage => 'Langue';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsCredits => 'Crédits';

  @override
  String get settingsAccountId => 'ID du compte';

  @override
  String get settingsCopyAccountId => 'Copier l’ID du compte';

  @override
  String get devSectionTitle => 'Développeur (DEV uniquement)';

  @override
  String get devKeychainReset => 'Supprimer les clés du trousseau';

  @override
  String get devKeychainResetHint => 'ID de l’appareil et jetons de session';

  @override
  String get devKeychainResetConfirmTitle =>
      'Supprimer les clés du trousseau ?';

  @override
  String get devKeychainResetConfirmBody =>
      'L’ID de l’appareil et les jetons de session sont effacés du trousseau. Le compte invité actuel est irrécupérable ; l’app se connecte en tant que nouvel invité.';

  @override
  String get devKeychainResetDone => 'Clés supprimées — nouvel invité connecté';

  @override
  String get settingsAppLanguage => 'Langue de l’app';

  @override
  String get settingsLanguageSystem => 'Langue du système';

  @override
  String settingsLanguageSystemValue(String language) {
    return 'Système ($language)';
  }

  @override
  String get settingsLanguageNativeName => 'Français';

  @override
  String get settingsLanguageSaveFailed =>
      'Impossible d’enregistrer la langue. Réessaie.';

  @override
  String get settingsLyricsLanguageHint => 'Pour les nouvelles chansons.';

  @override
  String composerRemoveInspiration(String name) {
    return 'Retirer $name';
  }

  @override
  String get composerPromptHint =>
      'Décris la chanson ou choisis une idée ci-dessus';

  @override
  String get composerPromptHintWide => 'Décris la chanson ou choisis une idée';

  @override
  String get composerWordsLabel => 'Tes mots';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString photos ajoutées',
      one: '$countString photo ajoutée',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return 'Options de la chanson : $summary';
  }

  @override
  String get composerOptionsShow => 'Afficher les options';

  @override
  String get composerOptionsHide => 'Masquer les options';

  @override
  String get composerSummaryAnyVocals => 'Toute voix';

  @override
  String get composerSummaryAnyGenre => 'Tout genre';

  @override
  String get composerSummaryLyrics => 'Paroles perso';

  @override
  String get composerSummaryVideo => 'Vidéo lyrics';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Créer l’aperçu · gratuit',
      'preview': 'Créer l’aperçu · 1 aperçu',
      'other': 'Créer l’aperçu',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Créer l’aperçu pour $name · gratuit',
      'preview': 'Créer l’aperçu pour $name · 1 aperçu',
      'other': 'Créer l’aperçu pour $name',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': 'Créer la chanson complète · 1 chanson',
      'other': 'Créer la chanson complète',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => 'Utiliser ce texte';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level démarre dans $seconds s';
  }

  @override
  String planPerWeek(String price) {
    return '$price/sem.';
  }

  @override
  String get planCreditsWeekly => 'De nouveaux crédits chaque semaine';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'votre premier jour',
      'week': 'votre première semaine',
      'month': 'votre premier mois',
      'year': 'votre première année',
      'other': 'votre première période',
    });
    return '$percent % de réduction sur $_temp0';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return 'Après le tarif d’introduction de $introPrice, $pricePerPeriod vous seront facturés automatiquement. Résiliez à tout moment avant le renouvellement.';
  }

  @override
  String get storePreviewAHook => 'Commencez par son prénom';

  @override
  String get storePreviewAWords => 'Ajoutez trois mots';

  @override
  String get storePreviewAWait => 'Votre chanson s\'écrit';

  @override
  String get storePreviewAChorus => 'Son prénom dans le refrain';

  @override
  String get storePreviewAEnd => 'Une chanson à son prénom';

  @override
  String get storePreviewBHook => 'Partez de vos photos';

  @override
  String get storePreviewBVideo => 'Ajoutez un clip paroles';

  @override
  String get storePreviewBWait => 'Votre chanson s\'écrit';

  @override
  String get storePreviewBLyrics => 'Paroles synchronisées';

  @override
  String get storePreviewBMood => 'Vos photos donnent le ton.';

  @override
  String get storePreviewBShare => 'Partagez la vidéo.';

  @override
  String get storePreviewBLanguage => 'Paroles dans votre langue';

  @override
  String get storePreviewAShare => 'Envoyez-la en carte';

  @override
  String get storePreviewCta => 'Créez votre première chanson';

  @override
  String get storePreviewDisclosure => 'Nécessite un abonnement ou des crédits';

  @override
  String get storeCreativeHeader => 'Des chansons pour ceux que vous aimez';

  @override
  String get storeCreativeSearch => 'Un prénom devient une chanson';

  @override
  String get storeCreativeBirthday => 'Une chanson d\'anniversaire à son nom';

  @override
  String get storeCreativePhoto => 'Vos photos deviennent une chanson';

  @override
  String get storeCreativeWedding => 'Une chanson pour votre mariage';
}
