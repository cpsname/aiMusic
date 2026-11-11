import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/ui/routing/music_routes.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  final routes = <MusicAppRoute>[
    const MusicCreateRoute(),
    const MusicCreateRoute(panel: MusicCreatePanel.length),
    const MusicCreateRoute(panel: MusicCreatePanel.genre, voice: true),
    const MusicCreateRoute(voice: true),
    MusicCreateRoute(pick: MusicSongTemplate.petAnthem.id),
    const MusicCreateRoute(pick: MusicCreateRoute.custom),
    const MusicCreateRoute(options: true),
    const MusicCreateRoute(panel: MusicCreatePanel.vocals, options: true),
    const MusicCreateRoute(pick: 'birthday_wish', options: true),
    const MusicRegionRoute(),
    const MusicPhotosRoute(),
    const MusicGenerateRoute(),
    MusicFestivalRoute(MusicFestival.carnival.wire),
    const MusicLibraryRoute(),
    const MusicLibraryRoute(occasion: MusicOccasion.birthday),
    const MusicWorkRoute('w1'),
    const MusicPreviewRoute('w1'),
    const MusicSongRoute('w1'),
    const MusicShareRoute('w1'),
    const MusicDownloadRoute('w1'),
    const MusicMvRoute('w1'),
    const MusicMvRoute('w1', level: MusicMvLevel.chorus),
    const MusicMvRoute('w1', level: MusicMvLevel.full, from: 'v1'),
    const MusicMvGenerateRoute('w1', 'v1'),
    const MusicMvPlayerRoute('w1', 'v1'),
    const MusicSettingsRoute(),
    const MusicAboutRoute(),
    const MusicPaywallRoute(reason: MusicPaywallReason.wav),
    const MusicPaywallRoute(
      reason: MusicPaywallReason.mv,
      productId: 'com.songlet.mv.chorus',
    ),
    const MusicUnavailableRoute(),
  ];

  test('every route round-trips through its location', () {
    for (final route in routes) {
      final parsed = MusicAppRoute.parse(Uri.parse(route.location));
      expect(parsed.runtimeType, route.runtimeType, reason: route.location);
      expect(parsed.location, route.location);
    }
  });

  test('deep links on the songlet scheme open the same location', () {
    expect(
      MusicAppRoute.locationFor(Uri.parse('songlet://app/library/works/abc/play')),
      '/library/works/abc/play',
    );
    expect(
      MusicAppRoute.locationFor(Uri.parse('songlet://app/create?panel=vocals')),
      '/create?panel=vocals',
    );
  });

  test(
    'a v1 progress link without its video opens the hub; an unknown level is ignored',
    () {
      expect(
        MusicAppRoute.parse(Uri.parse('/library/works/w1/mv/generate')),
        isA<MusicMvRoute>(),
      );
      expect(
        (MusicAppRoute.parse(Uri.parse('/library/works/w1/mv?level=hologram'))
                as MusicMvRoute)
            .level,
        isNull,
      );
      expect(
        MusicAppRoute.locationFor(
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
      expect(MusicAppRoute.parse(Uri.parse(link)), isA<MusicCreateRoute>(), reason: link);
    }
  });

  test('query parameters are typed', () {
    final create =
        MusicAppRoute.parse(Uri.parse('/create?panel=genre&mode=voice'))
            as MusicCreateRoute;
    expect(create.panel, MusicCreatePanel.genre);
    expect(create.voice, isTrue);
    expect(create.options, isFalse);
    expect(
      create.optionsShown,
      isTrue,
      reason: 'a panel opens from the options',
    );
    final options =
        MusicAppRoute.parse(Uri.parse('/create?options=1&template=birthday_wish'))
            as MusicCreateRoute;
    expect(options.options, isTrue);
    expect(options.pick, 'birthday_wish');
    expect(
      (MusicAppRoute.parse(Uri.parse('/create?options=yes')) as MusicCreateRoute).options,
      isFalse,
    );
    expect(const MusicCreateRoute().optionsShown, isFalse);
    // The former form's links name a tile to pick (ADR-0032).
    expect(
      (MusicAppRoute.parse(Uri.parse('/create/template/soundscape')) as MusicCreateRoute)
          .pick,
      'soundscape',
    );
    expect(
      MusicAppRoute.locationFor(Uri.parse('/create/template/pet_anthem')),
      '/create?template=pet_anthem',
    );
    expect(
      (MusicAppRoute.parse(Uri.parse('/create?template=..%2Fx')) as MusicCreateRoute)
          .pick,
      isNull,
    );
    expect(
      (MusicAppRoute.parse(Uri.parse('/paywall?reason=bogus')) as MusicPaywallRoute)
          .reason,
      MusicPaywallReason.upgrade,
    );
    final paywall =
        MusicAppRoute.parse(
              Uri.parse('/paywall?reason=mv&product=com.songlet.mv.full'),
            )
            as MusicPaywallRoute;
    expect(paywall.reason, MusicPaywallReason.mv);
    expect(paywall.productId, 'com.songlet.mv.full');
    expect(
      (MusicAppRoute.parse(Uri.parse('/paywall?reason=mv')) as MusicPaywallRoute)
          .productId,
      isNull,
    );
  });

  test('music-video deep links (PRD ch.15): hub, progress, one video', () {
    expect(
      MusicAppRoute.parse(Uri.parse('songlet://app/library/works/abc/mv')),
      isA<MusicMvRoute>(),
    );
    final progress =
        MusicAppRoute.parse(Uri.parse('/library/works/abc/mv/generate/v9'))
            as MusicMvGenerateRoute;
    expect(progress.videoId, 'v9');
    final player =
        MusicAppRoute.parse(Uri.parse('/library/works/abc/mv/v9')) as MusicMvPlayerRoute;
    expect(player.workId, 'abc');
    expect(player.videoId, 'v9');
    expect(
      MusicAppRoute.locationFor(Uri.parse('songlet://app/library/works/abc/mv/v9')),
      '/library/works/abc/mv/v9',
    );
  });

  test('the player route follows the work kind', () {
    MusicWork work(MusicSongModel model) => MusicWork(
      id: 'w',
      model: model,
      status: MusicWorkStatus.ready,
      occasion: MusicOccasion.birthday,
      region: 'US',
      genre: 'Pop',
      lyricLanguage: 'en',
      createdAt: DateTime.utc(2026),
    );
    expect(playerRouteFor(work(MusicSongModel.clip)), isA<MusicPreviewRoute>());
    expect(playerRouteFor(work(MusicSongModel.fullSong)), isA<MusicSongRoute>());
  });
}
