import 'package:flutter/material.dart';

import 'motion.dart';

/// Types [text] out one character at a time (one-shot). The controller is
/// disposed with the state; it restarts if the text changes. Under reduce-motion
/// it reveals the full text immediately (no animation).
class Typewriter extends StatefulWidget {
  const Typewriter(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.duration,
    this.onComplete,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration? duration;
  final VoidCallback? onComplete;

  @override
  State<Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<Typewriter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characters;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _play();
    }
  }

  @override
  void didUpdateWidget(Typewriter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.dispose();
      _build();
      _play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _build() {
    final length = widget.text.characters.length;
    _controller = AnimationController(
      vsync: this,
      duration:
          widget.duration ?? Duration(milliseconds: 32 * length.clamp(1, 240)),
    );
    _characters = StepTween(begin: 0, end: length).animate(_controller);
    final onComplete = widget.onComplete;
    if (onComplete != null) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) onComplete();
      });
    }
  }

  void _play() {
    if (MotionPolicy.reduceMotion(context)) {
      // Reveal the full text at once; fire onComplete after this frame (setting
      // the value directly does not emit AnimationStatus.completed).
      _controller.value = 1;
      final onComplete = widget.onComplete;
      if (onComplete != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) onComplete();
        });
      }
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characters,
      builder: (context, _) => Text(
        widget.text.characters.take(_characters.value).toString(),
        style: widget.style,
        textAlign: widget.textAlign,
      ),
    );
  }
}
