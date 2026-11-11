// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get startupLoading => 'Đang lên dây…';

  @override
  String get commonErrorTitle => 'Đã xảy ra lỗi';

  @override
  String get updateRequiredTitle => 'Cần cập nhật';

  @override
  String get updateRequiredMessage => 'Bạn cần phiên bản mới để tiếp tục.';

  @override
  String get updateNow => 'Cập nhật ngay';

  @override
  String get maintenanceTitle => 'Bảo trì theo lịch';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Dự kiến hoạt động lại sau khoảng $minutesString phút';
  }

  @override
  String get featureUnavailable => 'Tính năng này tạm thời không khả dụng.';

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get navStore => 'Cửa hàng';

  @override
  String get navUpload => 'Tải lên';

  @override
  String get uploadTitle => 'Tải lên';

  @override
  String get uploadSubtitle =>
      'Tải trực tiếp lên R2 bằng URL ký sẵn, kèm băm tệp, loại trùng tức thì và tiến trình.';

  @override
  String get uploadPick => 'Chọn ảnh & tải lên';

  @override
  String get uploadAgain => 'Tải lên tệp khác';

  @override
  String get uploadPhaseHashing => 'Đang băm tệp…';

  @override
  String get uploadPhaseSigning => 'Đang yêu cầu vé tải lên…';

  @override
  String uploadPhaseUploading(String percent) {
    return 'Đang tải lên $percent';
  }

  @override
  String get uploadPhaseFinalizing => 'Đang hoàn tất…';

  @override
  String get uploadDone => 'Đã tải lên.';

  @override
  String get uploadDedup => 'Tức thì: tệp này đã có sẵn trên máy chủ.';

  @override
  String get uploadOpenLink => 'Xem tệp';

  @override
  String get uploadFailed => 'Tải lên không thành công.';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Tệp quá lớn (tối đa $limitString MB).';
  }

  @override
  String get uploadUnsupportedType => 'Loại tệp không được hỗ trợ.';

  @override
  String get profileGuestTitle => 'Khách';

  @override
  String get profileGuestSubtitle =>
      'Đăng nhập để giữ các giao dịch mua trên mọi thiết bị.';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get profileBalanceLabel => 'Tín dụng';

  @override
  String get profileAccountId => 'ID tài khoản';

  @override
  String get profileFeaturesLabel => 'Quyền lợi đang có';

  @override
  String get profileNoFeatures => 'Chưa có quyền lợi nào.';

  @override
  String get profileSubscriptionLabel => 'Gói đăng ký';

  @override
  String get profileManageSubscription => 'Quản lý gói đăng ký';

  @override
  String get subscriptionActive => 'Đang hoạt động';

  @override
  String get subscriptionInactive => 'Không có';

  @override
  String get profileDeleteAccount => 'Xóa tài khoản';

  @override
  String get deleteAccountTitle => 'Xóa tài khoản này?';

  @override
  String get deleteAccountMessage =>
      'Không thể hoàn tác thao tác này: tài khoản này cùng tín dụng và hồ sơ quyền lợi của nó sẽ vĩnh viễn không thể truy cập được, và một tài khoản mới sẽ được tạo. Việc xóa tài khoản không hủy gói đăng ký app store đang hoạt động — hãy quản lý gói trong cài đặt app store của bạn, hoặc liên kết lại sau bằng Khôi phục giao dịch mua.';

  @override
  String get deleteAccountConfirm => 'Xóa';

  @override
  String get deleteAccountWorking => 'Đang xóa tài khoản…';

  @override
  String get deleteAccountDone => 'Đã xóa tài khoản.';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Thành viên từ $dateString';
  }

  @override
  String get loginTitle => 'Đăng nhập';

  @override
  String get loginUsername => 'Tên người dùng';

  @override
  String get loginPassword => 'Mật khẩu';

  @override
  String get loginSubmit => 'Đăng nhập';

  @override
  String get paywallTitle => 'Nhận bài hát đầy đủ';

  @override
  String get paywallSubtitle =>
      'Biến bản nghe thử thành bài hát 2 phút có lời — của riêng bạn để tải xuống và sử dụng.';

  @override
  String get paywallRestore => 'Khôi phục giao dịch mua';

  @override
  String get paywallAutoRenewNotice =>
      'Khoản thanh toán sẽ được tính vào Tài khoản Apple của bạn khi xác nhận. Gói đăng ký tự động gia hạn với cùng mức giá và thời hạn trừ khi được hủy ít nhất 24 giờ trước khi kết thúc kỳ hiện tại. Bản dùng thử miễn phí sẽ chuyển thành gói đăng ký trả phí khi kết thúc. Quản lý hoặc hủy bất cứ lúc nào trong cài đặt tài khoản App Store của bạn.';

  @override
  String get paywallContinue => 'Tiếp tục';

  @override
  String get paywallFreeTrial => 'Dùng thử miễn phí';

  @override
  String get paywallOffer => 'Ưu đãi';

  @override
  String get paywallManage => 'Quản lý';

  @override
  String get paywallTermsOfUse => 'Điều khoản sử dụng';

  @override
  String get paywallPrivacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get paywallSubscriptionTerms => 'Điều khoản gói đăng ký';

  @override
  String get commonLinkError => 'Không thể mở liên kết.';

  @override
  String get commonError => 'Đã xảy ra lỗi.';

  @override
  String get commonNetworkError =>
      'Lỗi mạng — hãy kiểm tra kết nối và thử lại.';

  @override
  String get commonOfflineError =>
      'Có vẻ bạn đang ngoại tuyến. Hãy kiểm tra kết nối và thử lại.';

  @override
  String get networkErrorTitle => 'Sự cố kết nối';

  @override
  String get configErrorTitle => 'Sự cố cấu hình ứng dụng';

  @override
  String get configErrorMessage =>
      'Phiên bản này không thể kết nối với dịch vụ của chúng tôi. Hãy cập nhật ứng dụng từ App Store hoặc cài đặt lại. Nếu sự cố vẫn tiếp diễn, hãy liên hệ bộ phận hỗ trợ.';

  @override
  String get commonAuthError =>
      'Phiên đăng nhập đã hết hạn — vui lòng đăng nhập lại.';

  @override
  String get paywallProductsErrorTitle => 'Không thể tải sản phẩm';

  @override
  String get paywallNoProducts => 'Hiện chưa có sản phẩm nào.';

  @override
  String get paywallPurchaseSuccess => 'Mua thành công — chúc bạn vui vẻ!';

  @override
  String get paywallProcessing => 'Đang xử lý giao dịch mua…';

  @override
  String get paywallVerifying => 'Đang xác minh giao dịch mua…';

  @override
  String get paywallPurchaseFailed => 'Không thể hoàn tất giao dịch mua.';

  @override
  String get paywallRestoreStarted => 'Đang khôi phục giao dịch mua…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã khôi phục $countString giao dịch mua.',
      one: 'Đã khôi phục $countString giao dịch mua.',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing =>
      'Không có giao dịch mua nào để khôi phục.';

  @override
  String get paywallDeferred =>
      'Đang chờ phê duyệt — chúng tôi sẽ hoàn tất ngay khi được duyệt.';

  @override
  String get paywallAlreadySubscribed => 'Bạn đã đăng ký rồi.';

  @override
  String get paywallBillingRetry =>
      'Hãy cập nhật phương thức thanh toán để duy trì gói đăng ký.';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Dùng thử miễn phí $daysString ngày';
  }

  @override
  String get cycleOneTime => 'một lần';

  @override
  String get cycleWeekly => '/ tuần';

  @override
  String get cycleMonthly => '/ tháng';

  @override
  String get cycleQuarterly => '/ quý';

  @override
  String get cycleSemiAnnual => '/ 6 tháng';

  @override
  String get cycleAnnual => '/ năm';

  @override
  String get cycleLifetime => 'trọn đời';

  @override
  String get navCreate => 'Tạo';

  @override
  String get navLibrary => 'Thư viện';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get commonContinue => 'Tiếp tục';

  @override
  String get commonBack => 'Quay lại';

  @override
  String get createTitle => 'Bài hát này dành cho ai?';

  @override
  String get occasionBirthday => 'Sinh nhật';

  @override
  String get occasionBirthdayHint => 'Một bài hát vui tươi cho ngày đặc biệt';

  @override
  String get occasionAnniversary => 'Kỷ niệm';

  @override
  String get occasionAnniversaryHint => 'Mừng câu chuyện của hai bạn';

  @override
  String get occasionConfession => 'Tỏ tình';

  @override
  String get occasionConfessionHint => 'Nói lên điều con tim mách bảo';

  @override
  String get occasionWedding => 'Đám cưới';

  @override
  String get occasionWeddingHint => 'Bài hát cho khoảnh khắc trọn đời';

  @override
  String get occasionMemorial => 'Tưởng nhớ';

  @override
  String get occasionMemorialHint => 'Tưởng nhớ một người bạn trân quý';

  @override
  String get occasionFestival => 'Lễ hội';

  @override
  String get occasionFestivalHint => 'Lời chúc ấm áp cho mùa đặc biệt';

  @override
  String get occasionBrand => 'Nhạc hiệu thương hiệu';

  @override
  String get occasionBrandHint => 'Giai điệu bắt tai cho thương hiệu của bạn';

  @override
  String get occasionSoundtrack => 'Nhạc nền video';

  @override
  String get occasionSoundtrackHint => 'Âm nhạc hợp với câu chuyện của bạn';

  @override
  String get festivalNewYear => 'Năm mới';

  @override
  String get festivalThanksgiving => 'Lễ Tạ ơn';

  @override
  String get festivalDiwali => 'Diwali';

  @override
  String get festivalCarnival => 'Lễ hội Carnival';

  @override
  String get festivalEid => 'Lễ Eid';

  @override
  String get festivalLunarNewYear => 'Tết Nguyên đán';

  @override
  String get regionTitle => 'Bài hát sẽ được nghe ở đâu?';

  @override
  String get regionSearchHint => 'Tìm quốc gia';

  @override
  String get regionLanguageSheetTitle => 'Ngôn ngữ lời bài hát';

  @override
  String get countryUS => 'Hoa Kỳ';

  @override
  String get countryGB => 'Vương quốc Anh';

  @override
  String get countryCA => 'Canada';

  @override
  String get countryAU => 'Úc';

  @override
  String get countryDE => 'Đức';

  @override
  String get countryFR => 'Pháp';

  @override
  String get countryJP => 'Nhật Bản';

  @override
  String get countryKR => 'Hàn Quốc';

  @override
  String get countryBR => 'Brazil';

  @override
  String get countryMX => 'Mexico';

  @override
  String get countryIN => 'Ấn Độ';

  @override
  String get countryID => 'Indonesia';

  @override
  String get countryVN => 'Việt Nam';

  @override
  String get countryTR => 'Thổ Nhĩ Kỳ';

  @override
  String get languageEn => 'Tiếng Anh';

  @override
  String get languageFr => 'Tiếng Pháp';

  @override
  String get languageDe => 'Tiếng Đức';

  @override
  String get languageJa => 'Tiếng Nhật';

  @override
  String get languageKo => 'Tiếng Hàn';

  @override
  String get languagePtBR => 'Tiếng Bồ Đào Nha (Brazil)';

  @override
  String get languageEsMX => 'Tiếng Tây Ban Nha (Mexico)';

  @override
  String get languageHi => 'Tiếng Hindi';

  @override
  String get languageId => 'Tiếng Indonesia';

  @override
  String get languageVi => 'Tiếng Việt';

  @override
  String get languageTr => 'Tiếng Thổ Nhĩ Kỳ';

  @override
  String get languageZhHans => 'Tiếng Trung (Giản thể)';

  @override
  String get languageZhHant => 'Tiếng Trung (Phồn thể)';

  @override
  String get inputNameLabel => 'Tên người ấy';

  @override
  String get inputNameOptionalLabel => 'Tên (không bắt buộc)';

  @override
  String get inputNameHint => 'VD: Alex';

  @override
  String get inputKeywordsLabel => 'Ba từ về người ấy';

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
      'Lời bài hát này là của tôi hoặc tôi có quyền sử dụng';

  @override
  String get issueRecipientMissing => 'Hãy thêm tên người ấy.';

  @override
  String get issueRecipientTooLong => 'Tên có thể dài tối đa 24 ký tự.';

  @override
  String get issueBriefMissing =>
      'Kể cho chúng tôi về bài hát — vài lời, lời bài hát hoặc ảnh.';

  @override
  String get issueDescriptionMissing =>
      'Ý tưởng này cần lời của bạn — hãy viết một câu về bài hát.';

  @override
  String get generatingBackToEdit => 'Quay lại chỉnh sửa';

  @override
  String get issueKeywordTooLong => 'Mỗi từ có thể dài tối đa 20 ký tự.';

  @override
  String get issueTooManyKeywords => 'Dùng tối đa ba từ.';

  @override
  String get issueArtistName =>
      'Không thể dùng tên nghệ sĩ — hãy mô tả cảm xúc thay vào đó.';

  @override
  String get issueStyleImitation =>
      'Chúng tôi không thể bắt chước ca sĩ hay ban nhạc. Hãy mô tả tâm trạng thay vào đó.';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Lời bài hát có thể dài tối đa $limitString ký tự.';
  }

  @override
  String get issueLyricsNotOriginal =>
      'Lời này có vẻ giống một bài hát đã có. Hãy tự viết lời của bạn.';

  @override
  String get issueLyricsOwnership =>
      'Hãy xác nhận bạn có quyền sử dụng lời bài hát này.';

  @override
  String get issueTooManyPhotos => 'Chọn tối đa 10 ảnh.';

  @override
  String get photosTitle => 'Chọn vài bức ảnh';

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
      'Ảnh chỉ được dùng một lần để viết bài hát và sẽ bị xóa khỏi máy chủ của chúng tôi trong vòng 24 giờ.';

  @override
  String get photosAdd => 'Thêm ảnh';

  @override
  String get photosCreate => 'Tạo từ ảnh';

  @override
  String get photosEmpty => 'Chọn 1–10 bức ảnh về khoảnh khắc đó.';

  @override
  String get generatingStepPolishing =>
      'Đang trau chuốt lời của bạn trên iPhone này…';

  @override
  String get generatingStepUploading => 'Đang gửi ảnh của bạn…';

  @override
  String get generatingStepSubmitting => 'Đang gửi đến phòng thu…';

  @override
  String get errorSafetyBlocked =>
      'Chúng tôi không thể tạo bài này — hãy thử từ khác và đừng dùng tên nghệ sĩ.';

  @override
  String get errorQuotaExhausted =>
      'Bạn đã dùng hết số bài hát của tháng này. Hãy thêm gói bài hát hoặc nâng cấp.';

  @override
  String get errorUpstreamTimeout =>
      'Mất nhiều thời gian hơn bình thường. Chúng tôi sẽ tiếp tục thử và thông báo cho bạn.';

  @override
  String get errorUpstreamRateLimited =>
      'Hiện có rất nhiều bài hát đang được tạo. Bài của bạn đã được xếp hàng.';

  @override
  String get errorAttestFailed => 'Vui lòng cập nhật Songlet từ App Store.';

  @override
  String get errorImageRejected =>
      'Một trong các ảnh này không thể sử dụng. Hãy thử ảnh khác.';

  @override
  String get errorNetworkOffline =>
      'Bạn đang ngoại tuyến. Thư viện của bạn vẫn hoạt động.';

  @override
  String get errorDownloadLocked =>
      'Không thể tải xuống bài hát này — giao dịch mua dùng để tạo bài hát đã được hoàn tiền hoặc gói của bạn đã kết thúc. Bạn vẫn có thể phát bài hát.';

  @override
  String get errorJobAlreadyFinished => 'Bài hát đã hoàn tất — không cần hủy.';

  @override
  String get errorMvSongNotReady => 'Bài hát này chưa sẵn sàng để làm video.';

  @override
  String get errorMvSongTooLong =>
      'Bài hát này quá dài cho video trọn bài — hãy thử video điệp khúc.';

  @override
  String get errorMvSongExpired =>
      'Bài hát này đã hết hạn. Hãy tạo lại để làm video.';

  @override
  String get errorMvNotFound => 'Video này không còn khả dụng.';

  @override
  String get errorMvPhotosExpired => 'Những ảnh đó đã hết hạn — hãy chọn lại.';

  @override
  String get errorMvRenderFailed =>
      'Chúng tôi không thể hoàn thành video này. Tín dụng đã được hoàn — hãy thử lại.';

  @override
  String get mvHubTitle => 'Làm video';

  @override
  String mvHubSubtitle(String title) {
    return 'Biến “$title” thành video ca nhạc.';
  }

  @override
  String get mvLevelLyricVideo => 'Video lời bài hát';

  @override
  String get mvLevelLyricHint => 'Một cảnh tĩnh với lời bài hát';

  @override
  String get mvLevelChorus => 'Video điệp khúc';

  @override
  String get mvLevelChorusHint => '30 giây điệp khúc, do AI quay';

  @override
  String get mvLevelFull => 'Video trọn bài';

  @override
  String get mvLevelFullHint => 'Trọn bài hát, từng cảnh một';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString tín dụng',
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
      other: 'Bạn có $creditsString tín dụng',
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
      other: 'Cần thêm $creditsString',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => 'Đang kiểm tra giá…';

  @override
  String get mvOptionsHeader => 'Tùy chọn';

  @override
  String get mvAspectLabel => 'Khung hình';

  @override
  String get mvAspectPortrait => 'Dọc';

  @override
  String get mvAspectLandscape => 'Ngang';

  @override
  String get mvAspectSquare => 'Vuông';

  @override
  String get mvQualityLabel => 'Chất lượng';

  @override
  String get mvQualityStandard => 'Tiêu chuẩn';

  @override
  String get mvQualityHigh => 'Cao';

  @override
  String get mvSubtitlesLabel => 'Lời bài hát trên màn hình';

  @override
  String get mvPhotosLabel => 'Ảnh tham khảo';

  @override
  String get mvPhotosHint =>
      'Định hình bối cảnh và màu sắc — không dùng khuôn mặt';

  @override
  String mvPhotosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ảnh',
    );
    return '$_temp0';
  }

  @override
  String get mvChorusLabel => 'Điệp khúc';

  @override
  String get mvChorusAuto => 'Tự động tìm';

  @override
  String get mvChorusCustom => 'Tự chọn đoạn';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => 'Làm video';

  @override
  String get mvBuyPack => 'Mua gói và làm';

  @override
  String get mvSongLocked => 'Bài hát của bạn đã được lưu cho video.';

  @override
  String get mvGeneratingTitle => 'Đang làm video của bạn…';

  @override
  String get mvStageQueued => 'Đang chờ bắt đầu';

  @override
  String get mvStageSlicing => 'Đang chọn khoảnh khắc';

  @override
  String get mvStageStoryboarding => 'Đang viết kịch bản phân cảnh';

  @override
  String get mvStageKeyframing => 'Đang vẽ các cảnh';

  @override
  String get mvStageRendering => 'Đang quay các cảnh';

  @override
  String get mvStageAssembling => 'Đang dựng phim';

  @override
  String get mvStageDone => 'Xong';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Cảnh $doneString/$totalString';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Thường mất khoảng $minutesString phút';
  }

  @override
  String get mvCancelRequested => 'Sẽ dừng sau cảnh hiện tại…';

  @override
  String get mvCancelTitle => 'Dừng video này?';

  @override
  String get mvCancelQueued => 'Chưa bắt đầu nên sẽ không dùng gì cả.';

  @override
  String get mvCancelStarted =>
      'Đã bắt đầu rồi. Các cảnh đã làm sẽ bị tính phí; phần còn lại được hoàn.';

  @override
  String get mvCancelConfirm => 'Dừng video';

  @override
  String get mvCancelled => 'Đã dừng video';

  @override
  String get mvCancelledRefunded => 'Đã dừng video — không dùng gì cả';

  @override
  String get mvNothing => 'Hiện không có video nào đang được làm.';

  @override
  String get mvQuotaTitle => 'Không đủ tín dụng';

  @override
  String get mvAiLabelBurnedIn => 'Tạo bởi AI — huy hiệu là một phần của video';

  @override
  String get mvSave => 'Lưu vào Ảnh';

  @override
  String get mvSaveFiles => 'Lưu vào Tệp';

  @override
  String get mvShareText => 'Tôi đã làm video ca nhạc này với Songlet 🎬';

  @override
  String get mvMissing => 'Video này không còn trên thiết bị này.';

  @override
  String get mvDeleteTitle => 'Xóa video này?';

  @override
  String get mvDeleteBody => 'Sẽ bị xóa khỏi thiết bị này.';

  @override
  String get mvDeleted => 'Đã xóa video';

  @override
  String get mvProvenance =>
      'Tạo bằng Google Lyria 3 và các mô hình video AI · Tạo bởi AI';

  @override
  String get detailVideos => 'Video';

  @override
  String get detailMakeVideo => 'Làm video';

  @override
  String get mvStatusReady => 'Sẵn sàng';

  @override
  String get mvStatusPending => 'Đang làm…';

  @override
  String get mvStatusFailed => 'Chưa xong';

  @override
  String get mvPackTitle => 'Video ca nhạc';

  @override
  String get mvPackChorusSubtitle => 'Một video điệp khúc';

  @override
  String get mvPackFullSubtitle => 'Một video trọn bài';

  @override
  String get paywallMvHeroTitle => 'Biến nó thành video';

  @override
  String get paywallMvHeroSubtitle =>
      'Tín dụng cho video ca nhạc của bạn — lưu và chia sẻ.';

  @override
  String get playerAiGenerated => 'Do AI tạo';

  @override
  String get playerLoop => 'Lặp lại';

  @override
  String get playerPlay => 'Phát';

  @override
  String get playerPause => 'Tạm dừng';

  @override
  String get playerPreviewLabel => 'Bản nghe thử 30 giây';

  @override
  String playerTitleFor(String name) {
    return 'Dành cho $name';
  }

  @override
  String get downloadSaved => 'Đã lưu vào Tệp.';

  @override
  String get shareComposing => 'Đang tạo thẻ chia sẻ…';

  @override
  String get shareFailed => 'Không thể tạo thẻ chia sẻ.';

  @override
  String get shareText => 'Mình đã tạo bài hát này bằng Songlet 🎵';

  @override
  String get paywallBestValue => 'Tiết kiệm nhất';

  @override
  String get paywallStartTrial => 'Bắt đầu dùng thử miễn phí';

  @override
  String get paywallClose => 'Đóng';

  @override
  String get paywallSeePlans => 'Xem gói đăng ký';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Gói của bạn đang hoạt động — còn $countString bài hát đầy đủ trong kỳ này.',
      one:
          'Gói của bạn đang hoạt động — còn $countString bài hát đầy đủ trong kỳ này.',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => 'Các bài hát của bạn sẽ nằm ở đây.';

  @override
  String get libraryEmptyAction => 'Tạo bài hát đầu tiên';

  @override
  String get libraryPending => 'Đang soạn nhạc…';

  @override
  String get libraryPreviewBadge => 'Nghe thử';

  @override
  String get librarySongBadge => 'Bài hát đầy đủ';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsPlan => 'Gói của bạn';

  @override
  String get settingsPlanUnavailable =>
      'Không thể tải gói của bạn. Hãy kéo để thử lại sau.';

  @override
  String get tierFree => 'Chưa đăng ký gói';

  @override
  String get tierPack => 'Gói bài hát';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $countString bài hát đầy đủ',
      one: 'Còn $countString bài hát đầy đủ',
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
      other: 'Còn $countString bản nghe thử',
      one: 'Còn $countString bản nghe thử',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Đặt lại vào $dateString';
  }

  @override
  String get settingsUpgrade => 'Nâng cấp';

  @override
  String get appTagline => 'Những bài hát cho người bạn thương';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonDone => 'Xong';

  @override
  String get commonDelete => 'Xóa';

  @override
  String get commonMore => 'Thêm';

  @override
  String get commonCopy => 'Sao chép';

  @override
  String get commonCopied => 'Đã sao chép';

  @override
  String get commonNotNow => 'Để sau';

  @override
  String get commonLearnMore => 'Tìm hiểu thêm';

  @override
  String get commonSeeAll => 'Xem tất cả';

  @override
  String get commonKeepGoing => 'Tiếp tục';

  @override
  String get composerHint => 'Mô tả bài hát bạn muốn';

  @override
  String get composerAddPhotos => 'Thêm ảnh';

  @override
  String get composerSourceMusicHint => 'Mô tả bằng lời của bạn';

  @override
  String get composerDictate => 'Đọc chính tả';

  @override
  String get composerStopDictation => 'Dừng đọc chính tả';

  @override
  String get lengthPreview => 'Nghe thử';

  @override
  String get lengthFull => 'Bài hát đầy đủ';

  @override
  String get paramLength => 'Độ dài';

  @override
  String get paramVocals => 'Giọng hát';

  @override
  String get paramGenre => 'Thể loại';

  @override
  String templatePlaySample(String name) {
    return 'Phát bản mẫu $name';
  }

  @override
  String get templatePauseSample => 'Tạm dừng bản mẫu';

  @override
  String get lengthShort => 'Ngắn';

  @override
  String get lengthShortHint => 'Nghe thử 30 giây';

  @override
  String get lengthStandard => 'Tiêu chuẩn';

  @override
  String get lengthStandardHint => 'khoảng 2 phút, Pro';

  @override
  String get vocalsCustom => 'Tự động';

  @override
  String get vocalsCustomHint => 'theo mô tả của bạn';

  @override
  String get vocalsCustomDetail => 'Phong cách giọng hát theo mô tả của bạn.';

  @override
  String get vocalsOn => 'Có giọng hát';

  @override
  String get vocalsInstrumental => 'Không lời';

  @override
  String vocalsLyricsIn(String language) {
    return 'Lời bài hát bằng $language';
  }

  @override
  String get genreCustom => 'Tự động';

  @override
  String get genreCustomHint => 'theo mô tả của bạn';

  @override
  String genrePopularIn(String country) {
    return 'Phổ biến ở $country';
  }

  @override
  String get genreAll => 'Tất cả thể loại';

  @override
  String get regionHelper =>
      'Thay đổi 3 thể loại gợi ý và ngôn ngữ lời bài hát';

  @override
  String regionLyricsRow(String language) {
    return 'Ngôn ngữ lời: $language';
  }

  @override
  String get regionNoMatch => 'Không có quốc gia phù hợp';

  @override
  String get keywordAdd => 'Thêm một từ';

  @override
  String keywordRemove(String word) {
    return 'Xóa $word';
  }

  @override
  String get nameClear => 'Xóa tên';

  @override
  String get lyricsOptional => 'Tự viết lời (không bắt buộc)';

  @override
  String get issueRecipientArtistName => 'Không được dùng tên nghệ sĩ.';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Giữ mô tả dưới $limitString ký tự.';
  }

  @override
  String get voiceRecording => 'Đang ghi âm…';

  @override
  String get voiceStarting => 'Đang bắt đầu…';

  @override
  String get voiceListening =>
      'Hãy nói bài hát dành cho ai và người ấy yêu thích điều gì…';

  @override
  String get voiceOnDevice => 'Chép lời trên thiết bị';

  @override
  String get voicePermissionDenied =>
      'Hãy cho phép Songlet dùng micrô và nhận dạng giọng nói trong Cài đặt để đọc chính tả.';

  @override
  String get voiceUnavailable =>
      'Thiết bị này không hỗ trợ đọc chính tả cho ngôn ngữ này.';

  @override
  String get voiceApplied => 'Đã thêm từ giọng nói của bạn';

  @override
  String get photoRemove => 'Xóa ảnh';

  @override
  String generatingTitleFor(String name) {
    return 'Đang viết bài hát cho $name…';
  }

  @override
  String get generatingTitleGeneric => 'Đang viết bài hát của bạn…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Thường mất khoảng $secondsString giây';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => 'Tiến độ';

  @override
  String get generatingGlimpse => 'Nghe trước một chút lời';

  @override
  String get generatingCancelTitle => 'Dừng bài hát này?';

  @override
  String get generatingCancelQueued =>
      'Bài hát chưa bắt đầu nên không bị trừ lượt.';

  @override
  String get generatingCancelStarted =>
      'Bài hát đã bắt đầu nên vẫn bị trừ lượt.';

  @override
  String get generatingCancelConfirm => 'Dừng';

  @override
  String get generatingCancelled => 'Đã dừng bài hát';

  @override
  String get generatingCancelledRefunded =>
      'Đã dừng bài hát — không bị trừ lượt';

  @override
  String get queueTitle => 'Đang có rất nhiều bài hát được tạo.';

  @override
  String get queueSubtitle => 'Bài của bạn đang chờ.';

  @override
  String get queuePosition => 'Vị trí';

  @override
  String get queueWait => 'thời gian chờ ước tính';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '≈ $minutesString phút';
  }

  @override
  String get generatingNothing => 'Hiện không có bài hát nào đang được tạo.';

  @override
  String get previewGetFull => 'Nhận bài hát đầy đủ 2 phút';

  @override
  String get previewShare => 'Chia sẻ bản nghe thử';

  @override
  String get previewAnother => 'Thử phiên bản khác (dùng 1 lượt nghe thử)';

  @override
  String get playerPosition => 'Vị trí phát';

  @override
  String get playerPrevSection => 'Đoạn trước';

  @override
  String get playerNextSection => 'Đoạn sau';

  @override
  String get playerShuffle => 'Phát ngẫu nhiên các đoạn';

  @override
  String get playerRepeat => 'Lặp lại';

  @override
  String get playerProvenance =>
      'Tạo bằng Google Lyria 3 · hình mờ SynthID · do AI tạo';

  @override
  String get playerMissing => 'Bài hát này không còn trên thiết bị.';

  @override
  String get actionDownload => 'Tải xuống';

  @override
  String get actionShare => 'Chia sẻ';

  @override
  String get actionLicense => 'Giấy phép';

  @override
  String get actionRegenerate => 'Tạo lại';

  @override
  String get actionDetails => 'Chi tiết';

  @override
  String get sectionIntro => 'Dạo đầu';

  @override
  String get sectionVerse => 'Phiên khúc';

  @override
  String get sectionPreChorus => 'Tiền điệp khúc';

  @override
  String get sectionChorus => 'Điệp khúc';

  @override
  String get sectionBridge => 'Chuyển đoạn';

  @override
  String get sectionOutro => 'Kết';

  @override
  String get sectionHook => 'Hook';

  @override
  String get shareTitle => 'Thẻ chia sẻ';

  @override
  String get shareSubtitle => 'Chọn chủ đề và bố cục.';

  @override
  String get shareTheme => 'Chủ đề';

  @override
  String get shareLayout => 'Bố cục';

  @override
  String get shareLayoutScene => 'Có minh họa';

  @override
  String get shareLayoutText => 'Chỉ chữ';

  @override
  String get paletteTerracotta => 'Đất nung';

  @override
  String get paletteSand => 'Cát';

  @override
  String get paletteOlive => 'Ô liu';

  @override
  String get paletteNavy => 'Xanh navy';

  @override
  String get shareAction => 'Chia sẻ';

  @override
  String get shareSaveVideo => 'Lưu video';

  @override
  String get shareCopyLyrics => 'Sao chép lời';

  @override
  String get shareVideoSaved => 'Đã lưu vào Ảnh';

  @override
  String get shareLyricsCopied => 'Đã sao chép lời';

  @override
  String get shareCardTagline => 'Một bài hát cho ai đó';

  @override
  String get shareSaveFailed =>
      'Không lưu được video. Hãy cho phép Songlet thêm vào Ảnh trong Cài đặt.';

  @override
  String get downloadReady => 'Bài hát đầy đủ đã sẵn sàng';

  @override
  String get downloadTitle => 'Của bạn mãi mãi';

  @override
  String get downloadIntro =>
      'Bài hát đã hoàn tất. Tải âm thanh chất lượng cao và giấy phép thương mại bên dưới.';

  @override
  String get downloadAudioHeader => 'Tải âm thanh';

  @override
  String get downloadAudioNote => 'Chất lượng cao';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle => 'Phù hợp để chia sẻ và nghe hằng ngày';

  @override
  String get downloadWavTitle => 'WAV · 44,1 kHz (Premier)';

  @override
  String get downloadWavSubtitle =>
      'Chất lượng cao nhất cho mục đích chuyên nghiệp';

  @override
  String get downloadMp3Action => 'Tải MP3';

  @override
  String get downloadWavAction => 'Tải WAV';

  @override
  String get downloadLicenseAction => 'Tải giấy phép';

  @override
  String get licenseHeader => 'Giấy phép thương mại';

  @override
  String get licenseIncluded => 'Có trong gói của bạn';

  @override
  String get licenseNotIncluded => 'Có khi mua gói hoặc gói bài hát';

  @override
  String get licensePdfTitle => 'Giấy phép thương mại (PDF)';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Cấp ngày $dateString';
  }

  @override
  String licenseId(String id) {
    return 'Mã giấy phép: $id';
  }

  @override
  String get licenseUsesTitle => 'Bạn có thể dùng bài hát này cho:';

  @override
  String get usePersonal => 'Sử dụng cá nhân';

  @override
  String get usePersonalDetail => 'Quà tặng, kỷ niệm, phi thương mại';

  @override
  String get useAds => 'Quảng cáo & tiếp thị';

  @override
  String get useAdsDetail => 'Khuyến mãi, chiến dịch trả phí';

  @override
  String get useSocial => 'Mạng xã hội';

  @override
  String get useSocialDetail => 'TikTok, Instagram, YouTube, v.v.';

  @override
  String get usePodcasts => 'Podcast & video';

  @override
  String get usePodcastsDetail => 'Nội dung kiếm tiền';

  @override
  String get licenseDetailsNote =>
      'Chi tiết đầy đủ có trong file PDF giấy phép.';

  @override
  String get saveEnjoyHeader => 'Lưu và thưởng thức';

  @override
  String get saveToFiles => 'Lưu vào Tệp';

  @override
  String get addToMusic => 'Thêm vào Nhạc';

  @override
  String get synthIdNote =>
      'Bài hát này có hình mờ SynthID để nhận diện nội dung do AI tạo, kể cả sau khi tải xuống.';

  @override
  String get wavNeedsPremier => 'Tải WAV có trong gói Premier.';

  @override
  String get wavUnavailable =>
      'Bài hát này không có tệp WAV. Tệp WAV có thể được lưu trong vòng 24 giờ sau khi tạo bài hát.';

  @override
  String get libraryFilterAll => 'Tất cả';

  @override
  String get libraryJustBecause => 'Chỉ vì thích';

  @override
  String libraryPlay(String title) {
    return 'Phát $title';
  }

  @override
  String libraryActions(String title) {
    return 'Tác vụ cho $title';
  }

  @override
  String get libraryDeleteTitle => 'Xóa bài hát này?';

  @override
  String get libraryDeleteBody =>
      'Bài hát sẽ bị xóa khỏi thiết bị này. Nếu đang bật đồng bộ iCloud, bài hát cũng bị xóa khỏi các thiết bị khác của bạn.';

  @override
  String get libraryDeleted => 'Đã xóa bài hát';

  @override
  String get libraryFailed => 'Chưa hoàn tất';

  @override
  String get libraryNoMatch => 'Chưa có bài hát cho dịp này.';

  @override
  String get detailFullGenerated => 'Đã tạo bài hát đầy đủ';

  @override
  String get detailPreviewGenerated => 'Đã tạo bản nghe thử';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Tạo ngày $dateString';
  }

  @override
  String get detailPromptUsed => 'Thông tin đã dùng';

  @override
  String get detailOccasion => 'Dịp';

  @override
  String get detailCountry => 'Quốc gia';

  @override
  String get detailGenre => 'Thể loại';

  @override
  String get detailKeywords => 'Từ khóa';

  @override
  String get detailDescription => 'Mô tả';

  @override
  String get detailLyrics => 'Lời bài hát';

  @override
  String get detailGenerationId => 'Mã tạo';

  @override
  String get detailRegenerate => 'Tạo lại cùng phong cách';

  @override
  String get detailCustomGenre => 'Theo mô tả';

  @override
  String get settingsSectionPlan => 'Mua hàng';

  @override
  String get settingsSectionLibrary => 'Thư viện';

  @override
  String get settingsSectionAbout => 'Giới thiệu';

  @override
  String get settingsRestore => 'Khôi phục giao dịch mua';

  @override
  String get settingsManage => 'Quản lý gói đăng ký';

  @override
  String get settingsICloud => 'Đồng bộ iCloud';

  @override
  String get settingsICloudOn =>
      'Bài hát được đồng bộ trên các thiết bị của bạn';

  @override
  String get settingsICloudOff => 'Bài hát chỉ lưu trên thiết bị này';

  @override
  String get settingsICloudUnavailable =>
      'Đăng nhập iCloud trong Cài đặt để đồng bộ';

  @override
  String get settingsLyricsLanguage => 'Ngôn ngữ lời mặc định';

  @override
  String get settingsLyricsLanguageAuto => 'Theo quốc gia';

  @override
  String get settingsTerms => 'Điều khoản sử dụng';

  @override
  String get settingsPrivacy => 'Chính sách quyền riêng tư';

  @override
  String settingsVersion(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get aboutTitle => 'Về cách tạo bài hát';

  @override
  String get aboutSubtitle => 'Songlet tạo bài hát của bạn như thế nào';

  @override
  String get aboutLyriaTitle => 'Sử dụng Lyria 3 của Google';

  @override
  String get aboutLyriaBody =>
      'Bài hát được tạo bằng Lyria 3 của Google qua Gemini API. Lyria 3 là mô hình tạo nhạc biến ý tưởng của bạn thành bài hát nguyên bản.';

  @override
  String get aboutWatermarkTitle => 'Hình mờ tích hợp';

  @override
  String get aboutWatermarkBody =>
      'Mỗi bài hát đều có hình mờ SynthID của Google. Hình mờ giúp nhận diện nhạc do AI tạo và không thể xóa.';

  @override
  String get aboutImitationTitle => 'Không bắt chước nghệ sĩ thật';

  @override
  String get aboutImitationBody =>
      'Songlet không bao giờ bắt chước nghệ sĩ thật, giọng hát hay phong cách riêng của họ. Bài hát là nguyên bản, tạo từ ý tưởng, mô tả và ảnh của bạn.';

  @override
  String get aboutPrivacyTitle => 'Quyền riêng tư của bạn là quan trọng';

  @override
  String get aboutPrivacyBody =>
      'Ảnh và mô tả được xóa khỏi máy chủ trong vòng 24 giờ. Chúng tôi không giữ ảnh hay mô tả của bạn sau khi bài hát được tạo.';

  @override
  String get aboutBanner =>
      'Mọi bài hát bạn chia sẻ đều được gắn nhãn do AI tạo.';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · Tạo bằng Google Lyria 3';
  }

  @override
  String get festivalKicker => 'Sống trọn câu chuyện của bạn';

  @override
  String get festivalComing => 'sắp đến rồi!';

  @override
  String get festivalBody => 'Tạo một bài hát độc nhất để ăn mừng.';

  @override
  String festivalCta(String festival) {
    return 'Tạo bài hát $festival';
  }

  @override
  String get festivalPickOccasion => 'Chọn một dịp và bắt đầu sáng tác';

  @override
  String get festivalLanguagesTitle => 'Bài hát bằng ngôn ngữ của bạn';

  @override
  String festivalLanguagesBody(String language) {
    return 'Tạo bài hát bằng $language và 12 ngôn ngữ khác';
  }

  @override
  String get unavailableTitle => 'Tạm thời không khả dụng';

  @override
  String get unavailableMessage =>
      'Hiện Songlet chưa thể tạo bài hát. Thư viện của bạn vẫn dùng được — hãy thử lại sau ít phút.';

  @override
  String get paywallHeroTitle => 'Biến nó thành bài hát đầy đủ';

  @override
  String get paywallHeroSubtitle =>
      'Biến ý tưởng thành bài hát hoàn chỉnh với chất lượng cao hơn và đầy đủ quyền sử dụng.';

  @override
  String get paywallBenefitSongs => 'Nhiều bài hơn';

  @override
  String get paywallBenefitQuality => 'Chất lượng cao hơn';

  @override
  String get paywallBenefitCommercial => 'Dùng thương mại';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bài đầy đủ mỗi tháng',
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
      other: '$countString lượt nghe thử mỗi tháng',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'Tải MP3';

  @override
  String get planMp3Wav => 'Tải MP3 + WAV';

  @override
  String get planLicense => 'Giấy phép thương mại';

  @override
  String get planPriority => 'Ưu tiên tạo bài';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Dùng thử miễn phí $daysString ngày';
  }

  @override
  String planPerYear(String price) {
    return '$price/năm';
  }

  @override
  String planPerMonth(String price) {
    return '$price/tháng';
  }

  @override
  String get packTitle => 'Chỉ cần vài bài?';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gói $countString bài hát',
    );
    return '$_temp0';
  }

  @override
  String get packNote => 'không hết hạn';

  @override
  String get valueForever => 'Bài hát của bạn, mãi mãi';

  @override
  String get valueDownloads => 'Tải xuống chất lượng cao';

  @override
  String get valueCommercial => 'Được dùng thương mại';

  @override
  String get valuePrivate => 'Ưu tiên quyền riêng tư';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return 'Hết thời gian dùng thử miễn phí, bạn sẽ tự động được tính phí $pricePerPeriod. Có thể hủy bất cứ lúc nào trước khi hết dùng thử.';
  }

  @override
  String get paywallSubscribe => 'Đăng ký';

  @override
  String get paywallBuyPack => 'Mua gói';

  @override
  String get templateBirthdayWish => 'Chúc mừng sinh nhật';

  @override
  String get templateBirthdayWishHint =>
      'Một bài hát đặc biệt cho ngày đặc biệt';

  @override
  String get templateBirthdayParty => 'Tiệc sinh nhật';

  @override
  String get templateBirthdayPartyHint =>
      'Khuấy động bữa tiệc cho nhân vật chính';

  @override
  String get templateLoveStory => 'Chuyện tình';

  @override
  String get templateLoveStoryHint => 'Câu chuyện của hai bạn thành bài hát';

  @override
  String get templateThankAFriend => 'Cảm ơn bạn bè';

  @override
  String get templateThankAFriendHint =>
      'Nói lời cảm ơn theo cách lời nói không thể';

  @override
  String get templatePartyInvite => 'Mời dự tiệc';

  @override
  String get templatePartyInviteHint => 'Rủ mọi người đến bữa tiệc';

  @override
  String get templateWedding => 'Đám cưới';

  @override
  String get templateWeddingHint => 'Bài hát cho khoảnh khắc mãi mãi của họ';

  @override
  String get templateInMemory => 'Tưởng nhớ';

  @override
  String get templateInMemoryHint => 'Tưởng nhớ người bạn trân quý';

  @override
  String get templateFestival => 'Lễ hội';

  @override
  String get templateFestivalHint => 'Lời chúc ấm áp cho mùa đặc biệt';

  @override
  String get templateRingtone => 'Nhạc chuông';

  @override
  String get templateRingtoneHint => 'Một đoạn lặp ngắn của riêng bạn';

  @override
  String get templateTeamAnthem => 'Bài ca đội bóng';

  @override
  String get templateTeamAnthemHint => 'Tiếp lửa cho đội và khán giả';

  @override
  String get templateSportsRecap => 'Tóm tắt trận đấu';

  @override
  String get templateSportsRecapHint => 'Trận đấu lớn kể bằng bài hát';

  @override
  String get templateRapBattle => 'Đối đầu rap';

  @override
  String get templateRapBattleHint =>
      'Những câu rap thân thiện cho đối thủ thân thiện';

  @override
  String get templateComedy => 'Hài hước';

  @override
  String get templateComedyHint => 'Chuyện đùa nội bộ, giờ có cả điệp khúc';

  @override
  String get templatePetAnthem => 'Bài ca thú cưng';

  @override
  String get templatePetAnthemHint => 'Bài hát chủ đề cho người bạn thân nhất';

  @override
  String get templateHometown => 'Quê hương';

  @override
  String get templateHometownHint => 'Tình yêu cho nơi bạn gọi là nhà';

  @override
  String get templateBusinessPromo => 'Quảng bá cửa hàng';

  @override
  String get templateBusinessPromoHint =>
      'Giai điệu bắt tai cho cửa hàng hay thương hiệu của bạn';

  @override
  String get templateCustom => 'Ý tưởng của riêng bạn';

  @override
  String get mvRecommended => 'Đề xuất';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString giây';
  }

  @override
  String get mvViewProgress => 'Xem tiến độ';

  @override
  String mvIntentWaiting(String level) {
    return '$level đang chờ tín dụng';
  }

  @override
  String get mvSongExpiredAction => 'Làm lại bài hát';

  @override
  String mvQuotaNeed(String level, int required, int available) {
    final intl.NumberFormat requiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requiredString = requiredNumberFormat.format(required);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return '$level cần $requiredString tín dụng. Bạn có $availableString.';
  }

  @override
  String get mvQuotaBuyAndContinue => 'Mua và tiếp tục';

  @override
  String get mvQuotaMayNeedTwice =>
      'Ở khu vực của bạn, một gói có thể chưa đủ — có thể cần hai gói.';

  @override
  String get mvQuotaAutoRetry =>
      'Video của bạn bắt đầu ngay khi giao dịch hoàn tất.';

  @override
  String get mvAutoLyricMaking => 'Đang làm video lời bài hát';

  @override
  String get mvAutoChorusDetail => 'Làm từ bài hát này bằng tín dụng của bạn';

  @override
  String mvAutoReady(String level) {
    return '$level đã sẵn sàng';
  }

  @override
  String get mvAutoView => 'Xem';

  @override
  String get mvUpgradeChorus => 'Làm video điệp khúc';

  @override
  String get mvAutoFailed => 'Không thể bắt đầu video';

  @override
  String get mvLeaveHint =>
      'Bạn có thể rời màn hình này — chúng tôi sẽ báo khi video lẽ ra đã xong.';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString tín dụng của bạn đã được hoàn lại.',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => 'Video này chưa hoàn tất';

  @override
  String get mvRejectedTitle => 'Có một ảnh không dùng được';

  @override
  String get mvRejectedBody =>
      'Mô hình video đã từ chối một ảnh tham khảo của bạn. Hãy đổi ảnh và thử lại.';

  @override
  String get mvAdjustPhotos => 'Đổi ảnh và thử lại';

  @override
  String get mvTryChorus => 'Làm video điệp khúc thay thế';

  @override
  String get mvPreparingPhotos => 'Đang tải ảnh lên…';

  @override
  String get mvPreparingSubmit => 'Đang gửi video…';

  @override
  String get mvNotifyTitle => 'Video của bạn lẽ ra đã xong';

  @override
  String mvNotifyBody(String level) {
    return '$level — chạm để xem.';
  }

  @override
  String get mvRegenerate => 'Làm thêm';

  @override
  String get mvEntryTitle => 'Biến thành video';

  @override
  String get mvEntrySubtitle =>
      'Video lời bài hát, điệp khúc và cả bài, dùng tín dụng';

  @override
  String get mvEntryDisabled => 'Có khi bài hát đã xong';

  @override
  String get mvEntryChoose => 'Chọn video';

  @override
  String get mvEntryWatch => 'Xem video';

  @override
  String get mvChipReady => 'Video';

  @override
  String get mvChipMaking => 'Đang làm video';

  @override
  String get lengthAutoVideo => 'Làm thêm video lời bài hát';

  @override
  String get lengthAutoVideoHint => 'Xong vài phút sau bài hát · dùng tín dụng';

  @override
  String get lengthSongAndChorus => 'Bài hát + video điệp khúc';

  @override
  String get lengthSongAndChorusHint =>
      'Cả bài hát, sau đó là video điệp khúc 30 giây';

  @override
  String get paywallVideoGroup => 'Video ca nhạc';

  @override
  String get planVideoIncluded =>
      'Hạn mức của bạn cũng dùng để làm video ca nhạc';

  @override
  String get settingsVideoCredits => 'Tín dụng video';

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
  String get createGenreElectronic => 'Điện tử';

  @override
  String get createGenreRnb => 'R&B';

  @override
  String get createGenreCountry => 'Đồng quê';

  @override
  String get createGenreAfrobeats => 'Afrobeats';

  @override
  String get createGenreReggae => 'Reggae';

  @override
  String get createGenreJazzBlues => 'Jazz & blues';

  @override
  String get createGenreClassical => 'Cổ điển';

  @override
  String get createGenreFolk => 'Dân gian';

  @override
  String get createGenreLofi => 'Lo-fi';

  @override
  String get createGenreAcoustic => 'Mộc';

  @override
  String get createGenreCinematic => 'Nhạc phim';

  @override
  String get createGenreAmbient => 'Ambient';

  @override
  String get createGenreBossaNova => 'Bossa nova';

  @override
  String get createGenreIndiePop => 'Indie pop';

  @override
  String get createGenreContemporaryRnb => 'R&B đương đại';

  @override
  String get createGenreAlternativeCountry => 'Đồng quê phá cách';

  @override
  String get createGenreGarageRock => 'Garage rock';

  @override
  String get createGenreGrime => 'Grime';

  @override
  String get createGenreIndieFolk => 'Indie folk';

  @override
  String get createGenreSynthpop => 'Synthpop';

  @override
  String get createGenrePianoBallad => 'Ballad piano';

  @override
  String get createGenreSurfRock => 'Surf rock';

  @override
  String get createGenreDeepHouse => 'Deep house';

  @override
  String get createGenreMinimalTechno => 'Techno tối giản';

  @override
  String get createGenreFrenchYeyePop => 'Pop Pháp thập niên 60';

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
  String get createGenreIndianClassical => 'Cổ điển Ấn Độ';

  @override
  String get createGenreLofiHipHop => 'Hip-hop lo-fi';

  @override
  String profileAccountIdWithValue(String id) {
    return 'ID tài khoản: $id';
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
  String get createVocalsCustomSummary => 'Tự động — theo mô tả của bạn';

  @override
  String mvChipMakingWithProgress(String progress) {
    return 'Đang làm video · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return 'Không thể bắt đầu video · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    return 'Điểm video: $creditsString';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => 'Cảm hứng';

  @override
  String inspirationPlay(String name) {
    return 'Phát $name';
  }

  @override
  String get inspirationStop => 'Dừng nghe thử';

  @override
  String get inspirationNameSoundscape => 'Âm cảnh';

  @override
  String get inspirationStyleSoundscape => 'Âm thanh không gian, không lời';

  @override
  String get inspirationNameBackgroundMusic => 'Nhạc nền';

  @override
  String get inspirationStyleBackgroundMusic =>
      'Nhạc không lời nhẹ nhàng cho video';

  @override
  String get inspirationNameMemorizeSomething => 'Ghi nhớ điều gì đó';

  @override
  String get inspirationStyleMemorizeSomething => 'Pop bắt tai để ghi nhớ';

  @override
  String get inspirationNameTextMessages => 'Tin nhắn thành bài hát';

  @override
  String get inspirationStyleTextMessages =>
      'Pop tinh nghịch từ tin nhắn của bạn';

  @override
  String get inspirationNameIntroMusic => 'Nhạc mở đầu';

  @override
  String get inspirationStyleIntroMusic => 'Mở đầu hoành tráng như phim';

  @override
  String get inspirationNameMontage => 'Dựng phim';

  @override
  String get inspirationStyleMontage =>
      'Cao trào hứng khởi cho video điểm nhấn';

  @override
  String get inspirationNameSayItWithATrack => 'Nói bằng bài hát';

  @override
  String get inspirationStyleSayItWithATrack => 'Bản ballad pop sâu lắng';

  @override
  String get inspirationNameBrandJingle => 'Nhạc hiệu thương hiệu';

  @override
  String get inspirationStyleBrandJingle => 'Đoạn nhạc ngắn, tươi sáng, dễ nhớ';

  @override
  String get inspirationNameRingtone => 'Nhạc chuông';

  @override
  String get inspirationStyleRingtone => 'Đoạn nhạc 30 giây lặp lại được';

  @override
  String get inspirationNameStreaming => 'Livestream';

  @override
  String get inspirationStyleStreaming => 'Mở đầu livestream điện tử sôi động';

  @override
  String get inspirationNameSpeechToTrack => 'Giọng nói thành bài hát';

  @override
  String get inspirationStyleSpeechToTrack => 'Giọng của bạn thành bài hát';

  @override
  String get inspirationNameRapBattle => 'Đấu rap';

  @override
  String get inspirationStyleRapBattle => 'Hip-hop mạnh mẽ';

  @override
  String get inspirationNameComedy => 'Hài hước';

  @override
  String get inspirationStyleComedy => 'Lạ, vui tươi, hóm hỉnh';

  @override
  String get inspirationNameTeamAnthem => 'Bài hát đội';

  @override
  String get inspirationStyleTeamAnthem => 'Bài cổ vũ rock sân vận động';

  @override
  String get inspirationNameSportsRecap => 'Tổng kết trận đấu';

  @override
  String get inspirationStyleSportsRecap =>
      'Khoảnh khắc giao hưởng hoành tráng';

  @override
  String get inspirationNamePartyInvite => 'Lời mời dự tiệc';

  @override
  String get inspirationStylePartyInvite => 'Lời mời dance-pop';

  @override
  String get inspirationNameHappyBirthday => 'Chúc mừng sinh nhật';

  @override
  String get inspirationStyleHappyBirthday =>
      'Bài hát sinh nhật acoustic ấm áp';

  @override
  String get inspirationNameFriendAppreciation => 'Cảm ơn bạn bè';

  @override
  String get inspirationStyleFriendAppreciation => 'Indie pop dễ chịu';

  @override
  String get inspirationNameLoveStory => 'Chuyện tình';

  @override
  String get inspirationStyleLoveStory => 'Ballad R&B lãng mạn';

  @override
  String get inspirationNameBirthdayRoast => 'Sinh nhật cà khịa';

  @override
  String get inspirationStyleBirthdayRoast =>
      'Bài sinh nhật tinh nghịch hài hước';

  @override
  String get inspirationNameOdeToYourPet => 'Bài ca cho thú cưng';

  @override
  String get inspirationStyleOdeToYourPet => 'Pop dễ thương, nhún nhảy';

  @override
  String get inspirationNameHometownTribute => 'Tri ân quê hương';

  @override
  String get inspirationStyleHometownTribute => 'Dân ca hoài niệm';

  @override
  String get inspirationNameWeatherReport => 'Bản tin thời tiết';

  @override
  String get inspirationStyleWeatherReport => 'Giai điệu lounge vui tươi';

  @override
  String get inspirationNameBusinessPromo => 'Quảng bá kinh doanh';

  @override
  String get inspirationStyleBusinessPromo => 'Pop doanh nghiệp tự tin';

  @override
  String get inspirationStyleBirthdayWish =>
      'Bài hát chân thành cho ngày đặc biệt';

  @override
  String get inspirationStyleBirthdayParty =>
      'Bài ca tiệc tùng sôi động cho nhân vật chính';

  @override
  String get inspirationStyleThankAFriend => 'Bài hát cảm ơn ấm áp, chân thành';

  @override
  String get inspirationStyleWedding =>
      'Bài hát vui tươi, lãng mạn cho ngày trọng đại';

  @override
  String get inspirationStyleInMemory => 'Lời tưởng nhớ dịu dàng, đầy hy vọng';

  @override
  String get inspirationStyleFestival => 'Lời chúc mùa lễ hội tươi sáng';

  @override
  String get inspirationStylePetAnthem =>
      'Giai điệu đáng yêu, tung tăng cho thú cưng';

  @override
  String get inspirationStyleHometown => 'Bài ca quê hương tự hào và hoài niệm';

  @override
  String get settingsSectionLanguage => 'Ngôn ngữ';

  @override
  String get settingsSectionProfile => 'Hồ sơ';

  @override
  String get settingsCredits => 'Tín dụng';

  @override
  String get settingsAccountId => 'ID tài khoản';

  @override
  String get settingsCopyAccountId => 'Sao chép ID tài khoản';

  @override
  String get devSectionTitle => 'Nhà phát triển (chỉ DEV)';

  @override
  String get devKeychainReset => 'Xóa khóa Keychain';

  @override
  String get devKeychainResetHint => 'ID thiết bị và token phiên';

  @override
  String get devKeychainResetConfirmTitle => 'Xóa khóa Keychain?';

  @override
  String get devKeychainResetConfirmBody =>
      'ID thiết bị và token phiên sẽ bị xóa khỏi Keychain. Không thể khôi phục tài khoản khách hiện tại; ứng dụng sẽ đăng nhập bằng khách mới.';

  @override
  String get devKeychainResetDone =>
      'Đã xóa khóa Keychain — đăng nhập bằng khách mới';

  @override
  String get settingsAppLanguage => 'Ngôn ngữ ứng dụng';

  @override
  String get settingsLanguageSystem => 'Theo ngôn ngữ hệ thống';

  @override
  String settingsLanguageSystemValue(String language) {
    return 'Hệ thống ($language)';
  }

  @override
  String get settingsLanguageNativeName => 'Tiếng Việt';

  @override
  String get settingsLanguageSaveFailed =>
      'Không lưu được ngôn ngữ. Hãy thử lại.';

  @override
  String get settingsLyricsLanguageHint => 'Áp dụng cho bài hát mới.';

  @override
  String composerRemoveInspiration(String name) {
    return 'Bỏ $name';
  }

  @override
  String get composerPromptHint => 'Mô tả bài hát hoặc chọn một ý tưởng ở trên';

  @override
  String get composerPromptHintWide => 'Mô tả bài hát hoặc chọn một ý tưởng';

  @override
  String get composerWordsLabel => 'Lời của bạn';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã thêm $countString ảnh',
      one: 'Đã thêm $countString ảnh',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return 'Tùy chọn bài hát: $summary';
  }

  @override
  String get composerOptionsShow => 'Hiện tùy chọn';

  @override
  String get composerOptionsHide => 'Ẩn tùy chọn';

  @override
  String get composerSummaryAnyVocals => 'Giọng bất kỳ';

  @override
  String get composerSummaryAnyGenre => 'Thể loại bất kỳ';

  @override
  String get composerSummaryLyrics => 'Lời tự viết';

  @override
  String get composerSummaryVideo => 'Video lời bài hát';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Tạo bản nghe thử · miễn phí',
      'preview': 'Tạo bản nghe thử · 1 lượt',
      'other': 'Tạo bản nghe thử',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Tạo bản nghe thử cho $name · miễn phí',
      'preview': 'Tạo bản nghe thử cho $name · 1 lượt',
      'other': 'Tạo bản nghe thử cho $name',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': 'Tạo bài hát đầy đủ · 1 bài',
      'other': 'Tạo bài hát đầy đủ',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => 'Dùng văn bản này';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level bắt đầu sau $seconds giây';
  }

  @override
  String planPerWeek(String price) {
    return '$price/tuần';
  }

  @override
  String get planCreditsWeekly => 'Tín dụng mới mỗi tuần';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'ngày đầu tiên',
      'week': 'tuần đầu tiên',
      'month': 'tháng đầu tiên',
      'year': 'năm đầu tiên',
      'other': 'kỳ đầu tiên',
    });
    return 'Giảm $percent% cho $_temp0';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return 'Sau mức giá giới thiệu $introPrice, bạn sẽ bị tính $pricePerPeriod tự động. Hủy bất cứ lúc nào trước khi gia hạn.';
  }

  @override
  String get storePreviewAHook => 'Bắt đầu từ tên người ấy';

  @override
  String get storePreviewAWords => 'Ba từ về người ấy';

  @override
  String get storePreviewAWait => 'Bài hát đang được viết';

  @override
  String get storePreviewAChorus => 'Tên người ấy trong điệp khúc';

  @override
  String get storePreviewAEnd => 'Bài hát mang tên người ấy';

  @override
  String get storePreviewBHook => 'Bắt đầu từ ảnh của bạn';

  @override
  String get storePreviewBVideo => 'Thêm video lời bài hát';

  @override
  String get storePreviewBWait => 'Đang viết bài hát';

  @override
  String get storePreviewBLyrics => 'Lời hát chạy theo nhạc';

  @override
  String get storePreviewBMood => 'Ảnh tạo nên không khí.';

  @override
  String get storePreviewBShare => 'Chia sẻ video.';

  @override
  String get storePreviewBLanguage => 'Lời hát bằng tiếng của bạn';

  @override
  String get storePreviewAShare => 'Gửi dưới dạng thiệp';

  @override
  String get storePreviewCta => 'Viết bài hát đầu tiên';

  @override
  String get storePreviewDisclosure => 'Cần gói đăng ký hoặc tín dụng';

  @override
  String get storeCreativeHeader => 'Bài hát cho người bạn thương';

  @override
  String get storeCreativeSearch => 'Biến một cái tên thành bài hát';

  @override
  String get storeCreativeBirthday => 'Bài hát sinh nhật có tên người ấy';

  @override
  String get storeCreativePhoto => 'Ảnh của bạn thành bài hát';

  @override
  String get storeCreativeWedding => 'Bài hát cho ngày cưới của bạn';
}
