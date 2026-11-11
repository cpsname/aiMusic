import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

class _Spinner extends StatefulWidget {
  const _Spinner();

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin, RepeatingMotion<_Spinner> {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  AnimationController get motionController => _c;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Widget _host({bool reduceMotion = false, required Widget child}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

void main() {
  testWidgets('repeats while foregrounded with motion allowed', (tester) async {
    await tester.pumpWidget(_host(child: const _Spinner()));
    final state = tester.state<_SpinnerState>(find.byType(_Spinner));
    expect(state.motionController.isAnimating, isTrue);
  });

  testWidgets('does not animate under reduce-motion', (tester) async {
    await tester.pumpWidget(_host(reduceMotion: true, child: const _Spinner()));
    final state = tester.state<_SpinnerState>(find.byType(_Spinner));
    expect(state.motionController.isAnimating, isFalse);
  });

  testWidgets('pauses when backgrounded and resumes on foreground',
      (tester) async {
    await tester.pumpWidget(_host(child: const _Spinner()));
    final state = tester.state<_SpinnerState>(find.byType(_Spinner));
    expect(state.motionController.isAnimating, isTrue);

    // Foreground → background follows the valid transition path.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(state.motionController.isAnimating, isFalse);

    // Background → foreground (reverse path).
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(state.motionController.isAnimating, isTrue);
  });

  testWidgets('MotionPolicyOverride forces reduce-motion over MediaQuery',
      (tester) async {
    await tester.pumpWidget(
      _host(
        child: const MotionPolicyOverride(
          reduceMotion: true,
          child: _Spinner(),
        ),
      ),
    );
    final state = tester.state<_SpinnerState>(find.byType(_Spinner));
    expect(state.motionController.isAnimating, isFalse);
  });

  testWidgets('AuroraBackground keeps no perpetual ticker under reduce-motion',
      (tester) async {
    await tester.pumpWidget(_host(reduceMotion: true, child: const AuroraBackground()));
    // A perpetual ticker would make pumpAndSettle time out.
    await tester.pumpAndSettle();
  });
}
