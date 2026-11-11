import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  const handler = ErrorHandler();

  group('fromWire', () {
    test('round-trips every code', () {
      for (final code in SongletErrorCode.values) {
        expect(SongletErrorCode.fromWire(code.wire), code);
      }
    });

    test('unknown / null → null', () {
      expect(SongletErrorCode.fromWire('SOMETHING_ELSE'), isNull);
      expect(SongletErrorCode.fromWire('quota_exhausted'), isNull);
      expect(SongletErrorCode.fromWire(null), isNull);
    });

    test('envelope codes match the contract §4 table', () {
      expect(
        {for (final c in SongletErrorCode.values) c.wire: c.envelopeCode},
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
      expect(SongletErrorCode.values.where((c) => c.isMusicVideo).map((c) => c.wire), [
        'MV_SONG_NOT_READY', 'MV_SONG_TOO_LONG', 'MV_SONG_EXPIRED', 'MV_NOT_FOUND', 'MV_PHOTOS_EXPIRED', 'MV_RENDER_FAILED',
      ]);
      expect(SongletErrorCode.mvRenderFailed.isRefunded, isTrue);
      expect(SongletErrorCode.mvNotFound.isRefunded, isFalse);
      expect(SongletErrorCode.mvSongNotReady.blocksGeneration, isFalse);
    });

    test('JOB_ALREADY_FINISHED is recognised by its string, whatever the numeric class', () {
      final failure = handler.handle(SongletErrorCode.jobAlreadyFinished.toApiError());
      expect(SongletErrorCode.of(failure), SongletErrorCode.jobAlreadyFinished);
      expect(SongletErrorCode.jobAlreadyFinished.blocksGeneration, isFalse);
    });
  });

  group('of(Failure)', () {
    test('reads the envelope error_code', () {
      expect(
        SongletErrorCode.of(
          const PaymentFailure(message: 'm', code: 40201, errorCode: 'QUOTA_EXHAUSTED'),
        ),
        SongletErrorCode.quotaExhausted,
      );
    });

    test('an offline NetworkFailure is NETWORK_OFFLINE', () {
      expect(
        SongletErrorCode.of(
          const NetworkFailure(message: '', kind: NetworkFailureKind.offline),
        ),
        SongletErrorCode.networkOffline,
      );
    });

    test('other network kinds carry no Songlet code', () {
      expect(
        SongletErrorCode.of(
          const NetworkFailure(message: '', kind: NetworkFailureKind.timeout),
        ),
        isNull,
      );
      expect(SongletErrorCode.of(const NetworkFailure(message: '')), isNull);
    });

    test('an explicit code wins over the transport kind', () {
      expect(
        SongletErrorCode.of(
          const NetworkFailure(
            message: '',
            kind: NetworkFailureKind.offline,
            errorCode: 'UPSTREAM_TIMEOUT',
          ),
        ),
        SongletErrorCode.upstreamTimeout,
      );
    });

    test('no code, not offline → null', () {
      expect(SongletErrorCode.of(const ServerFailure(message: '')), isNull);
      expect(
        SongletErrorCode.of(const ServerFailure(message: '', errorCode: 'NOPE')),
        isNull,
      );
    });
  });

  group('toApiError → ErrorHandler', () {
    Failure failureOf(SongletErrorCode code) => handler.handle(code.toApiError());

    test('every code keeps its errorCode through the handler', () {
      for (final code in SongletErrorCode.values) {
        final failure = failureOf(code);
        expect(failure.errorCode, code.wire, reason: code.wire);
        expect(SongletErrorCode.of(failure), code, reason: code.wire);
      }
    });

    test('carries the envelope code (NETWORK_OFFLINE → generic 50000)', () {
      expect(failureOf(SongletErrorCode.quotaExhausted).code, 49303);
      expect(failureOf(SongletErrorCode.networkOffline).code, 50000);
    });

    test('QUOTA_EXHAUSTED rides on 49303 (a business code on HTTP 200, platform 04 §2): the string, not the class, is the contract', () {
      final failure = failureOf(SongletErrorCode.quotaExhausted);
      expect(failure, isA<ServerFailure>());
      expect(SongletErrorCode.of(failure), SongletErrorCode.quotaExhausted);
    });

    test('UPSTREAM_RATE_LIMITED → RateLimitFailure', () {
      expect(
        failureOf(SongletErrorCode.upstreamRateLimited),
        isA<RateLimitFailure>(),
      );
    });

    test('SAFETY_BLOCKED / IMAGE_REJECTED / REGION_UNAVAILABLE → ContentFilterFailure', () {
      expect(failureOf(SongletErrorCode.safetyBlocked), isA<ContentFilterFailure>());
      expect(failureOf(SongletErrorCode.imageRejected), isA<ContentFilterFailure>());
      expect(
        failureOf(SongletErrorCode.regionUnavailable),
        isA<ContentFilterFailure>(),
      );
    });

    test('ATTEST_FAILED → AuthFailure without a forced logout', () {
      final failure = failureOf(SongletErrorCode.attestFailed);
      expect(failure, isA<AuthFailure>());
      expect((failure as AuthFailure).requiresForceLogout, isFalse);
    });

    test('UPSTREAM_TIMEOUT → ServerFailure; DOWNLOAD_LOCKED → AuthFailure (403)', () {
      expect(failureOf(SongletErrorCode.upstreamTimeout), isA<ServerFailure>());
      expect(failureOf(SongletErrorCode.downloadLocked), isA<AuthFailure>());
    });

    test('the message is empty (UI supplies localized copy)', () {
      for (final code in SongletErrorCode.values) {
        expect(failureOf(code).message, isEmpty);
      }
    });
  });

  group('flags', () {
    test('blocksGeneration: attest only — region never blocks (ADR-0005)', () {
      expect(
        SongletErrorCode.values.where((c) => c.blocksGeneration),
        [SongletErrorCode.attestFailed],
      );
    });

    test('presentedAs: REGION_UNAVAILABLE reads as UPSTREAM_TIMEOUT (ADR-0005)', () {
      expect(SongletErrorCode.regionUnavailable.presentedAs,
          SongletErrorCode.upstreamTimeout);
      for (final code in SongletErrorCode.values
          .where((c) => c != SongletErrorCode.regionUnavailable)) {
        expect(code.presentedAs, code);
      }
    });

    test('isRefunded: safety, timeout, image — and every refused or failed music video', () {
      expect(
        SongletErrorCode.values.where((c) => c.isRefunded).toSet(),
        {
          SongletErrorCode.safetyBlocked,
          SongletErrorCode.upstreamTimeout,
          SongletErrorCode.imageRejected,
          SongletErrorCode.mvRenderFailed,
          SongletErrorCode.mvSongNotReady,
          SongletErrorCode.mvSongTooLong,
          SongletErrorCode.mvSongExpired,
          SongletErrorCode.mvPhotosExpired,
        },
      );
    });
  });
}
