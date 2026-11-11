// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonCancel => '취소';

  @override
  String get startupLoading => '튜닝 중…';

  @override
  String get commonErrorTitle => '문제가 발생했습니다';

  @override
  String get updateRequiredTitle => '업데이트 필요';

  @override
  String get updateRequiredMessage => '계속하려면 새 버전이 필요합니다.';

  @override
  String get updateNow => '지금 업데이트';

  @override
  String get maintenanceTitle => '정기 점검 중';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '약 $minutesString분 후 재개 예정';
  }

  @override
  String get featureUnavailable => '이 기능은 일시적으로 사용할 수 없습니다.';

  @override
  String get navProfile => '프로필';

  @override
  String get navStore => '스토어';

  @override
  String get navUpload => '업로드';

  @override
  String get uploadTitle => '업로드';

  @override
  String get uploadSubtitle => '해시 계산, 즉시 중복 제거, 진행률 표시를 지원하는 R2 사전 서명 직접 업로드.';

  @override
  String get uploadPick => '이미지 선택 후 업로드';

  @override
  String get uploadAgain => '다른 파일 업로드';

  @override
  String get uploadPhaseHashing => '해시 계산 중…';

  @override
  String get uploadPhaseSigning => '업로드 권한 요청 중…';

  @override
  String uploadPhaseUploading(String percent) {
    return '업로드 중 $percent';
  }

  @override
  String get uploadPhaseFinalizing => '마무리 중…';

  @override
  String get uploadDone => '업로드되었습니다.';

  @override
  String get uploadDedup => '즉시 완료: 이미 서버에 있는 파일입니다.';

  @override
  String get uploadOpenLink => '파일 보기';

  @override
  String get uploadFailed => '업로드에 실패했습니다.';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '파일이 너무 큽니다(최대 ${limitString}MB).';
  }

  @override
  String get uploadUnsupportedType => '지원하지 않는 파일 형식입니다.';

  @override
  String get profileGuestTitle => '게스트';

  @override
  String get profileGuestSubtitle => '로그인하면 여러 기기에서 구입 항목을 유지할 수 있습니다.';

  @override
  String get signIn => '로그인';

  @override
  String get signOut => '로그아웃';

  @override
  String get profileBalanceLabel => '크레딧';

  @override
  String get profileAccountId => '계정 ID';

  @override
  String get profileFeaturesLabel => '활성 혜택';

  @override
  String get profileNoFeatures => '아직 활성 혜택이 없습니다.';

  @override
  String get profileSubscriptionLabel => '구독';

  @override
  String get profileManageSubscription => '구독 관리';

  @override
  String get subscriptionActive => '활성';

  @override
  String get subscriptionInactive => '없음';

  @override
  String get profileDeleteAccount => '계정 삭제';

  @override
  String get deleteAccountTitle => '이 계정을 삭제하시겠습니까?';

  @override
  String get deleteAccountMessage =>
      '이 작업은 되돌릴 수 없습니다. 이 계정과 크레딧 및 혜택 기록에 영구적으로 접근할 수 없게 되며, 새 계정이 생성됩니다. 활성 상태인 App Store 구독은 계정을 삭제해도 취소되지 않습니다. App Store 설정에서 관리하거나, 나중에 \'구입 항목 복원\'으로 다시 연결하세요.';

  @override
  String get deleteAccountConfirm => '삭제';

  @override
  String get deleteAccountWorking => '계정 삭제 중…';

  @override
  String get deleteAccountDone => '계정이 삭제되었습니다.';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString부터 회원';
  }

  @override
  String get loginTitle => '로그인';

  @override
  String get loginUsername => '사용자 이름';

  @override
  String get loginPassword => '비밀번호';

  @override
  String get loginSubmit => '로그인';

  @override
  String get paywallTitle => '전체 노래 받기';

  @override
  String get paywallSubtitle =>
      '미리 듣기를 가사가 있는 2분짜리 노래로 완성하세요. 다운로드해서 자유롭게 사용할 수 있어요.';

  @override
  String get paywallRestore => '구입 항목 복원';

  @override
  String get paywallAutoRenewNotice =>
      '구입 확인 시 Apple 계정으로 요금이 청구됩니다. 현재 기간이 끝나기 최소 24시간 전에 취소하지 않으면 구독은 동일한 가격과 기간으로 자동 갱신됩니다. 무료 체험이 끝나면 유료 구독으로 전환됩니다. App Store 계정 설정에서 언제든지 관리하거나 취소할 수 있습니다.';

  @override
  String get paywallContinue => '계속';

  @override
  String get paywallFreeTrial => '무료 체험';

  @override
  String get paywallOffer => '특가';

  @override
  String get paywallManage => '관리';

  @override
  String get paywallTermsOfUse => '이용 약관';

  @override
  String get paywallPrivacyPolicy => '개인정보 처리방침';

  @override
  String get paywallSubscriptionTerms => '구독 약관';

  @override
  String get commonLinkError => '링크를 열 수 없습니다.';

  @override
  String get commonError => '문제가 발생했습니다.';

  @override
  String get commonNetworkError => '네트워크 오류입니다. 연결 상태를 확인하고 다시 시도하세요.';

  @override
  String get commonOfflineError => '오프라인 상태인 것 같습니다. 연결 상태를 확인하고 다시 시도하세요.';

  @override
  String get networkErrorTitle => '연결 문제';

  @override
  String get configErrorTitle => '앱 구성 문제';

  @override
  String get configErrorMessage =>
      '이 버전은 서비스에 연결할 수 없습니다. App Store에서 앱을 업데이트하거나 다시 설치하세요. 문제가 계속되면 고객 지원에 문의하세요.';

  @override
  String get commonAuthError => '세션이 만료되었습니다. 다시 로그인하세요.';

  @override
  String get paywallProductsErrorTitle => '상품을 불러올 수 없습니다';

  @override
  String get paywallNoProducts => '지금은 구입할 수 있는 상품이 없습니다.';

  @override
  String get paywallPurchaseSuccess => '구입 완료! 즐겁게 감상하세요!';

  @override
  String get paywallProcessing => '구입을 처리하는 중…';

  @override
  String get paywallVerifying => '구입을 확인하는 중…';

  @override
  String get paywallPurchaseFailed => '구입을 완료할 수 없습니다.';

  @override
  String get paywallRestoreStarted => '구입 항목을 복원하는 중…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '구입 항목 $countString개를 복원했습니다.',
      one: '구입 항목 $countString개를 복원했습니다.',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => '복원할 구입 항목이 없습니다.';

  @override
  String get paywallDeferred => '승인을 기다리는 중입니다. 승인되면 구입을 완료합니다.';

  @override
  String get paywallAlreadySubscribed => '이미 구독 중입니다.';

  @override
  String get paywallBillingRetry => '구독을 유지하려면 결제 수단을 업데이트하세요.';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString일 무료 체험';
  }

  @override
  String get cycleOneTime => '1회 구입';

  @override
  String get cycleWeekly => '/ 주';

  @override
  String get cycleMonthly => '/ 월';

  @override
  String get cycleQuarterly => '/ 분기';

  @override
  String get cycleSemiAnnual => '/ 6개월';

  @override
  String get cycleAnnual => '/ 년';

  @override
  String get cycleLifetime => '평생';

  @override
  String get navCreate => '만들기';

  @override
  String get navLibrary => '보관함';

  @override
  String get navSettings => '설정';

  @override
  String get commonContinue => '계속';

  @override
  String get commonBack => '뒤로';

  @override
  String get createTitle => '누구를 위한 노래인가요?';

  @override
  String get occasionBirthday => '생일';

  @override
  String get occasionBirthdayHint => '특별한 날을 위한 신나는 노래';

  @override
  String get occasionAnniversary => '기념일';

  @override
  String get occasionAnniversaryHint => '두 사람의 이야기를 축하해요';

  @override
  String get occasionConfession => '사랑 고백';

  @override
  String get occasionConfessionHint => '마음속 이야기를 전해요';

  @override
  String get occasionWedding => '결혼식';

  @override
  String get occasionWeddingHint => '영원한 순간을 위한 노래';

  @override
  String get occasionMemorial => '추모';

  @override
  String get occasionMemorialHint => '소중한 사람을 기려요';

  @override
  String get occasionFestival => '명절';

  @override
  String get occasionFestivalHint => '특별한 시즌에 전하는 따뜻한 인사';

  @override
  String get occasionBrand => '브랜드 징글';

  @override
  String get occasionBrandHint => '브랜드를 위한 귀에 쏙 들어오는 멜로디';

  @override
  String get occasionSoundtrack => '영상 배경음악';

  @override
  String get occasionSoundtrackHint => '이야기에 어울리는 음악';

  @override
  String get festivalNewYear => '새해';

  @override
  String get festivalThanksgiving => '추수감사절';

  @override
  String get festivalDiwali => '디왈리';

  @override
  String get festivalCarnival => '카니발';

  @override
  String get festivalEid => '이드';

  @override
  String get festivalLunarNewYear => '설날';

  @override
  String get regionTitle => '어디에서 듣게 될 노래인가요?';

  @override
  String get regionSearchHint => '국가 검색';

  @override
  String get regionLanguageSheetTitle => '가사 언어';

  @override
  String get countryUS => '미국';

  @override
  String get countryGB => '영국';

  @override
  String get countryCA => '캐나다';

  @override
  String get countryAU => '호주';

  @override
  String get countryDE => '독일';

  @override
  String get countryFR => '프랑스';

  @override
  String get countryJP => '일본';

  @override
  String get countryKR => '대한민국';

  @override
  String get countryBR => '브라질';

  @override
  String get countryMX => '멕시코';

  @override
  String get countryIN => '인도';

  @override
  String get countryID => '인도네시아';

  @override
  String get countryVN => '베트남';

  @override
  String get countryTR => '튀르키예';

  @override
  String get languageEn => '영어';

  @override
  String get languageFr => '프랑스어';

  @override
  String get languageDe => '독일어';

  @override
  String get languageJa => '일본어';

  @override
  String get languageKo => '한국어';

  @override
  String get languagePtBR => '포르투갈어(브라질)';

  @override
  String get languageEsMX => '스페인어(멕시코)';

  @override
  String get languageHi => '힌디어';

  @override
  String get languageId => '인도네시아어';

  @override
  String get languageVi => '베트남어';

  @override
  String get languageTr => '튀르키예어';

  @override
  String get languageZhHans => '중국어(간체)';

  @override
  String get languageZhHant => '중국어(번체)';

  @override
  String get inputNameLabel => '상대방 이름';

  @override
  String get inputNameOptionalLabel => '이름(선택)';

  @override
  String get inputNameHint => '예: 지민';

  @override
  String get inputKeywordsLabel => '그 사람을 표현하는 세 단어';

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
  String get inputLyricsOwnership => '직접 쓴 가사이거나 사용할 권리가 있는 가사입니다';

  @override
  String get issueRecipientMissing => '이름을 입력하세요.';

  @override
  String get issueRecipientTooLong => '이름은 최대 24자까지 입력할 수 있습니다.';

  @override
  String get issueBriefMissing => '어떤 노래인지 알려 주세요 — 몇 마디, 가사 또는 사진.';

  @override
  String get issueDescriptionMissing =>
      '이 아이디어에는 당신의 말이 필요해요 — 노래에 대해 한 줄 적어 주세요.';

  @override
  String get generatingBackToEdit => '수정하러 돌아가기';

  @override
  String get issueKeywordTooLong => '각 단어는 최대 20자까지 입력할 수 있습니다.';

  @override
  String get issueTooManyKeywords => '단어는 최대 세 개까지 사용할 수 있습니다.';

  @override
  String get issueArtistName => '아티스트 이름은 사용할 수 없습니다. 대신 느낌을 표현해 보세요.';

  @override
  String get issueStyleImitation => '특정 가수나 밴드를 모방할 수 없습니다. 대신 분위기를 표현해 보세요.';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '가사는 최대 $limitString자까지 입력할 수 있습니다.';
  }

  @override
  String get issueLyricsNotOriginal => '기존 노래의 가사와 비슷해 보입니다. 직접 쓴 가사를 입력하세요.';

  @override
  String get issueLyricsOwnership => '가사를 사용할 권리가 있는지 확인하세요.';

  @override
  String get issueTooManyPhotos => '사진은 최대 10장까지 선택할 수 있습니다.';

  @override
  String get photosTitle => '사진을 몇 장 골라 주세요';

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
  String get photosPrivacy => '사진은 노래를 만드는 데 한 번만 사용되며 24시간 이내에 서버에서 삭제됩니다.';

  @override
  String get photosAdd => '사진 추가';

  @override
  String get photosCreate => '사진으로 만들기';

  @override
  String get photosEmpty => '그 순간을 담은 사진을 1~10장 선택하세요.';

  @override
  String get generatingStepPolishing => '이 iPhone에서 문장을 다듬는 중…';

  @override
  String get generatingStepUploading => '사진을 보내는 중…';

  @override
  String get generatingStepSubmitting => '스튜디오로 보내는 중…';

  @override
  String get errorSafetyBlocked =>
      '이 노래는 만들 수 없습니다. 다른 단어로 시도해 보고, 아티스트 이름은 빼 주세요.';

  @override
  String get errorQuotaExhausted => '이번 달 노래를 모두 사용했습니다. 팩을 추가하거나 업그레이드하세요.';

  @override
  String get errorUpstreamTimeout => '평소보다 오래 걸리고 있습니다. 계속 시도하고 알려 드릴게요.';

  @override
  String get errorUpstreamRateLimited =>
      '지금 많은 노래가 만들어지고 있습니다. 회원님의 노래는 대기열에 있습니다.';

  @override
  String get errorAttestFailed => 'App Store에서 Songlet을 업데이트하세요.';

  @override
  String get errorImageRejected => '사용할 수 없는 사진이 있습니다. 다른 사진을 사용해 보세요.';

  @override
  String get errorNetworkOffline => '오프라인 상태입니다. 보관함은 계속 사용할 수 있습니다.';

  @override
  String get errorDownloadLocked =>
      '이 노래는 다운로드할 수 없습니다. 이 노래를 만든 구입 항목이 환불되었거나 플랜이 종료되었습니다. 재생은 계속할 수 있습니다.';

  @override
  String get errorJobAlreadyFinished => '이미 완성되어 취소할 필요가 없어요.';

  @override
  String get errorMvSongNotReady => '이 노래는 아직 비디오를 만들 준비가 되지 않았어요.';

  @override
  String get errorMvSongTooLong =>
      '이 노래는 전체 비디오로 만들기엔 너무 길어요. 후렴 비디오를 시도해 보세요.';

  @override
  String get errorMvSongExpired => '이 노래는 만료되었어요. 다시 생성한 뒤 비디오를 만들어 주세요.';

  @override
  String get errorMvNotFound => '이 비디오는 더 이상 사용할 수 없어요.';

  @override
  String get errorMvPhotosExpired => '사진이 만료되었어요. 다시 선택해 주세요.';

  @override
  String get errorMvRenderFailed =>
      '이 비디오를 완성하지 못했어요. 크레딧은 돌려드렸어요. 다시 시도해 주세요.';

  @override
  String get mvHubTitle => '비디오 만들기';

  @override
  String mvHubSubtitle(String title) {
    return '‘$title’을(를) 뮤직비디오로 만들어 보세요.';
  }

  @override
  String get mvLevelLyricVideo => '가사 비디오';

  @override
  String get mvLevelLyricHint => '가사가 흐르는 한 장면';

  @override
  String get mvLevelChorus => '후렴 비디오';

  @override
  String get mvLevelChorusHint => '후렴 30초를 AI가 촬영';

  @override
  String get mvLevelFull => '전체 곡 비디오';

  @override
  String get mvLevelFullHint => '곡 전체를 장면별로';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString 크레딧',
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
      other: '보유 크레딧 $creditsString',
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
      other: '$creditsString 크레딧 더 필요',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => '가격을 확인하는 중…';

  @override
  String get mvOptionsHeader => '옵션';

  @override
  String get mvAspectLabel => '화면 비율';

  @override
  String get mvAspectPortrait => '세로';

  @override
  String get mvAspectLandscape => '가로';

  @override
  String get mvAspectSquare => '정사각형';

  @override
  String get mvQualityLabel => '화질';

  @override
  String get mvQualityStandard => '표준';

  @override
  String get mvQualityHigh => '고화질';

  @override
  String get mvSubtitlesLabel => '화면에 가사 표시';

  @override
  String get mvPhotosLabel => '참고 사진';

  @override
  String get mvPhotosHint => '분위기와 색감만 참고해요 — 얼굴은 사용하지 않아요';

  @override
  String mvPhotosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString장',
    );
    return '$_temp0';
  }

  @override
  String get mvChorusLabel => '후렴';

  @override
  String get mvChorusAuto => '자동으로 찾기';

  @override
  String get mvChorusCustom => '직접 고르기';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => '비디오 만들기';

  @override
  String get mvBuyPack => '팩을 구입하고 만들기';

  @override
  String get mvSongLocked => '이 노래는 비디오용으로 저장되었어요.';

  @override
  String get mvGeneratingTitle => '비디오를 만드는 중…';

  @override
  String get mvStageQueued => '시작 대기 중';

  @override
  String get mvStageSlicing => '장면 고르는 중';

  @override
  String get mvStageStoryboarding => '스토리보드 작성 중';

  @override
  String get mvStageKeyframing => '장면 그리는 중';

  @override
  String get mvStageRendering => '장면 촬영 중';

  @override
  String get mvStageAssembling => '편집하는 중';

  @override
  String get mvStageDone => '완료';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '장면 $doneString/$totalString';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '보통 약 $minutesString분';
  }

  @override
  String get mvCancelRequested => '현재 장면 후에 중단됩니다…';

  @override
  String get mvCancelTitle => '이 비디오를 중단할까요?';

  @override
  String get mvCancelQueued => '아직 시작하지 않아 아무것도 사용되지 않아요.';

  @override
  String get mvCancelStarted => '이미 시작되었어요. 완성된 장면은 차감되고 나머지는 돌려드려요.';

  @override
  String get mvCancelConfirm => '비디오 중단';

  @override
  String get mvCancelled => '비디오를 중단했어요';

  @override
  String get mvCancelledRefunded => '비디오를 중단했어요 — 아무것도 사용되지 않았어요';

  @override
  String get mvNothing => '지금 만들고 있는 비디오가 없어요.';

  @override
  String get mvQuotaTitle => '크레딧이 부족해요';

  @override
  String get mvAiLabelBurnedIn => 'AI 생성 — 배지가 영상에 포함되어 있어요';

  @override
  String get mvSave => '사진에 저장';

  @override
  String get mvSaveFiles => '파일에 저장';

  @override
  String get mvShareText => 'Songlet으로 이 뮤직비디오를 만들었어요 🎬';

  @override
  String get mvMissing => '이 비디오는 더 이상 이 기기에 없어요.';

  @override
  String get mvDeleteTitle => '이 비디오를 삭제할까요?';

  @override
  String get mvDeleteBody => '이 기기에서 삭제돼요.';

  @override
  String get mvDeleted => '비디오를 삭제했어요';

  @override
  String get mvProvenance => 'Google Lyria 3와 AI 영상 모델로 제작 · AI 생성';

  @override
  String get detailVideos => '비디오';

  @override
  String get detailMakeVideo => '비디오 만들기';

  @override
  String get mvStatusReady => '완료';

  @override
  String get mvStatusPending => '만드는 중…';

  @override
  String get mvStatusFailed => '완료되지 않음';

  @override
  String get mvPackTitle => '뮤직비디오';

  @override
  String get mvPackChorusSubtitle => '후렴 비디오 1개';

  @override
  String get mvPackFullSubtitle => '전체 곡 비디오 1개';

  @override
  String get paywallMvHeroTitle => '비디오로 만들기';

  @override
  String get paywallMvHeroSubtitle => '내 노래로 뮤직비디오를 만들 크레딧 — 저장하고 공유하세요.';

  @override
  String get playerAiGenerated => 'AI 생성';

  @override
  String get playerLoop => '반복 재생';

  @override
  String get playerPlay => '재생';

  @override
  String get playerPause => '일시 정지';

  @override
  String get playerPreviewLabel => '30초 미리 듣기';

  @override
  String playerTitleFor(String name) {
    return '$name에게';
  }

  @override
  String get downloadSaved => '\'파일\'에 저장했습니다.';

  @override
  String get shareComposing => '공유 카드를 만드는 중…';

  @override
  String get shareFailed => '공유 카드를 만들 수 없습니다.';

  @override
  String get shareText => 'Songlet으로 이 노래를 만들었어요 🎵';

  @override
  String get paywallBestValue => '최고 가성비';

  @override
  String get paywallStartTrial => '무료 체험 시작';

  @override
  String get paywallClose => '닫기';

  @override
  String get paywallSeePlans => '구독 보기';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '요금제가 활성 상태입니다. 이번 기간에 전체 노래 $countString곡이 남았습니다.',
      one: '요금제가 활성 상태입니다. 이번 기간에 전체 노래 $countString곡이 남았습니다.',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => '만든 노래가 여기에 보관됩니다.';

  @override
  String get libraryEmptyAction => '첫 노래 만들기';

  @override
  String get libraryPending => '작곡 중…';

  @override
  String get libraryPreviewBadge => '미리 듣기';

  @override
  String get librarySongBadge => '전체 노래';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsPlan => '내 요금제';

  @override
  String get settingsPlanUnavailable => '요금제를 불러올 수 없습니다. 잠시 후 당겨서 다시 시도하세요.';

  @override
  String get tierFree => '구독 없음';

  @override
  String get tierPack => '노래 팩';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '전체 노래 $countString곡 남음',
      one: '전체 노래 $countString곡 남음',
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
      other: '미리 듣기 $countString회 남음',
      one: '미리 듣기 $countString회 남음',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString에 초기화';
  }

  @override
  String get settingsUpgrade => '업그레이드';

  @override
  String get appTagline => '사랑하는 사람을 위한 노래';

  @override
  String get commonClose => '닫기';

  @override
  String get commonDone => '완료';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonMore => '더 보기';

  @override
  String get commonCopy => '복사';

  @override
  String get commonCopied => '복사됨';

  @override
  String get commonNotNow => '나중에';

  @override
  String get commonLearnMore => '자세히 알아보기';

  @override
  String get commonSeeAll => '모두 보기';

  @override
  String get commonKeepGoing => '계속하기';

  @override
  String get composerHint => '원하는 노래를 설명해 주세요';

  @override
  String get composerAddPhotos => '사진 추가';

  @override
  String get composerSourceMusicHint => '내 말로 설명하기';

  @override
  String get composerDictate => '음성 입력';

  @override
  String get composerStopDictation => '음성 입력 중지';

  @override
  String get lengthPreview => '미리 듣기';

  @override
  String get lengthFull => '전체 노래';

  @override
  String get paramLength => '길이';

  @override
  String get paramVocals => '보컬';

  @override
  String get paramGenre => '장르';

  @override
  String templatePlaySample(String name) {
    return '$name 샘플 재생';
  }

  @override
  String get templatePauseSample => '샘플 일시 정지';

  @override
  String get lengthShort => '짧게';

  @override
  String get lengthShortHint => '30초 미리 듣기';

  @override
  String get lengthStandard => '기본';

  @override
  String get lengthStandardHint => '약 2분, Pro';

  @override
  String get vocalsCustom => '자동';

  @override
  String get vocalsCustomHint => '설명에 맞춤';

  @override
  String get vocalsCustomDetail => '보컬 스타일은 설명에 맞춰집니다.';

  @override
  String get vocalsOn => '보컬 있음';

  @override
  String get vocalsInstrumental => '연주곡';

  @override
  String vocalsLyricsIn(String language) {
    return '가사 언어: $language';
  }

  @override
  String get genreCustom => '자동';

  @override
  String get genreCustomHint => '설명에 맞춤';

  @override
  String genrePopularIn(String country) {
    return '$country 인기';
  }

  @override
  String get genreAll => '모든 장르';

  @override
  String get regionHelper => '추천 장르 3개와 가사 언어가 바뀝니다';

  @override
  String regionLyricsRow(String language) {
    return '가사 언어: $language';
  }

  @override
  String get regionNoMatch => '일치하는 국가가 없습니다';

  @override
  String get keywordAdd => '단어 추가';

  @override
  String keywordRemove(String word) {
    return '$word 삭제';
  }

  @override
  String get nameClear => '이름 지우기';

  @override
  String get lyricsOptional => '직접 가사 쓰기 (선택)';

  @override
  String get issueRecipientArtistName => '아티스트 이름은 사용할 수 없습니다.';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '설명은 $limitString자 이내로 써 주세요.';
  }

  @override
  String get voiceRecording => '녹음 중…';

  @override
  String get voiceStarting => '시작하는 중…';

  @override
  String get voiceListening => '누구를 위한 노래인지, 그 사람이 좋아하는 것을 말해 주세요…';

  @override
  String get voiceOnDevice => '기기에서 받아쓰기';

  @override
  String get voicePermissionDenied =>
      '음성 입력을 하려면 설정에서 Songlet의 마이크와 음성 인식을 허용하세요.';

  @override
  String get voiceUnavailable => '이 기기에서는 이 언어의 음성 입력을 사용할 수 없습니다.';

  @override
  String get voiceApplied => '음성으로 추가했습니다';

  @override
  String get photoRemove => '사진 삭제';

  @override
  String generatingTitleFor(String name) {
    return '$name님의 노래를 쓰는 중…';
  }

  @override
  String get generatingTitleGeneric => '노래를 쓰는 중…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '보통 약 $secondsString초';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => '진행률';

  @override
  String get generatingGlimpse => '노래 살짝 엿보기';

  @override
  String get generatingCancelTitle => '이 노래를 중지할까요?';

  @override
  String get generatingCancelQueued => '아직 시작되지 않아 이용 횟수가 차감되지 않습니다.';

  @override
  String get generatingCancelStarted => '이미 시작되어 이용 횟수가 차감됩니다.';

  @override
  String get generatingCancelConfirm => '중지';

  @override
  String get generatingCancelled => '중지했습니다';

  @override
  String get generatingCancelledRefunded => '중지했습니다 — 차감 없음';

  @override
  String get queueTitle => '지금 많은 노래가 만들어지고 있어요.';

  @override
  String get queueSubtitle => '대기 중입니다.';

  @override
  String get queuePosition => '대기 순서';

  @override
  String get queueWait => '예상 대기 시간';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '약 $minutesString분';
  }

  @override
  String get generatingNothing => '지금 만들고 있는 노래가 없습니다.';

  @override
  String get previewGetFull => '2분 전체 노래 만들기';

  @override
  String get previewShare => '미리 듣기 공유';

  @override
  String get previewAnother => '다른 버전 만들기 (미리 듣기 1회 사용)';

  @override
  String get playerPosition => '재생 위치';

  @override
  String get playerPrevSection => '이전 구간';

  @override
  String get playerNextSection => '다음 구간';

  @override
  String get playerShuffle => '구간 셔플';

  @override
  String get playerRepeat => '반복';

  @override
  String get playerProvenance => 'Google Lyria 3로 제작 · SynthID 워터마크 · AI 생성';

  @override
  String get playerMissing => '이 노래가 더 이상 이 기기에 없습니다.';

  @override
  String get actionDownload => '다운로드';

  @override
  String get actionShare => '공유';

  @override
  String get actionLicense => '라이선스';

  @override
  String get actionRegenerate => '다시 만들기';

  @override
  String get actionDetails => '세부 정보';

  @override
  String get sectionIntro => '인트로';

  @override
  String get sectionVerse => '벌스';

  @override
  String get sectionPreChorus => '프리코러스';

  @override
  String get sectionChorus => '코러스';

  @override
  String get sectionBridge => '브리지';

  @override
  String get sectionOutro => '아웃트로';

  @override
  String get sectionHook => '훅';

  @override
  String get shareTitle => '공유 카드';

  @override
  String get shareSubtitle => '테마와 레이아웃을 고르세요.';

  @override
  String get shareTheme => '테마';

  @override
  String get shareLayout => '레이아웃';

  @override
  String get shareLayoutScene => '일러스트 포함';

  @override
  String get shareLayoutText => '텍스트만';

  @override
  String get paletteTerracotta => '테라코타';

  @override
  String get paletteSand => '샌드';

  @override
  String get paletteOlive => '올리브';

  @override
  String get paletteNavy => '네이비';

  @override
  String get shareAction => '공유';

  @override
  String get shareSaveVideo => '동영상 저장';

  @override
  String get shareCopyLyrics => '가사 복사';

  @override
  String get shareVideoSaved => '사진에 저장했습니다';

  @override
  String get shareLyricsCopied => '가사를 복사했습니다';

  @override
  String get shareCardTagline => '누군가를 위한 노래';

  @override
  String get shareSaveFailed =>
      '동영상을 저장하지 못했습니다. 설정에서 Songlet이 사진에 추가하도록 허용하세요.';

  @override
  String get downloadReady => '전체 노래 완성';

  @override
  String get downloadTitle => '영원히 당신의 것';

  @override
  String get downloadIntro => '노래가 완성되었습니다. 아래에서 고음질 오디오와 상업용 라이선스를 받으세요.';

  @override
  String get downloadAudioHeader => '오디오 다운로드';

  @override
  String get downloadAudioNote => '고음질';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle => '공유와 일상 감상에 적합';

  @override
  String get downloadWavTitle => 'WAV · 44.1 kHz (Premier)';

  @override
  String get downloadWavSubtitle => '전문가용 최고 음질';

  @override
  String get downloadMp3Action => 'MP3 다운로드';

  @override
  String get downloadWavAction => 'WAV 다운로드';

  @override
  String get downloadLicenseAction => '라이선스 다운로드';

  @override
  String get licenseHeader => '상업용 라이선스';

  @override
  String get licenseIncluded => '플랜에 포함됨';

  @override
  String get licenseNotIncluded => '플랜 또는 팩으로 이용 가능';

  @override
  String get licensePdfTitle => '상업용 라이선스 (PDF)';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString 발급';
  }

  @override
  String licenseId(String id) {
    return '라이선스 ID: $id';
  }

  @override
  String get licenseUsesTitle => '이 노래의 사용 범위:';

  @override
  String get usePersonal => '개인 용도';

  @override
  String get usePersonalDetail => '선물, 추억, 비상업적 용도';

  @override
  String get useAds => '광고 및 마케팅';

  @override
  String get useAdsDetail => '프로모션, 유료 캠페인';

  @override
  String get useSocial => '소셜 미디어';

  @override
  String get useSocialDetail => 'TikTok, Instagram, YouTube 등';

  @override
  String get usePodcasts => '팟캐스트 및 동영상';

  @override
  String get usePodcastsDetail => '수익 창출 콘텐츠';

  @override
  String get licenseDetailsNote => '자세한 내용은 라이선스 PDF를 확인하세요.';

  @override
  String get saveEnjoyHeader => '저장하고 즐기기';

  @override
  String get saveToFiles => '파일에 저장';

  @override
  String get addToMusic => '음악에 추가';

  @override
  String get synthIdNote =>
      '이 노래에는 SynthID 워터마크가 있어 다운로드 후에도 AI 생성 콘텐츠로 식별됩니다.';

  @override
  String get wavNeedsPremier => 'WAV 다운로드는 Premier에서 이용할 수 있습니다.';

  @override
  String get wavUnavailable =>
      '이 곡에는 WAV 파일이 없어요. WAV는 곡을 만든 후 24시간 이내에 저장할 수 있어요.';

  @override
  String get libraryFilterAll => '전체';

  @override
  String get libraryJustBecause => '그냥';

  @override
  String libraryPlay(String title) {
    return '$title 재생';
  }

  @override
  String libraryActions(String title) {
    return '$title 작업';
  }

  @override
  String get libraryDeleteTitle => '이 노래를 삭제할까요?';

  @override
  String get libraryDeleteBody =>
      '이 기기에서 삭제됩니다. iCloud 동기화가 켜져 있으면 다른 기기에서도 삭제됩니다.';

  @override
  String get libraryDeleted => '삭제했습니다';

  @override
  String get libraryFailed => '완성되지 않음';

  @override
  String get libraryNoMatch => '이 상황의 노래가 아직 없습니다.';

  @override
  String get detailFullGenerated => '전체 노래 생성됨';

  @override
  String get detailPreviewGenerated => '미리 듣기 생성됨';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString 생성';
  }

  @override
  String get detailPromptUsed => '사용한 프롬프트';

  @override
  String get detailOccasion => '상황';

  @override
  String get detailCountry => '국가';

  @override
  String get detailGenre => '장르';

  @override
  String get detailKeywords => '키워드';

  @override
  String get detailDescription => '설명';

  @override
  String get detailLyrics => '가사';

  @override
  String get detailGenerationId => '생성 ID';

  @override
  String get detailRegenerate => '같은 스타일로 다시 만들기';

  @override
  String get detailCustomGenre => '설명에 맞춤';

  @override
  String get settingsSectionPlan => '구입';

  @override
  String get settingsSectionLibrary => '보관함';

  @override
  String get settingsSectionAbout => '정보';

  @override
  String get settingsRestore => '구입 내역 복원';

  @override
  String get settingsManage => '구독 관리';

  @override
  String get settingsICloud => 'iCloud 동기화';

  @override
  String get settingsICloudOn => '노래가 기기 간에 동기화됩니다';

  @override
  String get settingsICloudOff => '노래는 이 기기에만 저장됩니다';

  @override
  String get settingsICloudUnavailable => '동기화하려면 설정에서 iCloud에 로그인하세요';

  @override
  String get settingsLyricsLanguage => '기본 가사 언어';

  @override
  String get settingsLyricsLanguageAuto => '국가에 맞춤';

  @override
  String get settingsTerms => '이용 약관';

  @override
  String get settingsPrivacy => '개인정보 처리방침';

  @override
  String settingsVersion(String version) {
    return '버전 $version';
  }

  @override
  String get aboutTitle => '생성 방식';

  @override
  String get aboutSubtitle => 'Songlet이 노래를 만드는 방법';

  @override
  String get aboutLyriaTitle => 'Google Lyria 3 기반';

  @override
  String get aboutLyriaBody =>
      '노래는 Gemini API를 통해 Google의 Lyria 3로 생성됩니다. Lyria 3는 아이디어를 오리지널 노래로 만드는 음악 생성 모델입니다.';

  @override
  String get aboutWatermarkTitle => '내장 워터마크';

  @override
  String get aboutWatermarkBody =>
      '모든 노래에는 Google의 SynthID 워터마크가 들어 있습니다. AI가 만든 음악임을 식별할 수 있으며 제거할 수 없습니다.';

  @override
  String get aboutImitationTitle => '실제 아티스트를 모방하지 않습니다';

  @override
  String get aboutImitationBody =>
      'Songlet은 실제 아티스트나 그 목소리, 특정 스타일을 모방하지 않습니다. 모든 노래는 당신의 아이디어, 설명, 사진으로 만든 오리지널입니다.';

  @override
  String get aboutPrivacyTitle => '개인정보 보호';

  @override
  String get aboutPrivacyBody =>
      '사진과 설명은 24시간 이내에 서버에서 삭제됩니다. 노래가 만들어진 후에는 이미지나 설명을 보관하지 않습니다.';

  @override
  String get aboutBanner => '공유하는 모든 노래에는 ‘AI 생성’ 표시가 붙습니다.';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · Google Lyria 3로 제작';
  }

  @override
  String get festivalKicker => '당신의 이야기를';

  @override
  String get festivalComing => '이 다가와요!';

  @override
  String get festivalBody => '세상에 하나뿐인 노래로 축하하세요.';

  @override
  String festivalCta(String festival) {
    return '$festival 노래 만들기';
  }

  @override
  String get festivalPickOccasion => '상황을 고르고 만들어 보세요';

  @override
  String get festivalLanguagesTitle => '내 언어로 부르는 노래';

  @override
  String festivalLanguagesBody(String language) {
    return '$language 외 12개 언어 지원';
  }

  @override
  String get unavailableTitle => '일시적으로 사용할 수 없음';

  @override
  String get unavailableMessage =>
      '지금은 Songlet이 노래를 만들 수 없습니다. 보관함은 계속 사용할 수 있으니 잠시 후 다시 시도하세요.';

  @override
  String get paywallHeroTitle => '전체 노래로 만들기';

  @override
  String get paywallHeroSubtitle => '아이디어를 더 높은 음질과 모든 권리를 갖춘 완전한 노래로.';

  @override
  String get paywallBenefitSongs => '더 많은 노래';

  @override
  String get paywallBenefitQuality => '더 높은 음질';

  @override
  String get paywallBenefitCommercial => '상업적 이용';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '매월 전체 노래 $countString곡',
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
      other: '매월 미리 듣기 $countString회',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'MP3 다운로드';

  @override
  String get planMp3Wav => 'MP3 + WAV 다운로드';

  @override
  String get planLicense => '상업용 라이선스';

  @override
  String get planPriority => '우선 생성';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString일 무료 체험';
  }

  @override
  String planPerYear(String price) {
    return '$price/년';
  }

  @override
  String planPerMonth(String price) {
    return '$price/월';
  }

  @override
  String get packTitle => '몇 곡만 필요하세요?';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString곡 팩',
    );
    return '$_temp0';
  }

  @override
  String get packNote => '기한 없음';

  @override
  String get valueForever => '내 노래는 영원히';

  @override
  String get valueDownloads => '고음질 다운로드';

  @override
  String get valueCommercial => '상업적 이용 가능';

  @override
  String get valuePrivate => '개인정보 우선';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return '무료 체험이 끝나면 $pricePerPeriod 요금이 자동 청구됩니다. 체험 종료 전 언제든지 취소할 수 있어요.';
  }

  @override
  String get paywallSubscribe => '구독하기';

  @override
  String get paywallBuyPack => '팩 구입';

  @override
  String get templateBirthdayWish => '생일 축하';

  @override
  String get templateBirthdayWishHint => '특별한 날을 위한 특별한 노래';

  @override
  String get templateBirthdayParty => '생일 파티';

  @override
  String get templateBirthdayPartyHint => '주인공을 위해 파티 분위기 업';

  @override
  String get templateLoveStory => '러브 스토리';

  @override
  String get templateLoveStoryHint => '두 사람의 이야기를 노래로';

  @override
  String get templateThankAFriend => '친구에게 고마워';

  @override
  String get templateThankAFriendHint => '말로 못 한 고마움을 노래로';

  @override
  String get templatePartyInvite => '파티 초대';

  @override
  String get templatePartyInviteHint => '모두를 파티로';

  @override
  String get templateWedding => '결혼식';

  @override
  String get templateWeddingHint => '두 사람의 영원한 순간을 위해';

  @override
  String get templateInMemory => '추모';

  @override
  String get templateInMemoryHint => '소중한 사람을 기리며';

  @override
  String get templateFestival => '명절·축제';

  @override
  String get templateFestivalHint => '특별한 계절의 따뜻한 인사';

  @override
  String get templateRingtone => '벨소리';

  @override
  String get templateRingtoneHint => '나만의 짧은 루프';

  @override
  String get templateTeamAnthem => '팀 응원가';

  @override
  String get templateTeamAnthemHint => '팀과 관중을 뜨겁게';

  @override
  String get templateSportsRecap => '경기 하이라이트';

  @override
  String get templateSportsRecapHint => '그 경기를 노래로';

  @override
  String get templateRapBattle => '랩 배틀';

  @override
  String get templateRapBattleHint => '친한 라이벌에게 보내는 벌스';

  @override
  String get templateComedy => '코미디';

  @override
  String get templateComedyHint => '우리끼리 농담을 후렴으로';

  @override
  String get templatePetAnthem => '반려동물 송';

  @override
  String get templatePetAnthemHint => '최고의 친구를 위한 테마송';

  @override
  String get templateHometown => '고향';

  @override
  String get templateHometownHint => '집이라 부르는 곳을 향한 사랑';

  @override
  String get templateBusinessPromo => '가게 홍보';

  @override
  String get templateBusinessPromoHint => '가게나 브랜드를 위한 중독성 있는 곡';

  @override
  String get templateCustom => '나만의 아이디어';

  @override
  String get mvRecommended => '추천';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString초';
  }

  @override
  String get mvViewProgress => '진행 상황 보기';

  @override
  String mvIntentWaiting(String level) {
    return '$level이(가) 크레딧을 기다리고 있어요';
  }

  @override
  String get mvSongExpiredAction => '노래 다시 만들기';

  @override
  String mvQuotaNeed(String level, int required, int available) {
    final intl.NumberFormat requiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requiredString = requiredNumberFormat.format(required);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return '$level에 $requiredString 크레딧이 필요해요. 지금 $availableString 있어요.';
  }

  @override
  String get mvQuotaBuyAndContinue => '구매하고 계속';

  @override
  String get mvQuotaMayNeedTwice => '지역에 따라 팩 하나로 부족할 수 있어요. 두 개가 필요할 수도 있어요.';

  @override
  String get mvQuotaAutoRetry => '구매가 완료되는 즉시 비디오를 시작해요.';

  @override
  String get mvAutoLyricMaking => '가사 비디오를 만드는 중';

  @override
  String get mvAutoChorusDetail => '이 노래로, 내 크레딧으로 만들어요';

  @override
  String mvAutoReady(String level) {
    return '$level이(가) 준비됐어요';
  }

  @override
  String get mvAutoView => '보기';

  @override
  String get mvUpgradeChorus => '후렴 비디오 만들기';

  @override
  String get mvAutoFailed => '비디오를 시작하지 못했어요';

  @override
  String get mvLeaveHint => '이 화면을 나가도 괜찮아요. 완성될 즈음 알려 드릴게요.';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString 크레딧이 돌아왔어요.',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => '이 비디오는 완성되지 않았어요';

  @override
  String get mvRejectedTitle => '사용할 수 없는 사진이 있어요';

  @override
  String get mvRejectedBody => '비디오 모델이 참고 사진 한 장을 거절했어요. 사진을 바꿔 다시 시도해 주세요.';

  @override
  String get mvAdjustPhotos => '사진 바꾸고 다시 시도';

  @override
  String get mvTryChorus => '대신 후렴 비디오 만들기';

  @override
  String get mvPreparingPhotos => '사진 업로드 중…';

  @override
  String get mvPreparingSubmit => '비디오 보내는 중…';

  @override
  String get mvNotifyTitle => '비디오가 준비됐을 거예요';

  @override
  String mvNotifyBody(String level) {
    return '$level — 탭해서 보기.';
  }

  @override
  String get mvRegenerate => '하나 더 만들기';

  @override
  String get mvEntryTitle => '비디오로 만들기';

  @override
  String get mvEntrySubtitle => '가사·후렴·전곡 비디오를 크레딧으로';

  @override
  String get mvEntryDisabled => '노래가 완성되면 이용할 수 있어요';

  @override
  String get mvEntryChoose => '비디오 고르기';

  @override
  String get mvEntryWatch => '비디오 보기';

  @override
  String get mvChipReady => '비디오';

  @override
  String get mvChipMaking => '비디오 만드는 중';

  @override
  String get lengthAutoVideo => '가사 비디오도 만들기';

  @override
  String get lengthAutoVideoHint => '노래 완성 몇 분 뒤 준비 · 크레딧 사용';

  @override
  String get lengthSongAndChorus => '노래 + 후렴 비디오';

  @override
  String get lengthSongAndChorusHint => '전곡을 만든 뒤 30초 후렴 비디오';

  @override
  String get paywallVideoGroup => '뮤직비디오';

  @override
  String get planVideoIncluded => '월 이용량으로 뮤직비디오도 만들 수 있어요';

  @override
  String get settingsVideoCredits => '비디오 크레딧';

  @override
  String get createGenrePop => '팝';

  @override
  String get createGenreHipHopRap => '힙합·랩';

  @override
  String get createGenreRock => '록';

  @override
  String get createGenreKPop => 'K팝';

  @override
  String get createGenreLatin => '라틴';

  @override
  String get createGenreElectronic => '일렉트로닉';

  @override
  String get createGenreRnb => 'R&B';

  @override
  String get createGenreCountry => '컨트리';

  @override
  String get createGenreAfrobeats => '아프로비츠';

  @override
  String get createGenreReggae => '레게';

  @override
  String get createGenreJazzBlues => '재즈·블루스';

  @override
  String get createGenreClassical => '클래식';

  @override
  String get createGenreFolk => '포크';

  @override
  String get createGenreLofi => '로파이';

  @override
  String get createGenreAcoustic => '어쿠스틱';

  @override
  String get createGenreCinematic => '영화 음악';

  @override
  String get createGenreAmbient => '앰비언트';

  @override
  String get createGenreBossaNova => '보사노바';

  @override
  String get createGenreIndiePop => '인디 팝';

  @override
  String get createGenreContemporaryRnb => '컨템퍼러리 R&B';

  @override
  String get createGenreAlternativeCountry => '얼터너티브 컨트리';

  @override
  String get createGenreGarageRock => '개러지 록';

  @override
  String get createGenreGrime => '그라임';

  @override
  String get createGenreIndieFolk => '인디 포크';

  @override
  String get createGenreSynthpop => '신스팝';

  @override
  String get createGenrePianoBallad => '피아노 발라드';

  @override
  String get createGenreSurfRock => '서프 록';

  @override
  String get createGenreDeepHouse => '딥 하우스';

  @override
  String get createGenreMinimalTechno => '미니멀 테크노';

  @override
  String get createGenreFrenchYeyePop => '60년대 프렌치 팝';

  @override
  String get createGenreChillout => '칠아웃';

  @override
  String get createGenreJPopIndiePop => '일본 인디 팝';

  @override
  String get createGenreChiptune => '칩튠';

  @override
  String get createGenreDiscoFunk => '디스코 펑크';

  @override
  String get createGenreReggaeton => '레게톤';

  @override
  String get createGenreCumbia => '쿰비아';

  @override
  String get createGenreLatinJazz => '라틴 재즈';

  @override
  String get createGenreBhangra => '방그라';

  @override
  String get createGenreIndianClassical => '인도 클래식';

  @override
  String get createGenreLofiHipHop => '로파이 힙합';

  @override
  String profileAccountIdWithValue(String id) {
    return '계정 ID: $id';
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
  String get createVocalsCustomSummary => '자동 — 설명에 맞춤';

  @override
  String mvChipMakingWithProgress(String progress) {
    return '비디오 만드는 중 · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return '비디오를 시작하지 못했어요 · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    return '동영상 크레딧: $creditsString';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => '영감';

  @override
  String inspirationPlay(String name) {
    return '$name 재생';
  }

  @override
  String get inspirationStop => '미리듣기 정지';

  @override
  String get inspirationNameSoundscape => '사운드스케이프';

  @override
  String get inspirationStyleSoundscape => '앰비언트 질감, 보컬 없음';

  @override
  String get inspirationNameBackgroundMusic => '배경 음악';

  @override
  String get inspirationStyleBackgroundMusic => '영상용 가벼운 연주곡';

  @override
  String get inspirationNameMemorizeSomething => '암기송';

  @override
  String get inspirationStyleMemorizeSomething => '귀에 쏙 들어오는 암기 팝';

  @override
  String get inspirationNameTextMessages => '메시지를 노래로';

  @override
  String get inspirationStyleTextMessages => '메시지로 만든 장난스러운 팝';

  @override
  String get inspirationNameIntroMusic => '인트로 음악';

  @override
  String get inspirationStyleIntroMusic => '웅장한 영화 같은 오프닝';

  @override
  String get inspirationNameMontage => '몽타주';

  @override
  String get inspirationStyleMontage => '하이라이트 영상용 고조되는 음악';

  @override
  String get inspirationNameSayItWithATrack => '노래로 전하기';

  @override
  String get inspirationStyleSayItWithATrack => '진심 어린 팝 발라드';

  @override
  String get inspirationNameBrandJingle => '브랜드 징글';

  @override
  String get inspirationStyleBrandJingle => '짧고 밝고 기억에 남는 훅';

  @override
  String get inspirationNameRingtone => '벨소리';

  @override
  String get inspirationStyleRingtone => '30초 반복 재생용 훅';

  @override
  String get inspirationNameStreaming => '스트리밍';

  @override
  String get inspirationStyleStreaming => '에너지 넘치는 일렉트로닉 방송 인트로';

  @override
  String get inspirationNameSpeechToTrack => '목소리를 노래로';

  @override
  String get inspirationStyleSpeechToTrack => '내 목소리가 노래로';

  @override
  String get inspirationNameRapBattle => '랩 배틀';

  @override
  String get inspirationStyleRapBattle => '강렬한 힙합';

  @override
  String get inspirationNameComedy => '코미디';

  @override
  String get inspirationStyleComedy => '독특하고 경쾌하고 재치 있게';

  @override
  String get inspirationNameTeamAnthem => '팀 응원가';

  @override
  String get inspirationStyleTeamAnthem => '스타디움 록 응원가';

  @override
  String get inspirationNameSportsRecap => '경기 하이라이트';

  @override
  String get inspirationStyleSportsRecap => '웅장한 오케스트라 하이라이트';

  @override
  String get inspirationNamePartyInvite => '파티 초대';

  @override
  String get inspirationStylePartyInvite => '댄스 팝 초대장';

  @override
  String get inspirationNameHappyBirthday => '생일 축하해';

  @override
  String get inspirationStyleHappyBirthday => '따뜻한 어쿠스틱 생일 노래';

  @override
  String get inspirationNameFriendAppreciation => '친구에게 고마워';

  @override
  String get inspirationStyleFriendAppreciation => '기분 좋아지는 인디 팝';

  @override
  String get inspirationNameLoveStory => '러브 스토리';

  @override
  String get inspirationStyleLoveStory => '로맨틱한 R&B 발라드';

  @override
  String get inspirationNameBirthdayRoast => '생일 놀리기 송';

  @override
  String get inspirationStyleBirthdayRoast => '장난스럽고 웃긴 생일 노래';

  @override
  String get inspirationNameOdeToYourPet => '반려동물 찬가';

  @override
  String get inspirationStyleOdeToYourPet => '귀엽고 통통 튀는 팝';

  @override
  String get inspirationNameHometownTribute => '고향 헌정곡';

  @override
  String get inspirationStyleHometownTribute => '향수를 부르는 포크';

  @override
  String get inspirationNameWeatherReport => '날씨 예보';

  @override
  String get inspirationStyleWeatherReport => '장난스러운 라운지 그루브';

  @override
  String get inspirationNameBusinessPromo => '가게 홍보';

  @override
  String get inspirationStyleBusinessPromo => '자신감 있는 기업 팝';

  @override
  String get inspirationStyleBirthdayWish => '특별한 날을 위한 진심 어린 노래';

  @override
  String get inspirationStyleBirthdayParty => '생일 주인공을 위한 신나는 파티 송';

  @override
  String get inspirationStyleThankAFriend => '따뜻하고 고마운 마음을 담은 감사 노래';

  @override
  String get inspirationStyleWedding => '특별한 날을 위한 기쁘고 로맨틱한 노래';

  @override
  String get inspirationStyleInMemory => '잔잔하고 희망찬 추모곡';

  @override
  String get inspirationStyleFestival => '밝고 흥겨운 시즌 인사';

  @override
  String get inspirationStylePetAnthem => '반려동물을 위한 사랑스럽고 통통 튀는 테마곡';

  @override
  String get inspirationStyleHometown => '자랑스럽고 그리운 고향 찬가';

  @override
  String get settingsSectionLanguage => '언어';

  @override
  String get settingsSectionProfile => '프로필';

  @override
  String get settingsCredits => '크레딧';

  @override
  String get settingsAccountId => '계정 ID';

  @override
  String get settingsCopyAccountId => '계정 ID 복사';

  @override
  String get devSectionTitle => '개발자 (DEV 전용)';

  @override
  String get devKeychainReset => 'Keychain 키 삭제';

  @override
  String get devKeychainResetHint => '기기 ID 및 세션 토큰';

  @override
  String get devKeychainResetConfirmTitle => 'Keychain 키를 삭제할까요?';

  @override
  String get devKeychainResetConfirmBody =>
      'Keychain에서 기기 ID와 세션 토큰을 지웁니다. 현재 게스트 계정은 복구할 수 없으며, 앱은 새 게스트로 로그인합니다.';

  @override
  String get devKeychainResetDone => 'Keychain 키 삭제됨 — 새 게스트로 로그인';

  @override
  String get settingsAppLanguage => '앱 언어';

  @override
  String get settingsLanguageSystem => '시스템 언어 사용';

  @override
  String settingsLanguageSystemValue(String language) {
    return '시스템 ($language)';
  }

  @override
  String get settingsLanguageNativeName => '한국어';

  @override
  String get settingsLanguageSaveFailed => '언어를 저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String get settingsLyricsLanguageHint => '새로 만드는 노래에 적용돼요.';

  @override
  String composerRemoveInspiration(String name) {
    return '$name 제거';
  }

  @override
  String get composerPromptHint => '노래를 설명하거나 위에서 아이디어를 고르세요';

  @override
  String get composerPromptHintWide => '노래를 설명하거나 아이디어를 고르세요';

  @override
  String get composerWordsLabel => '나의 글';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사진 $countString장 추가됨',
      one: '사진 $countString장 추가됨',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return '노래 옵션: $summary';
  }

  @override
  String get composerOptionsShow => '옵션 보기';

  @override
  String get composerOptionsHide => '옵션 숨기기';

  @override
  String get composerSummaryAnyVocals => '보컬 자유';

  @override
  String get composerSummaryAnyGenre => '장르 자유';

  @override
  String get composerSummaryLyrics => '직접 쓴 가사';

  @override
  String get composerSummaryVideo => '가사 비디오';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': '미리 듣기 만들기 · 무료',
      'preview': '미리 듣기 만들기 · 1회',
      'other': '미리 듣기 만들기',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': '$name의 미리 듣기 만들기 · 무료',
      'preview': '$name의 미리 듣기 만들기 · 1회',
      'other': '$name의 미리 듣기 만들기',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': '전체 노래 만들기 · 1곡',
      'other': '전체 노래 만들기',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => '이 텍스트 사용';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level이(가) $seconds초 후 시작됩니다';
  }

  @override
  String planPerWeek(String price) {
    return '$price/주';
  }

  @override
  String get planCreditsWeekly => '매주 새 크레딧';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': '1일',
      'week': '1주',
      'month': '1개월',
      'year': '1년',
      'other': '기간',
    });
    return '첫 $_temp0 $percent% 할인';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return '$introPrice 소개 가격 이후에는 $pricePerPeriod이(가) 자동으로 청구됩니다. 갱신 전에 언제든 취소할 수 있습니다.';
  }

  @override
  String get storePreviewAHook => '이름부터 시작하세요';

  @override
  String get storePreviewAWords => '그 사람을 세 단어로';

  @override
  String get storePreviewAWait => '노래를 만드는 중';

  @override
  String get storePreviewAChorus => '후렴에 이름이 들어가요';

  @override
  String get storePreviewAEnd => '그 사람 이름이 담긴 노래';

  @override
  String get storePreviewBHook => '사진으로 시작하세요';

  @override
  String get storePreviewBVideo => '가사 비디오도 함께';

  @override
  String get storePreviewBWait => '노래를 만드는 중';

  @override
  String get storePreviewBLyrics => '화면에 가사가 싱크';

  @override
  String get storePreviewBMood => '사진이 분위기를 정해요.';

  @override
  String get storePreviewBShare => '영상을 공유하세요.';

  @override
  String get storePreviewBLanguage => '내 언어로 된 가사';

  @override
  String get storePreviewAShare => '카드로 보내세요';

  @override
  String get storePreviewCta => '첫 노래를 만들어 보세요';

  @override
  String get storePreviewDisclosure => '구독 또는 크레딧이 필요합니다';

  @override
  String get storeCreativeHeader => '사랑하는 사람을 위한 노래';

  @override
  String get storeCreativeSearch => '이름 하나로 노래를 만들어요';

  @override
  String get storeCreativeBirthday => '이름이 들어간 생일 노래';

  @override
  String get storeCreativePhoto => '사진이 노래가 돼요';

  @override
  String get storeCreativeWedding => '두 사람의 결혼식을 위한 노래';
}
