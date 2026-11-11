// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get commonRetry => 'फिर से कोशिश करें';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get startupLoading => 'सुर मिलाए जा रहे हैं…';

  @override
  String get commonErrorTitle => 'कुछ गड़बड़ हो गई';

  @override
  String get updateRequiredTitle => 'अपडेट ज़रूरी है';

  @override
  String get updateRequiredMessage => 'जारी रखने के लिए नया वर्शन ज़रूरी है।';

  @override
  String get updateNow => 'अभी अपडेट करें';

  @override
  String get maintenanceTitle => 'निर्धारित मेंटेनेंस';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'लगभग $minutesString मिनट में फिर से शुरू होने की उम्मीद है';
  }

  @override
  String get featureUnavailable =>
      'यह फ़ीचर अभी कुछ समय के लिए उपलब्ध नहीं है।';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get navStore => 'स्टोर';

  @override
  String get navUpload => 'अपलोड';

  @override
  String get uploadTitle => 'अपलोड';

  @override
  String get uploadSubtitle =>
      'हैशिंग, तुरंत डुप्लिकेट-जाँच और प्रोग्रेस के साथ प्रीसाइन्ड URL से सीधे R2 पर अपलोड।';

  @override
  String get uploadPick => 'इमेज चुनें और अपलोड करें';

  @override
  String get uploadAgain => 'एक और अपलोड करें';

  @override
  String get uploadPhaseHashing => 'हैश बनाया जा रहा है…';

  @override
  String get uploadPhaseSigning => 'अपलोड टिकट माँगा जा रहा है…';

  @override
  String uploadPhaseUploading(String percent) {
    return 'अपलोड हो रहा है $percent';
  }

  @override
  String get uploadPhaseFinalizing => 'पूरा किया जा रहा है…';

  @override
  String get uploadDone => 'अपलोड हो गया।';

  @override
  String get uploadDedup => 'तुरंत: यह फ़ाइल सर्वर पर पहले से मौजूद थी।';

  @override
  String get uploadOpenLink => 'फ़ाइल देखें';

  @override
  String get uploadFailed => 'अपलोड नहीं हो सका।';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'फ़ाइल बहुत बड़ी है (अधिकतम $limitString MB)।';
  }

  @override
  String get uploadUnsupportedType => 'यह फ़ाइल टाइप सपोर्ट नहीं है।';

  @override
  String get profileGuestTitle => 'गेस्ट';

  @override
  String get profileGuestSubtitle =>
      'अपनी ख़रीदारियाँ सभी डिवाइस पर बनाए रखने के लिए साइन इन करें।';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get profileBalanceLabel => 'क्रेडिट';

  @override
  String get profileAccountId => 'अकाउंट ID';

  @override
  String get profileFeaturesLabel => 'सक्रिय लाभ';

  @override
  String get profileNoFeatures => 'अभी तक कोई सक्रिय लाभ नहीं।';

  @override
  String get profileSubscriptionLabel => 'सब्सक्रिप्शन';

  @override
  String get profileManageSubscription => 'सब्सक्रिप्शन मैनेज करें';

  @override
  String get subscriptionActive => 'सक्रिय';

  @override
  String get subscriptionInactive => 'कोई नहीं';

  @override
  String get profileDeleteAccount => 'अकाउंट डिलीट करें';

  @override
  String get deleteAccountTitle => 'यह अकाउंट डिलीट करें?';

  @override
  String get deleteAccountMessage =>
      'इसे वापस नहीं किया जा सकता: यह अकाउंट और इसके क्रेडिट व लाभ के रिकॉर्ड हमेशा के लिए पहुँच से बाहर हो जाएँगे, और एक नया अकाउंट बना दिया जाएगा। अकाउंट डिलीट करने से सक्रिय app store सब्सक्रिप्शन रद्द नहीं होता — इसे अपनी app store सेटिंग्स में मैनेज करें, या बाद में \"ख़रीदारियाँ रीस्टोर करें\" से फिर से जोड़ें।';

  @override
  String get deleteAccountConfirm => 'डिलीट करें';

  @override
  String get deleteAccountWorking => 'अकाउंट डिलीट किया जा रहा है…';

  @override
  String get deleteAccountDone => 'अकाउंट डिलीट हो गया।';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString से सदस्य';
  }

  @override
  String get loginTitle => 'साइन इन करें';

  @override
  String get loginUsername => 'यूज़रनेम';

  @override
  String get loginPassword => 'पासवर्ड';

  @override
  String get loginSubmit => 'साइन इन करें';

  @override
  String get paywallTitle => 'पूरा गाना पाएँ';

  @override
  String get paywallSubtitle =>
      'अपने प्रीव्यू को बोलों के साथ 2 मिनट के गाने में बदलें — डाउनलोड करने और इस्तेमाल करने के लिए पूरी तरह आपका।';

  @override
  String get paywallRestore => 'ख़रीदारियाँ रीस्टोर करें';

  @override
  String get paywallAutoRenewNotice =>
      'पुष्टि होते ही भुगतान आपके Apple खाते से लिया जाता है। सब्सक्रिप्शन उसी क़ीमत और अवधि पर अपने-आप रिन्यू होते हैं, जब तक कि मौजूदा अवधि ख़त्म होने से कम से कम 24 घंटे पहले रद्द न किए जाएँ। फ़्री ट्रायल ख़त्म होने पर वह पेड सब्सक्रिप्शन में बदल जाता है। अपनी App Store अकाउंट सेटिंग्स में कभी भी मैनेज या रद्द करें।';

  @override
  String get paywallContinue => 'जारी रखें';

  @override
  String get paywallFreeTrial => 'फ़्री ट्रायल';

  @override
  String get paywallOffer => 'ऑफ़र';

  @override
  String get paywallManage => 'मैनेज करें';

  @override
  String get paywallTermsOfUse => 'उपयोग की शर्तें';

  @override
  String get paywallPrivacyPolicy => 'प्राइवेसी पॉलिसी';

  @override
  String get paywallSubscriptionTerms => 'सब्सक्रिप्शन की शर्तें';

  @override
  String get commonLinkError => 'लिंक नहीं खुल सका।';

  @override
  String get commonError => 'कुछ गड़बड़ हो गई।';

  @override
  String get commonNetworkError =>
      'नेटवर्क की समस्या — अपना कनेक्शन जाँचें और फिर से कोशिश करें।';

  @override
  String get commonOfflineError =>
      'लगता है आप ऑफ़लाइन हैं। अपना कनेक्शन जाँचें और फिर से कोशिश करें।';

  @override
  String get networkErrorTitle => 'कनेक्शन की समस्या';

  @override
  String get configErrorTitle => 'ऐप कॉन्फ़िगरेशन की समस्या';

  @override
  String get configErrorMessage =>
      'यह वर्शन हमारी सर्विस से कनेक्ट नहीं हो पा रहा है। App Store से ऐप अपडेट करें, या इसे दोबारा इंस्टॉल करें। अगर समस्या बनी रहे, तो सपोर्ट से संपर्क करें।';

  @override
  String get commonAuthError =>
      'आपका सेशन ख़त्म हो गया — कृपया फिर से साइन इन करें।';

  @override
  String get paywallProductsErrorTitle => 'प्रोडक्ट लोड नहीं हो सके';

  @override
  String get paywallNoProducts => 'अभी कोई प्रोडक्ट उपलब्ध नहीं है।';

  @override
  String get paywallPurchaseSuccess => 'ख़रीदारी पूरी हुई — आनंद लें!';

  @override
  String get paywallProcessing => 'आपकी ख़रीदारी प्रोसेस हो रही है…';

  @override
  String get paywallVerifying => 'आपकी ख़रीदारी वेरिफ़ाई हो रही है…';

  @override
  String get paywallPurchaseFailed => 'ख़रीदारी पूरी नहीं हो सकी।';

  @override
  String get paywallRestoreStarted => 'आपकी ख़रीदारियाँ रीस्टोर हो रही हैं…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ख़रीदारियाँ रीस्टोर हुईं।',
      one: '$countString ख़रीदारी रीस्टोर हुई।',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing =>
      'रीस्टोर करने के लिए कोई ख़रीदारी नहीं है।';

  @override
  String get paywallDeferred =>
      'मंज़ूरी का इंतज़ार है — मंज़ूरी मिलते ही हम इसे पूरा कर देंगे।';

  @override
  String get paywallAlreadySubscribed => 'आप पहले से सब्सक्राइब्ड हैं।';

  @override
  String get paywallBillingRetry =>
      'अपना सब्सक्रिप्शन जारी रखने के लिए पेमेंट का तरीका अपडेट करें।';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString दिन का फ़्री ट्रायल';
  }

  @override
  String get cycleOneTime => 'एक बार';

  @override
  String get cycleWeekly => '/ हफ़्ता';

  @override
  String get cycleMonthly => '/ महीना';

  @override
  String get cycleQuarterly => '/ तिमाही';

  @override
  String get cycleSemiAnnual => '/ 6 महीने';

  @override
  String get cycleAnnual => '/ साल';

  @override
  String get cycleLifetime => 'लाइफ़टाइम';

  @override
  String get navCreate => 'बनाएँ';

  @override
  String get navLibrary => 'लाइब्रेरी';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get commonContinue => 'जारी रखें';

  @override
  String get commonBack => 'वापस';

  @override
  String get createTitle => 'यह गाना किसके लिए है?';

  @override
  String get occasionBirthday => 'जन्मदिन';

  @override
  String get occasionBirthdayHint => 'उनके ख़ास दिन के लिए एक ख़ुशनुमा गाना';

  @override
  String get occasionAnniversary => 'सालगिरह';

  @override
  String get occasionAnniversaryHint => 'अपनी साथ की कहानी का जश्न मनाएँ';

  @override
  String get occasionConfession => 'प्यार का इज़हार';

  @override
  String get occasionConfessionHint => 'दिल की बात कह दें';

  @override
  String get occasionWedding => 'शादी';

  @override
  String get occasionWeddingHint => 'आपके हमेशा के पल के लिए एक गाना';

  @override
  String get occasionMemorial => 'याद में';

  @override
  String get occasionMemorialHint => 'किसी अपने को सम्मान दें';

  @override
  String get occasionFestival => 'त्योहार';

  @override
  String get occasionFestivalHint => 'ख़ास मौसम के लिए प्यार भरी शुभकामनाएँ';

  @override
  String get occasionBrand => 'ब्रांड जिंगल';

  @override
  String get occasionBrandHint => 'आपके ब्रांड के लिए एक कैची धुन';

  @override
  String get occasionSoundtrack => 'वीडियो साउंडट्रैक';

  @override
  String get occasionSoundtrackHint => 'आपकी कहानी से मेल खाता संगीत';

  @override
  String get festivalNewYear => 'नया साल';

  @override
  String get festivalThanksgiving => 'थैंक्सगिविंग';

  @override
  String get festivalDiwali => 'दिवाली';

  @override
  String get festivalCarnival => 'कार्निवल';

  @override
  String get festivalEid => 'ईद';

  @override
  String get festivalLunarNewYear => 'लूनर न्यू ईयर';

  @override
  String get regionTitle => 'यह कहाँ सुना जाएगा?';

  @override
  String get regionSearchHint => 'देश खोजें';

  @override
  String get regionLanguageSheetTitle => 'बोलों की भाषा';

  @override
  String get countryUS => 'संयुक्त राज्य अमेरिका';

  @override
  String get countryGB => 'यूनाइटेड किंगडम';

  @override
  String get countryCA => 'कनाडा';

  @override
  String get countryAU => 'ऑस्ट्रेलिया';

  @override
  String get countryDE => 'जर्मनी';

  @override
  String get countryFR => 'फ़्रांस';

  @override
  String get countryJP => 'जापान';

  @override
  String get countryKR => 'दक्षिण कोरिया';

  @override
  String get countryBR => 'ब्राज़ील';

  @override
  String get countryMX => 'मेक्सिको';

  @override
  String get countryIN => 'भारत';

  @override
  String get countryID => 'इंडोनेशिया';

  @override
  String get countryVN => 'वियतनाम';

  @override
  String get countryTR => 'तुर्किये';

  @override
  String get languageEn => 'अंग्रेज़ी';

  @override
  String get languageFr => 'फ़्रेंच';

  @override
  String get languageDe => 'जर्मन';

  @override
  String get languageJa => 'जापानी';

  @override
  String get languageKo => 'कोरियाई';

  @override
  String get languagePtBR => 'पुर्तगाली (ब्राज़ील)';

  @override
  String get languageEsMX => 'स्पैनिश (मेक्सिको)';

  @override
  String get languageHi => 'हिन्दी';

  @override
  String get languageId => 'इंडोनेशियाई';

  @override
  String get languageVi => 'वियतनामी';

  @override
  String get languageTr => 'तुर्की';

  @override
  String get languageZhHans => 'चीनी (सरलीकृत)';

  @override
  String get languageZhHant => 'चीनी (पारंपरिक)';

  @override
  String get inputNameLabel => 'उनका नाम';

  @override
  String get inputNameOptionalLabel => 'नाम (वैकल्पिक)';

  @override
  String get inputNameHint => 'जैसे Alex';

  @override
  String get inputKeywordsLabel => 'उनके बारे में तीन शब्द';

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
      'ये बोल मेरे हैं या मुझे इन्हें इस्तेमाल करने का अधिकार है';

  @override
  String get issueRecipientMissing => 'उनका नाम जोड़ें।';

  @override
  String get issueRecipientTooLong => 'नाम अधिकतम 24 अक्षरों का हो सकता है।';

  @override
  String get issueBriefMissing =>
      'गाने के बारे में बताएं — कुछ शब्द, बोल या फ़ोटो।';

  @override
  String get issueDescriptionMissing =>
      'इस आइडिया को आपके शब्द चाहिए — गाने के बारे में एक लाइन लिखें।';

  @override
  String get generatingBackToEdit => 'वापस बदलें';

  @override
  String get issueKeywordTooLong => 'हर शब्द अधिकतम 20 अक्षरों का हो सकता है।';

  @override
  String get issueTooManyKeywords => 'अधिकतम तीन शब्द इस्तेमाल करें।';

  @override
  String get issueArtistName =>
      'कलाकारों के नाम इस्तेमाल नहीं किए जा सकते — इसके बजाय भावना बताएँ।';

  @override
  String get issueStyleImitation =>
      'हम किसी गायक या बैंड की नकल नहीं कर सकते। इसके बजाय मूड बताएँ।';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'बोल अधिकतम $limitString अक्षरों के हो सकते हैं।';
  }

  @override
  String get issueLyricsNotOriginal =>
      'ये बोल किसी मौजूदा गाने जैसे लगते हैं। कृपया अपने बोल ख़ुद लिखें।';

  @override
  String get issueLyricsOwnership =>
      'पुष्टि करें कि आपको ये बोल इस्तेमाल करने का अधिकार है।';

  @override
  String get issueTooManyPhotos => 'अधिकतम 10 फ़ोटो चुनें।';

  @override
  String get photosTitle => 'कुछ फ़ोटो चुनें';

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
      'फ़ोटो का इस्तेमाल सिर्फ़ एक बार गाना लिखने के लिए होता है और 24 घंटे के अंदर हमारे सर्वर से डिलीट कर दी जाती हैं।';

  @override
  String get photosAdd => 'फ़ोटो जोड़ें';

  @override
  String get photosCreate => 'फ़ोटो से बनाएँ';

  @override
  String get photosEmpty => 'उस पल की 1–10 फ़ोटो चुनें।';

  @override
  String get generatingStepPolishing =>
      'इस iPhone पर आपके शब्द निखारे जा रहे हैं…';

  @override
  String get generatingStepUploading => 'आपकी फ़ोटो भेजी जा रही हैं…';

  @override
  String get generatingStepSubmitting => 'स्टूडियो को भेजा जा रहा है…';

  @override
  String get errorSafetyBlocked =>
      'हम यह गाना नहीं बना सकते — दूसरे शब्द आज़माएँ, और कलाकारों के नाम न लिखें।';

  @override
  String get errorQuotaExhausted =>
      'आपने इस महीने के गाने इस्तेमाल कर लिए हैं। कोई पैक जोड़ें या अपग्रेड करें।';

  @override
  String get errorUpstreamTimeout =>
      'सामान्य से ज़्यादा समय लग रहा है। हम कोशिश करते रहेंगे और आपको सूचित करेंगे।';

  @override
  String get errorUpstreamRateLimited =>
      'अभी बहुत सारे गाने बन रहे हैं। आपका गाना कतार में है।';

  @override
  String get errorAttestFailed => 'कृपया App Store से Songlet अपडेट करें।';

  @override
  String get errorImageRejected =>
      'इनमें से एक फ़ोटो इस्तेमाल नहीं की जा सकती। कोई दूसरी आज़माएँ।';

  @override
  String get errorNetworkOffline =>
      'आप ऑफ़लाइन हैं। आपकी लाइब्रेरी अब भी काम करती है।';

  @override
  String get errorDownloadLocked =>
      'यह गाना डाउनलोड नहीं किया जा सकता — जिस ख़रीदारी से यह बना था उसका रिफ़ंड हो गया है या आपका प्लान ख़त्म हो गया है। आप इसे अब भी चला सकते हैं।';

  @override
  String get errorJobAlreadyFinished =>
      'यह पहले ही पूरा हो चुका है — रद्द करने के लिए कुछ नहीं है।';

  @override
  String get errorMvSongNotReady => 'यह गाना अभी वीडियो के लिए तैयार नहीं है।';

  @override
  String get errorMvSongTooLong =>
      'यह गाना पूरे वीडियो के लिए बहुत लंबा है — कोरस वीडियो आज़माएँ।';

  @override
  String get errorMvSongExpired =>
      'यह गाना समाप्त हो गया है। वीडियो बनाने के लिए इसे फिर से बनाएँ।';

  @override
  String get errorMvNotFound => 'यह वीडियो अब उपलब्ध नहीं है।';

  @override
  String get errorMvPhotosExpired =>
      'वे फ़ोटो समाप्त हो गए हैं — उन्हें फिर से चुनें।';

  @override
  String get errorMvRenderFailed =>
      'हम यह वीडियो पूरा नहीं कर सके। आपके क्रेडिट वापस आ गए हैं — फिर से कोशिश करें।';

  @override
  String get mvHubTitle => 'वीडियो बनाएँ';

  @override
  String mvHubSubtitle(String title) {
    return '“$title” को म्यूज़िक वीडियो बनाएँ।';
  }

  @override
  String get mvLevelLyricVideo => 'लिरिक वीडियो';

  @override
  String get mvLevelLyricHint => 'आपके बोल के साथ एक स्थिर दृश्य';

  @override
  String get mvLevelChorus => 'कोरस वीडियो';

  @override
  String get mvLevelChorusHint => 'आपके कोरस के 30 सेकंड, AI द्वारा शूट';

  @override
  String get mvLevelFull => 'पूरे गाने का वीडियो';

  @override
  String get mvLevelFullHint => 'पूरा गाना, दृश्य दर दृश्य';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString क्रेडिट',
      one: '$creditsString क्रेडिट',
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
      other: 'आपके पास $creditsString क्रेडिट हैं',
      one: 'आपके पास $creditsString क्रेडिट है',
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
      other: '$creditsString और क्रेडिट चाहिए',
      one: '$creditsString और क्रेडिट चाहिए',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => 'क़ीमत देख रहे हैं…';

  @override
  String get mvOptionsHeader => 'विकल्प';

  @override
  String get mvAspectLabel => 'फ़ॉर्मैट';

  @override
  String get mvAspectPortrait => 'पोर्ट्रेट';

  @override
  String get mvAspectLandscape => 'लैंडस्केप';

  @override
  String get mvAspectSquare => 'वर्ग';

  @override
  String get mvQualityLabel => 'गुणवत्ता';

  @override
  String get mvQualityStandard => 'मानक';

  @override
  String get mvQualityHigh => 'उच्च';

  @override
  String get mvSubtitlesLabel => 'स्क्रीन पर बोल';

  @override
  String get mvPhotosLabel => 'संदर्भ फ़ोटो';

  @override
  String get mvPhotosHint => 'माहौल और रंग तय करें — चेहरों का उपयोग नहीं होता';

  @override
  String mvPhotosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString फ़ोटो',
      one: '$countString फ़ोटो',
    );
    return '$_temp0';
  }

  @override
  String get mvChorusLabel => 'कोरस';

  @override
  String get mvChorusAuto => 'अपने आप खोजा जाएगा';

  @override
  String get mvChorusCustom => 'पल चुनें';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => 'वीडियो बनाएँ';

  @override
  String get mvBuyPack => 'पैक लें और बनाएँ';

  @override
  String get mvSongLocked => 'आपका गाना वीडियो के लिए सहेज लिया गया है।';

  @override
  String get mvGeneratingTitle => 'आपका वीडियो बन रहा है…';

  @override
  String get mvStageQueued => 'शुरू होने की प्रतीक्षा';

  @override
  String get mvStageSlicing => 'पल चुने जा रहे हैं';

  @override
  String get mvStageStoryboarding => 'स्टोरीबोर्ड लिखा जा रहा है';

  @override
  String get mvStageKeyframing => 'दृश्य बनाए जा रहे हैं';

  @override
  String get mvStageRendering => 'दृश्य फ़िल्माए जा रहे हैं';

  @override
  String get mvStageAssembling => 'जोड़ा जा रहा है';

  @override
  String get mvStageDone => 'हो गया';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'दृश्य $doneString / $totalString';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'आमतौर पर लगभग $minutesString मिनट';
  }

  @override
  String get mvCancelRequested => 'मौजूदा दृश्य के बाद रुक जाएगा…';

  @override
  String get mvCancelTitle => 'यह वीडियो रोकें?';

  @override
  String get mvCancelQueued =>
      'यह अभी शुरू नहीं हुआ है, इसलिए कुछ भी उपयोग नहीं होगा।';

  @override
  String get mvCancelStarted =>
      'यह शुरू हो चुका है। बने हुए दृश्यों का शुल्क लगेगा; बाक़ी वापस आ जाएगा।';

  @override
  String get mvCancelConfirm => 'वीडियो रोकें';

  @override
  String get mvCancelled => 'वीडियो रोका गया';

  @override
  String get mvCancelledRefunded => 'वीडियो रोका गया — कुछ भी उपयोग नहीं हुआ';

  @override
  String get mvNothing => 'अभी कोई वीडियो नहीं बन रहा है।';

  @override
  String get mvQuotaTitle => 'पर्याप्त क्रेडिट नहीं';

  @override
  String get mvAiLabelBurnedIn => 'AI से बना — बैज वीडियो का हिस्सा है';

  @override
  String get mvSave => 'फ़ोटो में सहेजें';

  @override
  String get mvSaveFiles => 'फ़ाइल में सहेजें';

  @override
  String get mvShareText => 'मैंने यह म्यूज़िक वीडियो Songlet से बनाया 🎬';

  @override
  String get mvMissing => 'यह वीडियो अब इस डिवाइस पर नहीं है।';

  @override
  String get mvDeleteTitle => 'यह वीडियो हटाएँ?';

  @override
  String get mvDeleteBody => 'यह इस डिवाइस से हटा दिया जाएगा।';

  @override
  String get mvDeleted => 'वीडियो हटाया गया';

  @override
  String get mvProvenance =>
      'Google Lyria 3 और AI वीडियो मॉडल से बना · AI से बना';

  @override
  String get detailVideos => 'वीडियो';

  @override
  String get detailMakeVideo => 'वीडियो बनाएँ';

  @override
  String get mvStatusReady => 'तैयार';

  @override
  String get mvStatusPending => 'बन रहा है…';

  @override
  String get mvStatusFailed => 'पूरा नहीं हुआ';

  @override
  String get mvPackTitle => 'म्यूज़िक वीडियो';

  @override
  String get mvPackChorusSubtitle => 'एक कोरस वीडियो';

  @override
  String get mvPackFullSubtitle => 'एक पूरे गाने का वीडियो';

  @override
  String get paywallMvHeroTitle => 'इसे वीडियो बनाएँ';

  @override
  String get paywallMvHeroSubtitle =>
      'आपके गाने के म्यूज़िक वीडियो के लिए क्रेडिट — सहेजें और साझा करें।';

  @override
  String get playerAiGenerated => 'AI द्वारा बनाया गया';

  @override
  String get playerLoop => 'लूप';

  @override
  String get playerPlay => 'चलाएँ';

  @override
  String get playerPause => 'रोकें';

  @override
  String get playerPreviewLabel => '30 सेकंड का प्रीव्यू';

  @override
  String playerTitleFor(String name) {
    return '$name के लिए';
  }

  @override
  String get downloadSaved => 'फ़ाइलें में सेव किया गया।';

  @override
  String get shareComposing => 'आपका शेयर कार्ड बनाया जा रहा है…';

  @override
  String get shareFailed => 'शेयर कार्ड नहीं बन सका।';

  @override
  String get shareText => 'मैंने यह गाना Songlet से बनाया 🎵';

  @override
  String get paywallBestValue => 'सबसे फ़ायदेमंद';

  @override
  String get paywallStartTrial => 'फ़्री ट्रायल शुरू करें';

  @override
  String get paywallClose => 'बंद करें';

  @override
  String get paywallSeePlans => 'सदस्यताएँ देखें';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'आपका प्लान सक्रिय है — इस अवधि में $countString पूरे गाने बचे हैं।',
      one: 'आपका प्लान सक्रिय है — इस अवधि में $countString पूरा गाना बचा है।',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => 'आपके गाने यहाँ रहेंगे।';

  @override
  String get libraryEmptyAction => 'अपना पहला गाना बनाएँ';

  @override
  String get libraryPending => 'कंपोज़ हो रहा है…';

  @override
  String get libraryPreviewBadge => 'प्रीव्यू';

  @override
  String get librarySongBadge => 'पूरा गाना';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsPlan => 'आपका प्लान';

  @override
  String get settingsPlanUnavailable =>
      'आपका प्लान लोड नहीं हो सका। बाद में फिर से कोशिश करने के लिए नीचे खींचें।';

  @override
  String get tierFree => 'कोई सदस्यता नहीं';

  @override
  String get tierPack => 'सॉन्ग पैक';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString पूरे गाने बचे हैं',
      one: '$countString पूरा गाना बचा है',
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
      other: '$countString प्रीव्यू बचे हैं',
      one: '$countString प्रीव्यू बचा है',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString को रीसेट होगा';
  }

  @override
  String get settingsUpgrade => 'अपग्रेड करें';

  @override
  String get appTagline => 'अपनों के लिए गीत';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonDone => 'हो गया';

  @override
  String get commonDelete => 'मिटाएँ';

  @override
  String get commonMore => 'और';

  @override
  String get commonCopy => 'कॉपी करें';

  @override
  String get commonCopied => 'कॉपी हो गया';

  @override
  String get commonNotNow => 'अभी नहीं';

  @override
  String get commonLearnMore => 'और जानें';

  @override
  String get commonSeeAll => 'सभी देखें';

  @override
  String get commonKeepGoing => 'जारी रखें';

  @override
  String get composerHint => 'जैसा गीत चाहिए, उसके बारे में लिखें';

  @override
  String get composerAddPhotos => 'फ़ोटो जोड़ें';

  @override
  String get composerSourceMusicHint => 'अपने शब्दों में बताएँ';

  @override
  String get composerDictate => 'बोलकर लिखें';

  @override
  String get composerStopDictation => 'बोलकर लिखना बंद करें';

  @override
  String get lengthPreview => 'प्रीव्यू';

  @override
  String get lengthFull => 'पूरा गाना';

  @override
  String get paramLength => 'लंबाई';

  @override
  String get paramVocals => 'आवाज़';

  @override
  String get paramGenre => 'शैली';

  @override
  String templatePlaySample(String name) {
    return '$name का नमूना सुनें';
  }

  @override
  String get templatePauseSample => 'नमूना रोकें';

  @override
  String get lengthShort => 'छोटा';

  @override
  String get lengthShortHint => '30 सेकंड प्रीव्यू';

  @override
  String get lengthStandard => 'सामान्य';

  @override
  String get lengthStandardHint => 'लगभग 2 मिनट, Pro';

  @override
  String get vocalsCustom => 'अपने आप';

  @override
  String get vocalsCustomHint => 'आपके विवरण के अनुसार';

  @override
  String get vocalsCustomDetail => 'आवाज़ की शैली आपके विवरण के अनुसार होगी।';

  @override
  String get vocalsOn => 'आवाज़ के साथ';

  @override
  String get vocalsInstrumental => 'केवल संगीत';

  @override
  String vocalsLyricsIn(String language) {
    return 'बोल $language में लिखे जाएँगे';
  }

  @override
  String get genreCustom => 'अपने आप';

  @override
  String get genreCustomHint => 'आपके विवरण के अनुसार';

  @override
  String genrePopularIn(String country) {
    return '$country में लोकप्रिय';
  }

  @override
  String get genreAll => 'सभी शैलियाँ';

  @override
  String get regionHelper => '3 सुझाई गई शैलियाँ और बोल की भाषा बदल जाती है';

  @override
  String regionLyricsRow(String language) {
    return 'बोल की भाषा: $language';
  }

  @override
  String get regionNoMatch => 'कोई देश नहीं मिला';

  @override
  String get keywordAdd => 'एक शब्द जोड़ें';

  @override
  String keywordRemove(String word) {
    return '$word हटाएँ';
  }

  @override
  String get nameClear => 'नाम साफ़ करें';

  @override
  String get lyricsOptional => 'अपने बोल लिखें (वैकल्पिक)';

  @override
  String get issueRecipientArtistName =>
      'कलाकारों के नाम इस्तेमाल नहीं किए जा सकते।';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'विवरण $limitString अक्षरों से कम रखें।';
  }

  @override
  String get voiceRecording => 'रिकॉर्ड हो रहा है…';

  @override
  String get voiceStarting => 'शुरू हो रहा है…';

  @override
  String get voiceListening =>
      'बताइए यह गीत किसके लिए है और उन्हें क्या पसंद है…';

  @override
  String get voiceOnDevice => 'डिवाइस पर ही लिखा गया';

  @override
  String get voicePermissionDenied =>
      'बोलकर लिखने के लिए Settings में Songlet को माइक्रोफ़ोन और स्पीच रिकग्निशन की अनुमति दें।';

  @override
  String get voiceUnavailable =>
      'इस डिवाइस पर इस भाषा में बोलकर लिखना उपलब्ध नहीं है।';

  @override
  String get voiceApplied => 'आपकी आवाज़ से जोड़ा गया';

  @override
  String get photoRemove => 'फ़ोटो हटाएँ';

  @override
  String generatingTitleFor(String name) {
    return '$name का गीत लिखा जा रहा है…';
  }

  @override
  String get generatingTitleGeneric => 'आपका गीत लिखा जा रहा है…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'आमतौर पर लगभग $secondsString सेकंड';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => 'प्रगति';

  @override
  String get generatingGlimpse => 'आपके गीत की एक झलक';

  @override
  String get generatingCancelTitle => 'यह गीत रोकें?';

  @override
  String get generatingCancelQueued =>
      'यह अभी शुरू नहीं हुआ है, इसलिए आपकी सीमा में नहीं गिना जाएगा।';

  @override
  String get generatingCancelStarted =>
      'यह शुरू हो चुका है, इसलिए आपकी सीमा में गिना जाएगा।';

  @override
  String get generatingCancelConfirm => 'गीत रोकें';

  @override
  String get generatingCancelled => 'गीत रोक दिया गया';

  @override
  String get generatingCancelledRefunded =>
      'गीत रोक दिया गया — कुछ भी खर्च नहीं हुआ';

  @override
  String get queueTitle => 'अभी बहुत सारे गीत बन रहे हैं।';

  @override
  String get queueSubtitle => 'आपका गीत कतार में है।';

  @override
  String get queuePosition => 'कतार में स्थान';

  @override
  String get queueWait => 'अनुमानित इंतज़ार';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '≈ $minutesString मिनट';
  }

  @override
  String get generatingNothing => 'अभी कोई गीत नहीं बन रहा है।';

  @override
  String get previewGetFull => 'पूरा 2 मिनट का गीत पाएँ';

  @override
  String get previewShare => 'प्रीव्यू शेयर करें';

  @override
  String get previewAnother => 'दूसरा वर्शन आज़माएँ (1 प्रीव्यू लगेगा)';

  @override
  String get playerPosition => 'चलने की स्थिति';

  @override
  String get playerPrevSection => 'पिछला हिस्सा';

  @override
  String get playerNextSection => 'अगला हिस्सा';

  @override
  String get playerShuffle => 'हिस्से शफ़ल करें';

  @override
  String get playerRepeat => 'दोहराएँ';

  @override
  String get playerProvenance =>
      'Google Lyria 3 से बना · SynthID वॉटरमार्क · AI से बना';

  @override
  String get playerMissing => 'यह गीत अब इस डिवाइस पर नहीं है।';

  @override
  String get actionDownload => 'डाउनलोड';

  @override
  String get actionShare => 'शेयर';

  @override
  String get actionLicense => 'लाइसेंस';

  @override
  String get actionRegenerate => 'फिर से बनाएँ';

  @override
  String get actionDetails => 'विवरण';

  @override
  String get sectionIntro => 'इंट्रो';

  @override
  String get sectionVerse => 'अंतरा';

  @override
  String get sectionPreChorus => 'प्री-कोरस';

  @override
  String get sectionChorus => 'मुखड़ा';

  @override
  String get sectionBridge => 'ब्रिज';

  @override
  String get sectionOutro => 'आउट्रो';

  @override
  String get sectionHook => 'हुक';

  @override
  String get shareTitle => 'शेयर कार्ड';

  @override
  String get shareSubtitle => 'थीम और लेआउट चुनें।';

  @override
  String get shareTheme => 'थीम';

  @override
  String get shareLayout => 'लेआउट';

  @override
  String get shareLayoutScene => 'चित्र के साथ';

  @override
  String get shareLayoutText => 'केवल टेक्स्ट';

  @override
  String get paletteTerracotta => 'टेराकोटा';

  @override
  String get paletteSand => 'रेतीला';

  @override
  String get paletteOlive => 'ज़ैतूनी';

  @override
  String get paletteNavy => 'नेवी';

  @override
  String get shareAction => 'शेयर करें';

  @override
  String get shareSaveVideo => 'वीडियो सहेजें';

  @override
  String get shareCopyLyrics => 'बोल कॉपी करें';

  @override
  String get shareVideoSaved => 'Photos में सहेजा गया';

  @override
  String get shareLyricsCopied => 'बोल कॉपी हो गए';

  @override
  String get shareCardTagline => 'किसी के लिए एक गीत';

  @override
  String get shareSaveFailed =>
      'वीडियो सहेजा नहीं जा सका। Settings में Songlet को Photos में जोड़ने की अनुमति दें।';

  @override
  String get downloadReady => 'पूरा गीत तैयार है';

  @override
  String get downloadTitle => 'हमेशा के लिए आपका';

  @override
  String get downloadIntro =>
      'आपका गीत तैयार है। नीचे से हाई-क्वालिटी ऑडियो और कमर्शियल लाइसेंस डाउनलोड करें।';

  @override
  String get downloadAudioHeader => 'ऑडियो डाउनलोड करें';

  @override
  String get downloadAudioNote => 'हाई क्वालिटी';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle => 'शेयर करने और रोज़ सुनने के लिए बढ़िया';

  @override
  String get downloadWavTitle => 'WAV · 44.1 kHz (Premier)';

  @override
  String get downloadWavSubtitle =>
      'प्रोफ़ेशनल इस्तेमाल के लिए सबसे बेहतर क्वालिटी';

  @override
  String get downloadMp3Action => 'MP3 डाउनलोड करें';

  @override
  String get downloadWavAction => 'WAV डाउनलोड करें';

  @override
  String get downloadLicenseAction => 'लाइसेंस डाउनलोड करें';

  @override
  String get licenseHeader => 'कमर्शियल लाइसेंस';

  @override
  String get licenseIncluded => 'आपके प्लान में शामिल';

  @override
  String get licenseNotIncluded => 'प्लान या पैक के साथ मिलता है';

  @override
  String get licensePdfTitle => 'कमर्शियल लाइसेंस (PDF)';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString को जारी';
  }

  @override
  String licenseId(String id) {
    return 'लाइसेंस ID: $id';
  }

  @override
  String get licenseUsesTitle => 'आप यह गीत इनके लिए इस्तेमाल कर सकते हैं:';

  @override
  String get usePersonal => 'निजी इस्तेमाल';

  @override
  String get usePersonalDetail => 'उपहार, यादें, गैर-व्यावसायिक';

  @override
  String get useAds => 'विज्ञापन और मार्केटिंग';

  @override
  String get useAdsDetail => 'प्रमोशन, पेड कैंपेन';

  @override
  String get useSocial => 'सोशल मीडिया';

  @override
  String get useSocialDetail => 'TikTok, Instagram, YouTube आदि';

  @override
  String get usePodcasts => 'पॉडकास्ट और वीडियो';

  @override
  String get usePodcastsDetail => 'कमाई वाला कंटेंट';

  @override
  String get licenseDetailsNote => 'पूरी जानकारी लाइसेंस PDF में है।';

  @override
  String get saveEnjoyHeader => 'सहेजें और सुनें';

  @override
  String get saveToFiles => 'Files में सहेजें';

  @override
  String get addToMusic => 'Music में जोड़ें';

  @override
  String get synthIdNote =>
      'इस गीत में SynthID वॉटरमार्क है, जिससे डाउनलोड के बाद भी इसे AI से बना कंटेंट पहचाना जा सकता है।';

  @override
  String get wavNeedsPremier => 'WAV डाउनलोड Premier के साथ मिलते हैं।';

  @override
  String get wavUnavailable =>
      'इस गाने की कोई WAV फ़ाइल नहीं है। WAV फ़ाइलें गाना बनने के 24 घंटे के भीतर सेव की जा सकती हैं।';

  @override
  String get libraryFilterAll => 'सभी';

  @override
  String get libraryJustBecause => 'यूँ ही';

  @override
  String libraryPlay(String title) {
    return '$title चलाएँ';
  }

  @override
  String libraryActions(String title) {
    return '$title के विकल्प';
  }

  @override
  String get libraryDeleteTitle => 'यह गीत मिटाएँ?';

  @override
  String get libraryDeleteBody =>
      'यह इस डिवाइस से हटा दिया जाएगा। अगर iCloud सिंक चालू है, तो आपके दूसरे डिवाइस से भी हट जाएगा।';

  @override
  String get libraryDeleted => 'गीत मिटा दिया गया';

  @override
  String get libraryFailed => 'पूरा नहीं हुआ';

  @override
  String get libraryNoMatch => 'इस मौके के लिए अभी कोई गीत नहीं है।';

  @override
  String get detailFullGenerated => 'पूरा गीत बना';

  @override
  String get detailPreviewGenerated => 'प्रीव्यू बना';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString को बना';
  }

  @override
  String get detailPromptUsed => 'इस्तेमाल की गई जानकारी';

  @override
  String get detailOccasion => 'मौका';

  @override
  String get detailCountry => 'देश';

  @override
  String get detailGenre => 'शैली';

  @override
  String get detailKeywords => 'कीवर्ड';

  @override
  String get detailDescription => 'विवरण';

  @override
  String get detailLyrics => 'बोल';

  @override
  String get detailGenerationId => 'जनरेशन ID';

  @override
  String get detailRegenerate => 'इसी शैली में फिर से बनाएँ';

  @override
  String get detailCustomGenre => 'विवरण के अनुसार';

  @override
  String get settingsSectionPlan => 'खरीदारी';

  @override
  String get settingsSectionLibrary => 'लाइब्रेरी';

  @override
  String get settingsSectionAbout => 'जानकारी';

  @override
  String get settingsRestore => 'खरीदारी बहाल करें';

  @override
  String get settingsManage => 'सदस्यता प्रबंधित करें';

  @override
  String get settingsICloud => 'iCloud सिंक';

  @override
  String get settingsICloudOn => 'गीत आपके सभी डिवाइस में सिंक होते हैं';

  @override
  String get settingsICloudOff => 'गीत सिर्फ़ इसी डिवाइस पर रहते हैं';

  @override
  String get settingsICloudUnavailable =>
      'सिंक के लिए Settings में iCloud में साइन इन करें';

  @override
  String get settingsLyricsLanguage => 'बोल की डिफ़ॉल्ट भाषा';

  @override
  String get settingsLyricsLanguageAuto => 'देश के अनुसार';

  @override
  String get settingsTerms => 'उपयोग की शर्तें';

  @override
  String get settingsPrivacy => 'गोपनीयता नीति';

  @override
  String settingsVersion(String version) {
    return 'वर्शन $version';
  }

  @override
  String get aboutTitle => 'गीत कैसे बनते हैं';

  @override
  String get aboutSubtitle => 'Songlet आपके गीत कैसे बनाता है';

  @override
  String get aboutLyriaTitle => 'Google के Lyria 3 से';

  @override
  String get aboutLyriaBody =>
      'गीत Gemini API के ज़रिए Google के Lyria 3 से बनाए जाते हैं। Lyria 3 एक संगीत मॉडल है जो आपके विचारों को मौलिक गीतों में बदलता है।';

  @override
  String get aboutWatermarkTitle => 'बिल्ट-इन वॉटरमार्क';

  @override
  String get aboutWatermarkBody =>
      'हर गीत में Google का SynthID वॉटरमार्क होता है। इससे AI से बने संगीत की पहचान होती है और इसे हटाया नहीं जा सकता।';

  @override
  String get aboutImitationTitle => 'असली कलाकारों की नकल नहीं';

  @override
  String get aboutImitationBody =>
      'Songlet कभी भी असली कलाकारों, उनकी आवाज़ या किसी खास शैली की नकल नहीं करता। गीत मौलिक होते हैं और आपके विचारों, विवरण और फ़ोटो से बनते हैं।';

  @override
  String get aboutPrivacyTitle => 'आपकी निजता ज़रूरी है';

  @override
  String get aboutPrivacyBody =>
      'फ़ोटो और विवरण 24 घंटे के भीतर हमारे सर्वर से मिटा दिए जाते हैं। गीत बनने के बाद हम आपकी तस्वीरें या विवरण नहीं रखते।';

  @override
  String get aboutBanner =>
      'आपका शेयर किया हर गीत AI से बना होने के रूप में चिह्नित होता है।';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · Google Lyria 3 से बना';
  }

  @override
  String get festivalKicker => 'अपनी कहानी जिएँ';

  @override
  String get festivalComing => 'आने वाली है!';

  @override
  String get festivalBody => 'जश्न मनाने के लिए एक अनोखा गीत बनाएँ।';

  @override
  String festivalCta(String festival) {
    return '$festival का गीत बनाएँ';
  }

  @override
  String get festivalPickOccasion => 'एक मौका चुनें और बनाना शुरू करें';

  @override
  String get festivalLanguagesTitle => 'आपकी भाषा में गीत';

  @override
  String festivalLanguagesBody(String language) {
    return '$language और 12 दूसरी भाषाओं में गीत बनाएँ';
  }

  @override
  String get unavailableTitle => 'कुछ समय के लिए उपलब्ध नहीं';

  @override
  String get unavailableMessage =>
      'Songlet अभी गीत नहीं बना सकता। आपकी लाइब्रेरी काम कर रही है — थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get paywallHeroTitle => 'इसे पूरा गीत बनाएँ';

  @override
  String get paywallHeroSubtitle =>
      'अपने विचार को बेहतर क्वालिटी और पूरे अधिकारों वाले पूरे गीत में बदलें।';

  @override
  String get paywallBenefitSongs => 'ज़्यादा गीत';

  @override
  String get paywallBenefitQuality => 'बेहतर क्वालिटी';

  @override
  String get paywallBenefitCommercial => 'कमर्शियल इस्तेमाल';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'हर महीने $countString पूरे गाने',
      one: 'हर महीने $countString पूरा गाना',
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
      other: 'हर महीने $countString प्रीव्यू',
      one: 'हर महीने $countString प्रीव्यू',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'MP3 डाउनलोड';

  @override
  String get planMp3Wav => 'MP3 + WAV डाउनलोड';

  @override
  String get planLicense => 'कमर्शियल लाइसेंस';

  @override
  String get planPriority => 'प्राथमिकता से बनना';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString दिन का मुफ़्त ट्रायल';
  }

  @override
  String planPerYear(String price) {
    return '$price/साल';
  }

  @override
  String planPerMonth(String price) {
    return '$price/महीना';
  }

  @override
  String get packTitle => 'बस कुछ चाहिए?';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString गानों का पैक',
      one: '$countString गाने का पैक',
    );
    return '$_temp0';
  }

  @override
  String get packNote => 'कभी खत्म नहीं होता';

  @override
  String get valueForever => 'आपके गीत, हमेशा के लिए';

  @override
  String get valueDownloads => 'हाई-क्वालिटी डाउनलोड';

  @override
  String get valueCommercial => 'कमर्शियल इस्तेमाल की अनुमति';

  @override
  String get valuePrivate => 'निजता सबसे पहले';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return 'मुफ़्त ट्रायल के बाद $pricePerPeriod अपने आप लिया जाएगा। ट्रायल खत्म होने से पहले कभी भी रद्द करें।';
  }

  @override
  String get paywallSubscribe => 'सदस्यता लें';

  @override
  String get paywallBuyPack => 'पैक खरीदें';

  @override
  String get templateBirthdayWish => 'जन्मदिन की शुभकामना';

  @override
  String get templateBirthdayWishHint => 'उनके खास दिन के लिए खास गीत';

  @override
  String get templateBirthdayParty => 'जन्मदिन की पार्टी';

  @override
  String get templateBirthdayPartyHint => 'बर्थडे स्टार के लिए पार्टी जमाएँ';

  @override
  String get templateLoveStory => 'प्रेम कहानी';

  @override
  String get templateLoveStoryHint => 'आपकी कहानी, संगीत में';

  @override
  String get templateThankAFriend => 'दोस्त को धन्यवाद';

  @override
  String get templateThankAFriendHint =>
      'वो धन्यवाद जो शब्दों में नहीं कहा जाता';

  @override
  String get templatePartyInvite => 'पार्टी का न्योता';

  @override
  String get templatePartyInviteHint => 'सबको पार्टी में बुलाएँ';

  @override
  String get templateWedding => 'शादी';

  @override
  String get templateWeddingHint => 'उनके हमेशा वाले पल के लिए गीत';

  @override
  String get templateInMemory => 'याद में';

  @override
  String get templateInMemoryHint => 'किसी प्रिय को श्रद्धांजलि';

  @override
  String get templateFestival => 'त्योहार';

  @override
  String get templateFestivalHint => 'खास मौसम के लिए शुभकामनाएँ';

  @override
  String get templateRingtone => 'रिंगटोन';

  @override
  String get templateRingtoneHint => 'सिर्फ़ आपका छोटा-सा लूप';

  @override
  String get templateTeamAnthem => 'टीम एंथम';

  @override
  String get templateTeamAnthemHint => 'टीम और दर्शकों में जोश भरें';

  @override
  String get templateSportsRecap => 'मैच की झलकियाँ';

  @override
  String get templateSportsRecapHint => 'बड़ा मैच, गीत के रूप में';

  @override
  String get templateRapBattle => 'रैप बैटल';

  @override
  String get templateRapBattleHint =>
      'दोस्ताना प्रतिद्वंद्वी के लिए दोस्ताना बार्स';

  @override
  String get templateComedy => 'कॉमेडी';

  @override
  String get templateComedyHint => 'आपस के मज़ाक, अब कोरस के साथ';

  @override
  String get templatePetAnthem => 'पेट एंथम';

  @override
  String get templatePetAnthemHint => 'आपके सबसे अच्छे दोस्त के लिए थीम सॉन्ग';

  @override
  String get templateHometown => 'अपना शहर';

  @override
  String get templateHometownHint => 'उस जगह के लिए प्यार जिसे आप घर कहते हैं';

  @override
  String get templateBusinessPromo => 'बिज़नेस प्रोमो';

  @override
  String get templateBusinessPromoHint =>
      'आपकी दुकान या ब्रांड के लिए एक यादगार धुन';

  @override
  String get templateCustom => 'आपका अपना विचार';

  @override
  String get mvRecommended => 'सुझाया गया';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString से.';
  }

  @override
  String get mvViewProgress => 'प्रगति देखें';

  @override
  String mvIntentWaiting(String level) {
    return '$level क्रेडिट का इंतज़ार कर रहा है';
  }

  @override
  String get mvSongExpiredAction => 'गाना फिर से बनाएँ';

  @override
  String mvQuotaNeed(String level, int required, int available) {
    final intl.NumberFormat requiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requiredString = requiredNumberFormat.format(required);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return '$level के लिए $requiredString क्रेडिट चाहिए। आपके पास $availableString हैं।';
  }

  @override
  String get mvQuotaBuyAndContinue => 'खरीदें और जारी रखें';

  @override
  String get mvQuotaMayNeedTwice =>
      'आपके क्षेत्र में एक पैक शायद काफ़ी न हो — दो की ज़रूरत पड़ सकती है।';

  @override
  String get mvQuotaAutoRetry =>
      'खरीदारी पूरी होते ही आपका वीडियो शुरू हो जाएगा।';

  @override
  String get mvAutoLyricMaking => 'आपका लिरिक वीडियो बन रहा है';

  @override
  String get mvAutoChorusDetail => 'इस गाने से, आपके क्रेडिट से बना';

  @override
  String mvAutoReady(String level) {
    return '$level तैयार है';
  }

  @override
  String get mvAutoView => 'देखें';

  @override
  String get mvUpgradeChorus => 'कोरस वीडियो बनाएँ';

  @override
  String get mvAutoFailed => 'वीडियो शुरू नहीं हो सका';

  @override
  String get mvLeaveHint =>
      'आप यह स्क्रीन छोड़ सकते हैं — तैयार होने के समय हम आपको बताएँगे।';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: 'आपके $creditsString क्रेडिट वापस आ गए।',
      one: 'आपका $creditsString क्रेडिट वापस आ गया।',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => 'यह वीडियो पूरा नहीं हुआ';

  @override
  String get mvRejectedTitle => 'एक फ़ोटो इस्तेमाल नहीं हो सकी';

  @override
  String get mvRejectedBody =>
      'वीडियो मॉडल ने आपकी एक रेफ़रेंस फ़ोटो अस्वीकार कर दी। फ़ोटो बदलकर फिर से कोशिश करें।';

  @override
  String get mvAdjustPhotos => 'फ़ोटो बदलें और फिर कोशिश करें';

  @override
  String get mvTryChorus => 'इसके बजाय कोरस वीडियो बनाएँ';

  @override
  String get mvPreparingPhotos => 'आपकी फ़ोटो अपलोड हो रही हैं…';

  @override
  String get mvPreparingSubmit => 'आपका वीडियो भेजा जा रहा है…';

  @override
  String get mvNotifyTitle => 'आपका वीडियो तैयार होना चाहिए';

  @override
  String mvNotifyBody(String level) {
    return '$level — देखने के लिए टैप करें।';
  }

  @override
  String get mvRegenerate => 'एक और बनाएँ';

  @override
  String get mvEntryTitle => 'इसका वीडियो बनाएँ';

  @override
  String get mvEntrySubtitle =>
      'लिरिक, कोरस और पूरे गाने के वीडियो — क्रेडिट से';

  @override
  String get mvEntryDisabled => 'गाना पूरा होने के बाद उपलब्ध';

  @override
  String get mvEntryChoose => 'वीडियो चुनें';

  @override
  String get mvEntryWatch => 'वीडियो देखें';

  @override
  String get mvChipReady => 'वीडियो';

  @override
  String get mvChipMaking => 'वीडियो बन रहा है';

  @override
  String get lengthAutoVideo => 'लिरिक वीडियो भी बनाएँ';

  @override
  String get lengthAutoVideoHint =>
      'गाने के कुछ मिनट बाद तैयार · क्रेडिट लगते हैं';

  @override
  String get lengthSongAndChorus => 'गाना + कोरस वीडियो';

  @override
  String get lengthSongAndChorusHint =>
      'पूरा गाना, फिर 30 सेकंड का कोरस वीडियो';

  @override
  String get paywallVideoGroup => 'म्यूज़िक वीडियो';

  @override
  String get planVideoIncluded => 'आपके कोटा से म्यूज़िक वीडियो भी बनते हैं';

  @override
  String get settingsVideoCredits => 'वीडियो क्रेडिट';

  @override
  String get createGenrePop => 'पॉप';

  @override
  String get createGenreHipHopRap => 'हिप-हॉप और रैप';

  @override
  String get createGenreRock => 'रॉक';

  @override
  String get createGenreKPop => 'के-पॉप';

  @override
  String get createGenreLatin => 'लैटिन';

  @override
  String get createGenreElectronic => 'इलेक्ट्रॉनिक';

  @override
  String get createGenreRnb => 'आर एंड बी';

  @override
  String get createGenreCountry => 'कंट्री';

  @override
  String get createGenreAfrobeats => 'अफ़्रोबीट्स';

  @override
  String get createGenreReggae => 'रेगे';

  @override
  String get createGenreJazzBlues => 'जैज़ और ब्लूज़';

  @override
  String get createGenreClassical => 'शास्त्रीय';

  @override
  String get createGenreFolk => 'लोक संगीत';

  @override
  String get createGenreLofi => 'लो-फ़ाई';

  @override
  String get createGenreAcoustic => 'अकूस्टिक';

  @override
  String get createGenreCinematic => 'फ़िल्मी संगीत';

  @override
  String get createGenreAmbient => 'ऐम्बिएंट';

  @override
  String get createGenreBossaNova => 'बॉसा नोवा';

  @override
  String get createGenreIndiePop => 'इंडी पॉप';

  @override
  String get createGenreContemporaryRnb => 'आधुनिक आर एंड बी';

  @override
  String get createGenreAlternativeCountry => 'ऑल्ट कंट्री';

  @override
  String get createGenreGarageRock => 'गैराज रॉक';

  @override
  String get createGenreGrime => 'ग्राइम';

  @override
  String get createGenreIndieFolk => 'इंडी लोक संगीत';

  @override
  String get createGenreSynthpop => 'सिंथपॉप';

  @override
  String get createGenrePianoBallad => 'पियानो बैलेड';

  @override
  String get createGenreSurfRock => 'सर्फ़ रॉक';

  @override
  String get createGenreDeepHouse => 'डीप हाउस';

  @override
  String get createGenreMinimalTechno => 'मिनिमल टेक्नो';

  @override
  String get createGenreFrenchYeyePop => '60 के दशक का फ़्रेंच पॉप';

  @override
  String get createGenreChillout => 'चिलआउट';

  @override
  String get createGenreJPopIndiePop => 'जापानी इंडी पॉप';

  @override
  String get createGenreChiptune => 'चिपट्यून';

  @override
  String get createGenreDiscoFunk => 'डिस्को फ़ंक';

  @override
  String get createGenreReggaeton => 'रेगेटॉन';

  @override
  String get createGenreCumbia => 'कुम्बिया';

  @override
  String get createGenreLatinJazz => 'लैटिन जैज़';

  @override
  String get createGenreBhangra => 'भांगड़ा';

  @override
  String get createGenreIndianClassical => 'भारतीय शास्त्रीय';

  @override
  String get createGenreLofiHipHop => 'लो-फ़ाई हिप-हॉप';

  @override
  String profileAccountIdWithValue(String id) {
    return 'अकाउंट ID: $id';
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
  String get createVocalsCustomSummary => 'अपने आप — आपके विवरण के अनुसार';

  @override
  String mvChipMakingWithProgress(String progress) {
    return 'वीडियो बन रहा है · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return 'वीडियो शुरू नहीं हो सका · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    return 'वीडियो क्रेडिट: $creditsString';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => 'प्रेरणा';

  @override
  String inspirationPlay(String name) {
    return '$name चलाएँ';
  }

  @override
  String get inspirationStop => 'नमूना रोकें';

  @override
  String get inspirationNameSoundscape => 'साउंडस्केप';

  @override
  String get inspirationStyleSoundscape => 'परिवेशी ध्वनियाँ, बिना गायन';

  @override
  String get inspirationNameBackgroundMusic => 'बैकग्राउंड म्यूज़िक';

  @override
  String get inspirationStyleBackgroundMusic =>
      'वीडियो के लिए हल्का वाद्य संगीत';

  @override
  String get inspirationNameMemorizeSomething => 'कुछ याद करें';

  @override
  String get inspirationStyleMemorizeSomething => 'याद रखने वाला आकर्षक पॉप';

  @override
  String get inspirationNameTextMessages => 'मैसेज से गाना';

  @override
  String get inspirationStyleTextMessages => 'आपके मैसेज से मज़ेदार पॉप';

  @override
  String get inspirationNameIntroMusic => 'इंट्रो म्यूज़िक';

  @override
  String get inspirationStyleIntroMusic => 'दमदार सिनेमाई शुरुआत';

  @override
  String get inspirationNameMontage => 'मोंटाज';

  @override
  String get inspirationStyleMontage => 'हाइलाइट रील के लिए जोशीला उठान';

  @override
  String get inspirationNameSayItWithATrack => 'गाने से कहें';

  @override
  String get inspirationStyleSayItWithATrack => 'दिल छू लेने वाला पॉप गीत';

  @override
  String get inspirationNameBrandJingle => 'ब्रांड जिंगल';

  @override
  String get inspirationStyleBrandJingle => 'छोटी, चमकदार, यादगार धुन';

  @override
  String get inspirationNameRingtone => 'रिंगटोन';

  @override
  String get inspirationStyleRingtone => '30 सेकंड की लूप होने वाली धुन';

  @override
  String get inspirationNameStreaming => 'स्ट्रीमिंग';

  @override
  String get inspirationStyleStreaming =>
      'ऊर्जावान इलेक्ट्रॉनिक स्ट्रीम इंट्रो';

  @override
  String get inspirationNameSpeechToTrack => 'आवाज़ से गाना';

  @override
  String get inspirationStyleSpeechToTrack => 'आपकी आवाज़ बनी गाना';

  @override
  String get inspirationNameRapBattle => 'रैप बैटल';

  @override
  String get inspirationStyleRapBattle => 'दमदार हिप-हॉप';

  @override
  String get inspirationNameComedy => 'कॉमेडी';

  @override
  String get inspirationStyleComedy => 'अनोखा, खुशमिज़ाज, चुटीला';

  @override
  String get inspirationNameTeamAnthem => 'टीम एंथम';

  @override
  String get inspirationStyleTeamAnthem => 'स्टेडियम रॉक नारा';

  @override
  String get inspirationNameSportsRecap => 'मैच की झलकियाँ';

  @override
  String get inspirationStyleSportsRecap => 'शानदार ऑर्केस्ट्रा हाइलाइट्स';

  @override
  String get inspirationNamePartyInvite => 'पार्टी का न्योता';

  @override
  String get inspirationStylePartyInvite => 'डांस-पॉप न्योता';

  @override
  String get inspirationNameHappyBirthday => 'जन्मदिन मुबारक';

  @override
  String get inspirationStyleHappyBirthday =>
      'गर्मजोशी भरा अकूस्टिक जन्मदिन गीत';

  @override
  String get inspirationNameFriendAppreciation => 'दोस्तों का शुक्रिया';

  @override
  String get inspirationStyleFriendAppreciation => 'सुकून देने वाला इंडी पॉप';

  @override
  String get inspirationNameLoveStory => 'प्रेम कहानी';

  @override
  String get inspirationStyleLoveStory => 'रोमांटिक R&B गीत';

  @override
  String get inspirationNameBirthdayRoast => 'जन्मदिन की मस्ती';

  @override
  String get inspirationStyleBirthdayRoast => 'शरारती मज़ेदार जन्मदिन धुन';

  @override
  String get inspirationNameOdeToYourPet => 'आपके पालतू के नाम';

  @override
  String get inspirationStyleOdeToYourPet => 'प्यारा, उछलता पॉप';

  @override
  String get inspirationNameHometownTribute => 'अपने शहर को सलाम';

  @override
  String get inspirationStyleHometownTribute => 'पुरानी यादों वाला लोक संगीत';

  @override
  String get inspirationNameWeatherReport => 'मौसम का हाल';

  @override
  String get inspirationStyleWeatherReport => 'हल्का-फुल्का लाउंज ग्रूव';

  @override
  String get inspirationNameBusinessPromo => 'बिज़नेस प्रोमो';

  @override
  String get inspirationStyleBusinessPromo => 'आत्मविश्वासी कॉर्पोरेट पॉप';

  @override
  String get inspirationStyleBirthdayWish => 'उनके ख़ास दिन के लिए दिल से गाना';

  @override
  String get inspirationStyleBirthdayParty =>
      'बर्थडे स्टार के लिए जोशीला पार्टी गीत';

  @override
  String get inspirationStyleThankAFriend => 'गर्मजोशी भरा धन्यवाद गीत';

  @override
  String get inspirationStyleWedding => 'बड़े दिन के लिए खुशनुमा, रोमांटिक गीत';

  @override
  String get inspirationStyleInMemory => 'कोमल, उम्मीद भरी श्रद्धांजलि';

  @override
  String get inspirationStyleFestival => 'चमकदार, उत्सवी मौसमी शुभकामना';

  @override
  String get inspirationStylePetAnthem => 'पालतू के लिए प्यारी, उछलती धुन';

  @override
  String get inspirationStyleHometown => 'गर्व और यादों से भरा अपने शहर का गीत';

  @override
  String get settingsSectionLanguage => 'भाषा';

  @override
  String get settingsSectionProfile => 'प्रोफ़ाइल';

  @override
  String get settingsCredits => 'क्रेडिट';

  @override
  String get settingsAccountId => 'खाता ID';

  @override
  String get settingsCopyAccountId => 'खाता ID कॉपी करें';

  @override
  String get devSectionTitle => 'डेवलपर (केवल DEV)';

  @override
  String get devKeychainReset => 'Keychain कुंजियाँ हटाएँ';

  @override
  String get devKeychainResetHint => 'डिवाइस ID और सत्र टोकन';

  @override
  String get devKeychainResetConfirmTitle => 'Keychain कुंजियाँ हटाएँ?';

  @override
  String get devKeychainResetConfirmBody =>
      'Keychain से डिवाइस ID और सत्र टोकन मिटा दिए जाएंगे। मौजूदा अतिथि खाता वापस नहीं मिलेगा; ऐप नए अतिथि के रूप में साइन इन करेगा।';

  @override
  String get devKeychainResetDone =>
      'Keychain कुंजियाँ हटाई गईं — नए अतिथि के रूप में साइन इन';

  @override
  String get settingsAppLanguage => 'ऐप की भाषा';

  @override
  String get settingsLanguageSystem => 'सिस्टम की भाषा इस्तेमाल करें';

  @override
  String settingsLanguageSystemValue(String language) {
    return 'सिस्टम ($language)';
  }

  @override
  String get settingsLanguageNativeName => 'हिन्दी';

  @override
  String get settingsLanguageSaveFailed =>
      'भाषा सेव नहीं हो सकी। फिर कोशिश करें।';

  @override
  String get settingsLyricsLanguageHint => 'नए गानों पर लागू होगा।';

  @override
  String composerRemoveInspiration(String name) {
    return '$name हटाएँ';
  }

  @override
  String get composerPromptHint =>
      'गीत के बारे में लिखें या ऊपर कोई आइडिया चुनें';

  @override
  String get composerPromptHintWide =>
      'गीत के बारे में लिखें या कोई आइडिया चुनें';

  @override
  String get composerWordsLabel => 'आपके शब्द';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString फ़ोटो जोड़ी गईं',
      one: '$countString फ़ोटो जोड़ी गई',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return 'गीत के विकल्प: $summary';
  }

  @override
  String get composerOptionsShow => 'विकल्प दिखाएँ';

  @override
  String get composerOptionsHide => 'विकल्प छिपाएँ';

  @override
  String get composerSummaryAnyVocals => 'कोई भी आवाज़';

  @override
  String get composerSummaryAnyGenre => 'कोई भी शैली';

  @override
  String get composerSummaryLyrics => 'अपने बोल';

  @override
  String get composerSummaryVideo => 'लिरिक वीडियो';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'प्रीव्यू बनाएँ · मुफ़्त',
      'preview': 'प्रीव्यू बनाएँ · 1 प्रीव्यू',
      'other': 'प्रीव्यू बनाएँ',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': '$name के लिए प्रीव्यू बनाएँ · मुफ़्त',
      'preview': '$name के लिए प्रीव्यू बनाएँ · 1 प्रीव्यू',
      'other': '$name के लिए प्रीव्यू बनाएँ',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': 'पूरा गाना बनाएँ · 1 गाना',
      'other': 'पूरा गाना बनाएँ',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => 'इस टेक्स्ट का उपयोग करें';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level $seconds सेकंड में शुरू होगा';
  }

  @override
  String planPerWeek(String price) {
    return '$price/सप्ताह';
  }

  @override
  String get planCreditsWeekly => 'हर हफ़्ते नए क्रेडिट';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'दिन',
      'week': 'सप्ताह',
      'month': 'महीने',
      'year': 'साल',
      'other': 'अवधि',
    });
    return 'पहले $_temp0 पर $percent% की छूट';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return '$introPrice की शुरुआती कीमत के बाद, आपसे अपने-आप $pricePerPeriod लिया जाएगा। नवीनीकरण से पहले कभी भी रद्द करें।';
  }

  @override
  String get storePreviewAHook => 'उनके नाम से शुरू करें';

  @override
  String get storePreviewAWords => 'उनके बारे में तीन शब्द';

  @override
  String get storePreviewAWait => 'आपका गाना बन रहा है';

  @override
  String get storePreviewAChorus => 'कोरस में उनका नाम';

  @override
  String get storePreviewAEnd => 'उनके नाम वाला गाना';

  @override
  String get storePreviewBHook => 'अपनी तस्वीरों से शुरू करें';

  @override
  String get storePreviewBVideo => 'लिरिक वीडियो भी बनाएँ';

  @override
  String get storePreviewBWait => 'आपका गाना बन रहा है';

  @override
  String get storePreviewBLyrics => 'स्क्रीन पर सिंक बोल';

  @override
  String get storePreviewBMood => 'तस्वीरें माहौल बनाती हैं।';

  @override
  String get storePreviewBShare => 'वीडियो शेयर करें।';

  @override
  String get storePreviewBLanguage => 'आपकी भाषा में बोल';

  @override
  String get storePreviewAShare => 'कार्ड बनाकर भेजें';

  @override
  String get storePreviewCta => 'अपना पहला गीत बनाएँ';

  @override
  String get storePreviewDisclosure => 'सदस्यता या क्रेडिट आवश्यक है';

  @override
  String get storeCreativeHeader => 'अपनों के लिए गाने';

  @override
  String get storeCreativeSearch => 'एक नाम से बनाएं गाना';

  @override
  String get storeCreativeBirthday => 'नाम वाला जन्मदिन गीत';

  @override
  String get storeCreativePhoto => 'आपकी तस्वीरें बनें गाना';

  @override
  String get storeCreativeWedding => 'आपकी शादी के लिए एक गाना';
}
