// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get startupLoading => 'Tuning up…';

  @override
  String get commonErrorTitle => 'Something went wrong';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredMessage => 'A new version is required to continue.';

  @override
  String get updateNow => 'Update now';

  @override
  String get maintenanceTitle => 'Scheduled maintenance';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Estimated to resume in about $minutesString min';
  }

  @override
  String get featureUnavailable => 'This feature is temporarily unavailable.';

  @override
  String get navProfile => 'Profile';

  @override
  String get navStore => 'Store';

  @override
  String get navUpload => 'Upload';

  @override
  String get uploadTitle => 'Uploads';

  @override
  String get uploadSubtitle =>
      'Presigned direct-to-R2 upload with hashing, instant dedup and progress.';

  @override
  String get uploadPick => 'Choose image & upload';

  @override
  String get uploadAgain => 'Upload another';

  @override
  String get uploadPhaseHashing => 'Hashing…';

  @override
  String get uploadPhaseSigning => 'Requesting upload ticket…';

  @override
  String uploadPhaseUploading(String percent) {
    return 'Uploading $percent';
  }

  @override
  String get uploadPhaseFinalizing => 'Finalizing…';

  @override
  String get uploadDone => 'Uploaded.';

  @override
  String get uploadDedup => 'Instant: this file already existed on the server.';

  @override
  String get uploadOpenLink => 'View file';

  @override
  String get uploadFailed => 'Upload failed.';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'File is too large ($limitString MB max).';
  }

  @override
  String get uploadUnsupportedType => 'Unsupported file type.';

  @override
  String get profileGuestTitle => 'Guest';

  @override
  String get profileGuestSubtitle =>
      'Sign in to keep your purchases across devices.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get profileBalanceLabel => 'Credits';

  @override
  String get profileAccountId => 'Account ID';

  @override
  String get profileFeaturesLabel => 'Active benefits';

  @override
  String get profileNoFeatures => 'No active benefits yet.';

  @override
  String get profileSubscriptionLabel => 'Subscription';

  @override
  String get profileManageSubscription => 'Manage subscription';

  @override
  String get subscriptionActive => 'Active';

  @override
  String get subscriptionInactive => 'None';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete this account?';

  @override
  String get deleteAccountMessage =>
      'This cannot be undone: this account and its credits and benefit records become permanently unreachable, and a fresh account is created. An active app store subscription is not cancelled by deleting the account — manage it in your app store settings, or re-link it later with Restore purchases.';

  @override
  String get deleteAccountConfirm => 'Delete';

  @override
  String get deleteAccountWorking => 'Deleting account…';

  @override
  String get deleteAccountDone => 'Account deleted.';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Member since $dateString';
  }

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginUsername => 'Username';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get paywallTitle => 'Get the full song';

  @override
  String get paywallSubtitle =>
      'Turn your preview into a 2-minute song with lyrics — yours to download and use.';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallAutoRenewNotice =>
      'Payment is charged to your Apple Account at confirmation. Subscriptions renew automatically at the same price and period unless cancelled at least 24 hours before the end of the current period. A free trial converts to a paid subscription when it ends. Manage or cancel anytime in your App Store account settings.';

  @override
  String get paywallContinue => 'Continue';

  @override
  String get paywallFreeTrial => 'Free trial';

  @override
  String get paywallOffer => 'Offer';

  @override
  String get paywallManage => 'Manage plan';

  @override
  String get paywallTermsOfUse => 'Terms of Use';

  @override
  String get paywallPrivacyPolicy => 'Privacy Policy';

  @override
  String get paywallSubscriptionTerms => 'Subscription Terms';

  @override
  String get commonLinkError => 'Couldn\'t open the link.';

  @override
  String get commonError => 'Something went wrong.';

  @override
  String get commonNetworkError =>
      'Network error — check your connection and try again.';

  @override
  String get commonOfflineError =>
      'You appear to be offline. Check your connection and try again.';

  @override
  String get networkErrorTitle => 'Connection problem';

  @override
  String get configErrorTitle => 'App configuration problem';

  @override
  String get configErrorMessage =>
      'This version can\'t reach our service. Update the app from the App Store, or reinstall it. If the problem persists, contact support.';

  @override
  String get commonAuthError => 'Your session expired — please sign in again.';

  @override
  String get paywallProductsErrorTitle => 'Couldn\'t load products';

  @override
  String get paywallNoProducts => 'No products available right now.';

  @override
  String get paywallPurchaseSuccess => 'Purchase complete — enjoy!';

  @override
  String get paywallProcessing => 'Processing your purchase…';

  @override
  String get paywallVerifying => 'Verifying your purchase…';

  @override
  String get paywallPurchaseFailed => 'Purchase couldn\'t be completed.';

  @override
  String get paywallRestoreStarted => 'Restoring your purchases…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString purchases restored.',
      one: '$countString purchase restored.',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => 'No purchases to restore.';

  @override
  String get paywallDeferred =>
      'Waiting for approval — we\'ll finish once it\'s approved.';

  @override
  String get paywallAlreadySubscribed => 'You\'re already subscribed.';

  @override
  String get paywallBillingRetry =>
      'Update your payment method to keep your subscription.';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString-day free trial';
  }

  @override
  String get cycleOneTime => 'one-time';

  @override
  String get cycleWeekly => '/ week';

  @override
  String get cycleMonthly => '/ month';

  @override
  String get cycleQuarterly => '/ quarter';

  @override
  String get cycleSemiAnnual => '/ 6 months';

  @override
  String get cycleAnnual => '/ year';

  @override
  String get cycleLifetime => 'lifetime';

  @override
  String get navCreate => 'Create';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSettings => 'Settings';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonBack => 'Go back';

  @override
  String get createTitle => 'Who is this song for?';

  @override
  String get occasionBirthday => 'Birthday';

  @override
  String get occasionBirthdayHint => 'A joyful song for their big day';

  @override
  String get occasionAnniversary => 'Anniversary';

  @override
  String get occasionAnniversaryHint => 'Celebrate your story together';

  @override
  String get occasionConfession => 'Love Confession';

  @override
  String get occasionConfessionHint => 'Say what your heart feels';

  @override
  String get occasionWedding => 'Wedding';

  @override
  String get occasionWeddingHint => 'A song for your forever moment';

  @override
  String get occasionMemorial => 'In Memory';

  @override
  String get occasionMemorialHint => 'Honor someone you cherish';

  @override
  String get occasionFestival => 'Festival';

  @override
  String get occasionFestivalHint => 'Warm wishes for a special season';

  @override
  String get occasionBrand => 'Brand Jingle';

  @override
  String get occasionBrandHint => 'A catchy tune for your brand';

  @override
  String get occasionSoundtrack => 'Video Soundtrack';

  @override
  String get occasionSoundtrackHint => 'Music that fits your story';

  @override
  String get festivalNewYear => 'New Year';

  @override
  String get festivalThanksgiving => 'Thanksgiving';

  @override
  String get festivalDiwali => 'Diwali';

  @override
  String get festivalCarnival => 'Carnival';

  @override
  String get festivalEid => 'Eid';

  @override
  String get festivalLunarNewYear => 'Lunar New Year';

  @override
  String get regionTitle => 'Where will it be heard?';

  @override
  String get regionSearchHint => 'Search country';

  @override
  String get regionLanguageSheetTitle => 'Lyrics language';

  @override
  String get countryUS => 'United States';

  @override
  String get countryGB => 'United Kingdom';

  @override
  String get countryCA => 'Canada';

  @override
  String get countryAU => 'Australia';

  @override
  String get countryDE => 'Germany';

  @override
  String get countryFR => 'France';

  @override
  String get countryJP => 'Japan';

  @override
  String get countryKR => 'South Korea';

  @override
  String get countryBR => 'Brazil';

  @override
  String get countryMX => 'Mexico';

  @override
  String get countryIN => 'India';

  @override
  String get countryID => 'Indonesia';

  @override
  String get countryVN => 'Vietnam';

  @override
  String get countryTR => 'Türkiye';

  @override
  String get languageEn => 'English';

  @override
  String get languageFr => 'French';

  @override
  String get languageDe => 'German';

  @override
  String get languageJa => 'Japanese';

  @override
  String get languageKo => 'Korean';

  @override
  String get languagePtBR => 'Portuguese (Brazil)';

  @override
  String get languageEsMX => 'Spanish (Mexico)';

  @override
  String get languageHi => 'Hindi';

  @override
  String get languageId => 'Indonesian';

  @override
  String get languageVi => 'Vietnamese';

  @override
  String get languageTr => 'Turkish';

  @override
  String get languageZhHans => 'Chinese (Simplified)';

  @override
  String get languageZhHant => 'Chinese (Traditional)';

  @override
  String get inputNameLabel => 'Their name';

  @override
  String get inputNameOptionalLabel => 'Name (optional)';

  @override
  String get inputNameHint => 'e.g. Alex';

  @override
  String get inputKeywordsLabel => 'Three words about them';

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
      'These lyrics are mine or I have the right to use them';

  @override
  String get issueRecipientMissing => 'Add their name.';

  @override
  String get issueRecipientTooLong => 'Names can be up to 24 characters.';

  @override
  String get issueBriefMissing =>
      'Tell us about the song — a few words, lyrics or photos.';

  @override
  String get issueDescriptionMissing =>
      'This idea needs your words — write a line about the song.';

  @override
  String get generatingBackToEdit => 'Back to edit';

  @override
  String get issueKeywordTooLong => 'Each word can be up to 20 characters.';

  @override
  String get issueTooManyKeywords => 'Use up to three words.';

  @override
  String get issueArtistName =>
      'Artist names can\'t be used — describe the feeling instead.';

  @override
  String get issueStyleImitation =>
      'We can\'t imitate a singer or a band. Describe the mood instead.';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Lyrics can be up to $limitString characters.';
  }

  @override
  String get issueLyricsNotOriginal =>
      'These lyrics look like an existing song. Please write your own.';

  @override
  String get issueLyricsOwnership => 'Confirm the lyrics are yours to use.';

  @override
  String get issueTooManyPhotos => 'Choose up to 10 photos.';

  @override
  String get photosTitle => 'Pick a few photos';

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
      'Photos are used once to write the song and deleted from our servers within 24 hours.';

  @override
  String get photosAdd => 'Add photos';

  @override
  String get photosCreate => 'Create from photos';

  @override
  String get photosEmpty => 'Choose 1–10 photos of the moment.';

  @override
  String get generatingStepPolishing => 'Polishing your words on this iPhone…';

  @override
  String get generatingStepUploading => 'Sending your photos…';

  @override
  String get generatingStepSubmitting => 'Sending to the studio…';

  @override
  String get errorSafetyBlocked =>
      'We can\'t make this one — try different words, and skip artist names.';

  @override
  String get errorQuotaExhausted =>
      'You\'ve used this month\'s songs. Add a pack or upgrade.';

  @override
  String get errorUpstreamTimeout =>
      'Taking longer than usual. We\'ll keep trying and notify you.';

  @override
  String get errorUpstreamRateLimited =>
      'Lots of songs being made right now. Yours is queued.';

  @override
  String get errorAttestFailed => 'Please update Songlet from the App Store.';

  @override
  String get errorImageRejected =>
      'One of these photos can\'t be used. Try another.';

  @override
  String get errorNetworkOffline =>
      'You\'re offline. Your library still works.';

  @override
  String get errorDownloadLocked =>
      'Downloads aren\'t available for this song — the purchase that made it was refunded or your plan has ended. You can still play it.';

  @override
  String get errorJobAlreadyFinished =>
      'It already finished — there\'s nothing to cancel.';

  @override
  String get errorMvSongNotReady => 'This song isn\'t ready for a video yet.';

  @override
  String get errorMvSongTooLong =>
      'This song is too long for a full video — try a chorus video.';

  @override
  String get errorMvSongExpired =>
      'This song has expired. Generate it again to make a video.';

  @override
  String get errorMvNotFound => 'This video isn\'t available anymore.';

  @override
  String get errorMvPhotosExpired =>
      'Those photos have expired — pick them again.';

  @override
  String get errorMvRenderFailed =>
      'We couldn\'t finish this video. Your credits are back — try again.';

  @override
  String get mvHubTitle => 'Make a video';

  @override
  String mvHubSubtitle(String title) {
    return 'Turn “$title” into a music video.';
  }

  @override
  String get mvLevelLyricVideo => 'Lyric video';

  @override
  String get mvLevelLyricHint => 'A still scene with your lyrics';

  @override
  String get mvLevelChorus => 'Chorus video';

  @override
  String get mvLevelChorusHint => '30 seconds of your chorus, AI-shot';

  @override
  String get mvLevelFull => 'Full-song video';

  @override
  String get mvLevelFullHint => 'The whole song, scene by scene';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString credits',
      one: '$creditsString credit',
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
      other: 'You have $creditsString credits',
      one: 'You have $creditsString credit',
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
      other: '$creditsString more credits needed',
      one: '$creditsString more credit needed',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => 'Checking the price…';

  @override
  String get mvOptionsHeader => 'Options';

  @override
  String get mvAspectLabel => 'Format';

  @override
  String get mvAspectPortrait => 'Portrait';

  @override
  String get mvAspectLandscape => 'Landscape';

  @override
  String get mvAspectSquare => 'Square';

  @override
  String get mvQualityLabel => 'Quality';

  @override
  String get mvQualityStandard => 'Standard';

  @override
  String get mvQualityHigh => 'High';

  @override
  String get mvSubtitlesLabel => 'Lyrics on screen';

  @override
  String get mvPhotosLabel => 'Reference photos';

  @override
  String get mvPhotosHint => 'Set the scene and colours — faces aren\'t used';

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
  String get mvChorusLabel => 'Chorus';

  @override
  String get mvChorusAuto => 'Found automatically';

  @override
  String get mvChorusCustom => 'Choose the moment';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => 'Make video';

  @override
  String get mvBuyPack => 'Get the pack and make it';

  @override
  String get mvSongLocked => 'Your song is saved for the video.';

  @override
  String get mvGeneratingTitle => 'Making your video…';

  @override
  String get mvStageQueued => 'Waiting to start';

  @override
  String get mvStageSlicing => 'Choosing the moments';

  @override
  String get mvStageStoryboarding => 'Writing the storyboard';

  @override
  String get mvStageKeyframing => 'Painting the scenes';

  @override
  String get mvStageRendering => 'Filming the scenes';

  @override
  String get mvStageAssembling => 'Cutting it together';

  @override
  String get mvStageDone => 'Finished';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Scene $doneString of $totalString';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Usually about $minutesString minutes';
  }

  @override
  String get mvCancelRequested => 'Stopping after the current scene…';

  @override
  String get mvCancelTitle => 'Stop this video?';

  @override
  String get mvCancelQueued =>
      'It hasn\'t started yet, so nothing will be used.';

  @override
  String get mvCancelStarted =>
      'It has already started. Scenes already made are charged; the rest comes back.';

  @override
  String get mvCancelConfirm => 'Stop video';

  @override
  String get mvCancelled => 'Video stopped';

  @override
  String get mvCancelledRefunded => 'Video stopped — nothing was used';

  @override
  String get mvNothing => 'No video is being made right now.';

  @override
  String get mvQuotaTitle => 'Not enough credits';

  @override
  String get mvAiLabelBurnedIn =>
      'AI generated — the badge is part of the video';

  @override
  String get mvSave => 'Save to Photos';

  @override
  String get mvSaveFiles => 'Save to Files';

  @override
  String get mvShareText => 'I made this music video with Songlet 🎬';

  @override
  String get mvMissing => 'This video isn\'t on this device anymore.';

  @override
  String get mvDeleteTitle => 'Delete this video?';

  @override
  String get mvDeleteBody => 'It\'s removed from this device.';

  @override
  String get mvDeleted => 'Video deleted';

  @override
  String get mvProvenance =>
      'Made with Google Lyria 3 and AI video models · AI generated';

  @override
  String get detailVideos => 'Videos';

  @override
  String get detailMakeVideo => 'Make a video';

  @override
  String get mvStatusReady => 'Ready';

  @override
  String get mvStatusPending => 'Making…';

  @override
  String get mvStatusFailed => 'Didn\'t finish';

  @override
  String get mvPackTitle => 'Music video';

  @override
  String get mvPackChorusSubtitle => 'One chorus video';

  @override
  String get mvPackFullSubtitle => 'One full-song video';

  @override
  String get paywallMvHeroTitle => 'Make it a video';

  @override
  String get paywallMvHeroSubtitle =>
      'Credits for a music video of your song — yours to save and share.';

  @override
  String get playerAiGenerated => 'AI generated';

  @override
  String get playerLoop => 'Loop';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerPreviewLabel => '30-second preview';

  @override
  String playerTitleFor(String name) {
    return 'For $name';
  }

  @override
  String get downloadSaved => 'Saved to Files.';

  @override
  String get shareComposing => 'Making your share card…';

  @override
  String get shareFailed => 'Couldn\'t make the share card.';

  @override
  String get shareText => 'I made this song with Songlet 🎵';

  @override
  String get paywallBestValue => 'Best value';

  @override
  String get paywallStartTrial => 'Start free trial';

  @override
  String get paywallClose => 'Dismiss';

  @override
  String get paywallSeePlans => 'See subscriptions';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your plan is active — $countString full songs left this period.',
      one: 'Your plan is active — $countString full song left this period.',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => 'Your songs will live here.';

  @override
  String get libraryEmptyAction => 'Make your first song';

  @override
  String get libraryPending => 'Composing…';

  @override
  String get libraryPreviewBadge => 'Preview';

  @override
  String get librarySongBadge => 'Full song';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPlan => 'Your plan';

  @override
  String get settingsPlanUnavailable =>
      'Couldn\'t load your plan. Pull to try again later.';

  @override
  String get tierFree => 'No subscription';

  @override
  String get tierPack => 'Song packs';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString full songs left',
      one: '$countString full song left',
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
      other: '$countString previews left',
      one: '$countString preview left',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Resets $dateString';
  }

  @override
  String get settingsUpgrade => 'Upgrade';

  @override
  String get appTagline => 'Songs for the people you love';

  @override
  String get commonClose => 'Dismiss';

  @override
  String get commonDone => 'Done';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonMore => 'More';

  @override
  String get commonCopy => 'Copy text';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonNotNow => 'Not now';

  @override
  String get commonLearnMore => 'Learn more';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonKeepGoing => 'Keep going';

  @override
  String get composerHint => 'Describe the song you want';

  @override
  String get composerAddPhotos => 'Add photos';

  @override
  String get composerSourceMusicHint => 'Describe it in your own words';

  @override
  String get composerDictate => 'Dictate';

  @override
  String get composerStopDictation => 'Stop dictation';

  @override
  String get lengthPreview => 'Preview';

  @override
  String get lengthFull => 'Full song';

  @override
  String get paramLength => 'Length';

  @override
  String get paramVocals => 'Vocals';

  @override
  String get paramGenre => 'Genre';

  @override
  String templatePlaySample(String name) {
    return 'Play a sample of $name';
  }

  @override
  String get templatePauseSample => 'Pause the sample';

  @override
  String get lengthShort => 'Short';

  @override
  String get lengthShortHint => '30-second preview';

  @override
  String get lengthStandard => 'Standard';

  @override
  String get lengthStandardHint => 'about 2 minutes, Pro';

  @override
  String get vocalsCustom => 'Custom';

  @override
  String get vocalsCustomHint => 'based on your prompt';

  @override
  String get vocalsCustomDetail => 'Vocals style follows your prompt.';

  @override
  String get vocalsOn => 'Vocals on';

  @override
  String get vocalsInstrumental => 'Instrumental';

  @override
  String vocalsLyricsIn(String language) {
    return 'Lyrics are written in $language';
  }

  @override
  String get genreCustom => 'Custom';

  @override
  String get genreCustomHint => 'based on your prompt';

  @override
  String genrePopularIn(String country) {
    return 'Popular in $country';
  }

  @override
  String get genreAll => 'All genres';

  @override
  String get regionHelper =>
      'Changes the 3 recommended genres and the lyrics language';

  @override
  String regionLyricsRow(String language) {
    return 'Lyrics language: $language';
  }

  @override
  String get regionNoMatch => 'No countries match';

  @override
  String get keywordAdd => 'Add a word';

  @override
  String keywordRemove(String word) {
    return 'Remove $word';
  }

  @override
  String get nameClear => 'Clear name';

  @override
  String get lyricsOptional => 'Write your own lyrics (optional)';

  @override
  String get issueRecipientArtistName => 'Artist names can’t be used.';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Keep the description under $limitString characters.';
  }

  @override
  String get voiceRecording => 'Recording…';

  @override
  String get voiceStarting => 'Starting…';

  @override
  String get voiceListening => 'Say who it’s for and what they love…';

  @override
  String get voiceOnDevice => 'On-device transcription';

  @override
  String get voicePermissionDenied =>
      'Allow the microphone and speech recognition for Songlet in Settings to dictate.';

  @override
  String get voiceUnavailable =>
      'Dictation isn’t available for this language on this device.';

  @override
  String get voiceApplied => 'Added from your voice';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String generatingTitleFor(String name) {
    return 'Writing $name’s song…';
  }

  @override
  String get generatingTitleGeneric => 'Writing your song…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Usually about $secondsString seconds';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => 'Progress';

  @override
  String get generatingGlimpse => 'A glimpse of your song';

  @override
  String get generatingCancelTitle => 'Stop this song?';

  @override
  String get generatingCancelQueued =>
      'It hasn’t started yet, so it won’t count toward your allowance.';

  @override
  String get generatingCancelStarted =>
      'It has already started, so it still counts toward your allowance.';

  @override
  String get generatingCancelConfirm => 'Stop song';

  @override
  String get generatingCancelled => 'Song stopped';

  @override
  String get generatingCancelledRefunded => 'Song stopped — nothing was used';

  @override
  String get queueTitle => 'Lots of songs being made right now.';

  @override
  String get queueSubtitle => 'Yours is queued.';

  @override
  String get queuePosition => 'Position';

  @override
  String get queueWait => 'estimated wait';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '≈ $minutesString min';
  }

  @override
  String get generatingNothing => 'Nothing is being made right now.';

  @override
  String get previewGetFull => 'Get the full 2-minute song';

  @override
  String get previewShare => 'Share preview';

  @override
  String get previewAnother => 'Try another version (uses 1 preview)';

  @override
  String get playerPosition => 'Playback position';

  @override
  String get playerPrevSection => 'Previous section';

  @override
  String get playerNextSection => 'Next section';

  @override
  String get playerShuffle => 'Shuffle sections';

  @override
  String get playerRepeat => 'Repeat';

  @override
  String get playerProvenance =>
      'Made with Google Lyria 3 · SynthID watermark · AI generated';

  @override
  String get playerMissing => 'This song isn’t on this device anymore.';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionShare => 'Share';

  @override
  String get actionLicense => 'License';

  @override
  String get actionRegenerate => 'Regenerate';

  @override
  String get actionDetails => 'Details';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionVerse => 'Verse';

  @override
  String get sectionPreChorus => 'Pre-chorus';

  @override
  String get sectionChorus => 'Chorus';

  @override
  String get sectionBridge => 'Bridge';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionHook => 'Hook';

  @override
  String get shareTitle => 'Share card';

  @override
  String get shareSubtitle => 'Choose a theme and layout.';

  @override
  String get shareTheme => 'Theme';

  @override
  String get shareLayout => 'Layout';

  @override
  String get shareLayoutScene => 'With art';

  @override
  String get shareLayoutText => 'Text only';

  @override
  String get paletteTerracotta => 'Terracotta';

  @override
  String get paletteSand => 'Sand';

  @override
  String get paletteOlive => 'Olive';

  @override
  String get paletteNavy => 'Navy';

  @override
  String get shareAction => 'Share';

  @override
  String get shareSaveVideo => 'Save video';

  @override
  String get shareCopyLyrics => 'Copy lyrics';

  @override
  String get shareVideoSaved => 'Saved to Photos';

  @override
  String get shareLyricsCopied => 'Lyrics copied';

  @override
  String get shareCardTagline => 'A song for someone';

  @override
  String get shareSaveFailed =>
      'Couldn’t save the video. Allow Songlet to add to Photos in Settings.';

  @override
  String get downloadReady => 'Full song ready';

  @override
  String get downloadTitle => 'Yours to keep';

  @override
  String get downloadIntro =>
      'Your song is ready. Download high-quality audio and your commercial license below.';

  @override
  String get downloadAudioHeader => 'Download audio';

  @override
  String get downloadAudioNote => 'High quality';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle => 'Best for sharing and everyday listening';

  @override
  String get downloadWavTitle => 'WAV · 44.1 kHz (Premier)';

  @override
  String get downloadWavSubtitle => 'Highest quality for professional use';

  @override
  String get downloadMp3Action => 'Download MP3';

  @override
  String get downloadWavAction => 'Download WAV';

  @override
  String get downloadLicenseAction => 'Download license';

  @override
  String get licenseHeader => 'Commercial license';

  @override
  String get licenseIncluded => 'Included with your plan';

  @override
  String get licenseNotIncluded => 'Comes with a plan or pack';

  @override
  String get licensePdfTitle => 'Commercial license (PDF)';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Generated on $dateString';
  }

  @override
  String licenseId(String id) {
    return 'License ID: $id';
  }

  @override
  String get licenseUsesTitle => 'You can use this song for:';

  @override
  String get usePersonal => 'Personal use';

  @override
  String get usePersonalDetail => 'Gifts, memories, non-commercial';

  @override
  String get useAds => 'Ads & marketing';

  @override
  String get useAdsDetail => 'Promotions, paid campaigns';

  @override
  String get useSocial => 'Social media';

  @override
  String get useSocialDetail => 'TikTok, Instagram, YouTube, etc.';

  @override
  String get usePodcasts => 'Podcasts & videos';

  @override
  String get usePodcastsDetail => 'Monetized content';

  @override
  String get licenseDetailsNote => 'Full details are in the license PDF.';

  @override
  String get saveEnjoyHeader => 'Save and enjoy';

  @override
  String get saveToFiles => 'Save to Files';

  @override
  String get addToMusic => 'Add to Music';

  @override
  String get synthIdNote =>
      'This song contains a SynthID watermark to identify AI-generated content, even after downloading.';

  @override
  String get wavNeedsPremier => 'WAV downloads come with Premier.';

  @override
  String get wavUnavailable =>
      'There\'s no WAV file for this song. WAV files can be saved for 24 hours after a song is made.';

  @override
  String get libraryFilterAll => 'All';

  @override
  String get libraryJustBecause => 'Just because';

  @override
  String libraryPlay(String title) {
    return 'Play $title';
  }

  @override
  String libraryActions(String title) {
    return 'Actions for $title';
  }

  @override
  String get libraryDeleteTitle => 'Delete this song?';

  @override
  String get libraryDeleteBody =>
      'It’s removed from this device. If iCloud sync is on, it’s removed from your other devices too.';

  @override
  String get libraryDeleted => 'Song deleted';

  @override
  String get libraryFailed => 'Didn’t finish';

  @override
  String get libraryNoMatch => 'No songs for this occasion yet.';

  @override
  String get detailFullGenerated => 'Full song generated';

  @override
  String get detailPreviewGenerated => 'Preview generated';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Generated $dateString';
  }

  @override
  String get detailPromptUsed => 'Prompt used';

  @override
  String get detailOccasion => 'Occasion';

  @override
  String get detailCountry => 'Country';

  @override
  String get detailGenre => 'Genre';

  @override
  String get detailKeywords => 'Keywords';

  @override
  String get detailDescription => 'Description';

  @override
  String get detailLyrics => 'Lyrics';

  @override
  String get detailGenerationId => 'Generation ID';

  @override
  String get detailRegenerate => 'Regenerate same style';

  @override
  String get detailCustomGenre => 'Based on the prompt';

  @override
  String get settingsSectionPlan => 'Purchases';

  @override
  String get settingsSectionLibrary => 'Library';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsRestore => 'Restore purchases';

  @override
  String get settingsManage => 'Manage subscription';

  @override
  String get settingsICloud => 'iCloud sync';

  @override
  String get settingsICloudOn => 'Songs sync across your devices';

  @override
  String get settingsICloudOff => 'Songs stay on this device';

  @override
  String get settingsICloudUnavailable =>
      'Sign in to iCloud in Settings to sync';

  @override
  String get settingsLyricsLanguage => 'Default lyrics language';

  @override
  String get settingsLyricsLanguageAuto => 'Match the country';

  @override
  String get settingsTerms => 'Terms of Use';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutTitle => 'About generation';

  @override
  String get aboutSubtitle => 'How Songlet makes your songs';

  @override
  String get aboutLyriaTitle => 'Powered by Google’s Lyria 3';

  @override
  String get aboutLyriaBody =>
      'Songs are generated by Google’s Lyria 3 via the Gemini API. Lyria 3 is a music generation model that turns your ideas into original songs.';

  @override
  String get aboutWatermarkTitle => 'Built-in watermark';

  @override
  String get aboutWatermarkBody =>
      'Every song includes a SynthID watermark from Google. It helps identify AI-generated music and can’t be removed.';

  @override
  String get aboutImitationTitle => 'No imitations of real artists';

  @override
  String get aboutImitationBody =>
      'Songlet never imitates real artists, their voices or specific styles. Songs are original and created from your own ideas, prompts and photos.';

  @override
  String get aboutPrivacyTitle => 'Your privacy matters';

  @override
  String get aboutPrivacyBody =>
      'Photos and prompts are deleted from our servers within 24 hours. We don’t keep your images or prompts after your song has been generated.';

  @override
  String get aboutBanner => 'Every song you share is labeled AI generated.';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · Made with Google Lyria 3';
  }

  @override
  String get festivalKicker => 'Live your story';

  @override
  String get festivalComing => 'is coming!';

  @override
  String get festivalBody => 'Make a one-of-a-kind song to celebrate.';

  @override
  String festivalCta(String festival) {
    return 'Make a $festival song';
  }

  @override
  String get festivalPickOccasion => 'Pick an occasion and start creating';

  @override
  String get festivalLanguagesTitle => 'Songs in your language';

  @override
  String festivalLanguagesBody(String language) {
    return 'Make songs in $language and 12 more languages';
  }

  @override
  String get unavailableTitle => 'Temporarily unavailable';

  @override
  String get unavailableMessage =>
      'Songlet can’t make songs right now. Your library still works — try again in a little while.';

  @override
  String get paywallHeroTitle => 'Make it a full song';

  @override
  String get paywallHeroSubtitle =>
      'Turn your idea into a complete song with higher quality and full rights.';

  @override
  String get paywallBenefitSongs => 'More songs';

  @override
  String get paywallBenefitQuality => 'Higher quality';

  @override
  String get paywallBenefitCommercial => 'Commercial use';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString full songs per month',
      one: '$countString full song per month',
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
      other: '$countString previews per month',
      one: '$countString preview per month',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'MP3 download';

  @override
  String get planMp3Wav => 'MP3 + WAV download';

  @override
  String get planLicense => 'Commercial license';

  @override
  String get planPriority => 'Priority generation';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString-day free trial';
  }

  @override
  String planPerYear(String price) {
    return '$price/yr';
  }

  @override
  String planPerMonth(String price) {
    return '$price/mo';
  }

  @override
  String get packTitle => 'Just need a few?';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString-song pack',
      one: '$countString-song pack',
    );
    return '$_temp0';
  }

  @override
  String get packNote => 'never expires';

  @override
  String get valueForever => 'Your songs, forever';

  @override
  String get valueDownloads => 'High-quality downloads';

  @override
  String get valueCommercial => 'Commercial use allowed';

  @override
  String get valuePrivate => 'Private by design';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return 'After your free trial, you’ll be charged $pricePerPeriod automatically. Cancel anytime before the trial ends.';
  }

  @override
  String get paywallSubscribe => 'Subscribe';

  @override
  String get paywallBuyPack => 'Buy pack';

  @override
  String get templateBirthdayWish => 'Birthday Wish';

  @override
  String get templateBirthdayWishHint => 'A special song for their special day';

  @override
  String get templateBirthdayParty => 'Birthday Party';

  @override
  String get templateBirthdayPartyHint =>
      'Turn up the party for the birthday star';

  @override
  String get templateLoveStory => 'Love Story';

  @override
  String get templateLoveStoryHint => 'Your story together, set to music';

  @override
  String get templateThankAFriend => 'Thank a Friend';

  @override
  String get templateThankAFriendHint => 'Say thank you the way words can’t';

  @override
  String get templatePartyInvite => 'Party Invite';

  @override
  String get templatePartyInviteHint => 'Get everyone to the party';

  @override
  String get templateWedding => 'Wedding';

  @override
  String get templateWeddingHint => 'A song for their forever moment';

  @override
  String get templateInMemory => 'In Memory';

  @override
  String get templateInMemoryHint => 'Honor someone you cherish';

  @override
  String get templateFestival => 'Festival';

  @override
  String get templateFestivalHint => 'Warm wishes for a special season';

  @override
  String get templateRingtone => 'Ringtone';

  @override
  String get templateRingtoneHint => 'A short loop that’s all yours';

  @override
  String get templateTeamAnthem => 'Team Anthem';

  @override
  String get templateTeamAnthemHint => 'Fire up the team and the crowd';

  @override
  String get templateSportsRecap => 'Sports Recap';

  @override
  String get templateSportsRecapHint => 'The big game, told as a song';

  @override
  String get templateRapBattle => 'Rap Battle';

  @override
  String get templateRapBattleHint => 'Friendly bars for a friendly rival';

  @override
  String get templateComedy => 'Comedy';

  @override
  String get templateComedyHint => 'Inside jokes, now with a chorus';

  @override
  String get templatePetAnthem => 'Pet Anthem';

  @override
  String get templatePetAnthemHint => 'A theme song for your best buddy';

  @override
  String get templateHometown => 'Hometown';

  @override
  String get templateHometownHint => 'Love for the place you call home';

  @override
  String get templateBusinessPromo => 'Business Promo';

  @override
  String get templateBusinessPromoHint =>
      'A catchy tune for your shop or brand';

  @override
  String get templateCustom => 'Your own idea';

  @override
  String get mvRecommended => 'Recommended';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString s';
  }

  @override
  String get mvViewProgress => 'See progress';

  @override
  String mvIntentWaiting(String level) {
    return '$level is waiting for credits';
  }

  @override
  String get mvSongExpiredAction => 'Make the song again';

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
      other: '$requiredString credits',
      one: '$requiredString credit',
    );
    String _temp1 = intl.Intl.pluralLogic(
      available,
      locale: localeName,
      other: '$availableString credits',
      one: '$availableString credit',
    );
    return '$level needs $_temp0. You have $_temp1.';
  }

  @override
  String get mvQuotaBuyAndContinue => 'Buy and continue';

  @override
  String get mvQuotaMayNeedTwice =>
      'Where you are, one pack may not cover it — you may need two.';

  @override
  String get mvQuotaAutoRetry =>
      'Your video starts as soon as the purchase goes through.';

  @override
  String get mvAutoLyricMaking => 'Making your lyric video';

  @override
  String get mvAutoChorusDetail => 'Made from this song with your credits';

  @override
  String mvAutoReady(String level) {
    return '$level is ready';
  }

  @override
  String get mvAutoView => 'View';

  @override
  String get mvUpgradeChorus => 'Make a chorus video';

  @override
  String get mvAutoFailed => 'The video couldn’t start';

  @override
  String get mvLeaveHint =>
      'You can leave this screen — we’ll let you know when it should be ready.';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: 'Your $creditsString credits are back.',
      one: 'Your $creditsString credit is back.',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => 'This video didn’t finish';

  @override
  String get mvRejectedTitle => 'A photo couldn’t be used';

  @override
  String get mvRejectedBody =>
      'The video model declined one of your reference photos. Adjust the photos and try again.';

  @override
  String get mvAdjustPhotos => 'Adjust photos and try again';

  @override
  String get mvTryChorus => 'Make a chorus video instead';

  @override
  String get mvPreparingPhotos => 'Uploading your photos…';

  @override
  String get mvPreparingSubmit => 'Sending your video…';

  @override
  String get mvNotifyTitle => 'Your video should be ready';

  @override
  String mvNotifyBody(String level) {
    return '$level — tap to watch.';
  }

  @override
  String get mvRegenerate => 'Make another';

  @override
  String get mvEntryTitle => 'Make it a video';

  @override
  String get mvEntrySubtitle =>
      'Lyric, chorus and full-song videos, made with credits';

  @override
  String get mvEntryDisabled => 'Available once the song is finished';

  @override
  String get mvEntryChoose => 'Choose a video';

  @override
  String get mvEntryWatch => 'Watch video';

  @override
  String get mvChipReady => 'Video';

  @override
  String get mvChipMaking => 'Making video';

  @override
  String get lengthAutoVideo => 'Also make a lyric video';

  @override
  String get lengthAutoVideoHint =>
      'Ready a few minutes after the song · uses credits';

  @override
  String get lengthSongAndChorus => 'Song + chorus video';

  @override
  String get lengthSongAndChorusHint =>
      'The full song, then a 30-second chorus video';

  @override
  String get paywallVideoGroup => 'Music videos';

  @override
  String get planVideoIncluded => 'Your allowance also makes music videos';

  @override
  String get settingsVideoCredits => 'Video credits';

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
  String get createGenreElectronic => 'Electronic';

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
  String get createGenreClassical => 'Classical';

  @override
  String get createGenreFolk => 'Folk';

  @override
  String get createGenreLofi => 'Lo-Fi';

  @override
  String get createGenreAcoustic => 'Acoustic';

  @override
  String get createGenreCinematic => 'Cinematic';

  @override
  String get createGenreAmbient => 'Ambient';

  @override
  String get createGenreBossaNova => 'Bossa Nova';

  @override
  String get createGenreIndiePop => 'Indie Pop';

  @override
  String get createGenreContemporaryRnb => 'Contemporary R&B';

  @override
  String get createGenreAlternativeCountry => 'Alternative Country';

  @override
  String get createGenreGarageRock => 'Garage Rock';

  @override
  String get createGenreGrime => 'Grime';

  @override
  String get createGenreIndieFolk => 'Indie Folk';

  @override
  String get createGenreSynthpop => 'Synthpop';

  @override
  String get createGenrePianoBallad => 'Piano Ballad';

  @override
  String get createGenreSurfRock => 'Surf Rock';

  @override
  String get createGenreDeepHouse => 'Deep House';

  @override
  String get createGenreMinimalTechno => 'Minimal Techno';

  @override
  String get createGenreFrenchYeyePop => '1960s French Yé-yé Pop';

  @override
  String get createGenreChillout => 'Chillout';

  @override
  String get createGenreJPopIndiePop => 'J-pop Indie Pop';

  @override
  String get createGenreChiptune => 'Chiptune';

  @override
  String get createGenreDiscoFunk => 'Disco Funk';

  @override
  String get createGenreReggaeton => 'Reggaeton';

  @override
  String get createGenreCumbia => 'Cumbia';

  @override
  String get createGenreLatinJazz => 'Latin Jazz';

  @override
  String get createGenreBhangra => 'Bhangra';

  @override
  String get createGenreIndianClassical => 'Indian Classical';

  @override
  String get createGenreLofiHipHop => 'Lo-Fi Hip Hop';

  @override
  String profileAccountIdWithValue(String id) {
    return 'Account ID: $id';
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
  String get createVocalsCustomSummary => 'Custom — based on your prompt';

  @override
  String mvChipMakingWithProgress(String progress) {
    return 'Making video · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return 'The video couldn’t start · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString credits',
      one: '$creditsString credit',
    );
    return 'Video credits: $_temp0';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => 'Inspiration';

  @override
  String inspirationPlay(String name) {
    return 'Play $name';
  }

  @override
  String get inspirationStop => 'Stop the preview';

  @override
  String get inspirationNameSoundscape => 'Soundscape';

  @override
  String get inspirationStyleSoundscape => 'Ambient textures, no vocals';

  @override
  String get inspirationNameBackgroundMusic => 'Background Music';

  @override
  String get inspirationStyleBackgroundMusic => 'Light instrumental for videos';

  @override
  String get inspirationNameMemorizeSomething => 'Memorize Something';

  @override
  String get inspirationStyleMemorizeSomething => 'Catchy mnemonic pop';

  @override
  String get inspirationNameTextMessages => 'Text Messages';

  @override
  String get inspirationStyleTextMessages => 'Playful pop from your texts';

  @override
  String get inspirationNameIntroMusic => 'Intro Music';

  @override
  String get inspirationStyleIntroMusic => 'Bold cinematic opener';

  @override
  String get inspirationNameMontage => 'Montage';

  @override
  String get inspirationStyleMontage => 'Uplifting build for highlight reels';

  @override
  String get inspirationNameSayItWithATrack => 'Say It With a Track';

  @override
  String get inspirationStyleSayItWithATrack => 'Heartfelt pop ballad';

  @override
  String get inspirationNameBrandJingle => 'Brand Jingle';

  @override
  String get inspirationStyleBrandJingle => 'Short, bright, memorable hook';

  @override
  String get inspirationNameRingtone => 'Ringtone';

  @override
  String get inspirationStyleRingtone => '30-second loopable hook';

  @override
  String get inspirationNameStreaming => 'Streaming';

  @override
  String get inspirationStyleStreaming => 'Energetic electronic stream intro';

  @override
  String get inspirationNameSpeechToTrack => 'Speech to Track';

  @override
  String get inspirationStyleSpeechToTrack => 'Your voice turned into a song';

  @override
  String get inspirationNameRapBattle => 'Rap Battle';

  @override
  String get inspirationStyleRapBattle => 'Hard-hitting hip-hop';

  @override
  String get inspirationNameComedy => 'Comedy';

  @override
  String get inspirationStyleComedy => 'Quirky, upbeat, tongue-in-cheek';

  @override
  String get inspirationNameTeamAnthem => 'Team Anthem';

  @override
  String get inspirationStyleTeamAnthem => 'Stadium rock chant';

  @override
  String get inspirationNameSportsRecap => 'Sports Recap';

  @override
  String get inspirationStyleSportsRecap => 'Epic orchestral highlights';

  @override
  String get inspirationNamePartyInvite => 'Party Invite';

  @override
  String get inspirationStylePartyInvite => 'Dance-pop invitation';

  @override
  String get inspirationNameHappyBirthday => 'Happy Birthday';

  @override
  String get inspirationStyleHappyBirthday => 'Warm acoustic birthday song';

  @override
  String get inspirationNameFriendAppreciation => 'Friend Appreciation';

  @override
  String get inspirationStyleFriendAppreciation => 'Feel-good indie pop';

  @override
  String get inspirationNameLoveStory => 'Love Story';

  @override
  String get inspirationStyleLoveStory => 'Romantic R&B ballad';

  @override
  String get inspirationNameBirthdayRoast => 'Birthday Roast';

  @override
  String get inspirationStyleBirthdayRoast => 'Cheeky comedic birthday tune';

  @override
  String get inspirationNameOdeToYourPet => 'Ode to Your Pet';

  @override
  String get inspirationStyleOdeToYourPet => 'Cute, bouncy pop';

  @override
  String get inspirationNameHometownTribute => 'Hometown Tribute';

  @override
  String get inspirationStyleHometownTribute => 'Nostalgic folk';

  @override
  String get inspirationNameWeatherReport => 'Weather Report';

  @override
  String get inspirationStyleWeatherReport => 'Playful lounge groove';

  @override
  String get inspirationNameBusinessPromo => 'Business Promo';

  @override
  String get inspirationStyleBusinessPromo => 'Confident corporate pop';

  @override
  String get inspirationStyleBirthdayWish =>
      'Heartfelt song for their special day';

  @override
  String get inspirationStyleBirthdayParty =>
      'Upbeat party anthem for the birthday star';

  @override
  String get inspirationStyleThankAFriend => 'Warm, grateful thank-you song';

  @override
  String get inspirationStyleWedding => 'Joyful, romantic song for the big day';

  @override
  String get inspirationStyleInMemory => 'Gentle, hopeful tribute';

  @override
  String get inspirationStyleFestival => 'Bright, festive seasonal greeting';

  @override
  String get inspirationStylePetAnthem =>
      'Affectionate, bouncy theme for a pet';

  @override
  String get inspirationStyleHometown => 'Proud, nostalgic hometown anthem';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionProfile => 'Profile';

  @override
  String get settingsCredits => 'Credits';

  @override
  String get settingsAccountId => 'Account ID';

  @override
  String get settingsCopyAccountId => 'Copy account ID';

  @override
  String get devSectionTitle => 'Developer (DEV only)';

  @override
  String get devKeychainReset => 'Delete Keychain keys';

  @override
  String get devKeychainResetHint => 'Device ID and session tokens';

  @override
  String get devKeychainResetConfirmTitle => 'Delete Keychain keys?';

  @override
  String get devKeychainResetConfirmBody =>
      'The device ID and session tokens are erased from the Keychain. The current guest account can’t be recovered; the app signs in as a new guest.';

  @override
  String get devKeychainResetDone =>
      'Keychain keys deleted — signed in as a new guest';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsLanguageSystem => 'Use system language';

  @override
  String settingsLanguageSystemValue(String language) {
    return 'System ($language)';
  }

  @override
  String get settingsLanguageNativeName => 'English';

  @override
  String get settingsLanguageSaveFailed =>
      'Couldn\'t save the language. Try again.';

  @override
  String get settingsLyricsLanguageHint => 'Applies to new songs.';

  @override
  String composerRemoveInspiration(String name) {
    return 'Remove $name';
  }

  @override
  String get composerPromptHint => 'Describe the song, or pick an idea above';

  @override
  String get composerPromptHintWide => 'Describe the song, or pick an idea';

  @override
  String get composerWordsLabel => 'Your words';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString photos added',
      one: '$countString photo added',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return 'Song options: $summary';
  }

  @override
  String get composerOptionsShow => 'Show song options';

  @override
  String get composerOptionsHide => 'Hide song options';

  @override
  String get composerSummaryAnyVocals => 'Any vocals';

  @override
  String get composerSummaryAnyGenre => 'Any genre';

  @override
  String get composerSummaryLyrics => 'Own lyrics';

  @override
  String get composerSummaryVideo => 'Lyric video';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Create preview · free',
      'preview': 'Create preview · 1 preview',
      'other': 'Create preview',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Create $name’s preview · free',
      'preview': 'Create $name’s preview · 1 preview',
      'other': 'Create $name’s preview',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': 'Create full song · 1 song',
      'other': 'Create full song',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => 'Use this text';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level starts in $seconds s';
  }

  @override
  String planPerWeek(String price) {
    return '$price/week';
  }

  @override
  String get planCreditsWeekly => 'Fresh credits every week';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'day',
      'week': 'week',
      'month': 'month',
      'year': 'year',
      'other': 'period',
    });
    return '$percent% off your first $_temp0';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return 'After the introductory price of $introPrice, you’ll be charged $pricePerPeriod automatically. Cancel anytime before it renews.';
  }

  @override
  String get storePreviewAHook => 'Start with their name';

  @override
  String get storePreviewAWords => 'Add three words about them';

  @override
  String get storePreviewAWait => 'Your song is being written';

  @override
  String get storePreviewAChorus => 'Their name in the chorus';

  @override
  String get storePreviewAEnd => 'A song with their name in it';

  @override
  String get storePreviewBHook => 'Start with your photos';

  @override
  String get storePreviewBVideo => 'Add a lyric video';

  @override
  String get storePreviewBWait => 'Writing your song';

  @override
  String get storePreviewBLyrics => 'Lyrics in sync, on screen';

  @override
  String get storePreviewBMood => 'Your photos set the mood.';

  @override
  String get storePreviewBShare => 'Share the video.';

  @override
  String get storePreviewBLanguage => 'Lyrics in your language';

  @override
  String get storePreviewAShare => 'Send it as a card';

  @override
  String get storePreviewCta => 'Write your first song';

  @override
  String get storePreviewDisclosure => 'Requires a subscription or credits';

  @override
  String get storeCreativeHeader => 'Songs for the people you love';

  @override
  String get storeCreativeSearch => 'Turn a name into a song';

  @override
  String get storeCreativeBirthday => 'A birthday song with their name';

  @override
  String get storeCreativePhoto => 'Your photos become a song';

  @override
  String get storeCreativeWedding => 'A song for your wedding day';
}
