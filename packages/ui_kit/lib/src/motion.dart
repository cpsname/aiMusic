import 'package:flutter/widgets.dart';

/// Central reduce-motion policy. Honours the platform accessibility setting
/// (`MediaQuery.disableAnimations` — "reduce motion", and some battery savers);
/// a host can force it via [MotionPolicyOverride] (e.g. a low-battery degrade or
/// deterministic golden tests).
abstract final class MotionPolicy {
  /// Whether non-essential motion should be suppressed for [context].
  static bool reduceMotion(BuildContext context) =>
      MotionPolicyOverride.maybeOf(context) ??
      (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
}

/// Forces [MotionPolicy.reduceMotion] on/off for its subtree. Omit it to defer to
/// `MediaQuery`.
class MotionPolicyOverride extends InheritedWidget {
  const MotionPolicyOverride({
    super.key,
    required this.reduceMotion,
    required super.child,
  });

  final bool reduceMotion;

  static bool? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MotionPolicyOverride>()
      ?.reduceMotion;

  @override
  bool updateShouldNotify(MotionPolicyOverride oldWidget) =>
      oldWidget.reduceMotion != reduceMotion;
}

/// Drives a repeating [AnimationController] per [MotionPolicy] and the app
/// lifecycle: it repeats only while motion is allowed **and** the app is
/// foregrounded, otherwise resting on [restFrame]. This honours reduce-motion and
/// saves power in the background — important because the Aura backdrop / shimmer
/// animate forever, which would otherwise keep a perpetual ticker alive.
///
/// Mix into a [State] that exposes [motionController]; the host still creates and
/// disposes the controller (without `..repeat()` — this mixin starts it).
mixin RepeatingMotion<T extends StatefulWidget> on State<T> {
  /// The controller this state drives.
  AnimationController get motionController;

  /// The frame to rest on when motion is suppressed (0 by default).
  double get restFrame => 0;

  AppLifecycleListener? _lifecycle;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _onLifecycle(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _syncMotion();
  }

  void _syncMotion() {
    if (!mounted) return;
    final suppress = !_foreground || MotionPolicy.reduceMotion(context);
    if (suppress) {
      if (motionController.isAnimating) motionController.stop();
      motionController.value = restFrame;
    } else if (!motionController.isAnimating) {
      motionController.repeat();
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }
}
