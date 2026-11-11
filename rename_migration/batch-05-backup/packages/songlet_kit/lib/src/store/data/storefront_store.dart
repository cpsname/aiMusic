import 'package:infra_core/infra_core.dart';

/// The last App Store storefront seen (ISO alpha-3), from StoreKit product
/// lookups and signed transactions. Sent as `X-Storefront` (region
/// availability, PRD §11.3) and used for T1/T2/T3 allowance copy (PRD §8.3).
class StorefrontStore {
  StorefrontStore(this._store);

  static const String _key = 'songlet.storefront';

  final KeyValueStore _store;

  String? get current {
    final value = _store.getString(_key);
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> remember(String alpha3) async {
    if (alpha3.isEmpty || alpha3 == current) return;
    await _store.setString(_key, alpha3.toUpperCase());
  }
}
