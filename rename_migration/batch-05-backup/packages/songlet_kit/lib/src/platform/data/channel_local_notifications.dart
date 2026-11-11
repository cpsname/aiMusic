import 'package:flutter/services.dart';

import '../domain/local_notifications.dart';

/// [LocalNotifications] over `songlet/notifications` (+ `/events`,
/// NotificationService.swift, ADR-0025).
class ChannelLocalNotifications implements LocalNotifications {
  const ChannelLocalNotifications({
    MethodChannel methods = const MethodChannel('songlet/notifications'),
    EventChannel events = const EventChannel('songlet/notifications/events'),
  })  : _methods = methods,
        _events = events;

  final MethodChannel _methods;
  final EventChannel _events;

  @override
  Future<bool> requestAuthorization() async =>
      await _methods.invokeMethod<String>('requestAuthorization') == 'granted';

  @override
  Future<void> schedule(LocalNotification notification) {
    final after = notification.after < LocalNotification.minDelay ? LocalNotification.minDelay : notification.after;
    return _methods.invokeMethod<void>('schedule', <String, Object?>{
      'id': notification.id,
      'title': notification.title,
      'body': notification.body,
      'afterSeconds': after.inSeconds,
      'location': notification.location,
    });
  }

  @override
  Future<void> cancel(String id) => _methods.invokeMethod<void>('cancel', <String, Object?>{'id': id});

  @override
  Stream<String> get opened => _events.receiveBroadcastStream().where((e) => e is String).cast<String>();
}
