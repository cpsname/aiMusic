import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  /// A 49303 as the envelope interceptor delivers it: numeric details already
  /// stringified, a JSON null as `"null"`.
  Failure quota(Map<String, String> details) => const ErrorHandler().handle(
        ApiError.fromEnvelope(code: 49303, message: 'quota exhausted', details: {'error_code': 'QUOTA_EXHAUSTED', ...details}),
      );

  test('reads the gap and the recommended pack from a v1.1 envelope', () {
    final gap = MusicQuotaGap.of(quota({
      'reason': 'insufficient',
      'required_credits': '2169',
      'available_credits': '66',
      'recommended_product_id': 'com.songlet.mv.chorus',
    }));
    expect(gap, isNotNull);
    expect(gap!.reason, MusicQuotaGap.reasonInsufficient);
    expect(gap.requiredCredits, 2169);
    expect(gap.availableCredits, 66);
    expect(gap.gapCredits, 2103);
    expect(gap.recommendedProductId, 'com.songlet.mv.chorus');
  });

  test('contract 02 v2.1: the offer says which page to open — plans or packs', () {
    final packs = quota({'offer': 'packs', 'reason': 'insufficient', 'required_credits': '120', 'available_credits': '20', 'recommended_product_id': 'com.songlet.pack.50'});
    expect(MusicQuotaGap.of(packs)!.offer, MusicQuotaOffer.packs);
    expect(MusicQuotaOffer.of(packs), MusicQuotaOffer.packs);
    final plans = quota({'offer': 'subscription', 'required_credits': '57', 'available_credits': '0'});
    expect(MusicQuotaGap.of(plans)!.offer, MusicQuotaOffer.subscription);
    expect(MusicQuotaOffer.of(plans), MusicQuotaOffer.subscription);
  });

  test('an offer without the numbers (or numbers without an offer) still reads', () {
    final onlyOffer = quota({'offer': 'packs'});
    expect(MusicQuotaGap.of(onlyOffer), isNull, reason: 'no credit numbers: no gap');
    expect(MusicQuotaOffer.of(onlyOffer), MusicQuotaOffer.packs);
    expect(MusicQuotaGap.of(quota({'required_credits': '57', 'available_credits': '0'}))!.offer, isNull);
  });

  test('only an error code, an unknown offer or another code: no offer (the paywall opens on the plans)', () {
    expect(MusicQuotaOffer.of(quota(const {})), isNull);
    expect(MusicQuotaOffer.of(quota({'offer': 'both'})), isNull);
    final other = const ErrorHandler().handle(
      ApiError.fromEnvelope(code: 49312, message: '', details: {'error_code': 'MV_SONG_NOT_READY', 'offer': 'packs'}),
    );
    expect(MusicQuotaOffer.of(other), isNull);
    expect(MusicQuotaOffer.of(const NetworkFailure(message: '')), isNull);
  });

  test('a null recommendation (paywall, or no pack for the level) stays null', () {
    final gap = MusicQuotaGap.of(quota({'reason': 'paywall', 'required_credits': '49', 'available_credits': '66', 'recommended_product_id': 'null'}));
    expect(gap!.reason, MusicQuotaGap.reasonPaywall);
    expect(gap.recommendedProductId, isNull);
    expect(gap.gapCredits, 0, reason: 'never negative');
  });

  test('a v1 envelope without numbers, or another code, carries no gap', () {
    expect(MusicQuotaGap.of(quota(const {})), isNull);
    final other = const ErrorHandler().handle(
      ApiError.fromEnvelope(code: 49312, message: '', details: {'error_code': 'MV_SONG_NOT_READY', 'required_credits': '1'}),
    );
    expect(MusicQuotaGap.of(other), isNull);
    expect(MusicQuotaGap.of(const NetworkFailure(message: '')), isNull);
  });
}
