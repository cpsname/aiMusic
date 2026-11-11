// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get commonRetry => '再試行';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get startupLoading => 'チューニング中…';

  @override
  String get commonErrorTitle => '問題が発生しました';

  @override
  String get updateRequiredTitle => 'アップデートが必要です';

  @override
  String get updateRequiredMessage => '続けるには新しいバージョンが必要です。';

  @override
  String get updateNow => '今すぐアップデート';

  @override
  String get maintenanceTitle => 'メンテナンス中';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '約$minutesString分後に再開予定';
  }

  @override
  String get featureUnavailable => 'この機能は一時的にご利用いただけません。';

  @override
  String get navProfile => 'プロフィール';

  @override
  String get navStore => 'ストア';

  @override
  String get navUpload => 'アップロード';

  @override
  String get uploadTitle => 'アップロード';

  @override
  String get uploadSubtitle => '署名付きURLでR2へ直接アップロード（ハッシュ計算・即時重複排除・進捗表示）。';

  @override
  String get uploadPick => '画像を選んでアップロード';

  @override
  String get uploadAgain => '別のファイルをアップロード';

  @override
  String get uploadPhaseHashing => 'ハッシュを計算中…';

  @override
  String get uploadPhaseSigning => 'アップロード許可を取得中…';

  @override
  String uploadPhaseUploading(String percent) {
    return 'アップロード中 $percent';
  }

  @override
  String get uploadPhaseFinalizing => '完了処理中…';

  @override
  String get uploadDone => 'アップロードしました。';

  @override
  String get uploadDedup => '即時完了：このファイルはすでにサーバーにありました。';

  @override
  String get uploadOpenLink => 'ファイルを表示';

  @override
  String get uploadFailed => 'アップロードに失敗しました。';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'ファイルが大きすぎます（最大 $limitString MB）。';
  }

  @override
  String get uploadUnsupportedType => 'サポートされていないファイル形式です。';

  @override
  String get profileGuestTitle => 'ゲスト';

  @override
  String get profileGuestSubtitle => 'サインインすると、購入内容を複数のデバイスで引き継げます。';

  @override
  String get signIn => 'サインイン';

  @override
  String get signOut => 'サインアウト';

  @override
  String get profileBalanceLabel => 'クレジット';

  @override
  String get profileAccountId => 'アカウントID';

  @override
  String get profileFeaturesLabel => '有効な特典';

  @override
  String get profileNoFeatures => '有効な特典はまだありません。';

  @override
  String get profileSubscriptionLabel => 'サブスクリプション';

  @override
  String get profileManageSubscription => 'サブスクリプションを管理';

  @override
  String get subscriptionActive => '有効';

  @override
  String get subscriptionInactive => 'なし';

  @override
  String get profileDeleteAccount => 'アカウントを削除';

  @override
  String get deleteAccountTitle => 'このアカウントを削除しますか？';

  @override
  String get deleteAccountMessage =>
      'この操作は取り消せません。このアカウントとそのクレジット・特典の記録には今後一切アクセスできなくなり、新しいアカウントが作成されます。有効な App Store のサブスクリプションは、アカウントを削除しても解約されません。App Store の設定で管理するか、後で「購入を復元」から再度関連付けてください。';

  @override
  String get deleteAccountConfirm => '削除';

  @override
  String get deleteAccountWorking => 'アカウントを削除中…';

  @override
  String get deleteAccountDone => 'アカウントを削除しました。';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateStringからのメンバー';
  }

  @override
  String get loginTitle => 'サインイン';

  @override
  String get loginUsername => 'ユーザー名';

  @override
  String get loginPassword => 'パスワード';

  @override
  String get loginSubmit => 'サインイン';

  @override
  String get paywallTitle => 'フルバージョンを手に入れよう';

  @override
  String get paywallSubtitle => 'プレビューを歌詞付きの2分間の曲に。ダウンロードして自由に使えます。';

  @override
  String get paywallRestore => '購入を復元';

  @override
  String get paywallAutoRenewNotice =>
      '購入の確定時に Apple アカウントに請求されます。サブスクリプションは、現在の期間が終了する24時間以上前にキャンセルしない限り、同じ価格・期間で自動的に更新されます。無料トライアルは終了時に有料サブスクリプションに移行します。管理やキャンセルは App Store のアカウント設定からいつでも行えます。';

  @override
  String get paywallContinue => '続ける';

  @override
  String get paywallFreeTrial => '無料トライアル';

  @override
  String get paywallOffer => 'オファー';

  @override
  String get paywallManage => '管理';

  @override
  String get paywallTermsOfUse => '利用規約';

  @override
  String get paywallPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get paywallSubscriptionTerms => 'サブスクリプション規約';

  @override
  String get commonLinkError => 'リンクを開けませんでした。';

  @override
  String get commonError => '問題が発生しました。';

  @override
  String get commonNetworkError => 'ネットワークエラーです。接続を確認して、もう一度お試しください。';

  @override
  String get commonOfflineError => 'オフラインのようです。接続を確認して、もう一度お試しください。';

  @override
  String get networkErrorTitle => '接続の問題';

  @override
  String get configErrorTitle => 'アプリの設定に問題があります';

  @override
  String get configErrorMessage =>
      'このバージョンではサービスに接続できません。App Store からアプリをアップデートするか、再インストールしてください。問題が解決しない場合は、サポートまでお問い合わせください。';

  @override
  String get commonAuthError => 'セッションの有効期限が切れました。もう一度サインインしてください。';

  @override
  String get paywallProductsErrorTitle => '商品を読み込めませんでした';

  @override
  String get paywallNoProducts => '現在購入できる商品はありません。';

  @override
  String get paywallPurchaseSuccess => '購入が完了しました。お楽しみください！';

  @override
  String get paywallProcessing => '購入を処理中…';

  @override
  String get paywallVerifying => '購入を確認中…';

  @override
  String get paywallPurchaseFailed => '購入を完了できませんでした。';

  @override
  String get paywallRestoreStarted => '購入を復元中…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString件の購入を復元しました。',
      one: '$countString件の購入を復元しました。',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => '復元できる購入はありません。';

  @override
  String get paywallDeferred => '承認を待っています。承認され次第、購入を完了します。';

  @override
  String get paywallAlreadySubscribed => 'すでに登録済みです。';

  @override
  String get paywallBillingRetry => 'サブスクリプションを継続するには、お支払い方法を更新してください。';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString日間無料トライアル';
  }

  @override
  String get cycleOneTime => '買い切り';

  @override
  String get cycleWeekly => '/ 週';

  @override
  String get cycleMonthly => '/ 月';

  @override
  String get cycleQuarterly => '/ 四半期';

  @override
  String get cycleSemiAnnual => '/ 6か月';

  @override
  String get cycleAnnual => '/ 年';

  @override
  String get cycleLifetime => '永久';

  @override
  String get navCreate => '作成';

  @override
  String get navLibrary => 'ライブラリ';

  @override
  String get navSettings => '設定';

  @override
  String get commonContinue => '続ける';

  @override
  String get commonBack => '戻る';

  @override
  String get createTitle => '誰に贈る曲ですか？';

  @override
  String get occasionBirthday => '誕生日';

  @override
  String get occasionBirthdayHint => '特別な日を彩る楽しい曲';

  @override
  String get occasionAnniversary => '記念日';

  @override
  String get occasionAnniversaryHint => 'ふたりの物語をお祝い';

  @override
  String get occasionConfession => '告白';

  @override
  String get occasionConfessionHint => '心の想いを伝えよう';

  @override
  String get occasionWedding => '結婚式';

  @override
  String get occasionWeddingHint => '永遠の瞬間に贈る曲';

  @override
  String get occasionMemorial => '追悼';

  @override
  String get occasionMemorialHint => '大切な人をしのんで';

  @override
  String get occasionFestival => '季節のお祝い';

  @override
  String get occasionFestivalHint => '特別な季節にあたたかい祝福を';

  @override
  String get occasionBrand => 'ブランドジングル';

  @override
  String get occasionBrandHint => 'ブランドのための耳に残るメロディ';

  @override
  String get occasionSoundtrack => '動画のBGM';

  @override
  String get occasionSoundtrackHint => 'あなたのストーリーに合う音楽';

  @override
  String get festivalNewYear => '新年';

  @override
  String get festivalThanksgiving => '感謝祭';

  @override
  String get festivalDiwali => 'ディワリ';

  @override
  String get festivalCarnival => 'カーニバル';

  @override
  String get festivalEid => 'イード';

  @override
  String get festivalLunarNewYear => '旧正月';

  @override
  String get regionTitle => 'どこで聴かれる曲ですか？';

  @override
  String get regionSearchHint => '国を検索';

  @override
  String get regionLanguageSheetTitle => '歌詞の言語';

  @override
  String get countryUS => 'アメリカ合衆国';

  @override
  String get countryGB => 'イギリス';

  @override
  String get countryCA => 'カナダ';

  @override
  String get countryAU => 'オーストラリア';

  @override
  String get countryDE => 'ドイツ';

  @override
  String get countryFR => 'フランス';

  @override
  String get countryJP => '日本';

  @override
  String get countryKR => '韓国';

  @override
  String get countryBR => 'ブラジル';

  @override
  String get countryMX => 'メキシコ';

  @override
  String get countryIN => 'インド';

  @override
  String get countryID => 'インドネシア';

  @override
  String get countryVN => 'ベトナム';

  @override
  String get countryTR => 'トルコ';

  @override
  String get languageEn => '英語';

  @override
  String get languageFr => 'フランス語';

  @override
  String get languageDe => 'ドイツ語';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '韓国語';

  @override
  String get languagePtBR => 'ポルトガル語（ブラジル）';

  @override
  String get languageEsMX => 'スペイン語（メキシコ）';

  @override
  String get languageHi => 'ヒンディー語';

  @override
  String get languageId => 'インドネシア語';

  @override
  String get languageVi => 'ベトナム語';

  @override
  String get languageTr => 'トルコ語';

  @override
  String get languageZhHans => '中国語（簡体字）';

  @override
  String get languageZhHant => '中国語（繁体字）';

  @override
  String get inputNameLabel => '相手の名前';

  @override
  String get inputNameOptionalLabel => '名前（任意）';

  @override
  String get inputNameHint => '例：ゆうき';

  @override
  String get inputKeywordsLabel => 'その人を表す3つの言葉';

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
  String get inputLyricsOwnership => 'この歌詞は自分で書いたもの、または使用する権利があるものです';

  @override
  String get issueRecipientMissing => '名前を入力してください。';

  @override
  String get issueRecipientTooLong => '名前は24文字までです。';

  @override
  String get issueBriefMissing => 'どんな曲にしたいか教えてください（ひとこと、歌詞、または写真）。';

  @override
  String get issueDescriptionMissing => 'このアイデアにはあなたの言葉が必要です。曲についてひとこと書いてください。';

  @override
  String get generatingBackToEdit => '編集に戻る';

  @override
  String get issueKeywordTooLong => '言葉はそれぞれ20文字までです。';

  @override
  String get issueTooManyKeywords => '言葉は3つまでです。';

  @override
  String get issueArtistName => 'アーティスト名は使用できません。代わりに気持ちを表現してください。';

  @override
  String get issueStyleImitation => '歌手やバンドを真似ることはできません。代わりに雰囲気を表現してください。';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '歌詞は$limitString文字までです。';
  }

  @override
  String get issueLyricsNotOriginal => 'この歌詞は既存の曲のようです。オリジナルの歌詞を書いてください。';

  @override
  String get issueLyricsOwnership => '歌詞を使用する権利があることを確認してください。';

  @override
  String get issueTooManyPhotos => '写真は10枚まで選べます。';

  @override
  String get photosTitle => '写真を何枚か選んでください';

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
  String get photosPrivacy => '写真は曲づくりに一度だけ使用され、24時間以内にサーバーから削除されます。';

  @override
  String get photosAdd => '写真を追加';

  @override
  String get photosCreate => '写真から作成';

  @override
  String get photosEmpty => 'その瞬間の写真を1〜10枚選んでください。';

  @override
  String get generatingStepPolishing => 'このiPhoneで言葉を磨いています…';

  @override
  String get generatingStepUploading => '写真を送信中…';

  @override
  String get generatingStepSubmitting => 'スタジオに送信中…';

  @override
  String get errorSafetyBlocked => 'この内容では曲を作れません。別の言葉を試し、アーティスト名は使わないでください。';

  @override
  String get errorQuotaExhausted => '今月の曲をすべて使い切りました。パックを追加するか、アップグレードしてください。';

  @override
  String get errorUpstreamTimeout => 'いつもより時間がかかっています。引き続き試して、お知らせします。';

  @override
  String get errorUpstreamRateLimited => '現在たくさんの曲が作られています。あなたの曲は順番待ちです。';

  @override
  String get errorAttestFailed => 'App Store から Songlet をアップデートしてください。';

  @override
  String get errorImageRejected => '使用できない写真があります。別の写真をお試しください。';

  @override
  String get errorNetworkOffline => 'オフラインです。ライブラリは引き続き利用できます。';

  @override
  String get errorDownloadLocked =>
      'この曲はダウンロードできません。作成に使った購入が返金されたか、プランの期間が終了しています。再生は引き続きできます。';

  @override
  String get errorJobAlreadyFinished => 'すでに完成しているため、キャンセルは不要です。';

  @override
  String get errorMvSongNotReady => 'この曲はまだビデオを作れる状態ではありません。';

  @override
  String get errorMvSongTooLong => 'この曲は長すぎてフルビデオにできません。サビのビデオをお試しください。';

  @override
  String get errorMvSongExpired => 'この曲は期限切れです。もう一度生成してからビデオを作ってください。';

  @override
  String get errorMvNotFound => 'このビデオはもう利用できません。';

  @override
  String get errorMvPhotosExpired => '写真の期限が切れました。もう一度選んでください。';

  @override
  String get errorMvRenderFailed =>
      'このビデオを完成できませんでした。クレジットは返却済みです。もう一度お試しください。';

  @override
  String get mvHubTitle => 'ビデオを作る';

  @override
  String mvHubSubtitle(String title) {
    return '「$title」をミュージックビデオにしましょう。';
  }

  @override
  String get mvLevelLyricVideo => 'リリックビデオ';

  @override
  String get mvLevelLyricHint => '静止画に歌詞を重ねる';

  @override
  String get mvLevelChorus => 'サビのビデオ';

  @override
  String get mvLevelChorusHint => 'サビの30秒をAIが撮影';

  @override
  String get mvLevelFull => 'フルソングビデオ';

  @override
  String get mvLevelFullHint => '曲全体をシーンごとに';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsStringクレジット',
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
      other: '残り$creditsStringクレジット',
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
      other: 'あと$creditsStringクレジット必要',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => '価格を確認しています…';

  @override
  String get mvOptionsHeader => 'オプション';

  @override
  String get mvAspectLabel => '画面の向き';

  @override
  String get mvAspectPortrait => '縦';

  @override
  String get mvAspectLandscape => '横';

  @override
  String get mvAspectSquare => '正方形';

  @override
  String get mvQualityLabel => '画質';

  @override
  String get mvQualityStandard => '標準';

  @override
  String get mvQualityHigh => '高';

  @override
  String get mvSubtitlesLabel => '歌詞を画面に表示';

  @override
  String get mvPhotosLabel => '参考写真';

  @override
  String get mvPhotosHint => '雰囲気と色味の参考に — 顔は使われません';

  @override
  String mvPhotosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString枚',
    );
    return '$_temp0';
  }

  @override
  String get mvChorusLabel => 'サビ';

  @override
  String get mvChorusAuto => '自動で検出';

  @override
  String get mvChorusCustom => '自分で選ぶ';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => 'ビデオを作る';

  @override
  String get mvBuyPack => 'パックを買って作る';

  @override
  String get mvSongLocked => 'この曲はビデオ用に保存されました。';

  @override
  String get mvGeneratingTitle => 'ビデオを作成中…';

  @override
  String get mvStageQueued => '開始待ち';

  @override
  String get mvStageSlicing => 'シーンを選んでいます';

  @override
  String get mvStageStoryboarding => '絵コンテを作成中';

  @override
  String get mvStageKeyframing => 'シーンを描いています';

  @override
  String get mvStageRendering => 'シーンを撮影中';

  @override
  String get mvStageAssembling => '編集しています';

  @override
  String get mvStageDone => '完了';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'シーン $doneString/$totalString';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '通常$minutesString分ほど';
  }

  @override
  String get mvCancelRequested => '現在のシーンの後に停止します…';

  @override
  String get mvCancelTitle => 'このビデオを中止しますか？';

  @override
  String get mvCancelQueued => 'まだ始まっていないので、何も消費されません。';

  @override
  String get mvCancelStarted => 'すでに始まっています。完成したシーン分は請求され、残りは返却されます。';

  @override
  String get mvCancelConfirm => 'ビデオを中止';

  @override
  String get mvCancelled => 'ビデオを中止しました';

  @override
  String get mvCancelledRefunded => 'ビデオを中止しました — 何も消費されていません';

  @override
  String get mvNothing => '現在作成中のビデオはありません。';

  @override
  String get mvQuotaTitle => 'クレジットが足りません';

  @override
  String get mvAiLabelBurnedIn => 'AI生成 — バッジは映像に埋め込まれています';

  @override
  String get mvSave => '写真に保存';

  @override
  String get mvSaveFiles => 'ファイルに保存';

  @override
  String get mvShareText => 'Songletでこのミュージックビデオを作りました 🎬';

  @override
  String get mvMissing => 'このビデオはもうこのデバイスにありません。';

  @override
  String get mvDeleteTitle => 'このビデオを削除しますか？';

  @override
  String get mvDeleteBody => 'このデバイスから削除されます。';

  @override
  String get mvDeleted => 'ビデオを削除しました';

  @override
  String get mvProvenance => 'Google Lyria 3とAI動画モデルで制作 · AI生成';

  @override
  String get detailVideos => 'ビデオ';

  @override
  String get detailMakeVideo => 'ビデオを作る';

  @override
  String get mvStatusReady => '完成';

  @override
  String get mvStatusPending => '作成中…';

  @override
  String get mvStatusFailed => '未完了';

  @override
  String get mvPackTitle => 'ミュージックビデオ';

  @override
  String get mvPackChorusSubtitle => 'サビのビデオ1本';

  @override
  String get mvPackFullSubtitle => 'フルソングビデオ1本';

  @override
  String get paywallMvHeroTitle => 'ビデオにしよう';

  @override
  String get paywallMvHeroSubtitle => 'あなたの曲のミュージックビデオ用クレジット — 保存も共有も自由。';

  @override
  String get playerAiGenerated => 'AI生成';

  @override
  String get playerLoop => 'ループ';

  @override
  String get playerPlay => '再生';

  @override
  String get playerPause => '一時停止';

  @override
  String get playerPreviewLabel => '30秒プレビュー';

  @override
  String playerTitleFor(String name) {
    return '$nameへ';
  }

  @override
  String get downloadSaved => '「ファイル」に保存しました。';

  @override
  String get shareComposing => 'シェアカードを作成中…';

  @override
  String get shareFailed => 'シェアカードを作成できませんでした。';

  @override
  String get shareText => 'Songlet でこの曲を作りました 🎵';

  @override
  String get paywallBestValue => 'いちばんお得';

  @override
  String get paywallStartTrial => '無料トライアルを開始';

  @override
  String get paywallClose => '閉じる';

  @override
  String get paywallSeePlans => 'サブスクリプションを見る';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'プランは有効です。今期のフルバージョンは残り$countString曲です。',
      one: 'プランは有効です。今期のフルバージョンは残り$countString曲です。',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => '作った曲はここに保存されます。';

  @override
  String get libraryEmptyAction => '最初の曲を作る';

  @override
  String get libraryPending => '作曲中…';

  @override
  String get libraryPreviewBadge => 'プレビュー';

  @override
  String get librarySongBadge => 'フルバージョン';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsPlan => 'あなたのプラン';

  @override
  String get settingsPlanUnavailable =>
      'プランを読み込めませんでした。しばらくしてから下に引っ張って再試行してください。';

  @override
  String get tierFree => 'サブスクなし';

  @override
  String get tierPack => 'ソングパック';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'フルバージョン残り$countString曲',
      one: 'フルバージョン残り$countString曲',
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
      other: 'プレビュー残り$countString回',
      one: 'プレビュー残り$countString回',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateStringにリセット';
  }

  @override
  String get settingsUpgrade => 'アップグレード';

  @override
  String get appTagline => '大切な人に贈る歌を';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonDone => '完了';

  @override
  String get commonDelete => '削除';

  @override
  String get commonMore => 'その他';

  @override
  String get commonCopy => 'コピー';

  @override
  String get commonCopied => 'コピーしました';

  @override
  String get commonNotNow => 'あとで';

  @override
  String get commonLearnMore => '詳しく見る';

  @override
  String get commonSeeAll => 'すべて見る';

  @override
  String get commonKeepGoing => '続ける';

  @override
  String get composerHint => '作りたい歌を書いてください';

  @override
  String get composerAddPhotos => '写真を追加';

  @override
  String get composerSourceMusicHint => '自分の言葉で書く';

  @override
  String get composerDictate => '音声入力';

  @override
  String get composerStopDictation => '音声入力を停止';

  @override
  String get lengthPreview => '試聴';

  @override
  String get lengthFull => 'フルバージョン';

  @override
  String get paramLength => '長さ';

  @override
  String get paramVocals => 'ボーカル';

  @override
  String get paramGenre => 'ジャンル';

  @override
  String templatePlaySample(String name) {
    return '「$name」のサンプルを再生';
  }

  @override
  String get templatePauseSample => 'サンプルを一時停止';

  @override
  String get lengthShort => 'ショート';

  @override
  String get lengthShortHint => '30 秒の試聴';

  @override
  String get lengthStandard => 'スタンダード';

  @override
  String get lengthStandardHint => '約 2 分、Pro';

  @override
  String get vocalsCustom => 'おまかせ';

  @override
  String get vocalsCustomHint => '説明に合わせる';

  @override
  String get vocalsCustomDetail => 'ボーカルのスタイルは説明に合わせます。';

  @override
  String get vocalsOn => 'ボーカルあり';

  @override
  String get vocalsInstrumental => 'インスト';

  @override
  String vocalsLyricsIn(String language) {
    return '歌詞の言語：$language';
  }

  @override
  String get genreCustom => 'おまかせ';

  @override
  String get genreCustomHint => '説明に合わせる';

  @override
  String genrePopularIn(String country) {
    return '$countryで人気';
  }

  @override
  String get genreAll => 'すべてのジャンル';

  @override
  String get regionHelper => 'おすすめの 3 ジャンルと歌詞の言語が変わります';

  @override
  String regionLyricsRow(String language) {
    return '歌詞の言語：$language';
  }

  @override
  String get regionNoMatch => '該当する国・地域がありません';

  @override
  String get keywordAdd => '言葉を追加';

  @override
  String keywordRemove(String word) {
    return '「$word」を削除';
  }

  @override
  String get nameClear => '名前を消去';

  @override
  String get lyricsOptional => '自分で歌詞を書く（任意）';

  @override
  String get issueRecipientArtistName => 'アーティスト名は使えません。';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '説明は $limitString 文字以内にしてください。';
  }

  @override
  String get voiceRecording => '録音中…';

  @override
  String get voiceStarting => '開始しています…';

  @override
  String get voiceListening => '誰に贈るか、その人の好きなものを話してください…';

  @override
  String get voiceOnDevice => 'デバイス上で文字起こし';

  @override
  String get voicePermissionDenied =>
      '音声入力するには、設定で Songlet にマイクと音声認識を許可してください。';

  @override
  String get voiceUnavailable => 'このデバイスではこの言語の音声入力を利用できません。';

  @override
  String get voiceApplied => '音声から追加しました';

  @override
  String get photoRemove => '写真を削除';

  @override
  String generatingTitleFor(String name) {
    return '$nameさんの歌を作成中…';
  }

  @override
  String get generatingTitleGeneric => '歌を作成中…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '通常 $secondsString 秒ほど';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => '進行状況';

  @override
  String get generatingGlimpse => '歌詞をちょっとだけ';

  @override
  String get generatingCancelTitle => 'この曲の作成を中止しますか？';

  @override
  String get generatingCancelQueued => 'まだ始まっていないので、回数は消費されません。';

  @override
  String get generatingCancelStarted => 'すでに始まっているため、回数は消費されます。';

  @override
  String get generatingCancelConfirm => '中止する';

  @override
  String get generatingCancelled => '中止しました';

  @override
  String get generatingCancelledRefunded => '中止しました（消費なし）';

  @override
  String get queueTitle => 'いま多くの曲が作られています。';

  @override
  String get queueSubtitle => '順番待ちです。';

  @override
  String get queuePosition => '待ち順';

  @override
  String get queueWait => '予想待ち時間';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '約 $minutesString 分';
  }

  @override
  String get generatingNothing => 'いま作成中の曲はありません。';

  @override
  String get previewGetFull => '2 分のフル曲にする';

  @override
  String get previewShare => '試聴をシェア';

  @override
  String get previewAnother => '別バージョンを試す（試聴 1 回分）';

  @override
  String get playerPosition => '再生位置';

  @override
  String get playerPrevSection => '前のセクション';

  @override
  String get playerNextSection => '次のセクション';

  @override
  String get playerShuffle => 'セクションをシャッフル';

  @override
  String get playerRepeat => 'リピート';

  @override
  String get playerProvenance => 'Google Lyria 3 で生成 · SynthID 透かし · AI 生成';

  @override
  String get playerMissing => 'この曲はもうこのデバイスにありません。';

  @override
  String get actionDownload => 'ダウンロード';

  @override
  String get actionShare => 'シェア';

  @override
  String get actionLicense => 'ライセンス';

  @override
  String get actionRegenerate => '作り直す';

  @override
  String get actionDetails => '詳細';

  @override
  String get sectionIntro => 'イントロ';

  @override
  String get sectionVerse => 'A メロ';

  @override
  String get sectionPreChorus => 'B メロ';

  @override
  String get sectionChorus => 'サビ';

  @override
  String get sectionBridge => 'ブリッジ';

  @override
  String get sectionOutro => 'アウトロ';

  @override
  String get sectionHook => 'フック';

  @override
  String get shareTitle => 'シェアカード';

  @override
  String get shareSubtitle => 'テーマとレイアウトを選んでください。';

  @override
  String get shareTheme => 'テーマ';

  @override
  String get shareLayout => 'レイアウト';

  @override
  String get shareLayoutScene => 'イラストあり';

  @override
  String get shareLayoutText => 'テキストのみ';

  @override
  String get paletteTerracotta => 'テラコッタ';

  @override
  String get paletteSand => 'サンド';

  @override
  String get paletteOlive => 'オリーブ';

  @override
  String get paletteNavy => 'ネイビー';

  @override
  String get shareAction => 'シェア';

  @override
  String get shareSaveVideo => '動画を保存';

  @override
  String get shareCopyLyrics => '歌詞をコピー';

  @override
  String get shareVideoSaved => '写真に保存しました';

  @override
  String get shareLyricsCopied => '歌詞をコピーしました';

  @override
  String get shareCardTagline => '誰かのための歌';

  @override
  String get shareSaveFailed => '動画を保存できませんでした。設定で Songlet に写真への追加を許可してください。';

  @override
  String get downloadReady => 'フル曲ができました';

  @override
  String get downloadTitle => 'ずっとあなたのもの';

  @override
  String get downloadIntro => '歌ができました。高音質の音声と商用ライセンスを下からダウンロードできます。';

  @override
  String get downloadAudioHeader => '音声をダウンロード';

  @override
  String get downloadAudioNote => '高音質';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle => 'シェアや普段使いに';

  @override
  String get downloadWavTitle => 'WAV · 44.1 kHz（Premier）';

  @override
  String get downloadWavSubtitle => 'プロ用途の最高音質';

  @override
  String get downloadMp3Action => 'MP3 をダウンロード';

  @override
  String get downloadWavAction => 'WAV をダウンロード';

  @override
  String get downloadLicenseAction => 'ライセンスをダウンロード';

  @override
  String get licenseHeader => '商用ライセンス';

  @override
  String get licenseIncluded => 'プランに含まれています';

  @override
  String get licenseNotIncluded => 'プランまたはパックで利用可能';

  @override
  String get licensePdfTitle => '商用ライセンス（PDF）';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString に発行';
  }

  @override
  String licenseId(String id) {
    return 'ライセンス ID：$id';
  }

  @override
  String get licenseUsesTitle => 'この曲の利用範囲：';

  @override
  String get usePersonal => '個人利用';

  @override
  String get usePersonalDetail => 'プレゼント、思い出、非商用';

  @override
  String get useAds => '広告・マーケティング';

  @override
  String get useAdsDetail => 'プロモーション、有料広告';

  @override
  String get useSocial => 'SNS';

  @override
  String get useSocialDetail => 'TikTok、Instagram、YouTube など';

  @override
  String get usePodcasts => 'ポッドキャスト・動画';

  @override
  String get usePodcastsDetail => '収益化コンテンツ';

  @override
  String get licenseDetailsNote => '詳細はライセンス PDF をご覧ください。';

  @override
  String get saveEnjoyHeader => '保存して楽しむ';

  @override
  String get saveToFiles => '「ファイル」に保存';

  @override
  String get addToMusic => 'ミュージックに追加';

  @override
  String get synthIdNote =>
      'この曲には SynthID 透かしが含まれ、ダウンロード後も AI 生成コンテンツとして識別できます。';

  @override
  String get wavNeedsPremier => 'WAV のダウンロードは Premier で利用できます。';

  @override
  String get wavUnavailable =>
      'この曲の WAV ファイルはありません。WAV は曲の作成から 24 時間以内に保存できます。';

  @override
  String get libraryFilterAll => 'すべて';

  @override
  String get libraryJustBecause => 'なんとなく';

  @override
  String libraryPlay(String title) {
    return '$titleを再生';
  }

  @override
  String libraryActions(String title) {
    return '$titleの操作';
  }

  @override
  String get libraryDeleteTitle => 'この曲を削除しますか？';

  @override
  String get libraryDeleteBody =>
      'このデバイスから削除されます。iCloud 同期がオンの場合は、ほかのデバイスからも削除されます。';

  @override
  String get libraryDeleted => '削除しました';

  @override
  String get libraryFailed => '完成しませんでした';

  @override
  String get libraryNoMatch => 'このシーンの曲はまだありません。';

  @override
  String get detailFullGenerated => 'フル曲を生成済み';

  @override
  String get detailPreviewGenerated => '試聴を生成済み';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString に生成';
  }

  @override
  String get detailPromptUsed => '作成時の内容';

  @override
  String get detailOccasion => 'シーン';

  @override
  String get detailCountry => '国・地域';

  @override
  String get detailGenre => 'ジャンル';

  @override
  String get detailKeywords => 'キーワード';

  @override
  String get detailDescription => '説明';

  @override
  String get detailLyrics => '歌詞';

  @override
  String get detailGenerationId => '生成 ID';

  @override
  String get detailRegenerate => '同じスタイルで作り直す';

  @override
  String get detailCustomGenre => '説明に合わせる';

  @override
  String get settingsSectionPlan => '購入';

  @override
  String get settingsSectionLibrary => 'ライブラリ';

  @override
  String get settingsSectionAbout => '情報';

  @override
  String get settingsRestore => '購入を復元';

  @override
  String get settingsManage => 'サブスクリプションを管理';

  @override
  String get settingsICloud => 'iCloud 同期';

  @override
  String get settingsICloudOn => '曲をデバイス間で同期します';

  @override
  String get settingsICloudOff => '曲はこのデバイスだけに保存されます';

  @override
  String get settingsICloudUnavailable => '同期するには設定で iCloud にサインインしてください';

  @override
  String get settingsLyricsLanguage => '歌詞のデフォルト言語';

  @override
  String get settingsLyricsLanguageAuto => '国・地域に合わせる';

  @override
  String get settingsTerms => '利用規約';

  @override
  String get settingsPrivacy => 'プライバシーポリシー';

  @override
  String settingsVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String get aboutTitle => '生成について';

  @override
  String get aboutSubtitle => 'Songlet が歌を作るしくみ';

  @override
  String get aboutLyriaTitle => 'Google の Lyria 3 を使用';

  @override
  String get aboutLyriaBody =>
      '曲は Gemini API を通じて Google の Lyria 3 で生成されます。Lyria 3 はあなたのアイデアをオリジナル曲にする音楽生成モデルです。';

  @override
  String get aboutWatermarkTitle => '透かし入り';

  @override
  String get aboutWatermarkBody =>
      'すべての曲に Google の SynthID 透かしが入っています。AI 生成の音楽であることを識別でき、取り除くことはできません。';

  @override
  String get aboutImitationTitle => '実在のアーティストを真似しません';

  @override
  String get aboutImitationBody =>
      'Songlet は実在のアーティストやその声、特定のスタイルを真似しません。曲はすべてオリジナルで、あなたのアイデア、説明、写真から作られます。';

  @override
  String get aboutPrivacyTitle => 'プライバシーを大切に';

  @override
  String get aboutPrivacyBody =>
      '写真と説明は 24 時間以内にサーバーから削除されます。曲の生成後に画像や説明を保持することはありません。';

  @override
  String get aboutBanner => 'シェアするすべての曲に「AI 生成」と表示されます。';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · Google Lyria 3 で生成';
  }

  @override
  String get festivalKicker => 'あなたの物語を';

  @override
  String get festivalComing => 'がやってくる！';

  @override
  String get festivalBody => '世界にひとつの歌でお祝いしましょう。';

  @override
  String festivalCta(String festival) {
    return '$festivalの歌を作る';
  }

  @override
  String get festivalPickOccasion => 'シーンを選んで作り始めましょう';

  @override
  String get festivalLanguagesTitle => 'あなたの言語で';

  @override
  String festivalLanguagesBody(String language) {
    return '$languageをはじめ 13 言語に対応';
  }

  @override
  String get unavailableTitle => '一時的に利用できません';

  @override
  String get unavailableMessage =>
      'Songlet はいま曲を作れません。ライブラリは使えます。しばらくしてからもう一度お試しください。';

  @override
  String get paywallHeroTitle => 'フル曲にしよう';

  @override
  String get paywallHeroSubtitle => 'アイデアを、より高音質で権利もすべて含んだ完全な曲に。';

  @override
  String get paywallBenefitSongs => 'もっと多くの曲';

  @override
  String get paywallBenefitQuality => '高音質';

  @override
  String get paywallBenefitCommercial => '商用利用';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '毎月フル曲 $countString 曲',
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
      other: '毎月試聴 $countString 回',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'MP3 ダウンロード';

  @override
  String get planMp3Wav => 'MP3 + WAV ダウンロード';

  @override
  String get planLicense => '商用ライセンス';

  @override
  String get planPriority => '優先生成';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString 日間無料トライアル';
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
  String get packTitle => '数曲だけ欲しい？';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 曲パック',
    );
    return '$_temp0';
  }

  @override
  String get packNote => '有効期限なし';

  @override
  String get valueForever => 'あなたの曲はずっと手元に';

  @override
  String get valueDownloads => '高音質ダウンロード';

  @override
  String get valueCommercial => '商用利用 OK';

  @override
  String get valuePrivate => 'プライバシー重視';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return '無料トライアル終了後は、$pricePerPeriodが自動で請求されます。トライアル終了前ならいつでもキャンセルできます。';
  }

  @override
  String get paywallSubscribe => '登録する';

  @override
  String get paywallBuyPack => 'パックを購入';

  @override
  String get templateBirthdayWish => '誕生日のお祝い';

  @override
  String get templateBirthdayWishHint => '特別な日に特別な歌を';

  @override
  String get templateBirthdayParty => '誕生日パーティー';

  @override
  String get templateBirthdayPartyHint => '主役のためにパーティーを盛り上げよう';

  @override
  String get templateLoveStory => 'ラブストーリー';

  @override
  String get templateLoveStoryHint => 'ふたりの物語を歌に';

  @override
  String get templateThankAFriend => '友だちにありがとう';

  @override
  String get templateThankAFriendHint => '言葉にできない感謝を歌で';

  @override
  String get templatePartyInvite => 'パーティーのお誘い';

  @override
  String get templatePartyInviteHint => 'みんなを集めよう';

  @override
  String get templateWedding => 'ウェディング';

  @override
  String get templateWeddingHint => 'ふたりの永遠の瞬間に';

  @override
  String get templateInMemory => '追悼';

  @override
  String get templateInMemoryHint => '大切な人をしのんで';

  @override
  String get templateFestival => '季節の行事';

  @override
  String get templateFestivalHint => '特別な季節にあたたかい気持ちを';

  @override
  String get templateRingtone => '着信音';

  @override
  String get templateRingtoneHint => 'あなただけの短いループ';

  @override
  String get templateTeamAnthem => 'チームアンセム';

  @override
  String get templateTeamAnthemHint => 'チームも観客も盛り上げよう';

  @override
  String get templateSportsRecap => '試合の振り返り';

  @override
  String get templateSportsRecapHint => 'あの試合を歌にしよう';

  @override
  String get templateRapBattle => 'ラップバトル';

  @override
  String get templateRapBattleHint => 'ライバルに贈るフレンドリーなバース';

  @override
  String get templateComedy => 'コメディ';

  @override
  String get templateComedyHint => '内輪ネタをサビにしよう';

  @override
  String get templatePetAnthem => 'ペットのテーマ';

  @override
  String get templatePetAnthemHint => '相棒のためのテーマソング';

  @override
  String get templateHometown => 'ふるさと';

  @override
  String get templateHometownHint => '「ただいま」と言える場所へ';

  @override
  String get templateBusinessPromo => 'お店の宣伝';

  @override
  String get templateBusinessPromoHint => 'お店やブランドのキャッチーな一曲';

  @override
  String get templateCustom => 'あなたのアイデア';

  @override
  String get mvRecommended => 'おすすめ';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString秒';
  }

  @override
  String get mvViewProgress => '進行状況を見る';

  @override
  String mvIntentWaiting(String level) {
    return '$levelはクレジット待ちです';
  }

  @override
  String get mvSongExpiredAction => '曲を作り直す';

  @override
  String mvQuotaNeed(String level, int required, int available) {
    final intl.NumberFormat requiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requiredString = requiredNumberFormat.format(required);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return '$levelには$requiredStringクレジット必要です。今は$availableStringあります。';
  }

  @override
  String get mvQuotaBuyAndContinue => '購入して続ける';

  @override
  String get mvQuotaMayNeedTwice => 'お住まいの地域では1パックで足りない場合があります。2つ必要になるかもしれません。';

  @override
  String get mvQuotaAutoRetry => '購入が完了するとすぐにビデオの作成が始まります。';

  @override
  String get mvAutoLyricMaking => 'リリックビデオを作成中';

  @override
  String get mvAutoChorusDetail => 'この曲からクレジットを使って作成';

  @override
  String mvAutoReady(String level) {
    return '$levelができました';
  }

  @override
  String get mvAutoView => '見る';

  @override
  String get mvUpgradeChorus => 'サビのビデオを作る';

  @override
  String get mvAutoFailed => 'ビデオを開始できませんでした';

  @override
  String get mvLeaveHint => 'この画面を離れても大丈夫です。できあがる頃にお知らせします。';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsStringクレジットが戻りました。',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => 'このビデオは完成しませんでした';

  @override
  String get mvRejectedTitle => '使えない写真がありました';

  @override
  String get mvRejectedBody => 'ビデオモデルが参考写真の1枚を受け付けませんでした。写真を変えてもう一度お試しください。';

  @override
  String get mvAdjustPhotos => '写真を変えてもう一度';

  @override
  String get mvTryChorus => '代わりにサビのビデオを作る';

  @override
  String get mvPreparingPhotos => '写真をアップロード中…';

  @override
  String get mvPreparingSubmit => 'ビデオを送信中…';

  @override
  String get mvNotifyTitle => 'ビデオができあがった頃です';

  @override
  String mvNotifyBody(String level) {
    return '$level — タップして見る。';
  }

  @override
  String get mvRegenerate => 'もうひとつ作る';

  @override
  String get mvEntryTitle => 'ビデオにする';

  @override
  String get mvEntrySubtitle => 'リリック・サビ・全曲のビデオをクレジットで';

  @override
  String get mvEntryDisabled => '曲が完成すると使えます';

  @override
  String get mvEntryChoose => 'ビデオを選ぶ';

  @override
  String get mvEntryWatch => 'ビデオを見る';

  @override
  String get mvChipReady => 'ビデオ';

  @override
  String get mvChipMaking => 'ビデオ作成中';

  @override
  String get lengthAutoVideo => 'リリックビデオも作る';

  @override
  String get lengthAutoVideoHint => '曲の数分後にできあがり・クレジットを使用';

  @override
  String get lengthSongAndChorus => '曲＋サビのビデオ';

  @override
  String get lengthSongAndChorusHint => '曲全体のあと、30秒のサビのビデオ';

  @override
  String get paywallVideoGroup => 'ミュージックビデオ';

  @override
  String get planVideoIncluded => '毎月の枠でミュージックビデオも作れます';

  @override
  String get settingsVideoCredits => 'ビデオ用クレジット';

  @override
  String get createGenrePop => 'ポップ';

  @override
  String get createGenreHipHopRap => 'ヒップホップ＆ラップ';

  @override
  String get createGenreRock => 'ロック';

  @override
  String get createGenreKPop => 'K-POP';

  @override
  String get createGenreLatin => 'ラテン';

  @override
  String get createGenreElectronic => 'エレクトロ';

  @override
  String get createGenreRnb => 'R&B';

  @override
  String get createGenreCountry => 'カントリー';

  @override
  String get createGenreAfrobeats => 'アフロビーツ';

  @override
  String get createGenreReggae => 'レゲエ';

  @override
  String get createGenreJazzBlues => 'ジャズ＆ブルース';

  @override
  String get createGenreClassical => 'クラシック';

  @override
  String get createGenreFolk => 'フォーク';

  @override
  String get createGenreLofi => 'ローファイ';

  @override
  String get createGenreAcoustic => 'アコースティック';

  @override
  String get createGenreCinematic => '映画音楽';

  @override
  String get createGenreAmbient => 'アンビエント';

  @override
  String get createGenreBossaNova => 'ボサノバ';

  @override
  String get createGenreIndiePop => 'インディーポップ';

  @override
  String get createGenreContemporaryRnb => '現代R&B';

  @override
  String get createGenreAlternativeCountry => 'オルタナカントリー';

  @override
  String get createGenreGarageRock => 'ガレージロック';

  @override
  String get createGenreGrime => 'グライム';

  @override
  String get createGenreIndieFolk => 'インディーフォーク';

  @override
  String get createGenreSynthpop => 'シンセポップ';

  @override
  String get createGenrePianoBallad => 'ピアノバラード';

  @override
  String get createGenreSurfRock => 'サーフロック';

  @override
  String get createGenreDeepHouse => 'ディープハウス';

  @override
  String get createGenreMinimalTechno => 'ミニマルテクノ';

  @override
  String get createGenreFrenchYeyePop => '60年代フレンチポップ';

  @override
  String get createGenreChillout => 'チルアウト';

  @override
  String get createGenreJPopIndiePop => '邦楽インディーポップ';

  @override
  String get createGenreChiptune => 'チップチューン';

  @override
  String get createGenreDiscoFunk => 'ディスコファンク';

  @override
  String get createGenreReggaeton => 'レゲトン';

  @override
  String get createGenreCumbia => 'クンビア';

  @override
  String get createGenreLatinJazz => 'ラテンジャズ';

  @override
  String get createGenreBhangra => 'バングラ';

  @override
  String get createGenreIndianClassical => 'インド古典音楽';

  @override
  String get createGenreLofiHipHop => 'ローファイヒップホップ';

  @override
  String profileAccountIdWithValue(String id) {
    return 'アカウントID: $id';
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
  String get createVocalsCustomSummary => 'おまかせ — 説明に合わせる';

  @override
  String mvChipMakingWithProgress(String progress) {
    return 'ビデオ作成中 · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return 'ビデオを開始できませんでした · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    return '動画クレジット：$creditsString';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => 'インスピレーション';

  @override
  String inspirationPlay(String name) {
    return '「$name」を再生';
  }

  @override
  String get inspirationStop => '試聴を停止';

  @override
  String get inspirationNameSoundscape => 'サウンドスケープ';

  @override
  String get inspirationStyleSoundscape => '環境音のテクスチャー、ボーカルなし';

  @override
  String get inspirationNameBackgroundMusic => 'BGM';

  @override
  String get inspirationStyleBackgroundMusic => '動画向けの軽やかなインスト';

  @override
  String get inspirationNameMemorizeSomething => '暗記ソング';

  @override
  String get inspirationStyleMemorizeSomething => '覚えやすい暗記ポップ';

  @override
  String get inspirationNameTextMessages => 'メッセージを歌に';

  @override
  String get inspirationStyleTextMessages => 'メッセージから作る遊び心あるポップ';

  @override
  String get inspirationNameIntroMusic => 'オープニング曲';

  @override
  String get inspirationStyleIntroMusic => '力強く映画的なオープニング';

  @override
  String get inspirationNameMontage => 'モンタージュ';

  @override
  String get inspirationStyleMontage => 'ハイライト映像を盛り上げる展開';

  @override
  String get inspirationNameSayItWithATrack => '曲で伝えよう';

  @override
  String get inspirationStyleSayItWithATrack => '心に響くポップバラード';

  @override
  String get inspirationNameBrandJingle => 'ブランドジングル';

  @override
  String get inspirationStyleBrandJingle => '短く明るく耳に残るフレーズ';

  @override
  String get inspirationNameRingtone => '着信音';

  @override
  String get inspirationStyleRingtone => '30 秒のループ用フレーズ';

  @override
  String get inspirationNameStreaming => '配信';

  @override
  String get inspirationStyleStreaming => 'エネルギッシュな電子系の配信イントロ';

  @override
  String get inspirationNameSpeechToTrack => '声から曲へ';

  @override
  String get inspirationStyleSpeechToTrack => 'あなたの声が歌になる';

  @override
  String get inspirationNameRapBattle => 'ラップバトル';

  @override
  String get inspirationStyleRapBattle => '骨太なヒップホップ';

  @override
  String get inspirationNameComedy => 'コメディ';

  @override
  String get inspirationStyleComedy => '個性的で明るく、ちょっと皮肉';

  @override
  String get inspirationNameTeamAnthem => 'チームアンセム';

  @override
  String get inspirationStyleTeamAnthem => 'スタジアムロックの掛け声';

  @override
  String get inspirationNameSportsRecap => '試合の振り返り';

  @override
  String get inspirationStyleSportsRecap => '壮大なオーケストラのハイライト';

  @override
  String get inspirationNamePartyInvite => 'パーティーのお誘い';

  @override
  String get inspirationStylePartyInvite => 'ダンスポップの招待状';

  @override
  String get inspirationNameHappyBirthday => 'お誕生日おめでとう';

  @override
  String get inspirationStyleHappyBirthday => '温かいアコースティックの誕生日ソング';

  @override
  String get inspirationNameFriendAppreciation => '友だちへの感謝';

  @override
  String get inspirationStyleFriendAppreciation => '気分が上がるインディーポップ';

  @override
  String get inspirationNameLoveStory => 'ラブストーリー';

  @override
  String get inspirationStyleLoveStory => 'ロマンチックな R&B バラード';

  @override
  String get inspirationNameBirthdayRoast => '誕生日のいじりソング';

  @override
  String get inspirationStyleBirthdayRoast => 'ちょっと生意気でおかしな誕生日ソング';

  @override
  String get inspirationNameOdeToYourPet => 'ペットに捧げる歌';

  @override
  String get inspirationStyleOdeToYourPet => 'かわいく弾むポップ';

  @override
  String get inspirationNameHometownTribute => 'ふるさと賛歌';

  @override
  String get inspirationStyleHometownTribute => '懐かしいフォーク';

  @override
  String get inspirationNameWeatherReport => '天気予報';

  @override
  String get inspirationStyleWeatherReport => '遊び心あるラウンジグルーヴ';

  @override
  String get inspirationNameBusinessPromo => 'お店の宣伝';

  @override
  String get inspirationStyleBusinessPromo => '自信に満ちたコーポレートポップ';

  @override
  String get inspirationStyleBirthdayWish => '特別な日に贈る心のこもった歌';

  @override
  String get inspirationStyleBirthdayParty => '主役を盛り上げるアップビートなパーティーソング';

  @override
  String get inspirationStyleThankAFriend => '温かく感謝を伝えるありがとうの歌';

  @override
  String get inspirationStyleWedding => '晴れの日を彩る喜びとロマンの歌';

  @override
  String get inspirationStyleInMemory => 'やさしく希望に満ちた追悼曲';

  @override
  String get inspirationStyleFestival => '明るく華やかな季節のあいさつ';

  @override
  String get inspirationStylePetAnthem => 'ペットに贈る愛情たっぷりの弾むテーマ曲';

  @override
  String get inspirationStyleHometown => '誇りと郷愁あふれるふるさとの歌';

  @override
  String get settingsSectionLanguage => '言語';

  @override
  String get settingsSectionProfile => 'プロフィール';

  @override
  String get settingsCredits => 'クレジット';

  @override
  String get settingsAccountId => 'アカウント ID';

  @override
  String get settingsCopyAccountId => 'アカウント ID をコピー';

  @override
  String get devSectionTitle => '開発者（DEV のみ）';

  @override
  String get devKeychainReset => 'Keychain キーを削除';

  @override
  String get devKeychainResetHint => 'デバイス ID とセッショントークン';

  @override
  String get devKeychainResetConfirmTitle => 'Keychain キーを削除しますか？';

  @override
  String get devKeychainResetConfirmBody =>
      'Keychain からデバイス ID とセッショントークンを消去します。現在のゲストアカウントは復元できず、アプリは新しいゲストとしてサインインします。';

  @override
  String get devKeychainResetDone => 'Keychain キーを削除しました（新しいゲストでサインイン）';

  @override
  String get settingsAppLanguage => 'アプリの言語';

  @override
  String get settingsLanguageSystem => 'システムに合わせる';

  @override
  String settingsLanguageSystemValue(String language) {
    return 'システム（$language）';
  }

  @override
  String get settingsLanguageNativeName => '日本語';

  @override
  String get settingsLanguageSaveFailed => '言語を保存できませんでした。もう一度お試しください。';

  @override
  String get settingsLyricsLanguageHint => '新しく作る曲に適用されます。';

  @override
  String composerRemoveInspiration(String name) {
    return '$nameを外す';
  }

  @override
  String get composerPromptHint => '歌について書くか、上のアイデアを選んでください';

  @override
  String get composerPromptHintWide => '歌について書くか、アイデアを選んでください';

  @override
  String get composerWordsLabel => 'あなたの言葉';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '写真$countString枚を追加済み',
      one: '写真$countString枚を追加済み',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return '曲のオプション：$summary';
  }

  @override
  String get composerOptionsShow => 'オプションを表示';

  @override
  String get composerOptionsHide => 'オプションを閉じる';

  @override
  String get composerSummaryAnyVocals => 'ボーカルおまかせ';

  @override
  String get composerSummaryAnyGenre => 'ジャンルおまかせ';

  @override
  String get composerSummaryLyrics => '自作の歌詞';

  @override
  String get composerSummaryVideo => 'リリックビデオ';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': '試聴を作成・無料',
      'preview': '試聴を作成・試聴1回',
      'other': '試聴を作成',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': '$nameの試聴を作成・無料',
      'preview': '$nameの試聴を作成・試聴1回',
      'other': '$nameの試聴を作成',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': 'フル曲を作成・1曲',
      'other': 'フル曲を作成',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => 'このテキストを使う';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$levelは$seconds秒後に始まります';
  }

  @override
  String planPerWeek(String price) {
    return '$price/週';
  }

  @override
  String get planCreditsWeekly => '毎週新しいクレジット';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': '1日',
      'week': '1週間',
      'month': '1か月',
      'year': '1年',
      'other': '期間',
    });
    return '最初の$_temp0が$percent%オフ';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return '導入価格 $introPrice の期間が終わると、自動的に $pricePerPeriod が請求されます。更新前ならいつでもキャンセルできます。';
  }

  @override
  String get storePreviewAHook => '名前から始めよう';

  @override
  String get storePreviewAWords => 'その人を3つの言葉で';

  @override
  String get storePreviewAWait => 'あなたの歌を作曲中';

  @override
  String get storePreviewAChorus => 'サビで名前を歌う';

  @override
  String get storePreviewAEnd => '名前が入った、その人の歌';

  @override
  String get storePreviewBHook => '写真から始めよう';

  @override
  String get storePreviewBVideo => '歌詞ビデオも作る';

  @override
  String get storePreviewBWait => '歌を作曲中';

  @override
  String get storePreviewBLyrics => '歌詞が画面に同期';

  @override
  String get storePreviewBMood => '写真が雰囲気を決める。';

  @override
  String get storePreviewBShare => 'ビデオをシェアしよう。';

  @override
  String get storePreviewBLanguage => 'あなたの言語で歌詞を';

  @override
  String get storePreviewAShare => 'カードにして贈ろう';

  @override
  String get storePreviewCta => '最初の一曲を作ろう';

  @override
  String get storePreviewDisclosure => 'サブスクリプションまたはクレジットが必要です';

  @override
  String get storeCreativeHeader => '大切な人に贈る歌';

  @override
  String get storeCreativeSearch => '名前から歌をつくる';

  @override
  String get storeCreativeBirthday => '名前入りのバースデーソング';

  @override
  String get storeCreativePhoto => '写真が歌になる';

  @override
  String get storeCreativeWedding => 'ふたりの結婚式のための歌';
}
