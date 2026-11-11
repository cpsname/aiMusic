// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonCancel => 'Vazgeç';

  @override
  String get startupLoading => 'Akort yapılıyor…';

  @override
  String get commonErrorTitle => 'Bir sorun oluştu';

  @override
  String get updateRequiredTitle => 'Güncelleme gerekli';

  @override
  String get updateRequiredMessage =>
      'Devam etmek için yeni bir sürüm gerekiyor.';

  @override
  String get updateNow => 'Şimdi güncelle';

  @override
  String get maintenanceTitle => 'Planlı bakım';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Yaklaşık $minutesString dk içinde yeniden hizmette olması bekleniyor';
  }

  @override
  String get featureUnavailable => 'Bu özellik geçici olarak kullanılamıyor.';

  @override
  String get navProfile => 'Profil';

  @override
  String get navStore => 'Mağaza';

  @override
  String get navUpload => 'Yükle';

  @override
  String get uploadTitle => 'Yüklemeler';

  @override
  String get uploadSubtitle =>
      'Karma hesaplama, anında tekilleştirme ve ilerleme göstergesiyle önceden imzalı, doğrudan R2\'ye yükleme.';

  @override
  String get uploadPick => 'Görsel seç ve yükle';

  @override
  String get uploadAgain => 'Başka bir tane yükle';

  @override
  String get uploadPhaseHashing => 'Karma hesaplanıyor…';

  @override
  String get uploadPhaseSigning => 'Yükleme bileti isteniyor…';

  @override
  String uploadPhaseUploading(String percent) {
    return 'Yükleniyor $percent';
  }

  @override
  String get uploadPhaseFinalizing => 'Tamamlanıyor…';

  @override
  String get uploadDone => 'Yüklendi.';

  @override
  String get uploadDedup => 'Anında: Bu dosya sunucuda zaten vardı.';

  @override
  String get uploadOpenLink => 'Dosyayı görüntüle';

  @override
  String get uploadFailed => 'Yükleme başarısız oldu.';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Dosya çok büyük (en fazla $limitString MB).';
  }

  @override
  String get uploadUnsupportedType => 'Desteklenmeyen dosya türü.';

  @override
  String get profileGuestTitle => 'Misafir';

  @override
  String get profileGuestSubtitle =>
      'Satın aldıklarını tüm cihazlarında korumak için giriş yap.';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get profileBalanceLabel => 'Krediler';

  @override
  String get profileAccountId => 'Hesap kimliği';

  @override
  String get profileFeaturesLabel => 'Etkin avantajlar';

  @override
  String get profileNoFeatures => 'Henüz etkin avantaj yok.';

  @override
  String get profileSubscriptionLabel => 'Abonelik';

  @override
  String get profileManageSubscription => 'Aboneliği yönet';

  @override
  String get subscriptionActive => 'Etkin';

  @override
  String get subscriptionInactive => 'Yok';

  @override
  String get profileDeleteAccount => 'Hesabı sil';

  @override
  String get deleteAccountTitle => 'Bu hesap silinsin mi?';

  @override
  String get deleteAccountMessage =>
      'Bu işlem geri alınamaz: Bu hesap ile kredileri ve avantaj kayıtları kalıcı olarak erişilemez hale gelir ve yeni bir hesap oluşturulur. Etkin bir app store aboneliği, hesap silinerek iptal edilmez — aboneliğini app store ayarlarından yönet veya daha sonra Satın alımları geri yükle ile yeniden bağla.';

  @override
  String get deleteAccountConfirm => 'Sil';

  @override
  String get deleteAccountWorking => 'Hesap siliniyor…';

  @override
  String get deleteAccountDone => 'Hesap silindi.';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Üyelik tarihi: $dateString';
  }

  @override
  String get loginTitle => 'Giriş yap';

  @override
  String get loginUsername => 'Kullanıcı adı';

  @override
  String get loginPassword => 'Parola';

  @override
  String get loginSubmit => 'Giriş yap';

  @override
  String get paywallTitle => 'Şarkının tamamını al';

  @override
  String get paywallSubtitle =>
      'Ön izlemeni sözleriyle birlikte 2 dakikalık bir şarkıya dönüştür — indirip kullanman için tamamen senin.';

  @override
  String get paywallRestore => 'Satın alımları geri yükle';

  @override
  String get paywallAutoRenewNotice =>
      'Ödeme, onay anında Apple Hesabından tahsil edilir. Abonelikler, mevcut dönemin bitiminden en az 24 saat önce iptal edilmediği sürece aynı fiyat ve süreyle otomatik olarak yenilenir. Ücretsiz deneme sona erdiğinde ücretli aboneliğe dönüşür. İstediğin zaman App Store hesap ayarlarından yönetebilir veya iptal edebilirsin.';

  @override
  String get paywallContinue => 'Devam et';

  @override
  String get paywallFreeTrial => 'Ücretsiz deneme';

  @override
  String get paywallOffer => 'Teklif';

  @override
  String get paywallManage => 'Yönet';

  @override
  String get paywallTermsOfUse => 'Kullanım Koşulları';

  @override
  String get paywallPrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get paywallSubscriptionTerms => 'Abonelik Koşulları';

  @override
  String get commonLinkError => 'Bağlantı açılamadı.';

  @override
  String get commonError => 'Bir sorun oluştu.';

  @override
  String get commonNetworkError =>
      'Ağ hatası — bağlantını kontrol edip tekrar dene.';

  @override
  String get commonOfflineError =>
      'Çevrim dışı görünüyorsun. Bağlantını kontrol edip tekrar dene.';

  @override
  String get networkErrorTitle => 'Bağlantı sorunu';

  @override
  String get configErrorTitle => 'Uygulama yapılandırma sorunu';

  @override
  String get configErrorMessage =>
      'Bu sürüm hizmetimize ulaşamıyor. Uygulamayı App Store\'dan güncelle veya yeniden yükle. Sorun devam ederse destek ekibiyle iletişime geç.';

  @override
  String get commonAuthError =>
      'Oturumunun süresi doldu — lütfen tekrar giriş yap.';

  @override
  String get paywallProductsErrorTitle => 'Ürünler yüklenemedi';

  @override
  String get paywallNoProducts => 'Şu anda kullanılabilir ürün yok.';

  @override
  String get paywallPurchaseSuccess => 'Satın alma tamamlandı — keyfini çıkar!';

  @override
  String get paywallProcessing => 'Satın alman işleniyor…';

  @override
  String get paywallVerifying => 'Satın alman doğrulanıyor…';

  @override
  String get paywallPurchaseFailed => 'Satın alma tamamlanamadı.';

  @override
  String get paywallRestoreStarted => 'Satın alımların geri yükleniyor…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString satın alım geri yüklendi.',
      one: '$countString satın alım geri yüklendi.',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => 'Geri yüklenecek satın alım yok.';

  @override
  String get paywallDeferred =>
      'Onay bekleniyor — onaylandığında işlemi tamamlayacağız.';

  @override
  String get paywallAlreadySubscribed => 'Zaten abonesin.';

  @override
  String get paywallBillingRetry =>
      'Aboneliğini sürdürmek için ödeme yöntemini güncelle.';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString günlük ücretsiz deneme';
  }

  @override
  String get cycleOneTime => 'tek seferlik';

  @override
  String get cycleWeekly => '/ hafta';

  @override
  String get cycleMonthly => '/ ay';

  @override
  String get cycleQuarterly => '/ 3 ay';

  @override
  String get cycleSemiAnnual => '/ 6 ay';

  @override
  String get cycleAnnual => '/ yıl';

  @override
  String get cycleLifetime => 'ömür boyu';

  @override
  String get navCreate => 'Oluştur';

  @override
  String get navLibrary => 'Arşiv';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get commonContinue => 'Devam et';

  @override
  String get commonBack => 'Geri';

  @override
  String get createTitle => 'Bu şarkı kimin için?';

  @override
  String get occasionBirthday => 'Doğum Günü';

  @override
  String get occasionBirthdayHint => 'Onun özel günü için neşeli bir şarkı';

  @override
  String get occasionAnniversary => 'Yıl Dönümü';

  @override
  String get occasionAnniversaryHint => 'Birlikte yazdığınız hikâyeyi kutlayın';

  @override
  String get occasionConfession => 'Aşk İtirafı';

  @override
  String get occasionConfessionHint => 'Kalbinden geçenleri söyle';

  @override
  String get occasionWedding => 'Düğün';

  @override
  String get occasionWeddingHint => 'Sonsuza dek sürecek anınız için bir şarkı';

  @override
  String get occasionMemorial => 'Anısına';

  @override
  String get occasionMemorialHint => 'Değer verdiğin birini an';

  @override
  String get occasionFestival => 'Bayram';

  @override
  String get occasionFestivalHint => 'Özel günler için sıcak dilekler';

  @override
  String get occasionBrand => 'Marka Jingle\'ı';

  @override
  String get occasionBrandHint => 'Markan için akılda kalan bir melodi';

  @override
  String get occasionSoundtrack => 'Video Müziği';

  @override
  String get occasionSoundtrackHint => 'Hikâyene uyan müzik';

  @override
  String get festivalNewYear => 'Yılbaşı';

  @override
  String get festivalThanksgiving => 'Şükran Günü';

  @override
  String get festivalDiwali => 'Diwali';

  @override
  String get festivalCarnival => 'Karnaval';

  @override
  String get festivalEid => 'Bayram';

  @override
  String get festivalLunarNewYear => 'Ay Yeni Yılı';

  @override
  String get regionTitle => 'Nerede dinlenecek?';

  @override
  String get regionSearchHint => 'Ülke ara';

  @override
  String get regionLanguageSheetTitle => 'Şarkı sözü dili';

  @override
  String get countryUS => 'Amerika Birleşik Devletleri';

  @override
  String get countryGB => 'Birleşik Krallık';

  @override
  String get countryCA => 'Kanada';

  @override
  String get countryAU => 'Avustralya';

  @override
  String get countryDE => 'Almanya';

  @override
  String get countryFR => 'Fransa';

  @override
  String get countryJP => 'Japonya';

  @override
  String get countryKR => 'Güney Kore';

  @override
  String get countryBR => 'Brezilya';

  @override
  String get countryMX => 'Meksika';

  @override
  String get countryIN => 'Hindistan';

  @override
  String get countryID => 'Endonezya';

  @override
  String get countryVN => 'Vietnam';

  @override
  String get countryTR => 'Türkiye';

  @override
  String get languageEn => 'İngilizce';

  @override
  String get languageFr => 'Fransızca';

  @override
  String get languageDe => 'Almanca';

  @override
  String get languageJa => 'Japonca';

  @override
  String get languageKo => 'Korece';

  @override
  String get languagePtBR => 'Portekizce (Brezilya)';

  @override
  String get languageEsMX => 'İspanyolca (Meksika)';

  @override
  String get languageHi => 'Hintçe';

  @override
  String get languageId => 'Endonezce';

  @override
  String get languageVi => 'Vietnamca';

  @override
  String get languageTr => 'Türkçe';

  @override
  String get languageZhHans => 'Çince (Basitleştirilmiş)';

  @override
  String get languageZhHant => 'Çince (Geleneksel)';

  @override
  String get inputNameLabel => 'Adı';

  @override
  String get inputNameOptionalLabel => 'Ad (isteğe bağlı)';

  @override
  String get inputNameHint => 'ör. Alex';

  @override
  String get inputKeywordsLabel => 'Onu anlatan üç kelime';

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
      'Bu sözler bana ait veya kullanma hakkına sahibim';

  @override
  String get issueRecipientMissing => 'Adını ekle.';

  @override
  String get issueRecipientTooLong => 'Adlar en fazla 24 karakter olabilir.';

  @override
  String get issueBriefMissing =>
      'Şarkıyı anlat: birkaç kelime, şarkı sözü ya da fotoğraf.';

  @override
  String get issueDescriptionMissing =>
      'Bu fikir senin sözlerine ihtiyaç duyuyor — şarkı hakkında bir cümle yaz.';

  @override
  String get generatingBackToEdit => 'Düzenlemeye dön';

  @override
  String get issueKeywordTooLong => 'Her kelime en fazla 20 karakter olabilir.';

  @override
  String get issueTooManyKeywords => 'En fazla üç kelime kullan.';

  @override
  String get issueArtistName =>
      'Sanatçı adları kullanılamaz — bunun yerine duyguyu anlat.';

  @override
  String get issueStyleImitation =>
      'Bir şarkıcıyı veya grubu taklit edemeyiz. Bunun yerine ruh halini anlat.';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Sözler en fazla $limitString karakter olabilir.';
  }

  @override
  String get issueLyricsNotOriginal =>
      'Bu sözler var olan bir şarkıya benziyor. Lütfen kendi sözlerini yaz.';

  @override
  String get issueLyricsOwnership =>
      'Sözleri kullanma hakkına sahip olduğunu onayla.';

  @override
  String get issueTooManyPhotos => 'En fazla 10 fotoğraf seç.';

  @override
  String get photosTitle => 'Birkaç fotoğraf seç';

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
      'Fotoğraflar şarkıyı yazmak için yalnızca bir kez kullanılır ve 24 saat içinde sunucularımızdan silinir.';

  @override
  String get photosAdd => 'Fotoğraf ekle';

  @override
  String get photosCreate => 'Fotoğraflardan oluştur';

  @override
  String get photosEmpty => 'O anı anlatan 1–10 fotoğraf seç.';

  @override
  String get generatingStepPolishing =>
      'Kelimelerin bu iPhone\'da düzenleniyor…';

  @override
  String get generatingStepUploading => 'Fotoğrafların gönderiliyor…';

  @override
  String get generatingStepSubmitting => 'Stüdyoya gönderiliyor…';

  @override
  String get errorSafetyBlocked =>
      'Bunu yapamıyoruz — farklı kelimeler dene ve sanatçı adı kullanma.';

  @override
  String get errorQuotaExhausted =>
      'Bu ayın şarkılarını kullandın. Paket ekle veya planını yükselt.';

  @override
  String get errorUpstreamTimeout =>
      'Her zamankinden uzun sürüyor. Denemeye devam edip sana haber vereceğiz.';

  @override
  String get errorUpstreamRateLimited =>
      'Şu anda çok sayıda şarkı yapılıyor. Seninki sıraya alındı.';

  @override
  String get errorAttestFailed => 'Lütfen Songlet\'i App Store\'dan güncelle.';

  @override
  String get errorImageRejected =>
      'Bu fotoğraflardan biri kullanılamıyor. Başka bir tane dene.';

  @override
  String get errorNetworkOffline =>
      'Çevrim dışısın. Arşivin yine de çalışıyor.';

  @override
  String get errorDownloadLocked =>
      'Bu şarkı indirilemiyor — onu oluşturan satın alma iade edildi ya da planının süresi doldu. Yine de çalabilirsin.';

  @override
  String get errorJobAlreadyFinished =>
      'Zaten tamamlandı, iptal edilecek bir şey yok.';

  @override
  String get errorMvSongNotReady => 'Bu şarkı henüz videoya hazır değil.';

  @override
  String get errorMvSongTooLong =>
      'Bu şarkı tam video için çok uzun — nakarat videosunu dene.';

  @override
  String get errorMvSongExpired =>
      'Bu şarkının süresi doldu. Video yapmak için yeniden oluştur.';

  @override
  String get errorMvNotFound => 'Bu video artık kullanılamıyor.';

  @override
  String get errorMvPhotosExpired =>
      'Bu fotoğrafların süresi doldu — yeniden seç.';

  @override
  String get errorMvRenderFailed =>
      'Bu videoyu bitiremedik. Kredilerin geri geldi — tekrar dene.';

  @override
  String get mvHubTitle => 'Video yap';

  @override
  String mvHubSubtitle(String title) {
    return '“$title” şarkısını müzik videosuna dönüştür.';
  }

  @override
  String get mvLevelLyricVideo => 'Sözlü video';

  @override
  String get mvLevelLyricHint => 'Sözlerinin olduğu sabit bir sahne';

  @override
  String get mvLevelChorus => 'Nakarat videosu';

  @override
  String get mvLevelChorusHint => 'Nakaratının 30 saniyesi, yapay zekâ çekimi';

  @override
  String get mvLevelFull => 'Tam şarkı videosu';

  @override
  String get mvLevelFullHint => 'Tüm şarkı, sahne sahne';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString kredi',
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
      other: '$creditsString kredin var',
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
      other: '$creditsString daha gerekli',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => 'Fiyat kontrol ediliyor…';

  @override
  String get mvOptionsHeader => 'Seçenekler';

  @override
  String get mvAspectLabel => 'Biçim';

  @override
  String get mvAspectPortrait => 'Dikey';

  @override
  String get mvAspectLandscape => 'Yatay';

  @override
  String get mvAspectSquare => 'Kare';

  @override
  String get mvQualityLabel => 'Kalite';

  @override
  String get mvQualityStandard => 'Standart';

  @override
  String get mvQualityHigh => 'Yüksek';

  @override
  String get mvSubtitlesLabel => 'Ekranda sözler';

  @override
  String get mvPhotosLabel => 'Referans fotoğraflar';

  @override
  String get mvPhotosHint =>
      'Sahneyi ve renkleri belirler — yüzler kullanılmaz';

  @override
  String mvPhotosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fotoğraf',
    );
    return '$_temp0';
  }

  @override
  String get mvChorusLabel => 'Nakarat';

  @override
  String get mvChorusAuto => 'Otomatik bulunur';

  @override
  String get mvChorusCustom => 'Anı seç';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => 'Videoyu yap';

  @override
  String get mvBuyPack => 'Paketi al ve yap';

  @override
  String get mvSongLocked => 'Şarkın video için kaydedildi.';

  @override
  String get mvGeneratingTitle => 'Videon yapılıyor…';

  @override
  String get mvStageQueued => 'Başlamak için bekliyor';

  @override
  String get mvStageSlicing => 'Anlar seçiliyor';

  @override
  String get mvStageStoryboarding => 'Storyboard yazılıyor';

  @override
  String get mvStageKeyframing => 'Sahneler çiziliyor';

  @override
  String get mvStageRendering => 'Sahneler çekiliyor';

  @override
  String get mvStageAssembling => 'Kurgulanıyor';

  @override
  String get mvStageDone => 'Tamam';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Sahne $doneString/$totalString';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Genellikle yaklaşık $minutesString dakika';
  }

  @override
  String get mvCancelRequested => 'Geçerli sahneden sonra duracak…';

  @override
  String get mvCancelTitle => 'Bu video durdurulsun mu?';

  @override
  String get mvCancelQueued => 'Henüz başlamadı, hiçbir şey kullanılmayacak.';

  @override
  String get mvCancelStarted =>
      'Zaten başladı. Yapılan sahneler ücretlendirilir, kalanı geri gelir.';

  @override
  String get mvCancelConfirm => 'Videoyu durdur';

  @override
  String get mvCancelled => 'Video durduruldu';

  @override
  String get mvCancelledRefunded =>
      'Video durduruldu — hiçbir şey kullanılmadı';

  @override
  String get mvNothing => 'Şu anda video yapılmıyor.';

  @override
  String get mvQuotaTitle => 'Yeterli kredi yok';

  @override
  String get mvAiLabelBurnedIn =>
      'Yapay zekâ üretimi — rozet videonun bir parçası';

  @override
  String get mvSave => 'Fotoğraflar\'a kaydet';

  @override
  String get mvSaveFiles => 'Dosyalar\'a kaydet';

  @override
  String get mvShareText => 'Bu müzik videosunu Songlet ile yaptım 🎬';

  @override
  String get mvMissing => 'Bu video artık bu cihazda değil.';

  @override
  String get mvDeleteTitle => 'Bu video silinsin mi?';

  @override
  String get mvDeleteBody => 'Bu cihazdan kaldırılır.';

  @override
  String get mvDeleted => 'Video silindi';

  @override
  String get mvProvenance =>
      'Google Lyria 3 ve yapay zekâ video modelleriyle yapıldı · Yapay zekâ üretimi';

  @override
  String get detailVideos => 'Videolar';

  @override
  String get detailMakeVideo => 'Video yap';

  @override
  String get mvStatusReady => 'Hazır';

  @override
  String get mvStatusPending => 'Yapılıyor…';

  @override
  String get mvStatusFailed => 'Bitmedi';

  @override
  String get mvPackTitle => 'Müzik videosu';

  @override
  String get mvPackChorusSubtitle => 'Bir nakarat videosu';

  @override
  String get mvPackFullSubtitle => 'Bir tam şarkı videosu';

  @override
  String get paywallMvHeroTitle => 'Video yap';

  @override
  String get paywallMvHeroSubtitle =>
      'Şarkının müzik videosu için kredi — kaydet ve paylaş.';

  @override
  String get playerAiGenerated => 'Yapay zeka ile üretildi';

  @override
  String get playerLoop => 'Döngü';

  @override
  String get playerPlay => 'Çal';

  @override
  String get playerPause => 'Duraklat';

  @override
  String get playerPreviewLabel => '30 saniyelik ön izleme';

  @override
  String playerTitleFor(String name) {
    return '$name için';
  }

  @override
  String get downloadSaved => 'Dosyalar\'a kaydedildi.';

  @override
  String get shareComposing => 'Paylaşım kartın hazırlanıyor…';

  @override
  String get shareFailed => 'Paylaşım kartı oluşturulamadı.';

  @override
  String get shareText => 'Bu şarkıyı Songlet ile yaptım 🎵';

  @override
  String get paywallBestValue => 'En avantajlı';

  @override
  String get paywallStartTrial => 'Ücretsiz denemeyi başlat';

  @override
  String get paywallClose => 'Kapat';

  @override
  String get paywallSeePlans => 'Abonelikleri gör';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Planın etkin — bu dönem $countString tam şarkı hakkın kaldı.',
      one: 'Planın etkin — bu dönem $countString tam şarkı hakkın kaldı.',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => 'Şarkıların burada yer alacak.';

  @override
  String get libraryEmptyAction => 'İlk şarkını yap';

  @override
  String get libraryPending => 'Besteleniyor…';

  @override
  String get libraryPreviewBadge => 'Ön izleme';

  @override
  String get librarySongBadge => 'Tam şarkı';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsPlan => 'Planın';

  @override
  String get settingsPlanUnavailable =>
      'Planın yüklenemedi. Daha sonra tekrar denemek için aşağı çek.';

  @override
  String get tierFree => 'Abonelik yok';

  @override
  String get tierPack => 'Şarkı paketleri';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tam şarkı hakkın kaldı',
      one: '$countString tam şarkı hakkın kaldı',
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
      other: '$countString ön izleme hakkın kaldı',
      one: '$countString ön izleme hakkın kaldı',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Sıfırlanma: $dateString';
  }

  @override
  String get settingsUpgrade => 'Yükselt';

  @override
  String get appTagline => 'Sevdiklerin için şarkılar';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonDone => 'Bitti';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonMore => 'Daha fazla';

  @override
  String get commonCopy => 'Kopyala';

  @override
  String get commonCopied => 'Kopyalandı';

  @override
  String get commonNotNow => 'Şimdi değil';

  @override
  String get commonLearnMore => 'Daha fazla bilgi';

  @override
  String get commonSeeAll => 'Tümünü gör';

  @override
  String get commonKeepGoing => 'Devam et';

  @override
  String get composerHint => 'İstediğin şarkıyı anlat';

  @override
  String get composerAddPhotos => 'Fotoğraf ekle';

  @override
  String get composerSourceMusicHint => 'Kendi kelimelerinle anlat';

  @override
  String get composerDictate => 'Dikte et';

  @override
  String get composerStopDictation => 'Dikteyi durdur';

  @override
  String get lengthPreview => 'Önizleme';

  @override
  String get lengthFull => 'Tam şarkı';

  @override
  String get paramLength => 'Süre';

  @override
  String get paramVocals => 'Vokal';

  @override
  String get paramGenre => 'Tür';

  @override
  String templatePlaySample(String name) {
    return '$name örneğini çal';
  }

  @override
  String get templatePauseSample => 'Örneği duraklat';

  @override
  String get lengthShort => 'Kısa';

  @override
  String get lengthShortHint => '30 saniyelik önizleme';

  @override
  String get lengthStandard => 'Standart';

  @override
  String get lengthStandardHint => 'yaklaşık 2 dakika, Pro';

  @override
  String get vocalsCustom => 'Otomatik';

  @override
  String get vocalsCustomHint => 'açıklamana göre';

  @override
  String get vocalsCustomDetail => 'Vokal tarzı açıklamana göre belirlenir.';

  @override
  String get vocalsOn => 'Vokalli';

  @override
  String get vocalsInstrumental => 'Enstrümantal';

  @override
  String vocalsLyricsIn(String language) {
    return 'Şarkı sözleri $language yazılır';
  }

  @override
  String get genreCustom => 'Otomatik';

  @override
  String get genreCustomHint => 'açıklamana göre';

  @override
  String genrePopularIn(String country) {
    return '$country popüler';
  }

  @override
  String get genreAll => 'Tüm türler';

  @override
  String get regionHelper => 'Önerilen 3 türü ve şarkı sözü dilini değiştirir';

  @override
  String regionLyricsRow(String language) {
    return 'Şarkı sözü dili: $language';
  }

  @override
  String get regionNoMatch => 'Eşleşen ülke yok';

  @override
  String get keywordAdd => 'Kelime ekle';

  @override
  String keywordRemove(String word) {
    return '$word öğesini kaldır';
  }

  @override
  String get nameClear => 'Adı temizle';

  @override
  String get lyricsOptional => 'Kendi sözlerini yaz (isteğe bağlı)';

  @override
  String get issueRecipientArtistName => 'Sanatçı adları kullanılamaz.';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Açıklamayı $limitString karakterin altında tut.';
  }

  @override
  String get voiceRecording => 'Kaydediliyor…';

  @override
  String get voiceStarting => 'Başlatılıyor…';

  @override
  String get voiceListening =>
      'Şarkının kime olduğunu ve neyi sevdiğini söyle…';

  @override
  String get voiceOnDevice => 'Cihazda yazıya dökme';

  @override
  String get voicePermissionDenied =>
      'Dikte etmek için Ayarlar’da Songlet’e mikrofon ve konuşma tanıma izni ver.';

  @override
  String get voiceUnavailable => 'Bu cihazda bu dil için dikte kullanılamıyor.';

  @override
  String get voiceApplied => 'Sesinden eklendi';

  @override
  String get photoRemove => 'Fotoğrafı kaldır';

  @override
  String generatingTitleFor(String name) {
    return '$name için şarkı yazılıyor…';
  }

  @override
  String get generatingTitleGeneric => 'Şarkın yazılıyor…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Genellikle yaklaşık $secondsString saniye';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => 'İlerleme';

  @override
  String get generatingGlimpse => 'Şarkından bir kesit';

  @override
  String get generatingCancelTitle => 'Bu şarkı durdurulsun mu?';

  @override
  String get generatingCancelQueued =>
      'Henüz başlamadı, bu yüzden hakkından düşülmez.';

  @override
  String get generatingCancelStarted => 'Başladı, bu yüzden hakkından düşülür.';

  @override
  String get generatingCancelConfirm => 'Durdur';

  @override
  String get generatingCancelled => 'Şarkı durduruldu';

  @override
  String get generatingCancelledRefunded =>
      'Şarkı durduruldu — hiçbir şey kullanılmadı';

  @override
  String get queueTitle => 'Şu anda çok sayıda şarkı yapılıyor.';

  @override
  String get queueSubtitle => 'Seninki sırada.';

  @override
  String get queuePosition => 'Sıra';

  @override
  String get queueWait => 'tahmini bekleme';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '≈ $minutesString dk';
  }

  @override
  String get generatingNothing => 'Şu anda yapılan bir şarkı yok.';

  @override
  String get previewGetFull => '2 dakikalık tam şarkıyı al';

  @override
  String get previewShare => 'Önizlemeyi paylaş';

  @override
  String get previewAnother => 'Başka bir sürüm dene (1 önizleme kullanır)';

  @override
  String get playerPosition => 'Çalma konumu';

  @override
  String get playerPrevSection => 'Önceki bölüm';

  @override
  String get playerNextSection => 'Sonraki bölüm';

  @override
  String get playerShuffle => 'Bölümleri karıştır';

  @override
  String get playerRepeat => 'Tekrarla';

  @override
  String get playerProvenance =>
      'Google Lyria 3 ile yapıldı · SynthID filigranı · Yapay zekâ ile üretildi';

  @override
  String get playerMissing => 'Bu şarkı artık bu cihazda değil.';

  @override
  String get actionDownload => 'İndir';

  @override
  String get actionShare => 'Paylaş';

  @override
  String get actionLicense => 'Lisans';

  @override
  String get actionRegenerate => 'Yeniden oluştur';

  @override
  String get actionDetails => 'Ayrıntılar';

  @override
  String get sectionIntro => 'Giriş';

  @override
  String get sectionVerse => 'Kıta';

  @override
  String get sectionPreChorus => 'Nakarat öncesi';

  @override
  String get sectionChorus => 'Nakarat';

  @override
  String get sectionBridge => 'Köprü';

  @override
  String get sectionOutro => 'Kapanış';

  @override
  String get sectionHook => 'Kanca';

  @override
  String get shareTitle => 'Paylaşım kartı';

  @override
  String get shareSubtitle => 'Bir tema ve düzen seç.';

  @override
  String get shareTheme => 'Tema';

  @override
  String get shareLayout => 'Düzen';

  @override
  String get shareLayoutScene => 'Çizimli';

  @override
  String get shareLayoutText => 'Yalnızca metin';

  @override
  String get paletteTerracotta => 'Kiremit';

  @override
  String get paletteSand => 'Kum';

  @override
  String get paletteOlive => 'Zeytin';

  @override
  String get paletteNavy => 'Lacivert';

  @override
  String get shareAction => 'Paylaş';

  @override
  String get shareSaveVideo => 'Videoyu kaydet';

  @override
  String get shareCopyLyrics => 'Sözleri kopyala';

  @override
  String get shareVideoSaved => 'Fotoğraflar’a kaydedildi';

  @override
  String get shareLyricsCopied => 'Sözler kopyalandı';

  @override
  String get shareCardTagline => 'Birisi için bir şarkı';

  @override
  String get shareSaveFailed =>
      'Video kaydedilemedi. Ayarlar’da Songlet’in Fotoğraflar’a eklemesine izin ver.';

  @override
  String get downloadReady => 'Tam şarkı hazır';

  @override
  String get downloadTitle => 'Sonsuza dek senin';

  @override
  String get downloadIntro =>
      'Şarkın hazır. Yüksek kaliteli sesi ve ticari lisansını aşağıdan indir.';

  @override
  String get downloadAudioHeader => 'Sesi indir';

  @override
  String get downloadAudioNote => 'Yüksek kalite';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle => 'Paylaşmak ve her gün dinlemek için ideal';

  @override
  String get downloadWavTitle => 'WAV · 44,1 kHz (Premier)';

  @override
  String get downloadWavSubtitle =>
      'Profesyonel kullanım için en yüksek kalite';

  @override
  String get downloadMp3Action => 'MP3 indir';

  @override
  String get downloadWavAction => 'WAV indir';

  @override
  String get downloadLicenseAction => 'Lisansı indir';

  @override
  String get licenseHeader => 'Ticari lisans';

  @override
  String get licenseIncluded => 'Planına dahil';

  @override
  String get licenseNotIncluded => 'Bir plan veya paketle gelir';

  @override
  String get licensePdfTitle => 'Ticari lisans (PDF)';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString tarihinde oluşturuldu';
  }

  @override
  String licenseId(String id) {
    return 'Lisans kimliği: $id';
  }

  @override
  String get licenseUsesTitle => 'Bu şarkıyı şunlar için kullanabilirsin:';

  @override
  String get usePersonal => 'Kişisel kullanım';

  @override
  String get usePersonalDetail => 'Hediyeler, anılar, ticari olmayan';

  @override
  String get useAds => 'Reklam ve pazarlama';

  @override
  String get useAdsDetail => 'Promosyonlar, ücretli kampanyalar';

  @override
  String get useSocial => 'Sosyal medya';

  @override
  String get useSocialDetail => 'TikTok, Instagram, YouTube vb.';

  @override
  String get usePodcasts => 'Podcast ve videolar';

  @override
  String get usePodcastsDetail => 'Para kazandıran içerik';

  @override
  String get licenseDetailsNote => 'Tüm ayrıntılar lisans PDF’sinde.';

  @override
  String get saveEnjoyHeader => 'Kaydet ve keyfini çıkar';

  @override
  String get saveToFiles => 'Dosyalar’a kaydet';

  @override
  String get addToMusic => 'Müzik’e ekle';

  @override
  String get synthIdNote =>
      'Bu şarkı, indirildikten sonra bile yapay zekâ ile üretilmiş içerik olarak tanınmasını sağlayan bir SynthID filigranı içerir.';

  @override
  String get wavNeedsPremier => 'WAV indirmeleri Premier ile gelir.';

  @override
  String get wavUnavailable =>
      'Bu şarkının WAV dosyası yok. WAV dosyaları şarkı oluşturulduktan sonraki 24 saat içinde kaydedilebilir.';

  @override
  String get libraryFilterAll => 'Tümü';

  @override
  String get libraryJustBecause => 'Öylesine';

  @override
  String libraryPlay(String title) {
    return '$title çal';
  }

  @override
  String libraryActions(String title) {
    return '$title işlemleri';
  }

  @override
  String get libraryDeleteTitle => 'Bu şarkı silinsin mi?';

  @override
  String get libraryDeleteBody =>
      'Bu cihazdan kaldırılır. iCloud eşitlemesi açıksa diğer cihazlarından da kaldırılır.';

  @override
  String get libraryDeleted => 'Şarkı silindi';

  @override
  String get libraryFailed => 'Tamamlanmadı';

  @override
  String get libraryNoMatch => 'Bu an için henüz şarkı yok.';

  @override
  String get detailFullGenerated => 'Tam şarkı oluşturuldu';

  @override
  String get detailPreviewGenerated => 'Önizleme oluşturuldu';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString tarihinde oluşturuldu';
  }

  @override
  String get detailPromptUsed => 'Kullanılan bilgiler';

  @override
  String get detailOccasion => 'Etkinlik';

  @override
  String get detailCountry => 'Ülke';

  @override
  String get detailGenre => 'Tür';

  @override
  String get detailKeywords => 'Anahtar kelimeler';

  @override
  String get detailDescription => 'Açıklama';

  @override
  String get detailLyrics => 'Sözler';

  @override
  String get detailGenerationId => 'Oluşturma kimliği';

  @override
  String get detailRegenerate => 'Aynı tarzda yeniden oluştur';

  @override
  String get detailCustomGenre => 'Açıklamaya göre';

  @override
  String get settingsSectionPlan => 'Satın almalar';

  @override
  String get settingsSectionLibrary => 'Arşiv';

  @override
  String get settingsSectionAbout => 'Hakkında';

  @override
  String get settingsRestore => 'Satın almaları geri yükle';

  @override
  String get settingsManage => 'Aboneliği yönet';

  @override
  String get settingsICloud => 'iCloud eşitlemesi';

  @override
  String get settingsICloudOn => 'Şarkılar cihazların arasında eşitlenir';

  @override
  String get settingsICloudOff => 'Şarkılar yalnızca bu cihazda kalır';

  @override
  String get settingsICloudUnavailable =>
      'Eşitlemek için Ayarlar’da iCloud’a giriş yap';

  @override
  String get settingsLyricsLanguage => 'Varsayılan şarkı sözü dili';

  @override
  String get settingsLyricsLanguageAuto => 'Ülkeye göre';

  @override
  String get settingsTerms => 'Kullanım Koşulları';

  @override
  String get settingsPrivacy => 'Gizlilik Politikası';

  @override
  String settingsVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String get aboutTitle => 'Üretim hakkında';

  @override
  String get aboutSubtitle => 'Songlet şarkılarını nasıl yapıyor';

  @override
  String get aboutLyriaTitle => 'Google Lyria 3 ile';

  @override
  String get aboutLyriaBody =>
      'Şarkılar, Gemini API aracılığıyla Google’ın Lyria 3 modeliyle üretilir. Lyria 3, fikirlerini özgün şarkılara dönüştüren bir müzik üretim modelidir.';

  @override
  String get aboutWatermarkTitle => 'Yerleşik filigran';

  @override
  String get aboutWatermarkBody =>
      'Her şarkı Google’ın SynthID filigranını içerir. Yapay zekâ ile üretilmiş müziği tanımaya yardımcı olur ve kaldırılamaz.';

  @override
  String get aboutImitationTitle => 'Gerçek sanatçıların taklidi yok';

  @override
  String get aboutImitationBody =>
      'Songlet asla gerçek sanatçıları, seslerini veya belirli tarzlarını taklit etmez. Şarkılar özgündür; fikirlerinden, açıklamalarından ve fotoğraflarından oluşturulur.';

  @override
  String get aboutPrivacyTitle => 'Gizliliğin önemli';

  @override
  String get aboutPrivacyBody =>
      'Fotoğraflar ve açıklamalar 24 saat içinde sunucularımızdan silinir. Şarkın oluşturulduktan sonra görsellerini veya açıklamalarını saklamayız.';

  @override
  String get aboutBanner =>
      'Paylaştığın her şarkı yapay zekâ ile üretildi olarak etiketlenir.';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · Google Lyria 3 ile yapıldı';
  }

  @override
  String get festivalKicker => 'Hikâyeni yaşa';

  @override
  String get festivalComing => 'geliyor!';

  @override
  String get festivalBody => 'Kutlamak için eşsiz bir şarkı yap.';

  @override
  String festivalCta(String festival) {
    return '$festival şarkısı yap';
  }

  @override
  String get festivalPickOccasion => 'Bir etkinlik seç ve üretmeye başla';

  @override
  String get festivalLanguagesTitle => 'Kendi dilinde şarkılar';

  @override
  String festivalLanguagesBody(String language) {
    return '$language ve 12 dilde daha şarkı yap';
  }

  @override
  String get unavailableTitle => 'Geçici olarak kullanılamıyor';

  @override
  String get unavailableMessage =>
      'Songlet şu anda şarkı yapamıyor. Arşivin çalışmaya devam ediyor — biraz sonra tekrar dene.';

  @override
  String get paywallHeroTitle => 'Tam şarkıya dönüştür';

  @override
  String get paywallHeroSubtitle =>
      'Fikrini daha yüksek kaliteli ve tüm haklara sahip eksiksiz bir şarkıya dönüştür.';

  @override
  String get paywallBenefitSongs => 'Daha fazla şarkı';

  @override
  String get paywallBenefitQuality => 'Daha yüksek kalite';

  @override
  String get paywallBenefitCommercial => 'Ticari kullanım';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ayda $countString tam şarkı',
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
      other: 'Ayda $countString önizleme',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'MP3 indirme';

  @override
  String get planMp3Wav => 'MP3 + WAV indirme';

  @override
  String get planLicense => 'Ticari lisans';

  @override
  String get planPriority => 'Öncelikli üretim';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString günlük ücretsiz deneme';
  }

  @override
  String planPerYear(String price) {
    return '$price/yıl';
  }

  @override
  String planPerMonth(String price) {
    return '$price/ay';
  }

  @override
  String get packTitle => 'Sadece birkaç tane mi lazım?';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString şarkılık paket',
    );
    return '$_temp0';
  }

  @override
  String get packNote => 'süresi dolmaz';

  @override
  String get valueForever => 'Şarkıların, sonsuza dek';

  @override
  String get valueDownloads => 'Yüksek kaliteli indirme';

  @override
  String get valueCommercial => 'Ticari kullanıma izin var';

  @override
  String get valuePrivate => 'Önce gizlilik';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return 'Ücretsiz denemeden sonra otomatik olarak $pricePerPeriod tahsil edilir. Deneme bitmeden istediğin zaman iptal et.';
  }

  @override
  String get paywallSubscribe => 'Abone ol';

  @override
  String get paywallBuyPack => 'Paketi satın al';

  @override
  String get templateBirthdayWish => 'Doğum Günü Dileği';

  @override
  String get templateBirthdayWishHint => 'Özel günü için özel bir şarkı';

  @override
  String get templateBirthdayParty => 'Doğum Günü Partisi';

  @override
  String get templateBirthdayPartyHint =>
      'Doğum günü yıldızı için partiyi coştur';

  @override
  String get templateLoveStory => 'Aşk Hikâyesi';

  @override
  String get templateLoveStoryHint => 'Hikâyeniz şarkıya dönüşsün';

  @override
  String get templateThankAFriend => 'Arkadaşa Teşekkür';

  @override
  String get templateThankAFriendHint => 'Kelimelerin yetmediği bir teşekkür';

  @override
  String get templatePartyInvite => 'Parti Daveti';

  @override
  String get templatePartyInviteHint => 'Herkesi partiye çağır';

  @override
  String get templateWedding => 'Düğün';

  @override
  String get templateWeddingHint => 'Sonsuz anları için bir şarkı';

  @override
  String get templateInMemory => 'Anısına';

  @override
  String get templateInMemoryHint => 'Değer verdiğin birini an';

  @override
  String get templateFestival => 'Bayram';

  @override
  String get templateFestivalHint => 'Özel bir dönem için sıcak dilekler';

  @override
  String get templateRingtone => 'Zil Sesi';

  @override
  String get templateRingtoneHint => 'Sadece sana ait kısa bir döngü';

  @override
  String get templateTeamAnthem => 'Takım Marşı';

  @override
  String get templateTeamAnthemHint => 'Takımı ve tribünü ateşle';

  @override
  String get templateSportsRecap => 'Maç Özeti';

  @override
  String get templateSportsRecapHint => 'Büyük maç, bir şarkıda';

  @override
  String get templateRapBattle => 'Rap Kapışması';

  @override
  String get templateRapBattleHint => 'Dost rakibe dostça dizeler';

  @override
  String get templateComedy => 'Komedi';

  @override
  String get templateComedyHint => 'Aranızdaki şakalar, artık nakaratlı';

  @override
  String get templatePetAnthem => 'Evcil Dost Marşı';

  @override
  String get templatePetAnthemHint => 'En iyi dostun için bir tema şarkısı';

  @override
  String get templateHometown => 'Memleket';

  @override
  String get templateHometownHint => 'Ev dediğin yere sevgi';

  @override
  String get templateBusinessPromo => 'İşletme Tanıtımı';

  @override
  String get templateBusinessPromoHint =>
      'Dükkânın veya markan için akılda kalan bir melodi';

  @override
  String get templateCustom => 'Kendi fikrin';

  @override
  String get mvRecommended => 'Önerilen';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString sn';
  }

  @override
  String get mvViewProgress => 'İlerlemeyi gör';

  @override
  String mvIntentWaiting(String level) {
    return '$level kredi bekliyor';
  }

  @override
  String get mvSongExpiredAction => 'Şarkıyı yeniden yap';

  @override
  String mvQuotaNeed(String level, int required, int available) {
    final intl.NumberFormat requiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requiredString = requiredNumberFormat.format(required);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return '$level için $requiredString kredi gerekiyor. Sende $availableString var.';
  }

  @override
  String get mvQuotaBuyAndContinue => 'Satın al ve devam et';

  @override
  String get mvQuotaMayNeedTwice =>
      'Bulunduğun yerde bir paket yetmeyebilir — iki tane gerekebilir.';

  @override
  String get mvQuotaAutoRetry =>
      'Satın alma tamamlanır tamamlanmaz videon başlar.';

  @override
  String get mvAutoLyricMaking => 'Sözlü videon hazırlanıyor';

  @override
  String get mvAutoChorusDetail => 'Bu şarkıdan, kredilerinle yapılır';

  @override
  String mvAutoReady(String level) {
    return '$level hazır';
  }

  @override
  String get mvAutoView => 'Gör';

  @override
  String get mvUpgradeChorus => 'Nakarat videosu yap';

  @override
  String get mvAutoFailed => 'Video başlatılamadı';

  @override
  String get mvLeaveHint =>
      'Bu ekrandan çıkabilirsin — hazır olması gerektiğinde haber veririz.';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString kredin geri geldi.',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => 'Bu video tamamlanmadı';

  @override
  String get mvRejectedTitle => 'Bir fotoğraf kullanılamadı';

  @override
  String get mvRejectedBody =>
      'Video modeli referans fotoğraflarından birini reddetti. Fotoğrafları değiştirip yeniden dene.';

  @override
  String get mvAdjustPhotos => 'Fotoğrafları değiştir ve yeniden dene';

  @override
  String get mvTryChorus => 'Bunun yerine nakarat videosu yap';

  @override
  String get mvPreparingPhotos => 'Fotoğrafların yükleniyor…';

  @override
  String get mvPreparingSubmit => 'Videon gönderiliyor…';

  @override
  String get mvNotifyTitle => 'Videon hazır olmalı';

  @override
  String mvNotifyBody(String level) {
    return '$level — izlemek için dokun.';
  }

  @override
  String get mvRegenerate => 'Bir tane daha';

  @override
  String get mvEntryTitle => 'Videoya dönüştür';

  @override
  String get mvEntrySubtitle =>
      'Sözlü, nakarat ve tam şarkı videoları krediyle';

  @override
  String get mvEntryDisabled => 'Şarkı bitince kullanılabilir';

  @override
  String get mvEntryChoose => 'Video seç';

  @override
  String get mvEntryWatch => 'Videoyu izle';

  @override
  String get mvChipReady => 'Video';

  @override
  String get mvChipMaking => 'Video yapılıyor';

  @override
  String get lengthAutoVideo => 'Sözlü video da yap';

  @override
  String get lengthAutoVideoHint =>
      'Şarkıdan birkaç dakika sonra hazır · kredi harcar';

  @override
  String get lengthSongAndChorus => 'Şarkı + nakarat videosu';

  @override
  String get lengthSongAndChorusHint =>
      'Önce şarkının tamamı, sonra 30 saniyelik nakarat videosu';

  @override
  String get paywallVideoGroup => 'Müzik videoları';

  @override
  String get planVideoIncluded => 'Hakkınla müzik videosu da yapabilirsin';

  @override
  String get settingsVideoCredits => 'Video kredileri';

  @override
  String get createGenrePop => 'Pop';

  @override
  String get createGenreHipHopRap => 'Hip-hop ve rap';

  @override
  String get createGenreRock => 'Rock';

  @override
  String get createGenreKPop => 'K-pop';

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
  String get createGenreJazzBlues => 'Caz ve blues';

  @override
  String get createGenreClassical => 'Klasik';

  @override
  String get createGenreFolk => 'Folk';

  @override
  String get createGenreLofi => 'Lo-fi';

  @override
  String get createGenreAcoustic => 'Akustik';

  @override
  String get createGenreCinematic => 'Film müziği';

  @override
  String get createGenreAmbient => 'Ambient';

  @override
  String get createGenreBossaNova => 'Bossa nova';

  @override
  String get createGenreIndiePop => 'İndie pop';

  @override
  String get createGenreContemporaryRnb => 'Çağdaş R&B';

  @override
  String get createGenreAlternativeCountry => 'Alternatif country';

  @override
  String get createGenreGarageRock => 'Garage rock';

  @override
  String get createGenreGrime => 'Grime';

  @override
  String get createGenreIndieFolk => 'İndie folk';

  @override
  String get createGenreSynthpop => 'Synthpop';

  @override
  String get createGenrePianoBallad => 'Piyano baladı';

  @override
  String get createGenreSurfRock => 'Surf rock';

  @override
  String get createGenreDeepHouse => 'Deep house';

  @override
  String get createGenreMinimalTechno => 'Minimal tekno';

  @override
  String get createGenreFrenchYeyePop => '60’lar Fransız yé-yé pop';

  @override
  String get createGenreChillout => 'Chillout';

  @override
  String get createGenreJPopIndiePop => 'J-pop indie';

  @override
  String get createGenreChiptune => 'Chiptune';

  @override
  String get createGenreDiscoFunk => 'Disco funk';

  @override
  String get createGenreReggaeton => 'Reggaeton';

  @override
  String get createGenreCumbia => 'Cumbia';

  @override
  String get createGenreLatinJazz => 'Latin caz';

  @override
  String get createGenreBhangra => 'Bhangra';

  @override
  String get createGenreIndianClassical => 'Hint klasik müziği';

  @override
  String get createGenreLofiHipHop => 'Lo-fi hip-hop';

  @override
  String profileAccountIdWithValue(String id) {
    return 'Hesap kimliği: $id';
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
  String get createVocalsCustomSummary => 'Otomatik — açıklamana göre';

  @override
  String mvChipMakingWithProgress(String progress) {
    return 'Video yapılıyor · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return 'Video başlatılamadı · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    return 'Video kredisi: $creditsString';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => 'İlham';

  @override
  String inspirationPlay(String name) {
    return '$name çal';
  }

  @override
  String get inspirationStop => 'Önizlemeyi durdur';

  @override
  String get inspirationNameSoundscape => 'Ses Manzarası';

  @override
  String get inspirationStyleSoundscape => 'Ambiyans dokular, vokalsiz';

  @override
  String get inspirationNameBackgroundMusic => 'Arka Plan Müziği';

  @override
  String get inspirationStyleBackgroundMusic =>
      'Videolar için hafif enstrümantal';

  @override
  String get inspirationNameMemorizeSomething => 'Aklında Kalsın';

  @override
  String get inspirationStyleMemorizeSomething => 'Akılda kalıcı ezber pop';

  @override
  String get inspirationNameTextMessages => 'Mesajlardan Şarkı';

  @override
  String get inspirationStyleTextMessages => 'Mesajlarından eğlenceli pop';

  @override
  String get inspirationNameIntroMusic => 'Giriş Müziği';

  @override
  String get inspirationStyleIntroMusic => 'Cesur, sinematik açılış';

  @override
  String get inspirationNameMontage => 'Montaj';

  @override
  String get inspirationStyleMontage => 'Öne çıkan anlar için coşkulu yükseliş';

  @override
  String get inspirationNameSayItWithATrack => 'Bir Şarkıyla Söyle';

  @override
  String get inspirationStyleSayItWithATrack => 'İçten bir pop baladı';

  @override
  String get inspirationNameBrandJingle => 'Marka Cıngılı';

  @override
  String get inspirationStyleBrandJingle =>
      'Kısa, parlak, akılda kalan nakarat';

  @override
  String get inspirationNameRingtone => 'Zil Sesi';

  @override
  String get inspirationStyleRingtone => '30 saniyelik döngü nakaratı';

  @override
  String get inspirationNameStreaming => 'Canlı Yayın';

  @override
  String get inspirationStyleStreaming => 'Enerjik elektronik yayın girişi';

  @override
  String get inspirationNameSpeechToTrack => 'Sesten Şarkıya';

  @override
  String get inspirationStyleSpeechToTrack => 'Sesin şarkıya dönüşsün';

  @override
  String get inspirationNameRapBattle => 'Rap Kapışması';

  @override
  String get inspirationStyleRapBattle => 'Sert hip-hop';

  @override
  String get inspirationNameComedy => 'Komedi';

  @override
  String get inspirationStyleComedy => 'Tuhaf, neşeli, esprili';

  @override
  String get inspirationNameTeamAnthem => 'Takım Marşı';

  @override
  String get inspirationStyleTeamAnthem => 'Stadyum rock tezahüratı';

  @override
  String get inspirationNameSportsRecap => 'Maç Özeti';

  @override
  String get inspirationStyleSportsRecap => 'Destansı orkestra anları';

  @override
  String get inspirationNamePartyInvite => 'Parti Daveti';

  @override
  String get inspirationStylePartyInvite => 'Dance-pop daveti';

  @override
  String get inspirationNameHappyBirthday => 'İyi ki Doğdun';

  @override
  String get inspirationStyleHappyBirthday =>
      'Sıcak akustik doğum günü şarkısı';

  @override
  String get inspirationNameFriendAppreciation => 'Arkadaşlara Teşekkür';

  @override
  String get inspirationStyleFriendAppreciation => 'İyi hissettiren indie pop';

  @override
  String get inspirationNameLoveStory => 'Aşk Hikâyesi';

  @override
  String get inspirationStyleLoveStory => 'Romantik R&B baladı';

  @override
  String get inspirationNameBirthdayRoast => 'Doğum Günü Takılması';

  @override
  String get inspirationStyleBirthdayRoast =>
      'Şakacı, komik doğum günü şarkısı';

  @override
  String get inspirationNameOdeToYourPet => 'Evcil Dostuna Övgü';

  @override
  String get inspirationStyleOdeToYourPet => 'Sevimli, zıplayan pop';

  @override
  String get inspirationNameHometownTribute => 'Memleket Güzellemesi';

  @override
  String get inspirationStyleHometownTribute => 'Nostaljik folk';

  @override
  String get inspirationNameWeatherReport => 'Hava Durumu';

  @override
  String get inspirationStyleWeatherReport => 'Eğlenceli lounge groove';

  @override
  String get inspirationNameBusinessPromo => 'İşletme Tanıtımı';

  @override
  String get inspirationStyleBusinessPromo => 'Kendinden emin kurumsal pop';

  @override
  String get inspirationStyleBirthdayWish =>
      'Özel günleri için içten bir şarkı';

  @override
  String get inspirationStyleBirthdayParty =>
      'Doğum günü yıldızı için coşkulu parti marşı';

  @override
  String get inspirationStyleThankAFriend =>
      'Sıcak ve minnettar bir teşekkür şarkısı';

  @override
  String get inspirationStyleWedding =>
      'Büyük gün için neşeli, romantik bir şarkı';

  @override
  String get inspirationStyleInMemory => 'Yumuşak, umut dolu bir anma';

  @override
  String get inspirationStyleFestival => 'Parlak, şenlikli bir mevsim tebriği';

  @override
  String get inspirationStylePetAnthem =>
      'Evcil dostun için sevgi dolu, hoplayan bir tema';

  @override
  String get inspirationStyleHometown =>
      'Gururlu, nostaljik bir memleket marşı';

  @override
  String get settingsSectionLanguage => 'Dil';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsCredits => 'Kredi';

  @override
  String get settingsAccountId => 'Hesap kimliği';

  @override
  String get settingsCopyAccountId => 'Hesap kimliğini kopyala';

  @override
  String get devSectionTitle => 'Geliştirici (yalnızca DEV)';

  @override
  String get devKeychainReset => 'Keychain anahtarlarını sil';

  @override
  String get devKeychainResetHint => 'Cihaz kimliği ve oturum belirteçleri';

  @override
  String get devKeychainResetConfirmTitle =>
      'Keychain anahtarları silinsin mi?';

  @override
  String get devKeychainResetConfirmBody =>
      'Cihaz kimliği ve oturum belirteçleri Keychain’den silinir. Mevcut misafir hesabı kurtarılamaz; uygulama yeni bir misafir olarak oturum açar.';

  @override
  String get devKeychainResetDone =>
      'Anahtarlar silindi — yeni misafir olarak giriş yapıldı';

  @override
  String get settingsAppLanguage => 'Uygulama dili';

  @override
  String get settingsLanguageSystem => 'Sistem dilini kullan';

  @override
  String settingsLanguageSystemValue(String language) {
    return 'Sistem ($language)';
  }

  @override
  String get settingsLanguageNativeName => 'Türkçe';

  @override
  String get settingsLanguageSaveFailed => 'Dil kaydedilemedi. Tekrar dene.';

  @override
  String get settingsLyricsLanguageHint => 'Yeni şarkılar için geçerli.';

  @override
  String composerRemoveInspiration(String name) {
    return '$name öğesini kaldır';
  }

  @override
  String get composerPromptHint =>
      'Şarkıyı anlat ya da yukarıdan bir fikir seç';

  @override
  String get composerPromptHintWide => 'Şarkıyı anlat ya da bir fikir seç';

  @override
  String get composerWordsLabel => 'Senin sözlerin';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fotoğraf eklendi',
      one: '$countString fotoğraf eklendi',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return 'Şarkı seçenekleri: $summary';
  }

  @override
  String get composerOptionsShow => 'Seçenekleri göster';

  @override
  String get composerOptionsHide => 'Seçenekleri gizle';

  @override
  String get composerSummaryAnyVocals => 'Vokal serbest';

  @override
  String get composerSummaryAnyGenre => 'Tür serbest';

  @override
  String get composerSummaryLyrics => 'Kendi sözlerin';

  @override
  String get composerSummaryVideo => 'Sözlü video';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Önizleme oluştur · ücretsiz',
      'preview': 'Önizleme oluştur · 1 önizleme',
      'other': 'Önizleme oluştur',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': '$name için önizleme oluştur · ücretsiz',
      'preview': '$name için önizleme oluştur · 1 önizleme',
      'other': '$name için önizleme oluştur',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': 'Tam şarkıyı oluştur · 1 şarkı',
      'other': 'Tam şarkıyı oluştur',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => 'Bu metni kullan';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level $seconds sn içinde başlıyor';
  }

  @override
  String planPerWeek(String price) {
    return '$price/hafta';
  }

  @override
  String get planCreditsWeekly => 'Her hafta yeni kredi';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'İlk gün',
      'week': 'İlk hafta',
      'month': 'İlk ay',
      'year': 'İlk yıl',
      'other': 'İlk dönem',
    });
    return '$_temp0 %$percent indirim';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return '$introPrice tanıtım fiyatından sonra otomatik olarak $pricePerPeriod tahsil edilir. Yenilemeden önce istediğin zaman iptal et.';
  }

  @override
  String get storePreviewAHook => 'Onun adıyla başla';

  @override
  String get storePreviewAWords => 'Onu anlatan üç kelime';

  @override
  String get storePreviewAWait => 'Şarkın yazılıyor';

  @override
  String get storePreviewAChorus => 'Nakaratta onun adı';

  @override
  String get storePreviewAEnd => 'İçinde adı geçen bir şarkı';

  @override
  String get storePreviewBHook => 'Fotoğraflarınla başla';

  @override
  String get storePreviewBVideo => 'Sözlü video da ekle';

  @override
  String get storePreviewBWait => 'Şarkın yazılıyor';

  @override
  String get storePreviewBLyrics => 'Ekranda senkron sözler';

  @override
  String get storePreviewBMood => 'Fotoğraflar havayı belirler.';

  @override
  String get storePreviewBShare => 'Videoyu paylaş.';

  @override
  String get storePreviewBLanguage => 'Kendi dilinde sözler';

  @override
  String get storePreviewAShare => 'Kart olarak gönder';

  @override
  String get storePreviewCta => 'İlk şarkını yaz';

  @override
  String get storePreviewDisclosure => 'Abonelik veya kredi gerektirir';

  @override
  String get storeCreativeHeader => 'Sevdiklerin için şarkılar';

  @override
  String get storeCreativeSearch => 'Bir isimden şarkı yap';

  @override
  String get storeCreativeBirthday => 'Adıyla bir doğum günü şarkısı';

  @override
  String get storeCreativePhoto => 'Fotoğrafların şarkıya dönüşsün';

  @override
  String get storeCreativeWedding => 'Düğün gününüz için bir şarkı';
}
