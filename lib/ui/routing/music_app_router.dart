import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../common/music_unavailable_page.dart';
import '../create/music_create_home_page.dart';
import '../create/music_generating_page.dart';
import '../create/music_photos_page.dart';
import '../create/music_region_sheet.dart';
import '../download/music_download_page.dart';
import '../festival/music_festival_page.dart';
import '../library/music_library_page.dart';
import '../mv/mv_music_generating_page.dart';
import '../mv/music_mv_hub_page.dart';
import '../mv/music_mv_player_page.dart';
import '../paywall/music_paywall_page.dart';
import '../player/music_preview_page.dart';
import '../player/music_song_page.dart';
import '../settings/music_about_page.dart';
import '../settings/music_settings_page.dart';
import '../share/music_share_card_page.dart';
import '../shell/music_shell.dart';
import '../work/music_work_detail_page.dart';
import 'music_routes.dart';
import 'music_sheet_page.dart';

/// The route table (ADR-0003): three tab branches (Create · Library ·
/// Settings) that each keep their own stack, plus root-level modals (paywall,
/// region sheet, unavailable). Every entry is reached through a typed
/// [MusicAppRoute]; unknown locations and deep links fall back to the create home.
GoRouter buildAppRouter({String initialLocation = MusicCreateRoute.path}) {
  final root = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: root,
    initialLocation: initialLocation,
    // Deep links arrive as `songlet://app/<path>` or plain paths; anything
    // unknown or malformed resolves to a typed route (the create home).
    redirect: (context, state) {
      final location = MusicAppRoute.locationFor(state.uri);
      final requested = state.uri.toString();
      return location == requested || state.uri.path == location
          ? null
          : location;
    },
    onException: (context, state, router) =>
        router.go(const MusicCreateRoute().location),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MusicShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: MusicCreateRoute.path,
                // Also builds under a child route (the page below a pushed
                // form), so read the query directly rather than parse the
                // whole location as a MusicCreateRoute.
                builder: (context, state) => MusicCreateHomePage(
                  panel: MusicCreatePanel.fromWire(
                    state.uri.queryParameters[MusicCreateRoute.panelParam],
                  ),
                  voice:
                      state.uri.queryParameters[MusicCreateRoute.modeParam] ==
                      MusicCreateRoute.voiceMode,
                  pick: MusicCreateRoute.validPick(
                    state.uri.queryParameters[MusicCreateRoute.pickParam],
                  ),
                  options:
                      state.uri.queryParameters[MusicCreateRoute.optionsParam] ==
                      MusicCreateRoute.optionsOpen,
                ),
                routes: [
                  GoRoute(
                    path: MusicRegionRoute.path,
                    parentNavigatorKey: root,
                    pageBuilder: (context, state) => MusicSheetPage<void>(
                      key: state.pageKey,
                      child: const MusicRegionSheet(),
                    ),
                  ),
                  GoRoute(
                    path: MusicPhotosRoute.path,
                    builder: (context, state) => const MusicPhotosPage(),
                  ),
                  GoRoute(
                    path: MusicGenerateRoute.path,
                    // Nothing in flight — the Create tab's stack after the song
                    // opened in Library, or a cold deep link — lands on the
                    // create home rather than an empty progress page.
                    redirect: (context, state) =>
                        ProviderScope.containerOf(
                              context,
                              listen: false,
                            ).read(generationControllerProvider)
                            is MusicGenerationIdle
                        ? const MusicCreateRoute().location
                        : null,
                    builder: (context, state) => const MusicGeneratingPage(),
                  ),
                  GoRoute(
                    path: MusicFestivalRoute.path,
                    builder: (context, state) => _keyed(
                      state,
                      MusicFestivalPage(
                        festival:
                            MusicFestival.fromWire(
                              state.pathParameters[MusicFestivalRoute.idParam],
                            ) ??
                            MusicFestival.newYear,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: MusicLibraryRoute.path,
                builder: (context, state) => const MusicLibraryPage(),
                routes: [
                  GoRoute(
                    path: MusicLibraryRoute.occasionPath,
                    builder: (context, state) => _keyed(
                      state,
                      MusicLibraryPage(
                        occasion: MusicOccasion.fromWire(
                          state.pathParameters[MusicLibraryRoute.occasionParam] ??
                              '',
                        ),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: MusicWorkScopedRoute.basePath,
                    builder: (context, state) =>
                        _keyed(state, MusicWorkDetailPage(workId: _workId(state))),
                    routes: [
                      GoRoute(
                        path: MusicPreviewRoute.path,
                        builder: (context, state) =>
                            _keyed(state, MusicPreviewPage(workId: _workId(state))),
                      ),
                      GoRoute(
                        path: MusicSongRoute.path,
                        builder: (context, state) =>
                            _keyed(state, MusicSongPage(workId: _workId(state))),
                      ),
                      GoRoute(
                        path: MusicShareRoute.path,
                        builder: (context, state) => _keyed(
                          state,
                          MusicShareCardPage(workId: _workId(state)),
                        ),
                      ),
                      GoRoute(
                        path: MusicDownloadRoute.path,
                        builder: (context, state) =>
                            _keyed(state, MusicDownloadPage(workId: _workId(state))),
                      ),
                      GoRoute(
                        path: MusicMvRoute.path,
                        builder: (context, state) => _keyed(
                          state,
                          MusicMvHubPage(
                            workId: _workId(state),
                            level: MusicMvLevel.fromWire(
                              state.uri.queryParameters[MusicMvRoute.levelParam],
                            ),
                            from: state.uri.queryParameters[MusicMvRoute.fromParam],
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: MusicMvGenerateRoute.path,
                            builder: (context, state) => _keyed(
                              state,
                              MusicMvGeneratingPage(
                                workId: _workId(state),
                                videoId:
                                    state.pathParameters[MusicMvGenerateRoute
                                        .videoParam]!,
                              ),
                            ),
                          ),
                          GoRoute(
                            path: MusicMvPlayerRoute.path,
                            // Immersive (docs/ui P26): above the tab bar.
                            parentNavigatorKey: root,
                            builder: (context, state) => _keyed(
                              state,
                              MusicMvPlayerPage(
                                workId: _workId(state),
                                videoId: state
                                    .pathParameters[MusicMvPlayerRoute.videoParam]!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: MusicSettingsRoute.path,
                builder: (context, state) => const MusicSettingsPage(),
                routes: [
                  GoRoute(
                    path: MusicAboutRoute.path,
                    builder: (context, state) => const MusicAboutPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: MusicPaywallRoute.path,
        parentNavigatorKey: root,
        pageBuilder: (context, state) => MaterialPage<bool>(
          key: state.pageKey,
          fullscreenDialog: true,
          child: switch (MusicAppRoute.parse(state.uri) as MusicPaywallRoute) {
            final route => MusicPaywallPage(
              reason: route.reason,
              productId: route.productId,
              offer: route.offer,
            ),
          },
        ),
      ),
      GoRoute(
        path: MusicUnavailableRoute.path,
        parentNavigatorKey: root,
        builder: (context, state) => const MusicUnavailablePage(),
      ),
    ],
  );
}

String _workId(GoRouterState state) =>
    state.pathParameters[MusicWorkScopedRoute.idParam]!;

/// go_router keys a page by its route pattern, so moving from one work (or
/// template, festival) to another would keep the first page's State — its
/// autoplay-once flag, loaded license, form fields. Keying the page's widget
/// by the concrete location gives every target its own State.
Widget _keyed(GoRouterState state, Widget page) =>
    KeyedSubtree(key: ValueKey(state.matchedLocation), child: page);
