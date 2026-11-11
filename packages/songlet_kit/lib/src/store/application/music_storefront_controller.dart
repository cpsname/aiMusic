import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'music_store_providers.dart';

/// The App Store storefront (ISO alpha-3) currently known, reactive so the
/// `X-Storefront` request header and the T1/T2/T3 allowance copy follow a
/// storefront change without a restart.
class MusicStorefrontController extends Notifier<String?> {
  @override
  String? build() => ref.watch(storefrontStoreProvider).current;

  Future<void> remember(String alpha3) async {
    final value = alpha3.toUpperCase();
    if (value.isEmpty || value == state) return;
    await ref.read(storefrontStoreProvider).remember(value);
    state = value;
  }
}
