import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../routing/music_routes.dart';
import 'music_mv_labels.dart';

/// Binds the music-video notifications to the app (ADR-0025): their copy in
/// the current language, and where opening one leads — the video's progress
/// page, which shows the finished video or why it failed. Sits under the
/// startup gate, so a tap that launched the app is routed once the app is
/// usable (the native side holds it until then).
class MusicMvNotificationBinding extends ConsumerStatefulWidget {
  const MusicMvNotificationBinding({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<MusicMvNotificationBinding> createState() =>
      _MvNotificationBindingState();
}

class _MvNotificationBindingState extends ConsumerState<MusicMvNotificationBinding> {
  StreamSubscription<String>? _opened;

  @override
  void initState() {
    super.initState();
    _opened = ref
        .read(localNotificationsProvider)
        .opened
        .listen(
          (location) =>
              widget.router.go(MusicAppRoute.locationFor(Uri.parse(location))),
          onError:
              (
                Object _,
                StackTrace _,
              ) {}, // no channel (tests, other platforms)
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    ref
        .read(mvNotificationsProvider)
        .bind(
          (video) => (
            title: l10n.mvNotifyTitle,
            body: l10n.mvNotifyBody(mvLevelName(l10n, video.level)),
            location: MusicMvGenerateRoute(video.workId, video.id).location,
          ),
        );
  }

  @override
  void dispose() {
    unawaited(_opened?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
