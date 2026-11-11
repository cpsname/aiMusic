import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  const handler = ErrorHandler();

  group('fromWire', () {
    test('round-trips every code', () {
      for (final code in MusicErrorCode.values) {
        expect(MusicErrorCode.fromWire(code.wire), code);
      }
    });

    test('unknown / null → null', () {
      expect(MusicErrorCode.fromWire('SOMETHING_ELSE'), isNull);
      expect(MusicErrorCode.fromWire('quota_exhausted'), isNull);
      expect(MusicErrorCode.fromWire(null), isNull);
    });

    test('envelope codes match the contract §4 table', () {
      expect(
        {for (final c in MusicErrorCode.values) c.wire: c.envelopeCode},
        {
          'SAFETY_BLOCKED': 45101,
          'QUOTA_EXHAUSTED': 49303,
          'UPSTREAM_TIMEOUT': 50401,
          'UPSTREAM_RATE_LIMITED': 42901,
          'REGION_UNAVAILABLE': 45103,
          'ATTEST_FAILED': 40140,
          'IMAGE_REJECTED': 45102,
          'NETWORK_OFFLINE': 0,
          'DOWNLOAD_LOCKED': 40310,
          'JOB_ALREADY_FINISHED': 49309,
          // Music videos (contract v1.1 §4; job-level codes carry no number).
          'MV_SONG_NOT_READY': 49312,
          'MV_SONG_TOO_LONG': 49313,
          'MV_SONG_EXPIRED': 49314,
          'MV_NOT_FOUND': 49315,
          'MV_PHOTOS_EXPIRED': 49316,
          'MV_RENDER_FAILED': 0,
          'USER_CANCELLED': 0,
        },
      );
    });

    test('music-video codes are their own family; render failures are refunded', () {
      expect(MusicErrorCode.values.where((c) => c.isMusicVideo).map((c) => c.wire), [
        'MV_SONG_NOT_READY', 'MV_SONG_TOO_LONG', 'MV_SONG_EXPIRED', 'MV_NOT_FOUND', 'MV_PHOTOS_EXPIRED', 'MV_RENDER_FAILED',
      ]);
      expect(MusicErrorCode.mvRenderFailed.isRefunded, isTrue);
      expect(MusicErrorCode.mvNotFound.isRefunded, isFalse);
      expect(MusicErrorCode.mvSongNotReady.blocksGeneration, isFalse);
    });

    test('JOB_ALREADY_FINISHED is recognised by its string, whatever the numeric class', () {
      final failure = handler.handle(MusicErrorCode.jobAlreadyFinished.toApiError());
      expect(MusicErrorCode.of(failure), MusicErrorCode.jobAlreadyFinished);
      expect(MusicErrorCode.jobAlreadyFinished.blocksGeneration, isFalse);
    });
  });

  group('of(Failure)', () {
    test('reads the envelope error_code', () {
      expect(
        MusicErrorCode.of(
          const PaymentFailure(message: 'm', code: 40201, errorCode: 'QUOTA_EXHAUSTED'),
        ),
        MusicErrorCode.quotaExhausted,
      );
    });

    test('an offline NetworkFailure is NETWORK_OFFLINE', () {
      expect(
        MusicErrorCode.of(
          const NetworkFailure(message: '', kind: NetworkFailureKind.offline),
        ),
        MusicErrorCode.networkOffline,
      );
    });

    test('other network kinds carry no Songlet code', () {
      expect(
        MusicErrorCode.of(
          const NetworkFailure(message: '', kind: NetworkFailureKind.timeout),
        ),
        isNull,
      );
      expect(MusicErrorCode.of(const NetworkFailure(message: '')), isNull);
    });

    test('an explicit code wins over the transport kind', () {
      expect(
        MusicErrorCode.of(
          const NetworkFailure(
            message: '',
            kind: NetworkFailureKind.offline,
            errorCode: 'UPSTREAM_TIMEOUT',
          ),
        ),
        MusicErrorCode.upstreamTimeout,
      );
    });

    test('no code, not offline → null', () {
      expect(MusicErrorCode.of(const ServerFailure(message: '')), isNull);
      expect(
        MusicErrorCode.of(const ServerFailure(message: '', errorCode: 'NOPE')),
        isNull,
      );
    });
  });

  group('toApiError → ErrorHandler', () {
    Failure failureOf(MusicErrorCode code) => handler.handle(code.toApiError());

    test('every code keeps its errorCode through the handler', () {
      for (final code in MusicErrorCode.values) {
        final failure = failureOf(code);
        expect(failure.errorCode, code.wire, reason: code.wire);
        expect(MusicErrorCode.of(failure), code, reason: code.wire);
      }
    });

    test('carries the envelope code (NETWORK_OFFLINE → generic 50000)', () {
      expect(failureOf(MusicErrorCode.quotaExhausted).code, 49303);
      expect(failureOf(MusicErrorCode.networkOffline).code, 50000);
    });

    test('QUOTA_EXHAUSTED rides on 49303 (a business code on HTTP 200, platform 04 §2): the string, not the class, is the contract', () {
      final failure = failureOf(MusicErrorCode.quotaExhausted);
      expect(failure, isA<ServerFailure>());
      expect(MusicErrorCode.of(failure), MusicErrorCode.quotaExhausted);
    });

    test('UPSTREAM_RATE_LIMITED → RateLimitFailure', () {
      expect(
        failureOf(MusicErrorCode.upstreamRateLimited),
        isA<RateLimitFailure>(),
      );
    });

    test('SAFETY_BLOCKED / IMAGE_REJECTED / REGION_UNAVAILABLE → ContentFilterFailure', () {
      expect(failureOf(MusicErrorCode.safetyBlocked), isA<ContentFilterFailure>());
      expect(failureOf(MusicErrorCode.imageRejected), isA<ContentFilterFailure>());
      expect(
        failureOf(MusicErrorCode.regionUnavailable),
        isA<ContentFilterFailure>(),
      );
    });

    test('ATTEST_FAILED → AuthFailure without a forced logout', () {
      final failure = failureOf(MusicErrorCode.attestFailed);
      expect(failure, isA<AuthFailure>());
      expect((failure as AuthFailure).requiresForceLogout, isFalse);
    });

    test('UPSTREAM_TIMEOUT → ServerFailure; DOWNLOAD_LOCKED → AuthFailure (403)', () {
      expect(failureOf(MusicErrorCode.upstreamTimeout), isA<ServerFailure>());
      expect(failureOf(MusicErrorCode.downloadLocked), isA<AuthFailure>());
    });

    test('the message is empty (UI supplies localized copy)', () {
      for (final code in MusicErrorCode.values) {
        expect(failureOf(code).message, isEmpty);
      }
    });
  });

  group('flags', () {
    test('blocksGeneration: attest only — region never blocks (ADR-0005)', () {
      expect(
        MusicErrorCode.values.where((c) => c.blocksGeneration),
        [MusicErrorCode.attestFailed],
      );
    });

    test('presentedAs: REGION_UNAVAILABLE reads as UPSTREAM_TIMEOUT (ADR-0005)', () {
      expect(MusicErrorCode.regionUnavailable.presentedAs,
          MusicErrorCode.upstreamTimeout);
      for (final code in MusicErrorCode.values
          .where((c) => c != MusicErrorCode.regionUnavailable)) {
        expect(code.presentedAs, code);
      }
    });

    test('isRefunded: safety, timeout, image — and every refused or failed music video', () {
      expect(
        MusicErrorCode.values.where((c) => c.isRefunded).toSet(),
        {
          MusicErrorCode.safetyBlocked,
          MusicErrorCode.upstreamTimeout,
          MusicErrorCode.imageRejected,
          MusicErrorCode.mvRenderFailed,
          MusicErrorCode.mvSongNotReady,
          MusicErrorCode.mvSongTooLong,
          MusicErrorCode.mvSongExpired,
          MusicErrorCode.mvPhotosExpired,
        },
      );
    });
  });
}
