import '../../platform/domain/local_notifications.dart';
import '../domain/music_video.dart';

/// What a video's notification says and where it leads; built by the app
/// (localized copy, typed routes) and bound once at startup.
typedef MvNotificationCopy = ({String title, String body, String location}) Function(MusicVideo video);

/// The ETA notification of a music video (ADR-0025): scheduled when the
/// platform accepts the video, cancelled once it settles while the app runs.
/// The app never polls in the background; this is how a user who left learns
/// the video should be ready. Best effort: a refused permission or a
/// channel error never affects the video.
class MvNotifications {
  MvNotifications(this._notifications);

  final LocalNotifications _notifications;
  MvNotificationCopy? _copy;

  static String idFor(String videoId) => 'mv.$videoId';

  /// The app's copy (re-bound when the locale changes).
  void bind(MvNotificationCopy copy) => _copy = copy;

  Future<void> scheduleFor(MusicVideo video, {required int etaSeconds}) async {
    final copy = _copy?.call(video);
    if (copy == null) return;
    try {
      if (!await _notifications.requestAuthorization()) return;
      await _notifications.schedule(
        LocalNotification(
          id: idFor(video.id),
          title: copy.title,
          body: copy.body,
          after: Duration(seconds: etaSeconds),
          location: copy.location,
        ),
      );
    } on Object {
      // Best effort: the video goes on without its reminder.
    }
  }

  Future<void> cancelFor(String videoId) async {
    try {
      await _notifications.cancel(idFor(videoId));
    } on Object {
      // Nothing scheduled, or no channel: nothing to cancel.
    }
  }
}
