import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../common/unavailable_page.dart';
import '../create/create_home_page.dart';
import '../create/generating_page.dart';
import '../create/photos_page.dart';
import '../create/region_sheet.dart';
import '../download/download_page.dart';
import '../festival/festival_page.dart';
import '../library/library_page.dart';
import '../mv/mv_generating_page.dart';
import '../mv/mv_hub_page.dart';
import '../mv/mv_player_page.dart';
import '../paywall/paywall_page.dart';
import '../player/preview_page.dart';
import '../player/song_page.dart';
import '../settings/about_page.dart';
import '../settings/settings_page.dart';
import '../share/share_card_page.dart';
import '../shell/songlet_shell.dart';
import '../work/work_detail_page.dart';
import 'routes.dart';
import 'sheet_page.dart';

/// The route table (ADR-0003): three tab branches (Create · Library ·
/// Settings) that each keep their own stack, plus root-level modals (paywall,
/// region sheet, unavailable). Every entry is reached through a typed
/// [AppRoute]; unknown locations and deep links fall back to the create home.
GoRouter buildAppRouter({String initialLocation = CreateRoute.path}) {
  final root = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: root,
    initialLocation: initialLocation,
    // Deep links arrive as `songlet://app/<path>` or plain paths; anything
    // unknown or malformed resolves to a typed route (the create home).
    redirect: (context, state) {
      final location = AppRoute.locationFor(state.uri);
      final requested = state.uri.toString();
      return location == requested || state.uri.path == location ? null : location;
    },
    onException: (context, state, router) => router.go(const CreateRoute().location),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => SongletShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: CreateRoute.path,
                // Also builds under a child route (the page below a pushed
                // form), so read the query directly rather than parse the
                // whole location as a CreateRoute.
                builder: (context, state) => CreateHomePage(
                  panel: CreatePanel.fromWire(state.uri.queryParameters[CreateRoute.panelParam]),
                  voice: state.uri.queryParameters[CreateRoute.modeParam] == CreateRoute.voiceMode,
                  pick: CreateRoute.validPick(state.uri.queryParameters[CreateRoute.pickParam]),
                  options: state.uri.queryParameters[CreateRoute.optionsParam] == CreateRoute.optionsOpen,
                ),
                routes: [
                  GoRoute(
                    path: RegionRoute.path,
                    parentNavigatorKey: root,
                    pageBuilder: (context, state) => SheetPage<void>(key: state.pageKey, child: const RegionSheet()),
                  ),
                  GoRoute(path: PhotosRoute.path, builder: (context, state) => const PhotosPage()),
                  GoRoute(
                    path: GenerateRoute.path,
                    // Nothing in flight — the Create tab's stack after the song
                    // opened in Library, or a cold deep link — lands on the
                    // create home rather than an empty progress page.
                    redirect: (context, state) =>
                        ProviderScope.containerOf(context, listen: false).read(generationControllerProvider)
                            is GenerationIdle
                        ? const CreateRoute().location
                        : null,
                    builder: (context, state) => const GeneratingPage(),
                  ),
                  GoRoute(
                    path: FestivalRoute.path,
                    builder: (context, state) => _keyed(
                      state,
                      FestivalPage(
                        festival: Festival.fromWire(state.pathParameters[FestivalRoute.idParam]) ?? Festival.newYear,
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
                path: LibraryRoute.path,
                builder: (context, state) => const LibraryPage(),
                routes: [
                  GoRoute(
                    path: LibraryRoute.occasionPath,
                    builder: (context, state) => _keyed(
                      state,
                      LibraryPage(occasion: Occasion.fromWire(state.pathParameters[LibraryRoute.occasionParam] ?? '')),
                    ),
                  ),
                  GoRoute(
                    path: WorkScopedRoute.basePath,
                    builder: (context, state) => _keyed(state, WorkDetailPage(workId: _workId(state))),
                    routes: [
                      GoRoute(
                        path: PreviewRoute.path,
                        builder: (context, state) => _keyed(state, PreviewPage(workId: _workId(state))),
                      ),
                      GoRoute(
                        path: SongRoute.path,
                        builder: (context, state) => _keyed(state, SongPage(workId: _workId(state))),
                      ),
                      GoRoute(
                        path: ShareRoute.path,
                        builder: (context, state) => _keyed(state, ShareCardPage(workId: _workId(state))),
                      ),
                      GoRoute(
                        path: DownloadRoute.path,
                        builder: (context, state) => _keyed(state, DownloadPage(workId: _workId(state))),
                      ),
                      GoRoute(
                        path: MvRoute.path,
                        builder: (context, state) => _keyed(
                          state,
                          MvHubPage(
                            workId: _workId(state),
                            level: MvLevel.fromWire(state.uri.queryParameters[MvRoute.levelParam]),
                            from: state.uri.queryParameters[MvRoute.fromParam],
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: MvGenerateRoute.path,
                            builder: (context, state) => _keyed(
                              state,
                              MvGeneratingPage(workId: _workId(state), videoId: state.pathParameters[MvGenerateRoute.videoParam]!),
                            ),
                          ),
                          GoRoute(
                            path: MvPlayerRoute.path,
                            // Immersive (docs/ui P26): above the tab bar.
                            parentNavigatorKey: root,
                            builder: (context, state) => _keyed(
                              state,
                              MvPlayerPage(workId: _workId(state), videoId: state.pathParameters[MvPlayerRoute.videoParam]!),
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
                path: SettingsRoute.path,
                builder: (context, state) => const SettingsPage(),
                routes: [GoRoute(path: AboutRoute.path, builder: (context, state) => const AboutPage())],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: PaywallRoute.path,
        parentNavigatorKey: root,
        pageBuilder: (context, state) => MaterialPage<bool>(
          key: state.pageKey,
          fullscreenDialog: true,
          child: switch (AppRoute.parse(state.uri) as PaywallRoute) {
            final route => PaywallPage(reason: route.reason, productId: route.productId, offer: route.offer),
          },
        ),
      ),
      GoRoute(
        path: UnavailableRoute.path,
        parentNavigatorKey: root,
        builder: (context, state) => const UnavailablePage(),
      ),
    ],
  );
}

String _workId(GoRouterState state) => state.pathParameters[WorkScopedRoute.idParam]!;

/// go_router keys a page by its route pattern, so moving from one work (or
/// template, festival) to another would keep the first page's State — its
/// autoplay-once flag, loaded license, form fields. Keying the page's widget
/// by the concrete location gives every target its own State.
Widget _keyed(GoRouterState state, Widget page) => KeyedSubtree(key: ValueKey(state.matchedLocation), child: page);
