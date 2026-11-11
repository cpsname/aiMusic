import 'package:flutter/widgets.dart';

/// Package-internal (not exported): the template tile and the composer's
/// template head draw a cover photo with a fallback picture.
///
/// Hands [builder] the image to draw — [primary] until it reports an error,
/// then [fallback] — and the listener to wire into the image's `onError`.
class CoverFallback extends StatefulWidget {
  const CoverFallback({
    super.key,
    required this.primary,
    required this.fallback,
    required this.builder,
  });

  final ImageProvider? primary;
  final ImageProvider? fallback;
  final Widget Function(BuildContext, ImageProvider?, ImageErrorListener)
  builder;

  @override
  State<CoverFallback> createState() => _CoverFallbackState();
}

class _CoverFallbackState extends State<CoverFallback> {
  bool _failed = false;

  @override
  void didUpdateWidget(CoverFallback old) {
    super.didUpdateWidget(old);
    if (old.primary != widget.primary) _failed = false;
  }

  void _onError(Object error, StackTrace? stackTrace) {
    if (_failed || widget.fallback == null || widget.primary == null) return;
    // Reported while painting: switch after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _failed ? widget.fallback : widget.primary,
    _onError,
  );
}
