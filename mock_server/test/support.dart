import 'dart:io';

import 'package:songlet_mock_server/songlet_mock_music_server.dart';
import 'package:test/test.dart';

/// Starts one in-process mock per test file (ephemeral port, quiet log) and
/// resets it + applies fast delays before every test.
class MusicHarness {
  late MusicMockServer server;
  final List<MusicMockClient> _clients = [];

  String get baseUrl => 'http://localhost:${server.port}';

  void install({int clipDelayMs = 40, int songDelayMs = 60}) {
    setUpAll(() async {
      server = MusicMockServer(log: (_) {});
      await server.start(port: 0, address: InternetAddress.loopbackIPv4);
    });
    tearDownAll(() => server.close());
    setUp(() async {
      final admin = client();
      await admin.admin('reset');
      await admin.admin('config', {
        'clip_delay_ms': clipDelayMs,
        'song_delay_ms': songDelayMs,
      });
    });
    tearDown(() {
      for (final c in _clients) {
        c.close();
      }
      _clients.clear();
    });
  }

  MusicMockClient client({
    String? token,
    String storefront = 'USA',
    String deviceRegion = 'US',
  }) {
    final c = MusicMockClient(
      baseUrl: baseUrl,
      appAccountToken: token,
      storefront: storefront,
      deviceRegion: deviceRegion,
    );
    _clients.add(c);
    return c;
  }

  /// A client that has already attested.
  Future<MusicMockClient> device({
    String? token,
    String storefront = 'USA',
    String deviceRegion = 'US',
  }) async {
    final c = client(
      token: token,
      storefront: storefront,
      deviceRegion: deviceRegion,
    );
    final res = await c.attest();
    expect(res.code, 0, reason: '$res');
    return c;
  }
}

int _txCounter = 1000;

/// An Apple `JWSTransactionDecodedPayload` fixture.
Map<String, Object?> txPayload({
  required String productId,
  required String appAccountToken,
  String? transactionId,
  String? originalTransactionId,
  DateTime? purchaseDate,
  DateTime? expiresDate,
  String storefront = 'USA',
  int? offerType,
  DateTime? revocationDate,
}) {
  final id = transactionId ?? '${2000000000 + _txCounter++}';
  final purchase = purchaseDate ?? DateTime.now().toUtc();
  final isSub = productId.contains('.pro.') || productId.contains('.premier.');
  final expires =
      expiresDate ??
      (isSub
          ? addMonths(purchase, productId.endsWith('yearly') ? 12 : 1)
          : null);
  return {
    'transactionId': id,
    'originalTransactionId': originalTransactionId ?? id,
    'productId': productId,
    'purchaseDate': purchase.millisecondsSinceEpoch,
    'originalPurchaseDate': purchase.millisecondsSinceEpoch,
    'expiresDate': ?expires?.millisecondsSinceEpoch,
    'type': isSub ? 'Auto-Renewable Subscription' : 'Consumable',
    'appAccountToken': appAccountToken,
    'storefront': storefront,
    'offerType': ?offerType,
    'revocationDate': ?revocationDate?.millisecondsSinceEpoch,
    'bundleId': 'com.songlet.app',
    'environment': 'Xcode',
  };
}
