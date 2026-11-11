import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet/l10n/generated/app_localizations.dart';
import 'package:songlet/ui/common/failure_copy.dart';
import 'package:songlet_kit/songlet_kit.dart';

/// PRD §6.5: every backend `error_code` surfaces the table's exact English
/// copy on every error surface.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  const expected = {
    MusicErrorCode.safetyBlocked:
        "We can't make this one — try different words, and skip artist names.",
    MusicErrorCode.quotaExhausted:
        "You've used this month's songs. Add a pack or upgrade.",
    MusicErrorCode.upstreamTimeout:
        "Taking longer than usual. We'll keep trying and notify you.",
    MusicErrorCode.upstreamRateLimited:
        'Lots of songs being made right now. Yours is queued.',
    // ADR-0005: a server REGION_UNAVAILABLE reads as a temporary delay.
    MusicErrorCode.regionUnavailable:
        "Taking longer than usual. We'll keep trying and notify you.",
    MusicErrorCode.attestFailed: 'Please update Songlet from the App Store.',
    MusicErrorCode.imageRejected:
        "One of these photos can't be used. Try another.",
    // Music videos (contract v1.1 §4 / platform 04 §2).
    MusicErrorCode.mvSongNotReady: "This song isn't ready for a video yet.",
    MusicErrorCode.mvSongTooLong:
        'This song is too long for a full video — try a chorus video.',
    MusicErrorCode.mvSongExpired:
        'This song has expired. Generate it again to make a video.',
    MusicErrorCode.mvNotFound: "This video isn't available anymore.",
    MusicErrorCode.mvPhotosExpired:
        'Those photos have expired — pick them again.',
    MusicErrorCode.mvRenderFailed:
        "We couldn't finish this video. Your credits are back — try again.",
  };

  for (final entry in expected.entries) {
    test('${entry.key.wire} → PRD §6.5 copy', () {
      final failure = const ErrorHandler().handle(entry.key.toApiError());
      expect(failure.errorCode, entry.key.wire);
      expect(failureMessageText(l10n, failure), entry.value);
    });
  }

  test('an unreachable host is NETWORK_OFFLINE copy', () {
    const failure = NetworkFailure(
      message: '',
      kind: NetworkFailureKind.offline,
    );
    expect(
      failureMessageText(l10n, failure),
      "You're offline. Your library still works.",
    );
  });

  test('the envelope detail wins over a localized server message', () {
    final failure = const ErrorHandler().handle(
      ApiError.fromEnvelope(
        code: 40201,
        message: 'server text',
        details: {ApiError.errorCodeDetailKey: 'QUOTA_EXHAUSTED'},
      ),
    );
    expect(failure, isA<PaymentFailure>());
    expect(
      failureMessageText(l10n, failure),
      expected[MusicErrorCode.quotaExhausted],
    );
  });
}
