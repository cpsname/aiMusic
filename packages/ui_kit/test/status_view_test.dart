import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders title, message, icon and a working action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_host(
      StatusView(
        title: 'Connection problem',
        message: 'Check your network.',
        icon: Icons.wifi_off_rounded,
        actionLabel: 'Retry',
        onAction: () => tapped = true,
      ),
    ));

    expect(find.text('Connection problem'), findsOneWidget);
    expect(find.text('Check your network.'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(tapped, isTrue);
  });

  testWidgets('without an action label, no button is rendered', (tester) async {
    await tester.pumpWidget(_host(const StatusView(title: 'All caught up')));
    expect(find.byType(ObsButton), findsNothing);
  });

  testWidgets('loading shows a spinner and disables the action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_host(
      StatusView(
        title: 'Retrying',
        actionLabel: 'Retry',
        loading: true,
        onAction: () => tapped = true,
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(ObsButton));
    expect(tapped, isFalse, reason: 'a loading action is disabled');
  });

  testWidgets('omitting the message renders title + action only', (tester) async {
    await tester.pumpWidget(_host(
      StatusView(
        title: 'Nope',
        actionLabel: 'Retry',
        onAction: () {},
      ),
    ));
    expect(find.text('Nope'), findsOneWidget);
    expect(find.byType(ObsButton), findsOneWidget);
  });
}
