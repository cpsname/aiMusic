import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A finder from a plan step: `key` (a `ValueKey<String>` — the app's test
/// id), optionally narrowed to a descendant widget class (`widget`), text
/// (`label`) or icon code point (`icon`) under it, `index`-th match.
class PlanFinder {
  PlanFinder(this.finder, this._label);

  factory PlanFinder.parse(Map<String, dynamic> spec) {
    final key = spec['key'] as String?;
    final widget = spec['widget'] as String?;
    final text = spec['label'] as String?;
    final icon = spec['icon'] as int?;
    final inner = widget != null
        ? byWidgetName(widget)
        : text != null
        ? find.text(text)
        : icon != null
        ? find.byWidgetPredicate((w) => w is Icon && w.icon?.codePoint == icon)
        : null;
    Finder finder;
    if (key != null) {
      final keyed = find.byKey(ValueKey(key));
      finder = inner == null ? keyed : find.descendant(of: keyed, matching: inner);
    } else if (inner != null) {
      finder = inner;
    } else {
      throw ArgumentError('a finder needs key, widget, label or icon: $spec');
    }
    final index = spec['index'];
    if (index is int) finder = finder.at(index);
    return PlanFinder(
      finder,
      jsonEncode({
        for (final k in ['key', 'widget', 'label', 'icon', 'index'])
          if (spec[k] != null) k: spec[k],
      }),
    );
  }

  final Finder finder;
  final String _label;

  /// Widgets of a class, by its runtime name (plans cannot name types).
  static Finder byWidgetName(String name) => find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

  @override
  String toString() => _label;
}
