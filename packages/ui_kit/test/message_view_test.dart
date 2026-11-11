import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
      home: Scaffold(
        body: MotionPolicyOverride(reduceMotion: reduceMotion, child: child),
      ),
    );

void main() {
  testWidgets('error 变体:文案 + action + dismiss 回调', (tester) async {
    var acted = false;
    var dismissed = false;
    await tester.pumpWidget(_host(
      MessageView(
        spec: MessageSpec(
          variant: MessageVariant.error,
          text: 'boom',
          actionLabel: 'Retry',
          onAction: () => acted = true,
        ),
        onDismiss: () => dismissed = true,
      ),
    ));

    expect(find.text('boom'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(acted, isTrue);
    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(dismissed, isTrue);
  });

  testWidgets('loading:显示进度圈,且无 dismiss 按钮', (tester) async {
    await tester.pumpWidget(_host(
      MessageView(
        spec: const MessageSpec(variant: MessageVariant.loading, text: '…'),
        onDismiss: () {},
      ),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('reduce-motion:loading 用静态图标,不用进度圈(DF⑥)', (tester) async {
    await tester.pumpWidget(_host(
      reduceMotion: true,
      MessageView(
        spec: const MessageSpec(variant: MessageVariant.loading, text: '…'),
        onDismiss: () {},
      ),
    ));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
  });

  testWidgets('MessageHost 渲染控制器条目并可消去', (tester) async {
    final c = MessageController();
    addTearDown(c.dispose);
    await tester.pumpWidget(MaterialApp(
      home: MotionPolicyOverride(
        reduceMotion: true,
        child: MessageHost(controller: c, child: const Scaffold(body: SizedBox())),
      ),
    ));
    c.error('on screen', tag: 't');
    await tester.pump();
    expect(find.text('on screen'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(find.text('on screen'), findsNothing);
    expect(c.entries, isEmpty);
  });
}
