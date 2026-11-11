import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// Shared buttons and messages. Purpose: common retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Shared buttons and messages. Purpose: common cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Startup gate. Purpose: startup loading.
  ///
  /// In en, this message translates to:
  /// **'Tuning up…'**
  String get startupLoading;

  /// Shared buttons and messages. Purpose: common error title.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonErrorTitle;

  /// Required app update. Purpose: update required title.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// Required app update. Purpose: update required message.
  ///
  /// In en, this message translates to:
  /// **'A new version is required to continue.'**
  String get updateRequiredMessage;

  /// Required app update. Purpose: update now.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// Maintenance gate. Purpose: maintenance title.
  ///
  /// In en, this message translates to:
  /// **'Scheduled maintenance'**
  String get maintenanceTitle;

  /// Maintenance gate. Purpose: maintenance resume estimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated to resume in about {minutes} min'**
  String maintenanceResumeEstimate(int minutes);

  /// Feature availability message. Purpose: feature unavailable.
  ///
  /// In en, this message translates to:
  /// **'This feature is temporarily unavailable.'**
  String get featureUnavailable;

  /// Application navigation. Purpose: nav profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Application navigation. Purpose: nav store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get navStore;

  /// Application navigation. Purpose: nav upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get navUpload;

  /// File upload screen. Purpose: upload title.
  ///
  /// In en, this message translates to:
  /// **'Uploads'**
  String get uploadTitle;

  /// File upload screen. Purpose: upload subtitle.
  ///
  /// In en, this message translates to:
  /// **'Presigned direct-to-R2 upload with hashing, instant dedup and progress.'**
  String get uploadSubtitle;

  /// File upload screen. Purpose: upload pick.
  ///
  /// In en, this message translates to:
  /// **'Choose image & upload'**
  String get uploadPick;

  /// File upload screen. Purpose: upload again.
  ///
  /// In en, this message translates to:
  /// **'Upload another'**
  String get uploadAgain;

  /// File upload screen. Purpose: upload phase hashing.
  ///
  /// In en, this message translates to:
  /// **'Hashing…'**
  String get uploadPhaseHashing;

  /// File upload screen. Purpose: upload phase signing.
  ///
  /// In en, this message translates to:
  /// **'Requesting upload ticket…'**
  String get uploadPhaseSigning;

  /// File upload screen. Purpose: upload phase uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {percent}'**
  String uploadPhaseUploading(String percent);

  /// File upload screen. Purpose: upload phase finalizing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing…'**
  String get uploadPhaseFinalizing;

  /// File upload screen. Purpose: upload done.
  ///
  /// In en, this message translates to:
  /// **'Uploaded.'**
  String get uploadDone;

  /// File upload screen. Purpose: upload dedup.
  ///
  /// In en, this message translates to:
  /// **'Instant: this file already existed on the server.'**
  String get uploadDedup;

  /// File upload screen. Purpose: upload open link.
  ///
  /// In en, this message translates to:
  /// **'View file'**
  String get uploadOpenLink;

  /// File upload screen. Purpose: upload failed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed.'**
  String get uploadFailed;

  /// File upload screen. Purpose: upload too large.
  ///
  /// In en, this message translates to:
  /// **'File is too large ({limit} MB max).'**
  String uploadTooLarge(int limit);

  /// File upload screen. Purpose: upload unsupported type.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type.'**
  String get uploadUnsupportedType;

  /// Account profile. Purpose: profile guest title.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get profileGuestTitle;

  /// Account profile. Purpose: profile guest subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your purchases across devices.'**
  String get profileGuestSubtitle;

  /// Account actions. Purpose: sign in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Account actions. Purpose: sign out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Account profile. Purpose: profile balance label.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get profileBalanceLabel;

  /// Account profile. Purpose: profile account id.
  ///
  /// In en, this message translates to:
  /// **'Account ID'**
  String get profileAccountId;

  /// Account profile. Purpose: profile features label.
  ///
  /// In en, this message translates to:
  /// **'Active benefits'**
  String get profileFeaturesLabel;

  /// Account profile. Purpose: profile no features.
  ///
  /// In en, this message translates to:
  /// **'No active benefits yet.'**
  String get profileNoFeatures;

  /// Account profile. Purpose: profile subscription label.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get profileSubscriptionLabel;

  /// Account profile. Purpose: profile manage subscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get profileManageSubscription;

  /// Subscription status. Purpose: subscription active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionActive;

  /// Subscription status. Purpose: subscription inactive.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get subscriptionInactive;

  /// Account profile. Purpose: profile delete account.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccount;

  /// Account deletion confirmation and result. Purpose: delete account title.
  ///
  /// In en, this message translates to:
  /// **'Delete this account?'**
  String get deleteAccountTitle;

  /// Account deletion confirmation and result. Purpose: delete account message.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone: this account and its credits and benefit records become permanently unreachable, and a fresh account is created. An active app store subscription is not cancelled by deleting the account — manage it in your app store settings, or re-link it later with Restore purchases.'**
  String get deleteAccountMessage;

  /// Account deletion confirmation and result. Purpose: delete account confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAccountConfirm;

  /// Account deletion confirmation and result. Purpose: delete account working.
  ///
  /// In en, this message translates to:
  /// **'Deleting account…'**
  String get deleteAccountWorking;

  /// Account deletion confirmation and result. Purpose: delete account done.
  ///
  /// In en, this message translates to:
  /// **'Account deleted.'**
  String get deleteAccountDone;

  /// Account profile. Purpose: profile member since.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String profileMemberSince(DateTime date);

  /// Sign-in sheet. Purpose: login title.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// Sign-in sheet. Purpose: login username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsername;

  /// Sign-in sheet. Purpose: login password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// Sign-in sheet. Purpose: login submit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSubmit;

  /// Purchase screen. Purpose: paywall title.
  ///
  /// In en, this message translates to:
  /// **'Get the full song'**
  String get paywallTitle;

  /// Purchase screen. Purpose: paywall subtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn your preview into a 2-minute song with lyrics — yours to download and use.'**
  String get paywallSubtitle;

  /// Purchase screen. Purpose: paywall restore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestore;

  /// Purchase screen. Purpose: paywall auto renew notice.
  ///
  /// In en, this message translates to:
  /// **'Payment is charged to your Apple Account at confirmation. Subscriptions renew automatically at the same price and period unless cancelled at least 24 hours before the end of the current period. A free trial converts to a paid subscription when it ends. Manage or cancel anytime in your App Store account settings.'**
  String get paywallAutoRenewNotice;

  /// Purchase screen. Purpose: paywall continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paywallContinue;

  /// Purchase screen. Purpose: paywall free trial.
  ///
  /// In en, this message translates to:
  /// **'Free trial'**
  String get paywallFreeTrial;

  /// Purchase screen. Purpose: paywall offer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get paywallOffer;

  /// Purchase screen. Purpose: paywall manage.
  ///
  /// In en, this message translates to:
  /// **'Manage plan'**
  String get paywallManage;

  /// Purchase screen. Purpose: paywall terms of use.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get paywallTermsOfUse;

  /// Purchase screen. Purpose: paywall privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get paywallPrivacyPolicy;

  /// Purchase screen. Purpose: paywall subscription terms.
  ///
  /// In en, this message translates to:
  /// **'Subscription Terms'**
  String get paywallSubscriptionTerms;

  /// Shared buttons and messages. Purpose: common link error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link.'**
  String get commonLinkError;

  /// Shared buttons and messages. Purpose: common error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get commonError;

  /// Shared buttons and messages. Purpose: common network error.
  ///
  /// In en, this message translates to:
  /// **'Network error — check your connection and try again.'**
  String get commonNetworkError;

  /// Shared buttons and messages. Purpose: common offline error.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection and try again.'**
  String get commonOfflineError;

  /// Network failure screen. Purpose: network error title.
  ///
  /// In en, this message translates to:
  /// **'Connection problem'**
  String get networkErrorTitle;

  /// Startup configuration failure. Purpose: config error title.
  ///
  /// In en, this message translates to:
  /// **'App configuration problem'**
  String get configErrorTitle;

  /// Startup configuration failure. Purpose: config error message.
  ///
  /// In en, this message translates to:
  /// **'This version can\'t reach our service. Update the app from the App Store, or reinstall it. If the problem persists, contact support.'**
  String get configErrorMessage;

  /// Shared buttons and messages. Purpose: common auth error.
  ///
  /// In en, this message translates to:
  /// **'Your session expired — please sign in again.'**
  String get commonAuthError;

  /// Purchase screen. Purpose: paywall products error title.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load products'**
  String get paywallProductsErrorTitle;

  /// Purchase screen. Purpose: paywall no products.
  ///
  /// In en, this message translates to:
  /// **'No products available right now.'**
  String get paywallNoProducts;

  /// Purchase screen. Purpose: paywall purchase success.
  ///
  /// In en, this message translates to:
  /// **'Purchase complete — enjoy!'**
  String get paywallPurchaseSuccess;

  /// Purchase screen. Purpose: paywall processing.
  ///
  /// In en, this message translates to:
  /// **'Processing your purchase…'**
  String get paywallProcessing;

  /// Purchase screen. Purpose: paywall verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying your purchase…'**
  String get paywallVerifying;

  /// Purchase screen. Purpose: paywall purchase failed.
  ///
  /// In en, this message translates to:
  /// **'Purchase couldn\'t be completed.'**
  String get paywallPurchaseFailed;

  /// Purchase screen. Purpose: paywall restore started.
  ///
  /// In en, this message translates to:
  /// **'Restoring your purchases…'**
  String get paywallRestoreStarted;

  /// Purchase screen. Purpose: paywall restore success.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} purchase restored.} other{{count} purchases restored.}}'**
  String paywallRestoreSuccess(int count);

  /// Purchase screen. Purpose: paywall restore nothing.
  ///
  /// In en, this message translates to:
  /// **'No purchases to restore.'**
  String get paywallRestoreNothing;

  /// Purchase screen. Purpose: paywall deferred.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval — we\'ll finish once it\'s approved.'**
  String get paywallDeferred;

  /// Purchase screen. Purpose: paywall already subscribed.
  ///
  /// In en, this message translates to:
  /// **'You\'re already subscribed.'**
  String get paywallAlreadySubscribed;

  /// Purchase screen. Purpose: paywall billing retry.
  ///
  /// In en, this message translates to:
  /// **'Update your payment method to keep your subscription.'**
  String get paywallBillingRetry;

  /// Purchase screen. Purpose: paywall trial.
  ///
  /// In en, this message translates to:
  /// **'{days}-day free trial'**
  String paywallTrial(int days);

  /// Subscription billing period. Purpose: cycle one time.
  ///
  /// In en, this message translates to:
  /// **'one-time'**
  String get cycleOneTime;

  /// Subscription billing period. Purpose: cycle weekly.
  ///
  /// In en, this message translates to:
  /// **'/ week'**
  String get cycleWeekly;

  /// Subscription billing period. Purpose: cycle monthly.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get cycleMonthly;

  /// Subscription billing period. Purpose: cycle quarterly.
  ///
  /// In en, this message translates to:
  /// **'/ quarter'**
  String get cycleQuarterly;

  /// Subscription billing period. Purpose: cycle semi annual.
  ///
  /// In en, this message translates to:
  /// **'/ 6 months'**
  String get cycleSemiAnnual;

  /// Subscription billing period. Purpose: cycle annual.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get cycleAnnual;

  /// Subscription billing period. Purpose: cycle lifetime.
  ///
  /// In en, this message translates to:
  /// **'lifetime'**
  String get cycleLifetime;

  /// Application navigation. Purpose: nav create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get navCreate;

  /// Application navigation. Purpose: nav library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// Application navigation. Purpose: nav settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Shared buttons and messages. Purpose: common continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// Shared buttons and messages. Purpose: common back.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get commonBack;

  /// Song creation screen. Purpose: create title.
  ///
  /// In en, this message translates to:
  /// **'Who is this song for?'**
  String get createTitle;

  /// Occasion picker. Purpose: occasion birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get occasionBirthday;

  /// Occasion picker. Purpose: occasion birthday hint.
  ///
  /// In en, this message translates to:
  /// **'A joyful song for their big day'**
  String get occasionBirthdayHint;

  /// Occasion picker. Purpose: occasion anniversary.
  ///
  /// In en, this message translates to:
  /// **'Anniversary'**
  String get occasionAnniversary;

  /// Occasion picker. Purpose: occasion anniversary hint.
  ///
  /// In en, this message translates to:
  /// **'Celebrate your story together'**
  String get occasionAnniversaryHint;

  /// Occasion picker. Purpose: occasion confession.
  ///
  /// In en, this message translates to:
  /// **'Love Confession'**
  String get occasionConfession;

  /// Occasion picker. Purpose: occasion confession hint.
  ///
  /// In en, this message translates to:
  /// **'Say what your heart feels'**
  String get occasionConfessionHint;

  /// Occasion picker. Purpose: occasion wedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get occasionWedding;

  /// Occasion picker. Purpose: occasion wedding hint.
  ///
  /// In en, this message translates to:
  /// **'A song for your forever moment'**
  String get occasionWeddingHint;

  /// Occasion picker. Purpose: occasion memorial.
  ///
  /// In en, this message translates to:
  /// **'In Memory'**
  String get occasionMemorial;

  /// Occasion picker. Purpose: occasion memorial hint.
  ///
  /// In en, this message translates to:
  /// **'Honor someone you cherish'**
  String get occasionMemorialHint;

  /// Occasion picker. Purpose: occasion festival.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get occasionFestival;

  /// Occasion picker. Purpose: occasion festival hint.
  ///
  /// In en, this message translates to:
  /// **'Warm wishes for a special season'**
  String get occasionFestivalHint;

  /// Occasion picker. Purpose: occasion brand.
  ///
  /// In en, this message translates to:
  /// **'Brand Jingle'**
  String get occasionBrand;

  /// Occasion picker. Purpose: occasion brand hint.
  ///
  /// In en, this message translates to:
  /// **'A catchy tune for your brand'**
  String get occasionBrandHint;

  /// Occasion picker. Purpose: occasion soundtrack.
  ///
  /// In en, this message translates to:
  /// **'Video Soundtrack'**
  String get occasionSoundtrack;

  /// Occasion picker. Purpose: occasion soundtrack hint.
  ///
  /// In en, this message translates to:
  /// **'Music that fits your story'**
  String get occasionSoundtrackHint;

  /// Festival creation screen. Purpose: festival new year.
  ///
  /// In en, this message translates to:
  /// **'New Year'**
  String get festivalNewYear;

  /// Festival creation screen. Purpose: festival thanksgiving.
  ///
  /// In en, this message translates to:
  /// **'Thanksgiving'**
  String get festivalThanksgiving;

  /// Festival creation screen. Purpose: festival diwali.
  ///
  /// In en, this message translates to:
  /// **'Diwali'**
  String get festivalDiwali;

  /// Festival creation screen. Purpose: festival carnival.
  ///
  /// In en, this message translates to:
  /// **'Carnival'**
  String get festivalCarnival;

  /// Festival creation screen. Purpose: festival eid.
  ///
  /// In en, this message translates to:
  /// **'Eid'**
  String get festivalEid;

  /// Festival creation screen. Purpose: festival lunar new year.
  ///
  /// In en, this message translates to:
  /// **'Lunar New Year'**
  String get festivalLunarNewYear;

  /// Country and lyrics-language sheet. Purpose: region title.
  ///
  /// In en, this message translates to:
  /// **'Where will it be heard?'**
  String get regionTitle;

  /// Country and lyrics-language sheet. Purpose: region search hint.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get regionSearchHint;

  /// Country and lyrics-language sheet. Purpose: region language sheet title.
  ///
  /// In en, this message translates to:
  /// **'Lyrics language'**
  String get regionLanguageSheetTitle;

  /// Country name in region picker. Purpose: country u s.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get countryUS;

  /// Country name in region picker. Purpose: country g b.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get countryGB;

  /// Country name in region picker. Purpose: country c a.
  ///
  /// In en, this message translates to:
  /// **'Canada'**
  String get countryCA;

  /// Country name in region picker. Purpose: country a u.
  ///
  /// In en, this message translates to:
  /// **'Australia'**
  String get countryAU;

  /// Country name in region picker. Purpose: country d e.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get countryDE;

  /// Country name in region picker. Purpose: country f r.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get countryFR;

  /// Country name in region picker. Purpose: country j p.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get countryJP;

  /// Country name in region picker. Purpose: country k r.
  ///
  /// In en, this message translates to:
  /// **'South Korea'**
  String get countryKR;

  /// Country name in region picker. Purpose: country b r.
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get countryBR;

  /// Country name in region picker. Purpose: country m x.
  ///
  /// In en, this message translates to:
  /// **'Mexico'**
  String get countryMX;

  /// Country name in region picker. Purpose: country i n.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get countryIN;

  /// Country name in region picker. Purpose: country i d.
  ///
  /// In en, this message translates to:
  /// **'Indonesia'**
  String get countryID;

  /// Country name in region picker. Purpose: country v n.
  ///
  /// In en, this message translates to:
  /// **'Vietnam'**
  String get countryVN;

  /// Country name in region picker. Purpose: country t r.
  ///
  /// In en, this message translates to:
  /// **'Türkiye'**
  String get countryTR;

  /// Lyrics-language display name. Purpose: language en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// Lyrics-language display name. Purpose: language fr.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFr;

  /// Lyrics-language display name. Purpose: language de.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageDe;

  /// Lyrics-language display name. Purpose: language ja.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJa;

  /// Lyrics-language display name. Purpose: language ko.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageKo;

  /// Lyrics-language display name. Purpose: language pt b r.
  ///
  /// In en, this message translates to:
  /// **'Portuguese (Brazil)'**
  String get languagePtBR;

  /// Lyrics-language display name. Purpose: language es m x.
  ///
  /// In en, this message translates to:
  /// **'Spanish (Mexico)'**
  String get languageEsMX;

  /// Lyrics-language display name. Purpose: language hi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHi;

  /// Lyrics-language display name. Purpose: language id.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get languageId;

  /// Lyrics-language display name. Purpose: language vi.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get languageVi;

  /// Lyrics-language display name. Purpose: language tr.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageTr;

  /// Lyrics-language display name. Purpose: language zh hans.
  ///
  /// In en, this message translates to:
  /// **'Chinese (Simplified)'**
  String get languageZhHans;

  /// Lyrics-language display name. Purpose: language zh hant.
  ///
  /// In en, this message translates to:
  /// **'Chinese (Traditional)'**
  String get languageZhHant;

  /// Song creation form. Purpose: input name label.
  ///
  /// In en, this message translates to:
  /// **'Their name'**
  String get inputNameLabel;

  /// Song creation form. Purpose: input name optional label.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get inputNameOptionalLabel;

  /// Song creation form. Purpose: input name hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Alex'**
  String get inputNameHint;

  /// Song creation form. Purpose: input keywords label.
  ///
  /// In en, this message translates to:
  /// **'Three words about them'**
  String get inputKeywordsLabel;

  /// Song creation form. Purpose: input lyrics hint.
  ///
  /// In en, this message translates to:
  /// **'[Verse] …\n[Chorus] …'**
  String get inputLyricsHint;

  /// Own-lyrics editor. Purpose: lyrics counter.
  ///
  /// In en, this message translates to:
  /// **'{count} / {limit}'**
  String lyricsCounter(int count, int limit);

  /// Song creation form. Purpose: input lyrics ownership.
  ///
  /// In en, this message translates to:
  /// **'These lyrics are mine or I have the right to use them'**
  String get inputLyricsOwnership;

  /// Creation form validation; explain how to correct the input. Purpose: issue recipient missing.
  ///
  /// In en, this message translates to:
  /// **'Add their name.'**
  String get issueRecipientMissing;

  /// Creation form validation; explain how to correct the input. Purpose: issue recipient too long.
  ///
  /// In en, this message translates to:
  /// **'Names can be up to 24 characters.'**
  String get issueRecipientTooLong;

  /// Creation validation (no inspiration card picked, nothing to write from): ask for a description, keywords, lyrics or photos. Also shown when the server answers 40001 details.prompt.
  ///
  /// In en, this message translates to:
  /// **'Tell us about the song — a few words, lyrics or photos.'**
  String get issueBriefMissing;

  /// Shown when the server answers 40001 details.prompt.description: the picked inspiration needs the user's own words.
  ///
  /// In en, this message translates to:
  /// **'This idea needs your words — write a line about the song.'**
  String get issueDescriptionMissing;

  /// Generating page, failure or rejected state: returns to the create home with the draft kept, to fix it.
  ///
  /// In en, this message translates to:
  /// **'Back to edit'**
  String get generatingBackToEdit;

  /// Creation form validation; explain how to correct the input. Purpose: issue keyword too long.
  ///
  /// In en, this message translates to:
  /// **'Each word can be up to 20 characters.'**
  String get issueKeywordTooLong;

  /// Creation form validation; explain how to correct the input. Purpose: issue too many keywords.
  ///
  /// In en, this message translates to:
  /// **'Use up to three words.'**
  String get issueTooManyKeywords;

  /// Creation form validation; explain how to correct the input. Purpose: issue artist name.
  ///
  /// In en, this message translates to:
  /// **'Artist names can\'t be used — describe the feeling instead.'**
  String get issueArtistName;

  /// Creation form validation; explain how to correct the input. Purpose: issue style imitation.
  ///
  /// In en, this message translates to:
  /// **'We can\'t imitate a singer or a band. Describe the mood instead.'**
  String get issueStyleImitation;

  /// Creation form validation; explain how to correct the input. Purpose: issue lyrics too long.
  ///
  /// In en, this message translates to:
  /// **'Lyrics can be up to {limit} characters.'**
  String issueLyricsTooLong(int limit);

  /// Creation form validation; explain how to correct the input. Purpose: issue lyrics not original.
  ///
  /// In en, this message translates to:
  /// **'These lyrics look like an existing song. Please write your own.'**
  String get issueLyricsNotOriginal;

  /// Creation form validation; explain how to correct the input. Purpose: issue lyrics ownership.
  ///
  /// In en, this message translates to:
  /// **'Confirm the lyrics are yours to use.'**
  String get issueLyricsOwnership;

  /// Creation form validation; explain how to correct the input. Purpose: issue too many photos.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 10 photos.'**
  String get issueTooManyPhotos;

  /// Photo selection. Purpose: photos title.
  ///
  /// In en, this message translates to:
  /// **'Pick a few photos'**
  String get photosTitle;

  /// Photo selection. Purpose: photos count.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max}'**
  String photosCount(int count, int max);

  /// Photo selection. Purpose: photos privacy.
  ///
  /// In en, this message translates to:
  /// **'Photos are used once to write the song and deleted from our servers within 24 hours.'**
  String get photosPrivacy;

  /// Photo selection. Purpose: photos add.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get photosAdd;

  /// Photo selection. Purpose: photos create.
  ///
  /// In en, this message translates to:
  /// **'Create from photos'**
  String get photosCreate;

  /// Photo selection. Purpose: photos empty.
  ///
  /// In en, this message translates to:
  /// **'Choose 1–10 photos of the moment.'**
  String get photosEmpty;

  /// Song generation progress and cancellation. Purpose: generating step polishing.
  ///
  /// In en, this message translates to:
  /// **'Polishing your words on this iPhone…'**
  String get generatingStepPolishing;

  /// Song generation progress and cancellation. Purpose: generating step uploading.
  ///
  /// In en, this message translates to:
  /// **'Sending your photos…'**
  String get generatingStepUploading;

  /// Song generation progress and cancellation. Purpose: generating step submitting.
  ///
  /// In en, this message translates to:
  /// **'Sending to the studio…'**
  String get generatingStepSubmitting;

  /// PRD 6.5 SAFETY_BLOCKED
  ///
  /// In en, this message translates to:
  /// **'We can\'t make this one — try different words, and skip artist names.'**
  String get errorSafetyBlocked;

  /// PRD 6.5 QUOTA_EXHAUSTED
  ///
  /// In en, this message translates to:
  /// **'You\'ve used this month\'s songs. Add a pack or upgrade.'**
  String get errorQuotaExhausted;

  /// PRD 6.5 UPSTREAM_TIMEOUT
  ///
  /// In en, this message translates to:
  /// **'Taking longer than usual. We\'ll keep trying and notify you.'**
  String get errorUpstreamTimeout;

  /// PRD 6.5 UPSTREAM_RATE_LIMITED
  ///
  /// In en, this message translates to:
  /// **'Lots of songs being made right now. Yours is queued.'**
  String get errorUpstreamRateLimited;

  /// PRD 6.5 ATTEST_FAILED
  ///
  /// In en, this message translates to:
  /// **'Please update Songlet from the App Store.'**
  String get errorAttestFailed;

  /// PRD 6.5 IMAGE_REJECTED
  ///
  /// In en, this message translates to:
  /// **'One of these photos can\'t be used. Try another.'**
  String get errorImageRejected;

  /// PRD 6.5 NETWORK_OFFLINE
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Your library still works.'**
  String get errorNetworkOffline;

  /// DOWNLOAD_LOCKED (PRD 8.4 refund)
  ///
  /// In en, this message translates to:
  /// **'Downloads aren\'t available for this song — the purchase that made it was refunded or your plan has ended. You can still play it.'**
  String get errorDownloadLocked;

  /// Cancel lost the race: the job had already finished (JOB_ALREADY_FINISHED).
  ///
  /// In en, this message translates to:
  /// **'It already finished — there\'s nothing to cancel.'**
  String get errorJobAlreadyFinished;

  /// MV_SONG_NOT_READY (contract v1.1)
  ///
  /// In en, this message translates to:
  /// **'This song isn\'t ready for a video yet.'**
  String get errorMvSongNotReady;

  /// MV_SONG_TOO_LONG
  ///
  /// In en, this message translates to:
  /// **'This song is too long for a full video — try a chorus video.'**
  String get errorMvSongTooLong;

  /// MV_SONG_EXPIRED
  ///
  /// In en, this message translates to:
  /// **'This song has expired. Generate it again to make a video.'**
  String get errorMvSongExpired;

  /// MV_NOT_FOUND
  ///
  /// In en, this message translates to:
  /// **'This video isn\'t available anymore.'**
  String get errorMvNotFound;

  /// MV_PHOTOS_EXPIRED
  ///
  /// In en, this message translates to:
  /// **'Those photos have expired — pick them again.'**
  String get errorMvPhotosExpired;

  /// MV_RENDER_FAILED (job level, refunded)
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t finish this video. Your credits are back — try again.'**
  String get errorMvRenderFailed;

  /// P19 hub title
  ///
  /// In en, this message translates to:
  /// **'Make a video'**
  String get mvHubTitle;

  /// P19 hub subtitle; {title} = song title
  ///
  /// In en, this message translates to:
  /// **'Turn “{title}” into a music video.'**
  String mvHubSubtitle(String title);

  /// Level: lyric video
  ///
  /// In en, this message translates to:
  /// **'Lyric video'**
  String get mvLevelLyricVideo;

  /// Level hint: lyric video
  ///
  /// In en, this message translates to:
  /// **'A still scene with your lyrics'**
  String get mvLevelLyricHint;

  /// Level: chorus video
  ///
  /// In en, this message translates to:
  /// **'Chorus video'**
  String get mvLevelChorus;

  /// Level hint: chorus video
  ///
  /// In en, this message translates to:
  /// **'30 seconds of your chorus, AI-shot'**
  String get mvLevelChorusHint;

  /// Level: full-song video
  ///
  /// In en, this message translates to:
  /// **'Full-song video'**
  String get mvLevelFull;

  /// Level hint: full-song video
  ///
  /// In en, this message translates to:
  /// **'The whole song, scene by scene'**
  String get mvLevelFullHint;

  /// Price line; {credits} = integer
  ///
  /// In en, this message translates to:
  /// **'{credits, plural, one{{credits} credit} other{{credits} credits}}'**
  String mvPriceCredits(int credits);

  /// Credits the account has; {credits} = integer
  ///
  /// In en, this message translates to:
  /// **'{credits, plural, one{You have {credits} credit} other{You have {credits} credits}}'**
  String mvAvailableCredits(int credits);

  /// Missing credits; {credits} = integer
  ///
  /// In en, this message translates to:
  /// **'{credits, plural, one{{credits} more credit needed} other{{credits} more credits needed}}'**
  String mvGapCredits(int credits);

  /// While the price is fetched
  ///
  /// In en, this message translates to:
  /// **'Checking the price…'**
  String get mvEstimating;

  /// P19 options section header
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get mvOptionsHeader;

  /// Aspect ratio option
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get mvAspectLabel;

  /// 9:16
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get mvAspectPortrait;

  /// 16:9
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get mvAspectLandscape;

  /// 1:1
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get mvAspectSquare;

  /// Quality option
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get mvQualityLabel;

  /// quality standard
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get mvQualityStandard;

  /// quality high
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get mvQualityHigh;

  /// Burn lyrics into the video (switch)
  ///
  /// In en, this message translates to:
  /// **'Lyrics on screen'**
  String get mvSubtitlesLabel;

  /// Reference photos row
  ///
  /// In en, this message translates to:
  /// **'Reference photos'**
  String get mvPhotosLabel;

  /// Reference photos hint (no face driving in V1)
  ///
  /// In en, this message translates to:
  /// **'Set the scene and colours — faces aren\'t used'**
  String get mvPhotosHint;

  /// Picked photos count; {count} = integer
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} photo} other{{count} photos}}'**
  String mvPhotosCount(int count);

  /// Chorus window row (chorus level only)
  ///
  /// In en, this message translates to:
  /// **'Chorus'**
  String get mvChorusLabel;

  /// Chorus window: automatic
  ///
  /// In en, this message translates to:
  /// **'Found automatically'**
  String get mvChorusAuto;

  /// Chorus window: chosen by the user
  ///
  /// In en, this message translates to:
  /// **'Choose the moment'**
  String get mvChorusCustom;

  /// Chosen chorus window; {start} and {end} are m:ss clock labels
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String mvChorusRange(String start, String end);

  /// P19 primary action
  ///
  /// In en, this message translates to:
  /// **'Make video'**
  String get mvCreate;

  /// P19 primary action when credits are missing (opens the paywall on the pack)
  ///
  /// In en, this message translates to:
  /// **'Get the pack and make it'**
  String get mvBuyPack;

  /// Note that the song was saved for the video (song_locked)
  ///
  /// In en, this message translates to:
  /// **'Your song is saved for the video.'**
  String get mvSongLocked;

  /// P20 title
  ///
  /// In en, this message translates to:
  /// **'Making your video…'**
  String get mvGeneratingTitle;

  /// Stage: queued
  ///
  /// In en, this message translates to:
  /// **'Waiting to start'**
  String get mvStageQueued;

  /// Stage: slicing
  ///
  /// In en, this message translates to:
  /// **'Choosing the moments'**
  String get mvStageSlicing;

  /// Stage: storyboarding
  ///
  /// In en, this message translates to:
  /// **'Writing the storyboard'**
  String get mvStageStoryboarding;

  /// Stage: keyframing
  ///
  /// In en, this message translates to:
  /// **'Painting the scenes'**
  String get mvStageKeyframing;

  /// Stage: rendering
  ///
  /// In en, this message translates to:
  /// **'Filming the scenes'**
  String get mvStageRendering;

  /// Stage: assembling
  ///
  /// In en, this message translates to:
  /// **'Cutting it together'**
  String get mvStageAssembling;

  /// Stage: done
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get mvStageDone;

  /// Scene progress; {done} and {total} = integers
  ///
  /// In en, this message translates to:
  /// **'Scene {done} of {total}'**
  String mvScenes(int done, int total);

  /// ETA caption; {minutes} = integer
  ///
  /// In en, this message translates to:
  /// **'Usually about {minutes} minutes'**
  String mvUsuallyMinutes(int minutes);

  /// Banner after a cancel was acknowledged while rendering
  ///
  /// In en, this message translates to:
  /// **'Stopping after the current scene…'**
  String get mvCancelRequested;

  /// Cancel dialog title
  ///
  /// In en, this message translates to:
  /// **'Stop this video?'**
  String get mvCancelTitle;

  /// Cancel dialog body while queued
  ///
  /// In en, this message translates to:
  /// **'It hasn\'t started yet, so nothing will be used.'**
  String get mvCancelQueued;

  /// Cancel dialog body while rendering (partial settlement)
  ///
  /// In en, this message translates to:
  /// **'It has already started. Scenes already made are charged; the rest comes back.'**
  String get mvCancelStarted;

  /// Cancel dialog confirm
  ///
  /// In en, this message translates to:
  /// **'Stop video'**
  String get mvCancelConfirm;

  /// Toast after a cancel was acknowledged
  ///
  /// In en, this message translates to:
  /// **'Video stopped'**
  String get mvCancelled;

  /// Toast after a queued cancel (full refund)
  ///
  /// In en, this message translates to:
  /// **'Video stopped — nothing was used'**
  String get mvCancelledRefunded;

  /// P20 when no video is in flight
  ///
  /// In en, this message translates to:
  /// **'No video is being made right now.'**
  String get mvNothing;

  /// P20 credit-gap headline
  ///
  /// In en, this message translates to:
  /// **'Not enough credits'**
  String get mvQuotaTitle;

  /// P21 explicit disclosure under the video
  ///
  /// In en, this message translates to:
  /// **'AI generated — the badge is part of the video'**
  String get mvAiLabelBurnedIn;

  /// P21 save to Photos
  ///
  /// In en, this message translates to:
  /// **'Save to Photos'**
  String get mvSave;

  /// P21 save to Files
  ///
  /// In en, this message translates to:
  /// **'Save to Files'**
  String get mvSaveFiles;

  /// Share sheet text for the video
  ///
  /// In en, this message translates to:
  /// **'I made this music video with Songlet 🎬'**
  String get mvShareText;

  /// P21 when the file is gone
  ///
  /// In en, this message translates to:
  /// **'This video isn\'t on this device anymore.'**
  String get mvMissing;

  /// Delete dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete this video?'**
  String get mvDeleteTitle;

  /// Delete dialog body
  ///
  /// In en, this message translates to:
  /// **'It\'s removed from this device.'**
  String get mvDeleteBody;

  /// Toast after delete
  ///
  /// In en, this message translates to:
  /// **'Video deleted'**
  String get mvDeleted;

  /// P21 footnote
  ///
  /// In en, this message translates to:
  /// **'Made with Google Lyria 3 and AI video models · AI generated'**
  String get mvProvenance;

  /// P13 section header
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get detailVideos;

  /// P13 / P09 make-a-video action
  ///
  /// In en, this message translates to:
  /// **'Make a video'**
  String get detailMakeVideo;

  /// Video row status
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get mvStatusReady;

  /// Video row status
  ///
  /// In en, this message translates to:
  /// **'Making…'**
  String get mvStatusPending;

  /// Video row status
  ///
  /// In en, this message translates to:
  /// **'Didn\'t finish'**
  String get mvStatusFailed;

  /// Paywall MV pack row title
  ///
  /// In en, this message translates to:
  /// **'Music video'**
  String get mvPackTitle;

  /// Paywall MV pack row subtitle
  ///
  /// In en, this message translates to:
  /// **'One chorus video'**
  String get mvPackChorusSubtitle;

  /// Paywall MV pack row subtitle
  ///
  /// In en, this message translates to:
  /// **'One full-song video'**
  String get mvPackFullSubtitle;

  /// Paywall headline when opened for a music video
  ///
  /// In en, this message translates to:
  /// **'Make it a video'**
  String get paywallMvHeroTitle;

  /// Paywall subtitle when opened for a music video
  ///
  /// In en, this message translates to:
  /// **'Credits for a music video of your song — yours to save and share.'**
  String get paywallMvHeroSubtitle;

  /// Non-removable disclosure badge (PRD 9.4)
  ///
  /// In en, this message translates to:
  /// **'AI generated'**
  String get playerAiGenerated;

  /// Song playback screen. Purpose: player loop.
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get playerLoop;

  /// Song playback screen. Purpose: player play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// Song playback screen. Purpose: player pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// Song playback screen. Purpose: player preview label.
  ///
  /// In en, this message translates to:
  /// **'30-second preview'**
  String get playerPreviewLabel;

  /// Song playback screen. Purpose: player title for.
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String playerTitleFor(String name);

  /// Audio download screen. Purpose: download saved.
  ///
  /// In en, this message translates to:
  /// **'Saved to Files.'**
  String get downloadSaved;

  /// Share card, exported attribution, or system share sheet. Purpose: share composing.
  ///
  /// In en, this message translates to:
  /// **'Making your share card…'**
  String get shareComposing;

  /// Share card, exported attribution, or system share sheet. Purpose: share failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t make the share card.'**
  String get shareFailed;

  /// Share card, exported attribution, or system share sheet. Purpose: share text.
  ///
  /// In en, this message translates to:
  /// **'I made this song with Songlet 🎵'**
  String get shareText;

  /// Purchase screen. Purpose: paywall best value.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get paywallBestValue;

  /// Purchase screen. Purpose: paywall start trial.
  ///
  /// In en, this message translates to:
  /// **'Start free trial'**
  String get paywallStartTrial;

  /// Purchase screen. Purpose: paywall close.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get paywallClose;

  /// Purchase screen. Purpose: paywall see plans.
  ///
  /// In en, this message translates to:
  /// **'See subscriptions'**
  String get paywallSeePlans;

  /// Purchase screen. Purpose: paywall current plan.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Your plan is active — {count} full song left this period.} other{Your plan is active — {count} full songs left this period.}}'**
  String paywallCurrentPlan(int count);

  /// Saved-song library. Purpose: library empty.
  ///
  /// In en, this message translates to:
  /// **'Your songs will live here.'**
  String get libraryEmpty;

  /// Saved-song library. Purpose: library empty action.
  ///
  /// In en, this message translates to:
  /// **'Make your first song'**
  String get libraryEmptyAction;

  /// Saved-song library. Purpose: library pending.
  ///
  /// In en, this message translates to:
  /// **'Composing…'**
  String get libraryPending;

  /// Saved-song library. Purpose: library preview badge.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get libraryPreviewBadge;

  /// Saved-song library. Purpose: library song badge.
  ///
  /// In en, this message translates to:
  /// **'Full song'**
  String get librarySongBadge;

  /// Settings screen. Purpose: settings title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings screen. Purpose: settings plan.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get settingsPlan;

  /// Settings screen. Purpose: settings plan unavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your plan. Pull to try again later.'**
  String get settingsPlanUnavailable;

  /// Plan tier display. Purpose: tier free.
  ///
  /// In en, this message translates to:
  /// **'No subscription'**
  String get tierFree;

  /// Plan tier display. Purpose: tier pack.
  ///
  /// In en, this message translates to:
  /// **'Song packs'**
  String get tierPack;

  /// Settings screen. Purpose: settings songs left.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} full song left} other{{count} full songs left}}'**
  String settingsSongsLeft(int count);

  /// Settings screen. Purpose: settings clips left.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} preview left} other{{count} previews left}}'**
  String settingsClipsLeft(int count);

  /// Settings screen. Purpose: settings resets.
  ///
  /// In en, this message translates to:
  /// **'Resets {date}'**
  String settingsResets(DateTime date);

  /// Settings screen. Purpose: settings upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get settingsUpgrade;

  /// Brand tagline under the app name
  ///
  /// In en, this message translates to:
  /// **'Songs for the people you love'**
  String get appTagline;

  /// Shared buttons and messages. Purpose: common close.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonClose;

  /// Shared buttons and messages. Purpose: common done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Shared buttons and messages. Purpose: common delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Shared buttons and messages. Purpose: common more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// Shared buttons and messages. Purpose: common copy.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get commonCopy;

  /// Shared buttons and messages. Purpose: common copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get commonCopied;

  /// Shared buttons and messages. Purpose: common not now.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get commonNotNow;

  /// Shared buttons and messages. Purpose: common learn more.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get commonLearnMore;

  /// Shared buttons and messages. Purpose: common see all.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// Shared buttons and messages. Purpose: common keep going.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get commonKeepGoing;

  /// P01 prompt field hint
  ///
  /// In en, this message translates to:
  /// **'Describe the song you want'**
  String get composerHint;

  /// P01 + button
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get composerAddPhotos;

  /// Song creation composer. Purpose: composer source music hint.
  ///
  /// In en, this message translates to:
  /// **'Describe it in your own words'**
  String get composerSourceMusicHint;

  /// P01 mic button
  ///
  /// In en, this message translates to:
  /// **'Dictate'**
  String get composerDictate;

  /// P03a stop button
  ///
  /// In en, this message translates to:
  /// **'Stop dictation'**
  String get composerStopDictation;

  /// Composer summary row: the 30-second preview (lyria-3-clip-preview).
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get lengthPreview;

  /// Composer summary row and options: the full ~2-minute song (lyria-3.5).
  ///
  /// In en, this message translates to:
  /// **'Full song'**
  String get lengthFull;

  /// Song option selector. Purpose: param length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get paramLength;

  /// Song option selector. Purpose: param vocals.
  ///
  /// In en, this message translates to:
  /// **'Vocals'**
  String get paramVocals;

  /// Song option selector. Purpose: param genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get paramGenre;

  /// Template tile play button
  ///
  /// In en, this message translates to:
  /// **'Play a sample of {name}'**
  String templatePlaySample(String name);

  /// Song template and creation form. Purpose: template pause sample.
  ///
  /// In en, this message translates to:
  /// **'Pause the sample'**
  String get templatePauseSample;

  /// Song length selector. Purpose: length short.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get lengthShort;

  /// Song length selector. Purpose: length short hint.
  ///
  /// In en, this message translates to:
  /// **'30-second preview'**
  String get lengthShortHint;

  /// Song length selector. Purpose: length standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get lengthStandard;

  /// Song length selector. Purpose: length standard hint.
  ///
  /// In en, this message translates to:
  /// **'about 2 minutes, Pro'**
  String get lengthStandardHint;

  /// Vocal option selector. Purpose: vocals custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get vocalsCustom;

  /// Vocal option selector. Purpose: vocals custom hint.
  ///
  /// In en, this message translates to:
  /// **'based on your prompt'**
  String get vocalsCustomHint;

  /// Vocal option selector. Purpose: vocals custom detail.
  ///
  /// In en, this message translates to:
  /// **'Vocals style follows your prompt.'**
  String get vocalsCustomDetail;

  /// Vocal option selector. Purpose: vocals on.
  ///
  /// In en, this message translates to:
  /// **'Vocals on'**
  String get vocalsOn;

  /// Vocal option selector. Purpose: vocals instrumental.
  ///
  /// In en, this message translates to:
  /// **'Instrumental'**
  String get vocalsInstrumental;

  /// Vocal option selector. Purpose: vocals lyrics in.
  ///
  /// In en, this message translates to:
  /// **'Lyrics are written in {language}'**
  String vocalsLyricsIn(String language);

  /// Genre picker. Purpose: genre custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get genreCustom;

  /// Genre picker. Purpose: genre custom hint.
  ///
  /// In en, this message translates to:
  /// **'based on your prompt'**
  String get genreCustomHint;

  /// Genre picker. Purpose: genre popular in.
  ///
  /// In en, this message translates to:
  /// **'Popular in {country}'**
  String genrePopularIn(String country);

  /// Genre picker. Purpose: genre all.
  ///
  /// In en, this message translates to:
  /// **'All genres'**
  String get genreAll;

  /// Country and lyrics-language sheet. Purpose: region helper.
  ///
  /// In en, this message translates to:
  /// **'Changes the 3 recommended genres and the lyrics language'**
  String get regionHelper;

  /// Country and lyrics-language sheet. Purpose: region lyrics row.
  ///
  /// In en, this message translates to:
  /// **'Lyrics language: {language}'**
  String regionLyricsRow(String language);

  /// Country and lyrics-language sheet. Purpose: region no match.
  ///
  /// In en, this message translates to:
  /// **'No countries match'**
  String get regionNoMatch;

  /// Creation keywords. Purpose: keyword add.
  ///
  /// In en, this message translates to:
  /// **'Add a word'**
  String get keywordAdd;

  /// Creation keywords. Purpose: keyword remove.
  ///
  /// In en, this message translates to:
  /// **'Remove {word}'**
  String keywordRemove(String word);

  /// Recipient name field. Purpose: name clear.
  ///
  /// In en, this message translates to:
  /// **'Clear name'**
  String get nameClear;

  /// Own-lyrics editor. Purpose: lyrics optional.
  ///
  /// In en, this message translates to:
  /// **'Write your own lyrics (optional)'**
  String get lyricsOptional;

  /// P18 name field
  ///
  /// In en, this message translates to:
  /// **'Artist names can’t be used.'**
  String get issueRecipientArtistName;

  /// Creation form validation; explain how to correct the input. Purpose: issue prompt too long.
  ///
  /// In en, this message translates to:
  /// **'Keep the description under {limit} characters.'**
  String issuePromptTooLong(int limit);

  /// On-device dictation panel. Purpose: voice recording.
  ///
  /// In en, this message translates to:
  /// **'Recording…'**
  String get voiceRecording;

  /// On-device dictation panel. Purpose: voice starting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get voiceStarting;

  /// On-device dictation panel. Purpose: voice listening.
  ///
  /// In en, this message translates to:
  /// **'Say who it’s for and what they love…'**
  String get voiceListening;

  /// On-device dictation panel. Purpose: voice on device.
  ///
  /// In en, this message translates to:
  /// **'On-device transcription'**
  String get voiceOnDevice;

  /// On-device dictation panel. Purpose: voice permission denied.
  ///
  /// In en, this message translates to:
  /// **'Allow the microphone and speech recognition for Songlet in Settings to dictate.'**
  String get voicePermissionDenied;

  /// On-device dictation panel. Purpose: voice unavailable.
  ///
  /// In en, this message translates to:
  /// **'Dictation isn’t available for this language on this device.'**
  String get voiceUnavailable;

  /// On-device dictation panel. Purpose: voice applied.
  ///
  /// In en, this message translates to:
  /// **'Added from your voice'**
  String get voiceApplied;

  /// Photo selection. Purpose: photo remove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photoRemove;

  /// Song generation progress and cancellation. Purpose: generating title for.
  ///
  /// In en, this message translates to:
  /// **'Writing {name}’s song…'**
  String generatingTitleFor(String name);

  /// Song generation progress and cancellation. Purpose: generating title generic.
  ///
  /// In en, this message translates to:
  /// **'Writing your song…'**
  String get generatingTitleGeneric;

  /// Song generation progress and cancellation. Purpose: generating usually.
  ///
  /// In en, this message translates to:
  /// **'Usually about {seconds} seconds'**
  String generatingUsually(int seconds);

  /// Song generation progress and cancellation. Purpose: generating percent.
  ///
  /// In en, this message translates to:
  /// **'{percent}'**
  String generatingPercent(String percent);

  /// Song generation progress and cancellation. Purpose: generating progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get generatingProgress;

  /// Song generation progress and cancellation. Purpose: generating glimpse.
  ///
  /// In en, this message translates to:
  /// **'A glimpse of your song'**
  String get generatingGlimpse;

  /// Song generation progress and cancellation. Purpose: generating cancel title.
  ///
  /// In en, this message translates to:
  /// **'Stop this song?'**
  String get generatingCancelTitle;

  /// Song generation progress and cancellation. Purpose: generating cancel queued.
  ///
  /// In en, this message translates to:
  /// **'It hasn’t started yet, so it won’t count toward your allowance.'**
  String get generatingCancelQueued;

  /// Song generation progress and cancellation. Purpose: generating cancel started.
  ///
  /// In en, this message translates to:
  /// **'It has already started, so it still counts toward your allowance.'**
  String get generatingCancelStarted;

  /// Song generation progress and cancellation. Purpose: generating cancel confirm.
  ///
  /// In en, this message translates to:
  /// **'Stop song'**
  String get generatingCancelConfirm;

  /// Song generation progress and cancellation. Purpose: generating cancelled.
  ///
  /// In en, this message translates to:
  /// **'Song stopped'**
  String get generatingCancelled;

  /// Song generation progress and cancellation. Purpose: generating cancelled refunded.
  ///
  /// In en, this message translates to:
  /// **'Song stopped — nothing was used'**
  String get generatingCancelledRefunded;

  /// Song generation queue. Purpose: queue title.
  ///
  /// In en, this message translates to:
  /// **'Lots of songs being made right now.'**
  String get queueTitle;

  /// Song generation queue. Purpose: queue subtitle.
  ///
  /// In en, this message translates to:
  /// **'Yours is queued.'**
  String get queueSubtitle;

  /// Song generation queue. Purpose: queue position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get queuePosition;

  /// Song generation queue. Purpose: queue wait.
  ///
  /// In en, this message translates to:
  /// **'estimated wait'**
  String get queueWait;

  /// Song generation queue. Purpose: queue wait minutes.
  ///
  /// In en, this message translates to:
  /// **'≈ {minutes} min'**
  String queueWaitMinutes(int minutes);

  /// Song generation progress and cancellation. Purpose: generating nothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing is being made right now.'**
  String get generatingNothing;

  /// Song preview screen. Purpose: preview get full.
  ///
  /// In en, this message translates to:
  /// **'Get the full 2-minute song'**
  String get previewGetFull;

  /// Song preview screen. Purpose: preview share.
  ///
  /// In en, this message translates to:
  /// **'Share preview'**
  String get previewShare;

  /// Song preview screen. Purpose: preview another.
  ///
  /// In en, this message translates to:
  /// **'Try another version (uses 1 preview)'**
  String get previewAnother;

  /// Song playback screen. Purpose: player position.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get playerPosition;

  /// Song playback screen. Purpose: player prev section.
  ///
  /// In en, this message translates to:
  /// **'Previous section'**
  String get playerPrevSection;

  /// Song playback screen. Purpose: player next section.
  ///
  /// In en, this message translates to:
  /// **'Next section'**
  String get playerNextSection;

  /// Song playback screen. Purpose: player shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle sections'**
  String get playerShuffle;

  /// Song playback screen. Purpose: player repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get playerRepeat;

  /// Song playback screen. Purpose: player provenance.
  ///
  /// In en, this message translates to:
  /// **'Made with Google Lyria 3 · SynthID watermark · AI generated'**
  String get playerProvenance;

  /// Song playback screen. Purpose: player missing.
  ///
  /// In en, this message translates to:
  /// **'This song isn’t on this device anymore.'**
  String get playerMissing;

  /// Work action button. Purpose: action download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get actionDownload;

  /// Work action button. Purpose: action share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// Work action button. Purpose: action license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get actionLicense;

  /// Work action button. Purpose: action regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get actionRegenerate;

  /// Work action button. Purpose: action details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get actionDetails;

  /// Song section display label; never translate the inserted protocol token. Purpose: section intro.
  ///
  /// In en, this message translates to:
  /// **'Intro'**
  String get sectionIntro;

  /// Song section display label; never translate the inserted protocol token. Purpose: section verse.
  ///
  /// In en, this message translates to:
  /// **'Verse'**
  String get sectionVerse;

  /// Song section display label; never translate the inserted protocol token. Purpose: section pre chorus.
  ///
  /// In en, this message translates to:
  /// **'Pre-chorus'**
  String get sectionPreChorus;

  /// Song section display label; never translate the inserted protocol token. Purpose: section chorus.
  ///
  /// In en, this message translates to:
  /// **'Chorus'**
  String get sectionChorus;

  /// Song section display label; never translate the inserted protocol token. Purpose: section bridge.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get sectionBridge;

  /// Song section display label; never translate the inserted protocol token. Purpose: section outro.
  ///
  /// In en, this message translates to:
  /// **'Outro'**
  String get sectionOutro;

  /// Song section display label; never translate the inserted protocol token. Purpose: section hook.
  ///
  /// In en, this message translates to:
  /// **'Hook'**
  String get sectionHook;

  /// Share card, exported attribution, or system share sheet. Purpose: share title.
  ///
  /// In en, this message translates to:
  /// **'Share card'**
  String get shareTitle;

  /// Share card, exported attribution, or system share sheet. Purpose: share subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a theme and layout.'**
  String get shareSubtitle;

  /// Share card, exported attribution, or system share sheet. Purpose: share theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get shareTheme;

  /// Share card, exported attribution, or system share sheet. Purpose: share layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get shareLayout;

  /// Share card, exported attribution, or system share sheet. Purpose: share layout scene.
  ///
  /// In en, this message translates to:
  /// **'With art'**
  String get shareLayoutScene;

  /// Share card, exported attribution, or system share sheet. Purpose: share layout text.
  ///
  /// In en, this message translates to:
  /// **'Text only'**
  String get shareLayoutText;

  /// Share-card color theme. Purpose: palette terracotta.
  ///
  /// In en, this message translates to:
  /// **'Terracotta'**
  String get paletteTerracotta;

  /// Share-card color theme. Purpose: palette sand.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get paletteSand;

  /// Share-card color theme. Purpose: palette olive.
  ///
  /// In en, this message translates to:
  /// **'Olive'**
  String get paletteOlive;

  /// Share-card color theme. Purpose: palette navy.
  ///
  /// In en, this message translates to:
  /// **'Navy'**
  String get paletteNavy;

  /// Share card, exported attribution, or system share sheet. Purpose: share action.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// Share card, exported attribution, or system share sheet. Purpose: share save video.
  ///
  /// In en, this message translates to:
  /// **'Save video'**
  String get shareSaveVideo;

  /// Share card, exported attribution, or system share sheet. Purpose: share copy lyrics.
  ///
  /// In en, this message translates to:
  /// **'Copy lyrics'**
  String get shareCopyLyrics;

  /// Share card, exported attribution, or system share sheet. Purpose: share video saved.
  ///
  /// In en, this message translates to:
  /// **'Saved to Photos'**
  String get shareVideoSaved;

  /// Share card, exported attribution, or system share sheet. Purpose: share lyrics copied.
  ///
  /// In en, this message translates to:
  /// **'Lyrics copied'**
  String get shareLyricsCopied;

  /// Share card, exported attribution, or system share sheet. Purpose: share card tagline.
  ///
  /// In en, this message translates to:
  /// **'A song for someone'**
  String get shareCardTagline;

  /// Share card, exported attribution, or system share sheet. Purpose: share save failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save the video. Allow Songlet to add to Photos in Settings.'**
  String get shareSaveFailed;

  /// Audio download screen. Purpose: download ready.
  ///
  /// In en, this message translates to:
  /// **'Full song ready'**
  String get downloadReady;

  /// Audio download screen. Purpose: download title.
  ///
  /// In en, this message translates to:
  /// **'Yours to keep'**
  String get downloadTitle;

  /// Audio download screen. Purpose: download intro.
  ///
  /// In en, this message translates to:
  /// **'Your song is ready. Download high-quality audio and your commercial license below.'**
  String get downloadIntro;

  /// Audio download screen. Purpose: download audio header.
  ///
  /// In en, this message translates to:
  /// **'Download audio'**
  String get downloadAudioHeader;

  /// Audio download screen. Purpose: download audio note.
  ///
  /// In en, this message translates to:
  /// **'High quality'**
  String get downloadAudioNote;

  /// Audio download screen. Purpose: download mp3 title.
  ///
  /// In en, this message translates to:
  /// **'MP3 · 320 kbps'**
  String get downloadMp3Title;

  /// Audio download screen. Purpose: download mp3 subtitle.
  ///
  /// In en, this message translates to:
  /// **'Best for sharing and everyday listening'**
  String get downloadMp3Subtitle;

  /// Audio download screen. Purpose: download wav title.
  ///
  /// In en, this message translates to:
  /// **'WAV · 44.1 kHz (Premier)'**
  String get downloadWavTitle;

  /// Audio download screen. Purpose: download wav subtitle.
  ///
  /// In en, this message translates to:
  /// **'Highest quality for professional use'**
  String get downloadWavSubtitle;

  /// Audio download screen. Purpose: download mp3 action.
  ///
  /// In en, this message translates to:
  /// **'Download MP3'**
  String get downloadMp3Action;

  /// Audio download screen. Purpose: download wav action.
  ///
  /// In en, this message translates to:
  /// **'Download WAV'**
  String get downloadWavAction;

  /// Audio download screen. Purpose: download license action.
  ///
  /// In en, this message translates to:
  /// **'Download license'**
  String get downloadLicenseAction;

  /// Commercial-license download and information. Purpose: license header.
  ///
  /// In en, this message translates to:
  /// **'Commercial license'**
  String get licenseHeader;

  /// Commercial-license download and information. Purpose: license included.
  ///
  /// In en, this message translates to:
  /// **'Included with your plan'**
  String get licenseIncluded;

  /// Commercial-license download and information. Purpose: license not included.
  ///
  /// In en, this message translates to:
  /// **'Comes with a plan or pack'**
  String get licenseNotIncluded;

  /// Commercial-license download and information. Purpose: license pdf title.
  ///
  /// In en, this message translates to:
  /// **'Commercial license (PDF)'**
  String get licensePdfTitle;

  /// Commercial-license download and information. Purpose: license generated.
  ///
  /// In en, this message translates to:
  /// **'Generated on {date}'**
  String licenseGenerated(DateTime date);

  /// Commercial-license download and information. Purpose: license id.
  ///
  /// In en, this message translates to:
  /// **'License ID: {id}'**
  String licenseId(String id);

  /// Commercial-license download and information. Purpose: license uses title.
  ///
  /// In en, this message translates to:
  /// **'You can use this song for:'**
  String get licenseUsesTitle;

  /// Commercial-license permitted uses. Purpose: use personal.
  ///
  /// In en, this message translates to:
  /// **'Personal use'**
  String get usePersonal;

  /// Commercial-license permitted uses. Purpose: use personal detail.
  ///
  /// In en, this message translates to:
  /// **'Gifts, memories, non-commercial'**
  String get usePersonalDetail;

  /// Commercial-license permitted uses. Purpose: use ads.
  ///
  /// In en, this message translates to:
  /// **'Ads & marketing'**
  String get useAds;

  /// Commercial-license permitted uses. Purpose: use ads detail.
  ///
  /// In en, this message translates to:
  /// **'Promotions, paid campaigns'**
  String get useAdsDetail;

  /// Commercial-license permitted uses. Purpose: use social.
  ///
  /// In en, this message translates to:
  /// **'Social media'**
  String get useSocial;

  /// Commercial-license permitted uses. Purpose: use social detail.
  ///
  /// In en, this message translates to:
  /// **'TikTok, Instagram, YouTube, etc.'**
  String get useSocialDetail;

  /// Commercial-license permitted uses. Purpose: use podcasts.
  ///
  /// In en, this message translates to:
  /// **'Podcasts & videos'**
  String get usePodcasts;

  /// Commercial-license permitted uses. Purpose: use podcasts detail.
  ///
  /// In en, this message translates to:
  /// **'Monetized content'**
  String get usePodcastsDetail;

  /// Commercial-license download and information. Purpose: license details note.
  ///
  /// In en, this message translates to:
  /// **'Full details are in the license PDF.'**
  String get licenseDetailsNote;

  /// Save and export actions. Purpose: save enjoy header.
  ///
  /// In en, this message translates to:
  /// **'Save and enjoy'**
  String get saveEnjoyHeader;

  /// Save and export actions. Purpose: save to files.
  ///
  /// In en, this message translates to:
  /// **'Save to Files'**
  String get saveToFiles;

  /// Export action. Purpose: add to music.
  ///
  /// In en, this message translates to:
  /// **'Add to Music'**
  String get addToMusic;

  /// AI watermark explanation. Purpose: synth id note.
  ///
  /// In en, this message translates to:
  /// **'This song contains a SynthID watermark to identify AI-generated content, even after downloading.'**
  String get synthIdNote;

  /// WAV download availability. Purpose: wav needs premier.
  ///
  /// In en, this message translates to:
  /// **'WAV downloads come with Premier.'**
  String get wavNeedsPremier;

  /// A Premier user tried to save WAV for a song that has no WAV render.
  ///
  /// In en, this message translates to:
  /// **'There\'s no WAV file for this song. WAV files can be saved for 24 hours after a song is made.'**
  String get wavUnavailable;

  /// Saved-song library. Purpose: library filter all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryFilterAll;

  /// Library section for songs without a template occasion
  ///
  /// In en, this message translates to:
  /// **'Just because'**
  String get libraryJustBecause;

  /// Saved-song library. Purpose: library play.
  ///
  /// In en, this message translates to:
  /// **'Play {title}'**
  String libraryPlay(String title);

  /// Saved-song library. Purpose: library actions.
  ///
  /// In en, this message translates to:
  /// **'Actions for {title}'**
  String libraryActions(String title);

  /// Saved-song library. Purpose: library delete title.
  ///
  /// In en, this message translates to:
  /// **'Delete this song?'**
  String get libraryDeleteTitle;

  /// Saved-song library. Purpose: library delete body.
  ///
  /// In en, this message translates to:
  /// **'It’s removed from this device. If iCloud sync is on, it’s removed from your other devices too.'**
  String get libraryDeleteBody;

  /// Saved-song library. Purpose: library deleted.
  ///
  /// In en, this message translates to:
  /// **'Song deleted'**
  String get libraryDeleted;

  /// Saved-song library. Purpose: library failed.
  ///
  /// In en, this message translates to:
  /// **'Didn’t finish'**
  String get libraryFailed;

  /// Saved-song library. Purpose: library no match.
  ///
  /// In en, this message translates to:
  /// **'No songs for this occasion yet.'**
  String get libraryNoMatch;

  /// Work details screen. Purpose: detail full generated.
  ///
  /// In en, this message translates to:
  /// **'Full song generated'**
  String get detailFullGenerated;

  /// Work details screen. Purpose: detail preview generated.
  ///
  /// In en, this message translates to:
  /// **'Preview generated'**
  String get detailPreviewGenerated;

  /// Work details screen. Purpose: detail generated on.
  ///
  /// In en, this message translates to:
  /// **'Generated {date}'**
  String detailGeneratedOn(DateTime date);

  /// Work details screen. Purpose: detail prompt used.
  ///
  /// In en, this message translates to:
  /// **'Prompt used'**
  String get detailPromptUsed;

  /// Work details screen. Purpose: detail occasion.
  ///
  /// In en, this message translates to:
  /// **'Occasion'**
  String get detailOccasion;

  /// Work details screen. Purpose: detail country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get detailCountry;

  /// Work details screen. Purpose: detail genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get detailGenre;

  /// Work details screen. Purpose: detail keywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get detailKeywords;

  /// Work details screen. Purpose: detail description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get detailDescription;

  /// Work details screen. Purpose: detail lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get detailLyrics;

  /// Work details screen. Purpose: detail generation id.
  ///
  /// In en, this message translates to:
  /// **'Generation ID'**
  String get detailGenerationId;

  /// Work details screen. Purpose: detail regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate same style'**
  String get detailRegenerate;

  /// Work details screen. Purpose: detail custom genre.
  ///
  /// In en, this message translates to:
  /// **'Based on the prompt'**
  String get detailCustomGenre;

  /// Settings screen. Purpose: settings section plan.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get settingsSectionPlan;

  /// Settings screen. Purpose: settings section library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsSectionLibrary;

  /// Settings screen. Purpose: settings section about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// Settings screen. Purpose: settings restore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get settingsRestore;

  /// Settings screen. Purpose: settings manage.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get settingsManage;

  /// Settings screen. Purpose: settings i cloud.
  ///
  /// In en, this message translates to:
  /// **'iCloud sync'**
  String get settingsICloud;

  /// Settings screen. Purpose: settings i cloud on.
  ///
  /// In en, this message translates to:
  /// **'Songs sync across your devices'**
  String get settingsICloudOn;

  /// Settings screen. Purpose: settings i cloud off.
  ///
  /// In en, this message translates to:
  /// **'Songs stay on this device'**
  String get settingsICloudOff;

  /// Settings screen. Purpose: settings i cloud unavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign in to iCloud in Settings to sync'**
  String get settingsICloudUnavailable;

  /// Settings screen. Purpose: settings lyrics language.
  ///
  /// In en, this message translates to:
  /// **'Default lyrics language'**
  String get settingsLyricsLanguage;

  /// Settings screen. Purpose: settings lyrics language auto.
  ///
  /// In en, this message translates to:
  /// **'Match the country'**
  String get settingsLyricsLanguageAuto;

  /// Settings screen. Purpose: settings terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get settingsTerms;

  /// Settings screen. Purpose: settings privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// Settings screen. Purpose: settings version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// About generation and privacy. Purpose: about title.
  ///
  /// In en, this message translates to:
  /// **'About generation'**
  String get aboutTitle;

  /// About generation and privacy. Purpose: about subtitle.
  ///
  /// In en, this message translates to:
  /// **'How Songlet makes your songs'**
  String get aboutSubtitle;

  /// About generation and privacy. Purpose: about lyria title.
  ///
  /// In en, this message translates to:
  /// **'Powered by Google’s Lyria 3'**
  String get aboutLyriaTitle;

  /// About generation and privacy. Purpose: about lyria body.
  ///
  /// In en, this message translates to:
  /// **'Songs are generated by Google’s Lyria 3 via the Gemini API. Lyria 3 is a music generation model that turns your ideas into original songs.'**
  String get aboutLyriaBody;

  /// About generation and privacy. Purpose: about watermark title.
  ///
  /// In en, this message translates to:
  /// **'Built-in watermark'**
  String get aboutWatermarkTitle;

  /// About generation and privacy. Purpose: about watermark body.
  ///
  /// In en, this message translates to:
  /// **'Every song includes a SynthID watermark from Google. It helps identify AI-generated music and can’t be removed.'**
  String get aboutWatermarkBody;

  /// About generation and privacy. Purpose: about imitation title.
  ///
  /// In en, this message translates to:
  /// **'No imitations of real artists'**
  String get aboutImitationTitle;

  /// About generation and privacy. Purpose: about imitation body.
  ///
  /// In en, this message translates to:
  /// **'Songlet never imitates real artists, their voices or specific styles. Songs are original and created from your own ideas, prompts and photos.'**
  String get aboutImitationBody;

  /// About generation and privacy. Purpose: about privacy title.
  ///
  /// In en, this message translates to:
  /// **'Your privacy matters'**
  String get aboutPrivacyTitle;

  /// About generation and privacy. Purpose: about privacy body.
  ///
  /// In en, this message translates to:
  /// **'Photos and prompts are deleted from our servers within 24 hours. We don’t keep your images or prompts after your song has been generated.'**
  String get aboutPrivacyBody;

  /// About generation and privacy. Purpose: about banner.
  ///
  /// In en, this message translates to:
  /// **'Every song you share is labeled AI generated.'**
  String get aboutBanner;

  /// About generation and privacy. Purpose: about footer.
  ///
  /// In en, this message translates to:
  /// **'Songlet {version} · Made with Google Lyria 3'**
  String aboutFooter(String version);

  /// Festival creation screen. Purpose: festival kicker.
  ///
  /// In en, this message translates to:
  /// **'Live your story'**
  String get festivalKicker;

  /// Festival creation screen. Purpose: festival coming.
  ///
  /// In en, this message translates to:
  /// **'is coming!'**
  String get festivalComing;

  /// Festival creation screen. Purpose: festival body.
  ///
  /// In en, this message translates to:
  /// **'Make a one-of-a-kind song to celebrate.'**
  String get festivalBody;

  /// Festival creation screen. Purpose: festival cta.
  ///
  /// In en, this message translates to:
  /// **'Make a {festival} song'**
  String festivalCta(String festival);

  /// Festival creation screen. Purpose: festival pick occasion.
  ///
  /// In en, this message translates to:
  /// **'Pick an occasion and start creating'**
  String get festivalPickOccasion;

  /// Festival creation screen. Purpose: festival languages title.
  ///
  /// In en, this message translates to:
  /// **'Songs in your language'**
  String get festivalLanguagesTitle;

  /// Festival creation screen. Purpose: festival languages body.
  ///
  /// In en, this message translates to:
  /// **'Make songs in {language} and 12 more languages'**
  String festivalLanguagesBody(String language);

  /// Service availability screen. Purpose: unavailable title.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable'**
  String get unavailableTitle;

  /// Service availability screen. Purpose: unavailable message.
  ///
  /// In en, this message translates to:
  /// **'Songlet can’t make songs right now. Your library still works — try again in a little while.'**
  String get unavailableMessage;

  /// Purchase screen. Purpose: paywall hero title.
  ///
  /// In en, this message translates to:
  /// **'Make it a full song'**
  String get paywallHeroTitle;

  /// Purchase screen. Purpose: paywall hero subtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn your idea into a complete song with higher quality and full rights.'**
  String get paywallHeroSubtitle;

  /// Purchase screen. Purpose: paywall benefit songs.
  ///
  /// In en, this message translates to:
  /// **'More songs'**
  String get paywallBenefitSongs;

  /// Purchase screen. Purpose: paywall benefit quality.
  ///
  /// In en, this message translates to:
  /// **'Higher quality'**
  String get paywallBenefitQuality;

  /// Purchase screen. Purpose: paywall benefit commercial.
  ///
  /// In en, this message translates to:
  /// **'Commercial use'**
  String get paywallBenefitCommercial;

  /// Purchase screen subscription benefits. Purpose: plan songs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} full song per month} other{{count} full songs per month}}'**
  String planSongs(int count);

  /// Purchase screen subscription benefits. Purpose: plan previews.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} preview per month} other{{count} previews per month}}'**
  String planPreviews(int count);

  /// Purchase screen subscription benefits. Purpose: plan mp3.
  ///
  /// In en, this message translates to:
  /// **'MP3 download'**
  String get planMp3;

  /// Purchase screen subscription benefits. Purpose: plan mp3 wav.
  ///
  /// In en, this message translates to:
  /// **'MP3 + WAV download'**
  String get planMp3Wav;

  /// Purchase screen subscription benefits. Purpose: plan license.
  ///
  /// In en, this message translates to:
  /// **'Commercial license'**
  String get planLicense;

  /// Purchase screen subscription benefits. Purpose: plan priority.
  ///
  /// In en, this message translates to:
  /// **'Priority generation'**
  String get planPriority;

  /// Purchase screen subscription benefits. Purpose: plan trial.
  ///
  /// In en, this message translates to:
  /// **'{days}-day free trial'**
  String planTrial(int days);

  /// Purchase screen subscription benefits. Purpose: plan per year.
  ///
  /// In en, this message translates to:
  /// **'{price}/yr'**
  String planPerYear(String price);

  /// Purchase screen subscription benefits. Purpose: plan per month.
  ///
  /// In en, this message translates to:
  /// **'{price}/mo'**
  String planPerMonth(String price);

  /// Purchase screen one-time song pack. Purpose: pack title.
  ///
  /// In en, this message translates to:
  /// **'Just need a few?'**
  String get packTitle;

  /// Purchase screen one-time song pack. Purpose: pack subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count}-song pack} other{{count}-song pack}}'**
  String packSubtitle(int count);

  /// Purchase screen one-time song pack. Purpose: pack note.
  ///
  /// In en, this message translates to:
  /// **'never expires'**
  String get packNote;

  /// Purchase screen benefits. Purpose: value forever.
  ///
  /// In en, this message translates to:
  /// **'Your songs, forever'**
  String get valueForever;

  /// Purchase screen benefits. Purpose: value downloads.
  ///
  /// In en, this message translates to:
  /// **'High-quality downloads'**
  String get valueDownloads;

  /// Purchase screen benefits. Purpose: value commercial.
  ///
  /// In en, this message translates to:
  /// **'Commercial use allowed'**
  String get valueCommercial;

  /// Purchase screen benefits. Purpose: value private.
  ///
  /// In en, this message translates to:
  /// **'Private by design'**
  String get valuePrivate;

  /// Paywall disclosure for a selected subscription with a free trial. States the actual recurring price and billing period after the trial, and that cancellation is possible before the trial ends. Shown together with the full auto-renewal notice.
  ///
  /// In en, this message translates to:
  /// **'After your free trial, you’ll be charged {pricePerPeriod} automatically. Cancel anytime before the trial ends.'**
  String paywallTrialDisclosure(String pricePerPeriod);

  /// Purchase screen. Purpose: paywall subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get paywallSubscribe;

  /// Purchase screen. Purpose: paywall buy pack.
  ///
  /// In en, this message translates to:
  /// **'Buy pack'**
  String get paywallBuyPack;

  /// Song template and creation form. Purpose: template birthday wish.
  ///
  /// In en, this message translates to:
  /// **'Birthday Wish'**
  String get templateBirthdayWish;

  /// Song template and creation form. Purpose: template birthday wish hint.
  ///
  /// In en, this message translates to:
  /// **'A special song for their special day'**
  String get templateBirthdayWishHint;

  /// Song template and creation form. Purpose: template birthday party.
  ///
  /// In en, this message translates to:
  /// **'Birthday Party'**
  String get templateBirthdayParty;

  /// Song template and creation form. Purpose: template birthday party hint.
  ///
  /// In en, this message translates to:
  /// **'Turn up the party for the birthday star'**
  String get templateBirthdayPartyHint;

  /// Song template and creation form. Purpose: template love story.
  ///
  /// In en, this message translates to:
  /// **'Love Story'**
  String get templateLoveStory;

  /// Song template and creation form. Purpose: template love story hint.
  ///
  /// In en, this message translates to:
  /// **'Your story together, set to music'**
  String get templateLoveStoryHint;

  /// Song template and creation form. Purpose: template thank a friend.
  ///
  /// In en, this message translates to:
  /// **'Thank a Friend'**
  String get templateThankAFriend;

  /// Song template and creation form. Purpose: template thank a friend hint.
  ///
  /// In en, this message translates to:
  /// **'Say thank you the way words can’t'**
  String get templateThankAFriendHint;

  /// Song template and creation form. Purpose: template party invite.
  ///
  /// In en, this message translates to:
  /// **'Party Invite'**
  String get templatePartyInvite;

  /// Song template and creation form. Purpose: template party invite hint.
  ///
  /// In en, this message translates to:
  /// **'Get everyone to the party'**
  String get templatePartyInviteHint;

  /// Song template and creation form. Purpose: template wedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get templateWedding;

  /// Song template and creation form. Purpose: template wedding hint.
  ///
  /// In en, this message translates to:
  /// **'A song for their forever moment'**
  String get templateWeddingHint;

  /// Song template and creation form. Purpose: template in memory.
  ///
  /// In en, this message translates to:
  /// **'In Memory'**
  String get templateInMemory;

  /// Song template and creation form. Purpose: template in memory hint.
  ///
  /// In en, this message translates to:
  /// **'Honor someone you cherish'**
  String get templateInMemoryHint;

  /// Song template and creation form. Purpose: template festival.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get templateFestival;

  /// Song template and creation form. Purpose: template festival hint.
  ///
  /// In en, this message translates to:
  /// **'Warm wishes for a special season'**
  String get templateFestivalHint;

  /// Song template and creation form. Purpose: template ringtone.
  ///
  /// In en, this message translates to:
  /// **'Ringtone'**
  String get templateRingtone;

  /// Song template and creation form. Purpose: template ringtone hint.
  ///
  /// In en, this message translates to:
  /// **'A short loop that’s all yours'**
  String get templateRingtoneHint;

  /// Song template and creation form. Purpose: template team anthem.
  ///
  /// In en, this message translates to:
  /// **'Team Anthem'**
  String get templateTeamAnthem;

  /// Song template and creation form. Purpose: template team anthem hint.
  ///
  /// In en, this message translates to:
  /// **'Fire up the team and the crowd'**
  String get templateTeamAnthemHint;

  /// Song template and creation form. Purpose: template sports recap.
  ///
  /// In en, this message translates to:
  /// **'Sports Recap'**
  String get templateSportsRecap;

  /// Song template and creation form. Purpose: template sports recap hint.
  ///
  /// In en, this message translates to:
  /// **'The big game, told as a song'**
  String get templateSportsRecapHint;

  /// Song template and creation form. Purpose: template rap battle.
  ///
  /// In en, this message translates to:
  /// **'Rap Battle'**
  String get templateRapBattle;

  /// Song template and creation form. Purpose: template rap battle hint.
  ///
  /// In en, this message translates to:
  /// **'Friendly bars for a friendly rival'**
  String get templateRapBattleHint;

  /// Song template and creation form. Purpose: template comedy.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get templateComedy;

  /// Song template and creation form. Purpose: template comedy hint.
  ///
  /// In en, this message translates to:
  /// **'Inside jokes, now with a chorus'**
  String get templateComedyHint;

  /// Song template and creation form. Purpose: template pet anthem.
  ///
  /// In en, this message translates to:
  /// **'Pet Anthem'**
  String get templatePetAnthem;

  /// Song template and creation form. Purpose: template pet anthem hint.
  ///
  /// In en, this message translates to:
  /// **'A theme song for your best buddy'**
  String get templatePetAnthemHint;

  /// Song template and creation form. Purpose: template hometown.
  ///
  /// In en, this message translates to:
  /// **'Hometown'**
  String get templateHometown;

  /// Song template and creation form. Purpose: template hometown hint.
  ///
  /// In en, this message translates to:
  /// **'Love for the place you call home'**
  String get templateHometownHint;

  /// Song template and creation form. Purpose: template business promo.
  ///
  /// In en, this message translates to:
  /// **'Business Promo'**
  String get templateBusinessPromo;

  /// Song template and creation form. Purpose: template business promo hint.
  ///
  /// In en, this message translates to:
  /// **'A catchy tune for your shop or brand'**
  String get templateBusinessPromoHint;

  /// Occasion name for a free-form prompt
  ///
  /// In en, this message translates to:
  /// **'Your own idea'**
  String get templateCustom;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get mvRecommended;

  /// Video length in seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String mvSeconds(int seconds);

  /// Opens the progress of a video being made.
  ///
  /// In en, this message translates to:
  /// **'See progress'**
  String get mvViewProgress;

  /// Hub banner: a video refused for credits can be finished.
  ///
  /// In en, this message translates to:
  /// **'{level} is waiting for credits'**
  String mvIntentWaiting(String level);

  /// Music-video configuration, progress, playback, or notification. Purpose: mv song expired action.
  ///
  /// In en, this message translates to:
  /// **'Make the song again'**
  String get mvSongExpiredAction;

  /// Quota sheet body.
  ///
  /// In en, this message translates to:
  /// **'{level} needs {required, plural, one{{required} credit} other{{required} credits}}. You have {available, plural, one{{available} credit} other{{available} credits}}.'**
  String mvQuotaNeed(String level, int required, int available);

  /// Music-video configuration, progress, playback, or notification. Purpose: mv quota buy and continue.
  ///
  /// In en, this message translates to:
  /// **'Buy and continue'**
  String get mvQuotaBuyAndContinue;

  /// T2/T3 storefronts: a pack grants fewer credits.
  ///
  /// In en, this message translates to:
  /// **'Where you are, one pack may not cover it — you may need two.'**
  String get mvQuotaMayNeedTwice;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv quota auto retry.
  ///
  /// In en, this message translates to:
  /// **'Your video starts as soon as the purchase goes through.'**
  String get mvQuotaAutoRetry;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv auto lyric making.
  ///
  /// In en, this message translates to:
  /// **'Making your lyric video'**
  String get mvAutoLyricMaking;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv auto chorus detail.
  ///
  /// In en, this message translates to:
  /// **'Made from this song with your credits'**
  String get mvAutoChorusDetail;

  /// Automatic video finished.
  ///
  /// In en, this message translates to:
  /// **'{level} is ready'**
  String mvAutoReady(String level);

  /// Music-video configuration, progress, playback, or notification. Purpose: mv auto view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get mvAutoView;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv upgrade chorus.
  ///
  /// In en, this message translates to:
  /// **'Make a chorus video'**
  String get mvUpgradeChorus;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv auto failed.
  ///
  /// In en, this message translates to:
  /// **'The video couldn’t start'**
  String get mvAutoFailed;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv leave hint.
  ///
  /// In en, this message translates to:
  /// **'You can leave this screen — we’ll let you know when it should be ready.'**
  String get mvLeaveHint;

  /// A failed video was refunded.
  ///
  /// In en, this message translates to:
  /// **'{credits, plural, one{Your {credits} credit is back.} other{Your {credits} credits are back.}}'**
  String mvCreditsBack(int credits);

  /// Music-video configuration, progress, playback, or notification. Purpose: mv failed title.
  ///
  /// In en, this message translates to:
  /// **'This video didn’t finish'**
  String get mvFailedTitle;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv rejected title.
  ///
  /// In en, this message translates to:
  /// **'A photo couldn’t be used'**
  String get mvRejectedTitle;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv rejected body.
  ///
  /// In en, this message translates to:
  /// **'The video model declined one of your reference photos. Adjust the photos and try again.'**
  String get mvRejectedBody;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv adjust photos.
  ///
  /// In en, this message translates to:
  /// **'Adjust photos and try again'**
  String get mvAdjustPhotos;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv try chorus.
  ///
  /// In en, this message translates to:
  /// **'Make a chorus video instead'**
  String get mvTryChorus;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv preparing photos.
  ///
  /// In en, this message translates to:
  /// **'Uploading your photos…'**
  String get mvPreparingPhotos;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv preparing submit.
  ///
  /// In en, this message translates to:
  /// **'Sending your video…'**
  String get mvPreparingSubmit;

  /// Local notification title at the video ETA.
  ///
  /// In en, this message translates to:
  /// **'Your video should be ready'**
  String get mvNotifyTitle;

  /// Local notification body.
  ///
  /// In en, this message translates to:
  /// **'{level} — tap to watch.'**
  String mvNotifyBody(String level);

  /// Music-video configuration, progress, playback, or notification. Purpose: mv regenerate.
  ///
  /// In en, this message translates to:
  /// **'Make another'**
  String get mvRegenerate;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv entry title.
  ///
  /// In en, this message translates to:
  /// **'Make it a video'**
  String get mvEntryTitle;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv entry subtitle.
  ///
  /// In en, this message translates to:
  /// **'Lyric, chorus and full-song videos, made with credits'**
  String get mvEntrySubtitle;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv entry disabled.
  ///
  /// In en, this message translates to:
  /// **'Available once the song is finished'**
  String get mvEntryDisabled;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv entry choose.
  ///
  /// In en, this message translates to:
  /// **'Choose a video'**
  String get mvEntryChoose;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv entry watch.
  ///
  /// In en, this message translates to:
  /// **'Watch video'**
  String get mvEntryWatch;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv chip ready.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get mvChipReady;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv chip making.
  ///
  /// In en, this message translates to:
  /// **'Making video'**
  String get mvChipMaking;

  /// Song length selector. Purpose: length auto video.
  ///
  /// In en, this message translates to:
  /// **'Also make a lyric video'**
  String get lengthAutoVideo;

  /// Song length selector. Purpose: length auto video hint.
  ///
  /// In en, this message translates to:
  /// **'Ready a few minutes after the song · uses credits'**
  String get lengthAutoVideoHint;

  /// Song length selector. Purpose: length song and chorus.
  ///
  /// In en, this message translates to:
  /// **'Song + chorus video'**
  String get lengthSongAndChorus;

  /// Song length selector. Purpose: length song and chorus hint.
  ///
  /// In en, this message translates to:
  /// **'The full song, then a 30-second chorus video'**
  String get lengthSongAndChorusHint;

  /// Purchase screen. Purpose: paywall video group.
  ///
  /// In en, this message translates to:
  /// **'Music videos'**
  String get paywallVideoGroup;

  /// Purchase screen subscription benefits. Purpose: plan video included.
  ///
  /// In en, this message translates to:
  /// **'Your allowance also makes music videos'**
  String get planVideoIncluded;

  /// Settings screen. Purpose: settings video credits.
  ///
  /// In en, this message translates to:
  /// **'Video credits'**
  String get settingsVideoCredits;

  /// Genre display label in creation, playback, library, and work details for Pop. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get createGenrePop;

  /// Genre display label in creation, playback, library, and work details for Hip-Hop & Rap. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Hip-Hop & Rap'**
  String get createGenreHipHopRap;

  /// Genre display label in creation, playback, library, and work details for Rock. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get createGenreRock;

  /// Genre display label in creation, playback, library, and work details for K-Pop. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'K-Pop'**
  String get createGenreKPop;

  /// Genre display label in creation, playback, library, and work details for Latin. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Latin'**
  String get createGenreLatin;

  /// Genre display label in creation, playback, library, and work details for Electronic. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Electronic'**
  String get createGenreElectronic;

  /// Genre display label in creation, playback, library, and work details for R&B. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'R&B'**
  String get createGenreRnb;

  /// Genre display label in creation, playback, library, and work details for Country. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get createGenreCountry;

  /// Genre display label in creation, playback, library, and work details for Afrobeats. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Afrobeats'**
  String get createGenreAfrobeats;

  /// Genre display label in creation, playback, library, and work details for Reggae. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Reggae'**
  String get createGenreReggae;

  /// Genre display label in creation, playback, library, and work details for Jazz & Blues. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Jazz & Blues'**
  String get createGenreJazzBlues;

  /// Genre display label in creation, playback, library, and work details for Classical. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Classical'**
  String get createGenreClassical;

  /// Genre display label in creation, playback, library, and work details for Folk. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Folk'**
  String get createGenreFolk;

  /// Genre display label in creation, playback, library, and work details for Lo-Fi. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Lo-Fi'**
  String get createGenreLofi;

  /// Genre display label in creation, playback, library, and work details for Acoustic. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Acoustic'**
  String get createGenreAcoustic;

  /// Genre display label in creation, playback, library, and work details for Cinematic. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Cinematic'**
  String get createGenreCinematic;

  /// Genre display label in creation, playback, library, and work details for Ambient. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Ambient'**
  String get createGenreAmbient;

  /// Genre display label in creation, playback, library, and work details for Bossa Nova. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Bossa Nova'**
  String get createGenreBossaNova;

  /// Genre display label in creation, playback, library, and work details for Indie Pop. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Indie Pop'**
  String get createGenreIndiePop;

  /// Genre display label in creation, playback, library, and work details for Contemporary R&B. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Contemporary R&B'**
  String get createGenreContemporaryRnb;

  /// Genre display label in creation, playback, library, and work details for Alternative Country. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Alternative Country'**
  String get createGenreAlternativeCountry;

  /// Genre display label in creation, playback, library, and work details for Garage Rock. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Garage Rock'**
  String get createGenreGarageRock;

  /// Genre display label in creation, playback, library, and work details for Grime. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Grime'**
  String get createGenreGrime;

  /// Genre display label in creation, playback, library, and work details for Indie Folk. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Indie Folk'**
  String get createGenreIndieFolk;

  /// Genre display label in creation, playback, library, and work details for Synthpop. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Synthpop'**
  String get createGenreSynthpop;

  /// Genre display label in creation, playback, library, and work details for Piano Ballad. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Piano Ballad'**
  String get createGenrePianoBallad;

  /// Genre display label in creation, playback, library, and work details for Surf Rock. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Surf Rock'**
  String get createGenreSurfRock;

  /// Genre display label in creation, playback, library, and work details for Deep House. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Deep House'**
  String get createGenreDeepHouse;

  /// Genre display label in creation, playback, library, and work details for Minimal Techno. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Minimal Techno'**
  String get createGenreMinimalTechno;

  /// Genre display label in creation, playback, library, and work details for 1960s French Yé-yé Pop. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'1960s French Yé-yé Pop'**
  String get createGenreFrenchYeyePop;

  /// Genre display label in creation, playback, library, and work details for Chillout. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Chillout'**
  String get createGenreChillout;

  /// Genre display label in creation, playback, library, and work details for J-pop Indie Pop. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'J-pop Indie Pop'**
  String get createGenreJPopIndiePop;

  /// Genre display label in creation, playback, library, and work details for Chiptune. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Chiptune'**
  String get createGenreChiptune;

  /// Genre display label in creation, playback, library, and work details for Disco Funk. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Disco Funk'**
  String get createGenreDiscoFunk;

  /// Genre display label in creation, playback, library, and work details for Reggaeton. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Reggaeton'**
  String get createGenreReggaeton;

  /// Genre display label in creation, playback, library, and work details for Cumbia. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Cumbia'**
  String get createGenreCumbia;

  /// Genre display label in creation, playback, library, and work details for Latin Jazz. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Latin Jazz'**
  String get createGenreLatinJazz;

  /// Genre display label in creation, playback, library, and work details for Bhangra. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Bhangra'**
  String get createGenreBhangra;

  /// Genre display label in creation, playback, library, and work details for Indian Classical. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Indian Classical'**
  String get createGenreIndianClassical;

  /// Genre display label in creation, playback, library, and work details for Lo-Fi Hip Hop. The generation request retains its original English genre value.
  ///
  /// In en, this message translates to:
  /// **'Lo-Fi Hip Hop'**
  String get createGenreLofiHipHop;

  /// Account profile. Purpose: profile account id with value.
  ///
  /// In en, this message translates to:
  /// **'Account ID: {id}'**
  String profileAccountIdWithValue(String id);

  /// Account profile. Purpose: profile balance value.
  ///
  /// In en, this message translates to:
  /// **'{balance}'**
  String profileBalanceValue(int balance);

  /// Song playback screen. Purpose: player export file name.
  ///
  /// In en, this message translates to:
  /// **'{brand} – {title} ({occasion})'**
  String playerExportFileName(String brand, String title, String occasion);

  /// Song creation screen. Purpose: create vocals custom summary.
  ///
  /// In en, this message translates to:
  /// **'Custom — based on your prompt'**
  String get createVocalsCustomSummary;

  /// Music-video configuration, progress, playback, or notification. Purpose: mv chip making with progress.
  ///
  /// In en, this message translates to:
  /// **'Making video · {progress}'**
  String mvChipMakingWithProgress(String progress);

  /// Music-video configuration, progress, playback, or notification. Purpose: mv auto failure message.
  ///
  /// In en, this message translates to:
  /// **'The video couldn’t start · {reason}'**
  String mvAutoFailureMessage(String reason);

  /// Settings screen. Purpose: settings video credits summary.
  ///
  /// In en, this message translates to:
  /// **'Video credits: {credits, plural, one{{credits} credit} other{{credits} credits}}'**
  String settingsVideoCreditsSummary(int credits);

  /// Share card, exported attribution, or system share sheet. Purpose: share lyrics attribution.
  ///
  /// In en, this message translates to:
  /// **'— {aiLabel} · {brand}'**
  String shareLyricsAttribution(String aiLabel, String brand);

  /// Create home: the row of inspirations (contract 02 v1.2, ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Inspiration'**
  String get inspirationHeader;

  /// Accessibility label of the play button of an inspiration preview.
  ///
  /// In en, this message translates to:
  /// **'Play {name}'**
  String inspirationPlay(String name);

  /// Accessibility label of the stop button while an inspiration preview plays.
  ///
  /// In en, this message translates to:
  /// **'Stop the preview'**
  String get inspirationStop;

  /// Inspiration names and styles: local copy of the server {en, zh} text for other languages, looked up by the English text (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Soundscape'**
  String get inspirationNameSoundscape;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Ambient textures, no vocals'**
  String get inspirationStyleSoundscape;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Background Music'**
  String get inspirationNameBackgroundMusic;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Light instrumental for videos'**
  String get inspirationStyleBackgroundMusic;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Memorize Something'**
  String get inspirationNameMemorizeSomething;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Catchy mnemonic pop'**
  String get inspirationStyleMemorizeSomething;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Text Messages'**
  String get inspirationNameTextMessages;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Playful pop from your texts'**
  String get inspirationStyleTextMessages;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Intro Music'**
  String get inspirationNameIntroMusic;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Bold cinematic opener'**
  String get inspirationStyleIntroMusic;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Montage'**
  String get inspirationNameMontage;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Uplifting build for highlight reels'**
  String get inspirationStyleMontage;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Say It With a Track'**
  String get inspirationNameSayItWithATrack;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Heartfelt pop ballad'**
  String get inspirationStyleSayItWithATrack;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Brand Jingle'**
  String get inspirationNameBrandJingle;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Short, bright, memorable hook'**
  String get inspirationStyleBrandJingle;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Ringtone'**
  String get inspirationNameRingtone;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'30-second loopable hook'**
  String get inspirationStyleRingtone;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get inspirationNameStreaming;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Energetic electronic stream intro'**
  String get inspirationStyleStreaming;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Speech to Track'**
  String get inspirationNameSpeechToTrack;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Your voice turned into a song'**
  String get inspirationStyleSpeechToTrack;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Rap Battle'**
  String get inspirationNameRapBattle;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Hard-hitting hip-hop'**
  String get inspirationStyleRapBattle;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get inspirationNameComedy;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Quirky, upbeat, tongue-in-cheek'**
  String get inspirationStyleComedy;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Team Anthem'**
  String get inspirationNameTeamAnthem;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Stadium rock chant'**
  String get inspirationStyleTeamAnthem;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Sports Recap'**
  String get inspirationNameSportsRecap;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Epic orchestral highlights'**
  String get inspirationStyleSportsRecap;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Party Invite'**
  String get inspirationNamePartyInvite;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Dance-pop invitation'**
  String get inspirationStylePartyInvite;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Happy Birthday'**
  String get inspirationNameHappyBirthday;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Warm acoustic birthday song'**
  String get inspirationStyleHappyBirthday;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Friend Appreciation'**
  String get inspirationNameFriendAppreciation;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Feel-good indie pop'**
  String get inspirationStyleFriendAppreciation;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Love Story'**
  String get inspirationNameLoveStory;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Romantic R&B ballad'**
  String get inspirationStyleLoveStory;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Birthday Roast'**
  String get inspirationNameBirthdayRoast;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Cheeky comedic birthday tune'**
  String get inspirationStyleBirthdayRoast;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Ode to Your Pet'**
  String get inspirationNameOdeToYourPet;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Cute, bouncy pop'**
  String get inspirationStyleOdeToYourPet;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Hometown Tribute'**
  String get inspirationNameHometownTribute;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Nostalgic folk'**
  String get inspirationStyleHometownTribute;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Weather Report'**
  String get inspirationNameWeatherReport;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Playful lounge groove'**
  String get inspirationStyleWeatherReport;

  /// Inspiration name (server name.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Business Promo'**
  String get inspirationNameBusinessPromo;

  /// Inspiration style (server style.en); shown in languages the server does not send (ADR-0029).
  ///
  /// In en, this message translates to:
  /// **'Confident corporate pop'**
  String get inspirationStyleBusinessPromo;

  /// Style line of the template entry BirthdayWish (server style.en), read with the tile name in languages the server does not send; mapped by slug (ADR-0032).
  ///
  /// In en, this message translates to:
  /// **'Heartfelt song for their special day'**
  String get inspirationStyleBirthdayWish;

  /// Style line of the template entry BirthdayParty (server style.en), read with the tile name in languages the server does not send; mapped by slug (ADR-0032).
  ///
  /// In en, this message translates to:
  /// **'Upbeat party anthem for the birthday star'**
  String get inspirationStyleBirthdayParty;

  /// Style line of the template entry ThankAFriend (server style.en), read with the tile name in languages the server does not send; mapped by slug (ADR-0032).
  ///
  /// In en, this message translates to:
  /// **'Warm, grateful thank-you song'**
  String get inspirationStyleThankAFriend;

  /// Style line of the template entry Wedding (server style.en), read with the tile name in languages the server does not send; mapped by slug (ADR-0032).
  ///
  /// In en, this message translates to:
  /// **'Joyful, romantic song for the big day'**
  String get inspirationStyleWedding;

  /// Style line of the template entry InMemory (server style.en), read with the tile name in languages the server does not send; mapped by slug (ADR-0032).
  ///
  /// In en, this message translates to:
  /// **'Gentle, hopeful tribute'**
  String get inspirationStyleInMemory;

  /// Style line of the template entry Festival (server style.en), read with the tile name in languages the server does not send; mapped by slug (ADR-0032).
  ///
  /// In en, this message translates to:
  /// **'Bright, festive seasonal greeting'**
  String get inspirationStyleFestival;

  /// Style line of the template entry PetAnthem (server style.en), read with the tile name in languages the server does not send; mapped by slug (ADR-0032).
  ///
  /// In en, this message translates to:
  /// **'Affectionate, bouncy theme for a pet'**
  String get inspirationStylePetAnthem;

  /// Style line of the template entry Hometown (server style.en), read with the tile name in languages the server does not send; mapped by slug (ADR-0032).
  ///
  /// In en, this message translates to:
  /// **'Proud, nostalgic hometown anthem'**
  String get inspirationStyleHometown;

  /// Settings section containing interface and default lyrics languages.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// Settings section showing the account: its credits and its account ID.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsSectionProfile;

  /// Settings > Profile: label of the account's credit balance (server truth).
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get settingsCredits;

  /// Settings > Profile: label of the account UUID (shown in full, for support).
  ///
  /// In en, this message translates to:
  /// **'Account ID'**
  String get settingsAccountId;

  /// Settings > Profile: accessibility label / tooltip of the button that copies the account ID.
  ///
  /// In en, this message translates to:
  /// **'Copy account ID'**
  String get settingsCopyAccountId;

  /// Settings section shown only in DEV debug builds (developer tools).
  ///
  /// In en, this message translates to:
  /// **'Developer (DEV only)'**
  String get devSectionTitle;

  /// DEV-only settings row: deletes the app's iOS Keychain keys.
  ///
  /// In en, this message translates to:
  /// **'Delete Keychain keys'**
  String get devKeychainReset;

  /// DEV-only settings row subtitle: what the Keychain reset removes.
  ///
  /// In en, this message translates to:
  /// **'Device ID and session tokens'**
  String get devKeychainResetHint;

  /// DEV-only confirmation dialog title before deleting the Keychain keys.
  ///
  /// In en, this message translates to:
  /// **'Delete Keychain keys?'**
  String get devKeychainResetConfirmTitle;

  /// DEV-only confirmation dialog body: consequences of deleting the Keychain keys.
  ///
  /// In en, this message translates to:
  /// **'The device ID and session tokens are erased from the Keychain. The current guest account can’t be recovered; the app signs in as a new guest.'**
  String get devKeychainResetConfirmBody;

  /// DEV-only message after the Keychain keys were deleted.
  ///
  /// In en, this message translates to:
  /// **'Keychain keys deleted — signed in as a new guest'**
  String get devKeychainResetDone;

  /// Settings row and picker heading for the interface language, distinct from lyrics language.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// Interface-language picker option that follows the system’s preferred supported language.
  ///
  /// In en, this message translates to:
  /// **'Use system language'**
  String get settingsLanguageSystem;

  /// Settings row value when the interface language follows the system.
  ///
  /// In en, this message translates to:
  /// **'System ({language})'**
  String settingsLanguageSystemValue(String language);

  /// This language’s own name (autonym); used to identify it in every interface-language picker, regardless of the current UI language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageNativeName;

  /// Interface-language preference could not be saved; the previous selection remains. Explain the failure and invite retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the language. Try again.'**
  String get settingsLanguageSaveFailed;

  /// Default lyrics-language setting helper. Changing the preference affects new songs, not an existing draft.
  ///
  /// In en, this message translates to:
  /// **'Applies to new songs.'**
  String get settingsLyricsLanguageHint;

  /// Accessibility label of the close button on the picked idea at the head of the composer.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String composerRemoveInspiration(String name);

  /// Placeholder of the create home's prompt field on phones, where the idea grid is above the composer (P01, state A).
  ///
  /// In en, this message translates to:
  /// **'Describe the song, or pick an idea above'**
  String get composerPromptHint;

  /// Placeholder of the create home's prompt field on iPad, where the idea grid is beside the composer (P01, state A).
  ///
  /// In en, this message translates to:
  /// **'Describe the song, or pick an idea'**
  String get composerPromptHintWide;

  /// Label of the field for the user's own text when the picked idea needs it (composer state B); the idea's hint is its placeholder.
  ///
  /// In en, this message translates to:
  /// **'Your words'**
  String get composerWordsLabel;

  /// Accessibility label of the composer's photo button once photos are added.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} photo added} other{{count} photos added}}'**
  String composerPhotosAttached(int count);

  /// Accessibility label of the composer's summary row; it opens the song options.
  ///
  /// In en, this message translates to:
  /// **'Song options: {summary}'**
  String composerOptionsSummary(String summary);

  /// Accessibility hint of the composer's summary row while the song options are folded.
  ///
  /// In en, this message translates to:
  /// **'Show song options'**
  String get composerOptionsShow;

  /// Accessibility hint of the composer's summary row while the song options are shown.
  ///
  /// In en, this message translates to:
  /// **'Hide song options'**
  String get composerOptionsHide;

  /// Composer summary row: the vocals follow the user's description (the Vocals panel's Custom).
  ///
  /// In en, this message translates to:
  /// **'Any vocals'**
  String get composerSummaryAnyVocals;

  /// Composer summary row: no genre chosen, the description decides (the Genre panel's Custom).
  ///
  /// In en, this message translates to:
  /// **'Any genre'**
  String get composerSummaryAnyGenre;

  /// Composer summary row: the user wrote their own lyrics (shown while the options are folded).
  ///
  /// In en, this message translates to:
  /// **'Own lyrics'**
  String get composerSummaryLyrics;

  /// Composer summary row: a lyric video will be made after the full song (shown while the options are folded).
  ///
  /// In en, this message translates to:
  /// **'Lyric video'**
  String get composerSummaryVideo;

  /// The composer's primary button for a 30-second preview; the cost part follows the account's ledger (ADR-0035).
  ///
  /// In en, this message translates to:
  /// **'{cost, select, free{Create preview · free} preview{Create preview · 1 preview} other{Create preview}}'**
  String createPreviewLabel(String cost);

  /// The composer's primary button for a 30-second preview of a picked idea with a name; the cost part follows the account's ledger (ADR-0035).
  ///
  /// In en, this message translates to:
  /// **'{cost, select, free{Create {name}’s preview · free} preview{Create {name}’s preview · 1 preview} other{Create {name}’s preview}}'**
  String createPreviewForLabel(String name, String cost);

  /// The composer's primary button for the full ~2-minute song; the cost part follows the account's ledger (ADR-0035).
  ///
  /// In en, this message translates to:
  /// **'{cost, select, song{Create full song · 1 song} other{Create full song}}'**
  String createFullSongLabel(String cost);

  /// P03a: the dictation's only action — put the transcript in the prompt field (dictation is free input).
  ///
  /// In en, this message translates to:
  /// **'Use this text'**
  String get voiceUseText;

  /// Banner title while an automatic music video counts down before it starts (and is charged); the user can cancel.
  ///
  /// In en, this message translates to:
  /// **'{level} starts in {seconds} s'**
  String mvAutoCountdown(String level, int seconds);

  /// Subscription billing period: price per week, e.g. $4.99/week.
  ///
  /// In en, this message translates to:
  /// **'{price}/week'**
  String planPerWeek(String price);

  /// Plan benefit line for the weekly subscription: credits are renewed every week (no fixed song count, never 'unlimited').
  ///
  /// In en, this message translates to:
  /// **'Fresh credits every week'**
  String get planCreditsWeekly;

  /// Plan card caption for an introductory discount read from the App Store, e.g. 50% off your first week.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off your first {unit, select, day{day} week{week} month{month} year{year} other{period}}'**
  String paywallIntroOffer(int percent, String unit);

  /// Paywall disclosure for a selected subscription with an introductory price: the actual recurring price and period after it, and that cancellation is possible before renewal (App Review 3.1.2).
  ///
  /// In en, this message translates to:
  /// **'After the introductory price of {introPrice}, you’ll be charged {pricePerPeriod} automatically. Cancel anytime before it renews.'**
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod);

  /// App Store preview, script A, 1–4 s, as the name is typed (the muted hook continues). ≤ 28 characters (CJK ≤ 14).
  ///
  /// In en, this message translates to:
  /// **'Start with their name'**
  String get storePreviewAHook;

  /// App Store preview, script A, 4–7.5 s, as three words about the person are typed. ≤ 28 characters (CJK ≤ 14).
  ///
  /// In en, this message translates to:
  /// **'Add three words about them'**
  String get storePreviewAWords;

  /// App Store preview, script A, 7.5–10 s, over the generating page. ≤ 28 characters (CJK ≤ 14).
  ///
  /// In en, this message translates to:
  /// **'Your song is being written'**
  String get storePreviewAWait;

  /// App Store preview, script A, 10.5–18.5 s, over the player on the chorus that sings the name. ≤ 28 characters (CJK ≤ 14).
  ///
  /// In en, this message translates to:
  /// **'Their name in the chorus'**
  String get storePreviewAChorus;

  /// App Store preview (store_preview/songlet), script A, 0–1 s: the claim on the intro card. ≤ 28 characters (CJK ≤ 14). Never shown in the app.
  ///
  /// In en, this message translates to:
  /// **'A song with their name in it'**
  String get storePreviewAEnd;

  /// App Store preview, script B, 1–4 s, as four photos are picked (the muted hook continues). ≤ 28 characters (CJK ≤ 14).
  ///
  /// In en, this message translates to:
  /// **'Start with your photos'**
  String get storePreviewBHook;

  /// App Store preview, script B, 4–8 s, as "also make a lyric video" is switched on. ≤ 28 characters (CJK ≤ 14).
  ///
  /// In en, this message translates to:
  /// **'Add a lyric video'**
  String get storePreviewBVideo;

  /// App Store preview, script B, 8–10 s, over the generating page. ≤ 28 characters (CJK ≤ 14).
  ///
  /// In en, this message translates to:
  /// **'Writing your song'**
  String get storePreviewBWait;

  /// App Store preview, script B, 10.5–17 s, over the lyric video with synced lyrics. ≤ 28 characters (CJK ≤ 14).
  ///
  /// In en, this message translates to:
  /// **'Lyrics in sync, on screen'**
  String get storePreviewBLyrics;

  /// App Store preview (store_preview/songlet), script B, 0–1 s: the claim on the intro card. ≤ 28 characters (CJK ≤ 14). Never shown in the app.
  ///
  /// In en, this message translates to:
  /// **'Your photos set the mood.'**
  String get storePreviewBMood;

  /// App Store preview, script B, 17–19.5 s, over the share sheet. ≤ 28 characters (CJK ≤ 14).
  ///
  /// In en, this message translates to:
  /// **'Share the video.'**
  String get storePreviewBShare;

  /// App Store preview, script B, 19.5–23 s, as the country and lyric language are picked. ≤ 28 characters (CJK ≤ 14).
  ///
  /// In en, this message translates to:
  /// **'Lyrics in your language'**
  String get storePreviewBLanguage;

  /// App Store preview, script A, 18.5–23 s, over the share card: the song goes out as a card. ≤ 28 characters (CJK ≤ 14).
  ///
  /// In en, this message translates to:
  /// **'Send it as a card'**
  String get storePreviewAShare;

  /// App Store preview end card: the call to action under the app name. ≤ 28 characters (CJK ≤ 14). No price, no "free".
  ///
  /// In en, this message translates to:
  /// **'Write your first song'**
  String get storePreviewCta;

  /// App Store preview end card, small print: making songs needs a subscription or credits (Apple requires disclosing in-app purchases). ≤ 60 characters (CJK ≤ 30).
  ///
  /// In en, this message translates to:
  /// **'Requires a subscription or credits'**
  String get storePreviewDisclosure;

  /// App Store product page header (store_preview/songlet/creatives/store-page.yaml): the phrase beside the app on the default product page, image and looping video. One short phrase, ≤ 40 characters (CJK ≤ 20), at most 2 lines as set. No price, no "free", no awards. Never shown in the app.
  ///
  /// In en, this message translates to:
  /// **'Songs for the people you love'**
  String get storeCreativeHeader;

  /// App Store search results asset (creatives/store-page.yaml): what the app does, obvious at a glance; shown muted beside a name being typed and the song it becomes. ≤ 40 characters (CJK ≤ 20). Never shown in the app.
  ///
  /// In en, this message translates to:
  /// **'Turn a name into a song'**
  String get storeCreativeSearch;

  /// Custom product page "Birthday Songs" header and search results asset (creatives/cpp-birthday.yaml). ≤ 40 characters (CJK ≤ 20). Never shown in the app.
  ///
  /// In en, this message translates to:
  /// **'A birthday song with their name'**
  String get storeCreativeBirthday;

  /// Custom product page "Photo to Song" header and search results asset (creatives/cpp-photo.yaml). ≤ 40 characters (CJK ≤ 20). Never shown in the app.
  ///
  /// In en, this message translates to:
  /// **'Your photos become a song'**
  String get storeCreativePhoto;

  /// Custom product page "Wedding Songs" header and search results asset (creatives/cpp-wedding.yaml). ≤ 40 characters (CJK ≤ 20). Never shown in the app.
  ///
  /// In en, this message translates to:
  /// **'A song for your wedding day'**
  String get storeCreativeWedding;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'ja',
    'ko',
    'pt',
    'tr',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
