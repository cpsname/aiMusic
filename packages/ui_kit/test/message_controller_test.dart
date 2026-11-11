import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('MessageController', () {
    test('handle 原地流转:loading → error,条目不增', () {
      final c = MessageController();
      final h = c.loading('processing', tag: 'p');
      expect(c.entries.length, 1);
      expect(c.entries.single.spec.variant, MessageVariant.loading);

      h.error('failed');
      expect(c.entries.length, 1);
      expect(c.entries.single.spec.variant, MessageVariant.error);
      expect(c.entries.single.spec.text, 'failed');
      c.dispose();
    });

    test('同 tag 复用同一条(不堆叠)', () {
      final c = MessageController();
      c.loading('a', tag: 'p');
      c.loading('b', tag: 'p');
      expect(c.entries.length, 1);
      expect(c.entries.single.spec.text, 'b');
      c.dispose();
    });

    test('无 tag 堆叠并受 maxVisible 限制(丢最旧)', () {
      final c = MessageController(maxVisible: 2);
      c.error('1');
      c.error('2');
      c.error('3');
      expect(c.entries.length, 2);
      expect(c.entries.first.spec.text, '2');
      expect(c.entries.last.spec.text, '3');
      c.dispose();
    });

    test('dismissTag / handle.dismiss / isActive', () {
      final c = MessageController();
      final h = c.error('x', tag: 't');
      expect(h.isActive, isTrue);
      c.dismissTag('t');
      expect(c.entries, isEmpty);
      expect(h.isActive, isFalse);
      h.error('again'); // 已移除 → no-op
      expect(c.entries, isEmpty);
      c.dispose();
    });

    test('notifyListeners 在 show / dismiss 时触发', () {
      final c = MessageController();
      var n = 0;
      c.addListener(() => n++);
      c.info('hi', tag: 't');
      c.dismissTag('t');
      expect(n, 2);
      c.dispose();
    });

    testWidgets('success 自动消失(autoDismiss)', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final c = MessageController();
      c.success('done'); // 默认 2s
      expect(c.entries.length, 1);
      await tester.pump(const Duration(seconds: 2, milliseconds: 1));
      expect(c.entries, isEmpty);
      c.dispose();
    });

    testWidgets('loading 常驻(不自动消失)', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final c = MessageController();
      c.loading('working', tag: 'p');
      await tester.pump(const Duration(seconds: 10));
      expect(c.entries.length, 1);
      c.dispose();
    });
  });
}
