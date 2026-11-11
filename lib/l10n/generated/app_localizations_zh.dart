// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get commonRetry => '重试';

  @override
  String get commonCancel => '取消';

  @override
  String get startupLoading => '正在调音…';

  @override
  String get commonErrorTitle => '出错了';

  @override
  String get updateRequiredTitle => '需要更新';

  @override
  String get updateRequiredMessage => '需要新版本才能继续。';

  @override
  String get updateNow => '立即更新';

  @override
  String get maintenanceTitle => '系统维护中';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '预计约 $minutesString 分钟后恢复';
  }

  @override
  String get featureUnavailable => '该功能暂时不可用。';

  @override
  String get navProfile => '我的';

  @override
  String get navStore => '商店';

  @override
  String get navUpload => '上传';

  @override
  String get uploadTitle => '文件上传';

  @override
  String get uploadSubtitle => '两段式预签名直传：哈希、秒传去重与实时进度。';

  @override
  String get uploadPick => '选择图片并上传';

  @override
  String get uploadAgain => '再传一张';

  @override
  String get uploadPhaseHashing => '计算哈希…';

  @override
  String get uploadPhaseSigning => '获取上传凭证…';

  @override
  String uploadPhaseUploading(String percent) {
    return '上传中 $percent';
  }

  @override
  String get uploadPhaseFinalizing => '确认完成…';

  @override
  String get uploadDone => '上传完成。';

  @override
  String get uploadDedup => '秒传：服务器已存在该文件。';

  @override
  String get uploadOpenLink => '查看文件';

  @override
  String get uploadFailed => '上传失败。';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '文件超过 $limitString MB 上限。';
  }

  @override
  String get uploadUnsupportedType => '不支持的文件类型。';

  @override
  String get profileGuestTitle => '游客';

  @override
  String get profileGuestSubtitle => '登录后可在多台设备同步购买。';

  @override
  String get signIn => '登录';

  @override
  String get signOut => '退出登录';

  @override
  String get profileBalanceLabel => '积分';

  @override
  String get profileAccountId => '账号 ID';

  @override
  String get profileFeaturesLabel => '已激活权益';

  @override
  String get profileNoFeatures => '暂无已激活权益。';

  @override
  String get profileSubscriptionLabel => '订阅';

  @override
  String get profileManageSubscription => '管理订阅';

  @override
  String get subscriptionActive => '生效中';

  @override
  String get subscriptionInactive => '无';

  @override
  String get profileDeleteAccount => '删除账号';

  @override
  String get deleteAccountTitle => '删除该账号？';

  @override
  String get deleteAccountMessage =>
      '此操作不可恢复：该账号及其积分、权益记录将永久无法找回，应用将为你创建一个全新账号。删除账号不会取消 App Store 订阅——请在应用商店的订阅设置中管理，也可稍后通过「恢复购买」重新关联。';

  @override
  String get deleteAccountConfirm => '删除';

  @override
  String get deleteAccountWorking => '正在删除账号…';

  @override
  String get deleteAccountDone => '账号已删除。';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '注册于 $dateString';
  }

  @override
  String get loginTitle => '登录';

  @override
  String get loginUsername => '用户名';

  @override
  String get loginPassword => '密码';

  @override
  String get loginSubmit => '登录';

  @override
  String get paywallTitle => '获取完整歌曲';

  @override
  String get paywallSubtitle => '把试听变成一首带歌词的 2 分钟歌曲——可下载，随你使用。';

  @override
  String get paywallRestore => '恢复购买';

  @override
  String get paywallAutoRenewNotice =>
      '确认购买时将通过你的 Apple 账户扣款。除非在当前订阅期结束前至少 24 小时取消，否则订阅将以相同价格和周期自动续订。免费试用结束后将自动转为付费订阅。你可以随时在 App Store 账户设置中管理或取消订阅。';

  @override
  String get paywallContinue => '继续';

  @override
  String get paywallFreeTrial => '免费试用';

  @override
  String get paywallOffer => '优惠';

  @override
  String get paywallManage => '管理';

  @override
  String get paywallTermsOfUse => '使用条款';

  @override
  String get paywallPrivacyPolicy => '隐私政策';

  @override
  String get paywallSubscriptionTerms => '订阅条款';

  @override
  String get commonLinkError => '无法打开链接。';

  @override
  String get commonError => '出了点问题。';

  @override
  String get commonNetworkError => '网络错误——请检查网络后重试。';

  @override
  String get commonOfflineError => '似乎已离线，请检查网络连接后重试。';

  @override
  String get networkErrorTitle => '网络连接异常';

  @override
  String get configErrorTitle => '应用配置异常';

  @override
  String get configErrorMessage =>
      '当前版本无法连接服务。请从 App Store 更新或重新安装应用；若问题仍在，请联系客服。';

  @override
  String get commonAuthError => '登录已过期——请重新登录。';

  @override
  String get paywallProductsErrorTitle => '无法加载商品';

  @override
  String get paywallNoProducts => '暂无可购买的商品。';

  @override
  String get paywallPurchaseSuccess => '购买成功，尽情享用！';

  @override
  String get paywallProcessing => '正在处理购买……';

  @override
  String get paywallVerifying => '正在校验购买……';

  @override
  String get paywallPurchaseFailed => '购买未能完成。';

  @override
  String get paywallRestoreStarted => '正在恢复购买…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已恢复 $countString 项购买。',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => '没有可恢复的购买。';

  @override
  String get paywallDeferred => '等待批准——批准后将自动完成。';

  @override
  String get paywallAlreadySubscribed => '你已订阅。';

  @override
  String get paywallBillingRetry => '请更新支付方式以保持订阅。';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString 天免费试用';
  }

  @override
  String get cycleOneTime => '一次性';

  @override
  String get cycleWeekly => '/ 周';

  @override
  String get cycleMonthly => '/ 月';

  @override
  String get cycleQuarterly => '/ 季';

  @override
  String get cycleSemiAnnual => '/ 半年';

  @override
  String get cycleAnnual => '/ 年';

  @override
  String get cycleLifetime => '永久';

  @override
  String get navCreate => '创作';

  @override
  String get navLibrary => '资料库';

  @override
  String get navSettings => '设置';

  @override
  String get commonContinue => '继续';

  @override
  String get commonBack => '返回';

  @override
  String get createTitle => '这首歌写给谁？';

  @override
  String get occasionBirthday => '生日';

  @override
  String get occasionBirthdayHint => '为 TA 的重要日子送上欢快的歌';

  @override
  String get occasionAnniversary => '纪念日';

  @override
  String get occasionAnniversaryHint => '庆祝你们一起走过的故事';

  @override
  String get occasionConfession => '表白';

  @override
  String get occasionConfessionHint => '唱出你的心里话';

  @override
  String get occasionWedding => '婚礼';

  @override
  String get occasionWeddingHint => '献给你们永恒时刻的歌';

  @override
  String get occasionMemorial => '追思';

  @override
  String get occasionMemorialHint => '纪念你珍视的人';

  @override
  String get occasionFestival => '节日';

  @override
  String get occasionFestivalHint => '在特别的时节送上温暖祝福';

  @override
  String get occasionBrand => '品牌广告歌';

  @override
  String get occasionBrandHint => '为你的品牌打造朗朗上口的旋律';

  @override
  String get occasionSoundtrack => '视频配乐';

  @override
  String get occasionSoundtrackHint => '贴合你故事的音乐';

  @override
  String get festivalNewYear => '新年';

  @override
  String get festivalThanksgiving => '感恩节';

  @override
  String get festivalDiwali => '排灯节';

  @override
  String get festivalCarnival => '狂欢节';

  @override
  String get festivalEid => '开斋节';

  @override
  String get festivalLunarNewYear => '春节';

  @override
  String get regionTitle => '这首歌会在哪里响起？';

  @override
  String get regionSearchHint => '搜索国家或地区';

  @override
  String get regionLanguageSheetTitle => '歌词语言';

  @override
  String get countryUS => '美国';

  @override
  String get countryGB => '英国';

  @override
  String get countryCA => '加拿大';

  @override
  String get countryAU => '澳大利亚';

  @override
  String get countryDE => '德国';

  @override
  String get countryFR => '法国';

  @override
  String get countryJP => '日本';

  @override
  String get countryKR => '韩国';

  @override
  String get countryBR => '巴西';

  @override
  String get countryMX => '墨西哥';

  @override
  String get countryIN => '印度';

  @override
  String get countryID => '印度尼西亚';

  @override
  String get countryVN => '越南';

  @override
  String get countryTR => '土耳其';

  @override
  String get languageEn => '英语';

  @override
  String get languageFr => '法语';

  @override
  String get languageDe => '德语';

  @override
  String get languageJa => '日语';

  @override
  String get languageKo => '韩语';

  @override
  String get languagePtBR => '葡萄牙语（巴西）';

  @override
  String get languageEsMX => '西班牙语（墨西哥）';

  @override
  String get languageHi => '印地语';

  @override
  String get languageId => '印度尼西亚语';

  @override
  String get languageVi => '越南语';

  @override
  String get languageTr => '土耳其语';

  @override
  String get languageZhHans => '简体中文';

  @override
  String get languageZhHant => '繁体中文';

  @override
  String get inputNameLabel => 'TA 的名字';

  @override
  String get inputNameOptionalLabel => '名字（选填）';

  @override
  String get inputNameHint => '例如：小雨';

  @override
  String get inputKeywordsLabel => '用三个词形容 TA';

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
  String get inputLyricsOwnership => '这些歌词是我原创的，或我有权使用';

  @override
  String get issueRecipientMissing => '请填写 TA 的名字。';

  @override
  String get issueRecipientTooLong => '名字最多 24 个字符。';

  @override
  String get issueBriefMissing => '说说这首歌吧——写几句话、歌词，或添加照片。';

  @override
  String get issueDescriptionMissing => '这个灵感需要你的文字——写一句关于这首歌的话吧。';

  @override
  String get generatingBackToEdit => '返回修改';

  @override
  String get issueKeywordTooLong => '每个词最多 20 个字符。';

  @override
  String get issueTooManyKeywords => '最多使用三个词。';

  @override
  String get issueArtistName => '不能使用艺人名称——试着描述你想要的感觉。';

  @override
  String get issueStyleImitation => '我们无法模仿歌手或乐队，试着描述你想要的氛围。';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '歌词最多 $limitString 个字符。';
  }

  @override
  String get issueLyricsNotOriginal => '这些歌词看起来像是已有的歌曲，请写你自己的歌词。';

  @override
  String get issueLyricsOwnership => '请确认你有权使用这些歌词。';

  @override
  String get issueTooManyPhotos => '最多选择 10 张照片。';

  @override
  String get photosTitle => '挑几张照片';

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
  String get photosPrivacy => '照片仅用于创作这首歌一次，并会在 24 小时内从我们的服务器删除。';

  @override
  String get photosAdd => '添加照片';

  @override
  String get photosCreate => '用照片创作';

  @override
  String get photosEmpty => '选择 1–10 张记录那一刻的照片。';

  @override
  String get generatingStepPolishing => '正在这台 iPhone 上润色你的文字…';

  @override
  String get generatingStepUploading => '正在发送照片…';

  @override
  String get generatingStepSubmitting => '正在发送到录音室…';

  @override
  String get errorSafetyBlocked => '这首歌我们无法制作——请换些词试试，并且不要使用艺人名称。';

  @override
  String get errorQuotaExhausted => '你已用完本月的歌曲。请添加歌曲包或升级。';

  @override
  String get errorUpstreamTimeout => '耗时比平时长。我们会继续尝试，并通知你。';

  @override
  String get errorUpstreamRateLimited => '现在有很多歌曲正在制作，你的歌已在排队。';

  @override
  String get errorAttestFailed => '请从 App Store 更新 Songlet。';

  @override
  String get errorImageRejected => '其中一张照片无法使用，请换一张试试。';

  @override
  String get errorNetworkOffline => '你已离线。资料库仍可正常使用。';

  @override
  String get errorDownloadLocked => '这首歌暂时无法下载——制作它的购买已退款，或你的方案已到期。你仍然可以播放它。';

  @override
  String get errorJobAlreadyFinished => '歌曲已完成，无需取消。';

  @override
  String get errorMvSongNotReady => '这首歌还没准备好制作视频。';

  @override
  String get errorMvSongTooLong => '这首歌太长，无法制作完整视频——试试副歌视频。';

  @override
  String get errorMvSongExpired => '这首歌已过期。请重新生成后再制作视频。';

  @override
  String get errorMvNotFound => '这个视频已不可用。';

  @override
  String get errorMvPhotosExpired => '这些照片已过期——请重新选择。';

  @override
  String get errorMvRenderFailed => '这个视频没能完成。积分已退回——再试一次。';

  @override
  String get mvHubTitle => '制作视频';

  @override
  String mvHubSubtitle(String title) {
    return '把《$title》变成一支音乐视频。';
  }

  @override
  String get mvLevelLyricVideo => '歌词视频';

  @override
  String get mvLevelLyricHint => '一幅静态画面配上歌词';

  @override
  String get mvLevelChorus => '副歌视频';

  @override
  String get mvLevelChorusHint => '30 秒副歌，由 AI 拍摄';

  @override
  String get mvLevelFull => '全曲视频';

  @override
  String get mvLevelFullHint => '整首歌，一幕接一幕';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString 积分',
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
      other: '你有 $creditsString 积分',
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
      other: '还差 $creditsString 积分',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => '正在查询价格…';

  @override
  String get mvOptionsHeader => '选项';

  @override
  String get mvAspectLabel => '画幅';

  @override
  String get mvAspectPortrait => '竖版';

  @override
  String get mvAspectLandscape => '横版';

  @override
  String get mvAspectSquare => '方形';

  @override
  String get mvQualityLabel => '画质';

  @override
  String get mvQualityStandard => '标准';

  @override
  String get mvQualityHigh => '高清';

  @override
  String get mvSubtitlesLabel => '画面显示歌词';

  @override
  String get mvPhotosLabel => '参考照片';

  @override
  String get mvPhotosHint => '设定场景与色调——不会使用人脸';

  @override
  String mvPhotosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 张',
    );
    return '$_temp0';
  }

  @override
  String get mvChorusLabel => '副歌';

  @override
  String get mvChorusAuto => '自动定位';

  @override
  String get mvChorusCustom => '自己选择片段';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => '制作视频';

  @override
  String get mvBuyPack => '购买视频包并制作';

  @override
  String get mvSongLocked => '你的歌曲已为视频保存。';

  @override
  String get mvGeneratingTitle => '正在制作你的视频…';

  @override
  String get mvStageQueued => '等待开始';

  @override
  String get mvStageSlicing => '挑选片段';

  @override
  String get mvStageStoryboarding => '撰写分镜';

  @override
  String get mvStageKeyframing => '绘制场景';

  @override
  String get mvStageRendering => '拍摄场景';

  @override
  String get mvStageAssembling => '剪辑合成';

  @override
  String get mvStageDone => '完成';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '第 $doneString/$totalString 幕';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '通常约 $minutesString 分钟';
  }

  @override
  String get mvCancelRequested => '将在当前场景结束后停止…';

  @override
  String get mvCancelTitle => '停止这个视频？';

  @override
  String get mvCancelQueued => '它还没开始，不会使用任何积分。';

  @override
  String get mvCancelStarted => '它已经开始了。已完成的场景会计费，其余积分退回。';

  @override
  String get mvCancelConfirm => '停止视频';

  @override
  String get mvCancelled => '视频已停止';

  @override
  String get mvCancelledRefunded => '视频已停止——未使用任何积分';

  @override
  String get mvNothing => '当前没有正在制作的视频。';

  @override
  String get mvQuotaTitle => '积分不足';

  @override
  String get mvAiLabelBurnedIn => 'AI 生成——角标已烧录进视频';

  @override
  String get mvSave => '保存到相册';

  @override
  String get mvSaveFiles => '保存到文件';

  @override
  String get mvShareText => '我用 Songlet 做了这支音乐视频 🎬';

  @override
  String get mvMissing => '这个视频已不在此设备上。';

  @override
  String get mvDeleteTitle => '删除这个视频？';

  @override
  String get mvDeleteBody => '它将从此设备上移除。';

  @override
  String get mvDeleted => '视频已删除';

  @override
  String get mvProvenance => '由 Google Lyria 3 与 AI 视频模型制作 · AI 生成';

  @override
  String get detailVideos => '视频';

  @override
  String get detailMakeVideo => '制作视频';

  @override
  String get mvStatusReady => '已完成';

  @override
  String get mvStatusPending => '制作中…';

  @override
  String get mvStatusFailed => '未完成';

  @override
  String get mvPackTitle => '音乐视频';

  @override
  String get mvPackChorusSubtitle => '一支副歌视频';

  @override
  String get mvPackFullSubtitle => '一支全曲视频';

  @override
  String get paywallMvHeroTitle => '把它做成视频';

  @override
  String get paywallMvHeroSubtitle => '为你的歌曲制作音乐视频的积分——可保存、可分享。';

  @override
  String get playerAiGenerated => 'AI 生成';

  @override
  String get playerLoop => '循环播放';

  @override
  String get playerPlay => '播放';

  @override
  String get playerPause => '暂停';

  @override
  String get playerPreviewLabel => '30 秒试听';

  @override
  String playerTitleFor(String name) {
    return '献给 $name';
  }

  @override
  String get downloadSaved => '已存储到“文件”。';

  @override
  String get shareComposing => '正在制作分享卡片…';

  @override
  String get shareFailed => '无法制作分享卡片。';

  @override
  String get shareText => '我用 Songlet 做了这首歌 🎵';

  @override
  String get paywallBestValue => '最超值';

  @override
  String get paywallStartTrial => '开始免费试用';

  @override
  String get paywallClose => '关闭';

  @override
  String get paywallSeePlans => '查看订阅';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你的方案已生效——本周期还剩 $countString 首完整歌曲。',
      one: '你的方案已生效——本周期还剩 $countString 首完整歌曲。',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => '你的歌曲会保存在这里。';

  @override
  String get libraryEmptyAction => '创作你的第一首歌';

  @override
  String get libraryPending => '作曲中…';

  @override
  String get libraryPreviewBadge => '试听';

  @override
  String get librarySongBadge => '完整歌曲';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsPlan => '你的方案';

  @override
  String get settingsPlanUnavailable => '无法加载你的方案。请稍后下拉重试。';

  @override
  String get tierFree => '未订阅';

  @override
  String get tierPack => '歌曲包';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还剩 $countString 首完整歌曲',
      one: '还剩 $countString 首完整歌曲',
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
      other: '还剩 $countString 次试听',
      one: '还剩 $countString 次试听',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString 重置';
  }

  @override
  String get settingsUpgrade => '升级';

  @override
  String get appTagline => '为你爱的人写一首歌';

  @override
  String get commonClose => '关闭';

  @override
  String get commonDone => '完成';

  @override
  String get commonDelete => '删除';

  @override
  String get commonMore => '更多';

  @override
  String get commonCopy => '复制';

  @override
  String get commonCopied => '已复制';

  @override
  String get commonNotNow => '以后再说';

  @override
  String get commonLearnMore => '了解更多';

  @override
  String get commonSeeAll => '查看全部';

  @override
  String get commonKeepGoing => '继续生成';

  @override
  String get composerHint => '描述你想要的歌';

  @override
  String get composerAddPhotos => '添加照片';

  @override
  String get composerSourceMusicHint => '用你自己的话描述';

  @override
  String get composerDictate => '语音输入';

  @override
  String get composerStopDictation => '停止语音输入';

  @override
  String get lengthPreview => '试听';

  @override
  String get lengthFull => '完整歌曲';

  @override
  String get paramLength => '时长';

  @override
  String get paramVocals => '人声';

  @override
  String get paramGenre => '曲风';

  @override
  String templatePlaySample(String name) {
    return '试听「$name」示例';
  }

  @override
  String get templatePauseSample => '暂停示例';

  @override
  String get lengthShort => '短';

  @override
  String get lengthShortHint => '30 秒试听';

  @override
  String get lengthStandard => '标准';

  @override
  String get lengthStandardHint => '约 2 分钟，Pro';

  @override
  String get vocalsCustom => '自定义';

  @override
  String get vocalsCustomHint => '根据你的描述';

  @override
  String get vocalsCustomDetail => '人声风格跟随你的描述。';

  @override
  String get vocalsOn => '有人声';

  @override
  String get vocalsInstrumental => '纯音乐';

  @override
  String vocalsLyricsIn(String language) {
    return '歌词语言：$language';
  }

  @override
  String get genreCustom => '自定义';

  @override
  String get genreCustomHint => '根据你的描述';

  @override
  String genrePopularIn(String country) {
    return '$country热门';
  }

  @override
  String get genreAll => '全部曲风';

  @override
  String get regionHelper => '会改变 3 个推荐曲风和歌词语言';

  @override
  String regionLyricsRow(String language) {
    return '歌词语言：$language';
  }

  @override
  String get regionNoMatch => '没有匹配的国家或地区';

  @override
  String get keywordAdd => '添加一个词';

  @override
  String keywordRemove(String word) {
    return '移除「$word」';
  }

  @override
  String get nameClear => '清除名字';

  @override
  String get lyricsOptional => '自己写歌词（可选）';

  @override
  String get issueRecipientArtistName => '不能使用艺人名字。';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '描述请控制在 $limitString 个字符以内。';
  }

  @override
  String get voiceRecording => '正在录音…';

  @override
  String get voiceStarting => '正在启动…';

  @override
  String get voiceListening => '说说这首歌送给谁、TA 喜欢什么…';

  @override
  String get voiceOnDevice => '本机转写';

  @override
  String get voicePermissionDenied => '请在“设置”中允许 Songlet 使用麦克风和语音识别后再试。';

  @override
  String get voiceUnavailable => '此设备不支持该语言的语音输入。';

  @override
  String get voiceApplied => '已从语音添加';

  @override
  String get photoRemove => '移除照片';

  @override
  String generatingTitleFor(String name) {
    return '正在为 $name 写歌…';
  }

  @override
  String get generatingTitleGeneric => '正在写你的歌…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '通常约 $secondsString 秒';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => '进度';

  @override
  String get generatingGlimpse => '抢先看一眼';

  @override
  String get generatingCancelTitle => '停止这首歌？';

  @override
  String get generatingCancelQueued => '还没开始生成，不会扣除额度。';

  @override
  String get generatingCancelStarted => '已经开始生成，仍会计入额度。';

  @override
  String get generatingCancelConfirm => '停止';

  @override
  String get generatingCancelled => '已停止';

  @override
  String get generatingCancelledRefunded => '已停止——未扣除额度';

  @override
  String get queueTitle => '现在创作的人很多。';

  @override
  String get queueSubtitle => '你的歌正在排队。';

  @override
  String get queuePosition => '排队位置';

  @override
  String get queueWait => '预计等待';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '约 $minutesString 分钟';
  }

  @override
  String get generatingNothing => '现在没有正在生成的歌。';

  @override
  String get previewGetFull => '生成 2 分钟完整版';

  @override
  String get previewShare => '分享试听';

  @override
  String get previewAnother => '换一版（消耗 1 次试听）';

  @override
  String get playerPosition => '播放进度';

  @override
  String get playerPrevSection => '上一段';

  @override
  String get playerNextSection => '下一段';

  @override
  String get playerShuffle => '随机段落';

  @override
  String get playerRepeat => '循环';

  @override
  String get playerProvenance => '由 Google Lyria 3 生成 · SynthID 水印 · AI 生成';

  @override
  String get playerMissing => '这首歌已不在此设备上。';

  @override
  String get actionDownload => '下载';

  @override
  String get actionShare => '分享';

  @override
  String get actionLicense => '授权';

  @override
  String get actionRegenerate => '重新生成';

  @override
  String get actionDetails => '详情';

  @override
  String get sectionIntro => '前奏';

  @override
  String get sectionVerse => '主歌';

  @override
  String get sectionPreChorus => '预副歌';

  @override
  String get sectionChorus => '副歌';

  @override
  String get sectionBridge => '桥段';

  @override
  String get sectionOutro => '尾奏';

  @override
  String get sectionHook => '记忆点';

  @override
  String get shareTitle => '分享卡片';

  @override
  String get shareSubtitle => '选择主题和版式。';

  @override
  String get shareTheme => '主题';

  @override
  String get shareLayout => '版式';

  @override
  String get shareLayoutScene => '带插画';

  @override
  String get shareLayoutText => '纯文字';

  @override
  String get paletteTerracotta => '陶土';

  @override
  String get paletteSand => '沙色';

  @override
  String get paletteOlive => '橄榄';

  @override
  String get paletteNavy => '藏青';

  @override
  String get shareAction => '分享';

  @override
  String get shareSaveVideo => '保存视频';

  @override
  String get shareCopyLyrics => '复制歌词';

  @override
  String get shareVideoSaved => '已存入照片';

  @override
  String get shareLyricsCopied => '歌词已复制';

  @override
  String get shareCardTagline => '为某个人写的歌';

  @override
  String get shareSaveFailed => '无法保存视频。请在“设置”中允许 Songlet 添加到照片。';

  @override
  String get downloadReady => '完整版已就绪';

  @override
  String get downloadTitle => '永久属于你';

  @override
  String get downloadIntro => '你的歌已完成。可在下方下载高品质音频和商用授权。';

  @override
  String get downloadAudioHeader => '下载音频';

  @override
  String get downloadAudioNote => '高品质';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle => '适合分享和日常收听';

  @override
  String get downloadWavTitle => 'WAV · 44.1 kHz（Premier）';

  @override
  String get downloadWavSubtitle => '专业用途的最高品质';

  @override
  String get downloadMp3Action => '下载 MP3';

  @override
  String get downloadWavAction => '下载 WAV';

  @override
  String get downloadLicenseAction => '下载授权文件';

  @override
  String get licenseHeader => '商用授权';

  @override
  String get licenseIncluded => '已包含在你的方案中';

  @override
  String get licenseNotIncluded => '购买方案或歌曲包后获得';

  @override
  String get licensePdfTitle => '商用授权（PDF）';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '生成于 $dateString';
  }

  @override
  String licenseId(String id) {
    return '授权编号：$id';
  }

  @override
  String get licenseUsesTitle => '这首歌可用于：';

  @override
  String get usePersonal => '个人使用';

  @override
  String get usePersonalDetail => '礼物、纪念、非商业用途';

  @override
  String get useAds => '广告与营销';

  @override
  String get useAdsDetail => '推广、付费投放';

  @override
  String get useSocial => '社交媒体';

  @override
  String get useSocialDetail => '抖音、Instagram、YouTube 等';

  @override
  String get usePodcasts => '播客与视频';

  @override
  String get usePodcastsDetail => '可变现内容';

  @override
  String get licenseDetailsNote => '完整条款见授权 PDF。';

  @override
  String get saveEnjoyHeader => '保存与收听';

  @override
  String get saveToFiles => '存储到“文件”';

  @override
  String get addToMusic => '添加到音乐';

  @override
  String get synthIdNote => '这首歌含有 SynthID 水印，下载后仍可识别为 AI 生成内容。';

  @override
  String get wavNeedsPremier => 'WAV 下载仅限 Premier。';

  @override
  String get wavUnavailable => '这首歌没有 WAV 文件。WAV 需在歌曲生成后 24 小时内保存。';

  @override
  String get libraryFilterAll => '全部';

  @override
  String get libraryJustBecause => '随心而作';

  @override
  String libraryPlay(String title) {
    return '播放 $title';
  }

  @override
  String libraryActions(String title) {
    return '$title 的操作';
  }

  @override
  String get libraryDeleteTitle => '删除这首歌？';

  @override
  String get libraryDeleteBody => '会从此设备删除。如果开启了 iCloud 同步，也会从你的其他设备删除。';

  @override
  String get libraryDeleted => '已删除';

  @override
  String get libraryFailed => '未完成';

  @override
  String get libraryNoMatch => '这个场合还没有歌。';

  @override
  String get detailFullGenerated => '完整版已生成';

  @override
  String get detailPreviewGenerated => '试听已生成';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '生成于 $dateString';
  }

  @override
  String get detailPromptUsed => '创作信息';

  @override
  String get detailOccasion => '场合';

  @override
  String get detailCountry => '国家或地区';

  @override
  String get detailGenre => '曲风';

  @override
  String get detailKeywords => '关键词';

  @override
  String get detailDescription => '描述';

  @override
  String get detailLyrics => '歌词';

  @override
  String get detailGenerationId => '生成编号';

  @override
  String get detailRegenerate => '同风格再生成';

  @override
  String get detailCustomGenre => '根据描述';

  @override
  String get settingsSectionPlan => '购买';

  @override
  String get settingsSectionLibrary => '作品库';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsRestore => '恢复购买';

  @override
  String get settingsManage => '管理订阅';

  @override
  String get settingsICloud => 'iCloud 同步';

  @override
  String get settingsICloudOn => '歌曲会在你的设备间同步';

  @override
  String get settingsICloudOff => '歌曲只保存在此设备';

  @override
  String get settingsICloudUnavailable => '请先在“设置”中登录 iCloud';

  @override
  String get settingsLyricsLanguage => '默认歌词语言';

  @override
  String get settingsLyricsLanguageAuto => '跟随国家或地区';

  @override
  String get settingsTerms => '使用条款';

  @override
  String get settingsPrivacy => '隐私政策';

  @override
  String settingsVersion(String version) {
    return '版本 $version';
  }

  @override
  String get aboutTitle => '关于生成';

  @override
  String get aboutSubtitle => 'Songlet 如何创作你的歌';

  @override
  String get aboutLyriaTitle => '由 Google Lyria 3 驱动';

  @override
  String get aboutLyriaBody =>
      '歌曲由 Google 的 Lyria 3 通过 Gemini API 生成。Lyria 3 是一个音乐生成模型，能把你的想法变成原创歌曲。';

  @override
  String get aboutWatermarkTitle => '内置水印';

  @override
  String get aboutWatermarkBody =>
      '每首歌都带有 Google 的 SynthID 水印，用于识别 AI 生成的音乐，且无法去除。';

  @override
  String get aboutImitationTitle => '不模仿真实艺人';

  @override
  String get aboutImitationBody =>
      'Songlet 从不模仿真实艺人、他们的声音或特定风格。歌曲均为原创，来自你的想法、描述和照片。';

  @override
  String get aboutPrivacyTitle => '重视你的隐私';

  @override
  String get aboutPrivacyBody => '照片和描述会在 24 小时内从服务器删除。歌曲生成后我们不会保留你的图片或描述。';

  @override
  String get aboutBanner => '你分享的每首歌都会标注“AI 生成”。';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · 由 Google Lyria 3 生成';
  }

  @override
  String get festivalKicker => '记录你的故事';

  @override
  String get festivalComing => '就要到了！';

  @override
  String get festivalBody => '写一首独一无二的歌来庆祝。';

  @override
  String festivalCta(String festival) {
    return '写一首$festival的歌';
  }

  @override
  String get festivalPickOccasion => '选一个场合，开始创作';

  @override
  String get festivalLanguagesTitle => '用你的语言唱';

  @override
  String festivalLanguagesBody(String language) {
    return '支持$language等 13 种语言';
  }

  @override
  String get unavailableTitle => '暂时不可用';

  @override
  String get unavailableMessage => 'Songlet 现在无法生成歌曲。作品库仍可使用——请稍后再试。';

  @override
  String get paywallHeroTitle => '生成完整版';

  @override
  String get paywallHeroSubtitle => '把你的想法变成更高品质、拥有完整权利的歌曲。';

  @override
  String get paywallBenefitSongs => '更多歌曲';

  @override
  String get paywallBenefitQuality => '更高品质';

  @override
  String get paywallBenefitCommercial => '可商用';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '每月 $countString 首完整歌曲',
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
      other: '每月 $countString 次试听',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'MP3 下载';

  @override
  String get planMp3Wav => 'MP3 + WAV 下载';

  @override
  String get planLicense => '商用授权';

  @override
  String get planPriority => '优先生成';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString 天免费试用';
  }

  @override
  String planPerYear(String price) {
    return '$price/年';
  }

  @override
  String planPerMonth(String price) {
    return '$price/月';
  }

  @override
  String get packTitle => '只需要几首？';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 首歌曲包',
    );
    return '$_temp0';
  }

  @override
  String get packNote => '永不过期';

  @override
  String get valueForever => '你的歌永久保存';

  @override
  String get valueDownloads => '高品质下载';

  @override
  String get valueCommercial => '允许商用';

  @override
  String get valuePrivate => '隐私优先';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return '免费试用结束后，将自动按 $pricePerPeriod 扣款。可在试用结束前随时取消。';
  }

  @override
  String get paywallSubscribe => '订阅';

  @override
  String get paywallBuyPack => '购买歌曲包';

  @override
  String get templateBirthdayWish => '生日祝福';

  @override
  String get templateBirthdayWishHint => '为 TA 的特别日子写一首特别的歌';

  @override
  String get templateBirthdayParty => '生日派对';

  @override
  String get templateBirthdayPartyHint => '为寿星把派对气氛拉满';

  @override
  String get templateLoveStory => '爱情故事';

  @override
  String get templateLoveStoryHint => '把你们的故事写成歌';

  @override
  String get templateThankAFriend => '感谢朋友';

  @override
  String get templateThankAFriendHint => '用歌说出说不出口的谢谢';

  @override
  String get templatePartyInvite => '派对邀请';

  @override
  String get templatePartyInviteHint => '把大家都叫来';

  @override
  String get templateWedding => '婚礼';

  @override
  String get templateWeddingHint => '为 TA 们的永恒时刻';

  @override
  String get templateInMemory => '纪念';

  @override
  String get templateInMemoryHint => '纪念你珍惜的人';

  @override
  String get templateFestival => '节日';

  @override
  String get templateFestivalHint => '为特别的季节送上祝福';

  @override
  String get templateRingtone => '铃声';

  @override
  String get templateRingtoneHint => '专属于你的短循环';

  @override
  String get templateTeamAnthem => '队歌';

  @override
  String get templateTeamAnthemHint => '点燃队伍和观众';

  @override
  String get templateSportsRecap => '赛事回顾';

  @override
  String get templateSportsRecapHint => '把那场比赛唱出来';

  @override
  String get templateRapBattle => '说唱对决';

  @override
  String get templateRapBattleHint => '给好对手的友好 battle';

  @override
  String get templateComedy => '搞笑';

  @override
  String get templateComedyHint => '把圈内梗唱成副歌';

  @override
  String get templatePetAnthem => '宠物之歌';

  @override
  String get templatePetAnthemHint => '给你的毛孩子一首主题曲';

  @override
  String get templateHometown => '家乡';

  @override
  String get templateHometownHint => '唱给你称为家的地方';

  @override
  String get templateBusinessPromo => '小店宣传';

  @override
  String get templateBusinessPromoHint => '给你的店或品牌一段洗脑旋律';

  @override
  String get templateCustom => '你的想法';

  @override
  String get mvRecommended => '推荐';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString 秒';
  }

  @override
  String get mvViewProgress => '查看进度';

  @override
  String mvIntentWaiting(String level) {
    return '$level正在等待积分';
  }

  @override
  String get mvSongExpiredAction => '重新生成这首歌';

  @override
  String mvQuotaNeed(String level, int required, int available) {
    final intl.NumberFormat requiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requiredString = requiredNumberFormat.format(required);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return '$level需要 $requiredString 积分，你现在有 $availableString。';
  }

  @override
  String get mvQuotaBuyAndContinue => '购买并继续';

  @override
  String get mvQuotaMayNeedTwice => '在你所在的地区，一个包可能不够，可能需要买两个。';

  @override
  String get mvQuotaAutoRetry => '购买完成后视频会立即开始制作。';

  @override
  String get mvAutoLyricMaking => '正在制作歌词视频';

  @override
  String get mvAutoChorusDetail => '用这首歌和你的积分制作';

  @override
  String mvAutoReady(String level) {
    return '$level已完成';
  }

  @override
  String get mvAutoView => '查看';

  @override
  String get mvUpgradeChorus => '制作副歌视频';

  @override
  String get mvAutoFailed => '视频未能开始';

  @override
  String get mvLeaveHint => '你可以离开此页面，我们会在预计完成时通知你。';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '你的 $creditsString 积分已退回。',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => '这个视频没有完成';

  @override
  String get mvRejectedTitle => '有一张照片无法使用';

  @override
  String get mvRejectedBody => '视频模型拒绝了你的一张参考照片。请调整照片后重试。';

  @override
  String get mvAdjustPhotos => '调整照片后重试';

  @override
  String get mvTryChorus => '改做副歌视频';

  @override
  String get mvPreparingPhotos => '正在上传照片…';

  @override
  String get mvPreparingSubmit => '正在提交视频…';

  @override
  String get mvNotifyTitle => '你的视频应该做好了';

  @override
  String mvNotifyBody(String level) {
    return '$level——点按观看。';
  }

  @override
  String get mvRegenerate => '再做一个';

  @override
  String get mvEntryTitle => '做成视频';

  @override
  String get mvEntrySubtitle => '歌词、副歌和整曲视频，均使用积分';

  @override
  String get mvEntryDisabled => '歌曲完成后可用';

  @override
  String get mvEntryChoose => '选择视频';

  @override
  String get mvEntryWatch => '观看视频';

  @override
  String get mvChipReady => '视频';

  @override
  String get mvChipMaking => '视频制作中';

  @override
  String get lengthAutoVideo => '同时生成歌词视频';

  @override
  String get lengthAutoVideoHint => '歌曲完成几分钟后即可 · 使用积分';

  @override
  String get lengthSongAndChorus => '歌曲 + 副歌视频';

  @override
  String get lengthSongAndChorusHint => '先生成整首歌，再做 30 秒副歌视频';

  @override
  String get paywallVideoGroup => '音乐视频';

  @override
  String get planVideoIncluded => '每月额度也可用于制作音乐视频';

  @override
  String get settingsVideoCredits => '视频积分';

  @override
  String get createGenrePop => '流行';

  @override
  String get createGenreHipHopRap => '嘻哈与说唱';

  @override
  String get createGenreRock => '摇滚';

  @override
  String get createGenreKPop => '韩流';

  @override
  String get createGenreLatin => '拉丁';

  @override
  String get createGenreElectronic => '电子';

  @override
  String get createGenreRnb => '节奏蓝调';

  @override
  String get createGenreCountry => '乡村';

  @override
  String get createGenreAfrobeats => '非洲流行';

  @override
  String get createGenreReggae => '雷鬼';

  @override
  String get createGenreJazzBlues => '爵士与蓝调';

  @override
  String get createGenreClassical => '古典';

  @override
  String get createGenreFolk => '民谣';

  @override
  String get createGenreLofi => '低保真';

  @override
  String get createGenreAcoustic => '原声';

  @override
  String get createGenreCinematic => '电影配乐';

  @override
  String get createGenreAmbient => '氛围';

  @override
  String get createGenreBossaNova => '巴萨诺瓦';

  @override
  String get createGenreIndiePop => '独立流行';

  @override
  String get createGenreContemporaryRnb => '当代节奏蓝调';

  @override
  String get createGenreAlternativeCountry => '另类乡村';

  @override
  String get createGenreGarageRock => '车库摇滚';

  @override
  String get createGenreGrime => 'Grime';

  @override
  String get createGenreIndieFolk => '独立民谣';

  @override
  String get createGenreSynthpop => '合成器流行';

  @override
  String get createGenrePianoBallad => '钢琴抒情';

  @override
  String get createGenreSurfRock => '冲浪摇滚';

  @override
  String get createGenreDeepHouse => '深度浩室';

  @override
  String get createGenreMinimalTechno => '极简电子';

  @override
  String get createGenreFrenchYeyePop => '法式复古流行';

  @override
  String get createGenreChillout => '轻松电子';

  @override
  String get createGenreJPopIndiePop => '日系独立流行';

  @override
  String get createGenreChiptune => '芯片音乐';

  @override
  String get createGenreDiscoFunk => '迪斯科放克';

  @override
  String get createGenreReggaeton => '雷鬼顿';

  @override
  String get createGenreCumbia => '昆比亚';

  @override
  String get createGenreLatinJazz => '拉丁爵士';

  @override
  String get createGenreBhangra => '邦格拉';

  @override
  String get createGenreIndianClassical => '印度古典';

  @override
  String get createGenreLofiHipHop => '低保真嘻哈';

  @override
  String profileAccountIdWithValue(String id) {
    return '账号 ID: $id';
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
  String get createVocalsCustomSummary => '自定义 — 根据你的描述';

  @override
  String mvChipMakingWithProgress(String progress) {
    return '视频制作中 · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return '视频未能开始 · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    return '视频积分：$creditsString';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => '灵感';

  @override
  String inspirationPlay(String name) {
    return '播放「$name」';
  }

  @override
  String get inspirationStop => '停止试听';

  @override
  String get inspirationNameSoundscape => '环境音景';

  @override
  String get inspirationStyleSoundscape => '氛围音色，纯音乐';

  @override
  String get inspirationNameBackgroundMusic => '背景音乐';

  @override
  String get inspirationStyleBackgroundMusic => '轻快纯音乐配乐';

  @override
  String get inspirationNameMemorizeSomething => '记忆小曲';

  @override
  String get inspirationStyleMemorizeSomething => '朗朗上口的记忆流行曲';

  @override
  String get inspirationNameTextMessages => '短信成歌';

  @override
  String get inspirationStyleTextMessages => '把消息唱出来的俏皮流行';

  @override
  String get inspirationNameIntroMusic => '开场音乐';

  @override
  String get inspirationStyleIntroMusic => '大气电影感开场';

  @override
  String get inspirationNameMontage => '混剪配乐';

  @override
  String get inspirationStyleMontage => '高光混剪的递进配乐';

  @override
  String get inspirationNameSayItWithATrack => '用歌说话';

  @override
  String get inspirationStyleSayItWithATrack => '深情流行抒情';

  @override
  String get inspirationNameBrandJingle => '品牌短曲';

  @override
  String get inspirationStyleBrandJingle => '简短明亮易记的短曲';

  @override
  String get inspirationNameRingtone => '铃声';

  @override
  String get inspirationStyleRingtone => '30 秒可循环片段';

  @override
  String get inspirationNameStreaming => '直播';

  @override
  String get inspirationStyleStreaming => '动感电子直播开场';

  @override
  String get inspirationNameSpeechToTrack => '语音生成歌曲';

  @override
  String get inspirationStyleSpeechToTrack => '把说话变成歌';

  @override
  String get inspirationNameRapBattle => '说唱对决';

  @override
  String get inspirationStyleRapBattle => '硬核嘻哈';

  @override
  String get inspirationNameComedy => '喜剧';

  @override
  String get inspirationStyleComedy => '俏皮欢快带点调侃';

  @override
  String get inspirationNameTeamAnthem => '队歌';

  @override
  String get inspirationStyleTeamAnthem => '体育场摇滚合唱';

  @override
  String get inspirationNameSportsRecap => '体育赛事回顾';

  @override
  String get inspirationStyleSportsRecap => '史诗管弦高光';

  @override
  String get inspirationNamePartyInvite => '派对邀请函';

  @override
  String get inspirationStylePartyInvite => '舞曲流行邀请';

  @override
  String get inspirationNameHappyBirthday => '生日祝福';

  @override
  String get inspirationStyleHappyBirthday => '温暖原声生日歌';

  @override
  String get inspirationNameFriendAppreciation => '感谢朋友';

  @override
  String get inspirationStyleFriendAppreciation => '治愈系独立流行';

  @override
  String get inspirationNameLoveStory => '爱情故事';

  @override
  String get inspirationStyleLoveStory => '浪漫 R&B 抒情';

  @override
  String get inspirationNameBirthdayRoast => '生日庆祝';

  @override
  String get inspirationStyleBirthdayRoast => '幽默吐槽版生日歌';

  @override
  String get inspirationNameOdeToYourPet => '宠物颂歌';

  @override
  String get inspirationStyleOdeToYourPet => '可爱蹦跳的流行';

  @override
  String get inspirationNameHometownTribute => '家乡特辑';

  @override
  String get inspirationStyleHometownTribute => '怀旧民谣';

  @override
  String get inspirationNameWeatherReport => '天气报告';

  @override
  String get inspirationStyleWeatherReport => '轻松俏皮的沙发律动';

  @override
  String get inspirationNameBusinessPromo => '业务宣传';

  @override
  String get inspirationStyleBusinessPromo => '自信商务流行';

  @override
  String get inspirationStyleBirthdayWish => '为 TA 的特别日子写的走心歌';

  @override
  String get inspirationStyleBirthdayParty => '为寿星炒热气氛的派对歌';

  @override
  String get inspirationStyleThankAFriend => '温暖真诚的感谢之歌';

  @override
  String get inspirationStyleWedding => '喜悦浪漫的婚礼之歌';

  @override
  String get inspirationStyleInMemory => '温柔而有希望的纪念曲';

  @override
  String get inspirationStyleFestival => '明亮喜庆的节日祝福';

  @override
  String get inspirationStylePetAnthem => '亲昵蹦跳的宠物主题曲';

  @override
  String get inspirationStyleHometown => '自豪又怀旧的家乡之歌';

  @override
  String get settingsSectionLanguage => '语言';

  @override
  String get settingsSectionProfile => '个人资料';

  @override
  String get settingsCredits => '积分';

  @override
  String get settingsAccountId => '账户 ID';

  @override
  String get settingsCopyAccountId => '复制账户 ID';

  @override
  String get devSectionTitle => '开发者（仅 DEV）';

  @override
  String get devKeychainReset => '删除 Keychain 密钥';

  @override
  String get devKeychainResetHint => '设备 ID 与会话令牌';

  @override
  String get devKeychainResetConfirmTitle => '删除 Keychain 密钥？';

  @override
  String get devKeychainResetConfirmBody =>
      '将从 Keychain 中清除设备 ID 与会话令牌。当前访客账户无法恢复，应用会以新访客身份登录。';

  @override
  String get devKeychainResetDone => 'Keychain 密钥已删除——已以新访客身份登录';

  @override
  String get settingsAppLanguage => '界面语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String settingsLanguageSystemValue(String language) {
    return '跟随系统（$language）';
  }

  @override
  String get settingsLanguageNativeName => '简体中文';

  @override
  String get settingsLanguageSaveFailed => '语言未能保存，请重试。';

  @override
  String get settingsLyricsLanguageHint => '用于新建歌曲。';

  @override
  String composerRemoveInspiration(String name) {
    return '移除$name';
  }

  @override
  String get composerPromptHint => '描述这首歌，或在上方选一个灵感';

  @override
  String get composerPromptHintWide => '描述这首歌，或选一个灵感';

  @override
  String get composerWordsLabel => '你的内容';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已添加 $countString 张照片',
      one: '已添加 $countString 张照片',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return '歌曲选项：$summary';
  }

  @override
  String get composerOptionsShow => '展开歌曲选项';

  @override
  String get composerOptionsHide => '收起歌曲选项';

  @override
  String get composerSummaryAnyVocals => '人声不限';

  @override
  String get composerSummaryAnyGenre => '曲风不限';

  @override
  String get composerSummaryLyrics => '自写歌词';

  @override
  String get composerSummaryVideo => '歌词视频';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': '生成试听 · 免费',
      'preview': '生成试听 · 1 次试听',
      'other': '生成试听',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': '为 $name 生成试听 · 免费',
      'preview': '为 $name 生成试听 · 1 次试听',
      'other': '为 $name 生成试听',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': '生成完整歌曲 · 1 首',
      'other': '生成完整歌曲',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => '使用这段文字';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level将在 $seconds 秒后开始';
  }

  @override
  String planPerWeek(String price) {
    return '$price/周';
  }

  @override
  String get planCreditsWeekly => '每周补充积分';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': '首日',
      'week': '首周',
      'month': '首月',
      'year': '首年',
      'other': '首期',
    });
    return '$_temp0立减 $percent%';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return '优惠价 $introPrice 结束后，将自动按 $pricePerPeriod 续费。可在续费前随时取消。';
  }

  @override
  String get storePreviewAHook => '从 TA 的名字开始';

  @override
  String get storePreviewAWords => '写下关于 TA 的三个词';

  @override
  String get storePreviewAWait => '正在为你写歌';

  @override
  String get storePreviewAChorus => '副歌里唱出 TA 的名字';

  @override
  String get storePreviewAEnd => '一首唱着 TA 名字的歌';

  @override
  String get storePreviewBHook => '从你的照片开始';

  @override
  String get storePreviewBVideo => '同时生成歌词视频';

  @override
  String get storePreviewBWait => '正在写歌';

  @override
  String get storePreviewBLyrics => '歌词同步上屏';

  @override
  String get storePreviewBMood => '照片定下歌的氛围。';

  @override
  String get storePreviewBShare => '分享这段视频。';

  @override
  String get storePreviewBLanguage => '用你的语言写歌词';

  @override
  String get storePreviewAShare => '做成卡片送给 TA';

  @override
  String get storePreviewCta => '写下你的第一首歌';

  @override
  String get storePreviewDisclosure => '需订阅或积分';

  @override
  String get storeCreativeHeader => '为你爱的人写一首歌';

  @override
  String get storeCreativeSearch => '一个名字，写成一首歌';

  @override
  String get storeCreativeBirthday => '唱出TA名字的生日歌';

  @override
  String get storeCreativePhoto => '让照片变成一首歌';

  @override
  String get storeCreativeWedding => '献给你们婚礼的歌';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get commonRetry => '重试';

  @override
  String get commonCancel => '取消';

  @override
  String get startupLoading => '正在调音…';

  @override
  String get commonErrorTitle => '出错了';

  @override
  String get updateRequiredTitle => '需要更新';

  @override
  String get updateRequiredMessage => '需要新版本才能继续。';

  @override
  String get updateNow => '立即更新';

  @override
  String get maintenanceTitle => '系统维护中';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '预计约 $minutesString 分钟后恢复';
  }

  @override
  String get featureUnavailable => '该功能暂时不可用。';

  @override
  String get navProfile => '我的';

  @override
  String get navStore => '商店';

  @override
  String get navUpload => '上传';

  @override
  String get uploadTitle => '文件上传';

  @override
  String get uploadSubtitle => '两段式预签名直传：哈希、秒传去重与实时进度。';

  @override
  String get uploadPick => '选择图片并上传';

  @override
  String get uploadAgain => '再传一张';

  @override
  String get uploadPhaseHashing => '计算哈希…';

  @override
  String get uploadPhaseSigning => '获取上传凭证…';

  @override
  String uploadPhaseUploading(String percent) {
    return '上传中 $percent';
  }

  @override
  String get uploadPhaseFinalizing => '确认完成…';

  @override
  String get uploadDone => '上传完成。';

  @override
  String get uploadDedup => '秒传：服务器已存在该文件。';

  @override
  String get uploadOpenLink => '查看文件';

  @override
  String get uploadFailed => '上传失败。';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '文件超过 $limitString MB 上限。';
  }

  @override
  String get uploadUnsupportedType => '不支持的文件类型。';

  @override
  String get profileGuestTitle => '游客';

  @override
  String get profileGuestSubtitle => '登录后可在多台设备同步购买。';

  @override
  String get signIn => '登录';

  @override
  String get signOut => '退出登录';

  @override
  String get profileBalanceLabel => '积分';

  @override
  String get profileAccountId => '账号 ID';

  @override
  String get profileFeaturesLabel => '已激活权益';

  @override
  String get profileNoFeatures => '暂无已激活权益。';

  @override
  String get profileSubscriptionLabel => '订阅';

  @override
  String get profileManageSubscription => '管理订阅';

  @override
  String get subscriptionActive => '生效中';

  @override
  String get subscriptionInactive => '无';

  @override
  String get profileDeleteAccount => '删除账号';

  @override
  String get deleteAccountTitle => '删除该账号？';

  @override
  String get deleteAccountMessage =>
      '此操作不可恢复：该账号及其积分、权益记录将永久无法找回，应用将为你创建一个全新账号。删除账号不会取消 App Store 订阅——请在应用商店的订阅设置中管理，也可稍后通过「恢复购买」重新关联。';

  @override
  String get deleteAccountConfirm => '删除';

  @override
  String get deleteAccountWorking => '正在删除账号…';

  @override
  String get deleteAccountDone => '账号已删除。';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '注册于 $dateString';
  }

  @override
  String get loginTitle => '登录';

  @override
  String get loginUsername => '用户名';

  @override
  String get loginPassword => '密码';

  @override
  String get loginSubmit => '登录';

  @override
  String get paywallTitle => '获取完整歌曲';

  @override
  String get paywallSubtitle => '把试听变成一首带歌词的 2 分钟歌曲——可下载，随你使用。';

  @override
  String get paywallRestore => '恢复购买';

  @override
  String get paywallAutoRenewNotice =>
      '确认购买时将通过你的 Apple 账户扣款。除非在当前订阅期结束前至少 24 小时取消，否则订阅将以相同价格和周期自动续订。免费试用结束后将自动转为付费订阅。你可以随时在 App Store 账户设置中管理或取消订阅。';

  @override
  String get paywallContinue => '继续';

  @override
  String get paywallFreeTrial => '免费试用';

  @override
  String get paywallOffer => '优惠';

  @override
  String get paywallManage => '管理';

  @override
  String get paywallTermsOfUse => '使用条款';

  @override
  String get paywallPrivacyPolicy => '隐私政策';

  @override
  String get paywallSubscriptionTerms => '订阅条款';

  @override
  String get commonLinkError => '无法打开链接。';

  @override
  String get commonError => '出了点问题。';

  @override
  String get commonNetworkError => '网络错误——请检查网络后重试。';

  @override
  String get commonOfflineError => '似乎已离线，请检查网络连接后重试。';

  @override
  String get networkErrorTitle => '网络连接异常';

  @override
  String get configErrorTitle => '应用配置异常';

  @override
  String get configErrorMessage =>
      '当前版本无法连接服务。请从 App Store 更新或重新安装应用；若问题仍在，请联系客服。';

  @override
  String get commonAuthError => '登录已过期——请重新登录。';

  @override
  String get paywallProductsErrorTitle => '无法加载商品';

  @override
  String get paywallNoProducts => '暂无可购买的商品。';

  @override
  String get paywallPurchaseSuccess => '购买成功，尽情享用！';

  @override
  String get paywallProcessing => '正在处理购买……';

  @override
  String get paywallVerifying => '正在校验购买……';

  @override
  String get paywallPurchaseFailed => '购买未能完成。';

  @override
  String get paywallRestoreStarted => '正在恢复购买…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已恢复 $countString 项购买。',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => '没有可恢复的购买。';

  @override
  String get paywallDeferred => '等待批准——批准后将自动完成。';

  @override
  String get paywallAlreadySubscribed => '你已订阅。';

  @override
  String get paywallBillingRetry => '请更新支付方式以保持订阅。';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString 天免费试用';
  }

  @override
  String get cycleOneTime => '一次性';

  @override
  String get cycleWeekly => '/ 周';

  @override
  String get cycleMonthly => '/ 月';

  @override
  String get cycleQuarterly => '/ 季';

  @override
  String get cycleSemiAnnual => '/ 半年';

  @override
  String get cycleAnnual => '/ 年';

  @override
  String get cycleLifetime => '永久';

  @override
  String get navCreate => '创作';

  @override
  String get navLibrary => '资料库';

  @override
  String get navSettings => '设置';

  @override
  String get commonContinue => '继续';

  @override
  String get commonBack => '返回';

  @override
  String get createTitle => '这首歌写给谁？';

  @override
  String get occasionBirthday => '生日';

  @override
  String get occasionBirthdayHint => '为 TA 的重要日子送上欢快的歌';

  @override
  String get occasionAnniversary => '纪念日';

  @override
  String get occasionAnniversaryHint => '庆祝你们一起走过的故事';

  @override
  String get occasionConfession => '表白';

  @override
  String get occasionConfessionHint => '唱出你的心里话';

  @override
  String get occasionWedding => '婚礼';

  @override
  String get occasionWeddingHint => '献给你们永恒时刻的歌';

  @override
  String get occasionMemorial => '追思';

  @override
  String get occasionMemorialHint => '纪念你珍视的人';

  @override
  String get occasionFestival => '节日';

  @override
  String get occasionFestivalHint => '在特别的时节送上温暖祝福';

  @override
  String get occasionBrand => '品牌广告歌';

  @override
  String get occasionBrandHint => '为你的品牌打造朗朗上口的旋律';

  @override
  String get occasionSoundtrack => '视频配乐';

  @override
  String get occasionSoundtrackHint => '贴合你故事的音乐';

  @override
  String get festivalNewYear => '新年';

  @override
  String get festivalThanksgiving => '感恩节';

  @override
  String get festivalDiwali => '排灯节';

  @override
  String get festivalCarnival => '狂欢节';

  @override
  String get festivalEid => '开斋节';

  @override
  String get festivalLunarNewYear => '春节';

  @override
  String get regionTitle => '这首歌会在哪里响起？';

  @override
  String get regionSearchHint => '搜索国家或地区';

  @override
  String get regionLanguageSheetTitle => '歌词语言';

  @override
  String get countryUS => '美国';

  @override
  String get countryGB => '英国';

  @override
  String get countryCA => '加拿大';

  @override
  String get countryAU => '澳大利亚';

  @override
  String get countryDE => '德国';

  @override
  String get countryFR => '法国';

  @override
  String get countryJP => '日本';

  @override
  String get countryKR => '韩国';

  @override
  String get countryBR => '巴西';

  @override
  String get countryMX => '墨西哥';

  @override
  String get countryIN => '印度';

  @override
  String get countryID => '印度尼西亚';

  @override
  String get countryVN => '越南';

  @override
  String get countryTR => '土耳其';

  @override
  String get languageEn => '英语';

  @override
  String get languageFr => '法语';

  @override
  String get languageDe => '德语';

  @override
  String get languageJa => '日语';

  @override
  String get languageKo => '韩语';

  @override
  String get languagePtBR => '葡萄牙语（巴西）';

  @override
  String get languageEsMX => '西班牙语（墨西哥）';

  @override
  String get languageHi => '印地语';

  @override
  String get languageId => '印度尼西亚语';

  @override
  String get languageVi => '越南语';

  @override
  String get languageTr => '土耳其语';

  @override
  String get languageZhHans => '简体中文';

  @override
  String get languageZhHant => '繁体中文';

  @override
  String get inputNameLabel => 'TA 的名字';

  @override
  String get inputNameOptionalLabel => '名字（选填）';

  @override
  String get inputNameHint => '例如：小雨';

  @override
  String get inputKeywordsLabel => '用三个词形容 TA';

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
  String get inputLyricsOwnership => '这些歌词是我原创的，或我有权使用';

  @override
  String get issueRecipientMissing => '请填写 TA 的名字。';

  @override
  String get issueRecipientTooLong => '名字最多 24 个字符。';

  @override
  String get issueBriefMissing => '说说这首歌吧——写几句话、歌词，或添加照片。';

  @override
  String get issueDescriptionMissing => '这个灵感需要你的文字——写一句关于这首歌的话吧。';

  @override
  String get generatingBackToEdit => '返回修改';

  @override
  String get issueKeywordTooLong => '每个词最多 20 个字符。';

  @override
  String get issueTooManyKeywords => '最多使用三个词。';

  @override
  String get issueArtistName => '不能使用艺人名称——试着描述你想要的感觉。';

  @override
  String get issueStyleImitation => '我们无法模仿歌手或乐队，试着描述你想要的氛围。';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '歌词最多 $limitString 个字符。';
  }

  @override
  String get issueLyricsNotOriginal => '这些歌词看起来像是已有的歌曲，请写你自己的歌词。';

  @override
  String get issueLyricsOwnership => '请确认你有权使用这些歌词。';

  @override
  String get issueTooManyPhotos => '最多选择 10 张照片。';

  @override
  String get photosTitle => '挑几张照片';

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
  String get photosPrivacy => '照片仅用于创作这首歌一次，并会在 24 小时内从我们的服务器删除。';

  @override
  String get photosAdd => '添加照片';

  @override
  String get photosCreate => '用照片创作';

  @override
  String get photosEmpty => '选择 1–10 张记录那一刻的照片。';

  @override
  String get generatingStepPolishing => '正在这台 iPhone 上润色你的文字…';

  @override
  String get generatingStepUploading => '正在发送照片…';

  @override
  String get generatingStepSubmitting => '正在发送到录音室…';

  @override
  String get errorSafetyBlocked => '这首歌我们无法制作——请换些词试试，并且不要使用艺人名称。';

  @override
  String get errorQuotaExhausted => '你已用完本月的歌曲。请添加歌曲包或升级。';

  @override
  String get errorUpstreamTimeout => '耗时比平时长。我们会继续尝试，并通知你。';

  @override
  String get errorUpstreamRateLimited => '现在有很多歌曲正在制作，你的歌已在排队。';

  @override
  String get errorAttestFailed => '请从 App Store 更新 Songlet。';

  @override
  String get errorImageRejected => '其中一张照片无法使用，请换一张试试。';

  @override
  String get errorNetworkOffline => '你已离线。资料库仍可正常使用。';

  @override
  String get errorDownloadLocked => '这首歌暂时无法下载——制作它的购买已退款，或你的方案已到期。你仍然可以播放它。';

  @override
  String get errorJobAlreadyFinished => '歌曲已完成，无需取消。';

  @override
  String get errorMvSongNotReady => '这首歌还没准备好制作视频。';

  @override
  String get errorMvSongTooLong => '这首歌太长，无法制作完整视频——试试副歌视频。';

  @override
  String get errorMvSongExpired => '这首歌已过期。请重新生成后再制作视频。';

  @override
  String get errorMvNotFound => '这个视频已不可用。';

  @override
  String get errorMvPhotosExpired => '这些照片已过期——请重新选择。';

  @override
  String get errorMvRenderFailed => '这个视频没能完成。积分已退回——再试一次。';

  @override
  String get mvHubTitle => '制作视频';

  @override
  String mvHubSubtitle(String title) {
    return '把《$title》变成一支音乐视频。';
  }

  @override
  String get mvLevelLyricVideo => '歌词视频';

  @override
  String get mvLevelLyricHint => '一幅静态画面配上歌词';

  @override
  String get mvLevelChorus => '副歌视频';

  @override
  String get mvLevelChorusHint => '30 秒副歌，由 AI 拍摄';

  @override
  String get mvLevelFull => '全曲视频';

  @override
  String get mvLevelFullHint => '整首歌，一幕接一幕';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString 积分',
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
      other: '你有 $creditsString 积分',
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
      other: '还差 $creditsString 积分',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => '正在查询价格…';

  @override
  String get mvOptionsHeader => '选项';

  @override
  String get mvAspectLabel => '画幅';

  @override
  String get mvAspectPortrait => '竖版';

  @override
  String get mvAspectLandscape => '横版';

  @override
  String get mvAspectSquare => '方形';

  @override
  String get mvQualityLabel => '画质';

  @override
  String get mvQualityStandard => '标准';

  @override
  String get mvQualityHigh => '高清';

  @override
  String get mvSubtitlesLabel => '画面显示歌词';

  @override
  String get mvPhotosLabel => '参考照片';

  @override
  String get mvPhotosHint => '设定场景与色调——不会使用人脸';

  @override
  String mvPhotosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 张',
    );
    return '$_temp0';
  }

  @override
  String get mvChorusLabel => '副歌';

  @override
  String get mvChorusAuto => '自动定位';

  @override
  String get mvChorusCustom => '自己选择片段';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => '制作视频';

  @override
  String get mvBuyPack => '购买视频包并制作';

  @override
  String get mvSongLocked => '你的歌曲已为视频保存。';

  @override
  String get mvGeneratingTitle => '正在制作你的视频…';

  @override
  String get mvStageQueued => '等待开始';

  @override
  String get mvStageSlicing => '挑选片段';

  @override
  String get mvStageStoryboarding => '撰写分镜';

  @override
  String get mvStageKeyframing => '绘制场景';

  @override
  String get mvStageRendering => '拍摄场景';

  @override
  String get mvStageAssembling => '剪辑合成';

  @override
  String get mvStageDone => '完成';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '第 $doneString/$totalString 幕';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '通常约 $minutesString 分钟';
  }

  @override
  String get mvCancelRequested => '将在当前场景结束后停止…';

  @override
  String get mvCancelTitle => '停止这个视频？';

  @override
  String get mvCancelQueued => '它还没开始，不会使用任何积分。';

  @override
  String get mvCancelStarted => '它已经开始了。已完成的场景会计费，其余积分退回。';

  @override
  String get mvCancelConfirm => '停止视频';

  @override
  String get mvCancelled => '视频已停止';

  @override
  String get mvCancelledRefunded => '视频已停止——未使用任何积分';

  @override
  String get mvNothing => '当前没有正在制作的视频。';

  @override
  String get mvQuotaTitle => '积分不足';

  @override
  String get mvAiLabelBurnedIn => 'AI 生成——角标已烧录进视频';

  @override
  String get mvSave => '保存到相册';

  @override
  String get mvSaveFiles => '保存到文件';

  @override
  String get mvShareText => '我用 Songlet 做了这支音乐视频 🎬';

  @override
  String get mvMissing => '这个视频已不在此设备上。';

  @override
  String get mvDeleteTitle => '删除这个视频？';

  @override
  String get mvDeleteBody => '它将从此设备上移除。';

  @override
  String get mvDeleted => '视频已删除';

  @override
  String get mvProvenance => '由 Google Lyria 3 与 AI 视频模型制作 · AI 生成';

  @override
  String get detailVideos => '视频';

  @override
  String get detailMakeVideo => '制作视频';

  @override
  String get mvStatusReady => '已完成';

  @override
  String get mvStatusPending => '制作中…';

  @override
  String get mvStatusFailed => '未完成';

  @override
  String get mvPackTitle => '音乐视频';

  @override
  String get mvPackChorusSubtitle => '一支副歌视频';

  @override
  String get mvPackFullSubtitle => '一支全曲视频';

  @override
  String get paywallMvHeroTitle => '把它做成视频';

  @override
  String get paywallMvHeroSubtitle => '为你的歌曲制作音乐视频的积分——可保存、可分享。';

  @override
  String get playerAiGenerated => 'AI 生成';

  @override
  String get playerLoop => '循环播放';

  @override
  String get playerPlay => '播放';

  @override
  String get playerPause => '暂停';

  @override
  String get playerPreviewLabel => '30 秒试听';

  @override
  String playerTitleFor(String name) {
    return '献给 $name';
  }

  @override
  String get downloadSaved => '已存储到“文件”。';

  @override
  String get shareComposing => '正在制作分享卡片…';

  @override
  String get shareFailed => '无法制作分享卡片。';

  @override
  String get shareText => '我用 Songlet 做了这首歌 🎵';

  @override
  String get paywallBestValue => '最超值';

  @override
  String get paywallStartTrial => '开始免费试用';

  @override
  String get paywallClose => '关闭';

  @override
  String get paywallSeePlans => '查看订阅';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你的方案已生效——本周期还剩 $countString 首完整歌曲。',
      one: '你的方案已生效——本周期还剩 $countString 首完整歌曲。',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => '你的歌曲会保存在这里。';

  @override
  String get libraryEmptyAction => '创作你的第一首歌';

  @override
  String get libraryPending => '作曲中…';

  @override
  String get libraryPreviewBadge => '试听';

  @override
  String get librarySongBadge => '完整歌曲';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsPlan => '你的方案';

  @override
  String get settingsPlanUnavailable => '无法加载你的方案。请稍后下拉重试。';

  @override
  String get tierFree => '未订阅';

  @override
  String get tierPack => '歌曲包';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还剩 $countString 首完整歌曲',
      one: '还剩 $countString 首完整歌曲',
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
      other: '还剩 $countString 次试听',
      one: '还剩 $countString 次试听',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString 重置';
  }

  @override
  String get settingsUpgrade => '升级';

  @override
  String get appTagline => '为你爱的人写一首歌';

  @override
  String get commonClose => '关闭';

  @override
  String get commonDone => '完成';

  @override
  String get commonDelete => '删除';

  @override
  String get commonMore => '更多';

  @override
  String get commonCopy => '复制';

  @override
  String get commonCopied => '已复制';

  @override
  String get commonNotNow => '以后再说';

  @override
  String get commonLearnMore => '了解更多';

  @override
  String get commonSeeAll => '查看全部';

  @override
  String get commonKeepGoing => '继续生成';

  @override
  String get composerHint => '描述你想要的歌';

  @override
  String get composerAddPhotos => '添加照片';

  @override
  String get composerSourceMusicHint => '用你自己的话描述';

  @override
  String get composerDictate => '语音输入';

  @override
  String get composerStopDictation => '停止语音输入';

  @override
  String get lengthPreview => '试听';

  @override
  String get lengthFull => '完整歌曲';

  @override
  String get paramLength => '时长';

  @override
  String get paramVocals => '人声';

  @override
  String get paramGenre => '曲风';

  @override
  String templatePlaySample(String name) {
    return '试听「$name」示例';
  }

  @override
  String get templatePauseSample => '暂停示例';

  @override
  String get lengthShort => '短';

  @override
  String get lengthShortHint => '30 秒试听';

  @override
  String get lengthStandard => '标准';

  @override
  String get lengthStandardHint => '约 2 分钟，Pro';

  @override
  String get vocalsCustom => '自定义';

  @override
  String get vocalsCustomHint => '根据你的描述';

  @override
  String get vocalsCustomDetail => '人声风格跟随你的描述。';

  @override
  String get vocalsOn => '有人声';

  @override
  String get vocalsInstrumental => '纯音乐';

  @override
  String vocalsLyricsIn(String language) {
    return '歌词语言：$language';
  }

  @override
  String get genreCustom => '自定义';

  @override
  String get genreCustomHint => '根据你的描述';

  @override
  String genrePopularIn(String country) {
    return '$country热门';
  }

  @override
  String get genreAll => '全部曲风';

  @override
  String get regionHelper => '会改变 3 个推荐曲风和歌词语言';

  @override
  String regionLyricsRow(String language) {
    return '歌词语言：$language';
  }

  @override
  String get regionNoMatch => '没有匹配的国家或地区';

  @override
  String get keywordAdd => '添加一个词';

  @override
  String keywordRemove(String word) {
    return '移除「$word」';
  }

  @override
  String get nameClear => '清除名字';

  @override
  String get lyricsOptional => '自己写歌词（可选）';

  @override
  String get issueRecipientArtistName => '不能使用艺人名字。';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '描述请控制在 $limitString 个字符以内。';
  }

  @override
  String get voiceRecording => '正在录音…';

  @override
  String get voiceStarting => '正在启动…';

  @override
  String get voiceListening => '说说这首歌送给谁、TA 喜欢什么…';

  @override
  String get voiceOnDevice => '本机转写';

  @override
  String get voicePermissionDenied => '请在“设置”中允许 Songlet 使用麦克风和语音识别后再试。';

  @override
  String get voiceUnavailable => '此设备不支持该语言的语音输入。';

  @override
  String get voiceApplied => '已从语音添加';

  @override
  String get photoRemove => '移除照片';

  @override
  String generatingTitleFor(String name) {
    return '正在为 $name 写歌…';
  }

  @override
  String get generatingTitleGeneric => '正在写你的歌…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '通常约 $secondsString 秒';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => '进度';

  @override
  String get generatingGlimpse => '抢先看一眼';

  @override
  String get generatingCancelTitle => '停止这首歌？';

  @override
  String get generatingCancelQueued => '还没开始生成，不会扣除额度。';

  @override
  String get generatingCancelStarted => '已经开始生成，仍会计入额度。';

  @override
  String get generatingCancelConfirm => '停止';

  @override
  String get generatingCancelled => '已停止';

  @override
  String get generatingCancelledRefunded => '已停止——未扣除额度';

  @override
  String get queueTitle => '现在创作的人很多。';

  @override
  String get queueSubtitle => '你的歌正在排队。';

  @override
  String get queuePosition => '排队位置';

  @override
  String get queueWait => '预计等待';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '约 $minutesString 分钟';
  }

  @override
  String get generatingNothing => '现在没有正在生成的歌。';

  @override
  String get previewGetFull => '生成 2 分钟完整版';

  @override
  String get previewShare => '分享试听';

  @override
  String get previewAnother => '换一版（消耗 1 次试听）';

  @override
  String get playerPosition => '播放进度';

  @override
  String get playerPrevSection => '上一段';

  @override
  String get playerNextSection => '下一段';

  @override
  String get playerShuffle => '随机段落';

  @override
  String get playerRepeat => '循环';

  @override
  String get playerProvenance => '由 Google Lyria 3 生成 · SynthID 水印 · AI 生成';

  @override
  String get playerMissing => '这首歌已不在此设备上。';

  @override
  String get actionDownload => '下载';

  @override
  String get actionShare => '分享';

  @override
  String get actionLicense => '授权';

  @override
  String get actionRegenerate => '重新生成';

  @override
  String get actionDetails => '详情';

  @override
  String get sectionIntro => '前奏';

  @override
  String get sectionVerse => '主歌';

  @override
  String get sectionPreChorus => '预副歌';

  @override
  String get sectionChorus => '副歌';

  @override
  String get sectionBridge => '桥段';

  @override
  String get sectionOutro => '尾奏';

  @override
  String get sectionHook => '记忆点';

  @override
  String get shareTitle => '分享卡片';

  @override
  String get shareSubtitle => '选择主题和版式。';

  @override
  String get shareTheme => '主题';

  @override
  String get shareLayout => '版式';

  @override
  String get shareLayoutScene => '带插画';

  @override
  String get shareLayoutText => '纯文字';

  @override
  String get paletteTerracotta => '陶土';

  @override
  String get paletteSand => '沙色';

  @override
  String get paletteOlive => '橄榄';

  @override
  String get paletteNavy => '藏青';

  @override
  String get shareAction => '分享';

  @override
  String get shareSaveVideo => '保存视频';

  @override
  String get shareCopyLyrics => '复制歌词';

  @override
  String get shareVideoSaved => '已存入照片';

  @override
  String get shareLyricsCopied => '歌词已复制';

  @override
  String get shareCardTagline => '为某个人写的歌';

  @override
  String get shareSaveFailed => '无法保存视频。请在“设置”中允许 Songlet 添加到照片。';

  @override
  String get downloadReady => '完整版已就绪';

  @override
  String get downloadTitle => '永久属于你';

  @override
  String get downloadIntro => '你的歌已完成。可在下方下载高品质音频和商用授权。';

  @override
  String get downloadAudioHeader => '下载音频';

  @override
  String get downloadAudioNote => '高品质';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle => '适合分享和日常收听';

  @override
  String get downloadWavTitle => 'WAV · 44.1 kHz（Premier）';

  @override
  String get downloadWavSubtitle => '专业用途的最高品质';

  @override
  String get downloadMp3Action => '下载 MP3';

  @override
  String get downloadWavAction => '下载 WAV';

  @override
  String get downloadLicenseAction => '下载授权文件';

  @override
  String get licenseHeader => '商用授权';

  @override
  String get licenseIncluded => '已包含在你的方案中';

  @override
  String get licenseNotIncluded => '购买方案或歌曲包后获得';

  @override
  String get licensePdfTitle => '商用授权（PDF）';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '生成于 $dateString';
  }

  @override
  String licenseId(String id) {
    return '授权编号：$id';
  }

  @override
  String get licenseUsesTitle => '这首歌可用于：';

  @override
  String get usePersonal => '个人使用';

  @override
  String get usePersonalDetail => '礼物、纪念、非商业用途';

  @override
  String get useAds => '广告与营销';

  @override
  String get useAdsDetail => '推广、付费投放';

  @override
  String get useSocial => '社交媒体';

  @override
  String get useSocialDetail => '抖音、Instagram、YouTube 等';

  @override
  String get usePodcasts => '播客与视频';

  @override
  String get usePodcastsDetail => '可变现内容';

  @override
  String get licenseDetailsNote => '完整条款见授权 PDF。';

  @override
  String get saveEnjoyHeader => '保存与收听';

  @override
  String get saveToFiles => '存储到“文件”';

  @override
  String get addToMusic => '添加到音乐';

  @override
  String get synthIdNote => '这首歌含有 SynthID 水印，下载后仍可识别为 AI 生成内容。';

  @override
  String get wavNeedsPremier => 'WAV 下载仅限 Premier。';

  @override
  String get wavUnavailable => '这首歌没有 WAV 文件。WAV 需在歌曲生成后 24 小时内保存。';

  @override
  String get libraryFilterAll => '全部';

  @override
  String get libraryJustBecause => '随心而作';

  @override
  String libraryPlay(String title) {
    return '播放 $title';
  }

  @override
  String libraryActions(String title) {
    return '$title 的操作';
  }

  @override
  String get libraryDeleteTitle => '删除这首歌？';

  @override
  String get libraryDeleteBody => '会从此设备删除。如果开启了 iCloud 同步，也会从你的其他设备删除。';

  @override
  String get libraryDeleted => '已删除';

  @override
  String get libraryFailed => '未完成';

  @override
  String get libraryNoMatch => '这个场合还没有歌。';

  @override
  String get detailFullGenerated => '完整版已生成';

  @override
  String get detailPreviewGenerated => '试听已生成';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '生成于 $dateString';
  }

  @override
  String get detailPromptUsed => '创作信息';

  @override
  String get detailOccasion => '场合';

  @override
  String get detailCountry => '国家或地区';

  @override
  String get detailGenre => '曲风';

  @override
  String get detailKeywords => '关键词';

  @override
  String get detailDescription => '描述';

  @override
  String get detailLyrics => '歌词';

  @override
  String get detailGenerationId => '生成编号';

  @override
  String get detailRegenerate => '同风格再生成';

  @override
  String get detailCustomGenre => '根据描述';

  @override
  String get settingsSectionPlan => '购买';

  @override
  String get settingsSectionLibrary => '作品库';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsRestore => '恢复购买';

  @override
  String get settingsManage => '管理订阅';

  @override
  String get settingsICloud => 'iCloud 同步';

  @override
  String get settingsICloudOn => '歌曲会在你的设备间同步';

  @override
  String get settingsICloudOff => '歌曲只保存在此设备';

  @override
  String get settingsICloudUnavailable => '请先在“设置”中登录 iCloud';

  @override
  String get settingsLyricsLanguage => '默认歌词语言';

  @override
  String get settingsLyricsLanguageAuto => '跟随国家或地区';

  @override
  String get settingsTerms => '使用条款';

  @override
  String get settingsPrivacy => '隐私政策';

  @override
  String settingsVersion(String version) {
    return '版本 $version';
  }

  @override
  String get aboutTitle => '关于生成';

  @override
  String get aboutSubtitle => 'Songlet 如何创作你的歌';

  @override
  String get aboutLyriaTitle => '由 Google Lyria 3 驱动';

  @override
  String get aboutLyriaBody =>
      '歌曲由 Google 的 Lyria 3 通过 Gemini API 生成。Lyria 3 是一个音乐生成模型，能把你的想法变成原创歌曲。';

  @override
  String get aboutWatermarkTitle => '内置水印';

  @override
  String get aboutWatermarkBody =>
      '每首歌都带有 Google 的 SynthID 水印，用于识别 AI 生成的音乐，且无法去除。';

  @override
  String get aboutImitationTitle => '不模仿真实艺人';

  @override
  String get aboutImitationBody =>
      'Songlet 从不模仿真实艺人、他们的声音或特定风格。歌曲均为原创，来自你的想法、描述和照片。';

  @override
  String get aboutPrivacyTitle => '重视你的隐私';

  @override
  String get aboutPrivacyBody => '照片和描述会在 24 小时内从服务器删除。歌曲生成后我们不会保留你的图片或描述。';

  @override
  String get aboutBanner => '你分享的每首歌都会标注“AI 生成”。';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · 由 Google Lyria 3 生成';
  }

  @override
  String get festivalKicker => '记录你的故事';

  @override
  String get festivalComing => '就要到了！';

  @override
  String get festivalBody => '写一首独一无二的歌来庆祝。';

  @override
  String festivalCta(String festival) {
    return '写一首$festival的歌';
  }

  @override
  String get festivalPickOccasion => '选一个场合，开始创作';

  @override
  String get festivalLanguagesTitle => '用你的语言唱';

  @override
  String festivalLanguagesBody(String language) {
    return '支持$language等 13 种语言';
  }

  @override
  String get unavailableTitle => '暂时不可用';

  @override
  String get unavailableMessage => 'Songlet 现在无法生成歌曲。作品库仍可使用——请稍后再试。';

  @override
  String get paywallHeroTitle => '生成完整版';

  @override
  String get paywallHeroSubtitle => '把你的想法变成更高品质、拥有完整权利的歌曲。';

  @override
  String get paywallBenefitSongs => '更多歌曲';

  @override
  String get paywallBenefitQuality => '更高品质';

  @override
  String get paywallBenefitCommercial => '可商用';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '每月 $countString 首完整歌曲',
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
      other: '每月 $countString 次试听',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'MP3 下载';

  @override
  String get planMp3Wav => 'MP3 + WAV 下载';

  @override
  String get planLicense => '商用授权';

  @override
  String get planPriority => '优先生成';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString 天免费试用';
  }

  @override
  String planPerYear(String price) {
    return '$price/年';
  }

  @override
  String planPerMonth(String price) {
    return '$price/月';
  }

  @override
  String get packTitle => '只需要几首？';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 首歌曲包',
    );
    return '$_temp0';
  }

  @override
  String get packNote => '永不过期';

  @override
  String get valueForever => '你的歌永久保存';

  @override
  String get valueDownloads => '高品质下载';

  @override
  String get valueCommercial => '允许商用';

  @override
  String get valuePrivate => '隐私优先';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return '免费试用结束后，将自动按 $pricePerPeriod 扣款。可在试用结束前随时取消。';
  }

  @override
  String get paywallSubscribe => '订阅';

  @override
  String get paywallBuyPack => '购买歌曲包';

  @override
  String get templateBirthdayWish => '生日祝福';

  @override
  String get templateBirthdayWishHint => '为 TA 的特别日子写一首特别的歌';

  @override
  String get templateBirthdayParty => '生日派对';

  @override
  String get templateBirthdayPartyHint => '为寿星把派对气氛拉满';

  @override
  String get templateLoveStory => '爱情故事';

  @override
  String get templateLoveStoryHint => '把你们的故事写成歌';

  @override
  String get templateThankAFriend => '感谢朋友';

  @override
  String get templateThankAFriendHint => '用歌说出说不出口的谢谢';

  @override
  String get templatePartyInvite => '派对邀请';

  @override
  String get templatePartyInviteHint => '把大家都叫来';

  @override
  String get templateWedding => '婚礼';

  @override
  String get templateWeddingHint => '为 TA 们的永恒时刻';

  @override
  String get templateInMemory => '纪念';

  @override
  String get templateInMemoryHint => '纪念你珍惜的人';

  @override
  String get templateFestival => '节日';

  @override
  String get templateFestivalHint => '为特别的季节送上祝福';

  @override
  String get templateRingtone => '铃声';

  @override
  String get templateRingtoneHint => '专属于你的短循环';

  @override
  String get templateTeamAnthem => '队歌';

  @override
  String get templateTeamAnthemHint => '点燃队伍和观众';

  @override
  String get templateSportsRecap => '赛事回顾';

  @override
  String get templateSportsRecapHint => '把那场比赛唱出来';

  @override
  String get templateRapBattle => '说唱对决';

  @override
  String get templateRapBattleHint => '给好对手的友好 battle';

  @override
  String get templateComedy => '搞笑';

  @override
  String get templateComedyHint => '把圈内梗唱成副歌';

  @override
  String get templatePetAnthem => '宠物之歌';

  @override
  String get templatePetAnthemHint => '给你的毛孩子一首主题曲';

  @override
  String get templateHometown => '家乡';

  @override
  String get templateHometownHint => '唱给你称为家的地方';

  @override
  String get templateBusinessPromo => '小店宣传';

  @override
  String get templateBusinessPromoHint => '给你的店或品牌一段洗脑旋律';

  @override
  String get templateCustom => '你的想法';

  @override
  String get mvRecommended => '推荐';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString 秒';
  }

  @override
  String get mvViewProgress => '查看进度';

  @override
  String mvIntentWaiting(String level) {
    return '$level正在等待积分';
  }

  @override
  String get mvSongExpiredAction => '重新生成这首歌';

  @override
  String mvQuotaNeed(String level, int required, int available) {
    final intl.NumberFormat requiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requiredString = requiredNumberFormat.format(required);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return '$level需要 $requiredString 积分，你现在有 $availableString。';
  }

  @override
  String get mvQuotaBuyAndContinue => '购买并继续';

  @override
  String get mvQuotaMayNeedTwice => '在你所在的地区，一个包可能不够，可能需要买两个。';

  @override
  String get mvQuotaAutoRetry => '购买完成后视频会立即开始制作。';

  @override
  String get mvAutoLyricMaking => '正在制作歌词视频';

  @override
  String get mvAutoChorusDetail => '用这首歌和你的积分制作';

  @override
  String mvAutoReady(String level) {
    return '$level已完成';
  }

  @override
  String get mvAutoView => '查看';

  @override
  String get mvUpgradeChorus => '制作副歌视频';

  @override
  String get mvAutoFailed => '视频未能开始';

  @override
  String get mvLeaveHint => '你可以离开此页面，我们会在预计完成时通知你。';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '你的 $creditsString 积分已退回。',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => '这个视频没有完成';

  @override
  String get mvRejectedTitle => '有一张照片无法使用';

  @override
  String get mvRejectedBody => '视频模型拒绝了你的一张参考照片。请调整照片后重试。';

  @override
  String get mvAdjustPhotos => '调整照片后重试';

  @override
  String get mvTryChorus => '改做副歌视频';

  @override
  String get mvPreparingPhotos => '正在上传照片…';

  @override
  String get mvPreparingSubmit => '正在提交视频…';

  @override
  String get mvNotifyTitle => '你的视频应该做好了';

  @override
  String mvNotifyBody(String level) {
    return '$level——点按观看。';
  }

  @override
  String get mvRegenerate => '再做一个';

  @override
  String get mvEntryTitle => '做成视频';

  @override
  String get mvEntrySubtitle => '歌词、副歌和整曲视频，均使用积分';

  @override
  String get mvEntryDisabled => '歌曲完成后可用';

  @override
  String get mvEntryChoose => '选择视频';

  @override
  String get mvEntryWatch => '观看视频';

  @override
  String get mvChipReady => '视频';

  @override
  String get mvChipMaking => '视频制作中';

  @override
  String get lengthAutoVideo => '同时生成歌词视频';

  @override
  String get lengthAutoVideoHint => '歌曲完成几分钟后即可 · 使用积分';

  @override
  String get lengthSongAndChorus => '歌曲 + 副歌视频';

  @override
  String get lengthSongAndChorusHint => '先生成整首歌，再做 30 秒副歌视频';

  @override
  String get paywallVideoGroup => '音乐视频';

  @override
  String get planVideoIncluded => '每月额度也可用于制作音乐视频';

  @override
  String get settingsVideoCredits => '视频积分';

  @override
  String get createGenrePop => '流行';

  @override
  String get createGenreHipHopRap => '嘻哈与说唱';

  @override
  String get createGenreRock => '摇滚';

  @override
  String get createGenreKPop => '韩流';

  @override
  String get createGenreLatin => '拉丁';

  @override
  String get createGenreElectronic => '电子';

  @override
  String get createGenreRnb => '节奏蓝调';

  @override
  String get createGenreCountry => '乡村';

  @override
  String get createGenreAfrobeats => '非洲流行';

  @override
  String get createGenreReggae => '雷鬼';

  @override
  String get createGenreJazzBlues => '爵士与蓝调';

  @override
  String get createGenreClassical => '古典';

  @override
  String get createGenreFolk => '民谣';

  @override
  String get createGenreLofi => '低保真';

  @override
  String get createGenreAcoustic => '原声';

  @override
  String get createGenreCinematic => '电影配乐';

  @override
  String get createGenreAmbient => '氛围';

  @override
  String get createGenreBossaNova => '巴萨诺瓦';

  @override
  String get createGenreIndiePop => '独立流行';

  @override
  String get createGenreContemporaryRnb => '当代节奏蓝调';

  @override
  String get createGenreAlternativeCountry => '另类乡村';

  @override
  String get createGenreGarageRock => '车库摇滚';

  @override
  String get createGenreGrime => 'Grime';

  @override
  String get createGenreIndieFolk => '独立民谣';

  @override
  String get createGenreSynthpop => '合成器流行';

  @override
  String get createGenrePianoBallad => '钢琴抒情';

  @override
  String get createGenreSurfRock => '冲浪摇滚';

  @override
  String get createGenreDeepHouse => '深度浩室';

  @override
  String get createGenreMinimalTechno => '极简电子';

  @override
  String get createGenreFrenchYeyePop => '法式复古流行';

  @override
  String get createGenreChillout => '轻松电子';

  @override
  String get createGenreJPopIndiePop => '日系独立流行';

  @override
  String get createGenreChiptune => '芯片音乐';

  @override
  String get createGenreDiscoFunk => '迪斯科放克';

  @override
  String get createGenreReggaeton => '雷鬼顿';

  @override
  String get createGenreCumbia => '昆比亚';

  @override
  String get createGenreLatinJazz => '拉丁爵士';

  @override
  String get createGenreBhangra => '邦格拉';

  @override
  String get createGenreIndianClassical => '印度古典';

  @override
  String get createGenreLofiHipHop => '低保真嘻哈';

  @override
  String profileAccountIdWithValue(String id) {
    return '账号 ID: $id';
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
  String get createVocalsCustomSummary => '自定义 — 根据你的描述';

  @override
  String mvChipMakingWithProgress(String progress) {
    return '视频制作中 · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return '视频未能开始 · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    return '视频积分：$creditsString';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => '灵感';

  @override
  String inspirationPlay(String name) {
    return '播放「$name」';
  }

  @override
  String get inspirationStop => '停止试听';

  @override
  String get inspirationNameSoundscape => '环境音景';

  @override
  String get inspirationStyleSoundscape => '氛围音色，纯音乐';

  @override
  String get inspirationNameBackgroundMusic => '背景音乐';

  @override
  String get inspirationStyleBackgroundMusic => '轻快纯音乐配乐';

  @override
  String get inspirationNameMemorizeSomething => '记忆小曲';

  @override
  String get inspirationStyleMemorizeSomething => '朗朗上口的记忆流行曲';

  @override
  String get inspirationNameTextMessages => '短信成歌';

  @override
  String get inspirationStyleTextMessages => '把消息唱出来的俏皮流行';

  @override
  String get inspirationNameIntroMusic => '开场音乐';

  @override
  String get inspirationStyleIntroMusic => '大气电影感开场';

  @override
  String get inspirationNameMontage => '混剪配乐';

  @override
  String get inspirationStyleMontage => '高光混剪的递进配乐';

  @override
  String get inspirationNameSayItWithATrack => '用歌说话';

  @override
  String get inspirationStyleSayItWithATrack => '深情流行抒情';

  @override
  String get inspirationNameBrandJingle => '品牌短曲';

  @override
  String get inspirationStyleBrandJingle => '简短明亮易记的短曲';

  @override
  String get inspirationNameRingtone => '铃声';

  @override
  String get inspirationStyleRingtone => '30 秒可循环片段';

  @override
  String get inspirationNameStreaming => '直播';

  @override
  String get inspirationStyleStreaming => '动感电子直播开场';

  @override
  String get inspirationNameSpeechToTrack => '语音生成歌曲';

  @override
  String get inspirationStyleSpeechToTrack => '把说话变成歌';

  @override
  String get inspirationNameRapBattle => '说唱对决';

  @override
  String get inspirationStyleRapBattle => '硬核嘻哈';

  @override
  String get inspirationNameComedy => '喜剧';

  @override
  String get inspirationStyleComedy => '俏皮欢快带点调侃';

  @override
  String get inspirationNameTeamAnthem => '队歌';

  @override
  String get inspirationStyleTeamAnthem => '体育场摇滚合唱';

  @override
  String get inspirationNameSportsRecap => '体育赛事回顾';

  @override
  String get inspirationStyleSportsRecap => '史诗管弦高光';

  @override
  String get inspirationNamePartyInvite => '派对邀请函';

  @override
  String get inspirationStylePartyInvite => '舞曲流行邀请';

  @override
  String get inspirationNameHappyBirthday => '生日祝福';

  @override
  String get inspirationStyleHappyBirthday => '温暖原声生日歌';

  @override
  String get inspirationNameFriendAppreciation => '感谢朋友';

  @override
  String get inspirationStyleFriendAppreciation => '治愈系独立流行';

  @override
  String get inspirationNameLoveStory => '爱情故事';

  @override
  String get inspirationStyleLoveStory => '浪漫 R&B 抒情';

  @override
  String get inspirationNameBirthdayRoast => '生日庆祝';

  @override
  String get inspirationStyleBirthdayRoast => '幽默吐槽版生日歌';

  @override
  String get inspirationNameOdeToYourPet => '宠物颂歌';

  @override
  String get inspirationStyleOdeToYourPet => '可爱蹦跳的流行';

  @override
  String get inspirationNameHometownTribute => '家乡特辑';

  @override
  String get inspirationStyleHometownTribute => '怀旧民谣';

  @override
  String get inspirationNameWeatherReport => '天气报告';

  @override
  String get inspirationStyleWeatherReport => '轻松俏皮的沙发律动';

  @override
  String get inspirationNameBusinessPromo => '业务宣传';

  @override
  String get inspirationStyleBusinessPromo => '自信商务流行';

  @override
  String get inspirationStyleBirthdayWish => '为 TA 的特别日子写的走心歌';

  @override
  String get inspirationStyleBirthdayParty => '为寿星炒热气氛的派对歌';

  @override
  String get inspirationStyleThankAFriend => '温暖真诚的感谢之歌';

  @override
  String get inspirationStyleWedding => '喜悦浪漫的婚礼之歌';

  @override
  String get inspirationStyleInMemory => '温柔而有希望的纪念曲';

  @override
  String get inspirationStyleFestival => '明亮喜庆的节日祝福';

  @override
  String get inspirationStylePetAnthem => '亲昵蹦跳的宠物主题曲';

  @override
  String get inspirationStyleHometown => '自豪又怀旧的家乡之歌';

  @override
  String get settingsSectionLanguage => '语言';

  @override
  String get settingsSectionProfile => '个人资料';

  @override
  String get settingsCredits => '积分';

  @override
  String get settingsAccountId => '账户 ID';

  @override
  String get settingsCopyAccountId => '复制账户 ID';

  @override
  String get devSectionTitle => '开发者（仅 DEV）';

  @override
  String get devKeychainReset => '删除 Keychain 密钥';

  @override
  String get devKeychainResetHint => '设备 ID 与会话令牌';

  @override
  String get devKeychainResetConfirmTitle => '删除 Keychain 密钥？';

  @override
  String get devKeychainResetConfirmBody =>
      '将从 Keychain 中清除设备 ID 与会话令牌。当前访客账户无法恢复，应用会以新访客身份登录。';

  @override
  String get devKeychainResetDone => 'Keychain 密钥已删除——已以新访客身份登录';

  @override
  String get settingsAppLanguage => '界面语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String settingsLanguageSystemValue(String language) {
    return '跟随系统（$language）';
  }

  @override
  String get settingsLanguageNativeName => '简体中文';

  @override
  String get settingsLanguageSaveFailed => '语言未能保存，请重试。';

  @override
  String get settingsLyricsLanguageHint => '用于新建歌曲。';

  @override
  String composerRemoveInspiration(String name) {
    return '移除$name';
  }

  @override
  String get composerPromptHint => '描述这首歌，或在上方选一个灵感';

  @override
  String get composerPromptHintWide => '描述这首歌，或选一个灵感';

  @override
  String get composerWordsLabel => '你的内容';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已添加 $countString 张照片',
      one: '已添加 $countString 张照片',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return '歌曲选项：$summary';
  }

  @override
  String get composerOptionsShow => '展开歌曲选项';

  @override
  String get composerOptionsHide => '收起歌曲选项';

  @override
  String get composerSummaryAnyVocals => '人声不限';

  @override
  String get composerSummaryAnyGenre => '曲风不限';

  @override
  String get composerSummaryLyrics => '自写歌词';

  @override
  String get composerSummaryVideo => '歌词视频';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': '生成试听 · 免费',
      'preview': '生成试听 · 1 次试听',
      'other': '生成试听',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': '为 $name 生成试听 · 免费',
      'preview': '为 $name 生成试听 · 1 次试听',
      'other': '为 $name 生成试听',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': '生成完整歌曲 · 1 首',
      'other': '生成完整歌曲',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => '使用这段文字';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level将在 $seconds 秒后开始';
  }

  @override
  String planPerWeek(String price) {
    return '$price/周';
  }

  @override
  String get planCreditsWeekly => '每周补充积分';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': '首日',
      'week': '首周',
      'month': '首月',
      'year': '首年',
      'other': '首期',
    });
    return '$_temp0立减 $percent%';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return '优惠价 $introPrice 结束后，将自动按 $pricePerPeriod 续费。可在续费前随时取消。';
  }

  @override
  String get storePreviewAHook => '从 TA 的名字开始';

  @override
  String get storePreviewAWords => '写下关于 TA 的三个词';

  @override
  String get storePreviewAWait => '正在为你写歌';

  @override
  String get storePreviewAChorus => '副歌里唱出 TA 的名字';

  @override
  String get storePreviewAEnd => '一首唱着 TA 名字的歌';

  @override
  String get storePreviewBHook => '从你的照片开始';

  @override
  String get storePreviewBVideo => '同时生成歌词视频';

  @override
  String get storePreviewBWait => '正在写歌';

  @override
  String get storePreviewBLyrics => '歌词同步上屏';

  @override
  String get storePreviewBMood => '照片定下歌的氛围。';

  @override
  String get storePreviewBShare => '分享这段视频。';

  @override
  String get storePreviewBLanguage => '用你的语言写歌词';

  @override
  String get storePreviewAShare => '做成卡片送给 TA';

  @override
  String get storePreviewCta => '写下你的第一首歌';

  @override
  String get storePreviewDisclosure => '需订阅或积分';

  @override
  String get storeCreativeHeader => '为你爱的人写一首歌';

  @override
  String get storeCreativeSearch => '一个名字，写成一首歌';

  @override
  String get storeCreativeBirthday => '唱出TA名字的生日歌';

  @override
  String get storeCreativePhoto => '让照片变成一首歌';

  @override
  String get storeCreativeWedding => '献给你们婚礼的歌';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get commonRetry => '重試';

  @override
  String get commonCancel => '取消';

  @override
  String get startupLoading => '正在調音…';

  @override
  String get commonErrorTitle => '發生錯誤';

  @override
  String get updateRequiredTitle => '需要更新';

  @override
  String get updateRequiredMessage => '需要新版本才能繼續。';

  @override
  String get updateNow => '立即更新';

  @override
  String get maintenanceTitle => '系統維護中';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '預計約 $minutesString 分鐘後恢復';
  }

  @override
  String get featureUnavailable => '此功能暫時無法使用。';

  @override
  String get navProfile => '個人';

  @override
  String get navStore => '商店';

  @override
  String get navUpload => '上傳';

  @override
  String get uploadTitle => '檔案上傳';

  @override
  String get uploadSubtitle => '預先簽署直傳 R2：雜湊計算、秒傳去重與即時進度。';

  @override
  String get uploadPick => '選擇圖片並上傳';

  @override
  String get uploadAgain => '再上傳一個';

  @override
  String get uploadPhaseHashing => '正在計算雜湊…';

  @override
  String get uploadPhaseSigning => '正在取得上傳憑證…';

  @override
  String uploadPhaseUploading(String percent) {
    return '上傳中 $percent';
  }

  @override
  String get uploadPhaseFinalizing => '正在完成…';

  @override
  String get uploadDone => '已上傳。';

  @override
  String get uploadDedup => '秒傳：伺服器上已有此檔案。';

  @override
  String get uploadOpenLink => '檢視檔案';

  @override
  String get uploadFailed => '上傳失敗。';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '檔案太大（上限 $limitString MB）。';
  }

  @override
  String get uploadUnsupportedType => '不支援的檔案類型。';

  @override
  String get profileGuestTitle => '訪客';

  @override
  String get profileGuestSubtitle => '登入後即可在多部裝置間保留你的購買項目。';

  @override
  String get signIn => '登入';

  @override
  String get signOut => '登出';

  @override
  String get profileBalanceLabel => '點數';

  @override
  String get profileAccountId => '帳號 ID';

  @override
  String get profileFeaturesLabel => '已啟用的權益';

  @override
  String get profileNoFeatures => '尚無已啟用的權益。';

  @override
  String get profileSubscriptionLabel => '訂閱';

  @override
  String get profileManageSubscription => '管理訂閱';

  @override
  String get subscriptionActive => '使用中';

  @override
  String get subscriptionInactive => '無';

  @override
  String get profileDeleteAccount => '刪除帳號';

  @override
  String get deleteAccountTitle => '要刪除此帳號嗎？';

  @override
  String get deleteAccountMessage =>
      '此動作無法復原：此帳號及其點數與權益紀錄將永久無法存取，並會建立一個全新帳號。刪除帳號不會取消使用中的 App Store 訂閱——請在 App Store 設定中管理，或稍後透過「回復購買項目」重新連結。';

  @override
  String get deleteAccountConfirm => '刪除';

  @override
  String get deleteAccountWorking => '正在刪除帳號…';

  @override
  String get deleteAccountDone => '帳號已刪除。';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '自 $dateString 起成為會員';
  }

  @override
  String get loginTitle => '登入';

  @override
  String get loginUsername => '使用者名稱';

  @override
  String get loginPassword => '密碼';

  @override
  String get loginSubmit => '登入';

  @override
  String get paywallTitle => '取得完整歌曲';

  @override
  String get paywallSubtitle => '把試聽變成一首附歌詞的 2 分鐘歌曲——可下載，任你使用。';

  @override
  String get paywallRestore => '回復購買項目';

  @override
  String get paywallAutoRenewNotice =>
      '確認購買時，將向你的 Apple 帳號收費。除非在目前訂閱期結束前至少 24 小時取消，否則訂閱將以相同價格與週期自動續訂。免費試用結束後將轉為付費訂閱。你可以隨時在 App Store 帳號設定中管理或取消訂閱。';

  @override
  String get paywallContinue => '繼續';

  @override
  String get paywallFreeTrial => '免費試用';

  @override
  String get paywallOffer => '優惠';

  @override
  String get paywallManage => '管理';

  @override
  String get paywallTermsOfUse => '使用條款';

  @override
  String get paywallPrivacyPolicy => '隱私權政策';

  @override
  String get paywallSubscriptionTerms => '訂閱條款';

  @override
  String get commonLinkError => '無法開啟連結。';

  @override
  String get commonError => '發生錯誤。';

  @override
  String get commonNetworkError => '網路錯誤——請檢查連線後再試一次。';

  @override
  String get commonOfflineError => '你似乎已離線。請檢查連線後再試一次。';

  @override
  String get networkErrorTitle => '連線問題';

  @override
  String get configErrorTitle => 'App 設定問題';

  @override
  String get configErrorMessage =>
      '此版本無法連線至我們的服務。請從 App Store 更新 App，或重新安裝。若問題持續發生，請聯絡客服。';

  @override
  String get commonAuthError => '登入階段已過期——請重新登入。';

  @override
  String get paywallProductsErrorTitle => '無法載入商品';

  @override
  String get paywallNoProducts => '目前沒有可購買的商品。';

  @override
  String get paywallPurchaseSuccess => '購買完成，盡情享受吧！';

  @override
  String get paywallProcessing => '正在處理你的購買…';

  @override
  String get paywallVerifying => '正在驗證你的購買…';

  @override
  String get paywallPurchaseFailed => '無法完成購買。';

  @override
  String get paywallRestoreStarted => '正在回復你的購買項目…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已回復 $countString 個購買項目。',
      one: '已回復 $countString 個購買項目。',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => '沒有可回復的購買項目。';

  @override
  String get paywallDeferred => '正在等待核准——核准後我們就會完成購買。';

  @override
  String get paywallAlreadySubscribed => '你已經訂閱了。';

  @override
  String get paywallBillingRetry => '請更新付款方式以保留你的訂閱。';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString 天免費試用';
  }

  @override
  String get cycleOneTime => '單次購買';

  @override
  String get cycleWeekly => '/ 週';

  @override
  String get cycleMonthly => '/ 月';

  @override
  String get cycleQuarterly => '/ 季';

  @override
  String get cycleSemiAnnual => '/ 6 個月';

  @override
  String get cycleAnnual => '/ 年';

  @override
  String get cycleLifetime => '終身';

  @override
  String get navCreate => '創作';

  @override
  String get navLibrary => '資料庫';

  @override
  String get navSettings => '設定';

  @override
  String get commonContinue => '繼續';

  @override
  String get commonBack => '返回';

  @override
  String get createTitle => '這首歌要送給誰？';

  @override
  String get occasionBirthday => '生日';

  @override
  String get occasionBirthdayHint => '為對方的大日子獻上歡樂的歌';

  @override
  String get occasionAnniversary => '紀念日';

  @override
  String get occasionAnniversaryHint => '慶祝你們一起走過的故事';

  @override
  String get occasionConfession => '告白';

  @override
  String get occasionConfessionHint => '說出你的真心話';

  @override
  String get occasionWedding => '婚禮';

  @override
  String get occasionWeddingHint => '獻給你們永恆時刻的歌';

  @override
  String get occasionMemorial => '追思';

  @override
  String get occasionMemorialHint => '紀念你珍愛的人';

  @override
  String get occasionFestival => '節日';

  @override
  String get occasionFestivalHint => '在特別的季節送上溫暖祝福';

  @override
  String get occasionBrand => '品牌廣告歌';

  @override
  String get occasionBrandHint => '為你的品牌打造朗朗上口的旋律';

  @override
  String get occasionSoundtrack => '影片配樂';

  @override
  String get occasionSoundtrackHint => '貼合你故事的音樂';

  @override
  String get festivalNewYear => '新年';

  @override
  String get festivalThanksgiving => '感恩節';

  @override
  String get festivalDiwali => '排燈節';

  @override
  String get festivalCarnival => '嘉年華';

  @override
  String get festivalEid => '開齋節';

  @override
  String get festivalLunarNewYear => '農曆新年';

  @override
  String get regionTitle => '這首歌會在哪裡播放？';

  @override
  String get regionSearchHint => '搜尋國家或地區';

  @override
  String get regionLanguageSheetTitle => '歌詞語言';

  @override
  String get countryUS => '美國';

  @override
  String get countryGB => '英國';

  @override
  String get countryCA => '加拿大';

  @override
  String get countryAU => '澳洲';

  @override
  String get countryDE => '德國';

  @override
  String get countryFR => '法國';

  @override
  String get countryJP => '日本';

  @override
  String get countryKR => '南韓';

  @override
  String get countryBR => '巴西';

  @override
  String get countryMX => '墨西哥';

  @override
  String get countryIN => '印度';

  @override
  String get countryID => '印尼';

  @override
  String get countryVN => '越南';

  @override
  String get countryTR => '土耳其';

  @override
  String get languageEn => '英文';

  @override
  String get languageFr => '法文';

  @override
  String get languageDe => '德文';

  @override
  String get languageJa => '日文';

  @override
  String get languageKo => '韓文';

  @override
  String get languagePtBR => '葡萄牙文（巴西）';

  @override
  String get languageEsMX => '西班牙文（墨西哥）';

  @override
  String get languageHi => '印地文';

  @override
  String get languageId => '印尼文';

  @override
  String get languageVi => '越南文';

  @override
  String get languageTr => '土耳其文';

  @override
  String get languageZhHans => '簡體中文';

  @override
  String get languageZhHant => '繁體中文';

  @override
  String get inputNameLabel => '對方的名字';

  @override
  String get inputNameOptionalLabel => '名字（選填）';

  @override
  String get inputNameHint => '例如：小安';

  @override
  String get inputKeywordsLabel => '用三個詞形容對方';

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
  String get inputLyricsOwnership => '這些歌詞是我原創的，或我有權使用';

  @override
  String get issueRecipientMissing => '請輸入對方的名字。';

  @override
  String get issueRecipientTooLong => '名字最多 24 個字元。';

  @override
  String get issueBriefMissing => '說說這首歌吧——寫幾句話、歌詞，或加入照片。';

  @override
  String get issueDescriptionMissing => '這個靈感需要你的文字——寫一句關於這首歌的話吧。';

  @override
  String get generatingBackToEdit => '返回修改';

  @override
  String get issueKeywordTooLong => '每個詞最多 20 個字元。';

  @override
  String get issueTooManyKeywords => '最多使用三個詞。';

  @override
  String get issueArtistName => '不能使用藝人名稱——試著描述你想要的感覺。';

  @override
  String get issueStyleImitation => '我們無法模仿歌手或樂團，試著描述你想要的氛圍。';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '歌詞最多 $limitString 個字元。';
  }

  @override
  String get issueLyricsNotOriginal => '這些歌詞看起來像現有的歌曲，請寫你自己的歌詞。';

  @override
  String get issueLyricsOwnership => '請確認你有權使用這些歌詞。';

  @override
  String get issueTooManyPhotos => '最多選擇 10 張照片。';

  @override
  String get photosTitle => '挑幾張照片';

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
  String get photosPrivacy => '照片只會用來創作這首歌一次，並在 24 小時內從我們的伺服器刪除。';

  @override
  String get photosAdd => '加入照片';

  @override
  String get photosCreate => '用照片創作';

  @override
  String get photosEmpty => '選擇 1–10 張記錄那一刻的照片。';

  @override
  String get generatingStepPolishing => '正在這部 iPhone 上潤飾你的文字…';

  @override
  String get generatingStepUploading => '正在傳送照片…';

  @override
  String get generatingStepSubmitting => '正在傳送到錄音室…';

  @override
  String get errorSafetyBlocked => '這首歌我們無法製作——請換些詞試試，也不要使用藝人名稱。';

  @override
  String get errorQuotaExhausted => '你已用完本月的歌曲。請加購歌曲包或升級。';

  @override
  String get errorUpstreamTimeout => '花費的時間比平常久。我們會繼續嘗試，並通知你。';

  @override
  String get errorUpstreamRateLimited => '目前有很多歌曲正在製作，你的歌已在排隊中。';

  @override
  String get errorAttestFailed => '請從 App Store 更新 Songlet。';

  @override
  String get errorImageRejected => '其中一張照片無法使用，請換一張試試。';

  @override
  String get errorNetworkOffline => '你已離線。資料庫仍可正常使用。';

  @override
  String get errorDownloadLocked => '這首歌目前無法下載——製作它的購買項目已退款，或你的方案已到期。你仍然可以播放它。';

  @override
  String get errorJobAlreadyFinished => '歌曲已完成，不需要取消。';

  @override
  String get errorMvSongNotReady => '這首歌還沒準備好製作影片。';

  @override
  String get errorMvSongTooLong => '這首歌太長，無法製作完整影片——試試副歌影片。';

  @override
  String get errorMvSongExpired => '這首歌已過期。請重新生成後再製作影片。';

  @override
  String get errorMvNotFound => '這個影片已不可用。';

  @override
  String get errorMvPhotosExpired => '這些照片已過期——請重新選擇。';

  @override
  String get errorMvRenderFailed => '這個影片沒能完成。點數已退回——再試一次。';

  @override
  String get mvHubTitle => '製作影片';

  @override
  String mvHubSubtitle(String title) {
    return '把《$title》變成一支音樂影片。';
  }

  @override
  String get mvLevelLyricVideo => '歌詞影片';

  @override
  String get mvLevelLyricHint => '一幅靜態畫面配上歌詞';

  @override
  String get mvLevelChorus => '副歌影片';

  @override
  String get mvLevelChorusHint => '30 秒副歌，由 AI 拍攝';

  @override
  String get mvLevelFull => '全曲影片';

  @override
  String get mvLevelFullHint => '整首歌，一幕接一幕';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString 點數',
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
      other: '你有 $creditsString 點數',
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
      other: '還差 $creditsString 點數',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => '正在查詢價格…';

  @override
  String get mvOptionsHeader => '選項';

  @override
  String get mvAspectLabel => '畫幅';

  @override
  String get mvAspectPortrait => '直式';

  @override
  String get mvAspectLandscape => '橫式';

  @override
  String get mvAspectSquare => '方形';

  @override
  String get mvQualityLabel => '畫質';

  @override
  String get mvQualityStandard => '標準';

  @override
  String get mvQualityHigh => '高畫質';

  @override
  String get mvSubtitlesLabel => '畫面顯示歌詞';

  @override
  String get mvPhotosLabel => '參考照片';

  @override
  String get mvPhotosHint => '設定場景與色調——不會使用人臉';

  @override
  String mvPhotosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 張',
    );
    return '$_temp0';
  }

  @override
  String get mvChorusLabel => '副歌';

  @override
  String get mvChorusAuto => '自動定位';

  @override
  String get mvChorusCustom => '自己選擇片段';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => '製作影片';

  @override
  String get mvBuyPack => '購買影片包並製作';

  @override
  String get mvSongLocked => '你的歌曲已為影片保存。';

  @override
  String get mvGeneratingTitle => '正在製作你的影片…';

  @override
  String get mvStageQueued => '等待開始';

  @override
  String get mvStageSlicing => '挑選片段';

  @override
  String get mvStageStoryboarding => '撰寫分鏡';

  @override
  String get mvStageKeyframing => '繪製場景';

  @override
  String get mvStageRendering => '拍攝場景';

  @override
  String get mvStageAssembling => '剪輯合成';

  @override
  String get mvStageDone => '完成';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '第 $doneString/$totalString 幕';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '通常約 $minutesString 分鐘';
  }

  @override
  String get mvCancelRequested => '將在目前場景結束後停止…';

  @override
  String get mvCancelTitle => '停止這個影片？';

  @override
  String get mvCancelQueued => '它還沒開始，不會使用任何點數。';

  @override
  String get mvCancelStarted => '它已經開始了。已完成的場景會計費，其餘點數退回。';

  @override
  String get mvCancelConfirm => '停止影片';

  @override
  String get mvCancelled => '影片已停止';

  @override
  String get mvCancelledRefunded => '影片已停止——未使用任何點數';

  @override
  String get mvNothing => '目前沒有正在製作的影片。';

  @override
  String get mvQuotaTitle => '點數不足';

  @override
  String get mvAiLabelBurnedIn => 'AI 生成——角標已燒錄進影片';

  @override
  String get mvSave => '儲存到照片';

  @override
  String get mvSaveFiles => '儲存到檔案';

  @override
  String get mvShareText => '我用 Songlet 做了這支音樂影片 🎬';

  @override
  String get mvMissing => '這個影片已不在此裝置上。';

  @override
  String get mvDeleteTitle => '刪除這個影片？';

  @override
  String get mvDeleteBody => '它將從此裝置上移除。';

  @override
  String get mvDeleted => '影片已刪除';

  @override
  String get mvProvenance => '由 Google Lyria 3 與 AI 影片模型製作 · AI 生成';

  @override
  String get detailVideos => '影片';

  @override
  String get detailMakeVideo => '製作影片';

  @override
  String get mvStatusReady => '已完成';

  @override
  String get mvStatusPending => '製作中…';

  @override
  String get mvStatusFailed => '未完成';

  @override
  String get mvPackTitle => '音樂影片';

  @override
  String get mvPackChorusSubtitle => '一支副歌影片';

  @override
  String get mvPackFullSubtitle => '一支全曲影片';

  @override
  String get paywallMvHeroTitle => '把它做成影片';

  @override
  String get paywallMvHeroSubtitle => '為你的歌曲製作音樂影片的點數——可儲存、可分享。';

  @override
  String get playerAiGenerated => 'AI 生成';

  @override
  String get playerLoop => '循環播放';

  @override
  String get playerPlay => '播放';

  @override
  String get playerPause => '暫停';

  @override
  String get playerPreviewLabel => '30 秒試聽';

  @override
  String playerTitleFor(String name) {
    return '獻給 $name';
  }

  @override
  String get downloadSaved => '已儲存到「檔案」。';

  @override
  String get shareComposing => '正在製作分享卡片…';

  @override
  String get shareFailed => '無法製作分享卡片。';

  @override
  String get shareText => '我用 Songlet 做了這首歌 🎵';

  @override
  String get paywallBestValue => '最划算';

  @override
  String get paywallStartTrial => '開始免費試用';

  @override
  String get paywallClose => '關閉';

  @override
  String get paywallSeePlans => '查看訂閱';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你的方案已生效——本期還剩 $countString 首完整歌曲。',
      one: '你的方案已生效——本期還剩 $countString 首完整歌曲。',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => '你的歌曲會保存在這裡。';

  @override
  String get libraryEmptyAction => '創作你的第一首歌';

  @override
  String get libraryPending => '作曲中…';

  @override
  String get libraryPreviewBadge => '試聽';

  @override
  String get librarySongBadge => '完整歌曲';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsPlan => '你的方案';

  @override
  String get settingsPlanUnavailable => '無法載入你的方案。請稍後下拉重試。';

  @override
  String get tierFree => '未訂閱';

  @override
  String get tierPack => '歌曲包';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '還剩 $countString 首完整歌曲',
      one: '還剩 $countString 首完整歌曲',
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
      other: '還剩 $countString 次試聽',
      one: '還剩 $countString 次試聽',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString 重設';
  }

  @override
  String get settingsUpgrade => '升級';

  @override
  String get appTagline => '為你愛的人寫一首歌';

  @override
  String get commonClose => '關閉';

  @override
  String get commonDone => '完成';

  @override
  String get commonDelete => '刪除';

  @override
  String get commonMore => '更多';

  @override
  String get commonCopy => '拷貝';

  @override
  String get commonCopied => '已拷貝';

  @override
  String get commonNotNow => '稍後再說';

  @override
  String get commonLearnMore => '了解更多';

  @override
  String get commonSeeAll => '查看全部';

  @override
  String get commonKeepGoing => '繼續生成';

  @override
  String get composerHint => '描述你想要的歌';

  @override
  String get composerAddPhotos => '加入照片';

  @override
  String get composerSourceMusicHint => '用你自己的話描述';

  @override
  String get composerDictate => '語音輸入';

  @override
  String get composerStopDictation => '停止語音輸入';

  @override
  String get lengthPreview => '試聽';

  @override
  String get lengthFull => '完整歌曲';

  @override
  String get paramLength => '長度';

  @override
  String get paramVocals => '人聲';

  @override
  String get paramGenre => '曲風';

  @override
  String templatePlaySample(String name) {
    return '試聽「$name」範例';
  }

  @override
  String get templatePauseSample => '暫停範例';

  @override
  String get lengthShort => '短';

  @override
  String get lengthShortHint => '30 秒試聽';

  @override
  String get lengthStandard => '標準';

  @override
  String get lengthStandardHint => '約 2 分鐘，Pro';

  @override
  String get vocalsCustom => '自訂';

  @override
  String get vocalsCustomHint => '依照你的描述';

  @override
  String get vocalsCustomDetail => '人聲風格依照你的描述。';

  @override
  String get vocalsOn => '有人聲';

  @override
  String get vocalsInstrumental => '純音樂';

  @override
  String vocalsLyricsIn(String language) {
    return '歌詞語言：$language';
  }

  @override
  String get genreCustom => '自訂';

  @override
  String get genreCustomHint => '依照你的描述';

  @override
  String genrePopularIn(String country) {
    return '$country熱門';
  }

  @override
  String get genreAll => '全部曲風';

  @override
  String get regionHelper => '會改變 3 個推薦曲風和歌詞語言';

  @override
  String regionLyricsRow(String language) {
    return '歌詞語言：$language';
  }

  @override
  String get regionNoMatch => '沒有符合的國家或地區';

  @override
  String get keywordAdd => '加入一個詞';

  @override
  String keywordRemove(String word) {
    return '移除「$word」';
  }

  @override
  String get nameClear => '清除名字';

  @override
  String get lyricsOptional => '自己寫歌詞（選填）';

  @override
  String get issueRecipientArtistName => '不能使用藝人名字。';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '描述請控制在 $limitString 個字元以內。';
  }

  @override
  String get voiceRecording => '正在錄音…';

  @override
  String get voiceStarting => '正在啟動…';

  @override
  String get voiceListening => '說說這首歌要送給誰、對方喜歡什麼…';

  @override
  String get voiceOnDevice => '本機轉寫';

  @override
  String get voicePermissionDenied => '請在「設定」中允許 Songlet 使用麥克風和語音辨識後再試。';

  @override
  String get voiceUnavailable => '此裝置不支援這個語言的語音輸入。';

  @override
  String get voiceApplied => '已從語音加入';

  @override
  String get photoRemove => '移除照片';

  @override
  String generatingTitleFor(String name) {
    return '正在為 $name 寫歌…';
  }

  @override
  String get generatingTitleGeneric => '正在寫你的歌…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '通常約 $secondsString 秒';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => '進度';

  @override
  String get generatingGlimpse => '搶先看一眼';

  @override
  String get generatingCancelTitle => '停止這首歌？';

  @override
  String get generatingCancelQueued => '還沒開始生成，不會扣除額度。';

  @override
  String get generatingCancelStarted => '已經開始生成，仍會計入額度。';

  @override
  String get generatingCancelConfirm => '停止';

  @override
  String get generatingCancelled => '已停止';

  @override
  String get generatingCancelledRefunded => '已停止——未扣除額度';

  @override
  String get queueTitle => '現在創作的人很多。';

  @override
  String get queueSubtitle => '你的歌正在排隊。';

  @override
  String get queuePosition => '排隊位置';

  @override
  String get queueWait => '預計等待';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '約 $minutesString 分鐘';
  }

  @override
  String get generatingNothing => '現在沒有正在生成的歌。';

  @override
  String get previewGetFull => '生成 2 分鐘完整版';

  @override
  String get previewShare => '分享試聽';

  @override
  String get previewAnother => '換一版（使用 1 次試聽）';

  @override
  String get playerPosition => '播放進度';

  @override
  String get playerPrevSection => '上一段';

  @override
  String get playerNextSection => '下一段';

  @override
  String get playerShuffle => '隨機段落';

  @override
  String get playerRepeat => '重複播放';

  @override
  String get playerProvenance => '由 Google Lyria 3 生成 · SynthID 浮水印 · AI 生成';

  @override
  String get playerMissing => '這首歌已不在此裝置上。';

  @override
  String get actionDownload => '下載';

  @override
  String get actionShare => '分享';

  @override
  String get actionLicense => '授權';

  @override
  String get actionRegenerate => '重新生成';

  @override
  String get actionDetails => '詳細資訊';

  @override
  String get sectionIntro => '前奏';

  @override
  String get sectionVerse => '主歌';

  @override
  String get sectionPreChorus => '導歌';

  @override
  String get sectionChorus => '副歌';

  @override
  String get sectionBridge => '橋段';

  @override
  String get sectionOutro => '尾奏';

  @override
  String get sectionHook => '記憶點';

  @override
  String get shareTitle => '分享卡片';

  @override
  String get shareSubtitle => '選擇主題和版面。';

  @override
  String get shareTheme => '主題';

  @override
  String get shareLayout => '版面';

  @override
  String get shareLayoutScene => '附插畫';

  @override
  String get shareLayoutText => '純文字';

  @override
  String get paletteTerracotta => '陶土';

  @override
  String get paletteSand => '沙色';

  @override
  String get paletteOlive => '橄欖';

  @override
  String get paletteNavy => '深藍';

  @override
  String get shareAction => '分享';

  @override
  String get shareSaveVideo => '儲存影片';

  @override
  String get shareCopyLyrics => '拷貝歌詞';

  @override
  String get shareVideoSaved => '已存入照片';

  @override
  String get shareLyricsCopied => '歌詞已拷貝';

  @override
  String get shareCardTagline => '為某個人寫的歌';

  @override
  String get shareSaveFailed => '無法儲存影片。請在「設定」中允許 Songlet 加入照片。';

  @override
  String get downloadReady => '完整版已就緒';

  @override
  String get downloadTitle => '永久屬於你';

  @override
  String get downloadIntro => '你的歌已完成。可在下方下載高品質音訊和商用授權。';

  @override
  String get downloadAudioHeader => '下載音訊';

  @override
  String get downloadAudioNote => '高品質';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle => '適合分享和日常聆聽';

  @override
  String get downloadWavTitle => 'WAV · 44.1 kHz（Premier）';

  @override
  String get downloadWavSubtitle => '專業用途的最高品質';

  @override
  String get downloadMp3Action => '下載 MP3';

  @override
  String get downloadWavAction => '下載 WAV';

  @override
  String get downloadLicenseAction => '下載授權文件';

  @override
  String get licenseHeader => '商用授權';

  @override
  String get licenseIncluded => '已包含在你的方案中';

  @override
  String get licenseNotIncluded => '購買方案或歌曲包後取得';

  @override
  String get licensePdfTitle => '商用授權（PDF）';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '產生於 $dateString';
  }

  @override
  String licenseId(String id) {
    return '授權編號：$id';
  }

  @override
  String get licenseUsesTitle => '這首歌可用於：';

  @override
  String get usePersonal => '個人使用';

  @override
  String get usePersonalDetail => '禮物、紀念、非商業用途';

  @override
  String get useAds => '廣告與行銷';

  @override
  String get useAdsDetail => '推廣、付費投放';

  @override
  String get useSocial => '社群媒體';

  @override
  String get useSocialDetail => 'TikTok、Instagram、YouTube 等';

  @override
  String get usePodcasts => 'Podcast 與影片';

  @override
  String get usePodcastsDetail => '可營利內容';

  @override
  String get licenseDetailsNote => '完整條款請見授權 PDF。';

  @override
  String get saveEnjoyHeader => '儲存與聆聽';

  @override
  String get saveToFiles => '儲存到「檔案」';

  @override
  String get addToMusic => '加入音樂';

  @override
  String get synthIdNote => '這首歌含有 SynthID 浮水印，下載後仍可辨識為 AI 生成內容。';

  @override
  String get wavNeedsPremier => 'WAV 下載僅限 Premier。';

  @override
  String get wavUnavailable => '這首歌沒有 WAV 檔案。WAV 需在歌曲生成後 24 小時內儲存。';

  @override
  String get libraryFilterAll => '全部';

  @override
  String get libraryJustBecause => '隨心而作';

  @override
  String libraryPlay(String title) {
    return '播放 $title';
  }

  @override
  String libraryActions(String title) {
    return '$title 的動作';
  }

  @override
  String get libraryDeleteTitle => '刪除這首歌？';

  @override
  String get libraryDeleteBody => '會從此裝置刪除。如果已開啟 iCloud 同步，也會從你的其他裝置刪除。';

  @override
  String get libraryDeleted => '已刪除';

  @override
  String get libraryFailed => '未完成';

  @override
  String get libraryNoMatch => '這個場合還沒有歌。';

  @override
  String get detailFullGenerated => '完整版已生成';

  @override
  String get detailPreviewGenerated => '試聽已生成';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '生成於 $dateString';
  }

  @override
  String get detailPromptUsed => '創作資訊';

  @override
  String get detailOccasion => '場合';

  @override
  String get detailCountry => '國家或地區';

  @override
  String get detailGenre => '曲風';

  @override
  String get detailKeywords => '關鍵詞';

  @override
  String get detailDescription => '描述';

  @override
  String get detailLyrics => '歌詞';

  @override
  String get detailGenerationId => '生成編號';

  @override
  String get detailRegenerate => '同風格再生成';

  @override
  String get detailCustomGenre => '依照描述';

  @override
  String get settingsSectionPlan => '購買項目';

  @override
  String get settingsSectionLibrary => '作品庫';

  @override
  String get settingsSectionAbout => '關於';

  @override
  String get settingsRestore => '回復購買';

  @override
  String get settingsManage => '管理訂閱';

  @override
  String get settingsICloud => 'iCloud 同步';

  @override
  String get settingsICloudOn => '歌曲會在你的裝置間同步';

  @override
  String get settingsICloudOff => '歌曲只保存在此裝置';

  @override
  String get settingsICloudUnavailable => '請先在「設定」中登入 iCloud';

  @override
  String get settingsLyricsLanguage => '預設歌詞語言';

  @override
  String get settingsLyricsLanguageAuto => '依照國家或地區';

  @override
  String get settingsTerms => '使用條款';

  @override
  String get settingsPrivacy => '隱私權政策';

  @override
  String settingsVersion(String version) {
    return '版本 $version';
  }

  @override
  String get aboutTitle => '關於生成';

  @override
  String get aboutSubtitle => 'Songlet 如何創作你的歌';

  @override
  String get aboutLyriaTitle => '由 Google Lyria 3 驅動';

  @override
  String get aboutLyriaBody =>
      '歌曲由 Google 的 Lyria 3 透過 Gemini API 生成。Lyria 3 是一個音樂生成模型，能把你的想法變成原創歌曲。';

  @override
  String get aboutWatermarkTitle => '內建浮水印';

  @override
  String get aboutWatermarkBody =>
      '每首歌都帶有 Google 的 SynthID 浮水印，用來辨識 AI 生成的音樂，且無法移除。';

  @override
  String get aboutImitationTitle => '不模仿真實藝人';

  @override
  String get aboutImitationBody =>
      'Songlet 從不模仿真實藝人、他們的聲音或特定風格。歌曲皆為原創，來自你的想法、描述和照片。';

  @override
  String get aboutPrivacyTitle => '重視你的隱私';

  @override
  String get aboutPrivacyBody => '照片和描述會在 24 小時內從伺服器刪除。歌曲生成後我們不會保留你的圖片或描述。';

  @override
  String get aboutBanner => '你分享的每首歌都會標示「AI 生成」。';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · 由 Google Lyria 3 生成';
  }

  @override
  String get festivalKicker => '記錄你的故事';

  @override
  String get festivalComing => '就要到了！';

  @override
  String get festivalBody => '寫一首獨一無二的歌來慶祝。';

  @override
  String festivalCta(String festival) {
    return '寫一首$festival的歌';
  }

  @override
  String get festivalPickOccasion => '選一個場合，開始創作';

  @override
  String get festivalLanguagesTitle => '用你的語言唱';

  @override
  String festivalLanguagesBody(String language) {
    return '支援$language等 13 種語言';
  }

  @override
  String get unavailableTitle => '暫時無法使用';

  @override
  String get unavailableMessage => 'Songlet 現在無法生成歌曲。作品庫仍可使用——請稍後再試。';

  @override
  String get paywallHeroTitle => '生成完整版';

  @override
  String get paywallHeroSubtitle => '把你的想法變成更高品質、擁有完整權利的歌曲。';

  @override
  String get paywallBenefitSongs => '更多歌曲';

  @override
  String get paywallBenefitQuality => '更高品質';

  @override
  String get paywallBenefitCommercial => '可商用';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '每月 $countString 首完整歌曲',
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
      other: '每月 $countString 次試聽',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'MP3 下載';

  @override
  String get planMp3Wav => 'MP3 + WAV 下載';

  @override
  String get planLicense => '商用授權';

  @override
  String get planPriority => '優先生成';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString 天免費試用';
  }

  @override
  String planPerYear(String price) {
    return '$price/年';
  }

  @override
  String planPerMonth(String price) {
    return '$price/月';
  }

  @override
  String get packTitle => '只需要幾首？';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 首歌曲包',
    );
    return '$_temp0';
  }

  @override
  String get packNote => '永不過期';

  @override
  String get valueForever => '你的歌永久保存';

  @override
  String get valueDownloads => '高品質下載';

  @override
  String get valueCommercial => '允許商用';

  @override
  String get valuePrivate => '隱私優先';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return '免費試用結束後，將自動按 $pricePerPeriod 收費。可在試用結束前隨時取消。';
  }

  @override
  String get paywallSubscribe => '訂閱';

  @override
  String get paywallBuyPack => '購買歌曲包';

  @override
  String get templateBirthdayWish => '生日祝福';

  @override
  String get templateBirthdayWishHint => '為對方的特別日子寫一首特別的歌';

  @override
  String get templateBirthdayParty => '生日派對';

  @override
  String get templateBirthdayPartyHint => '為壽星把派對氣氛炒熱';

  @override
  String get templateLoveStory => '愛情故事';

  @override
  String get templateLoveStoryHint => '把你們的故事寫成歌';

  @override
  String get templateThankAFriend => '感謝朋友';

  @override
  String get templateThankAFriendHint => '用歌說出說不出口的謝謝';

  @override
  String get templatePartyInvite => '派對邀請';

  @override
  String get templatePartyInviteHint => '把大家都找來';

  @override
  String get templateWedding => '婚禮';

  @override
  String get templateWeddingHint => '為他們的永恆時刻';

  @override
  String get templateInMemory => '紀念';

  @override
  String get templateInMemoryHint => '紀念你珍惜的人';

  @override
  String get templateFestival => '節日';

  @override
  String get templateFestivalHint => '為特別的季節送上祝福';

  @override
  String get templateRingtone => '鈴聲';

  @override
  String get templateRingtoneHint => '專屬於你的短循環';

  @override
  String get templateTeamAnthem => '隊歌';

  @override
  String get templateTeamAnthemHint => '點燃隊伍和觀眾';

  @override
  String get templateSportsRecap => '賽事回顧';

  @override
  String get templateSportsRecapHint => '把那場比賽唱出來';

  @override
  String get templateRapBattle => '饒舌對決';

  @override
  String get templateRapBattleHint => '給好對手的友好 battle';

  @override
  String get templateComedy => '搞笑';

  @override
  String get templateComedyHint => '把圈內梗唱成副歌';

  @override
  String get templatePetAnthem => '寵物之歌';

  @override
  String get templatePetAnthemHint => '給你的毛孩一首主題曲';

  @override
  String get templateHometown => '家鄉';

  @override
  String get templateHometownHint => '唱給你稱為家的地方';

  @override
  String get templateBusinessPromo => '小店宣傳';

  @override
  String get templateBusinessPromoHint => '給你的店或品牌一段洗腦旋律';

  @override
  String get templateCustom => '你的想法';

  @override
  String get mvRecommended => '推薦';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString 秒';
  }

  @override
  String get mvViewProgress => '查看進度';

  @override
  String mvIntentWaiting(String level) {
    return '$level正在等待點數';
  }

  @override
  String get mvSongExpiredAction => '重新產生這首歌';

  @override
  String mvQuotaNeed(String level, int required, int available) {
    final intl.NumberFormat requiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requiredString = requiredNumberFormat.format(required);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return '$level需要 $requiredString 點數，你現在有 $availableString。';
  }

  @override
  String get mvQuotaBuyAndContinue => '購買並繼續';

  @override
  String get mvQuotaMayNeedTwice => '在你所在的地區，一個包可能不夠，可能需要買兩個。';

  @override
  String get mvQuotaAutoRetry => '購買完成後影片會立即開始製作。';

  @override
  String get mvAutoLyricMaking => '正在製作歌詞影片';

  @override
  String get mvAutoChorusDetail => '用這首歌和你的點數製作';

  @override
  String mvAutoReady(String level) {
    return '$level已完成';
  }

  @override
  String get mvAutoView => '查看';

  @override
  String get mvUpgradeChorus => '製作副歌影片';

  @override
  String get mvAutoFailed => '影片未能開始';

  @override
  String get mvLeaveHint => '你可以離開此頁面，我們會在預計完成時通知你。';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '你的 $creditsString 點數已退回。',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => '這支影片沒有完成';

  @override
  String get mvRejectedTitle => '有一張照片無法使用';

  @override
  String get mvRejectedBody => '影片模型拒絕了你的一張參考照片。請調整照片後重試。';

  @override
  String get mvAdjustPhotos => '調整照片後重試';

  @override
  String get mvTryChorus => '改做副歌影片';

  @override
  String get mvPreparingPhotos => '正在上傳照片…';

  @override
  String get mvPreparingSubmit => '正在送出影片…';

  @override
  String get mvNotifyTitle => '你的影片應該做好了';

  @override
  String mvNotifyBody(String level) {
    return '$level——點一下觀看。';
  }

  @override
  String get mvRegenerate => '再做一支';

  @override
  String get mvEntryTitle => '做成影片';

  @override
  String get mvEntrySubtitle => '歌詞、副歌與整首影片，均使用點數';

  @override
  String get mvEntryDisabled => '歌曲完成後可用';

  @override
  String get mvEntryChoose => '選擇影片';

  @override
  String get mvEntryWatch => '觀看影片';

  @override
  String get mvChipReady => '影片';

  @override
  String get mvChipMaking => '影片製作中';

  @override
  String get lengthAutoVideo => '同時產生歌詞影片';

  @override
  String get lengthAutoVideoHint => '歌曲完成幾分鐘後即可 · 使用點數';

  @override
  String get lengthSongAndChorus => '歌曲 + 副歌影片';

  @override
  String get lengthSongAndChorusHint => '先產生整首歌，再做 30 秒副歌影片';

  @override
  String get paywallVideoGroup => '音樂影片';

  @override
  String get planVideoIncluded => '每月額度也可用於製作音樂影片';

  @override
  String get settingsVideoCredits => '影片點數';

  @override
  String get createGenrePop => '流行';

  @override
  String get createGenreHipHopRap => '嘻哈與饒舌';

  @override
  String get createGenreRock => '搖滾';

  @override
  String get createGenreKPop => '韓流';

  @override
  String get createGenreLatin => '拉丁';

  @override
  String get createGenreElectronic => '電子';

  @override
  String get createGenreRnb => '節奏藍調';

  @override
  String get createGenreCountry => '鄉村';

  @override
  String get createGenreAfrobeats => '非洲流行';

  @override
  String get createGenreReggae => '雷鬼';

  @override
  String get createGenreJazzBlues => '爵士與藍調';

  @override
  String get createGenreClassical => '古典';

  @override
  String get createGenreFolk => '民謠';

  @override
  String get createGenreLofi => '低傳真';

  @override
  String get createGenreAcoustic => '原聲';

  @override
  String get createGenreCinematic => '電影配樂';

  @override
  String get createGenreAmbient => '氛圍';

  @override
  String get createGenreBossaNova => '巴薩諾瓦';

  @override
  String get createGenreIndiePop => '獨立流行';

  @override
  String get createGenreContemporaryRnb => '當代節奏藍調';

  @override
  String get createGenreAlternativeCountry => '另類鄉村';

  @override
  String get createGenreGarageRock => '車庫搖滾';

  @override
  String get createGenreGrime => 'Grime';

  @override
  String get createGenreIndieFolk => '獨立民謠';

  @override
  String get createGenreSynthpop => '合成器流行';

  @override
  String get createGenrePianoBallad => '鋼琴抒情';

  @override
  String get createGenreSurfRock => '衝浪搖滾';

  @override
  String get createGenreDeepHouse => '深度浩室';

  @override
  String get createGenreMinimalTechno => '極簡電子';

  @override
  String get createGenreFrenchYeyePop => '法式復古流行';

  @override
  String get createGenreChillout => '輕鬆電子';

  @override
  String get createGenreJPopIndiePop => '日系獨立流行';

  @override
  String get createGenreChiptune => '晶片音樂';

  @override
  String get createGenreDiscoFunk => '迪斯可放克';

  @override
  String get createGenreReggaeton => '雷鬼頓';

  @override
  String get createGenreCumbia => '昆比亞';

  @override
  String get createGenreLatinJazz => '拉丁爵士';

  @override
  String get createGenreBhangra => '邦格拉';

  @override
  String get createGenreIndianClassical => '印度古典';

  @override
  String get createGenreLofiHipHop => '低傳真嘻哈';

  @override
  String profileAccountIdWithValue(String id) {
    return '帳號 ID: $id';
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
  String get createVocalsCustomSummary => '自訂 — 依照你的描述';

  @override
  String mvChipMakingWithProgress(String progress) {
    return '影片製作中 · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return '影片未能開始 · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    return '影片點數：$creditsString';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => '靈感';

  @override
  String inspirationPlay(String name) {
    return '播放「$name」';
  }

  @override
  String get inspirationStop => '停止試聽';

  @override
  String get inspirationNameSoundscape => '環境音景';

  @override
  String get inspirationStyleSoundscape => '氛圍音色，純音樂';

  @override
  String get inspirationNameBackgroundMusic => '背景音樂';

  @override
  String get inspirationStyleBackgroundMusic => '輕快純音樂配樂';

  @override
  String get inspirationNameMemorizeSomething => '記憶小曲';

  @override
  String get inspirationStyleMemorizeSomething => '朗朗上口的記憶流行曲';

  @override
  String get inspirationNameTextMessages => '簡訊成歌';

  @override
  String get inspirationStyleTextMessages => '把訊息唱出來的俏皮流行';

  @override
  String get inspirationNameIntroMusic => '開場音樂';

  @override
  String get inspirationStyleIntroMusic => '大氣電影感開場';

  @override
  String get inspirationNameMontage => '混剪配樂';

  @override
  String get inspirationStyleMontage => '高光混剪的遞進配樂';

  @override
  String get inspirationNameSayItWithATrack => '用歌說話';

  @override
  String get inspirationStyleSayItWithATrack => '深情流行抒情';

  @override
  String get inspirationNameBrandJingle => '品牌短曲';

  @override
  String get inspirationStyleBrandJingle => '簡短明亮好記的短曲';

  @override
  String get inspirationNameRingtone => '鈴聲';

  @override
  String get inspirationStyleRingtone => '30 秒可循環片段';

  @override
  String get inspirationNameStreaming => '直播';

  @override
  String get inspirationStyleStreaming => '動感電子直播開場';

  @override
  String get inspirationNameSpeechToTrack => '語音生成歌曲';

  @override
  String get inspirationStyleSpeechToTrack => '把說話變成歌';

  @override
  String get inspirationNameRapBattle => '饒舌對決';

  @override
  String get inspirationStyleRapBattle => '硬派嘻哈';

  @override
  String get inspirationNameComedy => '喜劇';

  @override
  String get inspirationStyleComedy => '俏皮歡快帶點調侃';

  @override
  String get inspirationNameTeamAnthem => '隊歌';

  @override
  String get inspirationStyleTeamAnthem => '體育場搖滾合唱';

  @override
  String get inspirationNameSportsRecap => '體育賽事回顧';

  @override
  String get inspirationStyleSportsRecap => '史詩管弦高光';

  @override
  String get inspirationNamePartyInvite => '派對邀請函';

  @override
  String get inspirationStylePartyInvite => '舞曲流行邀請';

  @override
  String get inspirationNameHappyBirthday => '生日祝福';

  @override
  String get inspirationStyleHappyBirthday => '溫暖原聲生日歌';

  @override
  String get inspirationNameFriendAppreciation => '感謝朋友';

  @override
  String get inspirationStyleFriendAppreciation => '療癒系獨立流行';

  @override
  String get inspirationNameLoveStory => '愛情故事';

  @override
  String get inspirationStyleLoveStory => '浪漫 R&B 抒情';

  @override
  String get inspirationNameBirthdayRoast => '生日慶祝';

  @override
  String get inspirationStyleBirthdayRoast => '幽默吐槽版生日歌';

  @override
  String get inspirationNameOdeToYourPet => '寵物頌歌';

  @override
  String get inspirationStyleOdeToYourPet => '可愛蹦跳的流行';

  @override
  String get inspirationNameHometownTribute => '家鄉特輯';

  @override
  String get inspirationStyleHometownTribute => '懷舊民謠';

  @override
  String get inspirationNameWeatherReport => '天氣報告';

  @override
  String get inspirationStyleWeatherReport => '輕鬆俏皮的沙發律動';

  @override
  String get inspirationNameBusinessPromo => '業務宣傳';

  @override
  String get inspirationStyleBusinessPromo => '自信商務流行';

  @override
  String get inspirationStyleBirthdayWish => '為 TA 的特別日子寫的走心歌';

  @override
  String get inspirationStyleBirthdayParty => '為壽星炒熱氣氛的派對歌';

  @override
  String get inspirationStyleThankAFriend => '溫暖真誠的感謝之歌';

  @override
  String get inspirationStyleWedding => '喜悅浪漫的婚禮之歌';

  @override
  String get inspirationStyleInMemory => '溫柔而有希望的紀念曲';

  @override
  String get inspirationStyleFestival => '明亮喜慶的節日祝福';

  @override
  String get inspirationStylePetAnthem => '親暱蹦跳的寵物主題曲';

  @override
  String get inspirationStyleHometown => '自豪又懷舊的家鄉之歌';

  @override
  String get settingsSectionLanguage => '語言';

  @override
  String get settingsSectionProfile => '個人資料';

  @override
  String get settingsCredits => '積分';

  @override
  String get settingsAccountId => '帳戶 ID';

  @override
  String get settingsCopyAccountId => '複製帳戶 ID';

  @override
  String get devSectionTitle => '開發者（僅 DEV）';

  @override
  String get devKeychainReset => '刪除 Keychain 金鑰';

  @override
  String get devKeychainResetHint => '裝置 ID 與工作階段權杖';

  @override
  String get devKeychainResetConfirmTitle => '刪除 Keychain 金鑰？';

  @override
  String get devKeychainResetConfirmBody =>
      '將從 Keychain 中清除裝置 ID 與工作階段權杖。目前的訪客帳戶無法復原，應用程式會以新訪客身分登入。';

  @override
  String get devKeychainResetDone => 'Keychain 金鑰已刪除——已以新訪客身分登入';

  @override
  String get settingsAppLanguage => '介面語言';

  @override
  String get settingsLanguageSystem => '跟隨系統';

  @override
  String settingsLanguageSystemValue(String language) {
    return '跟隨系統（$language）';
  }

  @override
  String get settingsLanguageNativeName => '繁體中文';

  @override
  String get settingsLanguageSaveFailed => '無法儲存語言，請再試一次。';

  @override
  String get settingsLyricsLanguageHint => '用於新建歌曲。';

  @override
  String composerRemoveInspiration(String name) {
    return '移除$name';
  }

  @override
  String get composerPromptHint => '描述這首歌，或在上方選一個靈感';

  @override
  String get composerPromptHintWide => '描述這首歌，或選一個靈感';

  @override
  String get composerWordsLabel => '你的內容';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已加入 $countString 張照片',
      one: '已加入 $countString 張照片',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return '歌曲選項：$summary';
  }

  @override
  String get composerOptionsShow => '展開歌曲選項';

  @override
  String get composerOptionsHide => '收起歌曲選項';

  @override
  String get composerSummaryAnyVocals => '人聲不限';

  @override
  String get composerSummaryAnyGenre => '曲風不限';

  @override
  String get composerSummaryLyrics => '自寫歌詞';

  @override
  String get composerSummaryVideo => '歌詞影片';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': '生成試聽 · 免費',
      'preview': '生成試聽 · 1 次試聽',
      'other': '生成試聽',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': '為 $name 生成試聽 · 免費',
      'preview': '為 $name 生成試聽 · 1 次試聽',
      'other': '為 $name 生成試聽',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': '生成完整歌曲 · 1 首',
      'other': '生成完整歌曲',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => '使用這段文字';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level將在 $seconds 秒後開始';
  }

  @override
  String planPerWeek(String price) {
    return '$price/週';
  }

  @override
  String get planCreditsWeekly => '每週補充點數';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': '首日',
      'week': '首週',
      'month': '首月',
      'year': '首年',
      'other': '首期',
    });
    return '$_temp0立減 $percent%';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return '優惠價 $introPrice 結束後，將自動按 $pricePerPeriod 續費。可在續費前隨時取消。';
  }

  @override
  String get storePreviewAHook => '從 TA 的名字開始';

  @override
  String get storePreviewAWords => '寫下關於 TA 的三個詞';

  @override
  String get storePreviewAWait => '正在為你寫歌';

  @override
  String get storePreviewAChorus => '副歌裡唱出 TA 的名字';

  @override
  String get storePreviewAEnd => '一首唱著 TA 名字的歌';

  @override
  String get storePreviewBHook => '從你的照片開始';

  @override
  String get storePreviewBVideo => '同時生成歌詞影片';

  @override
  String get storePreviewBWait => '正在寫歌';

  @override
  String get storePreviewBLyrics => '歌詞同步上螢幕';

  @override
  String get storePreviewBMood => '照片定下歌的氛圍。';

  @override
  String get storePreviewBShare => '分享這段影片。';

  @override
  String get storePreviewBLanguage => '用你的語言寫歌詞';

  @override
  String get storePreviewAShare => '做成卡片送給 TA';

  @override
  String get storePreviewCta => '寫下你的第一首歌';

  @override
  String get storePreviewDisclosure => '需訂閱或點數';

  @override
  String get storeCreativeHeader => '為你愛的人寫一首歌';

  @override
  String get storeCreativeSearch => '一個名字，寫成一首歌';

  @override
  String get storeCreativeBirthday => '唱出TA名字的生日歌';

  @override
  String get storeCreativePhoto => '讓照片變成一首歌';

  @override
  String get storeCreativeWedding => '獻給你們婚禮的歌';
}
