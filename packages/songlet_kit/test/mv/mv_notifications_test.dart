import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

import 'mv_fakes.dart';

class _Notifications implements MusicLocalNotifications {
  _Notifications({this.granted = true, this.failing = false});

  final bool granted;
  final bool failing;
  final List<MusicLocalNotification> scheduled = [];
  final List<String> cancelled = [];

  @override
  Future<bool> requestAuthorization() async => granted;
  @override
  Future<void> schedule(MusicLocalNotification notification) async {
    if (failing) throw StateError('no channel');
    scheduled.add(notification);
  }

  @override
  Future<void> cancel(String id) async {
    if (failing) throw StateError('no channel');
    cancelled.add(id);
  }

  @override
  Stream<String> get opened => const Stream.empty();
}

void main() {
  ({String title, String body, String location}) copy(MusicVideo video) =>
      (title: 'Your video', body: video.level.wire, location: '/library/works/${video.workId}/mv/generate/${video.id}');

  test('schedules at the ETA with the bound copy and the video route', () async {
    final channel = _Notifications();
    final notifications = MusicMvNotifications(channel)..bind(copy);
    await notifications.scheduleFor(pendingVideo(), etaSeconds: 600);
    final n = channel.scheduled.single;
    expect(n.id, 'mv.v1');
    expect(n.after, const Duration(minutes: 10));
    expect(n.body, 'chorus_mv');
    expect(n.location, '/library/works/w1/mv/generate/v1');
    await notifications.cancelFor('v1');
    expect(channel.cancelled, ['mv.v1']);
  });

  test('nothing without copy or permission; a channel error never escapes', () async {
    final channel = _Notifications(granted: false);
    await MusicMvNotifications(channel).scheduleFor(pendingVideo(), etaSeconds: 600);
    await (MusicMvNotifications(channel)..bind(copy)).scheduleFor(pendingVideo(), etaSeconds: 600);
    expect(channel.scheduled, isEmpty);

    final broken = MusicMvNotifications(_Notifications(failing: true))..bind(copy);
    await broken.scheduleFor(pendingVideo(), etaSeconds: 600);
    await broken.cancelFor('v1');
  });
}
