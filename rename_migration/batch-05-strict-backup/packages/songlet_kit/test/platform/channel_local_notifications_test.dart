import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/platform/data/channel_local_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methods = MethodChannel('songlet/notifications');
  const events = EventChannel('songlet/notifications/events');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  String authorization = 'granted';

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      return call.method == 'requestAuthorization' ? authorization : null;
    });
  });

  tearDown(() {
    messenger
      ..setMockMethodCallHandler(methods, null)
      ..setMockStreamHandler(events, null);
  });

  const notifications = ChannelLocalNotifications();

  test('authorization maps the native answer', () async {
    expect(await notifications.requestAuthorization(), isTrue);
    authorization = 'denied';
    expect(await notifications.requestAuthorization(), isFalse);
  });

  test('schedule sends the id, copy, seconds and route; never sooner than a minute', () async {
    await notifications.schedule(const LocalNotification(
      id: 'mv.v1',
      title: 'Your video',
      body: 'Ready soon',
      after: Duration(minutes: 9),
      location: '/library/works/w1/mv/v1/making',
    ));
    await notifications.schedule(const LocalNotification(id: 'mv.v2', title: 't', body: 'b', after: Duration(seconds: 5), location: '/'));
    expect(calls[0].method, 'schedule');
    expect(calls[0].arguments, {
      'id': 'mv.v1',
      'title': 'Your video',
      'body': 'Ready soon',
      'afterSeconds': 540,
      'location': '/library/works/w1/mv/v1/making',
    });
    expect((calls[1].arguments as Map)['afterSeconds'], 60);

    await notifications.cancel('mv.v1');
    expect(calls.last.method, 'cancel');
    expect(calls.last.arguments, {'id': 'mv.v1'});
  });

  test('opened streams the tapped locations', () async {
    messenger.setMockStreamHandler(
      events,
      MockStreamHandler.inline(onListen: (arguments, sink) {
        sink
          ..success('/library/works/w1/mv/v1/making')
          ..success(42)
          ..success('/library');
      }),
    );
    final opened = await notifications.opened.take(2).toList();
    expect(opened, ['/library/works/w1/mv/v1/making', '/library']);
  });
}
