import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/ui/routing/routes.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  final routes = <AppRoute>[
    const CreateRoute(),
    const CreateRoute(panel: CreatePanel.length),
    const CreateRoute(panel: CreatePanel.genre, voice: true),
    const CreateRoute(voice: true),
    CreateRoute(pick: SongTemplate.petAnthem.id),
    const CreateRoute(pick: CreateRoute.custom),
    const CreateRoute(options: true),
    const CreateRoute(panel: CreatePanel.vocals, options: true),
    const CreateRoute(pick: 'birthday_wish', options: true),
    const RegionRoute(),
    const PhotosRoute(),
    const GenerateRoute(),
    FestivalRoute(Festival.carnival.wire),
    const LibraryRoute(),
    const LibraryRoute(occasion: Occasion.birthday),
    const WorkRoute('w1'),
    const PreviewRoute('w1'),
    const SongRoute('w1'),
    const ShareRoute('w1'),
    const DownloadRoute('w1'),
    const MvRoute('w1'),
    const MvRoute('w1', level: MvLevel.chorus),
    const MvRoute('w1', level: MvLevel.full, from: 'v1'),
    const MvGenerateRoute('w1', 'v1'),
    const MvPlayerRoute('w1', 'v1'),
    const SettingsRoute(),
    const AboutRoute(),
    const PaywallRoute(reason: PaywallReason.wav),
    const PaywallRoute(
      reason: PaywallReason.mv,
      productId: 'com.songlet.mv.chorus',
    ),
    const UnavailableRoute(),
  ];

  test('every route round-trips through its location', () {
    for (final route in routes) {
      final parsed = AppRoute.parse(Uri.parse(route.location));
      expect(parsed.runtimeType, route.runtimeType, reason: route.location);
      expect(parsed.location, route.location);
    }
  });

  test('deep links on the songlet scheme open the same location', () {
    expect(
      AppRoute.locationFor(Uri.parse('songlet://app/library/works/abc/play')),
      '/library/works/abc/play',
    );
    expect(
      AppRoute.locationFor(Uri.parse('songlet://app/create?panel=vocals')),
      '/create?panel=vocals',
    );
  });

  test(
    'a v1 progress link without its video opens the hub; an unknown level is ignored',
    () {
      expect(
        AppRoute.parse(Uri.parse('/library/works/w1/mv/generate')),
        isA<MvRoute>(),
      );
      expect(
        (AppRoute.parse(Uri.parse('/library/works/w1/mv?level=hologram'))
                as MvRoute)
            .level,
        isNull,
      );
      expect(
        AppRoute.locationFor(
          Uri.parse('songlet://app/library/works/w1/mv/generate/v1'),
        ),
        '/library/works/w1/mv/generate/v1',
      );
    },
  );

  test('unknown or malformed links fall back to the create home', () {
    for (final link in [
      '/nope',
      '/create/template/Not-A-Slug',
      '/create/festival/halloween',
      '/library/occasion/unknown',
      '/library/works',
    ]) {
      expect(AppRoute.parse(Uri.parse(link)), isA<CreateRoute>(), reason: link);
    }
  });

  test('query parameters are typed', () {
    final create =
        AppRoute.parse(Uri.parse('/create?panel=genre&mode=voice'))
            as CreateRoute;
    expect(create.panel, CreatePanel.genre);
    expect(create.voice, isTrue);
    expect(create.options, isFalse);
    expect(
      create.optionsShown,
      isTrue,
      reason: 'a panel opens from the options',
    );
    final options =
        AppRoute.parse(Uri.parse('/create?options=1&template=birthday_wish'))
            as CreateRoute;
    expect(options.options, isTrue);
    expect(options.pick, 'birthday_wish');
    expect(
      (AppRoute.parse(Uri.parse('/create?options=yes')) as CreateRoute).options,
      isFalse,
    );
    expect(const CreateRoute().optionsShown, isFalse);
    // The former form's links name a tile to pick (ADR-0032).
    expect(
      (AppRoute.parse(Uri.parse('/create/template/soundscape')) as CreateRoute)
          .pick,
      'soundscape',
    );
    expect(
      AppRoute.locationFor(Uri.parse('/create/template/pet_anthem')),
      '/create?template=pet_anthem',
    );
    expect(
      (AppRoute.parse(Uri.parse('/create?template=..%2Fx')) as CreateRoute)
          .pick,
      isNull,
    );
    expect(
      (AppRoute.parse(Uri.parse('/paywall?reason=bogus')) as PaywallRoute)
          .reason,
      PaywallReason.upgrade,
    );
    final paywall =
        AppRoute.parse(
              Uri.parse('/paywall?reason=mv&product=com.songlet.mv.full'),
            )
            as PaywallRoute;
    expect(paywall.reason, PaywallReason.mv);
    expect(paywall.productId, 'com.songlet.mv.full');
    expect(
      (AppRoute.parse(Uri.parse('/paywall?reason=mv')) as PaywallRoute)
          .productId,
      isNull,
    );
  });

  test('music-video deep links (PRD ch.15): hub, progress, one video', () {
    expect(
      AppRoute.parse(Uri.parse('songlet://app/library/works/abc/mv')),
      isA<MvRoute>(),
    );
    final progress =
        AppRoute.parse(Uri.parse('/library/works/abc/mv/generate/v9'))
            as MvGenerateRoute;
    expect(progress.videoId, 'v9');
    final player =
        AppRoute.parse(Uri.parse('/library/works/abc/mv/v9')) as MvPlayerRoute;
    expect(player.workId, 'abc');
    expect(player.videoId, 'v9');
    expect(
      AppRoute.locationFor(Uri.parse('songlet://app/library/works/abc/mv/v9')),
      '/library/works/abc/mv/v9',
    );
  });

  test('the player route follows the work kind', () {
    Work work(SongModel model) => Work(
      id: 'w',
      model: model,
      status: WorkStatus.ready,
      occasion: Occasion.birthday,
      region: 'US',
      genre: 'Pop',
      lyricLanguage: 'en',
      createdAt: DateTime.utc(2026),
    );
    expect(playerRouteFor(work(SongModel.clip)), isA<PreviewRoute>());
    expect(playerRouteFor(work(SongModel.fullSong)), isA<SongRoute>());
  });
}
