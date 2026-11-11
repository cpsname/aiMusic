import 'package:meta/meta.dart';

/// One local notification (ADR-0025): shown after [after] unless cancelled;
/// opening it takes the app to [location] (an app route).
@immutable
class MusicLocalNotification {
  const MusicLocalNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.after,
    required this.location,
  });

  /// A notification is never scheduled sooner than this: a video due in
  /// seconds is watched in the app, not announced.
  static const Duration minDelay = Duration(seconds: 60);

  /// Stable per subject (`mv.<videoId>`): scheduling again replaces it.
  final String id;
  final String title;
  final String body;
  final Duration after;
  final String location;
}

/// Local notifications of this device — no push, nothing leaves the phone.
abstract interface class MusicLocalNotifications {
  /// Asks once; afterwards reports the stored decision.
  Future<bool> requestAuthorization();

  Future<void> schedule(MusicLocalNotification notification);

  Future<void> cancel(String id);

  /// Locations of the notifications the user opens, including the one that
  /// launched the app.
  Stream<String> get opened;
}
