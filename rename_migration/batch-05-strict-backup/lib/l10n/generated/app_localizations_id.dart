// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonCancel => 'Batal';

  @override
  String get startupLoading => 'Menyetel nada…';

  @override
  String get commonErrorTitle => 'Terjadi kesalahan';

  @override
  String get updateRequiredTitle => 'Pembaruan diperlukan';

  @override
  String get updateRequiredMessage =>
      'Versi baru diperlukan untuk melanjutkan.';

  @override
  String get updateNow => 'Perbarui sekarang';

  @override
  String get maintenanceTitle => 'Pemeliharaan terjadwal';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Diperkirakan kembali dalam sekitar $minutesString menit';
  }

  @override
  String get featureUnavailable => 'Fitur ini untuk sementara tidak tersedia.';

  @override
  String get navProfile => 'Profil';

  @override
  String get navStore => 'Toko';

  @override
  String get navUpload => 'Unggah';

  @override
  String get uploadTitle => 'Unggahan';

  @override
  String get uploadSubtitle =>
      'Unggah langsung ke R2 dengan URL presigned, hashing, deduplikasi instan, dan progres.';

  @override
  String get uploadPick => 'Pilih gambar & unggah';

  @override
  String get uploadAgain => 'Unggah lainnya';

  @override
  String get uploadPhaseHashing => 'Menghitung hash…';

  @override
  String get uploadPhaseSigning => 'Meminta tiket unggahan…';

  @override
  String uploadPhaseUploading(String percent) {
    return 'Mengunggah $percent';
  }

  @override
  String get uploadPhaseFinalizing => 'Menyelesaikan…';

  @override
  String get uploadDone => 'Terunggah.';

  @override
  String get uploadDedup => 'Instan: file ini sudah ada di server.';

  @override
  String get uploadOpenLink => 'Lihat file';

  @override
  String get uploadFailed => 'Gagal mengunggah.';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'File terlalu besar (maks. $limitString MB).';
  }

  @override
  String get uploadUnsupportedType => 'Jenis file tidak didukung.';

  @override
  String get profileGuestTitle => 'Tamu';

  @override
  String get profileGuestSubtitle =>
      'Masuk agar pembelianmu tetap tersimpan di semua perangkat.';

  @override
  String get signIn => 'Masuk';

  @override
  String get signOut => 'Keluar';

  @override
  String get profileBalanceLabel => 'Kredit';

  @override
  String get profileAccountId => 'ID Akun';

  @override
  String get profileFeaturesLabel => 'Manfaat aktif';

  @override
  String get profileNoFeatures => 'Belum ada manfaat aktif.';

  @override
  String get profileSubscriptionLabel => 'Langganan';

  @override
  String get profileManageSubscription => 'Kelola langganan';

  @override
  String get subscriptionActive => 'Aktif';

  @override
  String get subscriptionInactive => 'Tidak ada';

  @override
  String get profileDeleteAccount => 'Hapus akun';

  @override
  String get deleteAccountTitle => 'Hapus akun ini?';

  @override
  String get deleteAccountMessage =>
      'Tindakan ini tidak dapat dibatalkan: akun ini beserta kredit dan catatan manfaatnya tidak akan dapat diakses lagi selamanya, lalu akun baru akan dibuat. Langganan app store yang aktif tidak dibatalkan dengan menghapus akun — kelola di pengaturan app store-mu, atau tautkan kembali nanti dengan Pulihkan pembelian.';

  @override
  String get deleteAccountConfirm => 'Hapus';

  @override
  String get deleteAccountWorking => 'Menghapus akun…';

  @override
  String get deleteAccountDone => 'Akun dihapus.';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Anggota sejak $dateString';
  }

  @override
  String get loginTitle => 'Masuk';

  @override
  String get loginUsername => 'Nama pengguna';

  @override
  String get loginPassword => 'Kata sandi';

  @override
  String get loginSubmit => 'Masuk';

  @override
  String get paywallTitle => 'Dapatkan lagu lengkap';

  @override
  String get paywallSubtitle =>
      'Ubah pratinjaumu menjadi lagu 2 menit lengkap dengan lirik — milikmu untuk diunduh dan digunakan.';

  @override
  String get paywallRestore => 'Pulihkan pembelian';

  @override
  String get paywallAutoRenewNotice =>
      'Pembayaran ditagihkan ke Akun Apple-mu saat konfirmasi. Langganan diperpanjang secara otomatis dengan harga dan periode yang sama kecuali dibatalkan setidaknya 24 jam sebelum periode saat ini berakhir. Uji coba gratis akan berubah menjadi langganan berbayar setelah berakhir. Kelola atau batalkan kapan saja di pengaturan akun App Store-mu.';

  @override
  String get paywallContinue => 'Lanjutkan';

  @override
  String get paywallFreeTrial => 'Uji coba gratis';

  @override
  String get paywallOffer => 'Penawaran';

  @override
  String get paywallManage => 'Kelola';

  @override
  String get paywallTermsOfUse => 'Ketentuan Penggunaan';

  @override
  String get paywallPrivacyPolicy => 'Kebijakan Privasi';

  @override
  String get paywallSubscriptionTerms => 'Ketentuan Langganan';

  @override
  String get commonLinkError => 'Tidak dapat membuka tautan.';

  @override
  String get commonError => 'Terjadi kesalahan.';

  @override
  String get commonNetworkError =>
      'Kesalahan jaringan — periksa koneksimu dan coba lagi.';

  @override
  String get commonOfflineError =>
      'Sepertinya kamu sedang offline. Periksa koneksimu dan coba lagi.';

  @override
  String get networkErrorTitle => 'Masalah koneksi';

  @override
  String get configErrorTitle => 'Masalah konfigurasi app';

  @override
  String get configErrorMessage =>
      'Versi ini tidak dapat terhubung ke layanan kami. Perbarui app dari App Store, atau instal ulang. Jika masalah berlanjut, hubungi dukungan.';

  @override
  String get commonAuthError => 'Sesimu telah berakhir — silakan masuk lagi.';

  @override
  String get paywallProductsErrorTitle => 'Tidak dapat memuat produk';

  @override
  String get paywallNoProducts => 'Belum ada produk yang tersedia saat ini.';

  @override
  String get paywallPurchaseSuccess => 'Pembelian selesai — selamat menikmati!';

  @override
  String get paywallProcessing => 'Memproses pembelianmu…';

  @override
  String get paywallVerifying => 'Memverifikasi pembelianmu…';

  @override
  String get paywallPurchaseFailed => 'Pembelian tidak dapat diselesaikan.';

  @override
  String get paywallRestoreStarted => 'Memulihkan pembelianmu…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString pembelian dipulihkan.',
      one: '$countString pembelian dipulihkan.',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => 'Tidak ada pembelian untuk dipulihkan.';

  @override
  String get paywallDeferred =>
      'Menunggu persetujuan — kami akan menyelesaikannya setelah disetujui.';

  @override
  String get paywallAlreadySubscribed => 'Kamu sudah berlangganan.';

  @override
  String get paywallBillingRetry =>
      'Perbarui metode pembayaranmu agar langganan tetap aktif.';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Uji coba gratis $daysString hari';
  }

  @override
  String get cycleOneTime => 'sekali bayar';

  @override
  String get cycleWeekly => '/ minggu';

  @override
  String get cycleMonthly => '/ bulan';

  @override
  String get cycleQuarterly => '/ 3 bulan';

  @override
  String get cycleSemiAnnual => '/ 6 bulan';

  @override
  String get cycleAnnual => '/ tahun';

  @override
  String get cycleLifetime => 'seumur hidup';

  @override
  String get navCreate => 'Buat';

  @override
  String get navLibrary => 'Koleksi';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String get commonContinue => 'Lanjutkan';

  @override
  String get commonBack => 'Kembali';

  @override
  String get createTitle => 'Lagu ini untuk siapa?';

  @override
  String get occasionBirthday => 'Ulang Tahun';

  @override
  String get occasionBirthdayHint => 'Lagu ceria untuk hari istimewanya';

  @override
  String get occasionAnniversary => 'Hari Jadi';

  @override
  String get occasionAnniversaryHint => 'Rayakan kisah kalian berdua';

  @override
  String get occasionConfession => 'Ungkapan Cinta';

  @override
  String get occasionConfessionHint => 'Ungkapkan isi hatimu';

  @override
  String get occasionWedding => 'Pernikahan';

  @override
  String get occasionWeddingHint => 'Lagu untuk momen selamanya';

  @override
  String get occasionMemorial => 'Kenangan';

  @override
  String get occasionMemorialHint => 'Kenang seseorang yang kamu sayangi';

  @override
  String get occasionFestival => 'Hari Raya';

  @override
  String get occasionFestivalHint => 'Ucapan hangat untuk musim istimewa';

  @override
  String get occasionBrand => 'Jingle Brand';

  @override
  String get occasionBrandHint => 'Nada catchy untuk brand-mu';

  @override
  String get occasionSoundtrack => 'Soundtrack Video';

  @override
  String get occasionSoundtrackHint => 'Musik yang pas dengan ceritamu';

  @override
  String get festivalNewYear => 'Tahun Baru';

  @override
  String get festivalThanksgiving => 'Thanksgiving';

  @override
  String get festivalDiwali => 'Diwali';

  @override
  String get festivalCarnival => 'Karnaval';

  @override
  String get festivalEid => 'Lebaran';

  @override
  String get festivalLunarNewYear => 'Imlek';

  @override
  String get regionTitle => 'Di mana lagu ini akan didengar?';

  @override
  String get regionSearchHint => 'Cari negara';

  @override
  String get regionLanguageSheetTitle => 'Bahasa lirik';

  @override
  String get countryUS => 'Amerika Serikat';

  @override
  String get countryGB => 'Inggris';

  @override
  String get countryCA => 'Kanada';

  @override
  String get countryAU => 'Australia';

  @override
  String get countryDE => 'Jerman';

  @override
  String get countryFR => 'Prancis';

  @override
  String get countryJP => 'Jepang';

  @override
  String get countryKR => 'Korea Selatan';

  @override
  String get countryBR => 'Brasil';

  @override
  String get countryMX => 'Meksiko';

  @override
  String get countryIN => 'India';

  @override
  String get countryID => 'Indonesia';

  @override
  String get countryVN => 'Vietnam';

  @override
  String get countryTR => 'Turki';

  @override
  String get languageEn => 'Inggris';

  @override
  String get languageFr => 'Prancis';

  @override
  String get languageDe => 'Jerman';

  @override
  String get languageJa => 'Jepang';

  @override
  String get languageKo => 'Korea';

  @override
  String get languagePtBR => 'Portugis (Brasil)';

  @override
  String get languageEsMX => 'Spanyol (Meksiko)';

  @override
  String get languageHi => 'Hindi';

  @override
  String get languageId => 'Indonesia';

  @override
  String get languageVi => 'Vietnam';

  @override
  String get languageTr => 'Turki';

  @override
  String get languageZhHans => 'Tionghoa (Sederhana)';

  @override
  String get languageZhHant => 'Tionghoa (Tradisional)';

  @override
  String get inputNameLabel => 'Namanya';

  @override
  String get inputNameOptionalLabel => 'Nama (opsional)';

  @override
  String get inputNameHint => 'mis. Alex';

  @override
  String get inputKeywordsLabel => 'Tiga kata tentang dia';

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
      'Lirik ini milik saya atau saya berhak menggunakannya';

  @override
  String get issueRecipientMissing => 'Tambahkan namanya.';

  @override
  String get issueRecipientTooLong => 'Nama maksimal 24 karakter.';

  @override
  String get issueBriefMissing =>
      'Ceritakan tentang lagunya — beberapa kata, lirik, atau foto.';

  @override
  String get issueDescriptionMissing =>
      'Ide ini butuh kata-katamu — tulis satu kalimat tentang lagunya.';

  @override
  String get generatingBackToEdit => 'Kembali mengedit';

  @override
  String get issueKeywordTooLong => 'Setiap kata maksimal 20 karakter.';

  @override
  String get issueTooManyKeywords => 'Gunakan maksimal tiga kata.';

  @override
  String get issueArtistName =>
      'Nama artis tidak dapat digunakan — gambarkan perasaannya saja.';

  @override
  String get issueStyleImitation =>
      'Kami tidak bisa meniru penyanyi atau band. Gambarkan suasananya saja.';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Lirik maksimal $limitString karakter.';
  }

  @override
  String get issueLyricsNotOriginal =>
      'Lirik ini mirip lagu yang sudah ada. Silakan tulis lirikmu sendiri.';

  @override
  String get issueLyricsOwnership =>
      'Konfirmasikan bahwa kamu berhak menggunakan lirik ini.';

  @override
  String get issueTooManyPhotos => 'Pilih maksimal 10 foto.';

  @override
  String get photosTitle => 'Pilih beberapa foto';

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
      'Foto hanya digunakan sekali untuk menulis lagu dan dihapus dari server kami dalam 24 jam.';

  @override
  String get photosAdd => 'Tambahkan foto';

  @override
  String get photosCreate => 'Buat dari foto';

  @override
  String get photosEmpty => 'Pilih 1–10 foto momen tersebut.';

  @override
  String get generatingStepPolishing => 'Merapikan kata-katamu di iPhone ini…';

  @override
  String get generatingStepUploading => 'Mengirim fotomu…';

  @override
  String get generatingStepSubmitting => 'Mengirim ke studio…';

  @override
  String get errorSafetyBlocked =>
      'Kami tidak bisa membuat lagu ini — coba kata lain, dan jangan gunakan nama artis.';

  @override
  String get errorQuotaExhausted =>
      'Lagu bulan ini sudah terpakai semua. Tambah paket lagu atau upgrade.';

  @override
  String get errorUpstreamTimeout =>
      'Butuh waktu lebih lama dari biasanya. Kami akan terus mencoba dan memberi tahu kamu.';

  @override
  String get errorUpstreamRateLimited =>
      'Banyak lagu sedang dibuat saat ini. Lagumu sudah masuk antrean.';

  @override
  String get errorAttestFailed => 'Silakan perbarui Songlet dari App Store.';

  @override
  String get errorImageRejected =>
      'Salah satu foto ini tidak dapat digunakan. Coba foto lain.';

  @override
  String get errorNetworkOffline =>
      'Kamu sedang offline. Koleksimu tetap bisa diakses.';

  @override
  String get errorDownloadLocked =>
      'Lagu ini tidak dapat diunduh — pembelian yang digunakan untuk membuatnya telah dikembalikan dananya atau paketmu telah berakhir. Kamu masih bisa memutarnya.';

  @override
  String get errorJobAlreadyFinished =>
      'Sudah selesai — tidak ada yang perlu dibatalkan.';

  @override
  String get errorMvSongNotReady =>
      'Lagu ini belum siap untuk dijadikan video.';

  @override
  String get errorMvSongTooLong =>
      'Lagu ini terlalu panjang untuk video penuh — coba video reff.';

  @override
  String get errorMvSongExpired =>
      'Lagu ini sudah kedaluwarsa. Buat lagi untuk membuat video.';

  @override
  String get errorMvNotFound => 'Video ini sudah tidak tersedia.';

  @override
  String get errorMvPhotosExpired => 'Foto itu sudah kedaluwarsa — pilih lagi.';

  @override
  String get errorMvRenderFailed =>
      'Kami tidak bisa menyelesaikan video ini. Kreditmu sudah kembali — coba lagi.';

  @override
  String get mvHubTitle => 'Buat video';

  @override
  String mvHubSubtitle(String title) {
    return 'Ubah “$title” menjadi video musik.';
  }

  @override
  String get mvLevelLyricVideo => 'Video lirik';

  @override
  String get mvLevelLyricHint => 'Satu adegan diam dengan lirikmu';

  @override
  String get mvLevelChorus => 'Video reff';

  @override
  String get mvLevelChorusHint => '30 detik reff-mu, direkam AI';

  @override
  String get mvLevelFull => 'Video lagu penuh';

  @override
  String get mvLevelFullHint => 'Seluruh lagu, adegan demi adegan';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString kredit',
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
      other: 'Kamu punya $creditsString kredit',
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
      other: 'Kurang $creditsString lagi',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => 'Memeriksa harga…';

  @override
  String get mvOptionsHeader => 'Opsi';

  @override
  String get mvAspectLabel => 'Format';

  @override
  String get mvAspectPortrait => 'Potret';

  @override
  String get mvAspectLandscape => 'Lanskap';

  @override
  String get mvAspectSquare => 'Persegi';

  @override
  String get mvQualityLabel => 'Kualitas';

  @override
  String get mvQualityStandard => 'Standar';

  @override
  String get mvQualityHigh => 'Tinggi';

  @override
  String get mvSubtitlesLabel => 'Lirik di layar';

  @override
  String get mvPhotosLabel => 'Foto referensi';

  @override
  String get mvPhotosHint => 'Untuk suasana dan warna — wajah tidak digunakan';

  @override
  String mvPhotosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString foto',
    );
    return '$_temp0';
  }

  @override
  String get mvChorusLabel => 'Reff';

  @override
  String get mvChorusAuto => 'Ditemukan otomatis';

  @override
  String get mvChorusCustom => 'Pilih momen';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => 'Buat video';

  @override
  String get mvBuyPack => 'Dapatkan paket dan buat';

  @override
  String get mvSongLocked => 'Lagumu disimpan untuk video.';

  @override
  String get mvGeneratingTitle => 'Membuat videomu…';

  @override
  String get mvStageQueued => 'Menunggu mulai';

  @override
  String get mvStageSlicing => 'Memilih momen';

  @override
  String get mvStageStoryboarding => 'Menulis storyboard';

  @override
  String get mvStageKeyframing => 'Melukis adegan';

  @override
  String get mvStageRendering => 'Merekam adegan';

  @override
  String get mvStageAssembling => 'Menyunting';

  @override
  String get mvStageDone => 'Selesai';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Adegan $doneString dari $totalString';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Biasanya sekitar $minutesString menit';
  }

  @override
  String get mvCancelRequested => 'Berhenti setelah adegan ini…';

  @override
  String get mvCancelTitle => 'Hentikan video ini?';

  @override
  String get mvCancelQueued => 'Belum dimulai, jadi tidak ada yang terpakai.';

  @override
  String get mvCancelStarted =>
      'Sudah dimulai. Adegan yang selesai ditagih; sisanya dikembalikan.';

  @override
  String get mvCancelConfirm => 'Hentikan video';

  @override
  String get mvCancelled => 'Video dihentikan';

  @override
  String get mvCancelledRefunded =>
      'Video dihentikan — tidak ada yang terpakai';

  @override
  String get mvNothing => 'Tidak ada video yang sedang dibuat.';

  @override
  String get mvQuotaTitle => 'Kredit tidak cukup';

  @override
  String get mvAiLabelBurnedIn =>
      'Dibuat AI — lencana adalah bagian dari video';

  @override
  String get mvSave => 'Simpan ke Foto';

  @override
  String get mvSaveFiles => 'Simpan ke File';

  @override
  String get mvShareText => 'Aku membuat video musik ini dengan Songlet 🎬';

  @override
  String get mvMissing => 'Video ini sudah tidak ada di perangkat ini.';

  @override
  String get mvDeleteTitle => 'Hapus video ini?';

  @override
  String get mvDeleteBody => 'Dihapus dari perangkat ini.';

  @override
  String get mvDeleted => 'Video dihapus';

  @override
  String get mvProvenance =>
      'Dibuat dengan Google Lyria 3 dan model video AI · Dibuat AI';

  @override
  String get detailVideos => 'Video';

  @override
  String get detailMakeVideo => 'Buat video';

  @override
  String get mvStatusReady => 'Siap';

  @override
  String get mvStatusPending => 'Dibuat…';

  @override
  String get mvStatusFailed => 'Tidak selesai';

  @override
  String get mvPackTitle => 'Video musik';

  @override
  String get mvPackChorusSubtitle => 'Satu video reff';

  @override
  String get mvPackFullSubtitle => 'Satu video lagu penuh';

  @override
  String get paywallMvHeroTitle => 'Jadikan video';

  @override
  String get paywallMvHeroSubtitle =>
      'Kredit untuk video musik lagumu — simpan dan bagikan.';

  @override
  String get playerAiGenerated => 'Dibuat oleh AI';

  @override
  String get playerLoop => 'Ulangi';

  @override
  String get playerPlay => 'Putar';

  @override
  String get playerPause => 'Jeda';

  @override
  String get playerPreviewLabel => 'Pratinjau 30 detik';

  @override
  String playerTitleFor(String name) {
    return 'Untuk $name';
  }

  @override
  String get downloadSaved => 'Disimpan ke File.';

  @override
  String get shareComposing => 'Membuat kartu berbagimu…';

  @override
  String get shareFailed => 'Tidak dapat membuat kartu berbagi.';

  @override
  String get shareText => 'Aku membuat lagu ini dengan Songlet 🎵';

  @override
  String get paywallBestValue => 'Paling hemat';

  @override
  String get paywallStartTrial => 'Mulai uji coba gratis';

  @override
  String get paywallClose => 'Tutup';

  @override
  String get paywallSeePlans => 'Lihat langganan';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Paketmu aktif — sisa $countString lagu lengkap periode ini.',
      one: 'Paketmu aktif — sisa $countString lagu lengkap periode ini.',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => 'Lagu-lagumu akan tersimpan di sini.';

  @override
  String get libraryEmptyAction => 'Buat lagu pertamamu';

  @override
  String get libraryPending => 'Menggubah…';

  @override
  String get libraryPreviewBadge => 'Pratinjau';

  @override
  String get librarySongBadge => 'Lagu lengkap';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsPlan => 'Paketmu';

  @override
  String get settingsPlanUnavailable =>
      'Tidak dapat memuat paketmu. Tarik untuk mencoba lagi nanti.';

  @override
  String get tierFree => 'Tanpa langganan';

  @override
  String get tierPack => 'Paket lagu';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sisa $countString lagu lengkap',
      one: 'Sisa $countString lagu lengkap',
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
      other: 'Sisa $countString pratinjau',
      one: 'Sisa $countString pratinjau',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Direset $dateString';
  }

  @override
  String get settingsUpgrade => 'Upgrade';

  @override
  String get appTagline => 'Lagu untuk orang-orang yang kamu sayangi';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonDone => 'Selesai';

  @override
  String get commonDelete => 'Hapus';

  @override
  String get commonMore => 'Lainnya';

  @override
  String get commonCopy => 'Salin';

  @override
  String get commonCopied => 'Disalin';

  @override
  String get commonNotNow => 'Nanti saja';

  @override
  String get commonLearnMore => 'Pelajari lebih lanjut';

  @override
  String get commonSeeAll => 'Lihat semua';

  @override
  String get commonKeepGoing => 'Lanjutkan';

  @override
  String get composerHint => 'Jelaskan lagu yang kamu inginkan';

  @override
  String get composerAddPhotos => 'Tambah foto';

  @override
  String get composerSourceMusicHint => 'Jelaskan dengan kata-katamu sendiri';

  @override
  String get composerDictate => 'Dikte';

  @override
  String get composerStopDictation => 'Hentikan dikte';

  @override
  String get lengthPreview => 'Pratinjau';

  @override
  String get lengthFull => 'Lagu lengkap';

  @override
  String get paramLength => 'Durasi';

  @override
  String get paramVocals => 'Vokal';

  @override
  String get paramGenre => 'Genre';

  @override
  String templatePlaySample(String name) {
    return 'Putar contoh $name';
  }

  @override
  String get templatePauseSample => 'Jeda contoh';

  @override
  String get lengthShort => 'Pendek';

  @override
  String get lengthShortHint => 'Pratinjau 30 detik';

  @override
  String get lengthStandard => 'Standar';

  @override
  String get lengthStandardHint => 'sekitar 2 menit, Pro';

  @override
  String get vocalsCustom => 'Otomatis';

  @override
  String get vocalsCustomHint => 'sesuai deskripsimu';

  @override
  String get vocalsCustomDetail => 'Gaya vokal mengikuti deskripsimu.';

  @override
  String get vocalsOn => 'Dengan vokal';

  @override
  String get vocalsInstrumental => 'Instrumental';

  @override
  String vocalsLyricsIn(String language) {
    return 'Lirik ditulis dalam $language';
  }

  @override
  String get genreCustom => 'Otomatis';

  @override
  String get genreCustomHint => 'sesuai deskripsimu';

  @override
  String genrePopularIn(String country) {
    return 'Populer di $country';
  }

  @override
  String get genreAll => 'Semua genre';

  @override
  String get regionHelper => 'Mengubah 3 genre rekomendasi dan bahasa lirik';

  @override
  String regionLyricsRow(String language) {
    return 'Bahasa lirik: $language';
  }

  @override
  String get regionNoMatch => 'Tidak ada negara yang cocok';

  @override
  String get keywordAdd => 'Tambah kata';

  @override
  String keywordRemove(String word) {
    return 'Hapus $word';
  }

  @override
  String get nameClear => 'Hapus nama';

  @override
  String get lyricsOptional => 'Tulis lirik sendiri (opsional)';

  @override
  String get issueRecipientArtistName => 'Nama artis tidak boleh dipakai.';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Buat deskripsi kurang dari $limitString karakter.';
  }

  @override
  String get voiceRecording => 'Merekam…';

  @override
  String get voiceStarting => 'Memulai…';

  @override
  String get voiceListening =>
      'Sebutkan untuk siapa lagu ini dan apa yang dia suka…';

  @override
  String get voiceOnDevice => 'Transkripsi di perangkat';

  @override
  String get voicePermissionDenied =>
      'Izinkan mikrofon dan pengenalan suara untuk Songlet di Pengaturan agar bisa dikte.';

  @override
  String get voiceUnavailable =>
      'Dikte tidak tersedia untuk bahasa ini di perangkat ini.';

  @override
  String get voiceApplied => 'Ditambahkan dari suaramu';

  @override
  String get photoRemove => 'Hapus foto';

  @override
  String generatingTitleFor(String name) {
    return 'Menulis lagu untuk $name…';
  }

  @override
  String get generatingTitleGeneric => 'Menulis lagumu…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Biasanya sekitar $secondsString detik';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => 'Kemajuan';

  @override
  String get generatingGlimpse => 'Sekilas lagumu';

  @override
  String get generatingCancelTitle => 'Hentikan lagu ini?';

  @override
  String get generatingCancelQueued =>
      'Belum dimulai, jadi tidak mengurangi kuotamu.';

  @override
  String get generatingCancelStarted =>
      'Sudah dimulai, jadi tetap mengurangi kuotamu.';

  @override
  String get generatingCancelConfirm => 'Hentikan';

  @override
  String get generatingCancelled => 'Lagu dihentikan';

  @override
  String get generatingCancelledRefunded =>
      'Lagu dihentikan — kuota tidak terpakai';

  @override
  String get queueTitle => 'Banyak lagu sedang dibuat saat ini.';

  @override
  String get queueSubtitle => 'Lagumu sedang mengantre.';

  @override
  String get queuePosition => 'Posisi';

  @override
  String get queueWait => 'perkiraan tunggu';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '≈ $minutesString mnt';
  }

  @override
  String get generatingNothing => 'Tidak ada lagu yang sedang dibuat.';

  @override
  String get previewGetFull => 'Dapatkan lagu lengkap 2 menit';

  @override
  String get previewShare => 'Bagikan pratinjau';

  @override
  String get previewAnother => 'Coba versi lain (pakai 1 pratinjau)';

  @override
  String get playerPosition => 'Posisi putar';

  @override
  String get playerPrevSection => 'Bagian sebelumnya';

  @override
  String get playerNextSection => 'Bagian berikutnya';

  @override
  String get playerShuffle => 'Acak bagian';

  @override
  String get playerRepeat => 'Ulangi';

  @override
  String get playerProvenance =>
      'Dibuat dengan Google Lyria 3 · watermark SynthID · dibuat AI';

  @override
  String get playerMissing => 'Lagu ini sudah tidak ada di perangkat ini.';

  @override
  String get actionDownload => 'Unduh';

  @override
  String get actionShare => 'Bagikan';

  @override
  String get actionLicense => 'Lisensi';

  @override
  String get actionRegenerate => 'Buat ulang';

  @override
  String get actionDetails => 'Detail';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionVerse => 'Bait';

  @override
  String get sectionPreChorus => 'Pra-reff';

  @override
  String get sectionChorus => 'Reff';

  @override
  String get sectionBridge => 'Bridge';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionHook => 'Hook';

  @override
  String get shareTitle => 'Kartu bagikan';

  @override
  String get shareSubtitle => 'Pilih tema dan tata letak.';

  @override
  String get shareTheme => 'Tema';

  @override
  String get shareLayout => 'Tata letak';

  @override
  String get shareLayoutScene => 'Dengan ilustrasi';

  @override
  String get shareLayoutText => 'Teks saja';

  @override
  String get paletteTerracotta => 'Terakota';

  @override
  String get paletteSand => 'Pasir';

  @override
  String get paletteOlive => 'Zaitun';

  @override
  String get paletteNavy => 'Biru dongker';

  @override
  String get shareAction => 'Bagikan';

  @override
  String get shareSaveVideo => 'Simpan video';

  @override
  String get shareCopyLyrics => 'Salin lirik';

  @override
  String get shareVideoSaved => 'Tersimpan di Foto';

  @override
  String get shareLyricsCopied => 'Lirik disalin';

  @override
  String get shareCardTagline => 'Lagu untuk seseorang';

  @override
  String get shareSaveFailed =>
      'Video tidak bisa disimpan. Izinkan Songlet menambahkan ke Foto di Pengaturan.';

  @override
  String get downloadReady => 'Lagu lengkap siap';

  @override
  String get downloadTitle => 'Milikmu selamanya';

  @override
  String get downloadIntro =>
      'Lagumu sudah jadi. Unduh audio berkualitas tinggi dan lisensi komersialmu di bawah.';

  @override
  String get downloadAudioHeader => 'Unduh audio';

  @override
  String get downloadAudioNote => 'Kualitas tinggi';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle =>
      'Cocok untuk dibagikan dan didengarkan sehari-hari';

  @override
  String get downloadWavTitle => 'WAV · 44,1 kHz (Premier)';

  @override
  String get downloadWavSubtitle =>
      'Kualitas tertinggi untuk penggunaan profesional';

  @override
  String get downloadMp3Action => 'Unduh MP3';

  @override
  String get downloadWavAction => 'Unduh WAV';

  @override
  String get downloadLicenseAction => 'Unduh lisensi';

  @override
  String get licenseHeader => 'Lisensi komersial';

  @override
  String get licenseIncluded => 'Termasuk dalam paketmu';

  @override
  String get licenseNotIncluded =>
      'Tersedia dengan paket langganan atau paket lagu';

  @override
  String get licensePdfTitle => 'Lisensi komersial (PDF)';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Diterbitkan $dateString';
  }

  @override
  String licenseId(String id) {
    return 'ID lisensi: $id';
  }

  @override
  String get licenseUsesTitle => 'Kamu bisa memakai lagu ini untuk:';

  @override
  String get usePersonal => 'Penggunaan pribadi';

  @override
  String get usePersonalDetail => 'Hadiah, kenangan, nonkomersial';

  @override
  String get useAds => 'Iklan & pemasaran';

  @override
  String get useAdsDetail => 'Promosi, kampanye berbayar';

  @override
  String get useSocial => 'Media sosial';

  @override
  String get useSocialDetail => 'TikTok, Instagram, YouTube, dll.';

  @override
  String get usePodcasts => 'Podcast & video';

  @override
  String get usePodcastsDetail => 'Konten yang dimonetisasi';

  @override
  String get licenseDetailsNote => 'Detail lengkap ada di PDF lisensi.';

  @override
  String get saveEnjoyHeader => 'Simpan dan nikmati';

  @override
  String get saveToFiles => 'Simpan ke File';

  @override
  String get addToMusic => 'Tambahkan ke Musik';

  @override
  String get synthIdNote =>
      'Lagu ini berisi watermark SynthID yang menandainya sebagai konten buatan AI, bahkan setelah diunduh.';

  @override
  String get wavNeedsPremier => 'Unduhan WAV tersedia di Premier.';

  @override
  String get wavUnavailable =>
      'Lagu ini tidak punya file WAV. File WAV bisa disimpan dalam 24 jam setelah lagu dibuat.';

  @override
  String get libraryFilterAll => 'Semua';

  @override
  String get libraryJustBecause => 'Iseng saja';

  @override
  String libraryPlay(String title) {
    return 'Putar $title';
  }

  @override
  String libraryActions(String title) {
    return 'Tindakan untuk $title';
  }

  @override
  String get libraryDeleteTitle => 'Hapus lagu ini?';

  @override
  String get libraryDeleteBody =>
      'Lagu akan dihapus dari perangkat ini. Jika sinkron iCloud aktif, juga dari perangkatmu yang lain.';

  @override
  String get libraryDeleted => 'Lagu dihapus';

  @override
  String get libraryFailed => 'Tidak selesai';

  @override
  String get libraryNoMatch => 'Belum ada lagu untuk momen ini.';

  @override
  String get detailFullGenerated => 'Lagu lengkap dibuat';

  @override
  String get detailPreviewGenerated => 'Pratinjau dibuat';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Dibuat $dateString';
  }

  @override
  String get detailPromptUsed => 'Data yang dipakai';

  @override
  String get detailOccasion => 'Momen';

  @override
  String get detailCountry => 'Negara';

  @override
  String get detailGenre => 'Genre';

  @override
  String get detailKeywords => 'Kata kunci';

  @override
  String get detailDescription => 'Deskripsi';

  @override
  String get detailLyrics => 'Lirik';

  @override
  String get detailGenerationId => 'ID pembuatan';

  @override
  String get detailRegenerate => 'Buat ulang dengan gaya sama';

  @override
  String get detailCustomGenre => 'Sesuai deskripsi';

  @override
  String get settingsSectionPlan => 'Pembelian';

  @override
  String get settingsSectionLibrary => 'Pustaka';

  @override
  String get settingsSectionAbout => 'Tentang';

  @override
  String get settingsRestore => 'Pulihkan pembelian';

  @override
  String get settingsManage => 'Kelola langganan';

  @override
  String get settingsICloud => 'Sinkron iCloud';

  @override
  String get settingsICloudOn => 'Lagu disinkronkan di perangkatmu';

  @override
  String get settingsICloudOff => 'Lagu hanya disimpan di perangkat ini';

  @override
  String get settingsICloudUnavailable =>
      'Masuk ke iCloud di Pengaturan untuk sinkron';

  @override
  String get settingsLyricsLanguage => 'Bahasa lirik bawaan';

  @override
  String get settingsLyricsLanguageAuto => 'Sesuai negara';

  @override
  String get settingsTerms => 'Ketentuan Penggunaan';

  @override
  String get settingsPrivacy => 'Kebijakan Privasi';

  @override
  String settingsVersion(String version) {
    return 'Versi $version';
  }

  @override
  String get aboutTitle => 'Tentang pembuatan';

  @override
  String get aboutSubtitle => 'Cara Songlet membuat lagumu';

  @override
  String get aboutLyriaTitle => 'Didukung Lyria 3 dari Google';

  @override
  String get aboutLyriaBody =>
      'Lagu dibuat oleh Lyria 3 dari Google melalui Gemini API. Lyria 3 adalah model pembuat musik yang mengubah idemu menjadi lagu orisinal.';

  @override
  String get aboutWatermarkTitle => 'Watermark bawaan';

  @override
  String get aboutWatermarkBody =>
      'Setiap lagu berisi watermark SynthID dari Google. Watermark ini membantu mengenali musik buatan AI dan tidak bisa dihapus.';

  @override
  String get aboutImitationTitle => 'Tidak meniru artis sungguhan';

  @override
  String get aboutImitationBody =>
      'Songlet tidak pernah meniru artis sungguhan, suara mereka, atau gaya tertentu. Lagu bersifat orisinal dan dibuat dari ide, deskripsi, dan fotomu.';

  @override
  String get aboutPrivacyTitle => 'Privasimu penting';

  @override
  String get aboutPrivacyBody =>
      'Foto dan deskripsi dihapus dari server kami dalam 24 jam. Kami tidak menyimpan gambar atau deskripsimu setelah lagu dibuat.';

  @override
  String get aboutBanner =>
      'Setiap lagu yang kamu bagikan diberi label buatan AI.';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · Dibuat dengan Google Lyria 3';
  }

  @override
  String get festivalKicker => 'Hidupkan ceritamu';

  @override
  String get festivalComing => 'segera tiba!';

  @override
  String get festivalBody => 'Buat lagu unik untuk merayakannya.';

  @override
  String festivalCta(String festival) {
    return 'Buat lagu $festival';
  }

  @override
  String get festivalPickOccasion => 'Pilih momen dan mulai berkarya';

  @override
  String get festivalLanguagesTitle => 'Lagu dalam bahasamu';

  @override
  String festivalLanguagesBody(String language) {
    return 'Buat lagu dalam $language dan 12 bahasa lainnya';
  }

  @override
  String get unavailableTitle => 'Sementara tidak tersedia';

  @override
  String get unavailableMessage =>
      'Songlet belum bisa membuat lagu sekarang. Pustakamu tetap bisa dipakai — coba lagi sebentar lagi.';

  @override
  String get paywallHeroTitle => 'Jadikan lagu lengkap';

  @override
  String get paywallHeroSubtitle =>
      'Ubah idemu jadi lagu lengkap dengan kualitas lebih tinggi dan hak penuh.';

  @override
  String get paywallBenefitSongs => 'Lebih banyak lagu';

  @override
  String get paywallBenefitQuality => 'Kualitas lebih tinggi';

  @override
  String get paywallBenefitCommercial => 'Penggunaan komersial';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString lagu lengkap per bulan',
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
      other: '$countString pratinjau per bulan',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'Unduh MP3';

  @override
  String get planMp3Wav => 'Unduh MP3 + WAV';

  @override
  String get planLicense => 'Lisensi komersial';

  @override
  String get planPriority => 'Pembuatan prioritas';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Uji coba gratis $daysString hari';
  }

  @override
  String planPerYear(String price) {
    return '$price/thn';
  }

  @override
  String planPerMonth(String price) {
    return '$price/bln';
  }

  @override
  String get packTitle => 'Hanya butuh beberapa?';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Paket $countString lagu',
    );
    return '$_temp0';
  }

  @override
  String get packNote => 'tidak kedaluwarsa';

  @override
  String get valueForever => 'Lagumu, selamanya';

  @override
  String get valueDownloads => 'Unduhan berkualitas tinggi';

  @override
  String get valueCommercial => 'Boleh dipakai komersial';

  @override
  String get valuePrivate => 'Privasi nomor satu';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return 'Setelah uji coba gratis, $pricePerPeriod ditagih otomatis. Batalkan kapan saja sebelum uji coba berakhir.';
  }

  @override
  String get paywallSubscribe => 'Berlangganan';

  @override
  String get paywallBuyPack => 'Beli paket';

  @override
  String get templateBirthdayWish => 'Ucapan Ulang Tahun';

  @override
  String get templateBirthdayWishHint => 'Lagu spesial untuk hari spesialnya';

  @override
  String get templateBirthdayParty => 'Pesta Ulang Tahun';

  @override
  String get templateBirthdayPartyHint =>
      'Meriahkan pesta sang bintang ulang tahun';

  @override
  String get templateLoveStory => 'Kisah Cinta';

  @override
  String get templateLoveStoryHint => 'Kisah kalian dalam sebuah lagu';

  @override
  String get templateThankAFriend => 'Terima Kasih, Teman';

  @override
  String get templateThankAFriendHint =>
      'Ucapkan terima kasih yang tak terucap';

  @override
  String get templatePartyInvite => 'Undangan Pesta';

  @override
  String get templatePartyInviteHint => 'Ajak semua orang ke pesta';

  @override
  String get templateWedding => 'Pernikahan';

  @override
  String get templateWeddingHint => 'Lagu untuk momen abadi mereka';

  @override
  String get templateInMemory => 'Mengenang';

  @override
  String get templateInMemoryHint => 'Hormati orang yang kamu sayangi';

  @override
  String get templateFestival => 'Hari Raya';

  @override
  String get templateFestivalHint => 'Ucapan hangat untuk musim istimewa';

  @override
  String get templateRingtone => 'Nada Dering';

  @override
  String get templateRingtoneHint => 'Loop pendek khusus untukmu';

  @override
  String get templateTeamAnthem => 'Lagu Tim';

  @override
  String get templateTeamAnthemHint => 'Bakar semangat tim dan penonton';

  @override
  String get templateSportsRecap => 'Rangkuman Laga';

  @override
  String get templateSportsRecapHint => 'Pertandingan besar dalam sebuah lagu';

  @override
  String get templateRapBattle => 'Adu Rap';

  @override
  String get templateRapBattleHint => 'Bait bersahabat untuk rival bersahabat';

  @override
  String get templateComedy => 'Komedi';

  @override
  String get templateComedyHint => 'Lelucon internal, kini dengan reff';

  @override
  String get templatePetAnthem => 'Lagu Hewan Peliharaan';

  @override
  String get templatePetAnthemHint => 'Lagu tema untuk sahabat terbaikmu';

  @override
  String get templateHometown => 'Kampung Halaman';

  @override
  String get templateHometownHint => 'Cinta untuk tempat yang kamu sebut rumah';

  @override
  String get templateBusinessPromo => 'Promo Usaha';

  @override
  String get templateBusinessPromoHint =>
      'Jingle yang nempel untuk toko atau merekmu';

  @override
  String get templateCustom => 'Idemu sendiri';

  @override
  String get mvRecommended => 'Disarankan';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString dtk';
  }

  @override
  String get mvViewProgress => 'Lihat progres';

  @override
  String mvIntentWaiting(String level) {
    return '$level menunggu kredit';
  }

  @override
  String get mvSongExpiredAction => 'Buat lagunya lagi';

  @override
  String mvQuotaNeed(String level, int required, int available) {
    final intl.NumberFormat requiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requiredString = requiredNumberFormat.format(required);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return '$level butuh $requiredString kredit. Kamu punya $availableString.';
  }

  @override
  String get mvQuotaBuyAndContinue => 'Beli dan lanjutkan';

  @override
  String get mvQuotaMayNeedTwice =>
      'Di wilayahmu, satu paket mungkin belum cukup — mungkin perlu dua.';

  @override
  String get mvQuotaAutoRetry => 'Videomu mulai begitu pembelian berhasil.';

  @override
  String get mvAutoLyricMaking => 'Membuat video lirikmu';

  @override
  String get mvAutoChorusDetail => 'Dibuat dari lagu ini dengan kreditmu';

  @override
  String mvAutoReady(String level) {
    return '$level sudah siap';
  }

  @override
  String get mvAutoView => 'Lihat';

  @override
  String get mvUpgradeChorus => 'Buat video reff';

  @override
  String get mvAutoFailed => 'Video tidak bisa dimulai';

  @override
  String get mvLeaveHint =>
      'Kamu boleh meninggalkan layar ini — kami kabari saat seharusnya sudah siap.';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString kreditmu sudah kembali.',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => 'Video ini tidak selesai';

  @override
  String get mvRejectedTitle => 'Satu foto tidak bisa dipakai';

  @override
  String get mvRejectedBody =>
      'Model video menolak salah satu foto referensimu. Ubah fotonya lalu coba lagi.';

  @override
  String get mvAdjustPhotos => 'Ubah foto dan coba lagi';

  @override
  String get mvTryChorus => 'Buat video reff saja';

  @override
  String get mvPreparingPhotos => 'Mengunggah fotomu…';

  @override
  String get mvPreparingSubmit => 'Mengirim videomu…';

  @override
  String get mvNotifyTitle => 'Videomu seharusnya sudah siap';

  @override
  String mvNotifyBody(String level) {
    return '$level — ketuk untuk menonton.';
  }

  @override
  String get mvRegenerate => 'Buat lagi';

  @override
  String get mvEntryTitle => 'Jadikan video';

  @override
  String get mvEntrySubtitle =>
      'Video lirik, reff, dan lagu penuh, dengan kredit';

  @override
  String get mvEntryDisabled => 'Tersedia setelah lagu selesai';

  @override
  String get mvEntryChoose => 'Pilih video';

  @override
  String get mvEntryWatch => 'Tonton video';

  @override
  String get mvChipReady => 'Video';

  @override
  String get mvChipMaking => 'Membuat video';

  @override
  String get lengthAutoVideo => 'Buat juga video lirik';

  @override
  String get lengthAutoVideoHint =>
      'Siap beberapa menit setelah lagu · memakai kredit';

  @override
  String get lengthSongAndChorus => 'Lagu + video reff';

  @override
  String get lengthSongAndChorusHint => 'Lagu penuh, lalu video reff 30 detik';

  @override
  String get paywallVideoGroup => 'Video musik';

  @override
  String get planVideoIncluded => 'Kuotamu juga bisa untuk video musik';

  @override
  String get settingsVideoCredits => 'Kredit video';

  @override
  String get createGenrePop => 'Pop';

  @override
  String get createGenreHipHopRap => 'Hip-hop & rap';

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
  String get createGenreJazzBlues => 'Jazz & blues';

  @override
  String get createGenreClassical => 'Klasik';

  @override
  String get createGenreFolk => 'Folk';

  @override
  String get createGenreLofi => 'Lo-fi';

  @override
  String get createGenreAcoustic => 'Akustik';

  @override
  String get createGenreCinematic => 'Musik film';

  @override
  String get createGenreAmbient => 'Ambient';

  @override
  String get createGenreBossaNova => 'Bossa nova';

  @override
  String get createGenreIndiePop => 'Pop indie';

  @override
  String get createGenreContemporaryRnb => 'R&B modern';

  @override
  String get createGenreAlternativeCountry => 'Country alternatif';

  @override
  String get createGenreGarageRock => 'Garage rock';

  @override
  String get createGenreGrime => 'Grime';

  @override
  String get createGenreIndieFolk => 'Folk indie';

  @override
  String get createGenreSynthpop => 'Synthpop';

  @override
  String get createGenrePianoBallad => 'Balada piano';

  @override
  String get createGenreSurfRock => 'Surf rock';

  @override
  String get createGenreDeepHouse => 'Deep house';

  @override
  String get createGenreMinimalTechno => 'Techno minimal';

  @override
  String get createGenreFrenchYeyePop => 'Pop yé-yé Prancis 60-an';

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
  String get createGenreLatinJazz => 'Jazz Latin';

  @override
  String get createGenreBhangra => 'Bhangra';

  @override
  String get createGenreIndianClassical => 'Klasik India';

  @override
  String get createGenreLofiHipHop => 'Hip-hop lo-fi';

  @override
  String profileAccountIdWithValue(String id) {
    return 'ID Akun: $id';
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
  String get createVocalsCustomSummary => 'Otomatis — sesuai deskripsimu';

  @override
  String mvChipMakingWithProgress(String progress) {
    return 'Membuat video · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return 'Video tidak bisa dimulai · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    return 'Kredit video: $creditsString';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => 'Inspirasi';

  @override
  String inspirationPlay(String name) {
    return 'Putar $name';
  }

  @override
  String get inspirationStop => 'Hentikan contoh';

  @override
  String get inspirationNameSoundscape => 'Lanskap Suara';

  @override
  String get inspirationStyleSoundscape => 'Tekstur ambient, tanpa vokal';

  @override
  String get inspirationNameBackgroundMusic => 'Musik Latar';

  @override
  String get inspirationStyleBackgroundMusic =>
      'Instrumental ringan untuk video';

  @override
  String get inspirationNameMemorizeSomething => 'Hafalkan Sesuatu';

  @override
  String get inspirationStyleMemorizeSomething =>
      'Pop mudah diingat untuk menghafal';

  @override
  String get inspirationNameTextMessages => 'Pesan Jadi Lagu';

  @override
  String get inspirationStyleTextMessages => 'Pop jenaka dari pesanmu';

  @override
  String get inspirationNameIntroMusic => 'Musik Pembuka';

  @override
  String get inspirationStyleIntroMusic => 'Pembuka sinematik yang megah';

  @override
  String get inspirationNameMontage => 'Montase';

  @override
  String get inspirationStyleMontage =>
      'Musik naik semangat untuk cuplikan terbaik';

  @override
  String get inspirationNameSayItWithATrack => 'Katakan Lewat Lagu';

  @override
  String get inspirationStyleSayItWithATrack => 'Balada pop penuh perasaan';

  @override
  String get inspirationNameBrandJingle => 'Jingle Merek';

  @override
  String get inspirationStyleBrandJingle =>
      'Hook singkat, cerah, mudah diingat';

  @override
  String get inspirationNameRingtone => 'Nada Dering';

  @override
  String get inspirationStyleRingtone => 'Hook 30 detik yang bisa diulang';

  @override
  String get inspirationNameStreaming => 'Streaming';

  @override
  String get inspirationStyleStreaming =>
      'Intro streaming elektronik yang enerjik';

  @override
  String get inspirationNameSpeechToTrack => 'Suara Jadi Lagu';

  @override
  String get inspirationStyleSpeechToTrack => 'Suaramu jadi lagu';

  @override
  String get inspirationNameRapBattle => 'Adu Rap';

  @override
  String get inspirationStyleRapBattle => 'Hip-hop keras';

  @override
  String get inspirationNameComedy => 'Komedi';

  @override
  String get inspirationStyleComedy => 'Unik, ceria, penuh canda';

  @override
  String get inspirationNameTeamAnthem => 'Lagu Tim';

  @override
  String get inspirationStyleTeamAnthem => 'Nyanyian rock stadion';

  @override
  String get inspirationNameSportsRecap => 'Rangkuman Laga';

  @override
  String get inspirationStyleSportsRecap => 'Sorotan orkestra epik';

  @override
  String get inspirationNamePartyInvite => 'Undangan Pesta';

  @override
  String get inspirationStylePartyInvite => 'Undangan dance-pop';

  @override
  String get inspirationNameHappyBirthday => 'Selamat Ulang Tahun';

  @override
  String get inspirationStyleHappyBirthday =>
      'Lagu ulang tahun akustik yang hangat';

  @override
  String get inspirationNameFriendAppreciation => 'Terima Kasih, Sahabat';

  @override
  String get inspirationStyleFriendAppreciation =>
      'Indie pop yang bikin senang';

  @override
  String get inspirationNameLoveStory => 'Kisah Cinta';

  @override
  String get inspirationStyleLoveStory => 'Balada R&B romantis';

  @override
  String get inspirationNameBirthdayRoast => 'Ulang Tahun Kocak';

  @override
  String get inspirationStyleBirthdayRoast => 'Lagu ulang tahun jenaka';

  @override
  String get inspirationNameOdeToYourPet => 'Pujian untuk Hewanmu';

  @override
  String get inspirationStyleOdeToYourPet => 'Pop lucu dan riang';

  @override
  String get inspirationNameHometownTribute => 'Tribut Kampung Halaman';

  @override
  String get inspirationStyleHometownTribute => 'Folk nostalgia';

  @override
  String get inspirationNameWeatherReport => 'Laporan Cuaca';

  @override
  String get inspirationStyleWeatherReport => 'Groove lounge yang santai';

  @override
  String get inspirationNameBusinessPromo => 'Promo Usaha';

  @override
  String get inspirationStyleBusinessPromo => 'Pop korporat yang percaya diri';

  @override
  String get inspirationStyleBirthdayWish =>
      'Lagu tulus untuk hari spesial mereka';

  @override
  String get inspirationStyleBirthdayParty =>
      'Lagu pesta ceria untuk yang berulang tahun';

  @override
  String get inspirationStyleThankAFriend =>
      'Lagu terima kasih yang hangat dan tulus';

  @override
  String get inspirationStyleWedding =>
      'Lagu ceria dan romantis untuk hari bahagia';

  @override
  String get inspirationStyleInMemory => 'Penghormatan lembut penuh harapan';

  @override
  String get inspirationStyleFestival => 'Ucapan musiman yang cerah dan meriah';

  @override
  String get inspirationStylePetAnthem =>
      'Lagu tema penuh kasih untuk hewan peliharaan';

  @override
  String get inspirationStyleHometown =>
      'Lagu kampung halaman yang bangga dan nostalgia';

  @override
  String get settingsSectionLanguage => 'Bahasa';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsCredits => 'Kredit';

  @override
  String get settingsAccountId => 'ID akun';

  @override
  String get settingsCopyAccountId => 'Salin ID akun';

  @override
  String get devSectionTitle => 'Pengembang (khusus DEV)';

  @override
  String get devKeychainReset => 'Hapus kunci Keychain';

  @override
  String get devKeychainResetHint => 'ID perangkat dan token sesi';

  @override
  String get devKeychainResetConfirmTitle => 'Hapus kunci Keychain?';

  @override
  String get devKeychainResetConfirmBody =>
      'ID perangkat dan token sesi dihapus dari Keychain. Akun tamu saat ini tidak dapat dipulihkan; aplikasi masuk sebagai tamu baru.';

  @override
  String get devKeychainResetDone =>
      'Kunci Keychain dihapus — masuk sebagai tamu baru';

  @override
  String get settingsAppLanguage => 'Bahasa aplikasi';

  @override
  String get settingsLanguageSystem => 'Ikuti bahasa sistem';

  @override
  String settingsLanguageSystemValue(String language) {
    return 'Sistem ($language)';
  }

  @override
  String get settingsLanguageNativeName => 'Bahasa Indonesia';

  @override
  String get settingsLanguageSaveFailed => 'Bahasa gagal disimpan. Coba lagi.';

  @override
  String get settingsLyricsLanguageHint => 'Berlaku untuk lagu baru.';

  @override
  String composerRemoveInspiration(String name) {
    return 'Hapus $name';
  }

  @override
  String get composerPromptHint => 'Jelaskan lagunya, atau pilih ide di atas';

  @override
  String get composerPromptHintWide => 'Jelaskan lagunya, atau pilih ide';

  @override
  String get composerWordsLabel => 'Kata-katamu';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString foto ditambahkan',
      one: '$countString foto ditambahkan',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return 'Opsi lagu: $summary';
  }

  @override
  String get composerOptionsShow => 'Tampilkan opsi';

  @override
  String get composerOptionsHide => 'Sembunyikan opsi';

  @override
  String get composerSummaryAnyVocals => 'Vokal bebas';

  @override
  String get composerSummaryAnyGenre => 'Genre bebas';

  @override
  String get composerSummaryLyrics => 'Lirik sendiri';

  @override
  String get composerSummaryVideo => 'Video lirik';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Buat pratinjau · gratis',
      'preview': 'Buat pratinjau · 1 pratinjau',
      'other': 'Buat pratinjau',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Buat pratinjau untuk $name · gratis',
      'preview': 'Buat pratinjau untuk $name · 1 pratinjau',
      'other': 'Buat pratinjau untuk $name',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': 'Buat lagu lengkap · 1 lagu',
      'other': 'Buat lagu lengkap',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => 'Gunakan teks ini';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level dimulai dalam $seconds dtk';
  }

  @override
  String planPerWeek(String price) {
    return '$price/minggu';
  }

  @override
  String get planCreditsWeekly => 'Kredit baru setiap minggu';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'hari pertama',
      'week': 'minggu pertama',
      'month': 'bulan pertama',
      'year': 'tahun pertama',
      'other': 'periode pertama',
    });
    return 'Diskon $percent% untuk $_temp0';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return 'Setelah harga perkenalan $introPrice, Anda akan ditagih $pricePerPeriod secara otomatis. Batalkan kapan saja sebelum perpanjangan.';
  }

  @override
  String get storePreviewAHook => 'Mulai dari namanya';

  @override
  String get storePreviewAWords => 'Tiga kata tentang dia';

  @override
  String get storePreviewAWait => 'Lagumu sedang dibuat';

  @override
  String get storePreviewAChorus => 'Namanya di reff';

  @override
  String get storePreviewAEnd => 'Lagu dengan namanya';

  @override
  String get storePreviewBHook => 'Mulai dari fotomu';

  @override
  String get storePreviewBVideo => 'Tambah video lirik';

  @override
  String get storePreviewBWait => 'Membuat lagumu';

  @override
  String get storePreviewBLyrics => 'Lirik sinkron di layar';

  @override
  String get storePreviewBMood => 'Fotomu menentukan suasana.';

  @override
  String get storePreviewBShare => 'Bagikan videonya.';

  @override
  String get storePreviewBLanguage => 'Lirik dalam bahasamu';

  @override
  String get storePreviewAShare => 'Kirim sebagai kartu';

  @override
  String get storePreviewCta => 'Buat lagu pertamamu';

  @override
  String get storePreviewDisclosure => 'Memerlukan langganan atau kredit';

  @override
  String get storeCreativeHeader => 'Lagu untuk orang yang kamu sayangi';

  @override
  String get storeCreativeSearch => 'Ubah nama jadi lagu';

  @override
  String get storeCreativeBirthday => 'Lagu ulang tahun dengan namanya';

  @override
  String get storeCreativePhoto => 'Fotomu jadi lagu';

  @override
  String get storeCreativeWedding => 'Lagu untuk hari pernikahanmu';
}
