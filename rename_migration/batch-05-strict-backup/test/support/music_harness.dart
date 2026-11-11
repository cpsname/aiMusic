import 'dart:async';

import 'package:app_config/app_config.dart';
import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:infra_core/infra_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songlet/l10n/generated/app_localizations.dart';
import 'package:songlet/l10n/ui_locale.dart';
import 'package:songlet/ui/common/device_family.dart';
import 'package:songlet/ui/common/messages.dart';
import 'package:songlet/ui/routing/app_router.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// A device of the phase-5 matrix: logical size, pixel ratio and the safe
/// area insets (status bar / Dynamic Island, home indicator).
class TestDevice {
  const TestDevice(
    this.name,
    this.size,
    this.pixelRatio, {
    this.top = 0,
    this.bottom = 0,
    this.side = 0,
  });

  final String name;
  final Size size;
  final double pixelRatio;
  final double top;
  final double bottom;

  /// Landscape side insets (sensor housing).
  final double side;

  TestDevice get landscape => TestDevice(
    '$name-landscape',
    Size(size.height, size.width),
    pixelRatio,
    top: side,
    bottom: bottom == 0 ? 0 : 21,
    side: top,
  );

  /// The same device rendered at [ratio] — layout is decided in logical
  /// points, so review goldens use 1× to stay small.
  TestDevice withPixelRatio(double ratio) =>
      TestDevice(name, size, ratio, top: top, bottom: bottom, side: side);

  /// The prototypes' design canvas (docs/ui, 393×852 pt; ADR-0007).
  static const design = TestDevice(
    'design',
    Size(393, 852),
    2,
    top: 59,
    bottom: 34,
  );
  static const iPhoneSE = TestDevice('iphone-se', Size(375, 667), 2, top: 20);
  static const iPhone17Pro = TestDevice(
    'iphone-17-pro',
    Size(402, 874),
    3,
    top: 62,
    bottom: 34,
  );
  static const iPhone17ProMax = TestDevice(
    'iphone-17-pro-max',
    Size(440, 956),
    3,
    top: 62,
    bottom: 34,
  );
  static const iPadMini = TestDevice(
    'ipad-mini',
    Size(744, 1133),
    2,
    top: 24,
    bottom: 20,
  );
  static const iPadPro13 = TestDevice(
    'ipad-pro-13',
    Size(1032, 1376),
    2,
    top: 24,
    bottom: 20,
  );

  /// Every configuration the adaptive goldens cover. The iPad devices only
  /// while the app ships for iPad ([ipadEnabled], ADR-0037); their goldens
  /// stay in the repo meanwhile.
  static final List<TestDevice> matrix = [
    iPhoneSE,
    iPhone17Pro,
    iPhone17ProMax,
    if (ipadEnabled) ...[iPadMini, iPadPro13, iPadPro13.landscape],
  ];

  /// An iPad configuration (portrait or landscape).
  bool get isIpad => name.startsWith('ipad');

  /// `skip:` for a test that needs this device: iPad tests run only while
  /// the app ships for iPad.
  bool get skipped => isIpad && !ipadEnabled;
}

/// iOS Dynamic Type as Flutter text scale factors (body size ÷ 17 pt, the
/// Large default).
abstract final class TextScale {
  /// Accessibility size AX5: 53 pt body — the largest setting.
  static const double largestAccessibility = 53 / 17;
}

/// Records native playback calls.
class FakeAudioEngine implements AudioEngine {
  final StreamController<double> _progress =
      StreamController<double>.broadcast();
  final List<(String, bool)> plays = [];
  final List<double> seeks = [];

  void emit(double value) => _progress.add(value);

  @override
  Future<void> play(String path, {required bool loop}) async =>
      plays.add((path, loop));

  @override
  Future<void> seek(double seconds) async => seeks.add(seconds);

  @override
  Stream<double> get progress => _progress.stream;
}

class MemoryWorkRepository implements WorkRepository {
  final Map<String, Work> works = {};

  @override
  Future<List<Work>> all() async =>
      works.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<Work?> byId(String id) async => works[id];

  @override
  Future<void> upsert(Work work) async => works[work.id] = work;

  @override
  Future<void> delete(String id) async => works.remove(id);
}

class MemoryAudioStore implements AudioStore {
  /// While set and not completed, reading a path waits (a slow disk read).
  Completer<void>? pathGate;

  @override
  Future<String> download({
    required String url,
    required String workId,
    required String title,
  }) async => '$workId.mp3';

  @override
  Future<String> pathOf(String fileName) async {
    await pathGate?.future;
    return '/audio/$fileName';
  }

  @override
  Future<String> scratchDirectory() async => '/scratch';

  @override
  Future<String> importFile({
    required String sourcePath,
    required String workId,
  }) async => '$workId.mp3';

  @override
  Future<String> fetchToScratch({
    required String url,
    required String fileName,
  }) async => '/scratch/$fileName';

  @override
  Future<void> delete(String fileName) async {}
}

/// Scripted `/v1/generate` + `/v1/jobs` + cancel.
class ScriptedJobs implements GenerationRepository {
  final List<GenerationRequest> submitted = [];
  JobSnapshot snapshot = const JobSnapshot(
    status: JobStatus.queued,
    etaSeconds: 120,
  );
  final List<String> cancelled = [];

  /// Thrown by the next submit (a server refusal), once.
  Object? submitError;

  @override
  Future<GenerationTicket> submit(GenerationRequest request) async {
    submitted.add(request);
    final error = submitError;
    submitError = null;
    if (error != null) throw error;
    return const GenerationTicket(
      jobId: 'job-1',
      etaSeconds: 45,
      creditsCharged: 1,
    );
  }

  @override
  Future<JobSnapshot> job(String jobId) async => snapshot;

  @override
  Future<CancelOutcome> cancel(String jobId) async {
    cancelled.add(jobId);
    return CancelOutcome(refunded: snapshot.status == JobStatus.queued);
  }
}

class SilentSpeech implements SpeechGateway {
  SpeechAvailability availabilityResult = SpeechAvailability.available;
  StreamController<SpeechEvent>? session;

  @override
  Future<SpeechAvailability> availability(String locale) async =>
      availabilityResult;

  @override
  Stream<SpeechEvent> start(String locale) =>
      (session = StreamController<SpeechEvent>()).stream;

  @override
  Future<void> stop() async {
    session?.add(const SpeechFinal("It's Alex's thirtieth birthday"));
    await session?.close();
  }

  @override
  Future<void> cancel() async => session?.close();
}

class OfflineCloud implements CloudSyncGateway {
  CloudAccount status = CloudAccount.noAccount;

  @override
  Future<CloudAccount> account() async => status;

  @override
  Future<void> push(Work work, {String? audioPath}) async {}

  @override
  Future<void> remove(String workId) async {}

  @override
  Future<List<CloudWorkChange>> pull({DateTime? since}) async => const [];
}

class NoSamples implements TemplateSampleSource {
  final List<String> requested = [];

  @override
  Future<String> samplePath(String templateId) async {
    requested.add(templateId);
    return '/samples/$templateId.mp3';
  }
}

/// A server whose sample files are missing (the clip answers 404).
class MissingSamples implements TemplateSampleSource {
  final List<String> requested = [];

  @override
  Future<String> samplePath(String templateId) async {
    requested.add(templateId);
    throw StateError('404 $templateId.mp3');
  }
}

/// The server's single list (contract 02 v2.1): a sample of the product
/// repo's entries in `sort` order — template entries named by their template
/// id, scenes with and without a composer block or cover.
List<Inspiration> sampleInspirations() {
  Inspiration make(
    int sort,
    String slug,
    String en,
    String zh,
    String styleEn,
    String styleZh, {
    int? seconds,
    String? cover,
    InspirationComposer? composer,
    String? occasion,
    String? model,
    String? vocals,
    String? genre,
    bool? recipient,
  }) => Inspiration(
    id: 'id-$slug',
    slug: slug,
    name: LocalizedText(en: en, zh: zh),
    style: LocalizedText(en: styleEn, zh: styleZh),
    previewAudioUrl: 'https://cdn.songlet.example/inspirations/$slug.mp3',
    sort: sort,
    durationSec: seconds,
    coverImageUrl: cover,
    occasionWire: occasion,
    defaultModelWire: model,
    defaultVocalsWire: vocals,
    suggestedGenre: genre,
    composer: composer,
    requiresRecipient: recipient,
  );
  return [
    make(
      1,
      'birthday_wish',
      'Birthday Wish',
      '生日祝福',
      'Heartfelt song for their special day',
      '为 TA 的特别日子写的走心歌',
      seconds: 31,
      composer: const InspirationComposer(
        hint: LocalizedText(en: "Who's the birthday star?", zh: '寿星是谁？'),
        inputRequired: false,
      ),
      occasion: 'birthday',
      model: 'lyria-3.5',
      recipient: true,
    ),
    make(
      3,
      'love_story',
      'Love Story',
      '爱情故事',
      'Romantic R&B ballad',
      '浪漫 R&B 抒情',
      seconds: 31,
      composer: const InspirationComposer(
        hint: LocalizedText(en: 'How did you meet?', zh: '你们怎么相遇的？'),
        inputRequired: false,
      ),
      occasion: 'anniversary',
      model: 'lyria-3.5',
      recipient: true,
    ),
    make(
      8,
      'festival',
      'Festival',
      '节日',
      'Bright, festive seasonal greeting',
      '明亮喜庆的节日祝福',
      seconds: 31,
      composer: const InspirationComposer(
        hint: LocalizedText(en: 'Which festival?', zh: '哪个节日？'),
        inputRequired: false,
      ),
      occasion: 'festival',
      model: 'lyria-3.5',
      recipient: false,
    ),
    make(
      10,
      'team_anthem',
      'Team Anthem',
      '队歌',
      'Stadium rock chant',
      '体育场摇滚合唱',
      seconds: 31,
      composer: const InspirationComposer(
        hint: LocalizedText(
          en: 'Name your team and what it stands for',
          zh: '写下队名和队魂',
        ),
        inputRequired: true,
      ),
      occasion: 'brand',
      model: 'lyria-3.5',
      genre: 'Rock',
      recipient: false,
      cover: 'https://cdn.songlet.example/covers/team_anthem.jpg',
    ),
    make(
      17,
      'soundscape',
      'Soundscape',
      '环境音景',
      'Ambient textures, no vocals',
      '氛围音色，纯音乐',
      seconds: 21,
      composer: const InspirationComposer(
        hint: LocalizedText(
          en: 'Describe the mood, or just create',
          zh: '描述氛围，或直接生成',
        ),
        inputRequired: false,
      ),
      occasion: 'soundtrack',
      model: 'lyria-3-clip-preview',
      vocals: 'instrumental',
      genre: 'Ambient',
      recipient: false,
    ),
    make(
      18,
      'background_music',
      'Background Music',
      '背景音乐',
      'Light instrumental for videos',
      '轻快纯音乐配乐',
      seconds: 15,
      composer: const InspirationComposer(
        hint: LocalizedText(en: 'What is the video about?', zh: '视频讲什么？'),
        inputRequired: true,
      ),
      occasion: 'soundtrack',
      recipient: false,
    ),
    make(
      23,
      'say_it_with_a_track',
      'Say It With a Track',
      '用歌说话',
      'Heartfelt pop ballad',
      '深情流行抒情',
      seconds: 24,
      occasion: 'confession',
      recipient: true,
      cover: 'https://cdn.songlet.example/covers/say_it_with_a_track.jpg',
    ),
    make(
      32,
      'weather_report',
      'Weather Report',
      '天气报告',
      'Playful lounge groove',
      '轻松俏皮的沙发律动',
      occasion: 'custom',
      recipient: false,
    ),
  ];
}

class FixedInspirations implements InspirationSource {
  FixedInspirations(this.items);

  List<Inspiration> items;
  final List<String> previews = [];

  /// Previews that cannot be fetched (the file answers 404).
  bool failing = false;

  @override
  Future<List<Inspiration>> inspirations() async => items;

  @override
  Future<String> previewPath(Inspiration inspiration) async {
    previews.add(inspiration.previewAudioUrl);
    if (failing) throw StateError('404 ${inspiration.slug}.mp3');
    return '/inspirations/${inspiration.slug}.mp3';
  }
}

class RecordingSaver implements VideoSaver {
  final List<String> saved = [];

  @override
  Future<bool> saveVideo(String path) async {
    saved.add(path);
    return true;
  }
}

/// A 2×2 PNG used for picked photos.
final Uint8List testPhoto = Uint8List.fromList(const [
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  2,
  0,
  0,
  0,
  2,
  8,
  2,
  0,
  0,
  0, //
  253,
  212,
  154,
  115,
  0,
  0,
  0,
  16,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  216,
  154,
  234,
  5,
  68,
  12,
  16,
  10,
  0, //
  40,
  170,
  5,
  145,
  22,
  210,
  1,
  219,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);

class FixedPhotos implements PhotoSource {
  @override
  Future<List<Uint8List>> pickPhotos(int max) async => [testPhoto, testPhoto];
}

/// Network-free app environment for page, golden and flow tests.
class SongletTestEnv {
  final audio = FakeAudioEngine();
  final works = MemoryWorkRepository();
  final audioStore = MemoryAudioStore();
  final jobs = ScriptedJobs();
  final mvs = ScriptedMvs();
  final videos = MemoryMusicVideoRepository();
  final speech = SilentSpeech();
  final cloud = OfflineCloud();
  final saver = RecordingSaver();
  final notifications = RecordingNotifications();

  /// The create home's inspirations (empty = an older server).
  final inspirations = FixedInspirations(sampleInspirations());

  /// The template sample clips (swap in [MissingSamples] for a server that
  /// advertises files it does not have).
  TemplateSampleSource samples = NoSamples();
  late final runner = ManualMvRunner(
    mvs: mvs,
    videos: MemoryVideoStore(),
    library: videos,
  );
  MusicEntitlement entitlement = const MusicEntitlement(
    tier: MusicTier.free,
    songsLeft: 0,
    clipsLeft: 3,
  );
  List<StoreProduct> products = songletProducts();

  /// Remote config (`/v1/app/config` `config`); empty = every switch at its
  /// production default.
  Map<String, Object?> remoteConfig = const {};

  /// Seeds a finished work in the library.
  Work addWork(Work work) {
    works.works[work.id] = work;
    return work;
  }

  /// Seeds a music video in the library.
  MusicVideo addVideo(MusicVideo video) {
    videos.videos[video.id] = video;
    return video;
  }

  Map<String, Object> preferences = {};
  SharedPreferences? preferencesInstance;
  Future<SharedPreferences>? preferencesFuture;

  Future<List<Override>> overrides() async {
    SharedPreferences.setMockInitialValues(preferences);
    final prefs = preferencesInstance ?? await SharedPreferences.getInstance();
    return [
      sharedPreferencesProvider.overrideWith(
        (ref) async => preferencesFuture ?? prefs,
      ),
      keyValueStoreProvider.overrideWithValue(KeyValueStore(prefs)),
      appConfigProvider.overrideWith(
        () => _FixedAppConfig(
          AppConfig(
            maintenance: Maintenance.inactive,
            killSwitches: const [],
            config: remoteConfig,
          ),
        ),
      ),
      musicEntitlementProvider.overrideWith((ref) async => entitlement),
      storefrontProvider.overrideWith(_FixedStorefront.new),
      deviceRegionProvider.overrideWithValue('US'),
      audioEngineProvider.overrideWithValue(audio),
      workRepositoryProvider.overrideWithValue(works),
      audioStoreProvider.overrideWithValue(audioStore),
      generationRepositoryProvider.overrideWithValue(jobs),
      mvRepositoryProvider.overrideWithValue(mvs),
      musicVideoRepositoryProvider.overrideWithValue(videos),
      videoStoreProvider.overrideWithValue(MemoryVideoStore()),
      mvRunnerProvider.overrideWithValue(runner),
      authControllerProvider.overrideWith(SignedInAuth.new),
      localNotificationsProvider.overrideWithValue(notifications),
      speechGatewayProvider.overrideWithValue(speech),
      cloudSyncGatewayProvider.overrideWithValue(cloud),
      templateSampleSourceProvider.overrideWithValue(samples),
      inspirationSourceProvider.overrideWithValue(inspirations),
      videoSaverProvider.overrideWithValue(saver),
      photoSourceProvider.overrideWithValue(FixedPhotos()),
      promptPolisherProvider.overrideWithValue(_EchoPolisher()),
      storeProductsProvider.overrideWith((ref) => products),
      subscriptionEntitlementProvider.overrideWithValue(
        SubscriptionEntitlement.none,
      ),
      deviceInfoServiceProvider.overrideWithValue(
        DeviceInfoService(
          tokenStore: SecureTokenStore.withDefaults(),
          platformDetailsProbe: () async =>
              (platform: 'ios', osVersion: '26.0', model: 'iPhone'),
          packageInfoProbe: () async => PackageInfo(
            appName: 'Songlet',
            packageName: 'com.songlet.ios',
            version: '1.0.0',
            buildNumber: '1',
          ),
        ),
      ),
      deviceProfileProvider.overrideWith(
        (ref) async => const DeviceProfile(
          deviceId: 'device-1',
          platform: 'ios',
          osVersion: '26.0',
          deviceModel: 'iPhone',
          appVersion: '1.0.0',
          appBuild: '1',
        ),
      ),
    ];
  }
}

/// The Songlet catalogue as the store would return it (USD, the Pro yearly
/// 7-day free trial).
List<StoreProduct> songletProducts() {
  const prices = {
    MusicCatalog.proWeekly: (r'$4.99', 4.99),
    MusicCatalog.proYearly: (r'$59.99', 59.99),
    MusicCatalog.proMonthly: (r'$9.99', 9.99),
    MusicCatalog.premierMonthly: (r'$24.99', 24.99),
    MusicCatalog.pack10: (r'$4.99', 4.99),
    MusicCatalog.pack50: (r'$19.99', 19.99),
    MusicCatalog.mvChorusPack: (r'$14.99', 14.99),
    MusicCatalog.mvFullPack: (r'$79.99', 79.99),
  };
  return [
    for (final product in MusicCatalog.products())
      StoreProduct(
        product: product,
        details: StoreProductDetails(
          id: product.storeProductId,
          title: product.productName,
          description: product.productName,
          price: prices[product.storeProductId]!.$1,
          rawPrice: prices[product.storeProductId]!.$2,
          currencyCode: 'USD',
          subscriptionPeriod: switch (product.billingCycle) {
            'annual' => const SubscriptionPeriodValue(
              numberOfUnits: 1,
              unit: PeriodUnit.year,
            ),
            'monthly' => const SubscriptionPeriodValue(
              numberOfUnits: 1,
              unit: PeriodUnit.month,
            ),
            'weekly' => const SubscriptionPeriodValue(
              numberOfUnits: 1,
              unit: PeriodUnit.week,
            ),
            _ => null,
          },
          introductoryOffer: switch (product.storeProductId) {
            MusicCatalog.proYearly => const ProductOffer(
              type: OfferType.introductory,
              paymentMode: OfferPaymentMode.freeTrial,
              formattedPrice: '',
              rawPrice: 0,
              currencyCode: 'USD',
              numberOfPeriods: 1,
              period: SubscriptionPeriodValue(
                numberOfUnits: 7,
                unit: PeriodUnit.day,
              ),
            ),
            // The App Store's first-week discount on Weekly Pro (50 % off).
            MusicCatalog.proWeekly => const ProductOffer(
              type: OfferType.introductory,
              paymentMode: OfferPaymentMode.payAsYouGo,
              formattedPrice: r'$2.49',
              rawPrice: 2.49,
              currencyCode: 'USD',
              numberOfPeriods: 1,
              period: SubscriptionPeriodValue(
                numberOfUnits: 1,
                unit: PeriodUnit.week,
              ),
            ),
            _ => null,
          },
        ),
      ),
  ];
}

class _EchoPolisher implements PromptPolisher {
  @override
  Future<String> polish(String raw, String locale) async => raw;
}

class _FixedStorefront extends StorefrontController {
  @override
  String? build() => 'USA';
}

class _FixedAppConfig extends AppConfigController {
  _FixedAppConfig(this._value);

  final AppConfig _value;

  @override
  AppConfig build() => _value;

  @override
  Future<void> refresh({bool force = false}) async {}
}

/// The software keyboard's height (logical pt) on a screen of [size], as iOS
/// reports it with the predictive bar: shorter on an SE-class phone, taller on
/// an iPad (wider still in landscape).
double keyboardHeightFor(Size size) {
  if (size.shortestSide >= 700) return size.width > size.height ? 398 : 313;
  return size.height < 700 ? 260 : 336;
}

/// Shows the software keyboard: the bottom view inset iOS reports for it
/// (cleared with the view by [pumpRoute]'s teardown).
Future<void> showKeyboard(WidgetTester tester) async {
  final ratio = tester.view.devicePixelRatio;
  final size = tester.view.physicalSize / ratio;
  tester.view.viewInsets = FakeViewPadding(
    bottom: keyboardHeightFor(size) * ratio,
  );
  await tester.pump();
}

/// Pumps the real route table at [location] on [device], without the startup
/// gate (the environment is ready by construction). Returns the container.
Future<ProviderContainer> pumpRoute(
  WidgetTester tester,
  String location, {
  SongletTestEnv? env,
  TestDevice device = TestDevice.iPhone17Pro,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  bool dynamicLocale = false,
  List<String> fontFamilyFallback = const [],
  TextDirection? textDirection,
  double textScale = 1,
  List<Override> overrides = const [],
}) async {
  final environment = env ?? SongletTestEnv();
  tester.view
    ..physicalSize = device.size * device.pixelRatio
    ..devicePixelRatio = device.pixelRatio
    ..padding = FakeViewPadding(
      top: device.top * device.pixelRatio,
      bottom: device.bottom * device.pixelRatio,
      left: device.side * device.pixelRatio,
      right: device.side * device.pixelRatio,
    );
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = buildAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  final scope = ProviderScope(
    retry: (_, _) => null,
    overrides: [
      ...await environment.overrides(),
      if (dynamicLocale)
        languageTagProvider.overrideWith(
          (ref) => ref.watch(uiLocaleProvider).toLanguageTag(),
        ),
      ...overrides,
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final effectiveLocale = dynamicLocale
            ? ref.watch(uiLocaleProvider)
            : locale;
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme:
              effectiveLocale.languageCode == 'hi' ||
                  fontFamilyFallback.isNotEmpty
              ? AuraTheme.warm.copyWith(
                  textTheme: AuraTheme.warm.textTheme.apply(
                    fontFamilyFallback: [
                      'Kohinoor Devanagari',
                      ...fontFamilyFallback,
                    ],
                  ),
                )
              : AuraTheme.warm,
          darkTheme: AuraTheme.warmDark,
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: effectiveLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MessageHost(
            controller: ref.watch(messageControllerProvider),
            child: MotionPolicyOverride(
              reduceMotion: true,
              child: textDirection == null
                  ? child!
                  : Directionality(textDirection: textDirection, child: child!),
            ),
          ),
        );
      },
    ),
  );
  await tester.pumpWidget(scope);
  await settleFrames(tester);
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

/// Pumps a few frames, letting async providers, asset images and route
/// transitions complete — never `pumpAndSettle` (perpetual animations).
Future<void> settleFrames(WidgetTester tester, {int frames = 6}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pump(const Duration(milliseconds: 100));
}

/// A finished clip with lyrics and a structure, for player / library tests.
Work sampleClip({
  String id = 'clip-1',
  SongTemplate? template = SongTemplate.birthdayWish,
  SongModel model = SongModel.clip,
}) => Work(
  id: id,
  jobId: 'job-$id',
  model: model,
  status: WorkStatus.ready,
  occasion: template?.occasion ?? Occasion.custom,
  template: template,
  region: 'US',
  genre: 'Indie Pop',
  lyricLanguage: 'en',
  recipient: 'Alex',
  keywords: const ['coffee', 'hiking', 'Sunday'],
  lyrics:
      '[Verse]\nHappy birthday, Alex\nHere\'s a little song for you\n\n[Chorus]\nMay your days be brighter\nAnd your dreams come true',
  structure: model == SongModel.clip
      ? const [
          LyricSection(label: 'Verse', start: 0, end: 12),
          LyricSection(label: 'Chorus', start: 12, end: 30),
        ]
      : const [
          LyricSection(label: 'Intro', start: 0, end: 10),
          LyricSection(label: 'Verse', start: 10, end: 45),
          LyricSection(label: 'Chorus', start: 45, end: 80),
          LyricSection(label: 'Bridge', start: 80, end: 105),
          LyricSection(label: 'Outro', start: 105, end: 127),
        ],
  audioFile: '$id.mp3',
  createdAt: DateTime.utc(2026, 9, 24, 9),
);

/// Silences platform channels the pages may touch in tests.
void mockNativeChannels() {
  VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in [
    'songlet/share_card',
    'songlet/playback',
    'songlet/speech',
    'songlet/cloud_sync',
    'songlet/notifications',
    'songlet/notifications/events',
    'plugins.it_nomads.com/flutter_secure_storage',
  ]) {
    messenger.setMockMethodCallHandler(
      MethodChannel(name),
      (call) async => null,
    );
  }
}

/// A generation controller frozen in [fixed] (no network, no timers).
class FixedGeneration extends GenerationController {
  FixedGeneration(this.fixed);

  final GenerationState fixed;

  @override
  GenerationState build() => fixed;
}

/// Export with a canned license (P11) and recorded saves.
class FakeExportService implements ExportService {
  FakeExportService({this.locked = false, this.wavRendered = true});

  final bool locked;

  /// The job has a WAV render; false = `saveFile(wav)` answers DOWNLOAD_LOCKED
  /// like `ExportService` does when the job carries no `wav_url`.
  final bool wavRendered;
  final List<ExportFile> saved = [];

  @override
  Future<LicenseDocument> license(Work work) async {
    if (locked) throw MusicErrorCode.downloadLocked.toApiError();
    return LicenseDocument(
      pdf: Uint8List(1),
      id: 'SL-20260924-7F3A9C',
      issuedAt: DateTime.utc(2026, 9, 24),
    );
  }

  @override
  Future<ExportOutcome> export(Work work, {required String folderName}) async =>
      ExportOutcome.saved;

  @override
  Future<ExportOutcome> saveFile(
    Work work,
    ExportFile file, {
    required String name,
  }) async {
    if (file == ExportFile.wav && !wavRendered)
      throw MusicErrorCode.downloadLocked.toApiError();
    saved.add(file);
    return ExportOutcome.saved;
  }

  @override
  Future<String> shareableAudio(Work work) async => '/audio/${work.id}.mp3';
}

/// A waiting generation as the P05 / P06 pages see it.
GenerationWaiting waitingGeneration({bool queued = false}) => GenerationWaiting(
  model: SongModel.clip,
  workId: 'clip-1',
  jobId: 'job-1',
  etaSeconds: 45,
  startedAt: DateTime.now(),
  status: queued ? JobStatus.queued : JobStatus.running,
  progress: 0.6,
  remainingSeconds: queued ? 120 : 20,
  lyricsPreview: const [
    "Here's to you, Alex",
    'Brighter days ahead',
    'Same kind heart',
    'Different adventures',
  ],
);

/// Records `generate` / `cancel` instead of running the pipeline, and lets a
/// test move the state along.
class RecordingGeneration extends GenerationController {
  RecordingGeneration([this.initial = const GenerationIdle()]);

  final GenerationState initial;
  final List<(CreationDraft, SongModel?)> generated = [];
  bool refundOnCancel = true;
  var cancels = 0;

  @override
  GenerationState build() => initial;

  @override
  Future<void> generate(
    CreationDraft draft, {
    SongModel? model,
    String? parentId,
  }) async {
    generated.add((draft, model));
    state = GenerationPreparing(model ?? draft.model, PreparingStep.submitting);
  }

  /// The server finished the job before the cancel arrived: `cancel` then
  /// answers JOB_ALREADY_FINISHED and the generation keeps its state.
  bool finishedBeforeCancel = false;

  @override
  Future<bool?> cancel() async {
    cancels++;
    if (finishedBeforeCancel)
      throw MusicErrorCode.jobAlreadyFinished.toApiError();
    state = const GenerationIdle();
    return refundOnCancel;
  }

  set current(GenerationState next) => state = next;
}

/// The current router location.
String currentLocation(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Navigator).first),
).state.uri.toString();

/// Scrolls the page's main list until [finder] is built and on screen.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
}

// ── Music videos (PRD ch.15) ────────────────────────────────────────────────

/// Scripted `/v1/mv/*`: estimate, create, poll, cancel.
class ScriptedMvs implements MvRepository {
  /// What the lyric video costs (credits).
  static const int lyricCredits = 57;

  MvEstimate estimateResult = const MvEstimate(
    level: MvLevel.chorus,
    credits: 2169,
    availableCredits: 3000,
    affordable: true,
    gapCredits: 0,
    songLocked: true,
  );
  Object? estimateError;
  MvTicket ticket = const MvTicket(
    mvId: 'mv-1',
    etaSeconds: 600,
    creditsCharged: 2169,
  );
  Object? createError;
  MvSnapshot snapshot = const MvSnapshot(
    status: JobStatus.queued,
    stage: 'queued',
    progress: 0.02,
    etaSeconds: 600,
  );
  MvCancelOutcome cancelOutcome = const MvCancelOutcome(
    mvId: 'mv-1',
    result: MvCancelResult.cancelled,
    refunded: true,
  );
  final List<(String, MvLevel)> estimated = [];
  final List<(String, MvRequest)> created = [];
  final List<String> cancelled = [];

  @override
  Future<MvEstimate> estimate(String jobId, MvLevel level) async {
    estimated.add((jobId, level));
    final error = estimateError;
    if (error != null) throw error;
    // The lyric video costs credits too (57, contract 02 v2.1).
    final lyric = level == MvLevel.lyricVideo;
    final affordable = lyric
        ? estimateResult.availableCredits >= lyricCredits
        : estimateResult.affordable;
    return MvEstimate(
      level: level,
      credits: lyric ? lyricCredits : estimateResult.credits,
      availableCredits: estimateResult.availableCredits,
      affordable: affordable,
      gapCredits: lyric
          ? (lyricCredits - estimateResult.availableCredits).clamp(
              0,
              lyricCredits,
            )
          : estimateResult.gapCredits,
      recommendedProductId: lyric && affordable
          ? null
          : estimateResult.recommendedProductId,
      offer: estimateResult.offer,
      songLocked: estimateResult.songLocked,
    );
  }

  @override
  Future<MvTicket> create(String jobId, MvRequest request) async {
    created.add((jobId, request));
    final error = createError;
    if (error != null) throw error;
    return ticket;
  }

  @override
  Future<MvSnapshot> mv(String mvId) async => snapshot;

  @override
  Future<MvCancelOutcome> cancel(String mvId) async {
    cancelled.add(mvId);
    return cancelOutcome;
  }
}

class MemoryMusicVideoRepository implements MusicVideoRepository {
  final Map<String, MusicVideo> videos = {};

  @override
  Future<List<MusicVideo>> all() async =>
      videos.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<MusicVideo>> byWork(String workId) async =>
      (await all()).where((v) => v.workId == workId).toList();

  @override
  Future<MusicVideo?> byId(String id) async => videos[id];

  @override
  Future<void> upsert(MusicVideo video) async => videos[video.id] = video;

  @override
  Future<void> delete(String id) async => videos.remove(id);
}

class MemoryVideoStore implements VideoStore {
  @override
  Future<String> download({
    required String url,
    required String videoId,
  }) async => '$videoId.mp4';

  @override
  Future<String> pathOf(String fileName) async => '/video/$fileName';

  @override
  Future<void> delete(String fileName) async {}
}

/// A chorus video of [workId] (P26), ready by default.
MusicVideo sampleVideo({
  String id = 'video-1',
  String workId = 'song-1',
  MvLevel level = MvLevel.chorus,
  WorkStatus status = WorkStatus.ready,
  String? errorCode,
  int photoCount = 0,
  MvChorusWindow? chorus,
  MvAspectRatio aspectRatio = MvAspectRatio.portrait,
  MvSource source = MvSource.library,
  int creditsCharged = 2169,
}) => MusicVideo(
  id: id,
  workId: workId,
  mvId: 'mv-$id',
  level: level,
  status: status,
  videoFile: status == WorkStatus.ready ? '$id.mp4' : null,
  errorCode: status == WorkStatus.failed
      ? (errorCode ?? 'MV_RENDER_FAILED')
      : null,
  durationMs: 30000,
  creditsCharged: creditsCharged,
  createdAt: DateTime.utc(2026, 9, 28, 10),
  photoCount: photoCount,
  chorus: chorus,
  aspectRatio: aspectRatio,
  source: source,
);

/// A video being rendered: scene 1 of 3 done (P20).
MvWaiting waitingMv({bool queued = false, bool cancelRequested = false}) =>
    MvWaiting(
      workId: 'song-1',
      videoId: 'video-1',
      mvId: 'mv-1',
      level: MvLevel.chorus,
      etaSeconds: 600,
      startedAt: DateTime.now(),
      status: queued ? JobStatus.queued : JobStatus.running,
      stage: queued ? 'queued' : 'rendering',
      progress: queued ? null : 0.661,
      segmentsDone: queued ? null : 1,
      segmentsTotal: queued ? null : 3,
      remainingSeconds: queued ? 600 : 420,
      cancelRequested: cancelRequested,
    );

/// A music-video controller frozen in [fixed] (no network, no timers).
class FixedMv extends MvController {
  FixedMv(this.fixed);

  final MvState fixed;

  @override
  MvState build() => fixed;

  @override
  void reset() {}

  @override
  Future<void> estimate(Work work, MvLevel level) async {}

  @override
  Future<void> estimateAll(
    Work work, {
    MvLevel selected = MvLevel.chorus,
    List<MvLevel> levels = MvLevel.values,
  }) async {}
}

/// Records `estimate` / `create` / `cancel` and lets a test push states.
class RecordingMv extends MvController {
  RecordingMv([this.initial = const MvIdle()]);

  final MvState initial;
  final List<(Work, MvLevel)> estimates = [];
  final List<(Work, MvRequest, int)> creates = [];
  var cancels = 0;
  var retries = 0;
  var intentRetries = 0;
  MvCancelOutcome cancelOutcome = const MvCancelOutcome(
    mvId: 'mv-1',
    result: MvCancelResult.cancelled,
    refunded: true,
  );
  Object? cancelError;

  @override
  MvState build() => initial;

  set current(MvState value) => state = value;

  @override
  Future<void> estimate(Work work, MvLevel level) async {
    estimates.add((work, level));
    final known = switch (state) {
      MvEstimated(:final estimates) => estimates,
      _ => const <MvLevel, MvEstimate>{},
    };
    state = MvEstimated(
      workId: work.id,
      level: level,
      estimates: {...known, level: _priced(level)},
    );
  }

  @override
  Future<void> estimateAll(
    Work work, {
    MvLevel selected = MvLevel.chorus,
    List<MvLevel> levels = MvLevel.values,
  }) async {
    for (final level in levels) {
      estimates.add((work, level));
    }
    state = MvEstimated(
      workId: work.id,
      level: selected,
      estimates: {for (final level in levels) level: _priced(level)},
    );
  }

  static MvEstimate _priced(MvLevel level) => MvEstimate(
    level: level,
    credits: level == MvLevel.lyricVideo ? ScriptedMvs.lyricCredits : 2169,
    availableCredits: 3000,
    affordable: true,
    gapCredits: 0,
    songLocked: true,
  );

  @override
  Future<void> retryIntent(Work work, {List<Duration>? attemptDelays}) async =>
      intentRetries++;

  @override
  Future<void> discardIntent() async => state = const MvIdle();

  @override
  Future<void> create(
    Work work,
    MvRequest request, {
    List<List<int>> photos = const [],
    List<Duration> attemptDelays = const [Duration.zero],
  }) async {
    creates.add((work, request, photos.length));
    state = MvWaiting(
      workId: work.id,
      videoId: request.clientRef,
      mvId: 'mv-1',
      level: request.level,
      etaSeconds: 600,
      startedAt: DateTime.now(),
    );
  }

  @override
  Future<void> retry(Work work) async => retries++;

  @override
  Future<MvCancelOutcome?> cancel() async {
    cancels++;
    final error = cancelError;
    if (error != null) throw error;
    if (cancelOutcome.result == MvCancelResult.cancelled) {
      state = const MvIdle();
    } else if (state case final MvWaiting waiting) {
      state = waiting.copyWith(cancelRequested: true);
    }
    return cancelOutcome;
  }
}

/// video_player without a platform: `initialize()` reports a 9:16, 30 s
/// video at once; play / pause / seek flip the value the page renders from.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _events = {};
  final List<String> calls = [];
  int _next = 1;

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async => _create();

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async =>
      _create();

  int _create() {
    final id = _next++;
    late final StreamController<VideoEvent> controller;
    // The controller subscribes after `create` returns; a broadcast stream
    // drops earlier events, so the initialised event waits for the listener.
    controller = StreamController<VideoEvent>.broadcast(
      onListen: () => controller.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 30),
          size: const Size(720, 1280),
        ),
      ),
    );
    _events[id] = controller;
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async => _events.remove(playerId)?.close();

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {
    calls.add('play');
    _events[playerId]?.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: true,
      ),
    );
  }

  @override
  Future<void> pause(int playerId) async {
    calls.add('pause');
    _events[playerId]?.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: false,
      ),
    );
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async =>
      calls.add('seek ${position.inMilliseconds}');

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildView(int playerId) => const ColoredBox(color: Color(0xFF202020));

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      buildView(options.playerId);

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
}

/// [MvRunner] without timers (page tests): a run stays open until the test
/// ends it; snapshots are pushed by the test.
class ManualMvRunner extends MvRunner {
  ManualMvRunner({
    required super.mvs,
    required super.videos,
    required super.library,
  });

  final Map<String, Completer<MusicVideo>> runs = {};
  final Map<String, MvSnapshot> _snapshots = {};
  final _bus = StreamController<(String, MvSnapshot)>.broadcast(sync: true);
  final List<String> abandoned = [];

  @override
  Future<MusicVideo> run(
    MusicVideo video, {
    required int etaSeconds,
    void Function(MvSnapshot snapshot)? onSnapshot,
    bool Function()? isCancelled,
  }) => (runs[video.id] = Completer<MusicVideo>()).future;

  @override
  bool isRunning(String videoId) => runs[videoId]?.isCompleted == false;

  @override
  MvSnapshot? latest(String videoId) => _snapshots[videoId];

  @override
  Stream<MvSnapshot> snapshots(String videoId) =>
      _bus.stream.where((e) => e.$1 == videoId).map((e) => e.$2);

  @override
  void abandon(String videoId) => abandoned.add(videoId);

  @override
  Future<void> dispose() => _bus.close();

  /// A poll answered [snapshot] for [videoId].
  void push(String videoId, MvSnapshot snapshot) {
    _snapshots[videoId] = snapshot;
    _bus.add((videoId, snapshot));
  }
}

/// Local notifications that only record (ADR-0025).
class RecordingNotifications implements LocalNotifications {
  final List<LocalNotification> scheduled = [];
  final List<String> cancelled = [];

  /// Taps on notifications, pushed by the test.
  final taps = StreamController<String>.broadcast();

  @override
  Future<bool> requestAuthorization() async => true;

  @override
  Future<void> schedule(LocalNotification notification) async =>
      scheduled.add(notification);

  @override
  Future<void> cancel(String id) async => cancelled.add(id);

  @override
  Stream<String> get opened => taps.stream;
}

/// The purchase orchestrator answering every purchase with [outcome]
/// (P22 / P08 tests): no StoreKit, no orders.
class ScriptedPurchase extends IapPurchaseOrchestrator {
  ScriptedPurchase(this.outcome);

  /// The state a purchase of a product code ends in.
  final IapPurchaseState Function(String productCode) outcome;
  final List<String> bought = [];

  @override
  IapPurchaseState build() => const IapIdle();

  @override
  Future<void> purchase(StoreProduct product) async {
    bought.add(product.productCode);
    state = IapCreatingOrder(product.productCode);
    state = outcome(product.productCode);
  }
}

/// The automatic-video coordinator frozen with [tasks] (P23 tests).
class FixedAutoVideo extends AutoVideoCoordinator {
  FixedAutoVideo(this.tasks);

  final Map<String, AutoVideoTask> tasks;
  final List<String> cancelledCountdowns = [];

  @override
  Map<String, AutoVideoTask> build() => tasks;

  @override
  Future<void> cancelCountdown(String workId) async {
    cancelledCountdowns.add(workId);
    state = {...state}..remove(workId);
  }

  @override
  void dismiss(String workId) => state = {...state}..remove(workId);
}

/// An [AuthController] that is always signed in (no network): the flows
/// behind the pages call `ensureAuthenticated` first, and providers that wait
/// for the device token (the inspirations) see an attested device.
class SignedInAuth extends AuthController {
  @override
  AuthPhase build() =>
      const AuthAuthenticated(userId: 'test-device', isGuest: true);

  @override
  Future<void> ensureAuthenticated() async {}
}
