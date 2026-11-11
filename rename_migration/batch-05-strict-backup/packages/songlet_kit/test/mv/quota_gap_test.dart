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
    final gap = QuotaGap.of(quota({
      'reason': 'insufficient',
      'required_credits': '2169',
      'available_credits': '66',
      'recommended_product_id': 'com.songlet.mv.chorus',
    }));
    expect(gap, isNotNull);
    expect(gap!.reason, QuotaGap.reasonInsufficient);
    expect(gap.requiredCredits, 2169);
    expect(gap.availableCredits, 66);
    expect(gap.gapCredits, 2103);
    expect(gap.recommendedProductId, 'com.songlet.mv.chorus');
  });

  test('contract 02 v2.1: the offer says which page to open — plans or packs', () {
    final packs = quota({'offer': 'packs', 'reason': 'insufficient', 'required_credits': '120', 'available_credits': '20', 'recommended_product_id': 'com.songlet.pack.50'});
    expect(QuotaGap.of(packs)!.offer, QuotaOffer.packs);
    expect(QuotaOffer.of(packs), QuotaOffer.packs);
    final plans = quota({'offer': 'subscription', 'required_credits': '57', 'available_credits': '0'});
    expect(QuotaGap.of(plans)!.offer, QuotaOffer.subscription);
    expect(QuotaOffer.of(plans), QuotaOffer.subscription);
  });

  test('an offer without the numbers (or numbers without an offer) still reads', () {
    final onlyOffer = quota({'offer': 'packs'});
    expect(QuotaGap.of(onlyOffer), isNull, reason: 'no credit numbers: no gap');
    expect(QuotaOffer.of(onlyOffer), QuotaOffer.packs);
    expect(QuotaGap.of(quota({'required_credits': '57', 'available_credits': '0'}))!.offer, isNull);
  });

  test('only an error code, an unknown offer or another code: no offer (the paywall opens on the plans)', () {
    expect(QuotaOffer.of(quota(const {})), isNull);
    expect(QuotaOffer.of(quota({'offer': 'both'})), isNull);
    final other = const ErrorHandler().handle(
      ApiError.fromEnvelope(code: 49312, message: '', details: {'error_code': 'MV_SONG_NOT_READY', 'offer': 'packs'}),
    );
    expect(QuotaOffer.of(other), isNull);
    expect(QuotaOffer.of(const NetworkFailure(message: '')), isNull);
  });

  test('a null recommendation (paywall, or no pack for the level) stays null', () {
    final gap = QuotaGap.of(quota({'reason': 'paywall', 'required_credits': '49', 'available_credits': '66', 'recommended_product_id': 'null'}));
    expect(gap!.reason, QuotaGap.reasonPaywall);
    expect(gap.recommendedProductId, isNull);
    expect(gap.gapCredits, 0, reason: 'never negative');
  });

  test('a v1 envelope without numbers, or another code, carries no gap', () {
    expect(QuotaGap.of(quota(const {})), isNull);
    final other = const ErrorHandler().handle(
      ApiError.fromEnvelope(code: 49312, message: '', details: {'error_code': 'MV_SONG_NOT_READY', 'required_credits': '1'}),
    );
    expect(QuotaGap.of(other), isNull);
    expect(QuotaGap.of(const NetworkFailure(message: '')), isNull);
  });
}
