import 'dart:convert';

import '../core/fields.dart';

/// An ordered, device-specific shelf. Locale sequences never fall back to
/// another language. Absence means unmanaged; empty lists cannot erase media.
class MediaSetBinding {
  const MediaSetBinding({required this.placement, required this.displayTarget, required this.locales});
  final String placement;
  final String displayTarget;
  final Map<String, List<String>> locales;

  factory MediaSetBinding.read(Fields f) {
    f.only({'placement', 'display_target', 'locales'});
    final locales = f.map('locales');
    return MediaSetBinding(
      placement: f.string('placement'),
      displayTarget: f.string('display_target'),
      locales: {for (final l in locales.raw.keys) l: locales.strings(l)},
    );
  }

  String get key => '$placement/$displayTarget';
  MediaSetBinding within(Set<String>? available) => MediaSetBinding(
    placement: placement,
    displayTarget: displayTarget,
    locales: {
      for (final e in locales.entries)
        if (available == null || available.contains(e.key)) e.key: e.value,
    },
  );
  Map<String, Object> toYaml() => {
    'placement': placement,
    'display_target': displayTarget,
    'locales': {for (final l in locales.keys.toList()..sort()) l: locales[l]!},
  };
  bool sameAs(MediaSetBinding other) => jsonEncode(toYaml()) == jsonEncode(other.toYaml());
}

class MediaShelfDeclaration {
  const MediaShelfDeclaration({required this.placement, required this.displayTarget, required this.ids});
  final String placement;
  final String displayTarget;
  final List<String> ids;

  factory MediaShelfDeclaration.read(Fields f) {
    f.only({'placement', 'display_target', 'locales'});
    return MediaShelfDeclaration(placement: f.string('placement'), displayTarget: f.string('display_target'), ids: f.strings('locales'));
  }

  String get key => '$placement/$displayTarget';
  MediaSetBinding expand(List<String> storefronts) => MediaSetBinding(
    placement: placement,
    displayTarget: displayTarget,
    locales: {
      for (final l in storefronts) l: [for (final id in ids) id.replaceAll('{storefront}', l)],
    },
  );
}
