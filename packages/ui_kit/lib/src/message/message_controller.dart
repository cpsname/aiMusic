import 'dart:async';

import 'package:flutter/widgets.dart';

import 'message_spec.dart';

const Duration _kSuccessDismiss = Duration(seconds: 2);
const Duration _kInfoDismiss = Duration(seconds: 4);

/// A live message in the stack. [spec] is mutable so a handle can transition it
/// in place (loading → success/error) without changing identity.
class MessageEntry {
  MessageEntry({required this.id, required this.spec, this.tag});
  final int id;
  MessageSpec spec;
  final Object? tag;
}

/// Imperative, presentation-only message stack (a [ChangeNotifier] — no Riverpod,
/// no app/business deps, so it lives in ui_kit). The host listens and renders;
/// the app drives it (mapping Failure / IAP states → messages).
///
/// Tagged messages replace in place — so a purchase flow keeps ONE entry that
/// flows `loading → verifying → success/error`. Untagged messages stack, capped
/// at [maxVisible] (oldest dropped).
class MessageController extends ChangeNotifier {
  MessageController({this.maxVisible = 3});

  final int maxVisible;
  final List<MessageEntry> _entries = [];
  final Map<int, Timer> _timers = {};
  int _seq = 0;

  List<MessageEntry> get entries => List.unmodifiable(_entries);

  /// Show (or, with [tag], upsert) a message. Returns a handle to transition it.
  MessageHandle show(MessageSpec spec, {Object? tag}) {
    MessageEntry? entry = tag == null ? null : _byTag(tag);
    if (entry != null) {
      entry.spec = spec;
    } else {
      entry = MessageEntry(id: _seq++, spec: spec, tag: tag);
      _entries.add(entry);
      _enforceCap();
    }
    _arm(entry);
    notifyListeners();
    return _Handle(this, entry.id);
  }

  MessageHandle loading(String text, {Object? tag}) => show(
    const MessageSpec(variant: MessageVariant.loading, text: '').copyText(text),
    tag: tag,
  );

  MessageHandle success(String text, {Object? tag, Duration? autoDismiss}) =>
      show(
        MessageSpec(
          variant: MessageVariant.success,
          text: text,
          autoDismiss: autoDismiss ?? _kSuccessDismiss,
        ),
        tag: tag,
      );

  MessageHandle error(
    String text, {
    String? actionLabel,
    VoidCallback? onAction,
    Object? tag,
  }) => show(
    MessageSpec(
      variant: MessageVariant.error,
      text: text,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
    tag: tag,
  );

  MessageHandle warning(String text, {Object? tag}) => show(
    MessageSpec(variant: MessageVariant.warning, text: text),
    tag: tag,
  );

  MessageHandle info(
    String text, {
    String? actionLabel,
    VoidCallback? onAction,
    Object? tag,
    Duration? autoDismiss,
  }) => show(
    MessageSpec(
      variant: MessageVariant.info,
      text: text,
      actionLabel: actionLabel,
      onAction: onAction,
      autoDismiss: autoDismiss ?? _kInfoDismiss,
    ),
    tag: tag,
  );

  /// Remove the message bound to [tag], if any (e.g. a cancelled purchase).
  void dismissTag(Object tag) {
    final e = _byTag(tag);
    if (e != null) _removeById(e.id);
  }

  void dismissEntry(MessageEntry entry) => _removeById(entry.id);

  void dismissAll() {
    if (_entries.isEmpty) return;
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _entries.clear();
    notifyListeners();
  }

  // --- internals ---------------------------------------------------------

  MessageEntry? _byTag(Object tag) {
    for (final e in _entries) {
      if (e.tag == tag) return e;
    }
    return null;
  }

  bool _has(int id) {
    for (final e in _entries) {
      if (e.id == id) return true;
    }
    return false;
  }

  void _enforceCap() {
    while (_entries.length > maxVisible) {
      final removed = _entries.removeAt(0);
      _timers.remove(removed.id)?.cancel();
    }
  }

  void _arm(MessageEntry e) {
    _timers.remove(e.id)?.cancel();
    final d = e.spec.autoDismiss;
    if (d != null) _timers[e.id] = Timer(d, () => _removeById(e.id));
  }

  void _removeById(int id) {
    _timers.remove(id)?.cancel();
    final before = _entries.length;
    _entries.removeWhere((e) => e.id == id);
    if (_entries.length != before) notifyListeners();
  }

  void _updateById(int id, MessageSpec spec) {
    for (final e in _entries) {
      if (e.id == id) {
        e.spec = spec;
        _arm(e);
        notifyListeners();
        return;
      }
    }
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}

/// A handle to one shown message — lets the caller transition it in place
/// (e.g. `loading → error`) or dismiss it. No-ops once the message is gone.
abstract class MessageHandle {
  void update(MessageSpec spec);
  void loading(String text);
  void success(String text, {Duration? autoDismiss});
  void error(String text, {String? actionLabel, VoidCallback? onAction});
  void info(String text, {Duration? autoDismiss});
  void dismiss();
  bool get isActive;
}

class _Handle implements MessageHandle {
  _Handle(this._controller, this._id);
  final MessageController _controller;
  final int _id;

  @override
  void update(MessageSpec spec) => _controller._updateById(_id, spec);

  @override
  void loading(String text) =>
      update(MessageSpec(variant: MessageVariant.loading, text: text));

  @override
  void success(String text, {Duration? autoDismiss}) => update(
    MessageSpec(
      variant: MessageVariant.success,
      text: text,
      autoDismiss: autoDismiss ?? _kSuccessDismiss,
    ),
  );

  @override
  void error(String text, {String? actionLabel, VoidCallback? onAction}) =>
      update(
        MessageSpec(
          variant: MessageVariant.error,
          text: text,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      );

  @override
  void info(String text, {Duration? autoDismiss}) => update(
    MessageSpec(
      variant: MessageVariant.info,
      text: text,
      autoDismiss: autoDismiss ?? _kInfoDismiss,
    ),
  );

  @override
  void dismiss() => _controller._removeById(_id);

  @override
  bool get isActive => _controller._has(_id);
}

extension on MessageSpec {
  // Tiny helper so loading() can build a sticky loading spec by text.
  MessageSpec copyText(String text) => MessageSpec(
    variant: variant,
    text: text,
    actionLabel: actionLabel,
    onAction: onAction,
    autoDismiss: autoDismiss,
  );
}
