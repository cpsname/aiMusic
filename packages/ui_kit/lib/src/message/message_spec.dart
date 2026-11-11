import 'package:flutter/widgets.dart';

/// The kind of user-facing message — drives icon, color and default lifetime.
enum MessageVariant { loading, success, error, warning, info }

/// An immutable description of one message. Pure data: no localization, no
/// business types — the app supplies already-localized [text] and [actionLabel].
@immutable
class MessageSpec {
  const MessageSpec({
    required this.variant,
    required this.text,
    this.actionLabel,
    this.onAction,
    this.autoDismiss,
  });

  final MessageVariant variant;
  final String text;

  /// Optional trailing action (e.g. "Retry" / "Manage").
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Auto-dismiss after this delay; `null` keeps it sticky. By convention
  /// loading/error/warning are sticky; success/info auto-dismiss (set by the
  /// controller's convenience constructors).
  final Duration? autoDismiss;

  bool get hasAction => actionLabel != null && onAction != null;
}
